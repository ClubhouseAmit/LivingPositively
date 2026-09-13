import 'breathing_models.dart';

/// Persistence operations shared by all page instances of breathing practice.
abstract interface class BreathingRepository {
  Future<BreathingSnapshot> load();
  Future<BreathingSnapshot> saveSettings(BreathingSettings settings);
  Future<BreathingSnapshot> saveSession(BreathingSession session);

  /// Discards only a snapshot that is still unreadable when recovery runs.
  Future<BreathingSnapshot> discardUnreadableSnapshot();
}

/// Privacy-safe persistence failure for retry and explicit recovery screens.
final class BreathingStorageException implements Exception {
  const BreathingStorageException({this.canDiscard = false});

  /// True only for malformed or unsupported saved data, never read failures.
  final bool canDiscard;

  @override
  String toString() => 'BreathingStorageException(canDiscard: $canDiscard)';
}
