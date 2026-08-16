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

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/form/phonePageListItem.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/form/speech_dictation_suffix_action.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _makePhonePageData({
  List<String> names = const <String>[],
  List<String> numbers = const <String>[],
}) => PhonePageData(
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

class _RecordingUrlLauncherPlatform extends UrlLauncherPlatform {
  final List<String> launchedUrls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return true;
  }
}

/// Allow the post-frame loadItemsFromPrefs in PhonePageData's constructor
/// to settle without producing visible-overflow noise that aborts the test.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  drainOverflowExceptions(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation userInformation;
  late TestServiceLocators services;

  setUp(() {
    services = registerTestServices(locale: 'en');
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
        wizardStepHarness(
          ShareForm(
            key: GlobalKey<WizardStepState>(),
            prev: () {},
            submit: (_) {},
          ),
        ),
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
    testWidgets('renders the manual-add TextButton with empty data', (
      tester,
    ) async {
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

    testWidgets(
      'manual-add TextButton opens a draft without persisting blank',
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

        expect(phoneData.savedPhoneNames.length, beforeNames.length);
        expect(find.byType(TextFormField), findsNWidgets(2));

        await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
        await tester.pump();
        expect(phoneData.savedPhoneNames.length, beforeNames.length);
        expect(find.text('Please enter a contact name.'), findsOneWidget);
        expect(find.text('Please enter a phone number.'), findsOneWidget);
      },
    );

    testWidgets(
      'manual contact draft hides dictation when feature flag is disabled',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
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
          await tester.pump(const Duration(milliseconds: 50));
          drainOverflowExceptions(tester);

          await tester.tap(find.byType(TextButton).last, warnIfMissed: false);
          await tester.pump();
          drainOverflowExceptions(tester);

          final formFields = find.byType(TextFormField);
          expect(formFields, findsNWidgets(2));
          final nameField = tester.widget<TextField>(
            find.descendant(
              of: formFields.at(0),
              matching: find.byType(TextField),
            ),
          );
          final numberField = tester.widget<TextField>(
            find.descendant(
              of: formFields.at(1),
              matching: find.byType(TextField),
            ),
          );
          expect(nameField.decoration?.suffixIcon, isNull);
          expect(numberField.decoration?.suffixIcon, isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'manual contact draft exposes dictation on both inputs when enabled',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        SpeechDictationSuffixAction.isFeatureEnabled = true;
        try {
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
          await tester.pump(const Duration(milliseconds: 50));
          drainOverflowExceptions(tester);

          await tester.tap(find.byType(TextButton).last, warnIfMissed: false);
          await tester.pump();
          drainOverflowExceptions(tester);

          final formFields = find.byType(TextFormField);
          expect(formFields, findsNWidgets(2));
          final nameField = tester.widget<TextField>(
            find.descendant(
              of: formFields.at(0),
              matching: find.byType(TextField),
            ),
          );
          final numberField = tester.widget<TextField>(
            find.descendant(
              of: formFields.at(1),
              matching: find.byType(TextField),
            ),
          );
          expect(
            nameField.decoration?.suffixIcon,
            isA<SpeechDictationSuffixAction>(),
          );
          expect(
            numberField.decoration?.suffixIcon,
            isA<SpeechDictationSuffixAction>(),
          );
        } finally {
          SpeechDictationSuffixAction.isFeatureEnabled = false;
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('valid manual draft saves an international contact', (
      tester,
    ) async {
      userInformation.location = 'IL';
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
      await tester.pump(const Duration(milliseconds: 50));
      drainOverflowExceptions(tester);

      await tester.tap(find.byType(TextButton).last, warnIfMissed: false);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
      await tester.enterText(find.byType(TextFormField).at(1), '050 123 4567');
      await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
      await tester.pump();
      drainOverflowExceptions(tester);

      expect(phoneData.savedPhoneNames, contains('Alice'));
      expect(phoneData.savedPhoneNumbers, contains('+972501234567'));
    });

    testWidgets(
      'country-code picker defaults to the profile country and canonicalizes a local number',
      (tester) async {
        userInformation.location = 'IL';
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

        await tester.tap(find.byType(TextButton).last, warnIfMissed: false);
        await tester.pump();

        final pickerFinder = find.byKey(
          const ValueKey('contact-country-code-picker-draft'),
        );
        expect(pickerFinder, findsOneWidget);
        final picker = tester.widget<CountryCodePicker>(pickerFinder);
        expect(picker.initialSelection, 'IL');
        expect(picker.countryFilter, countryPickerCodes);

        final phoneField = tester.widget<TextField>(
          find.byType(TextField).at(1),
        );
        expect(phoneField.textDirection, TextDirection.ltr);
        expect(phoneField.textAlign, TextAlign.left);

        await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
        await tester.enterText(find.byType(TextFormField).at(1), '0543897645');
        await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
        await tester.pump();

        expect(phoneData.savedPhoneNames, contains('Alice'));
        expect(phoneData.savedPhoneNumbers, contains('+972543897645'));
      },
    );

    testWidgets('changing the country code canonicalizes a US local number', (
      tester,
    ) async {
      userInformation.location = 'IL';
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

      await tester.tap(find.byType(TextButton).last, warnIfMissed: false);
      await tester.pump();

      final pickerFinder = find.byKey(
        const ValueKey('contact-country-code-picker-draft'),
      );
      await tester.tap(
        find.descendant(of: pickerFinder, matching: find.byType(TextButton)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'US');
      await tester.pump();
      await tester.tap(find.textContaining('United States').last);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CountryCodePicker>(
              find.byKey(const ValueKey('contact-country-code-picker-draft')),
            )
            .initialSelection,
        'US',
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '(555) 123-4567',
      );
      await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
      await tester.pump();

      expect(phoneData.savedPhoneNumbers, contains('+15551234567'));
    });

    testWidgets('country-code input remains LTR in a narrow RTL form', (
      tester,
    ) async {
      userInformation.location = 'IL';
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
        locale: const Locale('he'),
        surfaceSize: const Size(320, 900),
        ignoreOverflow: false,
      );
      await _settle(tester);

      await tester.tap(find.byType(TextButton).last, warnIfMissed: false);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('contact-country-code-picker-draft')),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).textDirection,
        TextDirection.ltr,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pasted international numbers remain canonical', (
      tester,
    ) async {
      userInformation.location = 'IL';
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

      await tester.tap(find.byType(TextButton).last, warnIfMissed: false);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
      await tester.enterText(find.byType(TextFormField).at(1), '+972543897645');
      await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
      await tester.pump();

      expect(phoneData.savedPhoneNumbers, contains('+972543897645'));
    });

    testWidgets('00-prefixed international numbers are saved canonically', (
      tester,
    ) async {
      userInformation.location = 'IL';
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

      await tester.tap(find.byType(TextButton).last, warnIfMissed: false);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '00972501234567',
      );
      await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
      await tester.pump();

      expect(phoneData.savedPhoneNumbers, contains('+972501234567'));
    });

    testWidgets(
      'editing a canonical contact detects its country and shows its national number',
      (tester) async {
        userInformation.location = 'US';
        await services.memory.setItem(
          'phonePageSavedPhoneNames',
          PersistentMemoryType.StringList,
          <String>['Alice'],
        );
        await services.memory.setItem(
          'phonePageSavedPhoneNumbers',
          PersistentMemoryType.StringList,
          <String>['+972543897645'],
        );
        final phoneData = _makePhonePageData(
          names: const <String>['Alice'],
          numbers: const <String>['+972543897645'],
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

        await tester.tap(find.byIcon(Icons.edit), warnIfMissed: false);
        await tester.pump();

        final picker = tester.widget<CountryCodePicker>(
          find.byKey(const ValueKey('contact-country-code-picker-0')),
        );
        expect(picker.initialSelection, 'IL');
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).at(1))
              .controller!
              .text,
          '543897645',
        );
      },
    );

    testWidgets('repairs the next unmatched legacy number explicitly', (
      tester,
    ) async {
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
      phoneData.savedPhoneNames = <String>['Paired contact'];
      phoneData.savedPhoneNumbers = <String>['111', '222'];
      phoneData.update();
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        '222',
      );

      await tester.enterText(find.byType(TextFormField).first, 'Number only');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(phoneData.savedPhoneNames, ['Paired contact', 'Number only']);
      expect(phoneData.savedPhoneNumbers, ['111', '+972222']);
    });

    testWidgets('editing an existing contact replaces it', (tester) async {
      await services.memory.setItem(
        'phonePageSavedPhoneNames',
        PersistentMemoryType.StringList,
        <String>['Alice'],
      );
      await services.memory.setItem(
        'phonePageSavedPhoneNumbers',
        PersistentMemoryType.StringList,
        <String>['111'],
      );
      final phoneData = _makePhonePageData(
        names: const <String>['Alice'],
        numbers: const <String>['111'],
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

      await tester.tap(find.byIcon(Icons.edit), warnIfMissed: false);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice updated');
      await tester.enterText(find.byType(TextFormField).at(1), '222');
      await tester.tap(find.byIcon(Icons.check), warnIfMissed: false);
      await tester.pump();
      drainOverflowExceptions(tester);

      expect(phoneData.savedPhoneNames, ['Alice updated']);
      expect(phoneData.savedPhoneNumbers, ['+972222']);
    });

    testWidgets('canceling an existing edit restores provider values', (
      tester,
    ) async {
      await services.memory.setItem(
        'phonePageSavedPhoneNames',
        PersistentMemoryType.StringList,
        <String>['Alice'],
      );
      await services.memory.setItem(
        'phonePageSavedPhoneNumbers',
        PersistentMemoryType.StringList,
        <String>['111'],
      );
      final phoneData = _makePhonePageData(
        names: const <String>['Alice'],
        numbers: const <String>['111'],
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

      await tester.tap(find.byIcon(Icons.edit), warnIfMissed: false);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, 'Changed');
      await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
      await tester.pump();
      drainOverflowExceptions(tester);

      expect(phoneData.savedPhoneNames, ['Alice']);
      expect(phoneData.savedPhoneNumbers, ['111']);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Changed'), findsNothing);
    });

    testWidgets('delete existing contact requires confirmation', (
      tester,
    ) async {
      await services.memory.setItem(
        'phonePageSavedPhoneNames',
        PersistentMemoryType.StringList,
        <String>['Alice'],
      );
      await services.memory.setItem(
        'phonePageSavedPhoneNumbers',
        PersistentMemoryType.StringList,
        <String>['111'],
      );
      final phoneData = _makePhonePageData(
        names: const <String>['Alice'],
        numbers: const <String>['111'],
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

      await tester.tap(find.byIcon(Icons.edit), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.delete), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Delete this contact?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(phoneData.savedPhoneNames, ['Alice']);

      await tester.tap(find.byIcon(Icons.delete), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(phoneData.savedPhoneNames, isEmpty);
      expect(phoneData.savedPhoneNumbers, isEmpty);
    });

    testWidgets('PhonePageData calls canonical personal-contact numbers', (
      tester,
    ) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fakePlatform = _RecordingUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);
      userInformation.location = 'IL';

      // PhonePageData's constructor calls loadItemsFromPrefs() which
      // overwrites our seeded lists with whatever is in
      // PersistentMemoryService. To keep the two seeded entries visible we
      // seed the fake persistent store first.
      await services.memory.setItem(
        'phonePageSavedPhoneNames',
        PersistentMemoryType.StringList,
        <String>['Alice', 'Bob'],
      );
      await services.memory.setItem(
        'phonePageSavedPhoneNumbers',
        PersistentMemoryType.StringList,
        <String>['0501234567', '+15551234567'],
      );
      final phoneData = _makePhonePageData(
        names: const <String>['Alice', 'Bob'],
        numbers: const <String>['0501234567', '+15551234567'],
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
      final callAlice = find.byTooltip('Call Alice');
      final callBob = find.byTooltip('Call Bob');
      expect(callAlice, findsOneWidget);
      expect(callBob, findsOneWidget);

      final aliceCard = find.ancestor(
        of: find.text('Alice'),
        matching: find.byType(Card),
      );
      expect(
        tester.getRect(callAlice).right,
        lessThanOrEqualTo(tester.getRect(aliceCard).left),
      );

      await tester.tap(callAlice);
      await tester.pump();
      expect(fakePlatform.launchedUrls, <String>['tel:+972501234567']);

      await tester.tap(callBob);
      await tester.pump();
      expect(fakePlatform.launchedUrls, <String>[
        'tel:+972501234567',
        'tel:+15551234567',
      ]);
    });

    testWidgets(
      'invalid legacy personal-contact numbers show feedback without dialing',
      (tester) async {
        final originalPlatform = UrlLauncherPlatform.instance;
        final fakePlatform = _RecordingUrlLauncherPlatform();
        UrlLauncherPlatform.instance = fakePlatform;
        addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);
        userInformation.location = 'IL';

        await services.memory.setItem(
          'phonePageSavedPhoneNames',
          PersistentMemoryType.StringList,
          <String>['Legacy shortcode'],
        );
        await services.memory.setItem(
          'phonePageSavedPhoneNumbers',
          PersistentMemoryType.StringList,
          <String>['*123#'],
        );
        final phoneData = _makePhonePageData(
          names: const <String>['Legacy shortcode'],
          numbers: const <String>['*123#'],
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

        await tester.tap(find.byTooltip('Call Legacy shortcode'));
        await tester.pump();

        expect(fakePlatform.launchedUrls, isEmpty);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text("Couldn't open the dialer for *123#"), findsOneWidget);
      },
    );
  });

  group('PhonePageForm (real production widget)', () {
    testWidgets(
      'renders header, import button, list, and confirmation button',
      (tester) async {
        final phoneData = _makePhonePageData();
        bool nextCalled = false;

        await pumpWithProviders(
          tester,
          ChangeNotifierProvider<PhonePageData>.value(
            value: phoneData,
            child: wizardStepHarness(
              PhonePageForm(
                key: GlobalKey<WizardStepState>(),
                next: () => nextCalled = true,
                prev: () {},
                phonePageData: phoneData,
              ),
            ),
          ),
          userInformation: userInformation,
          surfaceSize: const Size(1024, 2000),
        );
        await _settle(tester);

        expect(find.byType(PhonePageForm), findsOneWidget);
        // Embedded PhonePageList is built via Consumer<PhonePageData>.
        expect(find.byType(PhonePageList), findsOneWidget);
        expect(find.byTooltip('Contact storage information'), findsOneWidget);
        final infoIcon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
        expect(infoIcon.semanticLabel, 'Contact storage information');
        // Next/import buttons render — exact tap is platform-channel
        // sensitive (FlutterContacts), so we only assert presence here.
        expect(find.byType(TextButton), findsWidgets);
        expect(nextCalled, isFalse);
      },
    );
  });

  group('FormProgressIndicator (real production widget)', () {
    testWidgets('renders the first step and progress indicator dots', (
      tester,
    ) async {
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
