import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mazilon/features/auth/data/google_auth_models.dart';
import 'package:mazilon/util/async/analytics_service.dart';
import 'package:mazilon/util/async/logger_service.dart';

@visibleForTesting
DateTime Function() googleAuthTelemetryClock = DateTime.now;

final _androidCancellations =
    Expando<List<({DateTime finished, Map<String, Object> details})>>();
final _androidCancellationReported = Expando<bool>();

/// The last stage entered by an attempt, including successful attempts.
enum GoogleSignInStage {
  initialization,
  googleAuthentication,
  googleTokenValidation,
  firebaseAuthentication,
  sessionValidation,
}

/// Records one attempt's stage and duration without provider/account details.
final class GoogleSignInAttemptTelemetry {
  static final _firebaseCodePattern = RegExp(
    r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$',
  );
  static final _platformCodePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');
  final DateTime _started = googleAuthTelemetryClock();
  GoogleSignInStage stage = GoogleSignInStage.googleAuthentication;

  void record(String outcome, {Object? error}) {
    final now = googleAuthTelemetryClock();
    if (outcome == 'initializationFailed') {
      stage = GoogleSignInStage.initialization;
    }
    final details = outcome == 'started'
        ? <String, Object>{}
        : <String, Object>{
            'stage': stage.name,
            'duration_ms': now.difference(_started).inMilliseconds,
            'error_code': ?_errorCode(error),
          };
    _trackGoogleSignInOutcome(outcome, details);
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    unawaited(
      Future<void>.sync(() {
        final services = GetIt.instance;
        if (!services.isRegistered<IncidentLoggerService>()) return;
        _observeAndroidOutcome(
          outcome,
          now,
          details,
          services<IncidentLoggerService>(),
        );
      }).catchError((_) {}),
    );
  }

  String? _errorCode(Object? error) => switch (error) {
    GoogleSignInException(:final code) => code.name,
    FirebaseAuthException(:final code) =>
      code.length <= 80 && _firebaseCodePattern.stringMatch(code) == code
          ? code
          : 'unknown',
    PlatformException(:final code) =>
      code.length <= 80 && _platformCodePattern.stringMatch(code) == code
          ? code
          : 'unknown',
    _ => null,
  };
}

void _trackGoogleSignInOutcome(String outcome, Map<String, Object> details) {
  final services = GetIt.instance;
  if (!services.isRegistered<AnalyticsService>()) return;
  unawaited(
    Future<void>.sync(
      () => services<AnalyticsService>().trackEvent(
        'Google sign-in outcome',
        {
          'outcome': outcome,
          'platform': defaultTargetPlatform.name,
          ...details,
        },
      ),
    ).catchError((_) {}),
  );
}

void _observeAndroidOutcome(
  String outcome,
  DateTime now,
  Map<String, Object> details,
  IncidentLoggerService logger,
) {
  if (outcome == 'success') _androidCancellations[logger] = null;
  if (outcome != 'canceled' ||
      (_androidCancellationReported[logger] ?? false)) {
    return;
  }
  final attempts = _androidCancellations[logger] ??= [];
  attempts.removeWhere(
    (attempt) => now.difference(attempt.finished) >= const Duration(minutes: 5),
  );
  attempts.add((finished: now, details: {'outcome': outcome, ...details}));
  if (attempts.length < 3) return;
  _androidCancellationReported[logger] = true;
  // Android's cancellation code cannot establish the underlying cause.
  // Snapshot the attempts so later success cannot mutate an in-flight report.
  final context = <String, Object>{
    'cause': 'unknown',
    'cancellation_count': attempts.length,
    'window_ms': now.difference(attempts.first.finished).inMilliseconds,
    'attempts': attempts.map((attempt) => attempt.details).toList(),
  };
  _androidCancellations[logger] = null;
  unawaited(
    Future<void>.sync(
      () => logger.captureWarning(
        'Possible Google sign-in failure: repeated cancellations',
        contextName: 'google_sign_in',
        context: context,
      ),
    ).catchError((_) {
      _androidCancellationReported[logger] = null;
    }),
  );
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
