part of 'lp_button.dart';

// The colors for each LpButton look, kept apart from the layout so the
// dark-mode work can change them in one place.

typedef _Look = ({Color? fill, Color? border, Color content});

/// True when the app theme is dark.
///
/// The one Material import in the LP buttons: dark mode is the user's own
/// setting (on, off or scheduled), applied through `MaterialApp.themeMode`,
/// so the theme is the only place that knows it. With no `Theme` above,
/// `Theme.of` falls back to light, so the buttons still render without
/// Material.
bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

extension _LpButtonLooks on LpButton {
  _Look _disabledMainLook(bool dark) {
    Color c(Color light, Color darkColor) => dark ? darkColor : light;
    if (variant == LpButtonVariant.text) {
      return (
        fill: null,
        border: null,
        content: c(AppColors.contentTertiary, AppColors.darkContentTertiary),
      );
    }
    return variant == LpButtonVariant.emphasis
        ? (
            fill: c(AppColors.accentMuted, AppColors.darkAccentMuted),
            border: null,
            content: c(AppColors.surfaceWhite75, AppColors.darkSurfaceWhite75),
          )
        : (
            fill: c(AppColors.surfaceDisabled, AppColors.darkSurfaceDisabled),
            border: null,
            content: c(
              AppColors.contentTertiary,
              AppColors.darkContentTertiary,
            ),
          );
  }

  _Look _mainLook(bool dark, bool pressed) {
    if (onPressed == null) return _disabledMainLook(dark);
    Color c(Color light, Color darkColor) => dark ? darkColor : light;
    final Color hairline = c(
      AppColors.effectHairline,
      AppColors.darkEffectHairline,
    );
    final Color content = c(
      AppColors.contentPrimary,
      AppColors.darkContentPrimary,
    );
    final bool m = size == LpButtonSize.m;

    return switch (variant) {
      // Figma draws pressed beige at 90% in size m and solid in size s.
      LpButtonVariant.primary when pressed => (
        fill: m
            ? c(
                AppColors.surfaceRaisedHighest90,
                AppColors.darkSurfaceRaisedHighest90,
              )
            : c(
                AppColors.surfaceRaisedHighest,
                AppColors.darkSurfaceRaisedHighest,
              ),
        border: hairline,
        content: content,
      ),
      LpButtonVariant.primary => (
        fill: c(AppColors.surfaceSunken, AppColors.darkSurfaceSunken),
        border: hairline,
        content: content,
      ),
      LpButtonVariant.secondary => (
        fill: pressed
            ? c(AppColors.surfaceRaised, AppColors.darkSurfaceRaised)
            : null,
        border: hairline,
        content: content,
      ),
      LpButtonVariant.emphasis => (
        fill: pressed
            ? c(AppColors.accentPressed, AppColors.darkAccentPressed)
            : c(AppColors.accentPrimary, AppColors.darkAccentPrimary),
        border: null,
        content: c(AppColors.surfaceWhite, AppColors.darkSurfaceWhite),
      ),
      LpButtonVariant.raised => (
        fill: pressed
            ? c(
                AppColors.surfaceRaisedHighest,
                AppColors.darkSurfaceRaisedHighest,
              )
            : c(AppColors.surfaceRaisedHigh, AppColors.darkSurfaceRaisedHigh),
        border: hairline,
        content: content,
      ),
      LpButtonVariant.text => (
        fill: null,
        border: null,
        content: pressed
            ? c(AppColors.contentSecondary, AppColors.darkContentSecondary)
            : content,
      ),
    };
  }

  Color? _iconFill(bool dark, bool pressed) {
    final bool rounded = iconVariant == LpIconVariant.rounded;
    if (onPressed == null) {
      return rounded
          ? (dark ? AppColors.darkSurfaceDisabled : AppColors.surfaceDisabled)
          : null;
    }
    if (rounded || (pressed && iconVariant == LpIconVariant.secondary)) {
      return dark
          ? AppColors.darkSurfaceRaisedHighest
          : AppColors.surfaceRaisedHighest;
    }
    if (pressed) {
      return dark ? AppColors.darkSurfaceSunken : AppColors.surfaceSunken;
    }
    return null;
  }

  Color _iconColor(bool dark, bool pressed) {
    if (onPressed == null) {
      return dark ? AppColors.darkContentTertiary : AppColors.contentTertiary;
    }
    if (iconVariant == LpIconVariant.primary && !pressed) {
      return dark ? AppColors.darkContentPrimary : AppColors.contentPrimary;
    }
    return dark ? AppColors.darkContentSecondary : AppColors.contentSecondary;
  }
}
