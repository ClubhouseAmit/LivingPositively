import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

abstract class IncidentLoggerService {
  Future<void> initializeSentry(Widget MyApp);
  Future<void> captureLog(dynamic exception,
      {StackTrace? stackTrace, dynamic exceptionData});
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
        await SentryFlutter.init(
          (options) {
            options.dsn = _sentryDsn;
          },
          appRunner: () => runApp(MyApp),
        );
      }
    } catch (e) {
      debugPrint("sentry will not be initialized,error");
      debugPrint(e.toString());
      runApp(MyApp);
    }
  }

  @override
  Future<void> captureLog(dynamic log,
      {StackTrace? stackTrace, dynamic exceptionData}) async {
    if (Sentry.isEnabled) {
      if (exceptionData != null &&
          exceptionData.containsKey("name") &&
          exceptionData.containsKey("value")) {
        Sentry.configureScope((scope) {
          scope.setContexts('${exceptionData["name"]}', exceptionData["value"]);
        });
      }
      await Sentry.captureException(
        log,
        stackTrace: stackTrace,
      );
      return;
    }
  }
}
