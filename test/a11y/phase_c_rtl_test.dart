// Phase C (ADR-005) — RTL regression tests.
//
// Covers the directionality gaps catalogued in `docs/UX_GAPS.md` §1.4, §3.3,
// §3.5, and §3.11. The previous implementations branched on
// `appLocale.textDirection == "rtl"` to pick LTR/RTL `Positioned`, `EdgeInsets`,
// `TextAlign`, and `Alignment` values. Phase C replaces those branches with
// `PositionedDirectional`, `EdgeInsetsDirectional`, `TextAlign.start`, and
// `AlignmentDirectional` so layouts inherit the ambient `Directionality` from
// the MaterialApp locale.
//
// These tests pump real production widgets in both `en` and `he` locales and
// assert (a) directional widgets are used in place of the old branches and (b)
// the resulting global positions actually flip when the locale changes.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/main_menu_dialog.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/HomePage/quote_card_widget.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
      key: 'phone',
      header: 'h',
      subTitle: 's',
      midTitle: 'm',
      phoneNameTitle: 'n',
      phoneNumberTitle: 'p',
      phoneNames: const <String>[],
      phoneNumbers: const <String>[],
      savedPhoneNames: const <String>[],
      savedPhoneNumbers: const <String>[],
      phoneDescription: const <String>[],
    );

