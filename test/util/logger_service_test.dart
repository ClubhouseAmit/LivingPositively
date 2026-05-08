import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/logger_service.dart';

void main() {
  group('SentryServiceImpl.captureLog (Sentry not initialized)', () {
    // In the test environment Sentry.isEnabled is false, so captureLog
    // returns early without throwing on any input shape.
    test('captureLog returns without error when Sentry is disabled', () async {
      final svc = SentryServiceImpl();
      await svc.captureLog(Exception('boom'));
    });

    test('captureLog accepts a stackTrace', () async {
      final svc = SentryServiceImpl();
      await svc.captureLog(Exception('with trace'),
          stackTrace: StackTrace.current);
    });

    test('captureLog accepts exceptionData with name+value', () async {
      final svc = SentryServiceImpl();
      await svc.captureLog(
        Exception('with context'),
        exceptionData: {'name': 'tag', 'value': 'v1'},
      );
    });

    test('captureLog accepts exceptionData missing required keys', () async {
      final svc = SentryServiceImpl();
      await svc.captureLog(
        Exception('partial context'),
        exceptionData: {'unrelated': 'x'},
      );
    });

    test('captureLog accepts a plain string log', () async {
      final svc = SentryServiceImpl();
      await svc.captureLog('a message');
    });
  });
}
