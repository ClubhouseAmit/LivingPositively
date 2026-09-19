import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system form-label primitive.
///
/// Shape from Forui `FLabel` vertical layout (MIT) + DESIGN.md §3.4:
/// label above the field, optional description below. Built on `Column`,
/// not Material's `InputDecorator`.
class Label extends StatelessWidget {
  const Label({
    super.key,
    required this.label,
    required this.child,
    this.description,
  });

  final String label;
  final Widget child;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.titleSmall,
            color: AppColors.onSurface,
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description!,
              style: AppTextStyle.bodySmall,
              color: AppColors.onSurface,
            ),
          ],
        ],
      ),
    );
  }
}
