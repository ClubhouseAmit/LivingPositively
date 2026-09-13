import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/logger_service.dart';

/// Reports an authentication failure without allowing telemetry to replace it.
///
/// No user-entered credentials or form values are attached to the event. When
/// the incident logger is unavailable, the original failure is forwarded to
/// Flutter's error pipeline so configured framework integrations can observe it.
Future<void> reportAuthenticationError(
  Object error,
  StackTrace stackTrace,
) async {
  if (!GetIt.instance.isRegistered<IncidentLoggerService>()) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'authentication',
        context: ErrorDescription('while processing authentication'),
      ),
    );
    return;
  }

  try {
    await GetIt.instance<IncidentLoggerService>().captureLog(
      error,
      stackTrace: stackTrace,
    );
  } catch (_) {
    // Authentication behavior and user feedback must survive telemetry failure.
    debugPrint('Unable to report an authentication failure.');
  }
}
