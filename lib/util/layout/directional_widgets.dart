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

  const CardContainer({
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(borderRadius!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
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

  const SectionHeaderWidget({
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingEmoji,
    this.actionLabel,
    this.actionIcon,
    this.onActionTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                child: Row(
                  children: [
                    if (leadingEmoji != null) ...[
                      Text(leadingEmoji!, style: const TextStyle(fontSize: 20)),
                      SizedBox(width: AppSpacing.sm),
                    ] else if (leadingIcon != null) ...[
                      Icon(leadingIcon, color: colorScheme.onSurface, size: 22),
                      SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionIcon != null)
                IconButton(
                  icon: Icon(actionIcon, color: colorScheme.primary, size: 22),
                  onPressed: onActionTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
                color: colorScheme.outline,
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

  const PillItemRow({
    required this.index,
    required this.text,
    this.onEdit,
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
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(Icons.edit, size: 16, color: colorScheme.outline),
                  ),
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

  const DashedPillAddSlot({
    required this.placeholder,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            CustomPaint(
              painter: _DashedCirclePainter(color: colorScheme.tertiary),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.add, color: colorScheme.tertiary, size: 18),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: CustomPaint(
                painter: _DashedPillPainter(color: colorScheme.tertiary),
                child: Container(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  child: Text(
                    placeholder,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
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
  bool shouldRepaint(covariant _DashedCirclePainter old) => old.color != color;
}

class _DashedPillPainter extends CustomPainter {
  final Color color;
  const _DashedPillPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const radius = 24.0;
    const dashW = 7.0;
    const dashG = 5.0;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(radius),
      ));

    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dashW), paint);
        d += dashW + dashG;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPillPainter old) => old.color != color;
}
