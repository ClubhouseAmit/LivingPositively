import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('Google sign-in requires platform-specific native configuration', () {
    expect(
      AuthService.googleSignInAvailableOn(
        TargetPlatform.android,
        isWeb: false,
        serverClientId: 'test-server-client-id.apps.googleusercontent.com',
        iosClientId: '',
      ),
      isTrue,
    );
    expect(
      AuthService.googleSignInAvailableOn(
        TargetPlatform.iOS,
        isWeb: false,
        serverClientId: 'test-server-client-id.apps.googleusercontent.com',
        iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
      ),
      isTrue,
    );
    expect(
      AuthService.googleSignInAvailableOn(
        TargetPlatform.iOS,
        isWeb: false,
        serverClientId: 'test-server-client-id.apps.googleusercontent.com',
        iosClientId: '',
      ),
      isFalse,
    );
    expect(
      AuthService.googleSignInAvailableOn(
        TargetPlatform.windows,
        isWeb: false,
        serverClientId: 'test-server-client-id.apps.googleusercontent.com',
        iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
      ),
      isFalse,
    );
    expect(
      AuthService.googleSignInAvailableOn(
        TargetPlatform.android,
        isWeb: true,
        serverClientId: 'test-server-client-id.apps.googleusercontent.com',
        iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
      ),
      isFalse,
    );
    expect(
      AuthService.googleSignInAvailableOn(
        TargetPlatform.android,
        isWeb: false,
        serverClientId: '',
        iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
      ),
      isFalse,
    );
    expect(
      AuthService.googleSignInAvailableOn(
        TargetPlatform.android,
        isWeb: false,
        serverClientId: '   ',
        iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
      ),
      isFalse,
    );
  });

  test('Apple sign-in requires iOS and the build capability', () {
    expect(
      AuthService.appleSignInAvailableOn(
        TargetPlatform.iOS,
        isWeb: false,
        appleSignInEnabled: true,
      ),
      isTrue,
    );
    expect(
      AuthService.appleSignInAvailableOn(
        TargetPlatform.iOS,
        isWeb: false,
        appleSignInEnabled: false,
      ),
      isFalse,
    );
    expect(
      AuthService.appleSignInAvailableOn(
        TargetPlatform.android,
        isWeb: false,
        appleSignInEnabled: true,
      ),
      isFalse,
    );
    expect(
      AuthService.appleSignInAvailableOn(
        TargetPlatform.iOS,
        isWeb: true,
        appleSignInEnabled: true,
      ),
      isFalse,
    );
  });

  test('Apple sign-in returns null when the provider is unavailable', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    AuthService.debugAppleSignInEnabledOverride = false;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      AuthService.debugAppleSignInEnabledOverride = null;
    });

    await expectLater(AuthService.signInWithApple(), completion(isNull));
  });
}
