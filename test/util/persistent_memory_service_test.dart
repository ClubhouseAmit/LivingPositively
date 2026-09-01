import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../helpers/widget_test_scaffold.dart' show FakePersistentMemoryService;
import '../../test_support/contract_persistent_memory_service.dart';

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
    this.outcomesByKey = const <String, _WriteOutcome>{},
    this.clearOutcome = _WriteOutcome.succeed,
    this.clearGate,
  }) : super.empty();

  final _WriteOutcome outcome;
  final Completer<_WriteOutcome>? gate;
  final Map<String, _WriteOutcome> outcomesByKey;
  final _WriteOutcome clearOutcome;
  final Completer<_WriteOutcome>? clearGate;
  final Completer<void> setValueStarted = Completer<void>();
  final Completer<void> clearStarted = Completer<void>();
  final List<String> setValueKeys = <String>[];

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    setValueKeys.add(key);
    if (!setValueStarted.isCompleted) {
      setValueStarted.complete();
    }
    final _WriteOutcome resolvedOutcome = gate == null
        ? outcomesByKey[key] ?? outcome
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

  @override
  Future<bool> clear() async {
    if (!clearStarted.isCompleted) {
      clearStarted.complete();
    }
    final _WriteOutcome resolvedOutcome = clearGate == null
        ? clearOutcome
        : await clearGate!.future;
    switch (resolvedOutcome) {
      case _WriteOutcome.succeed:
        return super.clear();
      case _WriteOutcome.reject:
        return false;
      case _WriteOutcome.throwError:
        throw StateError('Platform preference reset failed.');
    }
  }
}

final class _ThrowingReadSharedPreferencesStore
    extends InMemorySharedPreferencesStore {
  _ThrowingReadSharedPreferencesStore(this.error) : super.empty();

  final Object error;

  @override
  Future<Map<String, Object>> getAll() async => throw error;
}

class _ThrowingLogger implements IncidentLoggerService {
  @override
  Future<void> initializeSentry(_) async {}

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    throw StateError('Incident logging failed.');
  }
}

