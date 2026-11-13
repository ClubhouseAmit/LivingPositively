import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';

/// The LP-DS chip (Figma `chip`, page "Chips" 4:95): a label that is on or
/// off. On/off is [pressed], state rather than a variant; Figma has one look,
/// so there is no variant enum yet.
///
/// Figma's `chip empty` (the dashed "add" pill) is an add action, not an
/// on/off control, so it is not this widget. Figma has no disabled look yet,
/// so [onPressed] is required.
class Chip extends StatelessWidget {
  const Chip({
    super.key,
    required this.label,
    required this.pressed,
    required this.onPressed,
  });

  final String label;
  final bool pressed;
  final VoidCallback onPressed;

  // Figma measurements, owned here like LpButtonSizes.
  static const height = 36.0;
  static const radius = 16.0;
  static const horizontalPadding = 14.0;
  static const border = 1.0;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens colors = context.colors;
    final Color fill = pressed ? colors.accentPrimary : colors.surfaceRaised;
    return Semantics(
      button: true,
      toggled: pressed,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        // No extra tap area beyond the visible 36: chips sit 8 apart in
        // Figma's wrapping rows, and 36 still passes WCAG 2.2 AA (24).
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(
                color: pressed ? colors.accentPrimary : colors.effectHairline,
                width: border,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                label,
                style: AppTextStyle.labelLarge,
                // Like LpButton emphasis: surface/white on accent/primary.
                color: pressed ? colors.surfaceWhite : colors.contentPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
