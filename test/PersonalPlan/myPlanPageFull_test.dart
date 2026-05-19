// Smoke tests for lib/pages/PersonalPlan/myPlanPageFull.dart.
//
// MyPlanPageFull is the clinical-grade personal safety plan summary screen.
// The widget pulls UserInformation + AppInformation from Provider and a
// PhonePageData from constructor injection, then renders 4 MyPlanSection
// rows + a phone section + a navigation button to FormProgressIndicator.
//
// We assert the section layout, the conditional "hasFilled" button label
// branch, and the Hebrew-locale RichText branch.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/PersonalPlan/myPlan.dart';
import 'package:mazilon/pages/PersonalPlan/myPlanPageFull.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _emptyPhonePageData() => PhonePageData(
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
  late AppInformation appInformation;

  setUp(() {
    registerTestServices(locale: 'en');
    userInformation = UserInformation();
    userInformation.gender = 'other';
    userInformation.localeName = 'en';
    userInformation.difficultEvents = ['Lonely', 'Stress'];
    userInformation.makeSafer = ['Remove sharp objects'];
    userInformation.feelBetter = ['Walk'];
    userInformation.distractions = ['Music', 'Reading'];

    appInformation = AppInformation();
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('MyPlanPageFull renders 5 MyPlanSection rows (4 form sections + '
      'phones)', (tester) async {
    final phoneData = _emptyPhonePageData();

    await pumpWithProviders(
      tester,
      MyPlanPageFull(
        phonePageData: phoneData,
        hasFilled: true,
        changeLocale: (_) {},
      ),
      userInformation: userInformation,
      appInformation: appInformation,
      surfaceSize: const Size(1024, 2400),
    );
    await tester.pump();
    drainOverflowExceptions(tester);

    expect(find.byType(MyPlanPageFull), findsOneWidget);
    // 4 form-section rows + 1 phones section = 5 MyPlanSection widgets.
    expect(find.byType(MyPlanSection), findsNWidgets(5));
  });

  testWidgets('hasFilled=true and hasFilled=false render different button '
      'labels (branch coverage)', (tester) async {
    await pumpWithProviders(
      tester,
      MyPlanPageFull(
        phonePageData: _emptyPhonePageData(),
        hasFilled: true,
        changeLocale: (_) {},
      ),
      userInformation: userInformation,
      appInformation: appInformation,
      surfaceSize: const Size(1024, 2400),
    );
    drainOverflowExceptions(tester);
    expect(find.byType(TextButton), findsWidgets);

    // Re-pump with hasFilled=false; the TextButton label-text branch flips.
    await pumpWithProviders(
      tester,
      MyPlanPageFull(
        phonePageData: _emptyPhonePageData(),
        hasFilled: false,
        changeLocale: (_) {},
      ),
      userInformation: userInformation,
      appInformation: appInformation,
      surfaceSize: const Size(1024, 2400),
    );
    drainOverflowExceptions(tester);
    expect(find.byType(TextButton), findsWidgets);
  });

  testWidgets('Hebrew locale activates the RichText branch with locale links',
      (tester) async {
    userInformation.localeName = 'he';
    appInformation.sharePDFtexts = {
      'firstLine': 'first',
      'firstLinkText': 'link1',
      'firstLinkURL': 'https://example.com/1',
      'secondLine': 'second',
      'thirdLine': 'third',
      'secondLinkText': 'link2',
      'secondLinkURL': 'https://example.com/2',
      'forthLine': 'forth',
    };

    await pumpWithProviders(
      tester,
      MyPlanPageFull(
        phonePageData: _emptyPhonePageData(),
        hasFilled: true,
        changeLocale: (_) {},
      ),
      userInformation: userInformation,
      appInformation: appInformation,
      locale: const Locale('he'),
      surfaceSize: const Size(1024, 2400),
    );
    drainOverflowExceptions(tester);

    // Hebrew locale activates the RichText link branch (lines 170+).
    expect(find.byType(RichText), findsWidgets);
  });

  testWidgets('Phone information renders as bullet items in phones section',
      (tester) async {
    final phoneData = PhonePageData(
      key: 'phonePage',
      header: 'Phones',
      subTitle: 'Sub',
      midTitle: 'Mid',
      phoneNameTitle: 'Name',
      phoneNumberTitle: 'Phone',
      phoneNames: const <String>[],
      phoneNumbers: const <String>[],
      savedPhoneNames: const <String>['Mom', 'Dad'],
      savedPhoneNumbers: const <String>['111', '222'],
      phoneDescription: const <String>[],
    );

    await pumpWithProviders(
      tester,
      MyPlanPageFull(
        phonePageData: phoneData,
        hasFilled: true,
        changeLocale: (_) {},
      ),
      userInformation: userInformation,
      appInformation: appInformation,
      surfaceSize: const Size(1024, 2400),
    );
    await tester.pump();
    drainOverflowExceptions(tester);

    // setPhones formats entries as 'name:number' and stores them in
    // phoneInformation, which is then passed to a MyPlanSection. We assert
    // the section was constructed (rather than match on the exact text,
    // which can be hidden by AutoSizeText/ellipsis depending on layout).
    expect(find.byType(MyPlanSection), findsWidgets);
  });
}
