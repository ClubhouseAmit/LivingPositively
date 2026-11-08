part of 'lp_button.dart';

// The colors for each LpButton look, kept apart from the layout. Each look
// names Figma tokens; [AppColorTokens] already holds the current mode's
// values, so nothing here knows whether the app is light or dark.

typedef _Look = ({Color? fill, Color? border, Color content});

extension _LpButtonLooks on LpButton {
  _Look _disabledMainLook(AppColorTokens colors) {
    if (variant == LpButtonVariant.text) {
      return (fill: null, border: null, content: colors.contentTertiary);
    }
    return variant == LpButtonVariant.emphasis
        ? (
            fill: colors.accentMuted,
            border: null,
            content: colors.surfaceWhite75,
          )
        : (
            fill: colors.surfaceDisabled,
            border: null,
            content: colors.contentTertiary,
          );
  }

  _Look _mainLook(AppColorTokens colors, bool pressed) {
    if (onPressed == null) return _disabledMainLook(colors);
    final Color hairline = colors.effectHairline;
    final Color content = colors.contentPrimary;
    final bool m = size == LpButtonSize.m;

    return switch (variant) {
      // Figma draws pressed beige at 90% in size m and solid in size s.
      LpButtonVariant.primary when pressed => (
        fill: m ? colors.surfaceRaisedHighest90 : colors.surfaceRaisedHighest,
        border: hairline,
        content: content,
      ),
      LpButtonVariant.primary => (
        fill: colors.surfaceSunken,
        border: hairline,
        content: content,
      ),
      LpButtonVariant.secondary => (
        fill: pressed ? colors.surfaceRaised : null,
        border: hairline,
        content: content,
      ),
      // Figma's label here is surface/white in both modes, not
      // content/on-accent (checked against the dark app screens).
      LpButtonVariant.emphasis => (
        fill: pressed ? colors.accentPressed : colors.accentPrimary,
        border: null,
        content: colors.surfaceWhite,
      ),
      LpButtonVariant.raised => (
        fill: pressed ? colors.surfaceRaisedHighest : colors.surfaceRaisedHigh,
        border: hairline,
        content: content,
      ),
      LpButtonVariant.text => (
        fill: null,
        border: null,
        content: pressed ? colors.contentSecondary : content,
      ),
    };
  }

  Color? _iconFill(AppColorTokens colors, bool pressed) {
    final bool rounded = iconVariant == LpIconVariant.rounded;
    if (onPressed == null) return rounded ? colors.surfaceDisabled : null;
    if (rounded || (pressed && iconVariant == LpIconVariant.secondary)) {
      return colors.surfaceRaisedHighest;
    }
    return pressed ? colors.surfaceSunken : null;
  }

  Color _iconColor(AppColorTokens colors, bool pressed) {
    if (onPressed == null) return colors.contentTertiary;
    if (iconVariant == LpIconVariant.primary && !pressed) {
      return colors.contentPrimary;
    }
    return colors.contentSecondary;
  }
}
