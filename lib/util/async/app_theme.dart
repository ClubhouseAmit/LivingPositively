import 'package:flutter/material.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/type_scale.dart';

export 'package:mazilon/design_system/tokens/colors.dart';

/// Phase D (ADR-005 §Decision step 4) — semantic colour tokens.
///
/// `AppColors` itself moved to `lib/design_system/tokens/colors.dart` (step 1
/// of the design-system extraction, 2026-09-19): this file keeps only what's
/// genuinely Material — turning those tokens into a `ColorScheme`/`ThemeData`
/// for `MaterialApp`. See that file's doc comment for the token history.

/// Light `ColorScheme` built from the Figma tokens in `AppColors` (#431).
/// Every slot reads a Figma-named token, never a legacy alias, so the
/// aliases can be deleted without touching this file.
const ColorScheme appLightColorScheme = ColorScheme.light(
  primary: AppColors.accentPrimary,
  onPrimary: AppColors.contentOnAccent,
  primaryContainer: AppColors.accentContainer,
  onPrimaryContainer: AppColors.accentOnContainer,
  secondary: AppColors.accentContainer,
  onSecondary: AppColors.accentOnContainer,
  tertiary: AppColors.statusSuccess,
  onTertiary: AppColors.contentOnAccent,
  surface: AppColors.surfaceRaised,
  onSurface: AppColors.contentPrimary,
  onSurfaceVariant: AppColors.contentSecondary,
  error: AppColors.statusDanger,
  onError: AppColors.contentOnAccent,
  errorContainer: AppColors.statusDangerContainer,
  // content/secondary, not tertiary: `outline` is read as muted text,
  // and tertiary is under 4.5:1 on every surface.
  outline: AppColors.contentSecondary,
  outlineVariant: AppColors.effectHairline,
  surfaceContainerHighest: AppColors.surfaceRaisedHighest,
  inverseSurface: AppColors.surfaceInverse,
  onInverseSurface: AppColors.contentOnInverse,
  scrim: AppColors.effectScrim,
  shadow: AppColors.effectShadow,
);

/// Dark `ColorScheme` for user-selected dark mode. Its foreground and
/// background pairs are deliberately separate from the light palette so the
/// setting does not merely dim the app while leaving unreadable text behind.
const ColorScheme appDarkColorScheme = ColorScheme.dark(
  primary: AppColors.darkAccentPrimary,
  onPrimary: AppColors.darkContentOnAccent,
  primaryContainer: AppColors.darkAccentContainer,
  onPrimaryContainer: AppColors.darkAccentOnContainer,
  secondary: AppColors.darkAccentContainer,
  onSecondary: AppColors.darkAccentOnContainer,
  tertiary: AppColors.darkStatusSuccess,
  onTertiary: AppColors.darkContentOnAccent,
  surface: AppColors.darkSurfaceRaised,
  onSurface: AppColors.darkContentPrimary,
  onSurfaceVariant: AppColors.darkContentSecondary,
  error: AppColors.darkStatusDanger,
  onError: AppColors.darkContentOnAccent,
  errorContainer: AppColors.darkStatusDangerContainer,
  outline: AppColors.darkContentSecondary,
  outlineVariant: AppColors.darkEffectHairline,
  surfaceContainerHighest: AppColors.darkSurfaceRaisedHighest,
  inverseSurface: AppColors.darkSurfaceInverse,
  onInverseSurface: AppColors.darkContentOnInverse,
  scrim: AppColors.darkEffectScrim,
  shadow: AppColors.darkEffectShadow,
);

/// Typography tokens — DESIGN.md §2.2. Extends `ThemeData.textTheme` rather
/// than a bespoke style class, so call sites read `Theme.of(context)
/// .textTheme.headlineLarge` the same way every other Material widget already
/// does, instead of each screen re-declaring its own `fontSize`/`fontWeight`.
/// That per-call-site duplication is how #359's button-cutoff bug happened:
/// an undeclared, unchecked `30.sp`/bold with nothing to catch it drifting
/// from the design.
///
/// Deliberately no `.sp` here: `.sp` re-scales for device *width*, which is
/// a different axis from the OS accessibility text-size the user actually
/// controls. Every `Text` already honours `MediaQuery.textScaler`
/// automatically regardless of the declared `fontSize` — stacking `.sp` on
/// top of that is the same double-scaling failure mode `AutoSizeText` hit in
/// this same fix (`designs/issue-338-audit.md`), one level further out.
///
/// No `color` set on any style: color stays with `ColorScheme`
/// (`AppColors`), unchanged from how call sites already source it.
///
/// Each Material slot points at the LP-DS Figma style closest to how the app
/// already uses it (#431). Slots the app never reads stay on Material's
/// defaults, in the theme's font.
const TextTheme _appTextTheme = TextTheme(
  // Screen title headers.
  headlineLarge: AppTypeScale.headingH1,
  // Section title headers.
  headlineMedium: AppTypeScale.headingH2,
  headlineSmall: AppTypeScale.headingH3,
  // Highlight text inside cards.
  titleLarge: AppTypeScale.titleLarge,
  titleMedium: AppTypeScale.bodyBaseMedium,
  // Textfield inputs — Figma's text fields use Title/Base.
  titleSmall: AppTypeScale.titleBase,
  // Buttons — Figma's buttons use Title/Small.
  labelLarge: AppTypeScale.titleSmall,
  // Standard paragraphs.
  bodyLarge: AppTypeScale.bodyBase,
  bodyMedium: AppTypeScale.bodySmall,
  // Muted hints.
  bodySmall: AppTypeScale.bodyXSmall,
  // Helper labels.
  labelSmall: AppTypeScale.captionMicro,
);

