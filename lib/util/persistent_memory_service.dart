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
    final loggerService =
        GetIt.instance<IncidentLoggerService>();
    if (key == '' || value == null) {
      loggerService.captureLog(
        'Invalid key or value for persistent memory service',
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      switch (type) {
        case PersistentMemoryType.String:
          prefs.setString(key, value);
        case PersistentMemoryType.Int:
          prefs.setInt(key, value);
        case PersistentMemoryType.Double:
          prefs.setDouble(key, value);
        case PersistentMemoryType.Bool:
          prefs.setBool(key, value);
        case PersistentMemoryType.StringList:
          prefs.setStringList(key, List<String>.from(value));
      }
    } catch (error, stackTrace) {
      loggerService.captureLog(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    final loggerService =
        GetIt.instance<IncidentLoggerService>();
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (type) {
        case PersistentMemoryType.String:
          return prefs.getString(key) ?? '';
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
    final loggerService =
        GetIt.instance<IncidentLoggerService>();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (error, stackTrace) {
      loggerService.captureLog(error, stackTrace: stackTrace);
    }
  }
}
