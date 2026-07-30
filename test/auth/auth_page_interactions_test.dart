import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/auth/auth_page.dart';
import 'package:mazilon/pages/auth/forgot_password_page.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  setUp(() => registerTestServices(locale: 'en'));
  tearDown(() => GetIt.instance.reset());

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
    expect(find.text('Check your email for a reset link'), findsNothing);
  });
}
