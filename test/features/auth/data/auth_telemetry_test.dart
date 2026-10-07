import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mazilon/features/auth/data/auth_telemetry.dart';
import 'package:mazilon/util/async/analytics_service.dart';
import 'package:mazilon/util/async/logger_service.dart';

import '../../../helpers/widget_test_scaffold.dart' show NoopAnalyticsService;

class _RecordingLogger implements IncidentLoggerService {
  final warnings =
      <({String message, String contextName, Map<String, Object> context})>[];
  String? failure;

  @override
  Future<void> initializeSentry(_) async {}

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) => throw StateError('Unexpected exception report');

  @override
  Future<void> captureWarning(
    String message, {
    required String contextName,
    required Map<String, Object> context,
  }) {
    if (failure == 'sync') throw StateError('logger unavailable');
    if (failure == 'async') {
      return Future<void>.error(StateError('logger unavailable'));
    }
    warnings.add((
      message: message,
      contextName: contextName,
      context: context,
    ));
    return Future<void>.value();
  }
}

void main() {
  group('GoogleSignInAttemptTelemetry', () {
    late DateTime now;
    late _RecordingLogger logger;
    late NoopAnalyticsService analytics;

    void record(String outcome, {Duration duration = Duration.zero}) {
      final attempt = GoogleSignInAttemptTelemetry();
      attempt.record('started');
      now = now.add(duration);
      attempt.record(
        outcome,
        error: outcome == 'canceled'
            ? const GoogleSignInException(
                code: GoogleSignInExceptionCode.canceled,
                description: 'private provider description',
              )
            : null,
      );
    }

    setUp(() {
      now = DateTime.utc(2026, 10, 5);
      googleAuthTelemetryClock = () => now;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      logger = _RecordingLogger();
      analytics = NoopAnalyticsService();
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
      GetIt.instance.registerSingleton<AnalyticsService>(analytics);
    });

    tearDown(() async {
      googleAuthTelemetryClock = DateTime.now;
      debugDefaultTargetPlatformOverride = null;
      await GetIt.instance.reset();
    });

    test(
      'should warn on the third cancellation with safe attempt details',
      () async {
        record('canceled', duration: const Duration(seconds: 1));
        record('canceled', duration: const Duration(seconds: 2));
        expect(logger.warnings, isEmpty);
        record('canceled', duration: const Duration(seconds: 3));
        await Future<void>.delayed(Duration.zero);
        final warning = logger.warnings.single;
        expect(
          warning.message,
          'Possible Google sign-in failure: repeated cancellations',
        );
        expect(warning.contextName, 'google_sign_in');
        final context = warning.context;
        expect(context['cause'], 'unknown');
        expect(context['cancellation_count'], 3);
        expect(context['window_ms'], 5000);
        expect(context['attempts'], [
          for (final duration in [1000, 2000, 3000])
            {
              'outcome': 'canceled',
              'stage': 'googleAuthentication',
              'duration_ms': duration,
              'error_code': 'canceled',
            },
        ]);
        expect(
          warning.context.toString(),
          isNot(contains('private provider description')),
        );
        expect(analytics.events, hasLength(6));
      },
    );

    test('should warn without an analytics service', () async {
      await GetIt.instance.unregister<AnalyticsService>();
      for (var index = 0; index < 3; index++) {
        record('canceled');
      }
      await Future<void>.delayed(Duration.zero);
      expect(logger.warnings, hasLength(1));
    });

    test('should exclude cancellations at the five-minute boundary', () async {
      record('canceled');
      record('canceled');
      now = now.add(const Duration(minutes: 5));
      record('canceled');
      record('canceled');
      await Future<void>.delayed(Duration.zero);
      expect(logger.warnings, isEmpty);
      record('canceled');
      await Future<void>.delayed(Duration.zero);
      expect(logger.warnings, hasLength(1));
    });

    test(
      'should retain recent retries when the oldest cancellation expires',
      () async {
        record('canceled');
        now = now.add(const Duration(minutes: 4));
        record('canceled');
        now = now.add(const Duration(minutes: 1));
        record('canceled');
        expect(logger.warnings, isEmpty);
        record('canceled');
        await Future<void>.delayed(Duration.zero);
        expect(logger.warnings, hasLength(1));
      },
    );

    test(
      'should reset cancellations after successful authentication',
      () async {
        record('canceled');
        record('canceled');
        record('success');
        record('canceled');
        record('canceled');
        await Future<void>.delayed(Duration.zero);
        expect(logger.warnings, isEmpty);
        record('canceled');
        await Future<void>.delayed(Duration.zero);
        expect(logger.warnings, hasLength(1));
      },
    );

    test(
      'should exclude app interruptions and other provider failures',
      () async {
        record('canceled');
        [
          'appCanceled',
          'cleanupPending',
          'interrupted',
          'uiUnavailable',
          'initializationFailed',
          'failed',
        ].forEach(record);
        record('canceled');
        await Future<void>.delayed(Duration.zero);
        expect(logger.warnings, isEmpty);
        record('canceled');
        await Future<void>.delayed(Duration.zero);
        expect(logger.warnings, hasLength(1));
      },
    );

    test(
      'should cap warnings across new windows and successful sign-in',
      () async {
        for (var index = 0; index < 3; index++) {
          record('canceled');
        }
        await Future<void>.delayed(Duration.zero);
        record('success');
        now = now.add(const Duration(minutes: 6));
        for (var index = 0; index < 6; index++) {
          record('canceled');
        }
        await Future<void>.delayed(Duration.zero);
        expect(logger.warnings, hasLength(1));
      },
    );

    test('should not report Android warnings on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      for (var index = 0; index < 6; index++) {
        record('canceled');
      }
      await Future<void>.delayed(Duration.zero);
      expect(logger.warnings, isEmpty);
      expect(analytics.events.last.value, containsPair('platform', 'iOS'));
    });

    for (final failure in ['sync', 'async']) {
      test(
        'should recover after a $failure warning submission failure',
        () async {
          logger.failure = failure;
          for (var index = 0; index < 3; index++) {
            record('canceled');
          }
          await Future<void>.delayed(Duration.zero);
          expect(logger.warnings, isEmpty);
          expect(analytics.events, hasLength(6));
          logger.failure = null;
          for (var index = 0; index < 3; index++) {
            record('canceled');
          }
          await Future<void>.delayed(Duration.zero);
          expect(logger.warnings, hasLength(1));
        },
      );
    }

    test('should measure overlapping attempts independently', () async {
      final first = GoogleSignInAttemptTelemetry();
      first.record('started');
      now = now.add(const Duration(seconds: 2));
      final second = GoogleSignInAttemptTelemetry();
      second.record('started');
      now = now.add(const Duration(seconds: 1));
      second.record('canceled');
      first.record('canceled');
      await Future<void>.delayed(Duration.zero);
      expect(analytics.events[2].value, containsPair('duration_ms', 1000));
      expect(analytics.events[3].value, containsPair('duration_ms', 3000));
    });

    test(
      'should retain Firebase identifiers without diagnostic messages',
      () async {
        final attempt = GoogleSignInAttemptTelemetry();
        attempt.stage = GoogleSignInStage.firebaseAuthentication;
        attempt.record(
          'failed',
          error: FirebaseAuthException(
            code: 'network-request-failed',
            message: 'private account/token details',
          ),
        );
        final unknown = GoogleSignInAttemptTelemetry();
        unknown.record(
          'failed',
          error: FirebaseAuthException(
            code: 'private unexpected code',
            message: 'private account details',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          analytics.events.first.value,
          containsPair('error_code', 'network-request-failed'),
        );
        expect(
          analytics.events.first.value,
          containsPair('stage', 'firebaseAuthentication'),
        );
        expect(
          analytics.events.last.value,
          containsPair('error_code', 'unknown'),
        );
        expect(analytics.events.toString(), isNot(contains('private')));
        expect(logger.warnings, isEmpty);
      },
    );

    test(
      'should omit constant diagnostic fields from started events',
      () async {
        final attempt = GoogleSignInAttemptTelemetry();
        now = now.add(const Duration(seconds: 2));
        attempt.record('started');
        await Future<void>.delayed(Duration.zero);
        expect(analytics.events.single.value, {
          'outcome': 'started',
          'platform': 'android',
        });
        expect(logger.warnings, isEmpty);
      },
    );

    for (final code in [
      'app-not-authorized',
      'invalid-api-key',
      'user-token-expired',
      'new-diagnostic-code',
    ]) {
      test(
        'should preserve the Firebase diagnostic identifier $code',
        () async {
          GoogleSignInAttemptTelemetry().record(
            'failed',
            error: FirebaseAuthException(
              code: code,
              message: 'private details',
            ),
          );
          await Future<void>.delayed(Duration.zero);
          expect(
            analytics.events.single.value,
            containsPair('error_code', code),
          );
          expect(
            analytics.events.single.value.toString(),
            isNot(contains('private details')),
          );
        },
      );
    }

    for (final code in [
      '',
      'invalid-api-key\n',
      'email@example.com',
      'private details',
      List.filled(81, 'a').join(),
    ]) {
      test(
        'should redact a malformed Firebase identifier ${code.length}',
        () async {
          GoogleSignInAttemptTelemetry().record(
            'failed',
            error: FirebaseAuthException(code: code),
          );
          await Future<void>.delayed(Duration.zero);
          expect(
            analytics.events.single.value,
            containsPair('error_code', 'unknown'),
          );
        },
      );
    }

    for (final code in ['developer_error', 'channel-error', 'ApiException']) {
      test('should retain a platform initialization code $code', () async {
        GoogleSignInAttemptTelemetry().record(
          'initializationFailed',
          error: PlatformException(
            code: code,
            message: 'private message',
            details: 'private details',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(analytics.events.single.value, containsPair('error_code', code));
        expect(analytics.events.toString(), isNot(contains('private')));
      });
    }

    for (final code in [
      '',
      'developer_error\n',
      'email@example.com',
      'private details',
      List.filled(81, 'a').join(),
    ]) {
      test('should redact a malformed platform code ${code.length}', () async {
        GoogleSignInAttemptTelemetry().record(
          'initializationFailed',
          error: PlatformException(code: code),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          analytics.events.single.value,
          containsPair('error_code', 'unknown'),
        );
      });
    }

    test(
      'should identify initialization failures as their own stage',
      () async {
        GoogleSignInAttemptTelemetry().record(
          'initializationFailed',
          error: const GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          analytics.events.single.value,
          allOf(
            containsPair('stage', 'initialization'),
            containsPair('error_code', 'clientConfigurationError'),
          ),
        );
      },
    );
  });
}
