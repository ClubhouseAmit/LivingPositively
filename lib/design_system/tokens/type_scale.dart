import 'dart:ui' show Locale;

import 'package:flutter/painting.dart' show TextStyle;

import 'font_weight.dart';

/// Type-scale tokens.
///
/// Mirrors the LP-DS Figma file (page "Typography", node 7:193) one-to-one by
/// name: Figma `Heading/H1` is [headingH1], `Body/Base Paragraph` is
/// [bodyBaseParagraph].
///
/// Most Figma styles use "auto" line height, which is the font's own line
/// height (1.46875 × size for Heebo, 1.185 × for Rubik). Those tokens leave
/// `height` unset, which is what Flutter does too. Only styles with a fixed
/// line height in Figma set `height`. So Hebrew lines are shorter than
/// English ones, as in Figma's Hebrew components (Title/Base 16px → 19px).
///
/// Tokens carry no `fontFamily`: the family depends on the app language
/// (Figma variable `font/family/FontFamily` — English mode Heebo, Hebrew mode
/// Rubik), so [familyFor] picks it. The theme and the design-system widgets
/// call it; anything else inherits the family from the theme, so a widget
/// never sets `fontFamily: 'Heebo'` itself.
abstract class AppTypeScale {
  static const String family = 'Heebo';
  static const String hebrewFamily = 'Rubik';

  /// The family for [locale]. A null locale (no `Localizations` above the
  /// widget) gets the default family.
  static String familyFor(Locale? locale) =>
      locale?.languageCode == 'he' ? hebrewFamily : family;

  // -- Display --

  static const TextStyle displayHugeExtraBold = TextStyle(
    fontSize: 68,
    fontWeight: AppFontWeight.extraBold,
    height: 74 / 68,
  );

  static const TextStyle displayHugeRegular = TextStyle(
    fontSize: 68,
    fontWeight: AppFontWeight.regular,
    height: 74 / 68,
  );

  static const TextStyle displayHeroExtraBold = TextStyle(
    fontSize: 34,
    fontWeight: AppFontWeight.extraBold,
    height: 44 / 34,
  );

  static const TextStyle displayHeroRegular = TextStyle(
    fontSize: 34,
    fontWeight: AppFontWeight.regular,
    height: 44 / 34,
  );

  // -- Heading --

  static const TextStyle headingH1 = TextStyle(
    fontSize: 28,
    fontWeight: AppFontWeight.medium,
  );

  static const TextStyle headingH2 = TextStyle(
    fontSize: 22,
    fontWeight: AppFontWeight.semiBold,
  );

  static const TextStyle headingH3 = TextStyle(
    fontSize: 20,
    fontWeight: AppFontWeight.bold,
  );

  static const TextStyle headingH4 = TextStyle(
    fontSize: 17,
    fontWeight: AppFontWeight.bold,
  );

  // -- Title --

  static const TextStyle titleLarge = TextStyle(
    fontSize: 17,
    fontWeight: AppFontWeight.semiBold,
  );

  static const TextStyle titleBase = TextStyle(
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle titleBaseBold = TextStyle(
    fontSize: 16,
    fontWeight: AppFontWeight.bold,
    height: 20 / 16,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 15,
    fontWeight: AppFontWeight.semiBold,
  );

  static const TextStyle titleSmallBold = TextStyle(
    fontSize: 15,
    fontWeight: AppFontWeight.bold,
  );

  /// Figma sets this style to UPPERCASE; `TextStyle` cannot, so the caller
  /// upper-cases the string. Despite its Figma name, its values are
  /// `Label/Small`'s (12 / SemiBold).
  static const TextStyle titleSmallBoldUppercase = labelSmall;

  // -- Body --

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle bodyBase = TextStyle(
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle bodyBaseMedium = TextStyle(
    fontSize: 16,
    fontWeight: AppFontWeight.medium,
  );

  static const TextStyle bodyBaseParagraph = TextStyle(
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
    height: 22 / 16,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 15,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle bodySmallParagraph = TextStyle(
    fontSize: 15,
    fontWeight: AppFontWeight.regular,
    height: 20 / 15,
  );

  static const TextStyle bodyXSmall = TextStyle(
    fontSize: 14,
    fontWeight: AppFontWeight.regular,
  );

  // -- Label --

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: AppFontWeight.semiBold,
  );

  /// Figma sets this style to UPPERCASE; `TextStyle` cannot, so the caller
  /// upper-cases the string.
  static const TextStyle labelLargeUppercase = labelLarge;

  static const TextStyle labelBase = TextStyle(
    fontSize: 13,
    fontWeight: AppFontWeight.semiBold,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: AppFontWeight.semiBold,
  );

  // -- Caption --

  static const TextStyle captionBase = TextStyle(
    fontSize: 13,
    fontWeight: AppFontWeight.regular,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 12,
    fontWeight: AppFontWeight.regular,
    height: 18 / 12,
    letterSpacing: 0.06,
  );

  static const TextStyle captionMicro = TextStyle(
    fontSize: 10,
    fontWeight: AppFontWeight.semiBold,
    height: 16 / 10,
    letterSpacing: 0.05,
  );
}
