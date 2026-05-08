import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingLogger implements IncidentLoggerService {
  final List<dynamic> logs = [];
  @override
  Future<void> initializeSentry(_) async {}
  @override
  Future<void> captureLog(dynamic exception,
      {StackTrace? stackTrace, dynamic exceptionData}) async {
    logs.add(exception);
  }
}

void main() {
  late _RecordingLogger logger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
      GetIt.instance.unregister<IncidentLoggerService>();
    }
    logger = _RecordingLogger();
    GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
      GetIt.instance.unregister<IncidentLoggerService>();
    }
  });

  group('SharedPreferencesService.setItem / getItem', () {
    test('stores and reads String', () async {
      final s = SharedPreferencesService();
      await s.setItem('k', PersistentMemoryType.String, 'hello');
      expect(await s.getItem('k', PersistentMemoryType.String), 'hello');
    });

    test('stores and reads Int', () async {
      final s = SharedPreferencesService();
      await s.setItem('k', PersistentMemoryType.Int, 42);
      expect(await s.getItem('k', PersistentMemoryType.Int), 42);
    });

    test('stores and reads Double', () async {
      final s = SharedPreferencesService();
      await s.setItem('k', PersistentMemoryType.Double, 3.14);
      expect(await s.getItem('k', PersistentMemoryType.Double), 3.14);
    });

    test('stores and reads Bool', () async {
      final s = SharedPreferencesService();
      await s.setItem('k', PersistentMemoryType.Bool, true);
      expect(await s.getItem('k', PersistentMemoryType.Bool), true);
    });

    test('stores and reads StringList', () async {
      final s = SharedPreferencesService();
      await s.setItem(
          'k', PersistentMemoryType.StringList, <String>['a', 'b']);
      expect(await s.getItem('k', PersistentMemoryType.StringList),
          ['a', 'b']);
    });

    test('accepts a List<dynamic> for StringList (cast)', () async {
      final s = SharedPreferencesService();
      final dynamic input = <dynamic>['x', 'y'];
      await s.setItem('k', PersistentMemoryType.StringList, input);
      expect(await s.getItem('k', PersistentMemoryType.StringList), ['x', 'y']);
    });

    test('empty key is skipped and logged', () async {
      final s = SharedPreferencesService();
      await s.setItem('', PersistentMemoryType.String, 'v');
      expect(logger.logs, isNotEmpty);
    });

    test('null value is skipped and logged', () async {
      final s = SharedPreferencesService();
      await s.setItem('k', PersistentMemoryType.String, null);
      expect(logger.logs, isNotEmpty);
    });

    test('getItem with no stored value returns String default ""', () async {
      final s = SharedPreferencesService();
      expect(
          await s.getItem('missing', PersistentMemoryType.String), '');
    });

    test('getItem with no stored value returns Int default 0', () async {
      final s = SharedPreferencesService();
      expect(await s.getItem('missing', PersistentMemoryType.Int), 0);
    });

    test('getItem with no stored value returns Double default 0.0', () async {
      final s = SharedPreferencesService();
      expect(await s.getItem('missing', PersistentMemoryType.Double), 0.0);
    });

    test('getItem with no stored value returns Bool default false', () async {
      final s = SharedPreferencesService();
      expect(await s.getItem('missing', PersistentMemoryType.Bool), false);
    });

    test('getItem with no stored value returns empty StringList', () async {
      final s = SharedPreferencesService();
      expect(await s.getItem('missing', PersistentMemoryType.StringList),
          <String>[]);
    });
  });

  group('SharedPreferencesService.reset', () {
    test('clears all stored values', () async {
      final s = SharedPreferencesService();
      await s.setItem('a', PersistentMemoryType.String, 'one');
      await s.setItem('b', PersistentMemoryType.Int, 9);
      await s.reset();
      expect(await s.getItem('a', PersistentMemoryType.String), '');
      expect(await s.getItem('b', PersistentMemoryType.Int), 0);
    });
  });

  group('error path: missing IncidentLoggerService registration', () {
    test('throws when logger not registered', () async {
      // Unregister, then expect throw on use
      if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
        GetIt.instance.unregister<IncidentLoggerService>();
      }
      final s = SharedPreferencesService();
      expect(
        () => s.setItem('k', PersistentMemoryType.String, 'v'),
        throwsA(anything),
      );
      // Re-register so tearDown is symmetric
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
    });
  });
}
