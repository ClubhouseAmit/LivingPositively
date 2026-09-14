import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

import 'breathing_models.dart';
import 'breathing_photo_importer.dart';
import 'breathing_repository.dart';

/// The singleton adapter containing breathing's serialized snapshot mutations.
///
/// Register one instance in GetIt so every page writes against the latest
/// committed snapshot. The existing app-data reset also clears this key.
final class BreathingStore implements BreathingRepository {
  BreathingStore(this._memoryService);

  static const String snapshotKey = 'remember_to_breathe.snapshot.v1';

  final PersistentMemoryService _memoryService;
  Future<void> _pendingOperation = Future<void>.value();
  int _writeEpoch = 0;

  /// Invalidates queued work before the existing app-wide reset starts.
  ///
  /// Writes already accepted by memory finish before its reset by that
  /// service's contract. Reads and queued writes from this earlier visit must
  /// not repopulate the cleared key after reset completes.
  void invalidatePendingWrites() => _writeEpoch++;

  @override
  Future<BreathingSnapshot> load() => _enqueue(_read);

  @override
  Future<BreathingSnapshot> saveSettings(BreathingSettings settings) {
    return _enqueue((epoch) async {
      final current = await _read(epoch);
      final next = BreathingSnapshot(
        settings: settings,
        sessions: current.sessions,
      );
      await _write(next, epoch);
      return next;
    });
  }

  @override
  Future<BreathingSnapshot> saveSession(BreathingSession session) {
    return _enqueue((epoch) async {
      final current = await _read(epoch);
      final index = current.sessions.indexWhere(
        (item) => item.id == session.id,
      );
      if (index >= 0 && current.sessions[index].revision >= session.revision) {
        // Idempotent retries, including an older completion write arriving
        // after its post-practice rating, cannot erase newer information.
        return current;
      }
      final sessions = [...current.sessions];
      if (index < 0) {
        sessions.add(session);
      } else {
        sessions[index] = session;
      }
      sessions.sort((first, second) {
        final byTime = second.startedAt.compareTo(first.startedAt);
        return byTime == 0 ? first.id.compareTo(second.id) : byTime;
      });
      final next = BreathingSnapshot(
        settings: current.settings,
        sessions: sessions,
      );
      await _write(next, epoch);
      return next;
    });
  }

  @override
  Future<BreathingSnapshot> discardUnreadableSnapshot() {
    return _enqueue((epoch) async {
      try {
        // Recheck inside the queue: another recovery may already have made
        // the latest value readable, in which case it must be preserved.
        return await _read(epoch);
      } on BreathingStorageException catch (error) {
        if (!error.canDiscard) {
          rethrow;
        }
        const empty = BreathingSnapshot.empty();
        await _write(empty, epoch);
        return empty;
      }
    });
  }

  Future<BreathingSnapshot> _read(int epoch) async {
    final dynamic raw;
    try {
      raw = await _memoryService.getItem(
        snapshotKey,
        PersistentMemoryType.String,
      );
    } catch (_) {
      // Arbitrary platform exception messages may contain personal data.
      throw const BreathingStorageException();
    }
    _requireCurrent(epoch);
    if (raw is String && raw == '') {
      return const BreathingSnapshot.empty();
    }
    if (raw is! String) {
      throw const BreathingStorageException(canDiscard: true);
    }
    try {
      final snapshot = BreathingSnapshot.decode(raw);
      final photo = snapshot.settings.personalPhotoBase64;
      if (photo != null) {
        await BreathingPhotoImporter.validatePhoto(photo);
      }
      _requireCurrent(epoch);
      return snapshot;
    } on FormatException {
      throw const BreathingStorageException(canDiscard: true);
    } on BreathingPhotoException {
      throw const BreathingStorageException(canDiscard: true);
    }
  }

  Future<void> _write(BreathingSnapshot snapshot, int epoch) async {
    try {
      final encoded = snapshot.encode();
      final photo = snapshot.settings.personalPhotoBase64;
      if (photo != null) {
        await BreathingPhotoImporter.validatePhoto(photo);
      }
      _requireCurrent(epoch);
      await _memoryService.setItem(
        snapshotKey,
        PersistentMemoryType.String,
        encoded,
      );
    } catch (_) {
      throw const BreathingStorageException();
    }
  }

  void _requireCurrent(int epoch) {
    if (epoch != _writeEpoch) {
      throw const BreathingStorageException();
    }
  }

  Future<T> _enqueue<T>(Future<T> Function(int epoch) operation) {
    final epoch = _writeEpoch;
    final queued = _pendingOperation.then<T>((_) {
      _requireCurrent(epoch);
      return operation(epoch);
    });
    _pendingOperation = queued.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return queued;
  }
}
