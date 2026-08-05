import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sharedPreferencesChannel = MethodChannel(
  'plugins.flutter.io/shared_preferences',
);

class _PendingLogger implements IncidentLoggerService {
  final Completer<void> completion = Completer<void>();

  @override
  Future<void> initializeSentry(_) async {}

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) => completion.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _PendingLogger logger;

  setUp(() {
    SharedPreferences.resetStatic();
    logger = _PendingLogger();
    GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
  });

  tearDown(() async {
    if (!logger.completion.isCompleted) {
      logger.completion.complete();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_sharedPreferencesChannel, null);
    SharedPreferences.resetStatic();
    await GetIt.instance.reset();
  });

  void installClearResult(Object? clearResult) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_sharedPreferencesChannel, (call) async {
          switch (call.method) {
            case 'getAll':
              return <String, Object>{};
            case 'clear':
              if (clearResult is Exception) {
                throw clearResult;
              }
              return clearResult;
            default:
              throw PlatformException(
                code: 'unexpected_method',
                message: call.method,
              );
          }
        });
  }

  test('reset rejects a false SharedPreferences clear result', () async {
    installClearResult(false);

    await expectLater(
      SharedPreferencesService().reset().timeout(const Duration(seconds: 1)),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('clear'),
        ),
      ),
    );
  });

  test('reset rethrows a SharedPreferences clear exception', () async {
    installClearResult(
      PlatformException(code: 'clear_failed', message: 'disk unavailable'),
    );

    await expectLater(
      SharedPreferencesService().reset().timeout(const Duration(seconds: 1)),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'clear_failed',
        ),
      ),
    );
  });
}
