import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/async/logger_service.dart';

/// Reports notification failures without allowing logging to fail startup.
final class NotificationErrorReporter {
  const NotificationErrorReporter._();

  static void report(Object error, StackTrace stackTrace) {
    debugPrint('[FcmService] FCM operation failed: $error');
    if (!GetIt.instance.isRegistered<IncidentLoggerService>()) return;
    try {
      unawaited(
        Future<void>.sync(
          () => GetIt.instance<IncidentLoggerService>().captureLog(
            error,
            stackTrace: stackTrace,
          ),
        ).catchError((Object loggerError, StackTrace _) {
          debugPrint(
            '[FcmService] Failed to report FCM operation: $loggerError',
          );
        }),
      );
    } catch (loggerError) {
      debugPrint('[FcmService] Failed to report FCM operation: $loggerError');
    }
  }
}
