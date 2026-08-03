import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/disclaimerLanguageSelect.dart';
import 'package:mazilon/util/languages_util_functions.dart';

void main() {
  group('Arabic locale support', () {
    test('AppLocalizations registers Arabic in supportedLocales', () {
      expect(
        AppLocalizations.supportedLocales,
        contains(const Locale('ar')),
      );
    });

    test('AppLocalizations delegate supports Arabic', () {
      expect(
        AppLocalizations.delegate.isSupported(const Locale('ar')),
        isTrue,
      );
    });

    test('languageName maps Arabic locale code to Arabic label', () {
      expect(languageName('ar'), 'العربية');
    });

    test('languageCode maps Arabic label to ar locale code', () {
      expect(languageCode('العربية'), 'ar');
    });

    testWidgets('LanguageDropDown exposes Arabic as visible selectable text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LanguageDropDown(changeLocale: (_) {}),
          ),
        ),
      );

      expect(find.text('العربية'), findsOneWidget);
    });

    testWidgets('Arabic locale resolves an Arabic localized label',
        (tester) async {
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

    testWidgets('Arabic locale resolves RTL directionality',
        (tester) async {
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
