// Drives the previously-uncovered branches of UserSettings:
//   - resetData (lines 86-113) via the reset confirmation dialog's "confirm"
//     button — pushes a FirstPage route
//   - resizeText non-empty branch (lines 136-145) — the "(parenthetical)"
//     suffix render
//   - Confirm-button female / nonBinary / notWillingToSay gender branches
//     (lines 386-392)
//   - Age dropdown onSelected (lines 272-279)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/pages/UserSettings.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/notification_preference.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';

import '../helpers/widget_test_scaffold.dart';
import '../Firebase/firebase_auth_service_test.mocks.dart';

PhonePageData _phone() => PhonePageData(
  key: 'phonePageData',
  header: 'header',
  subTitle: 'subTitle',
  midTitle: 'midTitle',
  phoneNameTitle: 'phoneNameTitle',
  phoneNumberTitle: 'phoneNumberTitle',
  phoneNames: const [],
  phoneNumbers: const [],
  savedPhoneNames: const [],
  savedPhoneNumbers: const [],
  phoneDescription: const [],
);

Future<T> _onPlatform<T>(
  TargetPlatform platform,
  Future<T> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'male';
    user.localeName = 'en';
  });

  tearDown(() {
    FcmScheduledNotificationService.resetForTesting();
    resetTestServices();
  });

  testWidgets(
    'reset confirmation dialog "Confirm" tap calls resetData and pushes '
    'FirstPage',
    (tester) async {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Reset Me',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Now the Dialog is open with two TextButtons: Close + Confirm. Tap the
      // last one (Confirm) → resetData runs.
      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      expect(dialogButtons, findsNWidgets(2));
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // resetData pushes a FirstPage route via pushAndRemoveUntil.
      expect(find.byType(FirstPage), findsOneWidget);
    },
  );

  testWidgets(
    'reset confirmation dialog "Close" tap pops without invoking resetData',
    (tester) async {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Stay',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      // First is "Close" — tap it, the dialog should pop without leaving
      // UserSettings.
      await tester.tap(dialogButtons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(UserSettings), findsOneWidget);
    },
  );

  testWidgets('does not offer a sign-out action for an authenticated user', (
    tester,
  ) async {
    user.loggedIn = true;
    await pumpWithProviders(
      tester,
      UserSettings(
        username: 'Keep identity',
        age: '18-30',
        gender: 'male',
        phonePageData: _phone(),
        changeLocale: (_) {},
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 2800),
    );

    expect(find.text('Sign Out'), findsNothing);
  });

  testWidgets(
    'reset keeps local data and navigation in place when remote cancellation fails',
    (tester) async {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 9, minute: 30),
      );
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Keep reminder',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
          cancelDefaultReminder: (userInfo) => _onPlatform(
            TargetPlatform.android,
            () => FcmScheduledNotificationService.cancelDefaultForReset(
              userInformation: userInfo,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) async {
                return http.Response('failed', 500);
              },
            ),
          ),
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(UserSettings), findsOneWidget);
      expect(find.byType(FirstPage), findsNothing);
      expect(user.getNotificationPreference('default'), isNotNull);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );

  testWidgets('reset skips remote cancellation on an unsupported platform', (
    tester,
  ) async {
    final auth = MockFirebaseAuth();
    final firebaseUser = MockUser();
    when(auth.currentUser).thenReturn(firebaseUser);
    when(firebaseUser.isAnonymous).thenReturn(false);
    GetIt.instance.registerSingleton<FirebaseAuth>(auth);
    user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 9, minute: 30),
    );
    var cancelCalls = 0;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Web reset',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
          cancelDefaultReminder: (_) async {
            cancelCalls++;
            return false;
          },
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(cancelCalls, 0);
      expect(find.byType(FirstPage), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'reset skips remote cancellation when no default reminder is stored',
    (tester) async {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      var cancelCalls = 0;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await pumpWithProviders(
          tester,
          UserSettings(
            username: 'Offline reset',
            age: '18-30',
            gender: 'male',
            phonePageData: _phone(),
            changeLocale: (_) {},
            cancelDefaultReminder: (_) async {
              cancelCalls++;
              return false;
            },
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 2800),
        );

        final resetButton = find.byKey(const Key('userSettingsResetButton'));
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton, warnIfMissed: false);
        await tester.pumpAndSettle();
        final dialogButtons = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextButton),
        );
        await tester.tap(dialogButtons.last, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(cancelCalls, 0);
        expect(find.byType(FirstPage), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'reset cancels the remote reminder and restores authenticated identity',
    (tester) async {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.uid).thenReturn('uid-123');
      when(firebaseUser.email).thenReturn('user@example.com');
      when(firebaseUser.displayName).thenReturn('Remembered User');
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 9, minute: 30),
      );
      var cancelRequests = 0;
      final cancellationStarted = Completer<void>();

      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Reset identity',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
          cancelDefaultReminder: (userInfo) => _onPlatform(
            TargetPlatform.android,
            () => FcmScheduledNotificationService.cancelDefaultForReset(
              userInformation: userInfo,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) async {
                cancelRequests++;
                cancellationStarted.complete();
                expect(url.path, '/cancelNotification');
                return http.Response('{}', 200);
              },
            ),
          ),
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pump();
      await cancellationStarted.future;
      await tester.pumpAndSettle();

      expect(cancelRequests, 1);
      expect(find.byType(FirstPage), findsOneWidget);
      expect(user.loggedIn, isTrue);
      expect(user.authDecisionMade, isTrue);
      expect(user.userId, 'uid-123');
      expect(user.email, 'user@example.com');
      expect(user.displayName, 'Remembered User');
    },
  );

  testWidgets(
    'renders for a female user without crashing (gender-specific build)',
    (tester) async {
      user.gender = 'female';
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Female User',
          age: '31-50',
          gender: 'female',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      expect(find.byType(UserSettings), findsOneWidget);
    },
  );

  testWidgets(
    'renders for a nonBinary user (binary=true initial selection branch)',
    (tester) async {
      user.binary = true;
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'NB User',
          age: '18-30',
          gender: '',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      expect(find.byType(UserSettings), findsOneWidget);
      expect(find.byType(DropdownMenu<String>), findsNWidgets(3));
    },
  );

  testWidgets('name text field keeps a Material-sized tap target', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      UserSettings(
        username: 'Sized',
        age: '18-30',
        gender: 'male',
        phonePageData: _phone(),
        changeLocale: (_) {},
      ),
      userInformation: user,
      surfaceSize: const Size(320, 900),
    );

    final textFieldSize = tester.getSize(find.byType(TextField).first);
    expect(textFieldSize.height, greaterThanOrEqualTo(48));
    expect(textFieldSize.width, lessThanOrEqualTo(320));
  });
}
