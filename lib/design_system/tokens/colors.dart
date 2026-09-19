import 'package:flutter/painting.dart' show Color;

/// Brand colour tokens.
///
/// Relocated verbatim from `lib/util/theme/app_theme.dart` (Phase D, ADR-005
/// §Decision step 4) as step 1 of the design-system extraction: same values,
/// same names, moved so the design system owns zero `material.dart` imports.
/// The two `Colors.white`/`Colors.black` references from that file are
/// replaced with their raw hex here for the same reason — `Colors` is a
/// Material class.
///
/// `lib/util/theme/app_theme.dart` still owns turning these into a
/// `ColorScheme`/`ThemeData` for `MaterialApp` — that construction is
/// genuinely Material and belongs there, not here.
class AppColors {
  AppColors._();

  /// Brand calming lavender — primary surface/button colour.
  /// Source: legacy `primaryPurple`.
  static const Color primary = Color(0xFFA688F8);

  /// Foreground colour on `primary` (button labels, icons).
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Soft purple highlight — used for selected/secondary affordances.
  /// Source: legacy `lightPurple`.
  static const Color secondary = Color(0xFFE3C6FF);

  /// Foreground colour on `secondary`.
  static const Color onSecondary = Color(0xFF000000);

  /// Default scaffold/background surface.
  /// Source: legacy `appWhite` / `backgroundGray` (same hex).
  static const Color surface = Color(0xFFFAF8F8);

  /// Pure white — `AppCard`'s default background.
  static const Color white = Color(0xFFFFFFFF);

  /// Body-text colour on `surface`.
  /// Source: legacy `appBlue` (the dark navy used for headings/text).
  static const Color onSurface = Color(0xFF0F2851);

  /// Destructive / error semantic colour. Replaces the raw `Colors.red`
  /// previously hard-coded in `myButtonStyle3`. Kept at the same red
  /// value as `Colors.red` (Material red 500) so Phase D was a no-op
  /// visually; downstream PRs can re-tune without touching call sites.
  static const Color error = Color(0xFFF44336);

  /// Foreground on `error`.
  static const Color onError = Color(0xFFFFFFFF);

  /// Pale lavender used for primary button backgrounds in dark mode.
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
  /// This artwork-specific token is deliberately not a `ColorScheme`
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
  static const Color onSuccess = Color(0xFFFFFFFF);

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
  /// distinct color from [success]/`tertiary` despite looking similar.
  /// Figma node 1661:3187 (Android Large - 15); no dark-mode treatment
  /// designed yet, same value used in both themes pending design follow-up.
  static const Color suggestionCardOutline = Color(0xFF01B99F);

  /// PDF-export tint. Source: legacy `pdfpurple`. The original literal
  /// `0xfaf6fd` lacks the leading `0xFF` alpha byte; preserved verbatim
  /// to keep PDF output byte-identical to pre-Phase-D builds.
  // ignore: use_full_hex_values_for_flutter_colors
  static const Color pdfTint = Color(0xfaf6fd);
}
