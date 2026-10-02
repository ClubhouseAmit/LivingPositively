import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/auth/data/google_auth_models.dart';
import 'package:mazilon/util/async/analytics_service.dart';
import 'package:mazilon/util/async/logger_service.dart';

final _androidCancellations = Expando<({int count, DateTime started})>();
@visibleForTesting
DateTime Function() googleAuthTelemetryClock = DateTime.now;
final _androidCancellationReported = Expando<bool>();

/// Records provider outcomes without credentials or provider descriptions.
void trackGoogleSignInOutcome(String outcome) {
  final services = GetIt.instance;
  if (defaultTargetPlatform == TargetPlatform.android &&
      services.isRegistered<IncidentLoggerService>()) {
    _observeAndroidOutcome(outcome, services<IncidentLoggerService>());
  }
  if (!services.isRegistered<AnalyticsService>()) return;
  unawaited(
    Future<void>.sync(
      () => services<AnalyticsService>().trackEvent(
        'Google sign-in outcome',
        {'outcome': outcome, 'platform': defaultTargetPlatform.name},
      ),
    ).catchError((_) {}),
  );
}

void _observeAndroidOutcome(String outcome, IncidentLoggerService logger) {
  if (outcome == 'success') _androidCancellations[logger] = null;
  if (outcome != 'canceled') return;
  final now = googleAuthTelemetryClock();
  final previous = _androidCancellations[logger];
  final recent =
      previous != null &&
      now.difference(previous.started) < const Duration(minutes: 5);
  final count = recent ? previous.count + 1 : 1;
  _androidCancellations[logger] = (
    count: count,
    started: recent ? previous.started : now,
  );
  // Isolated dismissals are usage. Three unsuccessful retries are an
  // operational signal; cap reports at one per logger instance/app run.
  if (count >= 3 && !(_androidCancellationReported[logger] ?? false)) {
    _androidCancellationReported[logger] = true;
    unawaited(
      Future<void>.sync(
        () => logger.captureLog(
          StateError('Repeated Android Google sign-in cancellations'),
          stackTrace: StackTrace.current,
        ),
      ).catchError((_) {}),
    );
  }
}

Future<void> observeGoogleCleanup(Future<void> cleanup) async {
  final observed = cleanup.then<void>(
    (_) {},
    onError: (Object error, StackTrace stackTrace) {
      _reportGoogleCleanup(error, stackTrace);
    },
  );
  await observed.timeout(
    const Duration(seconds: 5),
    onTimeout: () => _reportGoogleCleanup(
      TimeoutException('Google provider cleanup timed out'),
      StackTrace.current,
    ),
  );
}

void _reportGoogleCleanup(Object error, StackTrace stackTrace) {
  if (GetIt.instance.isRegistered<IncidentLoggerService>() &&
      (error is! GoogleSignInInitializationFailure || error.claimReport())) {
    unawaited(
      Future<void>.sync(
        () => GetIt.instance<IncidentLoggerService>().captureLog(
          error is GoogleSignInInitializationFailure ? error.cause : error,
          stackTrace: error is GoogleSignInInitializationFailure
              ? error.stackTrace
              : stackTrace,
        ),
      ).catchError((_) {
        if (error is GoogleSignInInitializationFailure) {
          error.releaseReport();
        }
      }),
    );
  }
}
