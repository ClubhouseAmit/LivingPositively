import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_repository.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_store.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

import '../../../../test_support/contract_persistent_memory_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('BreathingStore', () {
    late _Memory memory;
    late BreathingStore store;

    setUp(() {
      memory = _Memory();
      store = BreathingStore(memory);
    });

    test(
      'should save settings and history together and reload after reset',
      () async {
        await store.saveSettings(const BreathingSettings(showText: false));
        await store.saveSession(_session('first', cycles: 8));
        final loaded = await BreathingStore(memory).load();
        expect(loaded.settings.showText, isFalse);
        expect(loaded.sessions.single.isComplete, isTrue);
        expect(memory.keys, everyElement(BreathingStore.snapshotKey));
        await memory.reset();
        final reset = await store.load();
        expect(reset.sessions, isEmpty);
        expect(reset.settings.showText, isTrue);
      },
    );

    test(
      'should serialize concurrent writes and reads onto committed data',
      () async {
        final writeStarted = Completer<void>();
        final allowWrite = Completer<void>();
        memory.onWrite = () async {
          writeStarted.complete();
          await allowWrite.future;
          memory.onWrite = null;
        };
        final first = store.saveSession(_session('first'));
        await writeStarted.future;
        final second = store.saveSession(_session('second', offset: 1));
        final settings = store.saveSettings(
          const BreathingSettings(showCircle: false),
        );
        final read = store.load();
        expect(memory.writes, 1);
        allowWrite.complete();
        await Future.wait([first, second, settings]);
        final loaded = await read;
        expect(loaded.sessions.map((session) => session.id), [
          'second',
          'first',
        ]);
        expect(loaded.settings.showCircle, isFalse);
      },
    );

    test(
      'should upsert ratings once and reject older or duplicate retries',
      () async {
        final attempt = _session('first', cycles: 8);
        await store.saveSession(attempt);
        await store.saveSession(attempt.copyWith(stressAfter: 4, revision: 1));
        await store.saveSession(attempt);
        await store.saveSession(attempt.copyWith(stressAfter: 9, revision: 1));
        final snapshot = await store.load();
        expect(snapshot.sessions, hasLength(1));
        expect(snapshot.sessions.single.stressAfter, 4);
        expect(snapshot.sessions.single.revision, 1);
        expect(memory.writes, 2);
      },
    );

    test('should preserve missing ratings on an explicit early stop', () async {
      final snapshot = await store.saveSession(_session('partial', cycles: 2));
      expect(snapshot.sessions.single.completedCycles, 2);
      expect(snapshot.sessions.single.isComplete, isFalse);
      expect(snapshot.sessions.single.stressBefore, isNull);
      expect(snapshot.sessions.single.stressAfter, isNull);
    });

    test(
      'should retry a failed save without losing later ratings or duplicating',
      () async {
        memory.onWrite = () async => throw StateError('private data');
        final attempt = _session('attempt', cycles: 8);
        await expectLater(
          store.saveSession(attempt),
          throwsA(_storageFailure(false)),
        );
        expect(memory.value, '');
        memory.onWrite = null;
        await store.saveSession(attempt.copyWith(stressAfter: 2, revision: 1));
        final snapshot = await store.saveSession(attempt);
        expect(snapshot.sessions, hasLength(1));
        expect(snapshot.sessions.single.stressAfter, 2);
      },
    );

    test(
      'should preserve previous photo settings if a replacement cannot save',
      () async {
        final firstPhoto = await _pngPhoto(const ui.Color(0xff336633));
        final secondPhoto = await _pngPhoto(const ui.Color(0xff663333));
        final previous = BreathingSettings(
          background: BreathingBackground.personal,
          personalPhotoBase64: firstPhoto,
        );
        await store.saveSettings(previous);
        memory.onWrite = () async => throw StateError('storage full');
        await expectLater(
          store.saveSettings(
            previous.copyWith(personalPhotoBase64: secondPhoto),
          ),
          throwsA(_storageFailure(false)),
        );
        memory.onWrite = null;
        expect(
          (await store.load()).settings.background,
          BreathingBackground.personal,
        );
        expect((await store.load()).settings.personalPhotoBase64, firstPhoto);
        await store.saveSettings(
          previous.copyWith(personalPhotoBase64: secondPhoto),
        );
        final reloaded = await BreathingStore(memory).load();
        expect(reloaded.settings.personalPhotoBase64, secondPhoto);
        expect(memory.value.toString(), isNot(contains(firstPhoto)));
        await memory.reset();
        expect((await store.load()).settings.personalPhotoBase64, isNull);
      },
    );

    test(
      'should treat only the exact empty string as an absent snapshot',
      () async {
        expect((await store.load()).sessions, isEmpty);
        for (final invalid in [
          null,
          7,
          true,
          ' ',
          '{private',
          '{"version":2}',
        ]) {
          memory.value = invalid;
          await expectLater(store.load(), throwsA(_storageFailure(true)));
          await expectLater(
            store.saveSession(_session('first')),
            throwsA(_storageFailure(true)),
          );
          await expectLater(
            store.saveSettings(const BreathingSettings()),
            throwsA(_storageFailure(true)),
          );
          expect(memory.value, invalid);
        }
        expect(memory.writes, 0);
      },
    );

    test(
      'should never discard or overwrite data after a transient read failure',
      () async {
        memory.readError = StateError('private platform message');
        await expectLater(store.load(), throwsA(_storageFailure(false)));
        await expectLater(
          store.saveSettings(const BreathingSettings()),
          throwsA(_storageFailure(false)),
        );
        await expectLater(
          store.discardUnreadableSnapshot(),
          throwsA(_storageFailure(false)),
        );
        expect(memory.writes, 0);
        memory.readError = null;
        expect((await store.load()).sessions, isEmpty);
      },
    );

    test(
      'should allow explicit recovery only while latest snapshot is unreadable',
      () async {
        memory.value = '{unreadable';
        await expectLater(store.load(), throwsA(_storageFailure(true)));
        await store.discardUnreadableSnapshot();
        expect(memory.writes, 1);
        await store.saveSession(_session('new'));
        final recovered = await store.discardUnreadableSnapshot();
        expect(recovered.sessions.single.id, 'new');
        expect(memory.writes, 2);
      },
    );

    test(
      'should recheck queued recovery instead of discarding newly valid data',
      () async {
        memory.value = '{unreadable';
        final writeStarted = Completer<void>();
        final allowWrite = Completer<void>();
        memory.onWrite = () async {
          writeStarted.complete();
          await allowWrite.future;
        };
        final first = store.discardUnreadableSnapshot();
        await writeStarted.future;
        final second = store.discardUnreadableSnapshot();
        allowWrite.complete();
        await Future.wait([first, second]);
        expect(memory.writes, 1);
      },
    );

    test('should retain unreadable data when recovery writing fails', () async {
      memory.value = '{unreadable';
      memory.onWrite = () async => throw StateError('full');
      await expectLater(
        store.discardUnreadableSnapshot(),
        throwsA(_storageFailure(false)),
      );
      expect(memory.value, '{unreadable');
      memory.onWrite = null;
      expect((await store.discardUnreadableSnapshot()).sessions, isEmpty);
    });

    test('should expose no raw data in storage exception text', () {
      expect(
        const BreathingStorageException().toString(),
        'BreathingStorageException(canDiscard: false)',
      );
    });

    test(
      'should preserve undecodable retained PNGs as unreadable snapshots',
      () async {
        final badPhoto = base64Encode([137, 80, 78, 71, 13, 10, 26, 10]);
        final saved = BreathingSnapshot(
          settings: BreathingSettings(personalPhotoBase64: badPhoto),
          sessions: [_session('private')],
        ).encode();
        memory.value = saved;
        await expectLater(store.load(), throwsA(_storageFailure(true)));
        await expectLater(
          store.saveSession(_session('new')),
          throwsA(_storageFailure(true)),
        );
        expect(memory.value, saved);
        expect(memory.writes, 0);
        await store.discardUnreadableSnapshot();
        expect((await store.load()).sessions, isEmpty);
      },
    );

    test(
      'should reject undecodable replacement before changing a valid snapshot',
      () async {
        await store.saveSession(_session('existing'));
        final original = memory.value;
        await expectLater(
          store.saveSettings(
            BreathingSettings(
              personalPhotoBase64: base64Encode([
                137,
                80,
                78,
                71,
                13,
                10,
                26,
                10,
              ]),
            ),
          ),
          throwsA(_storageFailure(false)),
        );
        expect(memory.value, original);
      },
    );

    test(
      'should invalidate a pending read so reset cannot resurrect history',
      () async {
        final memory = ContractPersistentMemoryService();
        final store = BreathingStore(memory);
        await store.saveSession(_session('old'));
        final reading = Completer<void>();
        final release = Completer<void>();
        memory.onRead = (_, _) async {
          reading.complete();
          await release.future;
        };
        final pending = store.saveSession(_session('resurrected'));
        final rejected = expectLater(pending, throwsA(_storageFailure(false)));
        await reading.future;
        store.invalidatePendingWrites();
        await memory.reset();
        release.complete();
        await rejected;
        memory.onRead = null;
        expect((await store.load()).sessions, isEmpty);
      },
    );

    test(
      'should reject queued writes after accepted writes finish before reset',
      () async {
        final memory = ContractPersistentMemoryService(
          exposePendingWrites: false,
        );
        final store = BreathingStore(memory);
        final writing = Completer<void>();
        final release = Completer<void>();
        memory.onPersist = (_, _, _) async {
          writing.complete();
          await release.future;
        };
        final accepted = store.saveSession(_session('accepted'));
        await writing.future;
        final queued = store.saveSession(_session('queued'));
        final rejected = expectLater(queued, throwsA(_storageFailure(false)));
        store.invalidatePendingWrites();
        final reset = memory.reset();
        release.complete();
        await accepted;
        await reset;
        await rejected;
        expect((await store.load()).sessions, isEmpty);
        expect(memory.completedWrites, hasLength(1));
      },
    );
  });
}

Matcher _storageFailure(bool canDiscard) => isA<BreathingStorageException>()
    .having((error) => error.canDiscard, 'canDiscard', canDiscard);

Future<String> _pngPhoto(ui.Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(color, ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 8);
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    return base64Encode(data.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

BreathingSession _session(String id, {int cycles = 0, int offset = 0}) =>
    BreathingSession(
      id: id,
      startedAt: DateTime.utc(2026, 9, 13, 0, offset),
      endedAt: DateTime.utc(2026, 9, 13, 0, offset + 1),
      pattern: BreathingPattern.basic,
      completedCycles: cycles,
    );

final class _Memory implements PersistentMemoryService {
  Object? value = '';
  Object? readError;
  Future<void> Function()? onWrite;
  int writes = 0;
  final List<String> keys = [];

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    keys.add(key);
    expect(type, PersistentMemoryType.String);
    if (readError case final error?) {
      throw error;
    }
    return value;
  }

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    keys.add(key);
    expect(type, PersistentMemoryType.String);
    writes++;
    await onWrite?.call();
    this.value = value;
  }

  @override
  Future<void> reset() async => value = '';
}