/// Corner radius of a text input — DESIGN.md §2.3 "Input Fields".
const double kInputRadius = 10;

/// Inside horizontal padding of an input, matching the shared
/// `formFieldInputDecoration` in `styles.dart`.
const double kInputPaddingX = 14;

/// The app-wide input style — DESIGN.md §3.4: radius 10, a 1px outline, and
/// dense padding.
///
/// This is the **only** place an input's appearance is declared. A call site
/// supplies meaning — `labelText`, `hintText`, `suffixIcon`, `errorText`,
/// `validator`, `maxLines` — and nothing visual. Every state is spelled out
/// here rather than left to Flutter's fallbacks, because `InputDecorator`
/// resolves each state independently (`enabledBorder`, `focusedBorder`, …) and
/// never falls back to `border`: a theme that sets only some states leaks the
/// Material defaults into the rest.
///
/// Deliberately carries **no** height constraint even though DESIGN.md names
/// 40: `custom_category_editor`, `mood_medicine_page` and `addFormAnswer` hold
/// 3–6 line fields that have to grow. Dense padding lands a single-line field
/// on 40; a screen that needs every control on one exact height adds its own
/// `constraints` on top of this.
InputDecorationThemeData _inputDecorationTheme({
  required Color outline,
  required Color focus,
  required Color error,
  Color? fill,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(kInputRadius),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecorationThemeData(
    filled: fill != null,
    fillColor: fill,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: kInputPaddingX,
      vertical: 10,
    ),
    border: border(outline, 1),
    enabledBorder: border(outline, 1),
    focusedBorder: border(focus, 1.5),
    errorBorder: border(error, 1.5),
    focusedErrorBorder: border(error, 1.5),
  );
}

/// Light `ThemeData` for Phase D. Material 2 is kept on (`useMaterial3:
/// false`) because the codebase ships custom `TextButton.styleFrom` /
/// `RoundedRectangleBorder` styles that target Material 2 token names;
/// a Material 3 flip belongs in a separate PR with design review.
///
/// [locale] is the app language; it picks the font family of every text
/// style.
ThemeData buildLightTheme([Locale? locale]) {
  final InputDecorationThemeData inputs = _inputDecorationTheme(
    outline: AppColors.effectHairline,
    focus: AppColors.accentPrimary,
    error: AppColors.statusDanger,
  );
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: appLightColorScheme,
    primaryColor: AppColors.accentPrimary,
    scaffoldBackgroundColor: AppColors.surfaceCanvas,
    cardColor: AppColors.surfaceRaisedHigh,
    dividerColor: AppColors.effectHairline,
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColors.surfaceRaisedHigh,
    ),
    textTheme: _appTextTheme,
    inputDecorationTheme: inputs,
    // `DropdownMenu` reads `DropdownMenuThemeData`, never
    // `ThemeData.inputDecorationTheme` — both have to be set or a dropdown
    // and a text field on the same screen will not match.
    dropdownMenuTheme: DropdownMenuThemeData(inputDecorationTheme: inputs),
    fontFamily: AppTypeScale.familyFor(locale),
  );
}

/// Dark `ThemeData` used by the user's explicit dark-mode setting. Material 2
/// remains enabled to preserve the existing custom control styling.
/// [locale] as in [buildLightTheme].
ThemeData buildDarkTheme([Locale? locale]) {
  final InputDecorationThemeData inputs = _inputDecorationTheme(
    outline: AppColors.darkEffectHairline,
    focus: AppColors.darkAccentPrimary,
    error: AppColors.darkStatusDanger,
    fill: AppColors.darkSurfaceRaisedHigh,
  );
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    colorScheme: appDarkColorScheme,
    primaryColor: AppColors.darkAccentPrimary,
    scaffoldBackgroundColor: AppColors.darkSurfaceCanvas,
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColors.darkSurfaceRaised,
    ),
    canvasColor: AppColors.darkSurfaceRaised,
    cardColor: AppColors.darkSurfaceRaisedHigh,
    dividerColor: AppColors.darkEffectHairline,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurfaceRaised,
      foregroundColor: AppColors.darkContentPrimary,
    ),
    textTheme: _appTextTheme,
    inputDecorationTheme: inputs,
    dropdownMenuTheme: DropdownMenuThemeData(inputDecorationTheme: inputs),
    fontFamily: AppTypeScale.familyFor(locale),
  );
}
