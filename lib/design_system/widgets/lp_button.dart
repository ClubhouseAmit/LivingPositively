import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/button_sizes.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';

part 'lp_button_looks.dart';

/// Figma `Button-primary`: `type` primary/secondary plus the `purple` and
/// `White` switches, flattened into one choice named by role.
enum LpButtonVariant {
  /// Beige fill with a hairline border.
  primary,

  /// Hairline border, no fill.
  secondary,

  /// Accent (purple) fill, white label.
  emphasis,

  /// Raised-high fill (white in light mode) with a hairline border.
  raised,

  /// Figma `button-text`: a label and an optional icon, no fill or border.
  /// Always hugs its content and has one size, so it ignores [LpButton.size]
  /// and [LpButton.fullWidth].
  text,
}

enum LpButtonSize { m, s }

/// Figma `Button-icon` types.
enum LpIconVariant {
  /// No fill, primary-color icon.
  primary,

  /// No fill, secondary-color icon.
  secondary,

  /// Filled circle. Figma draws it in sizes xs and s only.
  rounded,
}

enum LpIconSize { xs, s, m }

/// [LpButtonVariant.text] alignment. [start] has a smaller start-side
/// padding so the label lines up with the content edge above it.
enum LpTextAlignment { center, start }

enum _Family { main, icon }

/// The LP-DS button. One widget for the Figma button components:
///
/// - `LpButton(...)`: `Button-primary`, a pill with a label and an optional
///   start-side icon, full width by default like `Button`; and, with
///   [LpButtonVariant.text], `button-text`.
/// - `LpButton.icon(...)`: `Button-icon`, icon only. [semanticLabel] is
///   required: an icon alone tells a screen reader nothing.
///
/// `onPressed: null` disables it.
class LpButton extends StatefulWidget {
  const LpButton({
    super.key,
    required String this.label,
    required this.onPressed,
    this.variant = LpButtonVariant.primary,
    this.size = LpButtonSize.m,
    this.icon,
    this.fullWidth = true,
    this.alignment = LpTextAlignment.center,
  }) : assert(
         alignment == LpTextAlignment.center || variant == LpButtonVariant.text,
         'alignment applies to the text variant only',
       ),
       _family = _Family.main,
       semanticLabel = null,
       iconVariant = LpIconVariant.primary,
       iconSize = LpIconSize.s;

  const LpButton.icon({
    super.key,
    required IconData this.icon,
    required String this.semanticLabel,
    required this.onPressed,
    LpIconVariant variant = LpIconVariant.primary,
    LpIconSize size = LpIconSize.s,
  }) : assert(
         variant != LpIconVariant.rounded || size != LpIconSize.m,
         'Figma has no rounded icon button in size m',
       ),
       _family = _Family.icon,
       label = null,
       iconVariant = variant,
       iconSize = size,
       variant = LpButtonVariant.primary,
       size = LpButtonSize.m,
       fullWidth = false,
       alignment = LpTextAlignment.center;

  final _Family _family;

  /// The visible text. Null only for [LpButton.icon].
  final String? label;

  /// What a screen reader announces for [LpButton.icon].
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LpButtonVariant variant;
  final LpButtonSize size;
  final LpIconVariant iconVariant;
  final LpIconSize iconSize;
  final LpTextAlignment alignment;
  final bool fullWidth;

  @override
  State<LpButton> createState() => _LpButtonState();

  Widget _face(BuildContext context, bool pressed) => switch (_family) {
    _Family.main when variant == LpButtonVariant.text => _buildTextFace(
      context,
      pressed,
    ),
    _Family.main => _buildMainFace(context, pressed),
    _Family.icon => _buildIconFace(context, pressed),
  };

  // -- LpButton --

  Widget _buildMainFace(BuildContext context, bool pressed) {
    final bool m = size == LpButtonSize.m;
    final _Look look = _mainLook(context.colors, pressed);
    Widget face = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: m ? LpButtonSizes.heightM : LpButtonSizes.heightS,
        minWidth: m ? LpButtonSizes.minWidthM : LpButtonSizes.minWidthS,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: look.fill,
          border: look.border == null
              ? null
              : Border.all(color: look.border!, width: LpButtonSizes.border),
          borderRadius: BorderRadius.circular(LpButtonSizes.pillRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: _mainContent(m, look.content),
          ),
        ),
      ),
    );
    if (fullWidth) face = SizedBox(width: double.infinity, child: face);
    return face;
  }

  Widget _mainContent(bool m, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: m ? LpButtonSizes.iconM : LpButtonSizes.iconS,
            color: color,
          ),
          SizedBox(width: m ? AppSpacing.sm : AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            label!,
            style: m ? AppTextStyle.labelLarge : AppTextStyle.bodySmall,
            color: color,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // -- LpButton.icon --

  Widget _buildIconFace(BuildContext context, bool pressed) {
    final AppColorTokens colors = context.colors;
    final (double box, double glyph) = switch (iconSize) {
      LpIconSize.xs => (
        LpButtonSizes.iconButtonXs,
        LpButtonSizes.iconButtonIconXs,
      ),
      LpIconSize.s => (
        LpButtonSizes.iconButtonS,
        LpButtonSizes.iconButtonIconS,
      ),
      LpIconSize.m => (
        LpButtonSizes.iconButtonM,
        LpButtonSizes.iconButtonIconM,
      ),
    };
    final bool rounded = iconVariant == LpIconVariant.rounded;
    return SizedBox.square(
      dimension: box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _iconFill(colors, pressed),
          borderRadius: BorderRadius.circular(
            pressed && !rounded
                ? LpButtonSizes.iconButtonPressedRadius
                : LpButtonSizes.iconButtonRadius,
          ),
        ),
        child: Center(
          child: Icon(icon, size: glyph, color: _iconColor(colors, pressed)),
        ),
      ),
    );
  }

  // -- LpButtonVariant.text --

  Widget _buildTextFace(BuildContext context, bool pressed) {
    final Color color = _mainLook(context.colors, pressed).content;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: LpButtonSizes.textButtonHeight,
        minWidth: LpButtonSizes.textButtonMinWidth,
      ),
      child: Padding(
        padding: alignment == LpTextAlignment.start
            ? const EdgeInsetsDirectional.only(
                start: AppSpacing.xs,
                end: AppSpacing.sm,
              )
            : const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              // Matches the label: Figma's old icon style has no token.
              Icon(icon, size: LpButtonSizes.textButtonIcon, color: color),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(label!, style: AppTextStyle.labelLarge, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tap, pressed state, semantics and the minimum tap area, shared by both
/// constructors. The tap area is at least
/// [LpButtonSizes.minTapTarget] square even when the visible button is
/// smaller (Figma sizes s and xs), with the visible part centered.
class _LpButtonState extends State<LpButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  void _onTapDown(TapDownDetails _) => _setPressed(true);

  void _onTapUp(TapUpDetails _) => _setPressed(false);

  void _onTapCancel() => _setPressed(false);

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      // Replaces the visible text, so the label is not read twice.
      label: widget.label ?? widget.semanticLabel,
      // excludeSemantics hides the GestureDetector's tap, so re-expose it.
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: LpButtonSizes.minTapTarget,
            minHeight: LpButtonSizes.minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: widget._face(context, enabled && _pressed),
          ),
        ),
      ),
    );
  }
}