void _installControlledStore(SharedPreferencesStorePlatform store) {
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

    test('should log and rethrow a platform read error', () async {
      final StateError failure = StateError(
        'private journal text must not escape',
      );
      _installControlledStore(_ThrowingReadSharedPreferencesStore(failure));
      final SharedPreferencesService service = SharedPreferencesService();

      await expectLater(
        service.getItem('history', PersistentMemoryType.String),
        throwsA(same(failure)),
      );
      expect(logger.logs, contains(same(failure)));
    });

    test('getItem with no stored value returns null for Int', () async {
      final s = SharedPreferencesService();
      expect(await s.getItem('missing', PersistentMemoryType.Int), isNull);
    });

    test('should log and return null for a wrong stored Int type', () async {
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

    test(
      'should complete a direct read during a held platform write',
      () async {
        final Completer<_WriteOutcome> gate = Completer<_WriteOutcome>();
        final _ControlledSharedPreferencesStore store =
            _ControlledSharedPreferencesStore(gate: gate);
        _installControlledStore(store);
        final PersistentMemoryService service = SharedPreferencesService();

        final Future<void> write = service.setItem(
          'delayed',
          PersistentMemoryType.String,
          'visible before durable',
        );
        await store.setValueStarted.future;
        var writeCompleted = false;
        final Future<void> completion = write.then((_) {
          writeCompleted = true;
        });

        expect(
          await service.getItem('delayed', PersistentMemoryType.String),
          'visible before durable',
        );
        expect(await store.getAll(), isNot(contains('flutter.delayed')));
        expect(writeCompleted, isFalse);

        gate.complete(_WriteOutcome.succeed);
        await completion;
      },
    );

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

    test('should continue queued operations after a failed write', () async {
      _installControlledStore(
        _ControlledSharedPreferencesStore(outcome: _WriteOutcome.reject),
      );
      final SharedPreferencesService service = SharedPreferencesService();

      await expectLater(
        service.setItem('rejected', PersistentMemoryType.String, 'value'),
        throwsA(isA<StateError>()),
      );

      await service.reset();
      expect(
        await service.getItem('rejected', PersistentMemoryType.String),
        '',
      );
    });

    test(
      'should not roll back an earlier write when a later write fails',
      () async {
        final _ControlledSharedPreferencesStore store =
            _ControlledSharedPreferencesStore(
              outcomesByKey: const <String, _WriteOutcome>{
                'flutter.second': _WriteOutcome.reject,
              },
            );
        _installControlledStore(store);
        final PersistentMemoryService service = SharedPreferencesService();

        await service.setItem(
          'first',
          PersistentMemoryType.String,
          'first durable value',
        );
        await expectLater(
          service.setItem(
            'second',
            PersistentMemoryType.String,
            'rejected second value',
          ),
          throwsA(isA<StateError>()),
        );

        final Map<String, Object> durableValues = await store.getAll();
        expect(
          durableValues,
          containsPair('flutter.first', 'first durable value'),
        );
        expect(durableValues, isNot(contains('flutter.second')));
      },
    );
  });

  group('ContractPersistentMemoryService', () {
    test(
      'should expose an idle visible write before awaiting completion',
      () async {
        final Completer<void> gate = Completer<void>();
        final Completer<void> writeStarted = Completer<void>();
        final ContractPersistentMemoryService service =
            ContractPersistentMemoryService()
              ..onPersist =
                  (String key, PersistentMemoryType type, Object value) async {
                    writeStarted.complete();
                    await gate.future;
                  };

        final Future<void> write = service.setItem(
          'idle',
          PersistentMemoryType.String,
          'visible immediately',
        );

        expect(writeStarted.isCompleted, isTrue);
        expect(service.store['idle'], 'visible immediately');
        expect(service.durableStore, isNot(contains('idle')));

        gate.complete();
        await write;
      },
    );

    test('should complete a direct read during a held queued write', () async {
      final Completer<void> writeStarted = Completer<void>();
      final Completer<void> gate = Completer<void>();
      final ContractPersistentMemoryService service =
          ContractPersistentMemoryService()
            ..onPersist =
                (String key, PersistentMemoryType type, Object value) async {
                  writeStarted.complete();
                  await gate.future;
                };

      final Future<void> write = service.setItem(
        'delayed',
        PersistentMemoryType.String,
        'visible before durable',
      );
      await writeStarted.future;
      var writeCompleted = false;
      final Future<void> completion = write.then((_) {
        writeCompleted = true;
      });

      expect(
        await service.getItem('delayed', PersistentMemoryType.String),
        'visible before durable',
      );
      expect(service.durableStore, isNot(contains('delayed')));
      expect(writeCompleted, isFalse);

      gate.complete();
      await completion;
      expect(service.durableStore['delayed'], 'visible before durable');
    });

    test(
      'should not roll back an earlier durable write when a later write fails',
      () async {
        final ContractPersistentMemoryService service =
            ContractPersistentMemoryService()
              ..onPersist =
                  (String key, PersistentMemoryType type, Object value) {
                    if (key == 'second') {
                      throw StateError('Rejected second value.');
                    }
                  };

        await service.setItem(
          'first',
          PersistentMemoryType.String,
          'first durable value',
        );
        await expectLater(
          service.setItem(
            'second',
            PersistentMemoryType.String,
            'rejected second value',
          ),
          throwsA(isA<StateError>()),
        );

        expect(service.durableStore['first'], 'first durable value');
        expect(service.durableStore, isNot(contains('second')));
      },
    );

    test(
      'should clear visible cache but retain durable values when reset fails',
      () async {
        final ContractPersistentMemoryService service =
            ContractPersistentMemoryService(
                initialValues: const <String, Object?>{
                  'before-reset': 'durable value',
                },
              )
              ..onReset = () {
                throw StateError('Rejected reset.');
              };

        await expectLater(service.reset(), throwsA(isA<StateError>()));

        expect(service.store, isEmpty);
        expect(service.durableStore['before-reset'], 'durable value');
        expect(
          await service.getItem('before-reset', PersistentMemoryType.String),
          '',
        );
      },
    );

    test(
      'should retain a caller-owned store and allow a null missing value',
      () async {
        final Map<String, dynamic> store = <String, dynamic>{};
        final ContractPersistentMemoryService service =
            ContractPersistentMemoryService(store: store)
              ..onMissingRead = (String key, PersistentMemoryType type) => null;

        store['seeded'] = 'caller-owned value';

        expect(identical(service.store, store), isTrue);
        expect(
          await service.getItem('missing', PersistentMemoryType.String),
          isNull,
        );
        expect(
          await service.getItem('seeded', PersistentMemoryType.String),
          'caller-owned value',
        );
      },
    );

    test('should validate and clone StringList writes', () async {
      final ContractPersistentMemoryService service =
          ContractPersistentMemoryService();
      final List<String> values = <String>['before write'];

      final Future<void> write = service.setItem(
        'list',
        PersistentMemoryType.StringList,
        values,
      );
      values.add('after write');
      await write;

      expect(service.store['list'], <String>['before write']);
      expect(service.durableStore['list'], <String>['before write']);
      await expectLater(
        service.setItem('', PersistentMemoryType.String, 'value'),
        throwsArgumentError,
      );
    });

    test('shared widget fake rejects invalid writes', () async {
      final FakePersistentMemoryService service = FakePersistentMemoryService();

      await expectLater(
        service.setItem('', PersistentMemoryType.String, 'value'),
        throwsArgumentError,
      );
      await expectLater(
        service.setItem('value', PersistentMemoryType.String, null),
        throwsArgumentError,
      );

      expect(service.store, isEmpty);
      expect(service.durableStore, isEmpty);
    });

    test(
      'should keep the reset fence and queue usable after failures',
      () async {
        final ContractPersistentMemoryService service =
            ContractPersistentMemoryService();
        service.onPersist =
            (String key, PersistentMemoryType type, Object value) {
              if (key == 'failed') {
                throw StateError('Rejected write.');
              }
            };

        await expectLater(
          service.setItem('failed', PersistentMemoryType.String, 'value'),
          throwsA(isA<StateError>()),
        );
        await service.setItem(
          'after-write-failure',
          PersistentMemoryType.String,
          'durable value',
        );

        final Completer<void> resetStarted = Completer<void>();
        final Completer<void> resetGate = Completer<void>();
        service.onReset = () async {
          resetStarted.complete();
          await resetGate.future;
        };
        final Future<void> reset = service.reset();
        await resetStarted.future;
        await expectLater(
          service.setItem('during-reset', PersistentMemoryType.String, 'value'),
          throwsA(isA<StateError>()),
        );

        final Future<void> failedReset = expectLater(
          reset,
          throwsA(isA<StateError>()),
        );
        resetGate.completeError(StateError('Rejected reset.'));
        await failedReset;

        service.onReset = null;
        await service.setItem(
          'after-reset-failure',
          PersistentMemoryType.String,
          'durable value',
        );
        expect(service.durableStore['after-write-failure'], 'durable value');
        expect(service.durableStore['after-reset-failure'], 'durable value');
      },
    );
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

    test('should clear a held earlier write only after it completes', () async {
      final Completer<_WriteOutcome> gate = Completer<_WriteOutcome>();
      final _ControlledSharedPreferencesStore store =
          _ControlledSharedPreferencesStore(gate: gate);
      _installControlledStore(store);
      final SharedPreferencesService service = SharedPreferencesService();

      final Future<void> write = service.setItem(
        'name',
        PersistentMemoryType.String,
        'old profile name',
      );
      await store.setValueStarted.future;
      final Future<void> reset = service.reset();
      await Future<void>.delayed(Duration.zero);
      expect(store.clearStarted.isCompleted, isFalse);

      gate.complete(_WriteOutcome.succeed);
      await write;
      await reset;

      expect(store.setValueKeys, <String>['flutter.name']);
      expect(await service.getItem('name', PersistentMemoryType.String), '');
    });

    test(
      'should reject a later composite write while reset is active',
      () async {
        final Completer<_WriteOutcome> writeGate = Completer<_WriteOutcome>();
        final Completer<_WriteOutcome> clearGate = Completer<_WriteOutcome>();
        final _ControlledSharedPreferencesStore store =
            _ControlledSharedPreferencesStore(
              gate: writeGate,
              clearGate: clearGate,
            );
        _installControlledStore(store);
        final SharedPreferencesService service = SharedPreferencesService();

        Future<void> writeProfile() async {
          await service.setItem(
            'name',
            PersistentMemoryType.String,
            'old profile name',
          );
          await service.setItem(
            'gender',
            PersistentMemoryType.String,
            'female',
          );
        }

        final Future<void> profileWrite = writeProfile();
        await store.setValueStarted.future;
        final Future<void> reset = service.reset();
        final Future<void> rejectedProfileWrite = expectLater(
          profileWrite,
          throwsA(isA<StateError>()),
        );

        writeGate.complete(_WriteOutcome.succeed);
        await store.clearStarted.future;
        await rejectedProfileWrite;
        expect(store.setValueKeys, <String>['flutter.name']);

        clearGate.complete(_WriteOutcome.succeed);
        await reset;

        expect(await service.getItem('name', PersistentMemoryType.String), '');
        expect(
          await service.getItem('gender', PersistentMemoryType.String),
          '',
        );
      },
    );

    test('should not resolve until the platform clear completes', () async {
      final Completer<_WriteOutcome> gate = Completer<_WriteOutcome>();
      final _ControlledSharedPreferencesStore store =
          _ControlledSharedPreferencesStore(clearGate: gate);
      _installControlledStore(store);
      final SharedPreferencesService service = SharedPreferencesService();

      final Future<void> reset = service.reset();
      await store.clearStarted.future;
      var completed = false;
      final Future<void> completion = reset.then((_) {
        completed = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      gate.complete(_WriteOutcome.succeed);
      await reset;
      await completion;
      expect(completed, isTrue);
    });

    test(
      'should log, throw, and retain durable values when the platform rejects a reset',
      () async {
        final _ControlledSharedPreferencesStore store =
            _ControlledSharedPreferencesStore(
              clearOutcome: _WriteOutcome.reject,
            );
        _installControlledStore(store);
        final SharedPreferencesService service = SharedPreferencesService();

        await service.setItem(
          'before-reset',
          PersistentMemoryType.String,
          'durable value',
        );

        await expectLater(service.reset(), throwsA(isA<StateError>()));
        expect(logger.logs, contains(isA<StateError>()));
        expect(
          await store.getAll(),
          containsPair('flutter.before-reset', 'durable value'),
        );
        expect(
          await service.getItem('before-reset', PersistentMemoryType.String),
          '',
        );

        await service.setItem(
          'after-reset-failure',
          PersistentMemoryType.String,
          'value',
        );
        expect(
          await service.getItem(
            'after-reset-failure',
            PersistentMemoryType.String,
          ),
          'value',
        );
      },
    );

    test('should log and rethrow a platform reset error', () async {
      _installControlledStore(
        _ControlledSharedPreferencesStore(
          clearOutcome: _WriteOutcome.throwError,
        ),
      );
      final SharedPreferencesService service = SharedPreferencesService();

      await expectLater(
        service.reset(),
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            'Platform preference reset failed.',
          ),
        ),
      );
      expect(logger.logs, contains(isA<StateError>()));
    });

    test(
      'should preserve a reset-fence write error when incident logging fails',
      () async {
        GetIt.instance.unregister<IncidentLoggerService>();
        GetIt.instance.registerSingleton<IncidentLoggerService>(
          _ThrowingLogger(),
        );
        final Completer<_WriteOutcome> clearGate = Completer<_WriteOutcome>();
        final _ControlledSharedPreferencesStore store =
            _ControlledSharedPreferencesStore(clearGate: clearGate);
        _installControlledStore(store);
        final SharedPreferencesService service = SharedPreferencesService();

        final Future<void> reset = service.reset();
        await store.clearStarted.future;

        await expectLater(
          service.setItem('during-reset', PersistentMemoryType.String, 'value'),
          throwsA(
            isA<StateError>().having(
              (StateError error) => error.message,
              'message',
              'Persistent memory cannot write while reset is in progress.',
            ),
          ),
        );

        clearGate.complete(_WriteOutcome.succeed);
        await reset;
      },
    );

    test(
      'should preserve the reset error when incident logging fails',
      () async {
        GetIt.instance.unregister<IncidentLoggerService>();
        GetIt.instance.registerSingleton<IncidentLoggerService>(
          _ThrowingLogger(),
        );
        _installControlledStore(
          _ControlledSharedPreferencesStore(
            clearOutcome: _WriteOutcome.throwError,
          ),
        );
        final SharedPreferencesService service = SharedPreferencesService();

        await expectLater(
          service.reset(),
          throwsA(
            isA<StateError>().having(
              (StateError error) => error.message,
              'message',
              'Platform preference reset failed.',
            ),
          ),
        );
      },
    );
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
