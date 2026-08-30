import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One check-in used only to render the Mood Medicine trend.
///
/// The storage layer intentionally owns the full check-in record. This small
/// view model keeps chart rendering independent from persistence details.
class MoodMedicineTrendPoint {
  const MoodMedicineTrendPoint({
    required this.label,
    required this.mood,
    this.activityIds = const <String>{},
  });

  final String label;
  final double mood;
  final Set<String> activityIds;
}

/// Responsive, dependency-free mood trend visualization.
///
/// It deliberately handles no data and one data point without attempting a
/// line interpolation, which is the common state for a new check-in.
class MoodMedicineTrendChart extends StatelessWidget {
  const MoodMedicineTrendChart({
    super.key,
    required this.points,
    required this.emptyLabel,
    required this.semanticSummary,
    this.highlightedActivityId,
  });

  final List<MoodMedicineTrendPoint> points;
  final String emptyLabel;
  final String semanticSummary;
  final String? highlightedActivityId;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Semantics(
        label: emptyLabel,
        child: ExcludeSemantics(
          child: SizedBox(
            height: 190,
            child: Center(
              child: Text(
                emptyLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticSummary,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 190,
          width: double.infinity,
          child: CustomPaint(
            painter: _MoodMedicineTrendPainter(
              points: points,
              lineColor: colorScheme.primary,
              gridColor: colorScheme.outline.withValues(alpha: 0.25),
              overlayColor: colorScheme.tertiary,
              pointCenterColor: colorScheme.surface,
              highlightedActivityId: highlightedActivityId,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodMedicineTrendPainter extends CustomPainter {
  const _MoodMedicineTrendPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.overlayColor,
    required this.pointCenterColor,
    required this.highlightedActivityId,
  });

  final List<MoodMedicineTrendPoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color overlayColor;
  final Color pointCenterColor;
  final String? highlightedActivityId;

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.fromLTRB(12, 12, 12, 18);
    final chart = padding.deflateRect(Offset.zero & size);
    if (chart.width <= 0 || chart.height <= 0 || points.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index < 5; index++) {
      final y = chart.top + chart.height * index / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    double xFor(int index) {
      if (points.length == 1) {
        return chart.center.dx;
      }
      return chart.left + chart.width * index / (points.length - 1);
    }

    double yFor(double value) {
      final normalised = ((value.clamp(1, 5) - 1) / 4).toDouble();
      return chart.bottom - chart.height * normalised;
    }

    final linePath = Path();
    for (var index = 0; index < points.length; index++) {
      final point = Offset(xFor(index), yFor(points[index].mood));
      if (index == 0) {
        linePath.moveTo(point.dx, point.dy);
      } else {
        linePath.lineTo(point.dx, point.dy);
      }
    }
    if (points.length > 1) {
      canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    for (var index = 0; index < points.length; index++) {
      final item = points[index];
      final isHighlighted =
          highlightedActivityId != null &&
          item.activityIds.contains(highlightedActivityId);
      final point = Offset(xFor(index), yFor(item.mood));
      canvas.drawCircle(
        point,
        isHighlighted ? 7 : 5,
        Paint()..color = isHighlighted ? overlayColor : lineColor,
      );
      canvas.drawCircle(
        point,
        math.max(1, isHighlighted ? 3 : 2),
        Paint()..color = pointCenterColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoodMedicineTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.pointCenterColor != pointCenterColor ||
        oldDelegate.highlightedActivityId != highlightedActivityId;
  }
}
