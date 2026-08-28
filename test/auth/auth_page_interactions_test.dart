import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/auth/auth_page.dart';
import 'package:mazilon/pages/auth/forgot_password_page.dart';
import 'package:mazilon/util/Firebase/auth_service.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../helpers/widget_test_scaffold.dart';

import 'auth_page_interactions_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<User>(),
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(),
  MockSpec<DocumentReference<Map<String, dynamic>>>(),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(),
])
void main() {
  setUp(() {
    registerTestServices(locale: 'en');
    FcmService.resetForTesting();
  });
  tearDown(() async {
    AuthService.debugAppleSignInEnabledOverride = null;
    AuthService.debugGoogleSignInServerClientIdOverride = null;
    AuthService.debugGoogleSignInIosClientIdOverride = null;
    AuthService.debugSignUpWithEmailOverride = null;
    debugDefaultTargetPlatformOverride = null;
    FcmService.resetForTesting();
    await GetIt.instance.reset();
  });

  test(
    'AuthService persists user profile through registered Firestore',
    () async {
      final firestore = FakeFirebaseFirestore();
      GetIt.instance.registerSingleton<FirebaseFirestore>(firestore);
      final user = MockUser();
      when(user.uid).thenReturn('uid-123');
      when(user.email).thenReturn('person@example.com');
      when(user.displayName).thenReturn('Person');

      await AuthService.saveUserToFirestore(user);

      final document = await firestore.collection('users').doc('uid-123').get();

      expect(document.data(), containsPair('email', 'person@example.com'));
      expect(document.data(), containsPair('displayName', 'Person'));
      expect(document.data(), containsPair('provider', 'password'));
    },
  );

  testWidgets('auth state is recorded before profile persistence completes', (
    tester,
  ) async {
    final userInformation = UserInformation();
    final firebaseUser = MockUser();
    when(firebaseUser.uid).thenReturn('uid-123');
    when(firebaseUser.email).thenReturn('person@example.com');
    when(firebaseUser.displayName).thenReturn('Person');
    final persistenceRead = Completer<DocumentSnapshot<Map<String, dynamic>>>();
    final firestore = MockFirebaseFirestore();
    final users = MockCollectionReference();
    final userDocument = MockDocumentReference();
    final documentSnapshot = MockDocumentSnapshot();
    when(firestore.collection('users')).thenReturn(users);
    when(users.doc('uid-123')).thenReturn(userDocument);
    when(userDocument.get()).thenAnswer((_) => persistenceRead.future);
    when(documentSnapshot.exists).thenReturn(false);
    GetIt.instance.registerSingleton<FirebaseFirestore>(firestore);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      await pumpWithProviders(
        tester,
        const AuthPage(),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );
      final loginForm =
          tester
                  .widgetList(
                    find.byWidgetPredicate(
                      (widget) => widget.runtimeType.toString() == '_LoginForm',
                    ),
                  )
                  .single
              as dynamic;
      final completion = (loginForm.onSuccess as Future<void> Function(User))(
        firebaseUser,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      expect(find.byType(AuthPage), findsNothing);
      expect(userInformation.loggedIn, isTrue);
      expect(userInformation.authDecisionMade, isTrue);

      persistenceRead.complete(documentSnapshot);
      await completion;

      expect(userInformation.loggedIn, isTrue);
      expect(userInformation.authDecisionMade, isTrue);
      expect(userInformation.userId, 'uid-123');
      expect(userInformation.email, 'person@example.com');
      expect(userInformation.displayName, 'Person');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('pending FCM refresh cannot delay authentication success', (
    tester,
  ) async {
    final userInformation = UserInformation();
    final firebaseUser = MockUser();
    when(firebaseUser.uid).thenReturn('uid-123');
    when(firebaseUser.email).thenReturn('person@example.com');
    when(firebaseUser.displayName).thenReturn('Person');
    final firestore = FakeFirebaseFirestore();
    GetIt.instance.registerSingleton<FirebaseFirestore>(firestore);
    final tokenRead = Completer<String?>();
    String? fcmUid;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FcmService.debugRequestPermissionOverride = () async =>
        _authorizedNotificationSettings();
    FcmService.debugInitializeLocalNotificationsOverride = () async {};
    FcmService.debugGetCurrentUserIdOverride = () => fcmUid;
    FcmService.debugGetTokenOverride = () async => 'initial-fcm-token';
    FcmService.debugRegisterListenersOverride = () {};
    await FcmService.initialize();
    fcmUid = 'uid-123';
    FcmService.debugGetTokenOverride = () => tokenRead.future;

    try {
      await pumpWithProviders(
        tester,
        const AuthPage(),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );
      final loginForm =
          tester
                  .widgetList(
                    find.byWidgetPredicate(
                      (widget) => widget.runtimeType.toString() == '_LoginForm',
                    ),
                  )
                  .single
              as dynamic;
      var callbackCompleted = false;
      final completion = (loginForm.onSuccess as Future<void> Function(User))(
        firebaseUser,
      )..then((_) => callbackCompleted = true);

      await tester.pump();

      expect(callbackCompleted, isTrue);
      expect(userInformation.loggedIn, isTrue);
      expect(userInformation.authDecisionMade, isTrue);
      expect(userInformation.userId, 'uid-123');

      tokenRead.complete(null);
      await completion;
    } finally {
      debugDefaultTargetPlatformOverride = null;
      if (!tokenRead.isCompleted) tokenRead.complete(null);
    }
  });

  testWidgets('notification auth pops while its FCM refresh is still pending', (
    tester,
  ) async {
    final userInformation = UserInformation();
    final firebaseUser = MockUser();
    when(firebaseUser.uid).thenReturn('uid-123');
    when(firebaseUser.email).thenReturn('person@example.com');
    when(firebaseUser.displayName).thenReturn('Person');
    GetIt.instance.registerSingleton<FirebaseFirestore>(
      FakeFirebaseFirestore(),
    );
    final tokenRead = Completer<String?>();
    String? fcmUid;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FcmService.debugRequestPermissionOverride = () async =>
        _authorizedNotificationSettings();
    FcmService.debugInitializeLocalNotificationsOverride = () async {};
    FcmService.debugGetCurrentUserIdOverride = () => fcmUid;
    FcmService.debugGetTokenOverride = () async => 'initial-fcm-token';
    FcmService.debugRegisterListenersOverride = () {};
    await FcmService.initialize();
    fcmUid = 'uid-123';
    FcmService.debugGetTokenOverride = () => tokenRead.future;

    try {
      await pumpWithProviders(
        tester,
        const _NotificationAuthLauncher(),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );
      await tester.tap(find.byKey(const Key('open-notification-auth')));
      await tester.pumpAndSettle();

      final loginForm =
          tester
                  .widgetList(
                    find.byWidgetPredicate(
                      (widget) => widget.runtimeType.toString() == '_LoginForm',
                    ),
                  )
                  .single
              as dynamic;
      final completion = (loginForm.onSuccess as Future<void> Function(User))(
        firebaseUser,
      );

      await tester.pumpAndSettle();

      expect(find.byType(AuthPage), findsNothing);
      expect(find.byKey(const Key('open-notification-auth')), findsOneWidget);
      expect(userInformation.loggedIn, isTrue);

      tokenRead.complete(null);
      await completion;
    } finally {
      debugDefaultTargetPlatformOverride = null;
      if (!tokenRead.isCompleted) tokenRead.complete(null);
    }
  });

  testWidgets('onboarding auth supports skip and signup validation', (
    tester,
  ) async {
    final userInformation = UserInformation();
    await pumpWithProviders(
      tester,
      const AuthPage(),
      userInformation: userInformation,
      surfaceSize: const Size(1024, 1800),
    );

    expect(find.text('Welcome'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    expect(find.text('Welcome'), findsOneWidget);

    await tester.tap(find.text('Skip for now'));
    await tester.pump();
    expect(userInformation.authDecisionMade, isTrue);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    await tester.tap(find.text('Create Account'));
    await tester.pump();
    expect(find.text('Full name'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'person@example.com');
    await tester.enterText(fields.at(2), 'secret');
    await tester.enterText(fields.at(3), 'different');
    await tester.tap(find.text('Create Account'));
    await tester.pump();
    expect(find.text("Passwords don't match"), findsOneWidget);

    await tester.enterText(fields.at(2), '123');
    await tester.enterText(fields.at(3), '123');
    await tester.tap(find.text('Create Account'));
    await tester.pump();
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('signup should continue when the display-name update fails', (
    tester,
  ) async {
    final userInformation = UserInformation();
    final user = MockUser();
    final credential = _MockUserCredential();
    when(credential.user).thenReturn(user);
    when(user.uid).thenReturn('uid-123');
    when(user.email).thenReturn('person@example.com');
    when(user.displayName).thenReturn(null);
    when(
      user.updateDisplayName('Person'),
    ).thenThrow(StateError('display-name update failed'));
    GetIt.instance.registerSingleton<FirebaseFirestore>(
      FakeFirebaseFirestore(),
    );
    AuthService.debugSignUpWithEmailOverride = (email, password) async {
      expect(email, 'person@example.com');
      expect(password, 'secret');
      return credential;
    };

    await pumpWithProviders(
      tester,
      const AuthPage(),
      userInformation: userInformation,
      surfaceSize: const Size(1024, 1800),
    );
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Person');
    await tester.enterText(fields.at(1), 'person@example.com');
    await tester.enterText(fields.at(2), 'secret');
    await tester.enterText(fields.at(3), 'secret');
    tester
        .widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Create Account'),
        )
        .onPressed!();
    await tester.pump();
    await tester.pump();

    expect(userInformation.loggedIn, isTrue);
    expect(userInformation.authDecisionMade, isTrue);
    expect(userInformation.userId, 'uid-123');
    verify(user.updateDisplayName('Person')).called(1);
    verifyNever(user.reload());
  });

  testWidgets('forgot-password navigation renders the reset form', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      const AuthPage(),
      surfaceSize: const Size(1024, 1800),
    );

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Send Reset Link'), findsOneWidget);

    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    expect(find.text('Invalid email address'), findsOneWidget);
  });

  testWidgets(
    'unsupported platforms hide the social section in login and signup',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await pumpWithProviders(
          tester,
          const AuthPage(),
          surfaceSize: const Size(1024, 1800),
        );

        void expectNoSocialSection() {
          expect(find.text('or'), findsNothing);
          expect(find.text('Continue with Google'), findsNothing);
          expect(find.text('Continue with Apple'), findsNothing);
        }

        expectNoSocialSection();
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expectNoSocialSection();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'Android hides the social section when Google is not configured',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AuthService.debugGoogleSignInServerClientIdOverride = '';
      AuthService.debugAppleSignInEnabledOverride = false;
      try {
        await pumpWithProviders(
          tester,
          const AuthPage(),
          surfaceSize: const Size(1024, 1800),
        );

        void expectNoSocialSection() {
          expect(find.text('or'), findsNothing);
          expect(find.text('Continue with Google'), findsNothing);
          expect(find.text('Continue with Apple'), findsNothing);
        }

        expectNoSocialSection();
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();
        expectNoSocialSection();
      } finally {
        AuthService.debugGoogleSignInServerClientIdOverride = null;
        AuthService.debugAppleSignInEnabledOverride = null;
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('Android shows only configured Google in login and signup', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AuthService.debugGoogleSignInServerClientIdOverride =
        'test-server-client-id.apps.googleusercontent.com';
    try {
      await pumpWithProviders(
        tester,
        const AuthPage(),
        surfaceSize: const Size(1024, 1800),
      );

      void expectGoogleOnly() {
        expect(find.text('or'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with Apple'), findsNothing);
      }

      expectGoogleOnly();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expectGoogleOnly();
    } finally {
      AuthService.debugGoogleSignInServerClientIdOverride = null;
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS hides the social section when Apple is not enabled', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    AuthService.debugGoogleSignInServerClientIdOverride = '';
    AuthService.debugAppleSignInEnabledOverride = false;
    try {
      await pumpWithProviders(
        tester,
        const AuthPage(),
        surfaceSize: const Size(1024, 1800),
      );

      void expectNoSocialSection() {
        expect(find.text('or'), findsNothing);
        expect(find.text('Continue with Google'), findsNothing);
        expect(find.text('Continue with Apple'), findsNothing);
      }

      expectNoSocialSection();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expectNoSocialSection();
    } finally {
      AuthService.debugAppleSignInEnabledOverride = null;
      AuthService.debugGoogleSignInServerClientIdOverride = null;
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS shows only Apple when its build capability is enabled', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    AuthService.debugAppleSignInEnabledOverride = true;
    try {
      await pumpWithProviders(
        tester,
        const AuthPage(),
        surfaceSize: const Size(1024, 1800),
      );

      void expectAppleOnly() {
        expect(find.text('or'), findsOneWidget);
        expect(find.text('Continue with Google'), findsNothing);
        expect(find.text('Continue with Apple'), findsOneWidget);
      }

      expectAppleOnly();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expectAppleOnly();
    } finally {
      AuthService.debugAppleSignInEnabledOverride = null;
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS shows configured Google in login and signup', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    AuthService.debugGoogleSignInServerClientIdOverride =
        'test-server-client-id.apps.googleusercontent.com';
    AuthService.debugGoogleSignInIosClientIdOverride =
        'test-ios-client-id.apps.googleusercontent.com';
    AuthService.debugFirebaseIosClientIdOverride =
        'test-ios-client-id.apps.googleusercontent.com';
    AuthService.debugFirebaseIosBundleIdOverride =
        'com.clubhouse.livingpositively';
    try {
      await pumpWithProviders(
        tester,
        const AuthPage(),
        surfaceSize: const Size(1024, 1800),
      );

      void expectGoogleOnly() {
        expect(find.text('or'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with Apple'), findsNothing);
      }

      expectGoogleOnly();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      expectGoogleOnly();
    } finally {
      AuthService.debugGoogleSignInServerClientIdOverride = null;
      AuthService.debugGoogleSignInIosClientIdOverride = null;
      AuthService.debugFirebaseIosClientIdOverride = null;
      AuthService.debugFirebaseIosBundleIdOverride = null;
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _NotificationAuthLauncher extends StatelessWidget {
  const _NotificationAuthLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        key: const Key('open-notification-auth'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AuthPage(fromNotifications: true),
            ),
          );
        },
        child: const Text('Open authentication'),
      ),
    );
  }
}

final class _MockUserCredential extends Mock implements UserCredential {}

NotificationSettings _authorizedNotificationSettings() {
  return const NotificationSettings(
    alert: AppleNotificationSetting.enabled,
    announcement: AppleNotificationSetting.disabled,
    authorizationStatus: AuthorizationStatus.authorized,
    badge: AppleNotificationSetting.enabled,
    carPlay: AppleNotificationSetting.disabled,
    criticalAlert: AppleNotificationSetting.disabled,
    lockScreen: AppleNotificationSetting.enabled,
    notificationCenter: AppleNotificationSetting.enabled,
    showPreviews: AppleShowPreviewSetting.always,
    sound: AppleNotificationSetting.enabled,
    timeSensitive: AppleNotificationSetting.disabled,
    providesAppNotificationSettings: AppleNotificationSetting.disabled,
  );
}
