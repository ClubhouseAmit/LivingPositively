import 'package:flutter/material.dart';

/// Phase D (ADR-005 §Decision step 4) — semantic colour tokens.
///
/// Until Phase D, the palette lived as nine top-level mutable `Color`
/// variables with no `ThemeData` wiring
/// (`lib/main.dart:410-428`). Call sites picked from that palette
/// alongside raw `Colors.red` / `Colors.blue` / one-off ARGB literals,
/// so the palette was decorative rather than enforced — see
/// `docs/UX_GAPS.md §1.1, §1.2`.
///
/// `AppColors` is the token layer the audit asked for. The brand-palette
/// values are preserved exactly (so this PR is visually a no-op) and
/// re-exposed under semantic names that `ColorScheme` understands. The
/// nine legacy variables in `styles.dart` now forward to these tokens —
/// the ADR's mitigation for the large blast radius.
class AppColors {
  AppColors._();

  /// Brand calming lavender — primary surface/button colour.
  /// Source: legacy `primaryPurple`.
  static const Color primary = Color(0xFFA688F8);

  /// Foreground colour on `primary` (button labels, icons).
  static const Color onPrimary = Colors.white;

  /// Soft purple highlight — used for selected/secondary affordances.
  /// Source: legacy `lightPurple`.
  static const Color secondary = Color(0xFFEAD5FF);

  /// Foreground colour on `secondary`.
  static const Color onSecondary = Colors.black;

  /// Default scaffold/background surface.
  /// Source: legacy `appWhite` / `backgroundGray` (same hex).
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1E2124);

  static const Color error = Color(0xFFF44336);

  /// Foreground on `error`.
  static const Color onError = Colors.white;

  /// Dark-mode equivalent of the brand lavender. The light value would not
  /// maintain enough contrast against the dark surface for controls.
  static const Color darkPrimary = Color(0xFFC4A8F5);

  /// Foreground colour on [darkPrimary].
  static const Color darkOnPrimary = Color(0xFF2E1649);

  /// Dark-mode secondary accent for selected and supporting controls.
  static const Color darkSecondary = Color(0xFFE8D7FF);

  /// Foreground colour on [darkSecondary].
  static const Color darkOnSecondary = Color(0xFF2A1941);

  /// Default dark scaffold and page surface.
  static const Color darkSurface = Color(0xFF141218);

  /// Elevated dark surface used by cards and input controls.
  static const Color darkSurfaceContainer = Color(0xFF211F26);

  /// Body-text colour on [darkSurface].
  static const Color darkOnSurface = Color(0xFFE7E0E8);

  /// Accessible destructive colour for dark mode.
  static const Color darkError = Color(0xFFFFB4AB);

  /// Foreground on [darkError].
  static const Color darkOnError = Color(0xFF690005);

  // -- Non-ColorScheme tokens (no semantic slot, kept for legacy parity) --

  /// Success / confirmation accent. Source: legacy `appGreen`.
  static const Color success = Color(0xFF01B91E);

  /// Foreground on [success].
  static const Color onSuccess = Colors.white;

  /// Card/inactive grey. Apple-style soft neutral.
  static const Color neutralLight = Color(0xFFF5F5F7);

  /// Muted text/icon grey. Source: legacy `darkGray`.
  static const Color neutralDark = Color(0xFF9A9EB6);

  /// Success accent that remains legible on the dark surface.
  static const Color darkSuccess = Color(0xFF87E990);

  /// Foreground on [darkSuccess].
  static const Color darkOnSuccess = Color(0xFF003913);

  /// Muted text, borders, and dividers in dark mode.
  static const Color darkOutline = Color.fromARGB(255, 178, 172, 182);

  /// PDF-export tint. Source: legacy `pdfpurple`. The original literal
  /// `0xfaf6fd` lacks the leading `0xFF` alpha byte; preserved verbatim
  /// to keep PDF output byte-identical to pre-Phase-D builds.
  // ignore: use_full_hex_values_for_flutter_colors
  static const Color pdfTint = Color(0xfaf6fd);

  // -- AffirmationCard tokens (dusty-blue palette, low arousal) --
  // Background: dusty blue #E6EDF2 (soft, clinical-grade support tool feel).
  // Foreground: dark blue-gray #2E3E4E.
  // Contrast ratio passes WCAG AA.
  // Brand purple is used only as a thin, desaturated accent (left border) or removed.

  /// Soft dusty-blue background for the AffirmationCard banner.
  static const Color affirmationBackground = Color(0xFFE6EDF2);

  /// Dark blue-gray text colour for the AffirmationCard banner.
  static const Color affirmationForeground = Color(0xFF2E3E4E);

  /// Muted blue-gray for the AffirmationCard label and secondary controls.
  /// Contrast on [affirmationBackground] ≈ 5.6:1 (Passes WCAG AA for small text).
  static const Color affirmationMuted = Color(0xFF4A6072);
}

