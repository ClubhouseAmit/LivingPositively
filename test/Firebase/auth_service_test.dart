import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    test('should localizedError maps Firebase authentication failures', () {
      expect(
        AuthService.localizedError(
          FirebaseAuthException(code: 'invalid-email'),
        ),
        'authErrorInvalidEmail',
      );
      expect(
        AuthService.localizedError(
          FirebaseAuthException(code: 'weak-password'),
        ),
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

    test(
      'should Google sign-in requires platform-specific native configuration',
      () {
        expect(
          AuthService.googleSignInAvailableOn(
            TargetPlatform.android,
            isWeb: false,
            serverClientId: 'test-server-client-id.apps.googleusercontent.com',
            iosClientId: '',
            firebaseIosClientId: '',
            firebaseIosBundleId: '',
          ),
          isTrue,
        );
        expect(
          AuthService.googleSignInAvailableOn(
            TargetPlatform.iOS,
            isWeb: false,
            serverClientId: 'test-server-client-id.apps.googleusercontent.com',
            iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosClientId:
                'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosBundleId: 'com.clubhouse.livingpositively',
          ),
          isTrue,
        );
        expect(
          AuthService.googleSignInAvailableOn(
            TargetPlatform.iOS,
            isWeb: false,
            serverClientId: 'test-server-client-id.apps.googleusercontent.com',
            iosClientId: '',
            firebaseIosClientId: '',
            firebaseIosBundleId: 'com.clubhouse.livingpositively',
          ),
          isFalse,
        );
        expect(
          AuthService.googleSignInAvailableOn(
            TargetPlatform.windows,
            isWeb: false,
            serverClientId: 'test-server-client-id.apps.googleusercontent.com',
            iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosClientId:
                'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosBundleId: 'com.clubhouse.livingpositively',
          ),
          isFalse,
        );
        expect(
          AuthService.googleSignInAvailableOn(
            TargetPlatform.android,
            isWeb: true,
            serverClientId: 'test-server-client-id.apps.googleusercontent.com',
            iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosClientId:
                'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosBundleId: 'com.clubhouse.livingpositively',
          ),
          isFalse,
        );
        expect(
          AuthService.googleSignInAvailableOn(
            TargetPlatform.android,
            isWeb: false,
            serverClientId: '',
            iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosClientId:
                'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosBundleId: 'com.clubhouse.livingpositively',
          ),
          isFalse,
        );
        expect(
          AuthService.googleSignInAvailableOn(
            TargetPlatform.android,
            isWeb: false,
            serverClientId: '   ',
            iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosClientId:
                'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosBundleId: 'com.clubhouse.livingpositively',
          ),
          isFalse,
        );
        expect(
          AuthService.googleSignInAvailableOn(
            TargetPlatform.iOS,
            isWeb: false,
            serverClientId: 'test-server-client-id.apps.googleusercontent.com',
            iosClientId: 'test-ios-client-id.apps.googleusercontent.com',
            firebaseIosClientId: 'different-client.apps.googleusercontent.com',
            firebaseIosBundleId: 'com.clubhouse.livingpositively',
          ),
          isFalse,
        );
      },
    );

    test('should Apple sign-in requires iOS and the build capability', () {
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

    test(
      'should Apple sign-in returns null when the provider is unavailable',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        AuthService.debugAppleSignInEnabledOverride = false;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
          AuthService.debugAppleSignInEnabledOverride = null;
        });

        await expectLater(AuthService.signInWithApple(), completion(isNull));
      },
    );

    test(
      'should iOS Google sign-in forwards the configured native client ID',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        AuthService.debugGoogleSignInServerClientIdOverride =
            'server-client.apps.googleusercontent.com';
        AuthService.debugGoogleSignInIosClientIdOverride =
            'ios-client.apps.googleusercontent.com';
        AuthService.debugFirebaseIosClientIdOverride =
            'ios-client.apps.googleusercontent.com';
        AuthService.debugFirebaseIosBundleIdOverride =
            'com.clubhouse.livingpositively';
        String? receivedServerClientId;
        String? receivedIosClientId;
        AuthService.debugGoogleSignInStarterOverride =
            ({required serverClientId, clientId}) async {
              receivedServerClientId = serverClientId;
              receivedIosClientId = clientId;
              return null;
            };
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
          AuthService.debugGoogleSignInServerClientIdOverride = null;
          AuthService.debugGoogleSignInIosClientIdOverride = null;
          AuthService.debugFirebaseIosClientIdOverride = null;
          AuthService.debugFirebaseIosBundleIdOverride = null;
          AuthService.debugGoogleSignInStarterOverride = null;
        });

        await expectLater(AuthService.signInWithGoogle(), completion(isNull));

        expect(
          receivedServerClientId,
          'server-client.apps.googleusercontent.com',
        );
        expect(receivedIosClientId, 'ios-client.apps.googleusercontent.com');
      },
    );
  });
}
