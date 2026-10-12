import 'package:flutter/painting.dart' show TextStyle;

import 'font_weight.dart';

/// Type-scale tokens.
///
/// Mirrors the LP-DS Figma file (page "Typography", node 7:193) one-to-one by
/// name: Figma `Heading/H1` is [headingH1], `Body/Base Paragraph` is
/// [bodyBaseParagraph].
///
/// Most Figma styles use "auto" line height, which is the font's own line
/// height (1.46875 for Heebo). Those tokens leave `height` unset, which is
/// what Flutter does too. Only styles with a fixed line height in Figma set
/// `height`.
///
/// `fontFamily` is baked in because the design-system `Text` never reads a
/// `ThemeData` to inherit one from. `ThemeData.textTheme` in
/// `lib/util/async/app_theme.dart` points Material's slots at these tokens.
abstract class AppTypeScale {
  static const String family = 'Heebo';

  // -- Display --

  static const TextStyle displayHugeExtraBold = TextStyle(
    fontFamily: family,
    fontSize: 68,
    fontWeight: AppFontWeight.extraBold,
    height: 74 / 68,
  );

  static const TextStyle displayHugeRegular = TextStyle(
    fontFamily: family,
    fontSize: 68,
    fontWeight: AppFontWeight.regular,
    height: 74 / 68,
  );

  static const TextStyle displayHeroExtraBold = TextStyle(
    fontFamily: family,
    fontSize: 34,
    fontWeight: AppFontWeight.extraBold,
    height: 44 / 34,
  );

  static const TextStyle displayHeroRegular = TextStyle(
    fontFamily: family,
    fontSize: 34,
    fontWeight: AppFontWeight.regular,
    height: 44 / 34,
  );

  // -- Heading --

  static const TextStyle headingH1 = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: AppFontWeight.medium,
  );

  static const TextStyle headingH2 = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: AppFontWeight.semiBold,
  );

  static const TextStyle headingH3 = TextStyle(
    fontFamily: family,
    fontSize: 20,
    fontWeight: AppFontWeight.bold,
  );

  static const TextStyle headingH4 = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: AppFontWeight.bold,
  );

  // -- Title --

  static const TextStyle titleLarge = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: AppFontWeight.semiBold,
  );

  static const TextStyle titleBase = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle titleBaseBold = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: AppFontWeight.bold,
    height: 20 / 16,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: AppFontWeight.semiBold,
  );

  static const TextStyle titleSmallBold = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: AppFontWeight.bold,
  );

  /// Figma sets this style to UPPERCASE; `TextStyle` cannot, so the caller
  /// upper-cases the string. Despite its Figma name, its values are
  /// `Label/Small`'s (12 / SemiBold).
  static const TextStyle titleSmallBoldUppercase = labelSmall;

  // -- Body --

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle bodyBase = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle bodyBaseMedium = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: AppFontWeight.medium,
  );

  static const TextStyle bodyBaseParagraph = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
    height: 22 / 16,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle bodySmallParagraph = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: AppFontWeight.regular,
    height: 20 / 15,
  );

  static const TextStyle bodyXSmall = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: AppFontWeight.regular,
  );

  // -- Label --

  static const TextStyle labelLarge = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: AppFontWeight.semiBold,
  );

  /// Figma sets this style to UPPERCASE; `TextStyle` cannot, so the caller
  /// upper-cases the string.
  static const TextStyle labelLargeUppercase = labelLarge;

  static const TextStyle labelBase = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: AppFontWeight.semiBold,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: AppFontWeight.semiBold,
  );

  // -- Caption --

  static const TextStyle captionBase = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle captionSmall = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: AppFontWeight.regular,
    height: 18 / 12,
    letterSpacing: 0.06,
  );

  static const TextStyle captionMicro = TextStyle(
    fontFamily: family,
    fontSize: 10,
    fontWeight: AppFontWeight.semiBold,
    height: 16 / 10,
    letterSpacing: 0.05,
  );
}
