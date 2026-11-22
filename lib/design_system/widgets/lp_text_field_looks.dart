part of 'lp_text_field.dart';

// The colors of the box field (Figma `Input Field`) for each state, kept
// apart from the layout like LpButton's looks. Each names a Figma token;
// [AppColorTokens] already holds the current mode's values.

typedef _BoxLook = ({
  Color fill,
  Color border,
  Color label,
  Color idleLabel,
  Color value,

  /// Figma's `Marker`: content/primary, status/danger in the error look.
  Color cursor,
  Color icon,
});

/// Figma's error fill: status/danger at 5%.
const _errorFillAlpha = 0.05;

extension _LpTextFieldLooks on _LpTextFieldState {
  /// Selected text's highlight, for both fields. Figma has no selection
  /// token; accent/primary at 40% is Material's recipe with our accent.
  /// Without one, EditableText selects but paints nothing. Null while
  /// unfocused, like Material: EditableText keeps the selection on blur.
  Color? _selectionColor(AppColorTokens colors) =>
      _focus.hasFocus ? colors.accentPrimary.withValues(alpha: 0.4) : null;

  _BoxLook _boxLook(AppColorTokens colors) {
    final Color tertiary = colors.contentTertiary;
    if (!widget.enabled) {
      return (
        fill: colors.surfaceDisabled,
        border: colors.surfaceDisabled,
        label: tertiary,
        idleLabel: tertiary,
        value: tertiary,
        cursor: tertiary,
        icon: tertiary,
      );
    }
    if (widget.errorText != null) {
      final Color danger = colors.statusDanger;
      return (
        fill: danger.withValues(alpha: _errorFillAlpha),
        border: danger,
        label: danger,
        idleLabel: danger,
        value: colors.contentPrimary,
        cursor: danger,
        icon: danger,
      );
    }
    final bool focused = _focus.hasFocus;
    return (
      fill: focused ? colors.surfaceRaised : colors.surfaceSunken,
      border: focused ? colors.accentPrimary : colors.effectHairline,
      label: focused ? colors.contentPrimary : colors.contentSecondary,
      idleLabel: colors.contentPlaceholder,
      value: colors.contentPrimary,
      cursor: colors.contentPrimary,
      icon: tertiary,
    );
  }
}
