import 'package:flutter/painting.dart' show Color;

/// Brand colour tokens.
///
/// The tokens below the "Figma tokens" line mirror the LP-DS Figma file
/// (page "Colors", frame "Variables Documentation - Color Tokens", node
/// 88:332), one-to-one by name: Figma `surface/canvas` is [surfaceCanvas]
/// (light mode) and [darkSurfaceCanvas] (dark mode). Alpha variants carry
/// their opacity in the hex alpha byte.
///
/// The names above that line are legacy aliases kept so existing call sites
/// compile while the app moves to the Figma names (#431). New code uses the
/// Figma names; the aliases are deleted once nothing reads them.
///
/// The design system owns zero `material.dart` imports — turning these into
/// a `ColorScheme`/`ThemeData` happens in `lib/util/async/app_theme.dart`.
class AppColors {
  AppColors._();

  // -- Legacy aliases (light) --

  /// Legacy alias — use [accentPrimary].
  static const Color primary = accentPrimary;

  /// Legacy alias — use [contentOnAccent].
  static const Color onPrimary = contentOnAccent;

  /// Legacy alias — use [accentContainer].
  static const Color secondary = accentContainer;

  /// Legacy alias — use [accentOnContainer].
  static const Color onSecondary = accentOnContainer;

  /// Legacy alias — use [surfaceRaised].
  static const Color surface = surfaceRaised;

  /// Legacy alias — use [surfaceRaisedHigh].
  static const Color white = surfaceRaisedHigh;

  /// Legacy alias — use [contentPrimary].
  static const Color onSurface = contentPrimary;

  /// Legacy alias — use [statusDanger].
  static const Color error = statusDanger;

  /// Legacy alias — use [contentOnAccent].
  static const Color onError = contentOnAccent;

  /// Legacy alias — use [surfaceCanvas].
  static const Color pageBackground = surfaceCanvas;

  /// Legacy alias — use [statusSuccess].
  static const Color success = statusSuccess;

  /// Legacy alias — use [contentOnAccent].
  static const Color onSuccess = contentOnAccent;

  /// Legacy alias — use [effectHairline].
  static const Color neutralLight = effectHairline;

  /// Legacy alias — use [contentSecondary].
  static const Color neutralDark = contentSecondary;

  /// Legacy alias — use [contentSecondary].
  static const Color mutedForeground = contentSecondary;

  // -- Legacy aliases (dark) --

  /// Legacy alias — use [darkAccentPrimary].
  static const Color darkPrimary = darkAccentPrimary;

  /// Legacy alias — use [darkContentOnAccent].
  static const Color darkOnPrimary = darkContentOnAccent;

  /// Legacy alias — use [darkAccentContainer].
  static const Color darkSecondary = darkAccentContainer;

  /// Legacy alias — use [darkAccentOnContainer].
  static const Color darkOnSecondary = darkAccentOnContainer;

  /// Legacy alias — use [darkSurfaceCanvas].
  static const Color darkPageBackground = darkSurfaceCanvas;

  /// Legacy alias — use [darkSurfaceRaised].
  static const Color darkNavBackground = darkSurfaceRaised;

  /// Legacy alias — use [darkSurfaceRaised].
  static const Color darkSurface = darkSurfaceRaised;

  /// Legacy alias — use [darkSurfaceRaisedHigh].
  static const Color darkSurfaceContainer = darkSurfaceRaisedHigh;

  /// Legacy alias — use [darkContentPrimary].
  static const Color darkOnSurface = darkContentPrimary;

  /// Legacy alias — use [darkStatusDanger].
  static const Color darkError = darkStatusDanger;

  /// Legacy alias — use [darkContentOnAccent].
  static const Color darkOnError = darkContentOnAccent;

  /// Legacy alias — use [darkStatusSuccess].
  static const Color darkSuccess = darkStatusSuccess;

  /// Legacy alias — use [darkContentOnAccent].
  static const Color darkOnSuccess = darkContentOnAccent;

