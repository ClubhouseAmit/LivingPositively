import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

abstract class IncidentLoggerService {
  Future<void> initializeSentry(Widget MyApp);

  /// Reports an exception through the existing transport.
  /// Legacy `exceptionData` accepts a map containing `name` and `value`.
  /// The name is converted to a string; the value, including null, is passed
  /// to Sentry on this event's scope. Other payloads are ignored, and the
  /// exception is still reported. Context never persists to subsequent events.
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  });

  /// Reports a warning message with context scoped to this event.
  /// Completion acknowledges the logger call, not backend delivery.
  Future<void> captureWarning(
    String message, {
    required String contextName,
    required Map<String, Object> context,
  });
}

class SentryServiceImpl implements IncidentLoggerService {
  @override
  Future<void> initializeSentry(Widget MyApp) async {
    try {
      if (_sentryDsn.isEmpty) {
        debugPrint("sentry will not be initialized");
        runApp(MyApp);
      } else {
        debugPrint("sentry will be initialized");
        await SentryFlutter.init((options) {
          options.dsn = _sentryDsn;
        }, appRunner: () => runApp(MyApp));
      }
    } catch (e) {
      debugPrint("sentry will not be initialized,error");
      debugPrint(e.toString());
      runApp(MyApp);
    }
  }

  @override
  Future<void> captureLog(
    dynamic log, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    if (!Sentry.isEnabled) return;
    await Sentry.captureException(
      log,
      stackTrace: stackTrace,
      withScope: (scope) => _attachContext(scope, exceptionData),
    );
  }

  @override
  Future<void> captureWarning(
    String message, {
    required String contextName,
    required Map<String, Object> context,
  }) async {
    if (!Sentry.isEnabled) return;
    await Sentry.captureMessage(
      message,
      level: SentryLevel.warning,
      withScope: (scope) => scope.setContexts(contextName, context),
    );
  }

  void _attachContext(Scope scope, dynamic data) {
    if (data case {'name': final Object? name, 'value': final Object? value}) {
      scope.setContexts('$name', value);
    }
  }
}
