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
    contentPlaceholder: AppColors.contentPlaceholder,
    contentPrimary: AppColors.contentPrimary,
    contentPrimary12: AppColors.contentPrimary12,
    contentSecondary: AppColors.contentSecondary,
    contentTertiary: AppColors.contentTertiary,
    effectHairline: AppColors.effectHairline,
    notificationsErrorBg: AppColors.notificationsErrorBg,
    notificationsErrorContent: AppColors.notificationsErrorContent,
    notificationsInfoBg: AppColors.notificationsInfoBg,
    notificationsSuccessBg: AppColors.notificationsSuccessBg,
    notificationsSuccessContent: AppColors.notificationsSuccessContent,
    notificationsWarningBg: AppColors.notificationsWarningBg,
    notificationsWarningContent: AppColors.notificationsWarningContent,
    surfaceCanvas: AppColors.surfaceCanvas,
    surfaceDisabled: AppColors.surfaceDisabled,
    surfaceRaised: AppColors.surfaceRaised,
    surfaceRaisedHigh: AppColors.surfaceRaisedHigh,
    surfaceRaisedHighest: AppColors.surfaceRaisedHighest,
    surfaceRaisedHighest90: AppColors.surfaceRaisedHighest90,
    statusDanger: AppColors.statusDanger,
    surfaceSunken: AppColors.surfaceSunken,
    surfaceSunkenMore: AppColors.surfaceSunkenMore,
    surfaceWhite: AppColors.surfaceWhite,
    surfaceWhite75: AppColors.surfaceWhite75,
  ),
  dark(
    accentMuted: AppColors.darkAccentMuted,
    accentPressed: AppColors.darkAccentPressed,
    accentPrimary: AppColors.darkAccentPrimary,
    contentPlaceholder: AppColors.darkContentPlaceholder,
    contentPrimary: AppColors.darkContentPrimary,
    contentPrimary12: AppColors.darkContentPrimary12,
    contentSecondary: AppColors.darkContentSecondary,
    contentTertiary: AppColors.darkContentTertiary,
    effectHairline: AppColors.darkEffectHairline,
    notificationsErrorBg: AppColors.darkNotificationsErrorBg,
    notificationsErrorContent: AppColors.darkNotificationsErrorContent,
    notificationsInfoBg: AppColors.darkNotificationsInfoBg,
    notificationsSuccessBg: AppColors.darkNotificationsSuccessBg,
    notificationsSuccessContent: AppColors.darkNotificationsSuccessContent,
    notificationsWarningBg: AppColors.darkNotificationsWarningBg,
    notificationsWarningContent: AppColors.darkNotificationsWarningContent,
    surfaceCanvas: AppColors.darkSurfaceCanvas,
    surfaceDisabled: AppColors.darkSurfaceDisabled,
    surfaceRaised: AppColors.darkSurfaceRaised,
    surfaceRaisedHigh: AppColors.darkSurfaceRaisedHigh,
    surfaceRaisedHighest: AppColors.darkSurfaceRaisedHighest,
    surfaceRaisedHighest90: AppColors.darkSurfaceRaisedHighest90,
    statusDanger: AppColors.darkStatusDanger,
    surfaceSunken: AppColors.darkSurfaceSunken,
    surfaceSunkenMore: AppColors.darkSurfaceSunkenMore,
    surfaceWhite: AppColors.darkSurfaceWhite,
    surfaceWhite75: AppColors.darkSurfaceWhite75,
  );

  const AppColorTokens({
    required this.accentMuted,
    required this.accentPressed,
    required this.accentPrimary,
    required this.contentPlaceholder,
    required this.contentPrimary,
    required this.contentPrimary12,
    required this.contentSecondary,
    required this.contentTertiary,
    required this.effectHairline,
    required this.notificationsErrorBg,
    required this.notificationsErrorContent,
    required this.notificationsInfoBg,
    required this.notificationsSuccessBg,
    required this.notificationsSuccessContent,
    required this.notificationsWarningBg,
    required this.notificationsWarningContent,
    required this.surfaceCanvas,
    required this.surfaceDisabled,
    required this.surfaceRaised,
    required this.surfaceRaisedHigh,
    required this.surfaceRaisedHighest,
    required this.surfaceRaisedHighest90,
    required this.statusDanger,
    required this.surfaceSunken,
    required this.surfaceSunkenMore,
    required this.surfaceWhite,
    required this.surfaceWhite75,
  });

  final Color accentMuted;
  final Color accentPressed;
  final Color accentPrimary;
  final Color contentPlaceholder;
  final Color contentPrimary;
  final Color contentPrimary12;
  final Color contentSecondary;
  final Color contentTertiary;
  final Color effectHairline;
  final Color notificationsErrorBg;
  final Color notificationsErrorContent;
  final Color notificationsInfoBg;
  final Color notificationsSuccessBg;
  final Color notificationsSuccessContent;
  final Color notificationsWarningBg;
  final Color notificationsWarningContent;
  final Color surfaceCanvas;
  final Color surfaceDisabled;
  final Color surfaceRaised;
  final Color surfaceRaisedHigh;
  final Color surfaceRaisedHighest;
  final Color surfaceRaisedHighest90;
  final Color statusDanger;
  final Color surfaceSunken;
  final Color surfaceSunkenMore;
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
