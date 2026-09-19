import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/card.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Which semantic role this alert represents.
enum AlertVariant {
  /// Soft primary tint — Forui `FAlert` primary.
  primary,

  /// Soft error tint — Forui `FAlert` destructive.
  destructive,
}

/// Design-system alert primitive.
///
/// Shape from Forui `FAlert` (MIT): a titled banner with an optional
/// subtitle. Built on `Card`, not Material's `Banner`/`AlertDialog`.
class Alert extends StatelessWidget {
  const Alert({
    super.key,
    required this.title,
    this.subtitle,
    this.variant = AlertVariant.primary,
  });

  final String title;
  final String? subtitle;
  final AlertVariant variant;

  @override
  Widget build(BuildContext context) {
    final (
      Color background,
      Color foreground,
      Color accent,
    ) = switch (variant) {
      AlertVariant.primary => (
        AppColors.secondary,
        AppColors.onSurface,
        AppColors.primary,
      ),
      AlertVariant.destructive => (
        AppColors.error.withValues(alpha: 0.12),
        AppColors.error,
        AppColors.error,
      ),
    };

    return Semantics(
      liveRegion: variant == AlertVariant.destructive,
      child: Card(
        color: background,
        border: BorderDirectional(
          start: BorderSide(color: accent, width: AppSpacing.xs),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: _SeverityMark(color: accent)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.titleLarge,
                    color: foreground,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: AppTextStyle.bodyLarge,
                      color: foreground,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color mark next to the title — not color-alone; the title is the name.
class _SeverityMark extends StatelessWidget {
  const _SeverityMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSpacing.md,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
