// Widget tests for lib/pages/SignIn_Pages/firstPage.dart.
//
// FirstPage is the small dispatcher widget at app entry that picks the
// initial screen based on UserInformation state. Branches:
//   1. !disclaimerSigned         → DisclaimerPage
//   2. disclaimerSigned, firsttime → InitialFormProgressIndicator
//   3. disclaimerSigned, !firsttime → Menu
//
// We pump each combination and assert the chosen widget appears.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/disclaimerPage.dart';
import 'package:mazilon/initialForm/form.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
      key: 'phonePage',
      header: 'Phones',
      subTitle: 'Sub',
      midTitle: 'Mid',
      phoneNameTitle: 'Name',
      phoneNumberTitle: 'Phone',
      phoneNames: const <String>[],
      phoneNumbers: const <String>[],
      savedPhoneNames: const <String>[],
      savedPhoneNumbers: const <String>[],
      phoneDescription: const <String>[],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation userInformation;

  setUp(() {
    registerTestServices(locale: 'en');
    userInformation = UserInformation();
    userInformation.gender = 'other';
    userInformation.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('disclaimerSigned=false → renders DisclaimerPage', (tester) async {
    userInformation.disclaimerSigned = false;

    await pumpWithProviders(
      tester,
      FirstPage(
        firsttime: true,
        hasFilled: false,
        changeLocale: (_) {},
        phonePageData: _phoneData(),
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1024, 1800),
    );

    expect(find.byType(FirstPage), findsOneWidget);
    expect(find.byType(DisclaimerPage), findsOneWidget);
    expect(find.byType(InitialFormProgressIndicator), findsNothing);
    expect(find.byType(Menu), findsNothing);
  });

  testWidgets('disclaimerSigned=true + firsttime=true → InitialFormProgressIndicator',
      (tester) async {
    userInformation.disclaimerSigned = true;

    await pumpWithProviders(
      tester,
      FirstPage(
        firsttime: true,
        hasFilled: false,
        changeLocale: (_) {},
        phonePageData: _phoneData(),
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1024, 1800),
    );

    expect(find.byType(InitialFormProgressIndicator), findsOneWidget);
    expect(find.byType(DisclaimerPage), findsNothing);
    expect(find.byType(Menu), findsNothing);
  });

  testWidgets('disclaimerSigned=true + firsttime=false → Menu', (tester) async {
    userInformation.disclaimerSigned = true;

    await pumpWithProviders(
      tester,
      FirstPage(
        firsttime: false,
        hasFilled: true,
        changeLocale: (_) {},
        phonePageData: _phoneData(),
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1024, 1800),
    );

    expect(find.byType(Menu), findsOneWidget);
    expect(find.byType(InitialFormProgressIndicator), findsNothing);
    expect(find.byType(DisclaimerPage), findsNothing);
  });
}
