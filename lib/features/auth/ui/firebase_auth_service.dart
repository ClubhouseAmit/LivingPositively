import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/shell/ui/popup_toast.dart';
import 'package:mazilon/util/async/logger_service.dart';

/// Legacy email flow adapter retained for callers that expect toast feedback.
class FirebaseAuthService {
  FirebaseAuthService(FirebaseApp app, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instanceFor(app: app);

  @visibleForTesting
  FirebaseAuthService.withAuth(FirebaseAuth auth) : _auth = auth;

  final FirebaseAuth _auth;

  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (error, stackTrace) {
      if (error.code == 'email-already-in-use') {
        showToast(message: 'The email address is already in use.');
      } else {
        final loggerService = GetIt.instance<IncidentLoggerService>();
        await loggerService.captureLog(error, stackTrace: stackTrace);
        showToast(message: 'An error occurred');
      }
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (error, stackTrace) {
      if (error.code == 'user-not-found' || error.code == 'wrong-password') {
        showToast(message: 'Invalid email or password.');
      } else {
        showToast(message: 'An error occurred');
        final loggerService = GetIt.instance<IncidentLoggerService>();
        await loggerService.captureLog(error, stackTrace: stackTrace);
      }
    }
    return null;
  }
}