/// Light `ColorScheme` derived from `AppColors`. Phase D wires this onto
/// `MaterialApp.theme` so future Material widgets read tokens rather than
/// re-deriving from `primarySwatch`.
const ColorScheme appLightColorScheme = ColorScheme.light(
  primary: AppColors.primary,
  secondary: AppColors.secondary,
  tertiary: AppColors.success,
  onTertiary: AppColors.onSuccess,
  onSurface: AppColors.onSurface,
  error: AppColors.error,
  outline: AppColors.neutralDark,
  surfaceContainerHighest: AppColors.neutralLight,
);

/// Dark `ColorScheme` for user-selected dark mode. Its foreground and
/// background pairs are deliberately separate from the light palette so the
/// setting does not merely dim the app while leaving unreadable text behind.
const ColorScheme appDarkColorScheme = ColorScheme.dark(
  primary: AppColors.darkPrimary,
  onPrimary: AppColors.darkOnPrimary,
  secondary: AppColors.darkSecondary,
  onSecondary: AppColors.darkOnSecondary,
  tertiary: AppColors.darkSuccess,
  onTertiary: AppColors.darkOnSuccess,
  surface: AppColors.darkSurface,
  onSurface: AppColors.darkOnSurface,
  error: AppColors.darkError,
  onError: AppColors.darkOnError,
  outline: AppColors.darkOutline,
  surfaceContainerHighest: AppColors.darkSurfaceContainer,
);

TextTheme _buildTextTheme(ColorScheme colorScheme) {
  return TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: colorScheme.onSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: colorScheme.onSurface,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: colorScheme.onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: colorScheme.onSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      height: 1.5,
      color: colorScheme.onSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.normal,
      height: 1.5,
      color: colorScheme.onSurface,
    ),
    labelSmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.normal,
      height: 1.4,
      color: colorScheme.onSurface.withValues(alpha: 0.7),
    ),
  );
}

/// Light `ThemeData` for Phase D. Material 2 is kept on (`useMaterial3:
/// false`) because the codebase ships custom `TextButton.styleFrom` /
/// `RoundedRectangleBorder` styles that target Material 2 token names;
/// a Material 3 flip belongs in a separate PR with design review.
ThemeData buildLightTheme() {
  const colorScheme = appLightColorScheme;
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Rubix',
    textTheme: _buildTextTheme(colorScheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: colorScheme.surfaceContainerHighest,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
  );
}

/// Dark `ThemeData` used by the user's explicit dark-mode setting. Material 2
/// remains enabled to preserve the existing custom control styling.
ThemeData buildDarkTheme() {
  const colorScheme = appDarkColorScheme;
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    primaryColor: AppColors.darkPrimary,
    scaffoldBackgroundColor: AppColors.darkSurface,
    canvasColor: AppColors.darkSurface,
    cardColor: AppColors.darkSurfaceContainer,
    dividerColor: AppColors.darkOnSurface.withValues(alpha: 0.2),
    textTheme: _buildTextTheme(colorScheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.darkOutline.withValues(alpha: 0.1)),
      ),
      margin: EdgeInsets.zero,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkOnSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.darkSurfaceContainer,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(32),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    fontFamily: 'Rubix',
  );
}
