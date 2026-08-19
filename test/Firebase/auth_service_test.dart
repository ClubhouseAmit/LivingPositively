import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/auth_service.dart';

void main() {
  test('localizedError maps Firebase authentication failures', () {
    expect(
      AuthService.localizedError(FirebaseAuthException(code: 'invalid-email')),
      'authErrorInvalidEmail',
    );
    expect(
      AuthService.localizedError(FirebaseAuthException(code: 'weak-password')),
      'authErrorWeakPassword',
    );
    for (final code in [
      'user-not-found',
      'invalid-credential',
      'wrong-password',
    ]) {
      expect(
        AuthService.localizedError(FirebaseAuthException(code: code)),
        'authErrorUserNotFound',
      );
    }
    expect(
      AuthService.localizedError(
        FirebaseAuthException(code: 'email-already-in-use'),
      ),
      'authErrorEmailInUse',
    );
    expect(
      AuthService.localizedError(
        FirebaseAuthException(code: 'too-many-requests'),
      ),
      'authErrorGeneric',
    );
    expect(
      AuthService.localizedError(StateError('not Firebase')),
      'authErrorGeneric',
    );
  });

  test('Apple sign-in availability is false on the test platform', () {
    expect(AuthService.isAppleSignInAvailable, isFalse);
  });
}
