part of 'lp_text_field.dart';

// The look of LpTextField, kept apart from its layout like LpButton's looks:
// the box field's colors per state, the value and selection styles, and the
// line field's clear button. Each color names a Figma token; [AppColorTokens]
// already holds the current mode's values.

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

/// The box field's value: Caption/Base at a fixed 16 line (Figma 15.7), so
/// label (16) + value (16) fill the 32 inside the box in every font. Left to
/// the font, Heebo's taller line grew the box from 56 to 59.
final TextStyle _valueStyle = AppTypeScale.captionBase.copyWith(
  height: 16 / 13,
);

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

  /// Figma's own size, 24, with no extra tap area, like LpCheckbox (WCAG
  /// 2.2 AA's 24px minimum).
  Widget _clearButton(AppColorTokens colors) {
    return Semantics(
      button: true,
      // Release builds skip the assert; never crash on it.
      label: widget.clearLabel ?? widget.placeholder,
      onTap: _clear,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _clear,
        child: Icon(
          widget.clearIcon,
          size: LpTextField.iconSize,
          color: colors.contentTertiary,
        ),
      ),
    );
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }
}
