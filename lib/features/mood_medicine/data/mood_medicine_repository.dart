import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';

/// A synchronous, pure change applied to the latest feature snapshot.
///
/// The repository invokes this only after serializing against earlier Mood
/// Medicine operations. It must return a new immutable snapshot and must not
/// perform I/O or mutate captured state.
typedef MoodMedicineSnapshotMutation =
    MoodMedicineSnapshot Function(MoodMedicineSnapshot current);

/// Feature-local persistence boundary for Mood Medicine snapshots.
///
/// The repository returns a typed load result so an unreadable history is never
/// mistaken for an empty one and overwritten by an ordinary check-in.
abstract interface class MoodMedicineRepository {
  /// Loads the one atomic Mood Medicine snapshot after earlier feature writes.
  ///
  /// Documented malformed-input failures are returned as typed unreadable
  /// results. Unexpected implementation errors may propagate to the caller's
  /// error boundary.
  Future<MoodMedicineLoadResult> loadSnapshot();

  /// Applies [mutation] to the latest valid snapshot and persists it once.
  ///
  /// A missing snapshot is treated as an empty v1 snapshot. An unreadable
  /// snapshot is returned unchanged so normal feature actions cannot overwrite
  /// it. A successful mutation always returns [MoodMedicineLoadedSnapshot]
  /// containing the exact committed snapshot.
  Future<MoodMedicineLoadResult> mutateSnapshot(
    MoodMedicineSnapshotMutation mutation,
  );

  /// Clears history only when the queued, latest value remains unreadable.
  ///
  /// If another operation has made the history valid before this confirmed
  /// recovery action reaches the repository, it returns that value without
  /// replacing it.
  Future<MoodMedicineLoadResult> discardUnreadableSnapshot();
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
  /// Creates a typed failure with optional privacy-safe diagnostics.
  const MoodMedicineLoadFailure(
    this.kind, {
    this.exceptionType,
    this.valueType,
  });

  /// Category appropriate for localized recovery guidance.
  final MoodMedicineLoadFailureKind kind;

  /// Runtime type of an exception raised while reading or decoding.
  ///
  /// This is intentionally a type rather than an exception instance so raw
  /// persisted history and exception messages cannot enter recovery state.
  final Type? exceptionType;

  /// Runtime type of a persisted value when it is not the expected string.
  ///
  /// This is kept separate from [exceptionType] because it describes stored
  /// data, not an exception raised by the read or decode boundary.
  final Type? valueType;
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
