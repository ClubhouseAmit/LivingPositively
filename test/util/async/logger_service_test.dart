import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/auth/data/auth_telemetry.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('SentryServiceImpl.captureLog (Sentry not initialized)', () {
    // In the test environment Sentry.isEnabled is false, so captureLog
    // returns early without throwing on any input shape.
    test('captureLog returns without error when Sentry is disabled', () async {
      final svc = SentryServiceImpl();
      await svc.captureLog(Exception('boom'));
    });

    test('captureWarning completes when Sentry is disabled', () async {
      final IncidentLoggerService logger = SentryServiceImpl();
      expect(Sentry.isEnabled, isFalse);
      await logger.captureWarning(
        'Possible Google sign-in failure',
        contextName: 'google_sign_in',
        context: {'cause': 'unknown'},
      );
    });

    test('captureLog accepts a stackTrace', () async {
      final svc = SentryServiceImpl();
      await svc.captureLog(
        Exception('with trace'),
        stackTrace: StackTrace.current,
      );
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

  group('SentryServiceImpl.captureLog (captured events)', () {
    late List<SentryEvent> events;
    late SentryServiceImpl logger;

    setUp(() async {
      events = [];
      logger = SentryServiceImpl();
      await Sentry.init((options) {
        options.dsn = 'https://public@example.com/1';
        options.attachStacktrace = false;
        // Inspect the real SDK event and drop it before any network delivery.
        options.beforeSend = (event, hint) {
          events.add(event);
          return null;
        };
      });
    });

    tearDown(Sentry.close);

    test('should capture a warning message without an exception', () async {
      await logger.captureWarning(
        'Possible Google sign-in failure',
        contextName: 'google_sign_in',
        context: {'cause': 'unknown', 'cancellation_count': 3},
      );
      final event = events.single;
      expect(event.level, SentryLevel.warning);
      expect(event.message?.formatted, 'Possible Google sign-in failure');
      expect(event.exceptions, anyOf(isNull, isEmpty));
      expect(event.contexts['google_sign_in'], {
        'cause': 'unknown',
        'cancellation_count': 3,
      });
    });

    test(
      'should retain the warning cap when beforeSend drops the event',
      () async {
        // Event processing may finish after the next event-loop turn.
        await Sentry.configureScope((scope) {
          scope.addEventProcessor(_DelayedEventProcessor());
        });
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final warningLogger = _AwaitableWarningLogger();
        GetIt.instance.registerSingleton<IncidentLoggerService>(warningLogger);
        addTearDown(() async {
          debugDefaultTargetPlatformOverride = null;
          await GetIt.instance.reset();
        });
        for (var window = 0; window < 2; window++) {
          for (var attempt = 0; attempt < 3; attempt++) {
            GoogleSignInAttemptTelemetry().record('canceled');
          }
          await Future.wait(warningLogger.captures);
          expect(warningLogger.captures, hasLength(1));
          expect(events, hasLength(1));
        }
        expect(events.single.level, SentryLevel.warning);
      },
    );

    test('should keep warning context out of a subsequent exception', () async {
      await logger.captureWarning(
        'Possible Google sign-in failure',
        contextName: 'google_sign_in',
        context: {'cause': 'unknown'},
      );
      await logger.captureLog(
        StateError('actual failure'),
        stackTrace: StackTrace.current,
      );
      expect(events.first.contexts['google_sign_in'], isNotNull);
      expect(events.last.contexts['google_sign_in'], isNull);
      expect(events.last.level, anyOf(isNull, SentryLevel.error));
      expect(events.last.exceptions, isNotEmpty);
      expect(events.last.exceptions!.single.value, contains('actual failure'));
    });

    for (final name in <Object?>[42, false, null]) {
      test('should preserve legacy name coercion for $name', () async {
        await logger.captureLog(
          StateError('legacy context'),
          exceptionData: {
            'name': name,
            'value': {'stage': 'legacy'},
          },
        );
        expect(events.single.contexts['$name'], {'stage': 'legacy'});
        await logger.captureLog(StateError('unrelated failure'));
        expect(events.last.contexts.containsKey('$name'), isFalse);
      });
    }

    test(
      'should pass a null context value through only for this event',
      () async {
        await Sentry.configureScope(
          (scope) => scope.setContexts('operation', {'stage': 'inherited'}),
        );
        await logger.captureLog(
          StateError('null context'),
          exceptionData: {'name': 'operation', 'value': null},
        );
        expect(events.single.contexts['operation'], isNull);
        await logger.captureLog(StateError('unrelated failure'));
        expect(events.last.contexts['operation'], {'stage': 'inherited'});
      },
    );

    test(
      'should report exceptions with malformed legacy context payloads',
      () async {
        for (final payload in <Object>[
          {'name': 'operation'},
          {
            'value': {'stage': 'legacy'},
          },
          'invalid context',
          ['name', 'value'],
        ]) {
          await logger.captureLog(
            StateError('actual failure'),
            exceptionData: payload,
          );
          expect(events.last.contexts['operation'], isNull);
          expect(
            events.last.exceptions!.single.value,
            contains('actual failure'),
          );
        }
        expect(events, hasLength(4));
      },
    );

    test(
      'should retain named context and stacks on genuine exceptions',
      () async {
        await logger.captureLog(
          StateError('actual failure'),
          stackTrace: StackTrace.current,
          exceptionData: {
            'name': 'operation',
            'value': {'stage': 'cleanup'},
          },
        );
        final event = events.single;
        expect(event.contexts['operation'], {'stage': 'cleanup'});
        expect(event.exceptions!.single.stackTrace, isNotNull);
        expect(event.message, isNull);
        await logger.captureLog(StateError('unrelated failure'));
        expect(events.last.contexts['operation'], isNull);
      },
    );
  });
}

class _DelayedEventProcessor extends EventProcessor {
  @override
  Future<SentryEvent?> apply(SentryEvent event, Hint hint) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return event;
  }
}

class _AwaitableWarningLogger extends SentryServiceImpl {
  final captures = <Future<void>>[];

  @override
  Future<void> captureWarning(
    String message, {
    required String contextName,
    required Map<String, Object> context,
  }) {
    final capture = super.captureWarning(
      message,
      contextName: contextName,
      context: context,
    );
    captures.add(capture);
    return capture;
  }
}
