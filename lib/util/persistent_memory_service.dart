import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PersistentMemoryService {
  Future<void> setItem(String key, PersistentMemoryType type, dynamic value);
  Future<dynamic> getItem(String key, PersistentMemoryType type);
  Future<void> reset();
}

class SharedPreferencesService implements PersistentMemoryService {
  /// Keeps all writes and reset operations in their invocation order.
  ///
  /// A failed operation is reported to its caller but does not prevent the
  /// next queued operation from running.
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
      loggerService.captureLog(error, stackTrace: stackTrace);
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
