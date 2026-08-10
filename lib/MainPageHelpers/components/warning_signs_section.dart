import 'package:flutter/material.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/theme/spacing.dart';

class WarningSignsSectionWidget extends StatelessWidget {
  final List<String> signs;
  final VoidCallback onAddItem;
  final VoidCallback onSeeAll;

  const WarningSignsSectionWidget({
    required this.signs,
    required this.onAddItem,
    required this.onSeeAll,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        SectionHeaderWidget(
          title: 'My warning signs', // TODO: localize
          leadingIcon: Icons.warning_amber_outlined,
          actionIcon: Icons.add,
          onActionTap: onAddItem,
          // TODO: localize subtitle
          subtitle:
              'If a warning sign appears, activate your personal safety plan. Fill in your warning signs',
        ),
        // Horizontal scroll of cards
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              end: AppSpacing.lg,
            ),
            children: [
              // Existing sign cards
              ...signs.take(3).map((sign) => _WarningCard(text: sign)),
              // Add-new dashed card
              _AddWarningCard(
                onTap: onAddItem,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
        // See all link
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: AppSpacing.md, top: AppSpacing.xs),
            child: TextButton.icon(
              onPressed: onSeeAll,
              label: Text(
                'see all',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              icon: Icon(Icons.chevron_right, color: colorScheme.primary, size: 16),
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String text;
  const _WarningCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: CardContainer(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.bedtime_outlined,
              size: 24,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWarningCard extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  const _AddWarningCard({required this.onTap, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: CustomPaint(
          painter: _DashedRectPainter(color: colorScheme.tertiary),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.tertiary, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: colorScheme.tertiary, size: 16),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Add warning sign', // TODO: localize
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                        height: 1.4,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const radius = 16.0;
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
  bool shouldRepaint(covariant _DashedRectPainter old) => old.color != color;
}
