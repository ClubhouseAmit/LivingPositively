import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/notifications/data/fcm_service.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';

void _reportAuthRestorationFailure(Object error, StackTrace stackTrace) {
  if (!GetIt.instance.isRegistered<IncidentLoggerService>()) return;

  final loggerService = GetIt.instance<IncidentLoggerService>();
  unawaited(
    Future<void>.sync(
      () => loggerService.captureLog(error, stackTrace: stackTrace),
    ).catchError((_) {}),
  );
}

/// Restores the live authorization state without trusting persisted sign-in flags.
Future<void> restoreAuthenticatedSession(
  UserInformation userInfo, {
  required bool hadMadeGuestDecision,
  required Duration authStateTimeout,
  Future<void> Function()? onAuthenticatedSessionRestored,
}) async {
  User? currentUser;
  var authStateResolved = false;
  var restoredFromAuthStateChanges = false;
  try {
    final auth = GetIt.instance.isRegistered<FirebaseAuth>()
        ? GetIt.instance<FirebaseAuth>()
        : FirebaseAuth.instance;
    currentUser = auth.currentUser;
    // A null currentUser before the first stream emission is not a sign-out.
    if (currentUser == null) {
      currentUser = await auth
          .authStateChanges()
          .timeout(authStateTimeout)
          .first;
      restoredFromAuthStateChanges = currentUser != null;
    }
    authStateResolved = true;
  } catch (error, stackTrace) {
    // A transient failure must not overwrite the persisted sign-in evidence.
    if (error is! FirebaseException) {
      _reportAuthRestorationFailure(error, stackTrace);
    }
  }
  final hasAuthenticatedSession =
      currentUser != null && !currentUser.isAnonymous;
  if (authStateResolved) {
    userInfo.updateLoggedIn(hasAuthenticatedSession);
    userInfo.updateAuthDecisionMade(
      hasAuthenticatedSession || hadMadeGuestDecision,
    );
    userInfo.updateUserId(hasAuthenticatedSession ? currentUser.uid : '');
    userInfo.updateEmail(
      hasAuthenticatedSession ? currentUser.email ?? '' : '',
    );
    userInfo.updateDisplayName(
      hasAuthenticatedSession ? currentUser.displayName ?? '' : '',
    );
  } else {
    userInfo.loggedIn = false;
    userInfo.authDecisionMade = hadMadeGuestDecision;
    userInfo.userId = '';
    userInfo.email = '';
    userInfo.displayName = '';
  }
  if (restoredFromAuthStateChanges && hasAuthenticatedSession) {
    final synchronizeFcmToken =
        onAuthenticatedSessionRestored ?? FcmService.onUserSignedIn;
    unawaited(
      Future<void>.sync(synchronizeFcmToken).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _reportAuthRestorationFailure(error, stackTrace);
      }),
    );
  }
}
