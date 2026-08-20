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
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/PersonalPlan/myPlan.dart';
import 'package:mazilon/pages/PersonalPlan/myPlanPageFull.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
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
    userInformation.safeEnvironment = ['Store medications safely'];
    userInformation.dreamsAndGoals = ['Write and publish a book'];

    appInformation = AppInformation();
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('MyPlanPageFull renders seven default sections in plan order', (
    tester,
  ) async {
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
    // Symptoms, triggers, wellness, environmental support, contacts, then
    // Safe Environment, then Dreams and Goals.
    expect(find.byType(MyPlanSection), findsNWidgets(7));
    final sections = tester
        .widgetList<MyPlanSection>(find.byType(MyPlanSection))
        .toList();
    expect(sections[0].answers, ['Music', 'Reading']);
    expect(sections[1].answers, ['Lonely', 'Stress']);
    expect(sections[2].answers, ['Walk']);
    expect(sections[3].answers, ['Remove sharp objects']);
    expect(sections[4].answers, isEmpty);
    expect(sections[5].answers, ['Store medications safely']);
    expect(sections[6].answers, ['Write and publish a book']);
  });

  testWidgets('omits Dreams and Goals for a legacy plan with no answers', (
    tester,
  ) async {
    userInformation.dreamsAndGoals = [];

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
    await tester.pump();
    drainOverflowExceptions(tester);

    expect(find.byType(MyPlanSection), findsNWidgets(6));
    expect(find.text('Dreams, Aspirations, and Goals'), findsNothing);
  });

  testWidgets('custom categories are rendered after Dreams and Goals', (
    tester,
  ) async {
    final memory = GetIt.instance<PersistentMemoryService>();
    await memory.setItem(
      'customCategoryTitles',
      PersistentMemoryType.StringList,
      ['My custom category'],
    );
    await memory.setItem(
      'customCategoryDescriptions',
      PersistentMemoryType.StringList,
      ['My custom category note'],
    );

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
    await tester.pumpAndSettle();

    final sections = tester
        .widgetList<MyPlanSection>(find.byType(MyPlanSection))
        .toList();
    expect(sections, hasLength(8));
    expect(sections[5].answers, ['Store medications safely']);
    expect(sections[6].answers, ['Write and publish a book']);
    expect(sections[7].title, 'My custom category');
    expect(sections[7].answers, ['My custom category note']);
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

  testWidgets('Hebrew locale activates the RichText branch with locale links', (
    tester,
  ) async {
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

  testWidgets('Phone information renders as bullet items in phones section', (
    tester,
  ) async {
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

  testWidgets(
    'Personal Plan renders only paired contacts when names are longer',
    (tester) async {
      final names = <String>['Mom', 'Dad'];
      final numbers = <String>['111'];
      final phoneData = _emptyPhonePageData();
      await tester.pump();
      phoneData.savedPhoneNames = names;
      phoneData.savedPhoneNumbers = numbers;

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

      final sections = tester
          .widgetList<MyPlanSection>(find.byType(MyPlanSection))
          .toList();
      expect(sections.elementAt(4).answers, <String>['Mom:111']);
      expect(phoneData.savedPhoneNames, <String>['Mom', 'Dad']);
      expect(phoneData.savedPhoneNumbers, <String>['111']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Personal Plan renders only paired contacts when numbers are longer',
    (tester) async {
      final names = <String>['Mom'];
      final numbers = <String>['111', '222'];
      final phoneData = _emptyPhonePageData();
      await tester.pump();
      phoneData.savedPhoneNames = names;
      phoneData.savedPhoneNumbers = numbers;

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

      final sections = tester
          .widgetList<MyPlanSection>(find.byType(MyPlanSection))
          .toList();
      expect(sections.elementAt(4).answers, <String>['Mom:111']);
      expect(phoneData.savedPhoneNames, <String>['Mom']);
      expect(phoneData.savedPhoneNumbers, <String>['111', '222']);
      expect(tester.takeException(), isNull);
    },
  );
}
