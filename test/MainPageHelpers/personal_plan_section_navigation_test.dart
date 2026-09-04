import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/MainPageHelpers/components/personal_plan_section.dart';
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

    testWidgets('should render localized title in Hebrew and trigger onSeeAll by default when tapped', (
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

      // Assert localized copy is correctly rendered
      expect(find.text('התוכנית שלי'), findsOneWidget);

      // Locate interactive title target via stable key
      final titleHitTarget = find.byKey(const Key('personalPlanHeaderTitle'));
      expect(titleHitTarget, findsOneWidget);

      await tester.tap(titleHitTarget);
      await tester.pump();

      expect(seeAllCalled, isTrue);
    });

    testWidgets('should trigger onSeeAll by default when leading icon is tapped in Hebrew', (
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

      final iconFinder = find.byIcon(Icons.assignment_outlined);
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();

      expect(seeAllCalled, isTrue);
    });

    testWidgets('should trigger custom onTitleTap when provided explicitly', (
      tester,
    ) async {
      var titleTapCount = 0;
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
              titleTapCount++;
            },
          ),
        ),
        userInformation: user,
        locale: const Locale('he'),
      );

      final titleHitTarget = find.byKey(const Key('personalPlanHeaderTitle'));
      expect(titleHitTarget, findsOneWidget);

      await tester.tap(titleHitTarget);
      await tester.pump();
      expect(titleTapCount, equals(1));
      expect(seeAllCalled, isFalse);

      final iconFinder = find.byIcon(Icons.assignment_outlined);
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();
      expect(titleTapCount, equals(2));
      expect(seeAllCalled, isFalse);
    });

    testWidgets('should render localized title in English and trigger onSeeAll when tapped', (
      tester,
    ) async {
      var seeAllCount = 0;

      user.localeName = 'en';
      await pumpWithProviders(
        tester,
        Scaffold(
          body: PersonalPlanSectionWidget(
            items: const ['Item 1'],
            onSeeAll: () {
              seeAllCount++;
            },
          ),
        ),
        userInformation: user,
        locale: const Locale('en'),
      );

      // Assert English localized copy is correctly rendered
      expect(find.text('My Plan'), findsOneWidget);

      final iconFinder = find.byIcon(Icons.assignment_outlined);
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();
      expect(seeAllCount, equals(1));

      final titleHitTarget = find.byKey(const Key('personalPlanHeaderTitle'));
      expect(titleHitTarget, findsOneWidget);

      await tester.tap(titleHitTarget);
      await tester.pump();
      expect(seeAllCount, equals(2));
    });

    testWidgets(
      'should open the info modal without replacing title navigation or the overflow menu',
      (tester) async {
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
          surfaceSize: const Size(1024, 2400),
        );

        expect(
          find.byKey(const Key('personalPlanHeaderTitle')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('personalPlanHeaderMenu')), findsOneWidget);

        await tester.tap(find.byKey(const Key('homePersonalPlanInfoButton')));
        await tester.pumpAndSettle();

        expect(seeAllCalled, isFalse);
        expect(find.byKey(const Key('personalPlanInfoModal')), findsOneWidget);

        await tester.tap(find.byKey(const Key('personalPlanInfoCloseButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('personalPlanHeaderMenu')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('personalPlanHeaderShare')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('personalPlanHeaderDownload')),
          findsOneWidget,
        );
      },
    );

    testWidgets('should disable title tapping and omit button semantics when enableTitleTap is false', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        var seeAllCalled = false;
        var titleTapCalled = false;

        await pumpWithProviders(
          tester,
          Scaffold(
            body: PersonalPlanSectionWidget(
              items: const ['Item 1'],
              enableTitleTap: false,
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

        // When title tap is disabled, the stable interactive key should not be present
        expect(find.byKey(const Key('personalPlanHeaderTitle')), findsNothing);

        await tester.tap(titleFinder);
        await tester.pump();

        expect(seeAllCalled, isFalse);
        expect(titleTapCalled, isFalse);

        final semantics = tester.getSemantics(titleFinder);
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      } finally {
        handle.dispose();
      }
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

    testWidgets('should navigate to FullPlan when My Plan title is tapped on Home page', (
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

      // Verify localized copy
      expect(find.text('התוכנית שלי'), findsOneWidget);

      final myPlanTitleHitTarget = find.byKey(const Key('personalPlanHeaderTitle'));
      expect(myPlanTitleHitTarget, findsOneWidget);

      await tester.tap(myPlanTitleHitTarget);
      await tester.pump();

      expect(navigatedPage, equals(PagesCode.FullPlan));
    });

    testWidgets('should navigate to FullPlan when leading assignment icon is tapped on Home page', (
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

      final myPlanIconFinder = find.byIcon(Icons.assignment_outlined);
      expect(myPlanIconFinder, findsOneWidget);

      await tester.tap(myPlanIconFinder);
      await tester.pump();

      expect(navigatedPage, equals(PagesCode.FullPlan));
    });
  });
}
