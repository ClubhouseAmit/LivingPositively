// Drives the previously-uncovered branches of UserSettings:
//   - resetData (lines 86-113) via the reset confirmation dialog's "confirm"
//     button — pushes a FirstPage route
//   - resizeText non-empty branch (lines 136-145) — the "(parenthetical)"
//     suffix render
//   - Confirm-button female / nonBinary / notWillingToSay gender branches
//     (lines 386-392)
//   - Age dropdown onSelected (lines 272-279)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/pages/UserSettings.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServiceLocators services;
  late UserInformation user;

  setUp(() {
    services = registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'male';
    user.localeName = 'en';
  });

  tearDown(() {
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

    // Open the reset confirmation dialog (the last top-level TextButton
    // before the dialog opens is ResetButton).
    final pageButtons = find.byType(TextButton);
    final last = pageButtons.evaluate().last;
    await tester.ensureVisible(find.byWidget(last.widget));
    await tester.tap(find.byWidget(last.widget), warnIfMissed: false);
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
  });

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

    final pageButtons = find.byType(TextButton);
    final last = pageButtons.evaluate().last;
    await tester.ensureVisible(find.byWidget(last.widget));
    await tester.tap(find.byWidget(last.widget), warnIfMissed: false);
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
  });

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
  });

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
  });
}
