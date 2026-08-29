import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_repository.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_store.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

import '../../test_support/contract_persistent_memory_service.dart';

final class _ValueMemoryService implements PersistentMemoryService {
  _ValueMemoryService(this.value);

  final Object? value;

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    _assertMoodMedicineSnapshotAccess(key, type);
    return value;
  }

  @override
  Future<void> reset() async {}

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    _assertMoodMedicineSnapshotAccess(key, type);
  }

  void _assertMoodMedicineSnapshotAccess(
    String key,
    PersistentMemoryType type,
  ) {
    if (key != MoodMedicineStore.snapshotKey ||
        type != PersistentMemoryType.String) {
      throw StateError('Unexpected Mood Medicine persistence access.');
    }
  }
}

String _validSnapshot() {
  return jsonEncode(<String, Object>{
    'version': moodMedicineSnapshotVersion,
    'hiddenDefaultActivityIds': <String>[],
    'customActivities': <Object>[],
    'entries': <Object>[],
  });
}

void main() {
  group('MoodMedicineStore', () {
    test(
      'should treat only an exact empty string as a missing snapshot',
      () async {
        final MoodMedicineLoadResult missing = await MoodMedicineStore(
          _ValueMemoryService(''),
        ).loadSnapshot();
        final MoodMedicineLoadResult whitespace = await MoodMedicineStore(
          _ValueMemoryService(' '),
        ).loadSnapshot();

        expect(missing, isA<MoodMedicineMissingSnapshot>());
        expect(whitespace, isA<MoodMedicineUnreadableSnapshot>());
      },
    );

    test(
      'should return typed recovery outcomes for null and wrong values',
      () async {
        final MoodMedicineLoadResult nullResult = await MoodMedicineStore(
          _ValueMemoryService(null),
        ).loadSnapshot();
        final MoodMedicineLoadResult wrongTypeResult = await MoodMedicineStore(
          _ValueMemoryService(42),
        ).loadSnapshot();

        expect(
          (nullResult as MoodMedicineUnreadableSnapshot).failure.kind,
          MoodMedicineLoadFailureKind.nullValue,
        );
        expect(
          (wrongTypeResult as MoodMedicineUnreadableSnapshot).failure.kind,
          MoodMedicineLoadFailureKind.wrongValueType,
        );
      },
    );

    test(
      'should reject malformed and unsupported envelopes without writing',
      () async {
        final ContractPersistentMemoryService malformedMemory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: '{not json',
              },
            );
        final ContractPersistentMemoryService unsupportedMemory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: jsonEncode(<String, Object>{
                  'version': moodMedicineSnapshotVersion + 1,
                  'hiddenDefaultActivityIds': <String>[],
                  'customActivities': <Object>[],
                  'entries': <Object>[],
                }),
              },
            );

        final MoodMedicineLoadResult malformed = await MoodMedicineStore(
          malformedMemory,
        ).loadSnapshot();
        final MoodMedicineLoadResult unsupported = await MoodMedicineStore(
          unsupportedMemory,
        ).loadSnapshot();

        expect(
          (malformed as MoodMedicineUnreadableSnapshot).failure.kind,
          MoodMedicineLoadFailureKind.malformedEnvelope,
        );
        expect(
          (unsupported as MoodMedicineUnreadableSnapshot).failure.kind,
          MoodMedicineLoadFailureKind.unsupportedVersion,
        );
        expect(malformedMemory.attemptedWrites, isEmpty);
        expect(unsupportedMemory.attemptedWrites, isEmpty);
      },
    );

    test('should strictly load a complete version-one envelope', () async {
      final MoodMedicineLoadResult result = await MoodMedicineStore(
        _ValueMemoryService(_validSnapshot()),
      ).loadSnapshot();

      expect(result, isA<MoodMedicineLoadedSnapshot>());
      expect(
        (result as MoodMedicineLoadedSnapshot).snapshot.version,
        moodMedicineSnapshotVersion,
      );
    });

    test(
      'should serialize mutations onto the latest committed snapshot',
      () async {
        // A direct read is allowed to return the older durable value while a
        // write is pending; without MoodMedicineStore's own queue this test
        // would persist only the second entry.
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(exposePendingWrites: false);
        final MoodMedicineStore store = MoodMedicineStore(memory);
        final Completer<void> firstWriteStarted = Completer<void>();
        final Completer<void> allowFirstWrite = Completer<void>();
        var snapshotWriteCount = 0;
        memory.onPersist = (String key, _, Object _) async {
          if (key != MoodMedicineStore.snapshotKey ||
              snapshotWriteCount++ > 0) {
            return;
          }
          firstWriteStarted.complete();
          await allowFirstWrite.future;
        };

        final Future<MoodMedicineLoadResult> first = store.mutateSnapshot(
          (MoodMedicineSnapshot current) => current.copyWith(
            entries: <MoodMedicineEntry>[
              ...current.entries,
              MoodMedicineEntry(
                id: 'first',
                occurredAtUtc: DateTime.utc(2026, 8, 29, 8),
                localDayKey: '2026-08-29',
                mood: 2,
              ),
            ],
          ),
        );
        await firstWriteStarted.future;
        final Future<MoodMedicineLoadResult> second = store.mutateSnapshot(
          (MoodMedicineSnapshot current) => current.copyWith(
            entries: <MoodMedicineEntry>[
              ...current.entries,
              MoodMedicineEntry(
                id: 'second',
                occurredAtUtc: DateTime.utc(2026, 8, 29, 9),
                localDayKey: '2026-08-29',
                mood: 5,
              ),
            ],
          ),
        );
        allowFirstWrite.complete();
        final List<MoodMedicineLoadResult> results =
            await Future.wait<MoodMedicineLoadResult>(
              <Future<MoodMedicineLoadResult>>[first, second],
            );

        expect(
          (results.first as MoodMedicineLoadedSnapshot).snapshot.entries,
          hasLength(1),
        );
        expect(
          (results.last as MoodMedicineLoadedSnapshot).snapshot.entries.map(
            (MoodMedicineEntry entry) => entry.id,
          ),
          <String>['first', 'second'],
        );
        expect(
          memory.completedWrites.where(
            (write) => write.key == MoodMedicineStore.snapshotKey,
          ),
          hasLength(2),
        );
        expect(
          memory.completedWrites
              .where((write) => write.key == MoodMedicineStore.snapshotKey)
              .every((write) => write.type == PersistentMemoryType.String),
          isTrue,
        );
      },
    );

    test(
      'should not overwrite unreadable history with a normal mutation',
      () async {
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: '{unreadable',
              },
            );
        final MoodMedicineStore store = MoodMedicineStore(memory);
        var mutationWasCalled = false;

        final MoodMedicineLoadResult result = await store.mutateSnapshot((
          MoodMedicineSnapshot current,
        ) {
          mutationWasCalled = true;
          return current;
        });

        expect(result, isA<MoodMedicineUnreadableSnapshot>());
        expect(mutationWasCalled, isFalse);
        expect(memory.attemptedWrites, isEmpty);
        expect(memory.store[MoodMedicineStore.snapshotKey], '{unreadable');
      },
    );

    test(
      'should preserve a valid snapshot when a queued discard rechecks it',
      () async {
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: '{unreadable',
              },
            );
        final MoodMedicineStore store = MoodMedicineStore(memory);
        final Completer<void> firstWriteStarted = Completer<void>();
        final Completer<void> allowFirstWrite = Completer<void>();
        var snapshotWriteCount = 0;
        memory.onPersist = (String key, _, Object _) async {
          if (key != MoodMedicineStore.snapshotKey ||
              snapshotWriteCount++ > 0) {
            return;
          }
          firstWriteStarted.complete();
          await allowFirstWrite.future;
        };

        final Future<MoodMedicineLoadResult> first = store
            .discardUnreadableSnapshot();
        await firstWriteStarted.future;
        final Future<MoodMedicineLoadResult> second = store
            .discardUnreadableSnapshot();
        allowFirstWrite.complete();
        final List<MoodMedicineLoadResult> results =
            await Future.wait<MoodMedicineLoadResult>(
              <Future<MoodMedicineLoadResult>>[first, second],
            );

        expect(results, everyElement(isA<MoodMedicineLoadedSnapshot>()));
        expect(
          memory.completedWrites.where(
            (write) => write.key == MoodMedicineStore.snapshotKey,
          ),
          hasLength(1),
        );
      },
    );
  });
}
