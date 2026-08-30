import 'package:flutter/material.dart';

/// Phase D (ADR-005 §Decision step 4) — semantic colour tokens.
///
/// Until Phase D, the palette lived as nine top-level mutable `Color`
/// variables in `lib/util/styles.dart:5-13` with no `ThemeData` wiring
/// (`lib/main.dart:410-428`). Call sites picked from that palette
/// alongside raw `Colors.red` / `Colors.blue` / one-off ARGB literals,
/// so the palette was decorative rather than enforced — see
/// `docs/UX_GAPS.md §1.1, §1.2`.
///
/// `AppColors` is the token layer the audit asked for. The light brand
/// palette and explicitly preserved legacy/PDF values are re-exposed under
/// semantic names that `ColorScheme` understands. The dark primary,
/// secondary, surface, error, outline, and navigation tokens intentionally
/// migrate to the cool taupe palette consumed by [appDarkColorScheme] and
/// [buildDarkTheme]. The nine legacy variables in `styles.dart` now forward
/// to these tokens — the ADR's mitigation for the large blast radius.
class AppColors {
  AppColors._();

  /// Brand calming lavender — primary surface/button colour.
  /// Source: legacy `primaryPurple`.
  static const Color primary = Color(0xFFA688F8);

  /// Foreground colour on `primary` (button labels, icons).
  static const Color onPrimary = Colors.white;

  /// Soft purple highlight — used for selected/secondary affordances.
  /// Source: legacy `lightPurple`.
  static const Color secondary = Color(0xFFE3C6FF);

  /// Foreground colour on `secondary`.
  static const Color onSecondary = Colors.black;

  /// Default scaffold/background surface.
  /// Source: legacy `appWhite` / `backgroundGray` (same hex).
  static const Color surface = Color(0xFFFAF8F8);

  /// Body-text colour on `surface`.
  /// Source: legacy `appBlue` (the dark navy used for headings/text).
  static const Color onSurface = Color(0xFF0F2851);

  /// Destructive / error semantic colour. Replaces the raw `Colors.red`
  /// previously hard-coded in `myButtonStyle3`. Kept at the same red
  /// value as `Colors.red` (Material red 500) so Phase D is a no-op
  /// visually; downstream PRs can re-tune without touching call sites.
  static const Color error = Color(0xFFF44336);

  /// Foreground on `error`.
  static const Color onError = Colors.white;

  /// Muted beige used for primary controls in the taupe dark palette.
  static const Color darkPrimary = Color(0xFFD7C2FF);

  /// Accessible charcoal-taupe foreground on [darkPrimary].
  static const Color darkOnPrimary = Color(0xFF2B2A2C);

  /// Muted greige used for selected and supporting dark-mode controls.
  static const Color darkSecondary = Color(0xFFB9AEA0);

  /// Foreground colour on [darkSecondary].
  static const Color darkOnSecondary = Color(0xFF2B2A2C);

  /// Home page background in light mode — warm cream.
  static const Color pageBackground = Color(0xFFF4F0EB);

  /// Home page background in dark mode — gently warm charcoal taupe.
  static const Color darkPageBackground = Color(0xFF2D2B2A);

  /// App and navigation chrome in dark mode — cool dark taupe.
  static const Color darkNavBackground = Color(0xFF393739);

  /// Default dark page surface.
  static const Color darkSurface = Color(0xFF2B2A2C);

  /// Elevated taupe surface used by cards and input controls.
  static const Color darkSurfaceContainer = Color(0xFF4C494B);

  /// Body-text colour on [darkSurface].
  static const Color darkOnSurface = Color(0xFFF5F0E8);

  /// Pure-white outline for the lower logo letters in dark mode.
  ///
  /// This artwork-specific token is deliberately not a [ColorScheme]
  /// foreground: regular dark-mode text uses [darkOnSurface].
  static const Color darkLogoOutline = Color(0xFFFFFFFF);

