import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/auth/auth_page.dart';
import 'package:mazilon/pages/auth/forgot_password_page.dart';
import 'package:mazilon/util/Firebase/auth_service.dart';
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
  setUp(() => registerTestServices(locale: 'en'));
  tearDown(() async {
    AuthService.debugAppleSignInEnabledOverride = null;
    AuthService.debugGoogleSignInServerClientIdOverride = null;
    debugDefaultTargetPlatformOverride = null;
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

  testWidgets(
    'disposed auth screen records the authenticated user after persistence',
    (tester) async {
      final userInformation = UserInformation();
      final firebaseUser = MockUser();
      when(firebaseUser.uid).thenReturn('uid-123');
      when(firebaseUser.email).thenReturn('person@example.com');
      when(firebaseUser.displayName).thenReturn('Person');
      final persistenceRead =
          Completer<DocumentSnapshot<Map<String, dynamic>>>();
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
                        (widget) =>
                            widget.runtimeType.toString() == '_LoginForm',
                      ),
                    )
                    .single
                as dynamic;
        final completion = (loginForm.onSuccess as Future<void> Function(User))(
          firebaseUser,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        expect(find.byType(AuthPage), findsNothing);
        expect(userInformation.loggedIn, isFalse);

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
    },
  );

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
      AuthService.debugGoogleSignInServerClientIdOverride = null;
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
    AuthService.debugAppleSignInEnabledOverride = null;
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
}
