import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';

/// Feature-local persistence boundary for Mood Medicine snapshots.
///
/// The repository returns a typed load result so an unreadable history is never
/// mistaken for an empty one and overwritten by an ordinary check-in.
abstract interface class MoodMedicineRepository {
  /// Loads the one atomic Mood Medicine snapshot without mutating storage.
  Future<MoodMedicineLoadResult> loadSnapshot();

  /// Persists [snapshot] as one awaited feature-local write.
  Future<void> saveSnapshot(MoodMedicineSnapshot snapshot);
}

/// Typed result of a [MoodMedicineRepository.loadSnapshot] attempt.
sealed class MoodMedicineLoadResult {
  /// Creates a repository load outcome.
  const MoodMedicineLoadResult();
}

/// Indicates that the feature key was truly absent from persistence.
final class MoodMedicineMissingSnapshot extends MoodMedicineLoadResult {
  /// Creates a missing-snapshot outcome.
  const MoodMedicineMissingSnapshot();
}

/// Contains a strictly decoded version-one snapshot.
final class MoodMedicineLoadedSnapshot extends MoodMedicineLoadResult {
  /// Creates a successful load containing [snapshot].
  const MoodMedicineLoadedSnapshot(this.snapshot);

  /// The immutable persisted history.
  final MoodMedicineSnapshot snapshot;
}

/// Describes an unreadable snapshot without exposing its journal contents.
final class MoodMedicineUnreadableSnapshot extends MoodMedicineLoadResult {
  /// Creates a recovery-required outcome for [failure].
  const MoodMedicineUnreadableSnapshot(this.failure);

  /// The typed reason ordinary writes must remain blocked.
  final MoodMedicineLoadFailure failure;
}

/// Categories used by recovery UI and tests without parsing implementation text.
enum MoodMedicineLoadFailureKind {
  /// The persistence service threw before supplying a value.
  readError,

  /// The persistence service supplied `null`, which is not an absent snapshot.
  nullValue,

  /// The persistence service supplied a value other than a string.
  wrongValueType,

  /// JSON or the snapshot envelope was malformed.
  malformedEnvelope,

  /// The stored schema version is not supported by this application build.
  unsupportedVersion,

  /// A nested record was malformed or had unsafe activity references.
  malformedRecord,
}

/// Safe diagnostic data for [MoodMedicineUnreadableSnapshot].
final class MoodMedicineLoadFailure {
  /// Creates a typed failure with an optional underlying [cause].
  const MoodMedicineLoadFailure(this.kind, {this.cause});

  /// Category appropriate for localized recovery guidance.
  final MoodMedicineLoadFailureKind kind;

  /// Original error object for logging or test diagnostics, never raw history.
  final Object? cause;
}

/// Error thrown by the legacy snapshot-only adapter.
///
/// New consumers should use [MoodMedicineRepository.loadSnapshot] and render a
/// recovery state for [MoodMedicineUnreadableSnapshot] instead.
final class MoodMedicineUnreadableSnapshotException implements Exception {
  /// Creates a legacy adapter error for [failure].
  const MoodMedicineUnreadableSnapshotException(this.failure);

  /// Typed recovery failure preserved from the repository result.
  final MoodMedicineLoadFailure failure;

  @override
  String toString() =>
      'MoodMedicineUnreadableSnapshotException(${failure.kind})';
}

/// Maps a strict decoder failure to the repository's public recovery category.
MoodMedicineLoadFailureKind moodMedicineLoadFailureKindForDecodeFailure(
  MoodMedicineSnapshotDecodeFailure failure,
) {
  return switch (failure) {
    MoodMedicineSnapshotDecodeFailure.malformedEnvelope =>
      MoodMedicineLoadFailureKind.malformedEnvelope,
    MoodMedicineSnapshotDecodeFailure.unsupportedVersion =>
      MoodMedicineLoadFailureKind.unsupportedVersion,
    MoodMedicineSnapshotDecodeFailure.malformedRecord =>
      MoodMedicineLoadFailureKind.malformedRecord,
  };
}
