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

    testWidgets('should trigger onTitleTap callback when title hit target is tapped', (
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
              titleKey: const Key('customTitleKey'),
              leadingIcon: Icons.star,
              onTitleTap: () {
                tapped = true;
              },
            ),
          ),
        );

        final titleFinder = find.byKey(const Key('customTitleKey'));
        expect(titleFinder, findsOneWidget);

        await tester.tap(titleFinder);
        await tester.pump();

        expect(tapped, isTrue);

        final semantics = tester.getSemantics(find.text('My Section'));
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('should trigger onTitleTap callback when leading icon is tapped', (
      tester,
    ) async {
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

      final iconFinder = find.byIcon(Icons.star);
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should occupy full width of Expanded and be tappable in whitespace', (
      tester,
    ) async {
      var tapCount = 0;
      await pumpWithProviders(
        tester,
        Scaffold(
          body: SizedBox(
            width: 400,
            child: SectionHeaderWidget(
              title: 'Title',
              leadingIcon: Icons.star,
              onTitleTap: () {
                tapCount++;
              },
            ),
          ),
        ),
        surfaceSize: const Size(600, 800),
      );

      // Tap near the far end of the Expanded region (e.g. at x=250)
      await tester.tapAt(const Offset(250, 20));
      await tester.pump();

      expect(tapCount, equals(1));
    });

    testWidgets('should not wrap with button semantics when onTitleTap is null', (
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