  /// Legacy alias — use [darkContentSecondary].
  static const Color darkOutline = darkContentSecondary;

  // -- Not yet in Figma (component follow-ups decide their fate) --

  /// Pure-white outline for the lower logo letters in dark mode — an
  /// artwork exception, not a text foreground.
  static const Color darkLogoOutline = Color(0xFFFFFFFF);

  /// Inactive onboarding progress-dot fill. Figma node 1660:2067; same value
  /// in both themes pending design follow-up.
  static const Color progressTrack = Color(0xFFD9D9D9);

  /// Dashed border on an unselected onboarding-suggestion card — teal,
  /// distinct from [statusSuccess]. Figma node 1661:3187; same value in both
  /// themes pending design follow-up.
  static const Color suggestionCardOutline = Color(0xFF01B99F);

  /// PDF-export tint. The original literal `0xfaf6fd` lacks the leading
  /// `0xFF` alpha byte; preserved verbatim to keep PDF output byte-identical.
  // ignore: use_full_hex_values_for_flutter_colors
  static const Color pdfTint = Color(0xfaf6fd);

  // ====================== Figma tokens (light) ======================

  // accent/*
  static const Color accentContainer = Color(0xFFE8DDFF);
  static const Color accentHighlight = Color(0xFFF2ED4E);
  static const Color accentMuted = Color(0xFFDC9BF6);
  static const Color accentOnContainer = Color(0xFF22005D);
  static const Color accentPrimary = Color(0xFFB44FDD);
  static const Color accentWash = Color(0xFFEFE9FE);

  // action/*
  static const Color actionEmergency = Color(0xFF33373D);

  // content/*
  static const Color contentOnAccent = Color(0xFFFFFFFF);
  static const Color contentOnEmergency = Color(0xFFFFFFFF);
  static const Color contentOnInverse = Color(0xFFF5EFF7);
  static const Color contentPlaceholder = Color(0xFF5C6066);
  static const Color contentPrimary = Color(0xFF16264A);
  static const Color contentPrimary12 = Color(0x1F16264A);
  static const Color contentSecondary = Color(0xFF596271);
  static const Color contentTertiary = Color(0xFFB6BCC6);

  // effect/*
  static const Color effectHairline = Color(0xFFD5CAC1);
  static const Color effectHighlight = Color(0x8CFFFFFF);
  static const Color effectScrim = Color(0x52000000);
  static const Color effectShadow = Color(0x1216264A);

  // nav/*
  static const Color navInactive = Color(0xFF8A8E97);

  // plan/*
  static const Color planProfessional = Color(0xFF3A5BA9);
  static const Color planProfessionalContainer = Color(0xFFDBE1FF);
  static const Color planSupport = Color(0xFF206A50);
  static const Color planSupportContainer = Color(0xFFA8F2CF);
  static const Color planTrigger = Color(0xFF8F4B45);
  static const Color planTriggerContainer = Color(0xFFFFDAD5);
  static const Color planWarning = Color(0xFF8B5000);
  static const Color planWarningContainer = Color(0xFFFFDCC2);
  static const Color planWellness = Color(0xFF6A4FBF);
  static const Color planWellnessContainer = Color(0xFFE8DDFF);

  // status/*
  static const Color statusDanger = Color(0xFFB3261E);
  static const Color statusDangerContainer = Color(0xFFF9DEDC);
  static const Color statusSuccess = Color(0xFF256C41);
  static const Color statusSuccessContainer = Color(0xFFA8F2C0);

