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
  Future<dynamic> getItem(String key, PersistentMemoryType type) async => value;

  @override
  Future<void> reset() async {}

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {}
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
    test('should treat only an exact empty string as a missing snapshot', () async {
      final MoodMedicineLoadResult missing = await MoodMedicineStore(
        _ValueMemoryService(''),
      ).loadSnapshot();
      final MoodMedicineLoadResult whitespace = await MoodMedicineStore(
        _ValueMemoryService(' '),
      ).loadSnapshot();

      expect(missing, isA<MoodMedicineMissingSnapshot>());
      expect(whitespace, isA<MoodMedicineUnreadableSnapshot>());
    });

    test('should return typed recovery outcomes for null and wrong values', () async {
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
    });

    test('should reject malformed and unsupported envelopes without writing', () async {
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
    });

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
  });
}
