import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/auth/data/google_auth_models.dart';
import 'package:mazilon/util/async/logger_service.dart';

/// Reports an authentication failure without allowing telemetry to replace it.
///
/// No user-entered credentials or form values are attached to the event. When
/// the incident logger is unavailable, the original failure is forwarded to
/// Flutter's error pipeline so configured framework integrations can observe it.
/// Cached Google initialization failures share one report across retry attempts.
Future<void> reportAuthenticationError(
  Object error,
  StackTrace stackTrace,
) async {
  if (error is GoogleSignInInitializationFailure) {
    if (!error.claimReport()) return;
    stackTrace = error.stackTrace;
    error = error.cause;
  }
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