  /// Accessible muted-rose destructive colour for dark mode.
  static const Color darkError = Color(0xFFA15857);

  /// Foreground on [darkError].
  static const Color darkOnError = Color(0xFFFFF5F0);

  // -- Non-ColorScheme tokens (no semantic slot, kept for legacy parity) --

  /// Success / confirmation accent. Source: legacy `appGreen`.
  static const Color success = Color(0xFF01B91E);

  /// Foreground on [success].
  static const Color onSuccess = Colors.white;

  /// Card/inactive grey. Source: legacy `lightGray`.
  static const Color neutralLight = Color.fromARGB(255, 231, 231, 231);

  /// Muted text/icon grey. Source: legacy `darkGray`.
  static const Color neutralDark = Color(0xFF9A9EB6);

  /// Forest-sage success accent that remains legible on the dark surface.
  static const Color darkSuccess = Color(0xFF74AD82);

  /// Foreground on [darkSuccess].
  static const Color darkOnSuccess = Color(0xFF102A1B);

  /// Accessible beige outline and small-text accent in dark mode.
  static const Color darkOutline = Color(0xFFD0C1A4);

  /// Inactive onboarding progress-dot fill — a lighter, distinct grey from
  /// [neutralDark]. Figma node 1660:2067; no dark-mode treatment designed
  /// yet, same value used in both themes pending design follow-up.
  static const Color progressTrack = Color(0xFFD9D9D9);

  /// Dashed border on an unselected onboarding-suggestion card — teal, a
  /// distinct color from [success]/[tertiary] despite looking similar.
  /// Figma node 1661:3187 (Android Large - 15); no dark-mode treatment
  /// designed yet, same value used in both themes pending design follow-up.
  static const Color suggestionCardOutline = Color(0xFF01B99F);

  /// PDF-export tint. Source: legacy `pdfpurple`. The original literal
  /// `0xfaf6fd` lacks the leading `0xFF` alpha byte; preserved verbatim
  /// to keep PDF output byte-identical to pre-Phase-D builds.
  // ignore: use_full_hex_values_for_flutter_colors
  static const Color pdfTint = Color(0xfaf6fd);
}

/// Light `ColorScheme` derived from `AppColors`. Phase D wires this onto
/// `MaterialApp.theme` so future Material widgets read tokens rather than
/// re-deriving from `primarySwatch`.
const ColorScheme appLightColorScheme = ColorScheme.light(
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  tertiary: AppColors.success,
  onTertiary: AppColors.onSuccess,
  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  error: AppColors.error,
  onError: AppColors.onError,
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
  outlineVariant: AppColors.darkOutline,
  surfaceContainerHighest: AppColors.darkSurfaceContainer,
);

/// Light `ThemeData` for Phase D. Material 2 is kept on (`useMaterial3:
/// false`) because the codebase ships custom `TextButton.styleFrom` /
/// `RoundedRectangleBorder` styles that target Material 2 token names;
/// a Material 3 flip belongs in a separate PR with design review.
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: appLightColorScheme,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.pageBackground,
    bottomAppBarTheme: const BottomAppBarThemeData(color: Colors.white),
    fontFamily: 'Rubix',
  );
}

/// Dark `ThemeData` used by the user's explicit dark-mode setting. Material 2
/// remains enabled to preserve the existing custom control styling.
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    colorScheme: appDarkColorScheme,
    primaryColor: AppColors.darkPrimary,
    scaffoldBackgroundColor: AppColors.darkPageBackground,
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColors.darkNavBackground,
    ),
    canvasColor: AppColors.darkSurface,
    cardColor: AppColors.darkSurfaceContainer,
    dividerColor: AppColors.darkOnSurface.withValues(alpha: 0.2),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkNavBackground,
      foregroundColor: AppColors.darkOnSurface,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: AppColors.darkSurfaceContainer,
      filled: true,
    ),
    fontFamily: 'Rubix',
  );
}
