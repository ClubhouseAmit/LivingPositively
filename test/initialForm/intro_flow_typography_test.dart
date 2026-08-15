// Guards the two decisions behind issue #338 for the onboarding intro flow:
//
//   1. Rubik ('Rubix') is the only font family the app ships. The Figma source
//      names Epilogue (field labels) and Assistant (safety-plan buttons); both
//      are rendered in Rubik at the design's sizes and weights instead.
//   2. These screens do not use AutoSizeText. `myAutoSizedText` resolves to its
//      `maxFontSize` ceiling rather than the style's `fontSize` whenever
//      maxLines is null inside an unbounded-height scroll view, which is why
//      titles specified at 26px were painting at 60px. See
//      designs/issue-338-audit.md §1.
//
// The view is pinned to 360 logical pixels wide — the Figma frame width, and
// the ScreenUtil design width — so `.sp` resolves 1:1 and the assertions below
// are the design's own numbers.
//
// Note the view is driven directly rather than via `pumpWithProviders`'
// `surfaceSize`: ScreenUtil reads the window, which `setSurfaceSize` does not
// change, so under that helper `.sp` scales against the default 800px test
// window and every size comes out 2.2x too large.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/initialForm/form.dart';
import 'package:mazilon/initialForm/initialFormPage1.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/initialForm/toFormPage.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
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

/// Sizes and weights of every Rubik-styled [Text] currently on screen.
///
/// Third-party widgets (the country picker renders Roboto) are excluded — this
/// asserts about the app's own typography, not its dependencies'.
List<({double size, FontWeight weight})> _appTextStyles(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.style?.fontFamily == 'Rubix')
      .where((t) => t.style?.fontSize != null && t.style?.fontWeight != null)
      .map((t) => (size: t.style!.fontSize!, weight: t.style!.fontWeight!))
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'he');
    user = UserInformation();
    user.gender = 'female';
    user.localeName = 'he';
    user.disclaimerSigned = true;
  });

  tearDown(resetTestServices);

  /// Design sizes per screen, from the Figma manifests for frames
  /// 1660:1264 (welcome), 1660:2278 (get-to-know-you), 1660:2313 (safety plan).
  final welcomeSizes = {26.0, 16.0, 18.0};
  final getToKnowSizes = {26.0, 16.0, 14.0, 18.0};
  // Frame 19 specifies its two actions at Assistant 17/w600, where frames 2
  // and 28 specify Rubik 18/w500. Now that all three screens draw their
  // actions from the one wizard wrapper, they are 18/w500 everywhere — the
  // size two of the three frames agree on, and DESIGN.md's "Card Title" token.
  // The 1pt deviation on this screen is the cost of having one control.
  final safetyPlanSizes = {26.0, 16.0, 18.0};

  // Rubik is registered at these four weights in pubspec.yaml. The design never
  // uses Bold (w700) anywhere in this flow.
  final designWeights = {FontWeight.w400, FontWeight.w500, FontWeight.w600};

  testWidgets(
    'intro flow renders at design sizes, never through AutoSizeText',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);

      await loadTestFonts();
      await pumpWithProviders(
        tester,
        InitialFormProgressIndicator(
          phonePageData: _phoneData(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        locale: const Locale('he'),
      );

      void check(String screen, Set<double> allowedSizes) {
        expect(
          find.byType(AutoSizeText),
          findsNothing,
          reason: '$screen must not size text through AutoSizeText',
        );
        for (final style in _appTextStyles(tester)) {
          expect(
            allowedSizes,
            contains(style.size),
            reason:
                '$screen has a ${style.size}px text outside the design scale',
          );
          expect(
            designWeights,
            contains(style.weight),
            reason:
                '$screen has a ${style.weight} text; design tops out at w600',
          );
        }
      }

      check('welcome', welcomeSizes);

      tester.widget<InitialFormPage1>(find.byType(InitialFormPage1)).next();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      drainOverflowExceptions(tester);
      expect(find.byType(InitialFormPage2), findsOneWidget);
      check('get-to-know-you', getToKnowSizes);

      tester.widget<InitialFormPage2>(find.byType(InitialFormPage2)).next();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      drainOverflowExceptions(tester);
      expect(find.byType(ToFormPage), findsOneWidget);
      check('safety-plan intro', safetyPlanSizes);
    },
  );
}
