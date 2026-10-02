/// A provider initialization failure that requires a new app process to retry.
final class GoogleSignInInitializationFailure implements Exception {
  GoogleSignInInitializationFailure(this.cause, this.stackTrace);

  final Object cause;
  final StackTrace stackTrace;
  bool _reported = false;

  /// Claims the single incident report shared by sign-in and sign-out attempts.
  bool claimReport() {
    if (_reported) return false;
    _reported = true;
    return true;
  }

  @override
  String toString() => 'Google Sign-In initialization failed: $cause';
}

/// An app interruption, distinct from a provider dismissal or failure.
enum GoogleSignInAbortReason { appCanceled, cleanupPending }

final class GoogleSignInAborted implements Exception {
  const GoogleSignInAborted(this.outcome);
  final GoogleSignInAbortReason outcome;
}
