import 'package:flutter/painting.dart' show TextStyle;

import 'font_weight.dart';

/// Named type-scale tokens, matching DESIGN.md §2.2's eight named styles.
///
/// These are the same values as `_appTextTheme` in
/// `lib/util/theme/app_theme.dart` (Rubik/'Rubix', §2.2's font sizes and line
/// heights), reproduced here as standalone `TextStyle`s with `fontFamily`
/// baked in — `AppText` (step 2) has no `ThemeData` to inherit a font family
/// from, since it never sits under a `Theme.of(context)` read.
///
/// `ThemeData.textTheme` in `app_theme.dart` is unaffected and still owns
/// Material's own text styling; the two are allowed to describe the same
/// design in two places because one is Material's contract and one is this
/// design system's.
abstract class AppTypeScale {
  static const String _family = 'Rubix';

  /// Screen title headers.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: AppFontWeight.medium,
    height: 36.4 / 28,
  );

  /// Section title headers.
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: AppFontWeight.medium,
    height: 24.6 / 24,
  );

  /// Highlight text inside cards.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: AppFontWeight.medium,
    height: 30.0 / 18,
  );

  /// Textfield inputs.
  static const TextStyle titleSmall = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: AppFontWeight.medium,
    height: 17.0 / 14,
  );

  /// Buttons, highlights.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: AppFontWeight.medium,
    height: 19.0 / 16,
  );

  /// Standard paragraphs.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: AppFontWeight.regular,
    height: 19.0 / 16,
  );

  /// Muted hints.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: AppFontWeight.regular,
    height: 32.0 / 14,
  );

  /// Helper labels.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _family,
    fontSize: 10,
    fontWeight: AppFontWeight.regular,
    height: 13.5 / 10,
  );
}
