import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system avatar primitive.
///
/// Shape from Forui `FAvatar` (MIT): a clipped circle with initials or a
/// child. Built on `DecoratedBox`/`ClipOval`, not Material's `CircleAvatar`.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.initials, this.child});

  /// Fallback letters when [child] is omitted.
  final String? initials;

  /// Typically an image. Wins over [initials] when both are set.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Widget face =
        child ??
        (initials != null && initials!.isNotEmpty
            ? Text(
                initials!,
                style: AppTextStyle.labelLarge,
                color: AppColors.onSurface,
                textAlign: TextAlign.center,
              )
            : const _FallbackMark());

    return SizedBox.square(
      dimension: AppSpacing.xxxl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: ClipOval(child: Center(child: face)),
      ),
    );
  }
}

/// Geometric stand-in when there is no photo and no initials.
class _FallbackMark extends StatelessWidget {
  const _FallbackMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSpacing.lg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.onSurface.withValues(alpha: 0.24),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
