import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/lp_button.dart';
import 'package:mazilon/design_system/widgets/lp_pressable.dart';
import 'package:mazilon/design_system/widgets/text.dart';

/// Figma `button-text` alignment. [start] has a smaller start-side padding
/// so the label lines up with the content edge above it.
enum LpTextButtonAlignment { center, start }

/// The LP-DS text button (Figma `button-text`): a label and an optional
/// start-side icon, with no fill or border.
///
/// `onPressed: null` disables it.
class LpTextButton extends StatelessWidget {
  const LpTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.alignment = LpTextButtonAlignment.center,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LpTextButtonAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return LpPressable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: _buildFace,
    );
  }

  Widget _buildFace(BuildContext context, bool pressed) {
    final Color color = _color(lpIsDark(context), pressed);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: LpButtonSizes.textButtonHeight,
        minWidth: LpButtonSizes.textButtonMinWidth,
      ),
      child: Padding(
        padding: alignment == LpTextButtonAlignment.start
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
              child: Text(label, style: AppTextStyle.labelLarge, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Color _color(bool dark, bool pressed) {
    if (onPressed == null) {
      return dark ? AppColors.darkContentTertiary : AppColors.contentTertiary;
    }
    if (pressed) {
      return dark ? AppColors.darkContentSecondary : AppColors.contentSecondary;
    }
    return dark ? AppColors.darkContentPrimary : AppColors.contentPrimary;
  }
}
