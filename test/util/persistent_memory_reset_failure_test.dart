import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sharedPreferencesChannel = MethodChannel(
  'plugins.flutter.io/shared_preferences',
);

class _RecordingLogger implements IncidentLoggerService {
  final List<dynamic> logs = <dynamic>[];

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingLogger logger;

  setUp(() {
    SharedPreferences.resetStatic();
    logger = _RecordingLogger();
    GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
  });

  tearDown(() async {
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
      SharedPreferencesService().reset(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('clear'),
        ),
      ),
    );
    expect(logger.logs, hasLength(1));
    expect(logger.logs.single, isA<StateError>());
  });

  test('reset rethrows a SharedPreferences clear exception', () async {
    installClearResult(
      PlatformException(code: 'clear_failed', message: 'disk unavailable'),
    );

    await expectLater(
      SharedPreferencesService().reset(),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'clear_failed',
        ),
      ),
    );
    expect(logger.logs, hasLength(1));
    expect(logger.logs.single, isA<PlatformException>());
  });
}
