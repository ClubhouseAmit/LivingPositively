import 'package:flutter/material.dart' hide Text;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/type_scale.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/util/async/app_theme.dart';

import '../helpers/widget_test_scaffold.dart';

/// Figma variable `font/family/FontFamily`: English mode Heebo, Hebrew mode
/// Rubik. Everything else (size, weight, line height) is shared.
void main() {
  group('AppTypeScale.familyFor', () {
    test('should pick Rubik for Hebrew', () {
      expect(AppTypeScale.familyFor(const Locale('he')), 'Rubik');
    });

    test('should pick Heebo for every other language and for none', () {
      expect(AppTypeScale.familyFor(const Locale('en')), 'Heebo');
      expect(AppTypeScale.familyFor(const Locale('ar')), 'Heebo');
      expect(AppTypeScale.familyFor(null), 'Heebo');
    });
  });

  group('buildLightTheme', () {
    test('should put every text-theme slot in the language font', () {
      final he = buildLightTheme(const Locale('he')).textTheme;
      final en = buildLightTheme(const Locale('en')).textTheme;
      expect(he.bodyMedium!.fontFamily, 'Rubik');
      expect(he.headlineLarge!.fontFamily, 'Rubik');
      expect(en.bodyMedium!.fontFamily, 'Heebo');
      expect(
        buildDarkTheme(const Locale('he')).textTheme.labelLarge!.fontFamily,
        'Rubik',
      );
    });
  });

  group('Text', () {
    // The app theme as main.dart builds it: for the app language.
    Future<RichText> pumpText(WidgetTester tester, Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('he')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildLightTheme(locale),
          home: const Scaffold(
            body: Center(
              child: Text('כתוב כאן בקצרה', style: AppTextStyle.titleSmall),
            ),
          ),
        ),
      );
      return tester.widget(find.byType(RichText));
    }

    testWidgets('should render in the font of the app language', (
      tester,
    ) async {
      expect(
        (await pumpText(tester, const Locale('he'))).text.style!.fontFamily,
        'Rubik',
      );
      expect(
        (await pumpText(tester, const Locale('en'))).text.style!.fontFamily,
        'Heebo',
      );
    });

    // Figma's Hebrew text field hugs Title/Base (16px, auto) to 19px: Rubik's
    // own line height, not Heebo's 24px.
    testWidgets("should give Hebrew Rubik's own auto line height, as Figma", (
      tester,
    ) async {
      await loadTestFonts();
      await pumpText(tester, const Locale('he'));
      expect(tester.getSize(find.byType(RichText)).height, 19);
    });
  });
}
