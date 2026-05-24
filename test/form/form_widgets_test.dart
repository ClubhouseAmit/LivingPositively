// Smoke tests for the multi-step personal-plan form widgets:
//   - lib/form/form.dart (FormProgressIndicator)
//   - lib/form/phonePageform.dart (PhonePageForm)
//   - lib/form/phonePageListItem.dart (PhonePageList)
//   - lib/form/shareform.dart (ShareForm)
//
// These run the real production widgets via the shared widget_test_scaffold
// so all internal logic (initState controllers, Consumer<PhonePageData>,
// the page-progress indicator dots, etc.) is exercised.
//
// We avoid asserting on localized strings (the app loads the AppLocalizations
// delegate but production code uses myText/myAutoSizedText with arbitrary
// genders, so a single test cannot reliably name a string). Instead we
// assert on widget types and on state recorded back into the shared
// PhonePageData ChangeNotifier — that's where the value lives.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/form/phonePageListItem.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _makePhonePageData({
  List<String> names = const <String>[],
  List<String> numbers = const <String>[],
}) =>
    PhonePageData(
      key: 'phonePage',
      header: 'Phones',
      subTitle: 'Sub',
      midTitle: 'Mid',
      phoneNameTitle: 'Name',
      phoneNumberTitle: 'Phone',
      phoneNames: const <String>[],
      phoneNumbers: const <String>[],
      savedPhoneNames: List<String>.from(names),
      savedPhoneNumbers: List<String>.from(numbers),
      phoneDescription: const <String>[],
    );

/// Allow the post-frame loadItemsFromPrefs in PhonePageData's constructor
/// to settle without producing visible-overflow noise that aborts the test.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  drainOverflowExceptions(tester);
}

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

  group('ShareForm (real production widget)', () {
    testWidgets('renders share and download icons', (tester) async {
      await pumpWithProviders(
        tester,
        ShareForm(prev: () {}, submit: (_) {}),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );
      await _settle(tester);

      expect(find.byType(ShareForm), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });

  group('PhonePageList (real production widget)', () {
    testWidgets('renders the manual-add TextButton with empty data',
        (tester) async {
      final phoneData = _makePhonePageData();

      await pumpWithProviders(
        tester,
        ChangeNotifierProvider<PhonePageData>.value(
          value: phoneData,
          child: Scaffold(
            body: SingleChildScrollView(
              child: PhonePageList(phonePageData: phoneData),
            ),
          ),
        ),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 2000),
      );
      await _settle(tester);

      expect(find.byType(PhonePageList), findsOneWidget);
      // The manual-add row is the bottom TextButton.
      expect(find.byType(TextButton), findsWidgets);
    });

    testWidgets('manual-add TextButton appends an empty phone row',
        (tester) async {
      final phoneData = _makePhonePageData();

      await pumpWithProviders(
        tester,
        ChangeNotifierProvider<PhonePageData>.value(
          value: phoneData,
          child: Scaffold(
            body: SingleChildScrollView(
              child: PhonePageList(phonePageData: phoneData),
            ),
          ),
        ),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 2000),
      );
      await _settle(tester);

      // Wait for the loadItemsFromPrefs Future scheduled in the
      // PhonePageData constructor to finish.
      await tester.pump(const Duration(milliseconds: 50));
      drainOverflowExceptions(tester);

      final beforeNames = List<String>.from(phoneData.savedPhoneNames);
      final manualAdd = find.byType(TextButton).last;
      await tester.tap(manualAdd, warnIfMissed: false);
      await tester.pump();
      drainOverflowExceptions(tester);

      // A new (empty) entry should be appended.
      expect(phoneData.savedPhoneNames.length, beforeNames.length + 1);
      expect(phoneData.savedPhoneNames.last, '');
    });

    testWidgets('PhonePageData seeded with two entries renders Card widgets',
        (tester) async {
      // PhonePageData's constructor calls loadItemsFromPrefs() which
      // overwrites our seeded lists with whatever is in
      // PersistentMemoryService. To keep the two seeded entries visible we
      // seed the fake persistent store first.
      final services = registerTestServices(locale: 'en');
      await services.memory.setItem(
        'phonePageSavedPhoneNames',
        PersistentMemoryType.StringList,
        <String>['Alice', 'Bob'],
      );
      await services.memory.setItem(
        'phonePageSavedPhoneNumbers',
        PersistentMemoryType.StringList,
        <String>['111', '222'],
      );
      final phoneData = _makePhonePageData(
        names: const <String>['Alice', 'Bob'],
        numbers: const <String>['111', '222'],
      );

      await pumpWithProviders(
        tester,
        ChangeNotifierProvider<PhonePageData>.value(
          value: phoneData,
          child: Scaffold(
            body: SingleChildScrollView(
              child: PhonePageList(phonePageData: phoneData),
            ),
          ),
        ),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 2000),
      );
      await _settle(tester);

      // Card is the production widget used to display a phone entry.
      expect(find.byType(Card), findsWidgets);
    });
  });

  group('PhonePageForm (real production widget)', () {
    testWidgets('renders header, import button, list, and confirmation button',
        (tester) async {
      final phoneData = _makePhonePageData();
      bool nextCalled = false;

      await pumpWithProviders(
        tester,
        ChangeNotifierProvider<PhonePageData>.value(
          value: phoneData,
          child: PhonePageForm(
            next: () => nextCalled = true,
            prev: () {},
            phonePageData: phoneData,
          ),
        ),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 2000),
      );
      await _settle(tester);

      expect(find.byType(PhonePageForm), findsOneWidget);
      // Embedded PhonePageList is built via Consumer<PhonePageData>.
      expect(find.byType(PhonePageList), findsOneWidget);
      // Next/import buttons render — exact tap is platform-channel
      // sensitive (FlutterContacts), so we only assert presence here.
      expect(find.byType(TextButton), findsWidgets);
      expect(nextCalled, isFalse);
    });
  });

  group('FormProgressIndicator (real production widget)', () {
    testWidgets('renders the first step and progress indicator dots',
        (tester) async {
      final phoneData = _makePhonePageData();

      await pumpWithProviders(
        tester,
        ChangeNotifierProvider<PhonePageData>.value(
          value: phoneData,
          child: FormProgressIndicator(
            phonePageData: phoneData,
            changeLocale: (_) {},
          ),
        ),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 2000),
      );
      await _settle(tester);

      expect(find.byType(FormProgressIndicator), findsOneWidget);
      // The progress indicator renders animated container dots for each step.
      expect(find.byType(AnimatedContainer), findsWidgets);
    });
  });
}
