import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_photo_importer.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_store.dart';
import 'package:mazilon/pages/breathing_page.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_model.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_state.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/async/app_theme.dart';

import '../../../helpers/widget_test_scaffold.dart';
import '../../../../test_support/contract_persistent_memory_service.dart';

final class _Harness {
  _Harness({String? stored}) {
    memory = ContractPersistentMemoryService(
      exposePendingWrites: false,
      initialValues: {BreathingStore.snapshotKey: ?stored},
    );
    store = BreathingStore(memory);
    model = BreathingViewModel(
      store,
      photoImporter: BreathingPhotoImporter(NoopImagePickerService()),
      monotonicElapsed: () => elapsed,
      now: () => DateTime.utc(2026, 9, 13, 12).add(elapsed),
      sessionId: () => 'attempt-${++ids}',
    );
  }

  late final ContractPersistentMemoryService memory;
  late final BreathingStore store;
  late final BreathingViewModel model;
  Duration elapsed = Duration.zero;
  int ids = 0;

  Future<void> advance(WidgetTester tester, Duration duration) async {
    elapsed += duration;
    model.refresh();
    await tester.pump();
    await tester.pump();
  }

  Future<void> pump(
    WidgetTester tester, {
    String locale = 'en',
    Size size = const Size(420, 900),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        theme: buildLightTheme(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: BreathingPage(viewModel: model)),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find
          .descendant(
            of: find.byType(BreathingPage),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 20,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump();
}

AppLocalizations _strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(BreathingPage)))!;

void main() {
  group('BreathingPage', () {
    testWidgets(
      'should preserve a five-second duration when scrolling across measurement',
      (tester) async {
        final harness = _Harness(
          stored: BreathingSnapshot(
            settings: const BreathingSettings(
              inhaleDuration: Duration(seconds: 5),
            ),
          ).encode(),
        );
        await harness.pump(tester, size: const Size(320, 620), scale: 1.8);
        await _tap(tester, 'breathingCustomize');
        await _tap(tester, 'breathingNextStep');
        await tester.ensureVisible(find.byKey(const Key('breathingMeasure')));
        await tester.drag(
          find.byKey(const Key('breathingMeasure')),
          const Offset(0, -90),
        );
        await tester.pump();
        expect(
          harness.model.draftSettings.inhaleDuration,
          const Duration(seconds: 5),
        );
        expect(harness.model.isMeasuring, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
    for (final locale in ['en', 'he', 'ar']) {
      testWidgets(
        'should support $locale at 320px with enlarged text and no default rating',
        (tester) async {
          final harness = _Harness();
          await harness.pump(
            tester,
            locale: locale,
            size: const Size(320, 740),
            scale: 1.8,
          );
          final context = tester.element(find.byType(BreathingPage));
          expect(
            Directionality.of(context),
            locale == 'en' ? TextDirection.ltr : TextDirection.rtl,
          );
          expect(find.text(_strings(tester).breathingTitle), findsOneWidget);
          await _tap(tester, 'breathingQuickStart');
          await tester.scrollUntilVisible(
            find.byKey(const Key('breathingStartRated')),
            150,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const Key('breathingStartRated')),
                )
                .onPressed,
            isNull,
          );
          expect(
            tester
                .widget<ChoiceChip>(find.byKey(const Key('breathingBefore1')))
                .selected,
            isFalse,
          );
          await _tap(tester, 'breathingSkipRating');
          expect(find.text(_strings(tester).breathingCycle(1)), findsOneWidget);
          await _tap(tester, 'breathingPause');
          expect(find.text(_strings(tester).breathingPaused), findsOneWidget);
          await _tap(tester, 'breathingContinue');
          await harness.advance(tester, const Duration(seconds: 48));
          expect(harness.model.screen, BreathingScreen.result);
          expect(
            find.text(_strings(tester).breathingCompleteMessage),
            findsOneWidget,
          );
          await _tap(tester, 'breathingDone');
          final saved = (await harness.store.load()).sessions.single;
          expect(saved.isComplete, isTrue);
          expect(saved.stressBefore, isNull);
          expect(saved.stressAfter, isNull);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'should preserve exact Hebrew guidance and credit on the info screen',
      (tester) async {
        final harness = _Harness();
        await harness.pump(tester, locale: 'he');
        await _tap(tester, 'breathingInfo');
        const guidance =
            'בפעמים הראשונות, מומלץ מאוד לתרגל בשכיבה או בישיבה נינוחה. הניחו בעדינות יד אחת על הבטן ויד שנייה על החזה, והרגישו כיצד היד שעל הבטן עולה בשאיפה ושוקעת בנשיפה.';
        const credit =
            "התרגול 'לזכור לנשום' פותח בהשראת אפליקציית Breathe2Relax מבית ה-T2 / משרד הביטחון האמריקאי (US Department of Defense). הפיצ'ר נשען על פרוטוקולים מחקריים לוויסות המערכת הפיזיולוגית, בשילוב תובנות וליווי של מומחים מניסיון אישי בשטח בתחום בריאות הנפש והשיקום, לחיזוק החוסן הנפשי באפליקציית Living Positively.";
        expect(_strings(tester).breathingGuidance, guidance);
        expect(_strings(tester).breathingCredits, credit);
        expect(find.text(guidance), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text(credit),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(credit), findsOneWidget);
        await _tap(tester, 'breathingBack');
        expect(find.byKey(const Key('breathingQuickStart')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should offer every preset and retain saved values when all three steps are skipped',
      (tester) async {
        final harness = _Harness(
          stored: BreathingSnapshot(
            settings: const BreathingSettings(
              background: BreathingBackground.beach,
              inhaleDuration: Duration(seconds: 5),
              exhaleDuration: Duration(seconds: 7),
            ),
          ).encode(),
        );
        await harness.pump(tester);
        await _tap(tester, 'breathingCustomize');
        for (final name in [
          'forest',
          'mountains',
          'cosmos',
          'beach',
          'flowers',
          'sunset',
          'house',
          'monastery',
        ]) {
          await _tap(tester, 'breathingBackground$name');
        }
        await _tap(tester, 'breathingSkipStep');
        expect(find.text(_strings(tester).breathingStep(2)), findsOneWidget);
        await _tap(tester, 'breathingInhaleIncrease');
        await _tap(tester, 'breathingSkipStep');
        expect(find.text(_strings(tester).breathingStep(3)), findsOneWidget);
        await _tap(tester, 'breathingExhaleDecrease');
        await _tap(tester, 'breathingSkipStep');
        final settings = (await harness.store.load()).settings;
        expect(settings.background, BreathingBackground.beach);
        expect(settings.inhaleDuration, const Duration(seconds: 5));
        expect(settings.exhaleDuration, const Duration(seconds: 7));
        expect(harness.model.screen, BreathingScreen.landing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should save measured durations and apply custom adjustments at the next matching phase',
      (tester) async {
        final harness = _Harness();
        await harness.pump(tester);
        await _tap(tester, 'breathingCustomize');
        await _tap(tester, 'breathingBackgroundsunset');
        await _tap(tester, 'breathingNextStep');
        await tester.ensureVisible(find.byKey(const Key('breathingMeasure')));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('breathingMeasure'))),
        );
        await harness.advance(tester, const Duration(seconds: 4));
        await gesture.up();
        await tester.pump();
        await _tap(tester, 'breathingInhaleIncrease');
        await _tap(tester, 'breathingInhaleDecrease');
        await _tap(tester, 'breathingNextStep');
        await tester.ensureVisible(find.byKey(const Key('breathingMeasure')));
        final exhale = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('breathingMeasure'))),
        );
        await harness.advance(tester, const Duration(seconds: 10));
        expect(harness.model.isMeasuring, isFalse);
        await exhale.up();
        await tester.pump();
        await _tap(tester, 'breathingNextStep');
        expect(
          (await harness.store.load()).settings.exhaleDuration,
          const Duration(seconds: 9),
        );
        await _tap(tester, 'breathingPatterncustom');
        await _tap(tester, 'breathingStartSelected');
        await _tap(tester, 'breathingBefore7');
        await _tap(tester, 'breathingStartRated');
        await _tap(tester, 'breathingLiveInhaleIncrease');
        await harness.advance(tester, const Duration(seconds: 4));
        expect(harness.model.phase, BreathingPhase.exhale);
        await harness.advance(tester, const Duration(seconds: 9));
        await harness.advance(tester, const Duration(seconds: 4));
        expect(harness.model.phase, BreathingPhase.inhale);
        await harness.advance(tester, const Duration(seconds: 1));
        expect(harness.model.phase, BreathingPhase.exhale);
        await _tap(tester, 'breathingPause');
        await _tap(tester, 'breathingEnd');
        final saved = (await harness.store.load()).sessions.single;
        expect(saved.pattern, BreathingPattern.custom);
        expect(saved.stressBefore, 7);
        expect(saved.completedCycles, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should render box holds and keep timing independent of hidden cues',
      (tester) async {
        final harness = _Harness();
        await harness.pump(tester);
        await _tap(tester, 'breathingPatternbox');
        await _tap(tester, 'breathingStartSelected');
        await _tap(tester, 'breathingSkipRating');
        await harness.advance(tester, const Duration(seconds: 4));
        expect(find.text(_strings(tester).breathingHold), findsOneWidget);
        final holdScale = tester
            .widget<Transform>(find.byKey(const Key('breathingCircle')))
            .transform;
        await harness.advance(tester, const Duration(seconds: 2));
        expect(
          tester
              .widget<Transform>(find.byKey(const Key('breathingCircle')))
              .transform,
          holdScale,
        );
        await _tap(tester, 'breathingToggleCircle');
        await _tap(tester, 'breathingToggleText');
        expect(find.byKey(const Key('breathingCircle')), findsNothing);
        expect(find.byKey(const Key('breathingPhase')), findsNothing);
        await _tap(tester, 'breathingToggleControls');
        expect(find.byKey(const Key('breathingToggleCircle')), findsNothing);
        await _tap(tester, 'breathingToggleControls');
        await harness.advance(tester, const Duration(seconds: 122));
        expect((await harness.store.load()).sessions.single.completedCycles, 8);
        expect(
          (await harness.store.load()).sessions.single.pattern,
          BreathingPattern.box,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should pause on back and inactivity, restart, and save neutral history',
      (tester) async {
        final harness = _Harness();
        await harness.pump(tester);
        await _tap(tester, 'breathingQuickStart');
        await _tap(tester, 'breathingBefore8');
        await _tap(tester, 'breathingStartRated');
        await harness.advance(tester, const Duration(seconds: 6));
        await _tap(tester, 'breathingBack');
        expect(harness.model.isPaused, isTrue);
        await harness.advance(tester, const Duration(seconds: 30));
        expect(harness.model.completedCycles, 1);
        await _tap(tester, 'breathingRestart');
        expect(harness.model.completedCycles, 0);
        expect((await harness.store.load()).sessions, isEmpty);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(harness.model.isPaused, isTrue);
        await _tap(tester, 'breathingContinue');
        await harness.advance(tester, const Duration(seconds: 12));
        await _tap(tester, 'breathingPause');
        await _tap(tester, 'breathingEnd');
        await _tap(tester, 'breathingAfter3');
        await _tap(tester, 'breathingDone');
        await _tap(tester, 'breathingHistory');
        expect(
          find.text(_strings(tester).breathingCompletedCycles(2)),
          findsOneWidget,
        );
        expect(
          find.text('${_strings(tester).breathingBefore}: 8 / 10'),
          findsOneWidget,
        );
        expect(
          find.text('${_strings(tester).breathingAfter}: 3 / 10'),
          findsOneWidget,
        );
        final saved = (await harness.store.load()).sessions.single;
        expect(saved.id, 'attempt-2');
        expect(saved.stressAfter, 3);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('should keep failed results until retry or explicit leave', (
      tester,
    ) async {
      final harness = _Harness();
      await harness.pump(tester);
      harness.memory.onPersist = (key, _, _) {
        if (key == BreathingStore.snapshotKey) throw StateError('full');
      };
      await _tap(tester, 'breathingQuickStart');
      await _tap(tester, 'breathingSkipRating');
      await harness.advance(tester, const Duration(seconds: 48));
      expect(find.byKey(const Key('breathingRetrySave')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('breathingDone')))
            .onPressed,
        isNull,
      );
      await _tap(tester, 'breathingDone');
      expect(harness.model.screen, BreathingScreen.result);
      await _tap(tester, 'breathingAfter4');
      harness.memory.onPersist = null;
      await _tap(tester, 'breathingRetrySave');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('breathingDone')))
            .onPressed,
        isNotNull,
      );
      await _tap(tester, 'breathingDone');
      expect((await harness.store.load()).sessions.single.stressAfter, 4);
      await _tap(tester, 'breathingQuickStart');
      await _tap(tester, 'breathingSkipRating');
      harness.memory.onPersist = (_, _, _) => throw StateError('full');
      await _tap(tester, 'breathingPause');
      await _tap(tester, 'breathingBack');
      expect(harness.model.screen, BreathingScreen.result);
      await _tap(tester, 'breathingBack');
      expect(harness.model.screen, BreathingScreen.result);
      await _tap(tester, 'breathingLeaveWithoutSaving');
      expect(harness.model.screen, BreathingScreen.landing);
      expect((await harness.store.load()).sessions, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should require explicit confirmation to discard corrupt history',
      (tester) async {
        final harness = _Harness(stored: '{unreadable private history');
        await harness.pump(tester);
        expect(find.byKey(const Key('breathingQuickStart')), findsNothing);
        await _tap(tester, 'breathingRetryLoad');
        expect(
          harness.memory.store[BreathingStore.snapshotKey],
          '{unreadable private history',
        );
        await _tap(tester, 'breathingDiscard');
        expect(harness.memory.completedWrites, isEmpty);
        await _tap(tester, 'breathingConfirmDiscard');
        expect(find.byKey(const Key('breathingQuickStart')), findsOneWidget);
        expect((await harness.store.load()).sessions, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should show newest-first history and explicitly missing ratings',
      (tester) async {
        final harness = _Harness();
        final older = BreathingSession(
          id: 'older',
          startedAt: DateTime.utc(2026, 9, 12),
          endedAt: DateTime.utc(2026, 9, 12, 0, 1),
          pattern: BreathingPattern.box,
          completedCycles: 8,
          stressBefore: 6,
          stressAfter: 6,
        );
        final newer = BreathingSession(
          id: 'newer',
          startedAt: DateTime.utc(2026, 9, 13),
          endedAt: DateTime.utc(2026, 9, 13, 0, 1),
          pattern: BreathingPattern.basic,
          completedCycles: 0,
        );
        await harness.store.saveSession(older);
        await harness.store.saveSession(newer);
        await harness.pump(tester);
        await _tap(tester, 'breathingHistory');
        final strings = _strings(tester);
        expect(
          find.text('${strings.breathingBefore}: ${strings.breathingNoRating}'),
          findsOneWidget,
        );
        expect(
          find.text('${strings.breathingAfter}: ${strings.breathingNoRating}'),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(find.text(strings.breathingBasic)).dy,
          lessThan(tester.getTopLeft(find.text(strings.breathingBox)).dy),
        );
        expect(find.text('${strings.breathingBefore}: 6 / 10'), findsOneWidget);
        expect(find.text('${strings.breathingAfter}: 6 / 10'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
