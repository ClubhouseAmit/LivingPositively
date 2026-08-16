import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/MainPageHelpers/components/personal_plan_section.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
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

  group('SectionHeaderWidget onTitleTap', () {
    setUp(() {
      registerTestServices(locale: 'en');
    });

    tearDown(() {
      resetTestServices();
    });

    testWidgets('triggers onTitleTap callback when tapped and has button semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        var tapped = false;
        await pumpWithProviders(
          tester,
          Scaffold(
            body: SectionHeaderWidget(
              title: 'My Section',
              leadingIcon: Icons.star,
              onTitleTap: () {
                tapped = true;
              },
            ),
          ),
        );

        final titleFinder = find.text('My Section');
        expect(titleFinder, findsOneWidget);

        await tester.tap(titleFinder);
        await tester.pump();

        expect(tapped, isTrue);

        final semantics = tester.getSemantics(titleFinder);
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('does not wrap with button semantics when onTitleTap is null', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpWithProviders(
          tester,
          const Scaffold(
            body: SectionHeaderWidget(
              title: 'Static Section',
              leadingIcon: Icons.star,
            ),
          ),
        );

        final titleFinder = find.text('Static Section');
        expect(titleFinder, findsOneWidget);

        final semantics = tester.getSemantics(titleFinder);
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      } finally {
        handle.dispose();
      }
    });
  });

  group('PersonalPlanSectionWidget clickable title', () {
    late UserInformation user;

    setUp(() {
      registerTestServices(locale: 'he');
      user = UserInformation();
      user.gender = 'male';
      user.localeName = 'he';
      user.makeSafer = ['Test Safe Item'];
      user.feelBetter = ['Test Feel Better Item'];
    });

    tearDown(() {
      resetTestServices();
    });

    testWidgets('tapping title triggers onSeeAll by default (Hebrew)', (
      tester,
    ) async {
      var seeAllCalled = false;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: PersonalPlanSectionWidget(
            items: const ['Item 1', 'Item 2'],
            onSeeAll: () {
              seeAllCalled = true;
            },
          ),
        ),
        userInformation: user,
        locale: const Locale('he'),
      );

      // Hebrew title for My Plan is "התוכנית שלי"
      final titleFinder = find.text('התוכנית שלי');
      expect(titleFinder, findsOneWidget);

      await tester.tap(titleFinder);
      await tester.pump();

      expect(seeAllCalled, isTrue);
    });

    testWidgets('tapping title triggers onTitleTap when provided explicitly', (
      tester,
    ) async {
      var titleTapCalled = false;
      var seeAllCalled = false;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: PersonalPlanSectionWidget(
            items: const ['Item 1'],
            onSeeAll: () {
              seeAllCalled = true;
            },
            onTitleTap: () {
              titleTapCalled = true;
            },
          ),
        ),
        userInformation: user,
        locale: const Locale('he'),
      );

      final titleFinder = find.text('התוכנית שלי');
      expect(titleFinder, findsOneWidget);

      await tester.tap(titleFinder);
      await tester.pump();

      expect(titleTapCalled, isTrue);
      expect(seeAllCalled, isFalse);
    });

    testWidgets('tapping leading icon or title triggers onTitleTap in English', (
      tester,
    ) async {
      var seeAllCalled = false;

      user.localeName = 'en';
      await pumpWithProviders(
        tester,
        Scaffold(
          body: PersonalPlanSectionWidget(
            items: const ['Item 1'],
            onSeeAll: () {
              seeAllCalled = true;
            },
          ),
        ),
        userInformation: user,
        locale: const Locale('en'),
      );

      final titleFinder = find.text('My Plan');
      expect(titleFinder, findsOneWidget);

      await tester.tap(titleFinder);
      await tester.pump();

      expect(seeAllCalled, isTrue);
    });
  });

  group('Home Page My Plan title navigation integration', () {
    late UserInformation user;

    setUp(() {
      registerTestServices(locale: 'he');
      user = UserInformation();
      user.gender = 'male';
      user.localeName = 'he';
      user.makeSafer = ['Plan item 1'];
      user.feelBetter = ['Plan item 2'];
    });

    tearDown(() {
      resetTestServices();
    });

    testWidgets('tapping "התוכנית שלי" title on Home page navigates to FullPlan', (
      tester,
    ) async {
      PagesCode? navigatedPage;

      await pumpWithProviders(
        tester,
        Home(
          phonePageData: _phoneData(),
          changeCurrentIndex: (BuildContext context, PagesCode code) {
            navigatedPage = code;
          },
          changeLocale: (_) {},
          openMainMenu: (_) {},
        ),
        userInformation: user,
        locale: const Locale('he'),
        surfaceSize: const Size(1024, 2400),
      );

      final myPlanTitleFinder = find.text('התוכנית שלי');
      expect(myPlanTitleFinder, findsOneWidget);

      await tester.tap(myPlanTitleFinder);
      await tester.pump();

      expect(navigatedPage, equals(PagesCode.FullPlan));
    });
  });
}
