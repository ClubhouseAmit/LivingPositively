import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PersistentMemoryService {
  /// Persists [value] for [key] using [type].
  ///
  /// Each service instance serializes accepted [setItem] and [reset]
  /// operations in invocation order. A write requested while a reset is active
  /// must fail without reaching storage. Failures complete the originating
  /// operation with an error, but do not prevent a later accepted operation
  /// from running.
  ///
  /// Separate [setItem] calls are not atomic or rolled back as a group. A
  /// caller that persists multiple keys can therefore observe an earlier key
  /// persisted when a later write fails.
  Future<void> setItem(String key, PersistentMemoryType type, dynamic value);

  /// Reads [key] using [type] without waiting for queued writes or resets.
  ///
  /// A concurrent read can observe implementation-specific visible state and
  /// does not establish that a write completed durably. Callers must not rely
  /// on it to observe either the old or new value during a pending operation.
  /// Underlying platform read failures propagate to the caller after
  /// best-effort incident logging. A [TypeError] from a primitive getter is
  /// retained as the legacy malformed-value fallback and returns `null`.
  Future<dynamic> getItem(String key, PersistentMemoryType type);

  /// Clears persisted values after earlier accepted writes complete.
  ///
  /// Concurrent callers join the active reset, and new writes are rejected
  /// while it is active. A reset error propagates to its callers, and its
  /// failure does not prevent a later accepted operation from running. The
  /// reset fence reopens after the reset succeeds or fails.
  Future<void> reset();
}

class SharedPreferencesService implements PersistentMemoryService {
  /// Keeps the next operation runnable after an earlier failure.
  Future<void> _pendingOperation = Future<void>.value();
  Future<void>? _activeReset;
  bool _resetFenceActive = false;

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    IncidentLoggerService loggerService =
        GetIt.instance<IncidentLoggerService>();
    if (key.isEmpty || value == null) {
      return _logAndRethrowWriteFailure(
        loggerService,
        ArgumentError(
          'Persistent memory requires a non-empty key and non-null value.',
        ),
      );
    }
    if (_resetFenceActive) {
      return _logAndRethrowWriteFailure(
        loggerService,
        StateError(
          'Persistent memory cannot write while reset is in progress.',
        ),
      );
    }
    return _enqueue(() => _setItem(loggerService, key, type, value));
  }

  Future<void> _setItem(
    IncidentLoggerService loggerService,
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    try {
      if (key.isEmpty || value == null) {
        throw ArgumentError(
          'Persistent memory requires a non-empty key and non-null value.',
        );
      }
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      late final bool saved;
      switch (type) {
        case PersistentMemoryType.String:
          saved = await prefs.setString(key, value as String);
        case PersistentMemoryType.Int:
          saved = await prefs.setInt(key, value as int);
        case PersistentMemoryType.Double:
          saved = await prefs.setDouble(key, value as double);
        case PersistentMemoryType.Bool:
          saved = await prefs.setBool(key, value as bool);
        case PersistentMemoryType.StringList:
          saved = await prefs.setStringList(
            key,
            List<String>.from(value as Iterable),
          );
      }
      if (!saved) {
        throw StateError('Persistent memory rejected "$key".');
      }
    } catch (error, stackTrace) {
      await loggerService.captureLog(error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _logAndRethrowWriteFailure(
    IncidentLoggerService loggerService,
    Object error,
  ) async {
    try {
      throw error;
    } catch (error, stackTrace) {
      try {
        await loggerService.captureLog(error, stackTrace: stackTrace);
      } catch (_) {
        // A logging failure must not mask the rejected write.
      }
      rethrow;
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final Future<void> queuedOperation = _pendingOperation.then<void>(
      (_) => operation(),
    );
    _pendingOperation = queuedOperation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return queuedOperation;
  }

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    IncidentLoggerService loggerService =
        GetIt.instance<IncidentLoggerService>();
    try {
      var prefs = await SharedPreferences.getInstance();
      switch (type) {
        case PersistentMemoryType.String:
          return prefs.getString(key) ?? "";
        case PersistentMemoryType.Int:
          return prefs.getInt(key);
        case PersistentMemoryType.Double:
          return prefs.getDouble(key) ?? 0.0;
        case PersistentMemoryType.Bool:
          return prefs.getBool(key) ?? false;
        case PersistentMemoryType.StringList:
          return prefs.getStringList(key) ?? [];
      }
    } catch (error, stackTrace) {
      try {
        await loggerService.captureLog(error, stackTrace: stackTrace);
      } catch (_) {
        // A logger failure must not mask the original persistence read error.
      }
      if (error is TypeError) {
        // The legacy service treats a value stored under the wrong primitive
        // type as malformed data and supplies the same fallback as a missing
        // value. Other platform/read failures must remain observable to the
        // feature that needs to distinguish them.
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> reset() async {
    final Future<void>? activeReset = _activeReset;
    if (activeReset != null) {
      return activeReset;
    }
    IncidentLoggerService loggerService =
        GetIt.instance<IncidentLoggerService>();
    _resetFenceActive = true;
    late final Future<void> resetOperation;
    resetOperation = _enqueue(() => _reset(loggerService)).whenComplete(() {
      if (identical(_activeReset, resetOperation)) {
        _activeReset = null;
        _resetFenceActive = false;
      }
    });
    _activeReset = resetOperation;
    return resetOperation;
  }

  Future<void> _reset(IncidentLoggerService loggerService) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool cleared = await prefs.clear();
      if (!cleared) {
        throw StateError('Persistent memory reset was rejected.');
      }
    } catch (error, stackTrace) {
      try {
        await loggerService.captureLog(error, stackTrace: stackTrace);
      } catch (_) {
        // Reset failures must remain visible if incident logging also fails.
      }
      rethrow;
    }
  }
}
