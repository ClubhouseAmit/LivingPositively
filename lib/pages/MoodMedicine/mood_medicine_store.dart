import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_repository.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

/// Feature-local persistence adapter. A Settings reset clears this key through
/// the existing [PersistentMemoryService] reset contract.
final class MoodMedicineStore implements MoodMedicineRepository {
  /// Creates a store backed by the existing feature-neutral memory service.
  MoodMedicineStore(this._memoryService);

  /// Namespaced key containing the one atomic Mood Medicine v1 snapshot.
  static const String snapshotKey = 'mood_medicine.snapshot.v1';

  final PersistentMemoryService _memoryService;

  /// Loads the local snapshot without converting invalid data into empty data.
  ///
  /// Only an exact empty string is an absent snapshot. A null value, another
  /// type, parser error, unsupported version, or malformed record requires an
  /// explicit feature-only recovery decision in the view model.
  @override
  Future<MoodMedicineLoadResult> loadSnapshot() async {
    final dynamic rawValue;
    try {
      rawValue = await _memoryService.getItem(
        snapshotKey,
        PersistentMemoryType.String,
      );
    } catch (error) {
      return MoodMedicineUnreadableSnapshot(
        MoodMedicineLoadFailure(
          MoodMedicineLoadFailureKind.readError,
          cause: error,
        ),
      );
    }

    if (rawValue is String && rawValue == '') {
      return const MoodMedicineMissingSnapshot();
    }
    if (rawValue == null) {
      return const MoodMedicineUnreadableSnapshot(
        MoodMedicineLoadFailure(MoodMedicineLoadFailureKind.nullValue),
      );
    }
    if (rawValue is! String) {
      return MoodMedicineUnreadableSnapshot(
        MoodMedicineLoadFailure(
          MoodMedicineLoadFailureKind.wrongValueType,
          cause: rawValue.runtimeType,
        ),
      );
    }

    try {
      return MoodMedicineLoadedSnapshot(MoodMedicineSnapshot.decode(rawValue));
    } on MoodMedicineSnapshotDecodeException catch (error) {
      return MoodMedicineUnreadableSnapshot(
        MoodMedicineLoadFailure(
          moodMedicineLoadFailureKindForDecodeFailure(error.failure),
          cause: error.cause ?? error,
        ),
      );
    } catch (error) {
      return MoodMedicineUnreadableSnapshot(
        MoodMedicineLoadFailure(
          MoodMedicineLoadFailureKind.malformedEnvelope,
          cause: error,
        ),
      );
    }
  }

  /// Persists [snapshot] under the feature-only namespaced key.
  @override
  Future<void> saveSnapshot(MoodMedicineSnapshot snapshot) {
    return _memoryService.setItem(
      snapshotKey,
      PersistentMemoryType.String,
      snapshot.encode(),
    );
  }

  /// Legacy snapshot-only adapter.
  ///
  /// New code must use [loadSnapshot] so it can present recovery without
  /// overwriting unreadable history.
  @Deprecated('Use loadSnapshot and handle MoodMedicineLoadResult.')
  Future<MoodMedicineSnapshot> load() async {
    final MoodMedicineLoadResult result = await loadSnapshot();
    return switch (result) {
      MoodMedicineMissingSnapshot() => const MoodMedicineSnapshot.empty(),
      MoodMedicineLoadedSnapshot(:final MoodMedicineSnapshot snapshot) =>
        snapshot,
      MoodMedicineUnreadableSnapshot(:final MoodMedicineLoadFailure failure) =>
        throw MoodMedicineUnreadableSnapshotException(failure),
    };
  }

  /// Legacy write adapter retained while existing callers migrate to the
  /// repository boundary.
  @Deprecated('Use saveSnapshot.')
  Future<void> save(MoodMedicineSnapshot snapshot) => saveSnapshot(snapshot);
}
