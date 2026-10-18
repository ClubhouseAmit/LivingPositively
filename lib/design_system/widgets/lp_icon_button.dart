import 'package:flutter/widgets.dart';

import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/lp_button.dart';
import 'package:mazilon/design_system/widgets/lp_pressable.dart';

/// Figma `Button-icon` types.
enum LpIconButtonType {
  /// No fill, primary-color icon.
  primary,

  /// No fill, secondary-color icon.
  secondary,

  /// Filled circle. Figma draws it in sizes xs and s only.
  rounded,
}

enum LpIconButtonSize { xs, s, m }

/// The LP-DS icon-only button (Figma `Button-icon`).
///
/// [semanticLabel] is required: an icon alone tells a screen reader nothing.
/// `onPressed: null` disables it.
class LpIconButton extends StatelessWidget {
  const LpIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.type = LpIconButtonType.primary,
    this.size = LpIconButtonSize.s,
  }) : assert(
         type != LpIconButtonType.rounded || size != LpIconButtonSize.m,
         'Figma has no rounded icon button in size m',
       );

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final LpIconButtonType type;
  final LpIconButtonSize size;

  @override
  Widget build(BuildContext context) {
    return LpPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: _buildFace,
    );
  }

  Widget _buildFace(BuildContext context, bool pressed) {
    final bool dark = lpIsDark(context);
    final (double box, double iconSize) = switch (size) {
      LpIconButtonSize.xs => (
        LpButtonSizes.iconButtonXs,
        LpButtonSizes.iconButtonIconXs,
      ),
      LpIconButtonSize.s => (
        LpButtonSizes.iconButtonS,
        LpButtonSizes.iconButtonIconS,
      ),
      LpIconButtonSize.m => (
        LpButtonSizes.iconButtonM,
        LpButtonSizes.iconButtonIconM,
      ),
    };
    final bool rounded = type == LpIconButtonType.rounded;
    return SizedBox.square(
      dimension: box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _fill(dark, pressed),
          borderRadius: BorderRadius.circular(
            pressed && !rounded
                ? LpButtonSizes.iconButtonPressedRadius
                : LpButtonSizes.iconButtonRadius,
          ),
        ),
        child: Center(
          child: Icon(icon, size: iconSize, color: _iconColor(dark, pressed)),
        ),
      ),
    );
  }

  Color? _fill(bool dark, bool pressed) {
    final bool rounded = type == LpIconButtonType.rounded;
    if (onPressed == null) {
      return rounded
          ? (dark ? AppColors.darkSurfaceDisabled : AppColors.surfaceDisabled)
          : null;
    }
    if (rounded || (pressed && type == LpIconButtonType.secondary)) {
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
    if (type == LpIconButtonType.primary && !pressed) {
      return dark ? AppColors.darkContentPrimary : AppColors.contentPrimary;
    }
    return dark ? AppColors.darkContentSecondary : AppColors.contentSecondary;
  }
}
