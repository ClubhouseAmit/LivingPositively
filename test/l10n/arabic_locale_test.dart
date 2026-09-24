import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/shell/ui/disclaimerLanguageSelect.dart';
import 'package:mazilon/util/languages_util_functions.dart';

void main() {
  group('Arabic locale support', () {
    test(
      'breathing durations use Arabic plural forms for measured seconds',
      () async {
        final strings = await AppLocalizations.delegate.load(
          const Locale('ar'),
        );
        for (final seconds in [3, 4, 5, 6, 7, 8, 9]) {
          expect(strings.breathingSeconds(seconds), endsWith(' ثوانٍ'));
        }
        for (final seconds in [0, 1, 3.5, 11, 100]) {
          expect(strings.breathingSeconds(seconds), endsWith(' ثانية'));
        }
        expect(strings.breathingSeconds(2), endsWith(' ثانيتان'));
      },
    );

    test(
      'breathing labels preserve decimal precision and Hebrew meaning',
      () async {
        final english = await AppLocalizations.delegate.load(
          const Locale('en'),
        );
        final hebrew = await AppLocalizations.delegate.load(const Locale('he'));
        expect(english.breathingSeconds(3), '3.0 seconds');
        expect(english.breathingSeconds(3.5), '3.5 seconds');
        expect(hebrew.breathingSeconds(3), '3.0 שניות');
        expect(hebrew.breathingDecrease, 'קיצור משך הנשימה בשנייה');
        expect(hebrew.breathingIncrease, 'הארכת משך הנשימה בשנייה');
      },
    );

    test('AppLocalizations registers Arabic in supportedLocales', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('ar')));
    });

    test('AppLocalizations delegate supports Arabic', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('ar')), isTrue);
    });

    test('languageName maps Arabic locale code to Arabic label', () {
      expect(languageName('ar'), 'العربية');
    });

    test('languageCode maps Arabic label to ar locale code', () {
      expect(languageCode('العربية'), 'ar');
    });

    testWidgets('LanguageDropDown exposes Arabic as visible selectable text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LanguageDropDown(changeLocale: (_) {})),
        ),
      );

      expect(find.text('العربية'), findsOneWidget);
    });

    testWidgets('Arabic locale resolves an Arabic localized label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('ar'),
          home: Builder(
            builder: (context) {
              final appLocale = AppLocalizations.of(context)!;
              return Text(appLocale.language);
            },
          ),
        ),
      );

      expect(find.text('العربية'), findsOneWidget);
    });

    testWidgets('Arabic locale resolves RTL directionality', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('ar'),
          home: Builder(
            builder: (context) {
              return Text(
                Directionality.of(context) == TextDirection.rtl ? 'rtl' : 'ltr',
              );
            },
          ),
        ),
      );

      expect(find.text('rtl'), findsOneWidget);
    });
  });
}
