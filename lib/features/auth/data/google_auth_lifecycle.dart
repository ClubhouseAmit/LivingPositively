import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:mazilon/features/auth/data/google_auth_models.dart';
import 'package:mazilon/features/auth/data/auth_telemetry.dart';

/// Coordinates interactive authentication with optional provider cleanup.
class GoogleAuthLifecycle {
  int _generation = 0;
  int _endedSessionGeneration = 0;
  Future<void>? _cleanup;
  bool _cleanupWaitExpired = false;

  int get generation => _generation;
  int get sessionGeneration => _endedSessionGeneration;
  bool get hasPendingFirebaseLogout => _firebaseLogouts.isNotEmpty;
  final _firebaseLogouts = <Future<void>>{};
  final _exchanges = <Future<void>>{};
  final _attempts = <Future<GoogleSignInAccount>>{};

  Future<GoogleSignInAccount> authenticate(
    GoogleSignIn sdk,
    Future<void> Function() initialize,
  ) {
    final attempt = _authenticate(sdk, initialize, _generation);
    _attempts.add(attempt);
    unawaited(
      attempt.then<void>(
        (_) => _attempts.remove(attempt),
        onError: (Object _, StackTrace _) => _attempts.remove(attempt),
      ),
    );
    return attempt;
  }

  Future<GoogleSignInAccount> _authenticate(
    GoogleSignIn sdk,
    Future<void> Function() initialize,
    int startedGeneration,
  ) async {
    final barriers = <Future<void>>[
      ?_cleanup,
      ..._firebaseLogouts.map(_awaitFirebaseLogout),
    ];
    if (_cleanupWaitExpired && _cleanup != null) {
      throw const GoogleSignInAborted(GoogleSignInAbortReason.cleanupPending);
    }
    if (barriers.isNotEmpty) {
      await Future.wait(barriers, eagerError: true).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (_cleanup != null) _cleanupWaitExpired = true;
          throw const GoogleSignInAborted(
            GoogleSignInAbortReason.cleanupPending,
          );
        },
      );
    }
    try {
      await initialize();
      _checkGeneration(startedGeneration);
      final account = await sdk.authenticate();
      _checkGeneration(startedGeneration);
      return account;
    } catch (_) {
      _checkGeneration(startedGeneration);
      rethrow;
    }
  }

  void _checkGeneration(int startedGeneration) {
    if (startedGeneration != _generation) {
      throw const GoogleSignInAborted(GoogleSignInAbortReason.appCanceled);
    }
  }

  Future<void> _awaitFirebaseLogout(Future<void> logout) async {
    try {
      await logout;
    } catch (_) {
      throw const GoogleSignInAborted(GoogleSignInAbortReason.cleanupPending);
    }
  }

  /// Fences success publication after the caller resumes from an exchange.
  void checkSession(int startedSessionGeneration) {
    if (_firebaseLogouts.isNotEmpty ||
        startedSessionGeneration != _endedSessionGeneration) {
      throw const GoogleSignInAborted(GoogleSignInAbortReason.appCanceled);
    }
  }

  Future<void> waitForFirebaseLogouts() => Future.wait(
    _firebaseLogouts.toList().map((future) => future.catchError((Object _) {})),
  );

  Future<T> exchange<T>(
    Future<T> Function() signIn,
    int startedGeneration,
  ) async {
    _checkGeneration(startedGeneration);
    final sessionGeneration = _endedSessionGeneration;
    final result = Future<T>.sync(signIn);
    final settled = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _exchanges.add(settled);
    unawaited(settled.then((_) => _exchanges.remove(settled)));
    final credential = await result;
    // Only a successful Firebase logout invalidates an issued exchange. A
    // failed logout must let its result reach the caller's session handling.
    await waitForFirebaseLogouts();
    if (sessionGeneration != _endedSessionGeneration) {
      throw const GoogleSignInAborted(GoogleSignInAbortReason.appCanceled);
    }
    return credential;
  }

  Future<void> _endFirebaseSession(Future<void> Function() signOut) async {
    // An issued credential exchange can create a session after logout. Drain it
    // before clearing Firebase; optional native cleanup never delays this work.
    await Future.wait(_exchanges.toList()).timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TimeoutException(
        'Firebase logout could not finish pending credential exchanges.',
      ),
    );
    await signOut();
    _endedSessionGeneration++;
  }

  ({Future<void> firebase, Future<void> provider, bool started}) startCleanup(
    GoogleSignIn sdk,
    Future<void> Function() firebaseSignOut,
    Future<void> Function() initialize,
  ) {
    _generation++;
    final firebaseLogout = _endFirebaseSession(firebaseSignOut);
    _firebaseLogouts.add(firebaseLogout);
    unawaited(
      firebaseLogout.then<void>(
        (_) => _firebaseLogouts.remove(firebaseLogout),
        onError: (Object _, StackTrace _) =>
            _firebaseLogouts.remove(firebaseLogout),
      ),
    );
    if (_cleanup case final pending?) {
      return (firebase: firebaseLogout, provider: pending, started: false);
    }
    final attempts = _attempts.toList();
    final future = _cleanUp(sdk, initialize, attempts, _endedSessionGeneration);
    _cleanup = future;
    return (firebase: firebaseLogout, provider: future, started: true);
  }

  Future<void> _cleanUp(
    GoogleSignIn sdk,
    Future<void> Function() initialize,
    List<Future<GoogleSignInAccount>> attempts,
    int startedSessionGeneration,
  ) async {
    try {
      // Drain every overlapping logout, so a failed first request cannot mask
      // a successful later request. Firebase errors stay with each caller.
      while (_firebaseLogouts.isNotEmpty) {
        await Future.wait(
          _firebaseLogouts.toList().map(
            (future) => future.catchError((Object _) {}),
          ),
        );
      }
      if (startedSessionGeneration == _endedSessionGeneration) return;
      for (final attempt in attempts) {
        try {
          await attempt;
        } catch (_) {
          // The caller handles authentication failures; cleanup must continue.
        }
      }
      final nativeCleanup = _cleanUpProvider(sdk, initialize);
      unawaited(observeGoogleCleanup(nativeCleanup));
      await nativeCleanup.catchError((Object _) {});
    } finally {
      _cleanup = null;
      _cleanupWaitExpired = false;
    }
  }

  Future<void> _cleanUpProvider(
    GoogleSignIn sdk,
    Future<void> Function() initialize,
  ) async {
    await initialize();
    await sdk.signOut();
  }
}
