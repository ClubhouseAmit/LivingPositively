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

  // -- Non-ColorScheme tokens (no semantic slot, kept for legacy parity) --

  /// Success / confirmation accent. Source: legacy `appGreen`.
  static const Color success = Color(0xFF01B91E);

  /// Card/inactive grey. Source: legacy `lightGray`.
  static const Color neutralLight = Color.fromARGB(255, 231, 231, 231);

  /// Muted text/icon grey. Source: legacy `darkGray`.
  static const Color neutralDark = Color(0xFF9A9EB6);

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
  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  error: AppColors.error,
  onError: AppColors.onError,
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
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Rubix',
  );
}

/// Dark `ThemeData` — the ADR specifies "light + initially light-only
/// `darkTheme` stub". This intentionally mirrors the light theme so
/// devices with a system dark setting do not render against an
/// unstyled Material 2 dark scheme (which would show unbranded
/// near-black backgrounds and break the visual contract the audit was
/// reviewing). A real dark palette is deferred to a follow-up phase.
ThemeData buildDarkThemeStub() => buildLightTheme();
