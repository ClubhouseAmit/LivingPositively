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
    if (key == "" || value == null) {
      loggerService.captureLog(
        'Invalid key or value for persistent memory service',
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      late final bool persisted;
      switch (type) {
        case PersistentMemoryType.String:
          persisted = await prefs.setString(key, value);
        case PersistentMemoryType.Int:
          persisted = await prefs.setInt(key, value);
        case PersistentMemoryType.Double:
          persisted = await prefs.setDouble(key, value);
        case PersistentMemoryType.Bool:
          persisted = await prefs.setBool(key, value);
        case PersistentMemoryType.StringList:
          persisted = await prefs.setStringList(key, List<String>.from(value));
      }
      if (!persisted) {
        throw StateError('SharedPreferences write returned false for $key');
      }
    } catch (error, stackTrace) {
      loggerService.captureLog(error, stackTrace: stackTrace);
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
    var prefs = await SharedPreferences.getInstance();
    final cleared = await prefs.clear();
    if (!cleared) {
      throw StateError('SharedPreferences clear returned false');
    }
  }
}
