// Widget tests for the REAL DisclaimerPage in lib/disclaimerPage.dart.
//
// The previous version of this file imported a stub copy of DisclaimerPage
// from the test directory. That stub had a different constructor and a
// different DOM (a text "אישור" button keyed `accept`), so it never exercised
// any production code. This file pumps the actual production widget through
// MultiProvider + AppLocalizations + ScreenUtilInit and asserts on the
// behaviour that real users see (disclaimer copy, language dropdown, the
// confirm button updating UserInformation + persistent storage).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/disclaimerPage.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/disclaimerLanguageSelect.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServiceLocators services;
  late UserInformation userInformation;

  setUp(() {
    services = registerTestServices(locale: 'en');
    userInformation = UserInformation();
  });

  tearDown(() {
    resetTestServices();
  });

  group('DisclaimerPage (real production widget)', () {
    testWidgets('renders disclaimer scaffold with language dropdown', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        DisclaimerPage(changeLocale: (_) {}),
        userInformation: userInformation,
      );

      // The production DisclaimerPage uses Scaffold + SingleChildScrollView
      // and embeds a LanguageDropDown. None of these existed in the old stub.
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(LanguageDropDown), findsOneWidget);
    });

    testWidgets('renders section headings in supported locales', (
      tester,
    ) async {
      final cases = <Locale, List<String>>{
        const Locale('en'): const [
          'App purpose',
          'Information and privacy',
          'Consent',
        ],
        const Locale('he'): const ['מטרת האפליקציה', 'מידע ופרטיות', 'הסכמה'],
        const Locale('ar'): const [
          'هدف التطبيق',
          'المعلومات والخصوصية',
          'الموافقة',
        ],
      };

      for (final entry in cases.entries) {
        await pumpWithProviders(
          tester,
          DisclaimerPage(changeLocale: (_) {}),
          userInformation: userInformation,
          locale: entry.key,
          surfaceSize: const Size(600, 1400),
        );

        for (final heading in entry.value) {
          expect(find.text(heading), findsOneWidget);
        }
      }
    });

    testWidgets('renders information collection disclaimer once', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        DisclaimerPage(changeLocale: (_) {}),
        userInformation: userInformation,
        surfaceSize: const Size(600, 1400),
      );

      expect(
        find.textContaining('The application only collects anonymous'),
        findsOneWidget,
      );
    });

    testWidgets('uses PopScope to disable back navigation', (tester) async {
      await pumpWithProviders(
        tester,
        DisclaimerPage(changeLocale: (_) {}),
        userInformation: userInformation,
      );

      final pop = tester.widget<PopScope>(find.byType(PopScope));
      expect(pop.canPop, isFalse);
    });

    testWidgets('confirm button updates UserInformation.disclaimerSigned', (
      tester,
    ) async {
      expect(userInformation.disclaimerSigned, isFalse);

      await pumpWithProviders(
        tester,
        DisclaimerPage(changeLocale: (_) {}),
        userInformation: userInformation,
        // A taller surface keeps the confirm button on-screen so we can tap.
        surfaceSize: const Size(600, 1400),
      );

      // The English locale renders the confirm button as "Confirm" — the
      // ConfirmationButton helper wraps it in a TextButton, so tap that
      // ancestor to trigger the real onPressed.
      final confirmButton = find.ancestor(
        of: find.text('Confirm'),
        matching: find.byType(TextButton),
      );
      expect(confirmButton, findsOneWidget);

      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(userInformation.disclaimerSigned, isTrue);
    });

    testWidgets('confirm button persists disclaimerConfirmed via service', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        DisclaimerPage(changeLocale: (_) {}),
        userInformation: userInformation,
        surfaceSize: const Size(600, 1400),
      );

      final confirmButton = find.ancestor(
        of: find.text('Confirm'),
        matching: find.byType(TextButton),
      );
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton, warnIfMissed: false);
      // Two pumps so the async setItem call settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final stored = await services.memory.getItem(
        'disclaimerConfirmed',
        PersistentMemoryType.Bool,
      );
      expect(stored, isTrue);
    });

    testWidgets(
      'updateDisclaimers helper writes to persistent memory and provider',
      (tester) async {
        // Exercise the top-level helper directly to cover its branches without
        // pumping the whole widget tree twice.
        await pumpWithProviders(
          tester,
          DisclaimerPage(changeLocale: (_) {}),
          userInformation: userInformation,
        );

        updateDisclaimers(userInformation);
        // updateDisclaimers is fire-and-forget; let the microtask drain.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(userInformation.disclaimerSigned, isTrue);
        expect(
          await services.memory.getItem(
            'disclaimerConfirmed',
            PersistentMemoryType.Bool,
          ),
          isTrue,
        );
      },
    );

    testWidgets('changeLocale callback fires when language changes', (
      tester,
    ) async {
      String? selected;
      await pumpWithProviders(
        tester,
        DisclaimerPage(changeLocale: (value) => selected = value as String),
        userInformation: userInformation,
      );

      final option = find.text('עברית');
      expect(option, findsOneWidget);
      await tester.tap(option);
      await tester.pumpAndSettle();

      expect(selected, 'he');
    });

    testWidgets('language selector highlights active language', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        DisclaimerPage(changeLocale: (_) {}),
        userInformation: userInformation,
      );

      final primaryColor = Theme.of(
        tester.element(find.byType(LanguageDropDown)),
      ).colorScheme.primary;

      final englishText = tester.widget<Text>(find.text('English'));
      expect(englishText.style?.fontWeight, FontWeight.bold);
      expect(englishText.style?.decoration, TextDecoration.underline);
      expect(englishText.style?.decorationColor, primaryColor);

      final hebrewText = tester.widget<Text>(find.text('עברית'));
      expect(hebrewText.style?.fontWeight, FontWeight.normal);
      expect(hebrewText.style?.decoration, TextDecoration.none);
    });

    testWidgets('still renders correctly under Hebrew (RTL) locale', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        DisclaimerPage(changeLocale: (_) {}),
        userInformation: userInformation,
        locale: const Locale('he'),
      );

      expect(find.byType(DisclaimerPage), findsOneWidget);
      expect(find.byType(LanguageDropDown), findsOneWidget);
    });

    testWidgets('GetIt reset still allows DisclaimerPage to throw cleanly '
        'when service is missing', (tester) async {
      // Isolate this test from the shared setUp registration.
      GetIt.instance.unregister<PersistentMemoryService>();

      await pumpWithProviders(
        tester,
        DisclaimerPage(changeLocale: (_) {}),
        userInformation: userInformation,
      );

      // Tapping confirm without a registered service should not crash the
      // build — updateDisclaimers logs/throws asynchronously.
      await tester.tap(find.text('Confirm'), warnIfMissed: false);
      await tester.pump();
      // Re-register so the global tearDown runs cleanly.
      GetIt.instance.registerSingleton<PersistentMemoryService>(
        services.memory,
      );
    });
  });

  // Verifies that consumers reading UserInformation re-render after the
  // confirm button toggles disclaimerSigned (Provider integration).
  testWidgets('Provider notifies listeners after confirmation', (tester) async {
    int rebuilds = 0;
    await pumpWithProviders(
      tester,
      Builder(
        builder: (context) {
          // Force rebuild whenever UserInformation notifies.
          context.watch<UserInformation>();
          rebuilds++;
          return DisclaimerPage(changeLocale: (_) {});
        },
      ),
      userInformation: userInformation,
      surfaceSize: const Size(600, 1400),
    );
    final before = rebuilds;
    final confirmButton = find.ancestor(
      of: find.text('Confirm'),
      matching: find.byType(TextButton),
    );
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(rebuilds, greaterThan(before));
  });
}
