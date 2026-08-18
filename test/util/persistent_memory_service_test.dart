import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _RecordingLogger implements IncidentLoggerService {
  final List<dynamic> logs = [];
  @override
  Future<void> initializeSentry(_) async {}
  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    logs.add(exception);
  }
}

enum _WriteOutcome { succeed, reject, throwError }

class _ControlledSharedPreferencesStore extends InMemorySharedPreferencesStore {
  _ControlledSharedPreferencesStore({
    this.outcome = _WriteOutcome.succeed,
    this.gate,
  }) : super.empty();

  final _WriteOutcome outcome;
  final Completer<_WriteOutcome>? gate;
  final Completer<void> setValueStarted = Completer<void>();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (!setValueStarted.isCompleted) {
      setValueStarted.complete();
    }
    final _WriteOutcome resolvedOutcome = gate == null
        ? outcome
        : await gate!.future;
    switch (resolvedOutcome) {
      case _WriteOutcome.succeed:
        return super.setValue(valueType, key, value);
      case _WriteOutcome.reject:
        return false;
      case _WriteOutcome.throwError:
        throw StateError('Platform preference write failed.');
    }
  }
}

void _installControlledStore(_ControlledSharedPreferencesStore store) {
  final SharedPreferencesStorePlatform previousStore =
      SharedPreferencesStorePlatform.instance;
  SharedPreferencesStorePlatform.instance = store;
  SharedPreferences.resetStatic();
  addTearDown(() {
    SharedPreferencesStorePlatform.instance = previousStore;
    SharedPreferences.resetStatic();
  });
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
      await s.setItem('k', PersistentMemoryType.StringList, <String>['a', 'b']);
      expect(await s.getItem('k', PersistentMemoryType.StringList), ['a', 'b']);
    });

    test('accepts a List<dynamic> for StringList (cast)', () async {
      final s = SharedPreferencesService();
      final dynamic input = <dynamic>['x', 'y'];
      await s.setItem('k', PersistentMemoryType.StringList, input);
      expect(await s.getItem('k', PersistentMemoryType.StringList), ['x', 'y']);
    });

    test('empty key is rejected and logged', () async {
      final s = SharedPreferencesService();
      await expectLater(
        s.setItem('', PersistentMemoryType.String, 'v'),
        throwsArgumentError,
      );
      expect(logger.logs, isNotEmpty);
    });

    test('null value is rejected and logged', () async {
      final s = SharedPreferencesService();
      await expectLater(
        s.setItem('k', PersistentMemoryType.String, null),
        throwsArgumentError,
      );
      expect(logger.logs, isNotEmpty);
    });

    test('getItem with no stored value returns String default ""', () async {
      final s = SharedPreferencesService();
      expect(await s.getItem('missing', PersistentMemoryType.String), '');
    });

    test('getItem with no stored value returns null for Int', () async {
      final s = SharedPreferencesService();
      expect(await s.getItem('missing', PersistentMemoryType.Int), isNull);
    });

    test('getItem with a wrong Int type returns null', () async {
      SharedPreferences.setMockInitialValues({'k': 'not-an-int'});
      final s = SharedPreferencesService();

      expect(await s.getItem('k', PersistentMemoryType.Int), isNull);
      expect(logger.logs, isNotEmpty);
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
      expect(
        await s.getItem('missing', PersistentMemoryType.StringList),
        <String>[],
      );
    });
  });

  group('SharedPreferencesService write completion', () {
    test('should not resolve until the platform write completes', () async {
      final gate = Completer<_WriteOutcome>();
      final store = _ControlledSharedPreferencesStore(gate: gate);
      _installControlledStore(store);
      final service = SharedPreferencesService();

      final Future<void> write = service.setItem(
        'delayed',
        PersistentMemoryType.String,
        'value',
      );
      await store.setValueStarted.future;
      var completed = false;
      final Future<void> completion = write.then((_) {
        completed = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      gate.complete(_WriteOutcome.succeed);
      await write;
      await completion;
      expect(completed, isTrue);
    });

    test('should log and throw when the platform rejects a write', () async {
      _installControlledStore(
        _ControlledSharedPreferencesStore(outcome: _WriteOutcome.reject),
      );
      final service = SharedPreferencesService();

      await expectLater(
        service.setItem('rejected', PersistentMemoryType.String, 'value'),
        throwsA(isA<StateError>()),
      );
      expect(logger.logs, contains(isA<StateError>()));
    });

    test('should log and rethrow a platform write error', () async {
      _installControlledStore(
        _ControlledSharedPreferencesStore(outcome: _WriteOutcome.throwError),
      );
      final service = SharedPreferencesService();

      await expectLater(
        service.setItem('failed', PersistentMemoryType.String, 'value'),
        throwsA(isA<StateError>()),
      );
      expect(logger.logs, contains(isA<StateError>()));
    });
  });

  group('SharedPreferencesService.reset', () {
    test('clears all stored values', () async {
      final s = SharedPreferencesService();
      await s.setItem('a', PersistentMemoryType.String, 'one');
      await s.setItem('b', PersistentMemoryType.Int, 9);
      await s.reset();
      expect(await s.getItem('a', PersistentMemoryType.String), '');
      expect(await s.getItem('b', PersistentMemoryType.Int), isNull);
    });
  });

  group('error path: missing IncidentLoggerService registration', () {
    test('throws when logger not registered', () async {
      // Unregister, then expect throw on use
      if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
        GetIt.instance.unregister<IncidentLoggerService>();
      }
      final s = SharedPreferencesService();
      await expectLater(
        s.setItem('k', PersistentMemoryType.String, 'v'),
        throwsA(anything),
      );
      // Re-register so tearDown is symmetric
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
    });
  });
}
