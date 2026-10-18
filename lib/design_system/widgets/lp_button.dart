import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/lp_pressable.dart';
import 'package:mazilon/design_system/widgets/text.dart';

/// Button measurements from the LP-DS Figma file, page "Buttons" (70:2383).
///
/// Owned here rather than borrowed from `AppRadii`/`AppSpacing` values that
/// happen to match: a badge or spacing change must not reshape the buttons.
/// Padding and gaps do use `AppSpacing`, since those are the shared scale.
abstract class LpButtonSizes {
  /// Figma radius 99: a full pill at any button height.
  static const pillRadius = 99.0;
  static const border = 1.0;

  // -- LpButton --
  static const heightM = 48.0;
  static const heightS = 32.0;
  static const minWidthM = 72.0;
  static const minWidthS = 48.0;
  static const iconM = 22.0;
  static const iconS = 18.0;

  // -- LpIconButton --
  static const iconButtonXs = 24.0;
  static const iconButtonS = 32.0;
  static const iconButtonM = 48.0;
  static const iconButtonIconXs = 16.0;
  static const iconButtonIconS = 24.0;
  static const iconButtonIconM = 40.0;
  static const iconButtonRadius = 20.0;
  static const iconButtonPressedRadius = 8.0;

  // -- LpTextButton --
  static const textButtonHeight = 32.0;
  static const textButtonMinWidth = 48.0;
  static const textButtonIcon = 16.0;
}

/// Figma `Button-primary`: `type` primary/secondary plus the `purple` and
/// `White` switches, flattened into one choice.
enum LpButtonVariant {
  /// Beige fill with a hairline border.
  primary,

  /// Hairline border, no fill.
  secondary,

  /// Accent fill, white label.
  purple,

  /// Raised-high fill (white in light mode) with a hairline border.
  white,
}

enum LpButtonSize { m, s }

typedef _Look = ({Color? fill, Color? border, Color content});

/// The LP-DS main button (Figma `Button-primary`, labelled "button-main").
///
/// A pill with a label and an optional icon at the start side. Full width
/// by default, like `Button`; set [fullWidth] to false to size it to its
/// content (with Figma's minimum width).
///
/// `onPressed: null` disables it.
class LpButton extends StatelessWidget {
  const LpButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = LpButtonVariant.primary,
    this.size = LpButtonSize.m,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final LpButtonVariant variant;
  final LpButtonSize size;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return LpPressable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: _buildFace,
    );
  }

  Widget _buildFace(BuildContext context, bool pressed) {
    final bool m = size == LpButtonSize.m;
    final _Look look = _look(lpIsDark(context), pressed);
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
            child: _content(m, look.content),
          ),
        ),
      ),
    );
    if (fullWidth) face = SizedBox(width: double.infinity, child: face);
    return face;
  }

  Widget _content(bool m, Color color) {
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
            label,
            style: m ? AppTextStyle.labelLarge : AppTextStyle.bodySmall,
            color: color,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  _Look _disabledLook(bool dark) {
    Color c(Color light, Color darkColor) => dark ? darkColor : light;
    return variant == LpButtonVariant.purple
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

  _Look _look(bool dark, bool pressed) {
    if (onPressed == null) return _disabledLook(dark);
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
      LpButtonVariant.purple => (
        fill: pressed
            ? c(AppColors.accentPressed, AppColors.darkAccentPressed)
            : c(AppColors.accentPrimary, AppColors.darkAccentPrimary),
        border: null,
        content: c(AppColors.surfaceWhite, AppColors.darkSurfaceWhite),
      ),
      LpButtonVariant.white => (
        fill: pressed
            ? c(
                AppColors.surfaceRaisedHighest,
                AppColors.darkSurfaceRaisedHighest,
              )
            : c(AppColors.surfaceRaisedHigh, AppColors.darkSurfaceRaisedHigh),
        border: hairline,
        content: content,
      ),
    };
  }
}