Widget _wrapQuote(String quote, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, _) => Scaffold(
        body: Center(
          child: QuoteCardWidget(
            quote: quote,
            onClose: () {},
            onRefresh: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuoteCardWidget uses directional layout (UX_GAPS §1.4, §3.3)', () {
    setUp(() => registerTestServices(locale: 'en'));
    tearDown(resetTestServices);

    testWidgets(
        'PositionedDirectional + EdgeInsetsDirectional replace the LTR/RTL branches',
        (tester) async {
      await tester.pumpWidget(_wrapQuote('quote-one'));
      await tester.pumpAndSettle();

      // Phase C contract: the quote mark uses PositionedDirectional.
      expect(
        find.byType(PositionedDirectional),
        findsOneWidget,
        reason:
            'QuoteCardWidget quote mark must use PositionedDirectional '
            'so its layout follows the ambient Directionality.',
      );

      // Phase C contract: the padding uses EdgeInsetsDirectional.
      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      final directional = paddings.where(
        (p) => p.padding is EdgeInsetsDirectional,
      );
      expect(
        directional,
        isNotEmpty,
        reason:
            'QuoteCardWidget must use EdgeInsetsDirectional '
            'instead of EdgeInsets keyed on isRtl.',
      );
    });

    testWidgets(
        'close button lands on the trailing edge in LTR (right side)',
        (tester) async {
      await tester.pumpWidget(_wrapQuote('quote-one'));
      await tester.pumpAndSettle();

      final closeCenter = tester.getCenter(find.byIcon(Icons.close));
      final quoteCenter = tester
          .getCenter(find.byType(QuoteCardWidget).first);
      expect(
        closeCenter.dx,
        greaterThan(quoteCenter.dx),
        reason: 'Close icon must sit on the right (trailing in LTR).',
      );
    });

    testWidgets(
        'close button flips to the trailing edge in RTL (left side)',
        (tester) async {
      await tester.pumpWidget(
        _wrapQuote('quote-one', locale: const Locale('he')),
      );
      await tester.pumpAndSettle();

      final closeCenter = tester.getCenter(find.byIcon(Icons.close));
      final quoteCenter = tester
          .getCenter(find.byType(QuoteCardWidget).first);
      expect(
        closeCenter.dx,
        lessThan(quoteCenter.dx),
        reason:
            'Close icon must flip to the left in RTL (trailing in he).',
      );
    });
  });

  group('main_menu_dialog Row inherits ambient Directionality '
      '(UX_GAPS §1.4, §3.11)', () {
    setUp(() {
      registerTestServices(locale: 'he');
    });
    tearDown(resetTestServices);

    Future<void> openMenu(WidgetTester tester, Locale locale) async {
      final user = UserInformation()
        ..gender = 'other'
        ..localeName = locale.languageCode;
      await pumpWithProviders(
        tester,
        Builder(builder: (ctx) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('openMenu'),
                onPressed: () {
                  showMainMenuDialog(
                    context: ctx,
                    anchorContext: ctx,
                    appLocale: AppLocalizations.of(ctx)!,
                    userInformation: user,
                    phonePageData: _phoneData(),
                    changeLocale: (_) {},
                    isWeb: false,
                    onAboutPressed: () {},
                    onNotificationsPressed: () {},
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        }),
        userInformation: user,
        locale: locale,
        surfaceSize: const Size(1024, 800),
      );
      await tester.tap(find.byKey(const Key('openMenu')));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'header Align uses explicit AlignmentDirectional.topEnd for the close button',
        (tester) async {
      await openMenu(tester, const Locale('he'));

      // The close button side is a physical product requirement:
      // English => right, Hebrew => left. Keep the header Align in
      // AlignmentDirectional.topEnd coordinates.
      final closeFinder = find.byKey(const Key('mainMenuCloseButton'));
      expect(closeFinder, findsOneWidget);

      final alignAncestor = find.ancestor(
        of: closeFinder,
        matching: find.byType(Align),
      );
      expect(alignAncestor, findsWidgets);

      final headerAlign = tester.widget<Align>(alignAncestor.first);
      expect(
        headerAlign.alignment,
        AlignmentDirectional.topEnd,
        reason:
            'main_menu_dialog must place the close button using explicit '
            'AlignmentDirectional.topEnd so locale, not inherited route direction, '
            'decides whether the X is left or right.',
      );
    });

    testWidgets('close button lands on the trailing edge in LTR', (
      tester,
    ) async {
      await openMenu(tester, const Locale('en'));

      final closeCenter = tester.getCenter(
        find.byKey(const Key('mainMenuCloseButton')),
      );
      final dialogCenter = tester.getCenter(
        find.byKey(const Key('mainMenuDialog')),
      );

      expect(
        closeCenter.dx,
        greaterThan(dialogCenter.dx),
        reason: 'The main menu close button must sit on the right in English.',
      );
    });

    testWidgets('close button flips to the trailing edge in RTL', (
      tester,
    ) async {
      await openMenu(tester, const Locale('he'));

      final closeCenter = tester.getCenter(
        find.byKey(const Key('mainMenuCloseButton')),
      );
      final dialogCenter = tester.getCenter(
        find.byKey(const Key('mainMenuDialog')),
      );

      expect(
        closeCenter.dx,
        lessThan(dialogCenter.dx),
        reason: 'The main menu close button must sit on the left in Hebrew.',
      );
    });

    testWidgets(
        'About label aligns to leading edge via AlignmentDirectional',
        (tester) async {
      await openMenu(tester, const Locale('he'));

      // The Align wrapping the About TextButton previously branched on
      // isRtl between centerLeft/centerRight. Phase C uses
      // AlignmentDirectional.centerStart so the label tracks the ambient
      // Directionality (start = right in RTL, left in LTR). Assert by
      // walking every Align under the dialog Material — the directional
      // Align is unique; TextButton/Material insert non-directional
      // Aligns internally that we must skip.
      final aligns = tester.widgetList<Align>(
        find.descendant(
          of: find.byKey(const Key('mainMenuDialog')),
          matching: find.byType(Align),
        ),
      );
      final directional = aligns
          .where((a) => a.alignment == AlignmentDirectional.centerStart);
      expect(
        directional,
        isNotEmpty,
        reason:
            'main_menu_dialog must wrap the About label in an Align with '
            'AlignmentDirectional.centerStart instead of the isRtl ? '
            'centerRight : centerLeft branch.',
      );
    });
  });
}
