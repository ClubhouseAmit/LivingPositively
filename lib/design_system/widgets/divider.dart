import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system divider primitive.
///
/// Shape from Forui `FDivider` (MIT): a 1-axis coloured rule with padding.
/// Built on `ColoredBox`, not Material's `Divider`.
class Divider extends StatelessWidget {
  const Divider({
    super.key,
    this.axis = Axis.horizontal,
    this.color = AppColors.neutralLight,
  });

  final Axis axis;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool horizontal = axis == Axis.horizontal;
    return Padding(
      padding: horizontal
          ? const EdgeInsets.symmetric(vertical: AppSpacing.lg)
          : const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ColoredBox(
        color: color,
        child: SizedBox(
          height: horizontal ? AppSpacing.hairline : null,
          width: horizontal ? null : AppSpacing.hairline,
        ),
      ),
    );
  }
}
