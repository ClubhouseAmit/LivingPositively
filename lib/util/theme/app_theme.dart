import 'package:flutter/material.dart';
import 'package:mazilon/design_system/tokens/colors.dart';

export 'package:mazilon/design_system/tokens/colors.dart';

/// Phase D (ADR-005 §Decision step 4) — semantic colour tokens.
///
/// `AppColors` itself moved to `lib/design_system/tokens/colors.dart` (step 1
/// of the design-system extraction, 2026-09-19): this file keeps only what's
/// genuinely Material — turning those tokens into a `ColorScheme`/`ThemeData`
/// for `MaterialApp`. See that file's doc comment for the token history.

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
/// No `fontFamily` set on any style either, for the same reason: `ThemeData`
/// already applies its own `fontFamily: 'Rubix'` argument to the base
/// `Typography` text theme before merging this one on top, so repeating
/// `fontFamily: 'Rubix'` on every entry here would be pure duplication.
const TextTheme _appTextTheme = TextTheme(
  // Screen title headers.
  headlineLarge: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 36.4 / 28,
  ),
  // Section title headers.
  headlineMedium: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 24.6 / 24,
  ),
  // Highlight text inside cards.
  titleLarge: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 30.0 / 18,
  ),
  // Textfield inputs.
  titleSmall: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 17.0 / 14,
  ),
  // Buttons, highlights.
  labelLarge: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 19.0 / 16,
  ),
  // Standard paragraphs.
  bodyLarge: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 19.0 / 16,
  ),
  // Muted hints.
  bodySmall: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 32.0 / 14,
  ),
  // Helper labels.
  labelSmall: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 13.5 / 10,
  ),
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
ThemeData buildLightTheme() {
  final InputDecorationThemeData inputs = _inputDecorationTheme(
    outline: AppColors.neutralLight,
    focus: AppColors.primary,
    error: AppColors.error,
  );
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: appLightColorScheme,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.pageBackground,
    bottomAppBarTheme: const BottomAppBarThemeData(color: Colors.white),
    textTheme: _appTextTheme,
    inputDecorationTheme: inputs,
    // `DropdownMenu` reads `DropdownMenuThemeData`, never
    // `ThemeData.inputDecorationTheme` — both have to be set or a dropdown
    // and a text field on the same screen will not match.
    dropdownMenuTheme: DropdownMenuThemeData(inputDecorationTheme: inputs),
    fontFamily: 'Rubix',
  );
}

/// Dark `ThemeData` used by the user's explicit dark-mode setting. Material 2
/// remains enabled to preserve the existing custom control styling.
ThemeData buildDarkTheme() {
  final InputDecorationThemeData inputs = _inputDecorationTheme(
    outline: AppColors.darkOutline,
    focus: AppColors.darkPrimary,
    error: AppColors.darkError,
    fill: AppColors.darkSurfaceContainer,
  );
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
    textTheme: _appTextTheme,
    inputDecorationTheme: inputs,
    dropdownMenuTheme: DropdownMenuThemeData(inputDecorationTheme: inputs),
    fontFamily: 'Rubix',
  );
}
