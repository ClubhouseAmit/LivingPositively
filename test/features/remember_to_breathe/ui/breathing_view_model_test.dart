import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_photo_importer.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_repository.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_model.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_state.dart';

class _Repository extends Mock implements BreathingRepository {}

class _PhotoImporter extends Mock implements BreathingPhotoImporter {}

Future<String> _photoFixture() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xff2f7650), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(1, 1);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return base64Encode(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

final class _Harness {
  _Harness({BreathingSettings settings = const BreathingSettings()}) {
    snapshot = BreathingSnapshot(settings: settings);
    when(repository.load).thenAnswer((_) async => snapshot);
    when(repository.discardUnreadableSnapshot).thenAnswer((_) async {
      snapshot = const BreathingSnapshot.empty();
      return snapshot;
    });
    when(() => repository.saveSettings(any())).thenAnswer((invocation) async {
      if (settingsFailure) throw const BreathingStorageException();
      snapshot = BreathingSnapshot(
        settings: invocation.positionalArguments.single as BreathingSettings,
        sessions: snapshot.sessions,
      );
      return snapshot;
    });
    when(() => repository.saveSession(any())).thenAnswer((invocation) async {
      final session = invocation.positionalArguments.single as BreathingSession;
      writes.add(session);
      if (sessionFailure) throw const BreathingStorageException();
      return commit(session);
    });
    when(photoImporter.pickPhoto).thenAnswer((_) async => null);
    model = BreathingViewModel(
      repository,
      photoImporter: photoImporter,
      monotonicElapsed: () => elapsed,
      now: () => wallTime.add(elapsed),
      sessionId: () => 'attempt-${++ids}',
    );
  }

  final _Repository repository = _Repository();
  final _PhotoImporter photoImporter = _PhotoImporter();
  late final BreathingViewModel model;
  late BreathingSnapshot snapshot;
  final List<BreathingSession> writes = [];
  Duration elapsed = Duration.zero;
  DateTime wallTime = DateTime.utc(2026, 9, 13);
  int ids = 0;
  bool sessionFailure = false;
  bool settingsFailure = false;

  BreathingSnapshot commit(BreathingSession session) {
    final sessions = snapshot.sessions.where((item) => item.id != session.id);
    snapshot = BreathingSnapshot(
      settings: snapshot.settings,
      sessions: [session, ...sessions],
    );
    return snapshot;
  }

  void advance(Duration duration) {
    elapsed += duration;
    model.refresh();
  }

  Future<void> start({
    BreathingPattern pattern = BreathingPattern.basic,
    int? rating,
  }) async {
    await model.load();
    model.selectPattern(pattern);
    model.preparePractice();
    model.startPractice(rating);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(const BreathingSettings());
    registerFallbackValue(
      BreathingSession(
        id: 'fallback',
        startedAt: DateTime(2026),
        endedAt: DateTime(2026),
        pattern: BreathingPattern.basic,
        completedCycles: 0,
      ),
    );
  });

  group('BreathingViewModel', () {
    late _Harness harness;
    late BreathingViewModel model;

    setUp(() {
      harness = _Harness();
      model = harness.model;
    });
    tearDown(() => model.dispose());

    test(
      'should load defaults, expose immutable history and quick start basic',
      () async {
        await model.load();
        expect(model.isReady, isTrue);
        expect(model.settings.background, BreathingBackground.forest);
        expect(model.settings.inhaleDuration, const Duration(seconds: 3));
        expect(model.settings.showCircle && model.settings.showText, isTrue);
        expect(() => model.history.clear(), throwsUnsupportedError);
        model.selectPattern(BreathingPattern.box);
        model.quickStart();
        expect(model.selectedPattern, BreathingPattern.basic);
        expect(model.screen, BreathingScreen.preRating);
        expect(model.requiresFullscreen, isFalse);
        model.startPractice(null);
        expect(model.requiresFullscreen, isTrue);
      },
    );

    test(
      'should use 3/3 phases and save exactly eight completed cycles once',
      () async {
        await harness.start();
        harness.advance(const Duration(seconds: 2));
        expect(model.phase, BreathingPhase.inhale);
        expect(model.phaseProgress, closeTo(2 / 3, 0.0001));
        harness.advance(const Duration(seconds: 1));
        expect(model.phase, BreathingPhase.exhale);
        expect(model.completedCycles, 0);
        harness.advance(const Duration(seconds: 3));
        expect(model.phase, BreathingPhase.inhale);
        expect(model.completedCycles, 1);
        harness.advance(const Duration(seconds: 41));
        expect(model.completedCycles, 7);
        expect(model.screen, BreathingScreen.practice);
        harness.advance(const Duration(seconds: 1));
        await model.retryResultSave();
        expect(model.screen, BreathingScreen.result);
        expect(model.result!.completedCycles, 8);
        expect(model.result!.isComplete, isTrue);
        expect(model.result!.stressBefore, isNull);
        expect(model.result!.stressAfter, isNull);
        harness.advance(const Duration(hours: 1));
        model.end();
        await model.retryResultSave();
        expect(harness.writes, hasLength(1));
        expect(model.history, hasLength(1));
      },
    );

    test(
      'should hold after inhale and exhale in each 16-second box cycle',
      () async {
        await harness.start(pattern: BreathingPattern.box);
        for (final phase in [
          BreathingPhase.holdInhale,
          BreathingPhase.exhale,
          BreathingPhase.holdExhale,
          BreathingPhase.inhale,
        ]) {
          harness.advance(const Duration(seconds: 4));
          expect(model.phase, phase);
        }
        expect(model.completedCycles, 1);
        harness.advance(const Duration(seconds: 111));
        expect(model.completedCycles, 7);
        harness.advance(const Duration(seconds: 1));
        await model.retryResultSave();
        expect(model.result!.isComplete, isTrue);
        expect(model.result!.pattern, BreathingPattern.box);
      },
    );

    test(
      'should use saved custom durations and complete eight cycles after a delayed tick',
      () async {
        model.dispose();
        harness = _Harness(
          settings: const BreathingSettings(
            inhaleDuration: Duration(seconds: 5),
            exhaleDuration: Duration(seconds: 7),
          ),
        );
        model = harness.model;
        await harness.start(pattern: BreathingPattern.custom);
        harness.advance(const Duration(seconds: 5));
        expect(model.phase, BreathingPhase.exhale);
        harness.advance(const Duration(seconds: 7));
        expect(model.completedCycles, 1);
        harness.advance(const Duration(minutes: 5));
        await model.retryResultSave();
        expect(model.result!.completedCycles, 8);
      },
    );

    test(
      'should apply duration edits only at the next matching phase',
      () async {
        await harness.start(pattern: BreathingPattern.custom);
        harness.advance(const Duration(seconds: 1));
        model.adjustDuration(inhale: true, delta: 2);
        model.adjustDuration(inhale: false, delta: 1);
        harness.advance(const Duration(seconds: 2));
        expect(model.phase, BreathingPhase.exhale);
        model.adjustDuration(inhale: false, delta: 2);
        harness.advance(const Duration(seconds: 4));
        expect(model.phase, BreathingPhase.inhale);
        expect(model.completedCycles, 1);
        harness.advance(const Duration(seconds: 4));
        expect(model.phase, BreathingPhase.inhale);
        harness.advance(const Duration(seconds: 1));
        expect(model.phase, BreathingPhase.exhale);
        harness.advance(const Duration(seconds: 5));
        expect(model.phase, BreathingPhase.exhale);
        harness.advance(const Duration(seconds: 1));
        expect(model.completedCycles, 2);
      },
    );

    test(
      'should preserve phase progress through pause and explicit lifecycle resume',
      () async {
        await harness.start();
        harness.advance(const Duration(seconds: 2));
        model.handleAppInactive();
        expect(model.isPaused, isTrue);
        expect(model.phaseProgress, closeTo(2 / 3, 0.0001));
        harness.advance(const Duration(minutes: 5));
        expect(model.phase, BreathingPhase.inhale);
        model.resume();
        harness.advance(const Duration(seconds: 1));
        expect(model.phase, BreathingPhase.exhale);
        expect(model.completedCycles, 0);
        expect(model.handleBack(), isFalse);
        expect(model.isPaused, isTrue);
      },
    );

    test(
      'should restart with new identity, unchanged settings and pre-rating',
      () async {
        await harness.start(pattern: BreathingPattern.custom, rating: 7);
        model.adjustDuration(inhale: true, delta: 2);
        harness.advance(const Duration(seconds: 10));
        model.pause();
        model.restart();
        expect(model.completedCycles, 0);
        expect(model.phaseProgress, 0);
        expect(model.isPaused, isFalse);
        expect(model.settings.inhaleDuration, const Duration(seconds: 5));
        expect(harness.writes, isEmpty);
        model.end();
        await model.retryResultSave();
        expect(model.result!.id, 'attempt-2');
        expect(model.result!.stressBefore, 7);
        expect(model.result!.completedCycles, 0);
      },
    );

    test('should continue timing when circle and text are hidden', () async {
      await harness.start();
      model.toggleCircle();
      model.toggleText();
      expect(model.settings.showCircle || model.settings.showText, isFalse);
      harness.advance(const Duration(seconds: 48));
      await model.retryResultSave();
      expect(model.result!.isComplete, isTrue);
    });

    test('should save only full cycles when stopped during a phase', () async {
      await harness.start(rating: 10);
      harness.advance(const Duration(seconds: 17));
      model.end();
      await model.retryResultSave();
      expect(model.result!.completedCycles, 2);
      expect(model.result!.isComplete, isFalse);
      expect(model.result!.stressBefore, 10);
      expect(model.result!.endedAt, harness.wallTime.add(harness.elapsed));
      expect(model.hasUnsavedResult, isFalse);
      expect(model.returnToLanding(), isTrue);
      expect(model.requiresFullscreen, isFalse);
    });

    test('should retain failed practice settings for result retry', () async {
      await harness.start(pattern: BreathingPattern.custom);
      harness.settingsFailure = true;
      model.adjustDuration(inhale: true, delta: 2);
      model.toggleText();
      await Future<void>.delayed(Duration.zero);
      expect(model.error, isA<BreathingStorageException>());
      model.end();
      await model.retryResultSave();
      expect(model.hasUnsavedResult, isTrue);
      expect(model.returnToLanding(), isFalse);
      harness.settingsFailure = false;
      await model.retryResultSave();
      expect(model.hasUnsavedResult, isFalse);
      expect(
        harness.snapshot.settings.inhaleDuration,
        const Duration(seconds: 5),
      );
      expect(harness.snapshot.settings.showText, isFalse);
      expect(model.history, hasLength(1));
    });

    test('should present loaded history newest first', () async {
      final first = BreathingSession(
        id: 'first',
        startedAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 1, 1),
        pattern: BreathingPattern.basic,
        completedCycles: 8,
      );
      final second = BreathingSession(
        id: 'second',
        startedAt: DateTime(2026, 1, 2),
        endedAt: DateTime(2026, 1, 2),
        pattern: BreathingPattern.box,
        completedCycles: 2,
      );
      harness.snapshot = BreathingSnapshot(sessions: [first, second]);
      await model.load();
      expect(model.history.map((session) => session.id), ['second', 'first']);
    });

    test(
      'should update post-rating on the same record without duplication',
      () async {
        await harness.start(rating: 8);
        model.end();
        await model.retryResultSave();
        final id = model.result!.id;
        await model.updateAfterRating(4);
        expect(model.result!.id, id);
        expect(model.result!.revision, 1);
        expect(model.history, hasLength(1));
        expect(model.history.single.stressAfter, 4);
        await model.updateAfterRating(null);
        expect(model.history.single.stressAfter, isNull);
        expect(model.history.single.stressBefore, 8);
      },
    );

    test(
      'should reject out-of-range ratings without starting or replacing a record',
      () async {
        await model.load();
        expect(() => model.startPractice(0), throwsArgumentError);
        expect(() => model.startPractice(11), throwsArgumentError);
        expect(model.screen, BreathingScreen.landing);
        model.startPractice(1);
        model.end();
        await model.retryResultSave();
        await expectLater(model.updateAfterRating(11), throwsArgumentError);
        expect(model.result!.stressAfter, isNull);
      },
    );

    test(
      'should keep failed results retryable and block ordinary departure',
      () async {
        await harness.start();
        harness.sessionFailure = true;
        model.end();
        await model.retryResultSave();
        expect(model.error, isA<BreathingStorageException>());
        expect(model.hasUnsavedResult, isTrue);
        expect(model.returnToLanding(), isFalse);
        expect(model.handleBack(), isFalse);
        model.showHistory();
        expect(model.screen, BreathingScreen.result);
        harness.sessionFailure = false;
        await model.retryResultSave();
        expect(model.hasUnsavedResult, isFalse);
        expect(model.history, hasLength(1));
        expect(model.returnToLanding(), isTrue);
      },
    );

    test(
      'should allow explicit leaving without saving after a failed result',
      () async {
        await harness.start();
        harness.sessionFailure = true;
        model.end();
        await model.retryResultSave();
        model.leaveWithoutSaving();
        expect(model.screen, BreathingScreen.landing);
        expect(model.result, isNull);
        expect(model.history, isEmpty);
        expect(model.error, isNull);
      },
    );

    test(
      'should retain a newer rating while the completion save is in flight',
      () async {
        await harness.start();
        final completion = Completer<BreathingSnapshot>();
        var call = 0;
        when(() => harness.repository.saveSession(any())).thenAnswer((
          invocation,
        ) {
          final session =
              invocation.positionalArguments.single as BreathingSession;
          harness.writes.add(session);
          if (call++ == 0) return completion.future;
          return Future.value(harness.commit(session));
        });
        model.end();
        await Future<void>.delayed(Duration.zero);
        final ratingSave = model.updateAfterRating(3);
        expect(model.isSaving, isTrue);
        expect(model.returnToLanding(), isFalse);
        completion.completeError(const BreathingStorageException());
        await ratingSave;
        expect(harness.writes.map((session) => session.revision), [0, 1]);
        expect(model.history.single.stressAfter, 3);
        expect(model.hasUnsavedResult, isFalse);
        await model.retryResultSave();
        expect(harness.writes, hasLength(2));
      },
    );

    test(
      'should retry a synchronous storage failure instead of retaining a completed future',
      () async {
        await harness.start();
        when(
          () => harness.repository.saveSession(any()),
        ).thenThrow(const BreathingStorageException());
        model.end();
        await model.retryResultSave();
        when(() => harness.repository.saveSession(any())).thenAnswer((
          invocation,
        ) async {
          return harness.commit(
            invocation.positionalArguments.single as BreathingSession,
          );
        });
        await model.retryResultSave();
        expect(model.hasUnsavedResult, isFalse);
      },
    );

    test(
      'should finish emergency departure immediately despite a blocked save',
      () async {
        await harness.start();
        harness.advance(const Duration(seconds: 8));
        model.pause();
        final blocked = Completer<BreathingSnapshot>();
        when(() => harness.repository.saveSession(any())).thenAnswer((
          invocation,
        ) {
          harness.writes.add(
            invocation.positionalArguments.single as BreathingSession,
          );
          return blocked.future;
        });
        var notifications = 0;
        model.addListener(() => notifications++);
        model.departForEmergency();
        expect(notifications, 0);
        expect(harness.writes.single.completedCycles, 1);
        harness.advance(const Duration(minutes: 5));
        model.resume();
        expect(model.completedCycles, 1);
        blocked.completeError(const BreathingStorageException());
        await Future<void>.delayed(Duration.zero);
        expect(notifications, 0);
      },
    );

    test(
      'should capture elapsed full cycles on emergency without an intervening tick',
      () async {
        await harness.start();
        harness.elapsed = const Duration(seconds: 49);
        model.departForEmergency();
        await Future<void>.delayed(Duration.zero);
        expect(harness.writes.single.completedCycles, 8);
      },
    );

    test('should ignore load and timer callbacks after disposal', () async {
      final loaded = Completer<BreathingSnapshot>();
      when(harness.repository.load).thenAnswer((_) => loaded.future);
      final load = model.load();
      var notifications = 0;
      model.addListener(() => notifications++);
      model.dispose();
      loaded.complete(const BreathingSnapshot.empty());
      await load;
      model.refresh();
      expect(notifications, 0);
      // Replace the disposed instance for shared cleanup.
      harness = _Harness();
      model = harness.model;
    });

    test(
      'should stop active timing and ignore an in-flight save after disposal',
      () async {
        await harness.start();
        final blocked = Completer<BreathingSnapshot>();
        when(
          () => harness.repository.saveSession(any()),
        ).thenAnswer((_) => blocked.future);
        model.end();
        final saving = model.retryResultSave();
        await Future<void>.delayed(Duration.zero);
        var notifications = 0;
        model.addListener(() => notifications++);
        model.dispose();
        blocked.complete(const BreathingSnapshot.empty());
        await saving;
        expect(notifications, 0);
        harness = _Harness();
        model = harness.model;
      },
    );

    test(
      'should require explicit unreadable-data recovery and preserve read failures',
      () async {
        when(
          harness.repository.load,
        ).thenThrow(const BreathingStorageException(canDiscard: true));
        await model.load();
        expect(model.isReady, isFalse);
        expect(model.canDiscardUnreadable, isTrue);
        model.quickStart();
        expect(model.screen, BreathingScreen.landing);
        verifyNever(harness.repository.discardUnreadableSnapshot);
        await model.discardUnreadableSnapshot();
        expect(model.isReady, isTrue);
        expect(model.canDiscardUnreadable, isFalse);
        expect(model.error, isNull);
      },
    );

    test(
      'should retry a read error without offering destructive recovery',
      () async {
        when(
          harness.repository.load,
        ).thenThrow(const BreathingStorageException());
        await model.load();
        expect(model.canDiscardUnreadable, isFalse);
        await model.discardUnreadableSnapshot();
        verifyNever(harness.repository.discardUnreadableSnapshot);
        when(harness.repository.load).thenAnswer((_) async => harness.snapshot);
        await model.load();
        expect(model.isReady, isTrue);
      },
    );

    test('should navigate information and history back to landing', () async {
      await model.load();
      model.showInfo();
      expect(model.screen, BreathingScreen.info);
      expect(model.handleBack(), isFalse);
      model.showHistory();
      expect(model.screen, BreathingScreen.history);
      expect(model.handleBack(), isFalse);
      model.preparePractice();
      expect(model.handleBack(), isFalse);
      expect(model.handleBack(), isTrue);
    });

    group('customization', () {
      setUp(() async {
        await model.load();
        model.openCustomization();
      });

      test(
        'should save only after three steps and retain skipped saved values',
        () async {
          model.setBackground(BreathingBackground.beach);
          await model.nextCustomizationStep();
          expect(model.customizationStep, 1);
          model.adjustDuration(inhale: true, delta: 4);
          await model.skipCustomizationStep();
          expect(model.customizationStep, 2);
          expect(
            model.draftSettings.inhaleDuration,
            const Duration(seconds: 3),
          );
          verifyNever(() => harness.repository.saveSettings(any()));
          model.adjustDuration(inhale: false, delta: 3);
          await model.nextCustomizationStep();
          expect(model.screen, BreathingScreen.landing);
          expect(model.settings.background, BreathingBackground.beach);
          expect(model.settings.exhaleDuration, const Duration(seconds: 6));
        },
      );

      test(
        'should clamp measured holds to 3–9 seconds and cancel interrupted gestures',
        () async {
          await model.nextCustomizationStep();
          model.beginDurationMeasurement(inhale: true);
          harness.advance(const Duration(milliseconds: 200));
          expect(model.isMeasuring, isTrue);
          model.finishDurationMeasurement();
          expect(
            model.draftSettings.inhaleDuration,
            const Duration(seconds: 3),
          );
          model.beginDurationMeasurement(inhale: true);
          harness.advance(const Duration(milliseconds: 4250));
          model.finishDurationMeasurement();
          expect(
            model.draftSettings.inhaleDuration,
            const Duration(milliseconds: 4250),
          );
          model.beginDurationMeasurement(inhale: true);
          harness.advance(const Duration(seconds: 10));
          expect(model.isMeasuring, isFalse);
          expect(model.measuredDuration, const Duration(seconds: 9));
          expect(
            model.draftSettings.inhaleDuration,
            const Duration(seconds: 9),
          );
          model.beginDurationMeasurement(inhale: true);
          harness.advance(const Duration(seconds: 4));
          model.handleAppInactive();
          model.finishDurationMeasurement();
          expect(
            model.draftSettings.inhaleDuration,
            const Duration(seconds: 9),
          );
          expect(model.isMeasuring, isFalse);
        },
      );

      test(
        'should measure exhale and bound accessible one-second adjustments',
        () async {
          model.adjustDuration(inhale: true, delta: -1);
          expect(
            model.draftSettings.inhaleDuration,
            const Duration(seconds: 3),
          );
          model.adjustDuration(inhale: true, delta: 20);
          expect(
            model.draftSettings.inhaleDuration,
            const Duration(seconds: 9),
          );
          model.adjustDuration(inhale: true, delta: -1);
          expect(
            model.draftSettings.inhaleDuration,
            const Duration(seconds: 8),
          );
          model.beginDurationMeasurement(inhale: false);
          harness.advance(const Duration(seconds: 6));
          model.finishDurationMeasurement();
          expect(
            model.draftSettings.exhaleDuration,
            const Duration(seconds: 6),
          );
        },
      );

      test(
        'should preserve draft on save failure and retry from the final step',
        () async {
          model.setBackground(BreathingBackground.monastery);
          await model.nextCustomizationStep();
          await model.nextCustomizationStep();
          harness.settingsFailure = true;
          await model.nextCustomizationStep();
          expect(model.screen, BreathingScreen.customize);
          expect(model.customizationStep, 2);
          expect(model.error, isA<BreathingStorageException>());
          expect(model.settings.background, BreathingBackground.forest);
          expect(model.draftSettings.background, BreathingBackground.monastery);
          harness.settingsFailure = false;
          await model.nextCustomizationStep();
          expect(model.settings.background, BreathingBackground.monastery);
        },
      );

      test(
        'should preserve previous photo on cancel/failure and discard a skipped new photo',
        () async {
          final photo = await _photoFixture();
          when(harness.photoImporter.pickPhoto).thenAnswer((_) async => photo);
          await model.importPhoto();
          expect(model.draftSettings.background, BreathingBackground.personal);
          when(harness.photoImporter.pickPhoto).thenAnswer((_) async => null);
          await model.importPhoto();
          expect(model.draftSettings.personalPhotoBase64, photo);
          when(
            harness.photoImporter.pickPhoto,
          ).thenThrow(const BreathingPhotoException());
          await model.importPhoto();
          expect(model.draftSettings.personalPhotoBase64, photo);
          expect(model.error, isA<BreathingPhotoException>());
          await model.skipCustomizationStep();
          expect(model.draftSettings.background, BreathingBackground.forest);
          expect(model.draftSettings.personalPhotoBase64, isNull);
        },
      );

      test(
        'should ignore photo selection after leaving its customization visit',
        () async {
          final pending = Completer<String?>();
          when(
            harness.photoImporter.pickPhoto,
          ).thenAnswer((_) => pending.future);
          final importing = model.importPhoto();
          expect(model.isImporting, isTrue);
          model.previousCustomizationStep();
          expect(model.screen, BreathingScreen.landing);
          pending.complete(await _photoFixture());
          await importing;
          model.openCustomization();
          expect(model.draftSettings.background, BreathingBackground.forest);
          expect(model.isImporting, isFalse);
        },
      );

      test(
        'should return through customization steps before leaving the wizard',
        () async {
          model.setBackground(BreathingBackground.personal);
          expect(model.draftSettings.background, BreathingBackground.forest);
          await model.nextCustomizationStep();
          await model.nextCustomizationStep();
          expect(model.handleBack(), isFalse);
          expect(model.customizationStep, 1);
          expect(model.handleBack(), isFalse);
          expect(model.customizationStep, 0);
          expect(model.handleBack(), isFalse);
          expect(model.screen, BreathingScreen.landing);
        },
      );
    });
  });
}
