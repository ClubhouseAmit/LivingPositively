// Drives the two TextButton onPressed handlers of ToFormPage:
//   - "Continue to personal plan form" pushes a FormProgressIndicator route
//     (lines 100-129 of lib/initialForm/toFormPage.dart)
//   - "Skip" pushes a Menu route via pushAndRemoveUntil (lines 139-149)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/initialForm/toFormPage.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _data() => PhonePageData(
      key: 'phone',
      header: 'h',
      subTitle: 's',
      midTitle: 'm',
      phoneNameTitle: 'n',
      phoneNumberTitle: 'p',
      phoneNames: const <String>[],
      phoneNumbers: const <String>[],
      savedPhoneNames: const <String>[],
      savedPhoneNumbers: const <String>[],
      phoneDescription: const <String>[],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('tapping the next button pushes a FormProgressIndicator',
      (tester) async {
    await pumpWithProviders(
      tester,
      ToFormPage(phonePageData: _data(), changeLocale: (_) {}),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);

    final buttons = find.byType(TextButton);
    expect(buttons.evaluate().length, greaterThanOrEqualTo(2));
    // First TextButton goes to the form.
    await tester.ensureVisible(buttons.first);
    await tester.tap(buttons.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(FormProgressIndicator), findsOneWidget);
  });

  testWidgets('tapping the skip button pushes a Menu route', (tester) async {
    await pumpWithProviders(
      tester,
      ToFormPage(phonePageData: _data(), changeLocale: (_) {}),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);

    final buttons = find.byType(TextButton);
    // Second TextButton is the skip.
    await tester.ensureVisible(buttons.at(1));
    await tester.tap(buttons.at(1), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(Menu), findsOneWidget);
  });
}
