import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/MainPageHelpers/components/gratitude_section.dart';
import 'package:mazilon/MainPageHelpers/components/virtues_section.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
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

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
    user.makeSafer = ['Call Alex', 'Go outside'];
    user.difficultEvents = ['Argument', 'Noise'];
    user.feelBetter = ['Music', 'Walk'];
    user.distractions = ['Puzzle', 'Tea'];
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('Home can rebuild without setState-during-build exceptions', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      Home(
        phonePageData: _phoneData(),
        changeCurrentIndex: (BuildContext context, PagesCode code) {},
        changeLocale: (_) {},
        openMainMenu: (_) {},
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Home places Gratitude Journal before Qualities List', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      Home(
        phonePageData: _phoneData(),
        changeCurrentIndex: (BuildContext context, PagesCode code) {},
        changeLocale: (_) {},
        openMainMenu: (_) {},
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );

    expect(find.byType(GratitudeSectionWidget), findsOneWidget);
    expect(find.byType(VirtuesSectionWidget), findsOneWidget);

    expect(
      tester.getTopLeft(find.byType(GratitudeSectionWidget)).dy,
      lessThan(tester.getTopLeft(find.byType(VirtuesSectionWidget)).dy),
    );
  });

  test(
    'home surfaces do not refresh randomized content from build methods',
    () {
      final homeSource = File('lib/pages/home.dart').readAsStringSync();
      final personalPlanSource = File(
        'lib/MainPageHelpers/personalPlanWidget.dart',
      ).readAsStringSync();
      final homeBuildPreamble = homeSource.substring(
        homeSource.indexOf('Widget build(BuildContext context)'),
        homeSource.indexOf('return Scaffold('),
      );
      final personalPlanBuildPreamble = personalPlanSource.substring(
        personalPlanSource.indexOf('Widget build(BuildContext context)'),
        personalPlanSource.indexOf('// the providers'),
      );

      expect(homeBuildPreamble, isNot(contains('setRandomPersonalWidgetText')));
      expect(personalPlanBuildPreamble, isNot(contains('loadFeelBetter')));
    },
  );
}
