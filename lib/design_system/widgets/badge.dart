import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Which semantic role this badge represents.
enum BadgeVariant {
  /// `AppColors.primary` fill — Forui `FBadge` primary.
  primary,

  /// `AppColors.secondary` fill — Forui `FBadge` secondary.
  secondary,

  /// Hairline border, no fill — Forui `FBadge` outline.
  outline,

  /// `AppColors.error` fill — Forui `FBadge` destructive.
  destructive,
}

/// Design-system badge primitive.
///
/// Shape from Forui `FBadge` (MIT): a pill `DecoratedBox` around a label.
/// Built on `widgets.dart`, not Material's `Chip`.
class Badge extends StatelessWidget {
  const Badge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.primary,
  });

  final String label;
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    // Soft tint + dark same-hue text — white-on-saturated fails AA at
    // labelSmall (10px). See DESIGN.md muted/secondary fills.
    final (
      Color background,
      Color foreground,
      Color? border,
    ) = switch (variant) {
      BadgeVariant.primary => (
        AppColors.secondary,
        AppColors.onSurface,
        null,
      ),
      BadgeVariant.secondary => (
        AppColors.neutralLight,
        AppColors.onSurface,
        null,
      ),
      BadgeVariant.outline => (
        AppColors.white,
        AppColors.onSurface,
        AppColors.neutralLight,
      ),
      BadgeVariant.destructive => (
        AppColors.error.withValues(alpha: 0.12),
        AppColors.error,
        null,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.badge),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: AppTextStyle.labelSmall,
          color: foreground,
        ),
      ),
    );
  }
}