  // surface/*
  static const Color surfaceBackdrop = Color(0xFFDFDAD3);
  static const Color surfaceCanvas = Color(0xFFF4EFE8);
  static const Color surfaceDisabled = Color(0xBFEBE4DA);
  static const Color surfaceFeatured = Color(0xFF14264C);
  static const Color surfaceInverse = Color(0xFF322F35);
  static const Color surfaceRaised = Color(0xFFFBF9F6);
  static const Color surfaceRaisedHigh = Color(0xFFFFFFFF);
  static const Color surfaceRaisedHighest = Color(0xFFF2EBE4);
  static const Color surfaceRaisedHighest90 = Color(0xE6F2EBE4);
  static const Color surfaceSunken = Color(0xFFEBE4DA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceWhite75 = Color(0xBFFFFFFF);

  // ====================== Figma tokens (dark) ======================

  // accent/*
  static const Color darkAccentContainer = Color(0xFF4F378B);
  static const Color darkAccentHighlight = Color(0xFFD8D34A);
  static const Color darkAccentMuted = Color(0xFFDD89FF);
  static const Color darkAccentOnContainer = Color(0xFFEADDFF);
  static const Color darkAccentPrimary = Color(0xFFB968D9);
  static const Color darkAccentWash = Color(0xFF2C2440);

  // action/*
  static const Color darkActionEmergency = Color(0xFF7C838E);

  // content/*
  static const Color darkContentOnAccent = Color(0xFF2A1A5E);
  static const Color darkContentOnEmergency = Color(0xFFFFFFFF);
  static const Color darkContentOnInverse = Color(0xFF322F35);
  static const Color darkContentPlaceholder = Color(0xFF7A736B);
  static const Color darkContentPrimary = Color(0xFFF2EDE6);
  static const Color darkContentPrimary12 = Color(0x1FF2EDE6);
  static const Color darkContentSecondary = Color(0xFFC0B9B2);
  static const Color darkContentTertiary = Color(0xFF6A635C);

  // effect/*
  static const Color darkEffectHairline = Color(0xFF4F4740);
  static const Color darkEffectHighlight = Color(0x29FFFFFF);
  static const Color darkEffectScrim = Color(0x99000000);
  static const Color darkEffectShadow = Color(0x80000000);

  // nav/*
  static const Color darkNavInactive = Color(0xFF8A8279);

  // plan/*
  static const Color darkPlanProfessional = Color(0xFFB4C5FF);
  static const Color darkPlanProfessionalContainer = Color(0xFF22407F);
  static const Color darkPlanSupport = Color(0xFF8CD6B4);
  static const Color darkPlanSupportContainer = Color(0xFF0C4A34);
  static const Color darkPlanTrigger = Color(0xFFFFB4AB);
  static const Color darkPlanTriggerContainer = Color(0xFF5F1F1B);
  static const Color darkPlanWarning = Color(0xFFFFB77C);
  static const Color darkPlanWarningContainer = Color(0xFF5C3600);
  static const Color darkPlanWellness = Color(0xFFD0BCFF);
  static const Color darkPlanWellnessContainer = Color(0xFF4F378B);

  // status/*
  static const Color darkStatusDanger = Color(0xFFF2B8B5);
  static const Color darkStatusDangerContainer = Color(0xFF8C1D18);
  static const Color darkStatusSuccess = Color(0xFF7FE0A5);
  static const Color darkStatusSuccessContainer = Color(0xFF1E5236);

  // surface/*
  static const Color darkSurfaceBackdrop = Color(0xFF0E0D0C);
  static const Color darkSurfaceCanvas = Color(0xFF161412);
  static const Color darkSurfaceDisabled = Color(0xBF100F0D);
  static const Color darkSurfaceFeatured = Color(0xFF2A2438);
  static const Color darkSurfaceInverse = Color(0xFFE9E1DA);
  static const Color darkSurfaceRaised = Color(0xFF221F1C);
  static const Color darkSurfaceRaisedHigh = Color(0xFF2B2725);
  static const Color darkSurfaceRaisedHighest = Color(0xFF363230);
  static const Color darkSurfaceRaisedHighest90 = Color(0xE6363230);
  static const Color darkSurfaceSunken = Color(0xFF100F0D);
  static const Color darkSurfaceWhite = Color(0xFFFFFFFF);
  static const Color darkSurfaceWhite75 = Color(0xBFFFFFFF);
}
