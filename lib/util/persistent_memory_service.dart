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
  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    IncidentLoggerService loggerService =
        GetIt.instance<IncidentLoggerService>();
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
    IncidentLoggerService loggerService =
        GetIt.instance<IncidentLoggerService>();
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
