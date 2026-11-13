import 'package:flutter/widgets.dart';

import 'package:mazilon/design_system/tokens/colors.dart';

/// The LP-DS Figma color tokens for one mode, the way a Figma variable has
/// one value per mode. Widgets ask for a color by its Figma name and never
/// check the mode:
///
/// ```dart
/// color: context.colors.surfaceSunken,
/// ```
///
/// Not a second palette: every value is an [AppColors] constant, and
/// `colors.dart` stays the only place hex values live. [light] holds the
/// plain names, [dark] the `dark`-prefixed ones (a test checks the pairing).
/// Tokens are added when a widget first needs them.
enum AppColorTokens {
  light(
    accentMuted: AppColors.accentMuted,
    accentPressed: AppColors.accentPressed,
    accentPrimary: AppColors.accentPrimary,
    contentPrimary: AppColors.contentPrimary,
    contentSecondary: AppColors.contentSecondary,
    contentTertiary: AppColors.contentTertiary,
    effectHairline: AppColors.effectHairline,
    surfaceCanvas: AppColors.surfaceCanvas,
    surfaceDisabled: AppColors.surfaceDisabled,
    surfaceRaised: AppColors.surfaceRaised,
    surfaceRaisedHigh: AppColors.surfaceRaisedHigh,
    surfaceRaisedHighest: AppColors.surfaceRaisedHighest,
    surfaceRaisedHighest90: AppColors.surfaceRaisedHighest90,
    surfaceSunken: AppColors.surfaceSunken,
    surfaceWhite: AppColors.surfaceWhite,
    surfaceWhite75: AppColors.surfaceWhite75,
  ),
  dark(
    accentMuted: AppColors.darkAccentMuted,
    accentPressed: AppColors.darkAccentPressed,
    accentPrimary: AppColors.darkAccentPrimary,
    contentPrimary: AppColors.darkContentPrimary,
    contentSecondary: AppColors.darkContentSecondary,
    contentTertiary: AppColors.darkContentTertiary,
    effectHairline: AppColors.darkEffectHairline,
    surfaceCanvas: AppColors.darkSurfaceCanvas,
    surfaceDisabled: AppColors.darkSurfaceDisabled,
    surfaceRaised: AppColors.darkSurfaceRaised,
    surfaceRaisedHigh: AppColors.darkSurfaceRaisedHigh,
    surfaceRaisedHighest: AppColors.darkSurfaceRaisedHighest,
    surfaceRaisedHighest90: AppColors.darkSurfaceRaisedHighest90,
    surfaceSunken: AppColors.darkSurfaceSunken,
    surfaceWhite: AppColors.darkSurfaceWhite,
    surfaceWhite75: AppColors.darkSurfaceWhite75,
  );

  const AppColorTokens({
    required this.accentMuted,
    required this.accentPressed,
    required this.accentPrimary,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentTertiary,
    required this.effectHairline,
    required this.surfaceCanvas,
    required this.surfaceDisabled,
    required this.surfaceRaised,
    required this.surfaceRaisedHigh,
    required this.surfaceRaisedHighest,
    required this.surfaceRaisedHighest90,
    required this.surfaceSunken,
    required this.surfaceWhite,
    required this.surfaceWhite75,
  });

  final Color accentMuted;
  final Color accentPressed;
  final Color accentPrimary;
  final Color contentPrimary;
  final Color contentSecondary;
  final Color contentTertiary;
  final Color effectHairline;
  final Color surfaceCanvas;
  final Color surfaceDisabled;
  final Color surfaceRaised;
  final Color surfaceRaisedHigh;
  final Color surfaceRaisedHighest;
  final Color surfaceRaisedHighest90;
  final Color surfaceSunken;
  final Color surfaceWhite;
  final Color surfaceWhite75;

  /// The tokens for the current mode, from the nearest [AppColorScope].
  ///
  /// A missing scope fails in debug: falling back to light would quietly
  /// draw light colors in dark mode. Release builds fall back to light
  /// rather than crash.
  static AppColorTokens of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppColorScope>();
    assert(
      scope != null,
      'No AppColorScope above this widget. The app gets one from appBuilder '
      '(features/shell/ui/app_builder.dart); a test wraps its widget in one.',
    );
    return scope?.tokens ?? light;
  }
}

/// Hands [tokens] to every widget below. The app sets it once, above the
/// navigator, from the mode `MaterialApp` resolved.
class AppColorScope extends InheritedWidget {
  const AppColorScope({super.key, required this.tokens, required super.child});

  final AppColorTokens tokens;

  @override
  bool updateShouldNotify(AppColorScope oldWidget) =>
      tokens != oldWidget.tokens;
}

extension AppColorTokensContext on BuildContext {
  /// The color tokens for the current mode. See [AppColorTokens].
  AppColorTokens get colors => AppColorTokens.of(this);
}
