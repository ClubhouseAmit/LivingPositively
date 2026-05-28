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
import 'package:mazilon/util/HomePage/inspirationalQuote.dart';
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

Widget _wrapQuote(List<String> quotes, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, _) => Scaffold(
        body: Center(child: InspirationalQuote(quotes: quotes)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InspirationalQuote uses directional layout (UX_GAPS §1.4, §3.3)', () {
    setUp(() => registerTestServices(locale: 'en'));
    tearDown(resetTestServices);

    testWidgets(
        'PositionedDirectional + EdgeInsetsDirectional replace the isRtl branches',
        (tester) async {
      await tester.pumpWidget(_wrapQuote(const ['quote-one']));
      await tester.pumpAndSettle();

      // Phase C contract: the close button is positioned with
      // PositionedDirectional(end:), not Positioned(left:/right:) branches.
      expect(
        find.byType(PositionedDirectional),
        findsOneWidget,
        reason:
            'InspirationalQuote close button must use PositionedDirectional '
            'so its trailing edge follows the ambient Directionality.',
      );

      // Phase C contract: the quote-text Padding uses EdgeInsetsDirectional,
      // so the trailing padding flips with the locale instead of being baked
      // into LTRB at construction time.
      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      final directional = paddings.where(
        (p) => p.padding is EdgeInsetsDirectional,
      );
      expect(
        directional,
        isNotEmpty,
        reason:
            'InspirationalQuote text wrapper must use EdgeInsetsDirectional '
            'instead of EdgeInsets.fromLTRB keyed on isRtl.',
      );
    });

    testWidgets(
        'close button lands on the trailing edge in LTR (right side)',
        (tester) async {
      await tester.pumpWidget(_wrapQuote(const ['quote-one']));
      await tester.pumpAndSettle();

      final closeCenter = tester.getCenter(find.byIcon(Icons.close));
      final quoteCenter = tester
          .getCenter(find.byType(InspirationalQuote).first);
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
        _wrapQuote(const ['quote-one'], locale: const Locale('he')),
      );
      await tester.pumpAndSettle();

      final closeCenter = tester.getCenter(find.byIcon(Icons.close));
      final quoteCenter = tester
          .getCenter(find.byType(InspirationalQuote).first);
      expect(
        closeCenter.dx,
        lessThan(quoteCenter.dx),
        reason:
            'Close icon must flip to the left in RTL (trailing in he). '
            'If this fails, the close button is still pinned with Positioned '
            'instead of PositionedDirectional.',
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
        'header Row no longer pins an inverted textDirection in he locale',
        (tester) async {
      await openMenu(tester, const Locale('he'));

      // The header Row that holds the close (X) button used to set
      // `textDirection: isRtl ? LTR : RTL` (UX_GAPS §1.4). Phase C drops
      // that override so the Row inherits the ambient Directionality (RTL
      // in `he`). We assert by walking up from the close button to the
      // first Row ancestor and confirming the override is null.
      final closeFinder = find.byKey(const Key('mainMenuCloseButton'));
      expect(closeFinder, findsOneWidget);

      final rowAncestor = find.ancestor(
        of: closeFinder,
        matching: find.byType(Row),
      );
      expect(rowAncestor, findsWidgets);

      final headerRow = tester.widget<Row>(rowAncestor.first);
      expect(
        headerRow.textDirection,
        isNull,
        reason:
            'main_menu_dialog header Row must not override textDirection — '
            'Phase C removed the inverted `isRtl ? LTR : RTL` branch.',
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
