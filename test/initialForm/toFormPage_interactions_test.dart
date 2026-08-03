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
    registerTestServices();
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(resetTestServices);

  testWidgets('tapping the next button pushes a FormProgressIndicator',
      (tester) async {
    await pumpWithProviders(
      tester,
      Scaffold(body: ToFormPage(phonePageData: _data(), changeLocale: (_) {})),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);

    final buttons = find.byType(ElevatedButton);
    expect(buttons, findsOneWidget);
    // First ElevatedButton goes to the form.
    await tester.ensureVisible(buttons);
    await tester.tap(buttons, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(FormProgressIndicator), findsOneWidget);
  });

  testWidgets('tapping the skip button pushes a Menu route', (tester) async {
    await pumpWithProviders(
      tester,
      Scaffold(body: ToFormPage(phonePageData: _data(), changeLocale: (_) {})),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);

    final skipBtn = find.byType(OutlinedButton);
    expect(skipBtn, findsOneWidget);
    await tester.ensureVisible(skipBtn);
    await tester.tap(skipBtn, warnIfMissed: false);
    await tester.pumpAndSettle();
    drainOverflowExceptions(tester);

    expect(find.byType(Menu), findsOneWidget);
  });
}
