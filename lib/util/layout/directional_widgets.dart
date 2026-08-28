import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mazilon/util/theme/spacing.dart';

/// Reusable card container with proper RTL support and Material Design styling
class CardContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool hasShadow;

  const CardContainer({
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 16,
    this.hasShadow = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? Colors.white;
    final bgIsLight =
        ThemeData.estimateBrightnessForColor(effectiveBg) == Brightness.light;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    Widget cardChild = child;
    if (bgIsLight && isDark) {
      cardChild = Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.apply(
            bodyColor: const Color(0xFF1A1A1A),
            displayColor: const Color(0xFF1A1A1A),
          ),
          colorScheme: theme.colorScheme.copyWith(
            onSurface: const Color(0xFF1A1A1A),
            outline: const Color(0xFF757575),
          ),
        ),
        child: child,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(borderRadius!),
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: cardChild,
      ),
    );
  }
}

/// Section header: title + icon + subtitle + optional action button or icon
/// RTL-safe: uses EdgeInsetsDirectional for all padding
class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final String? leadingEmoji;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;
  final Widget? actionWidget;

  /// Optional callback invoked when the section title or leading icon/emoji is tapped.
  /// When provided, the full title content row is made clickable with button semantics.
  final VoidCallback? onTitleTap;

  /// Optional key assigned to the interactive title hit target when [onTitleTap] is provided.
  final Key? titleKey;

  const SectionHeaderWidget({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingEmoji,
    this.actionLabel,
    this.actionIcon,
    this.onActionTap,
    this.actionWidget,
    this.onTitleTap,
    this.titleKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget titleContent = Row(
      children: [
        if (leadingEmoji != null) ...[
          Text(leadingEmoji!, style: const TextStyle(fontSize: 20)),
          SizedBox(width: AppSpacing.sm),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, color: colorScheme.onSurface, size: 22),
          SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );

    if (onTitleTap != null) {
      titleContent = Semantics(
        button: true,
        label: title,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: titleKey ?? const Key('sectionHeaderTitleTapTarget'),
            behavior: HitTestBehavior.opaque,
            onTap: onTitleTap,
            child: SizedBox(
              width: double.infinity,
              child: titleContent,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: titleContent,
              ),
              if (actionWidget != null)
                actionWidget!
              else if (actionIcon != null)
                IconButton(
                  icon: Icon(
                    actionIcon,
                    color: colorScheme.onSurface,
                    size: 22,
                  ),
                  onPressed: onActionTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                )
              else if (actionLabel != null)
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.start,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pill-shaped item row for traits and gratitude sections.
/// Numbered purple circle on left, white pill card with text and pencil icon on right.
class PillItemRow extends StatelessWidget {
  final int index;
  final String text;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const PillItemRow({
    required this.index,
    required this.text,
    this.onEdit,
    this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A),
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Color(0xFF757575),
                    ),
                  ),
                  if (onRemove != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed pill border add-slot used in traits and gratitude sections.
/// Dashed green + circle on left, dashed green pill container on right.
class DashedPillAddSlot extends StatelessWidget {
  final String placeholder;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  const DashedPillAddSlot({
    required this.placeholder,
    this.onTap,
    this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: CustomPaint(
              painter: _DashedCirclePainter(
                color: colorScheme.tertiary,
                strokeWidth: 1,
              ),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.add, color: colorScheme.tertiary, size: 18),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: CustomPaint(
              painter: DashedRoundedBorderPainter(
                color: colorScheme.tertiary,
                radius: 24,
                strokeWidth: 1,
              ),
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTap,
                        child: Text(
                          placeholder,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.outline),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                    if (onRefresh != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onRefresh,
                        child: Icon(
                          Icons.refresh,
                          size: 16,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _DashedCirclePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 2) / 2;
    const dashW = 5.0;
    const dashG = 3.5;
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dashW + dashG)).floor();
    final sweepAngle = (dashW / circumference) * 2 * math.pi;
    final gapAngle = (dashG / circumference) * 2 * math.pi;

    var startAngle = 0.0;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Paints the shared rounded dashed border used by add affordances.
///
/// [color], [radius], and [strokeWidth] keep each caller's visual variant
/// explicit while preserving the common dash geometry.
class DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashW = 7.0;
    const dashG = 5.0;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dashW), paint);
        d += dashW + dashG;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
