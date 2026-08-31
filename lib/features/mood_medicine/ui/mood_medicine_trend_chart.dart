import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_content.dart';

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
    this.activityColors = const <String, Color>{},
    this.fallbackActivityColor,
    this.highlightedActivityId,
  });

  final List<MoodMedicineTrendPoint> points;
  final String emptyLabel;
  final String semanticSummary;

  /// Activity colour cues keyed by stable activity ID.
  ///
  /// The visible activity-label chips and [semanticSummary] remain the
  /// non-colour representation. IDs not present in this map use the themed
  /// fallback colour, which keeps custom activities visible.
  final Map<String, Color> activityColors;

  /// Theme-aware fallback for custom activities. When omitted, the active
  /// theme's tertiary colour is used.
  final Color? fallbackActivityColor;
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
    final Color resolvedFallback =
        fallbackActivityColor ?? colorScheme.tertiary;
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
              fallbackActivityColor: resolvedFallback,
              pointCenterColor: colorScheme.surface,
              activityColors: activityColors,
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
    required this.fallbackActivityColor,
    required this.pointCenterColor,
    required this.activityColors,
    required this.highlightedActivityId,
  });

  final List<MoodMedicineTrendPoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color fallbackActivityColor;
  final Color pointCenterColor;
  final Map<String, Color> activityColors;
  final String? highlightedActivityId;

  @override
  void paint(Canvas canvas, Size size) {
    const EdgeInsets padding = EdgeInsets.fromLTRB(12, 12, 12, 8);
    const double activityBandHeight = 44;
    final Rect available = padding.deflateRect(Offset.zero & size);
    final Rect moodChart = Rect.fromLTRB(
      available.left,
      available.top,
      available.right,
      available.bottom - activityBandHeight,
    );
    if (moodChart.width <= 0 || moodChart.height <= 0 || points.isEmpty) {
      return;
    }

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index < 5; index++) {
      final double y = moodChart.top + moodChart.height * index / 4;
      canvas.drawLine(
        Offset(moodChart.left, y),
        Offset(moodChart.right, y),
        gridPaint,
      );
    }

    double xCoordinateForPointIndex(int index) {
      if (points.length == 1) {
        return moodChart.center.dx;
      }
      return moodChart.left + moodChart.width * index / (points.length - 1);
    }

    double yCoordinateForMoodValue(double value) {
      final double normalised = ((value.clamp(1, 5) - 1) / 4).toDouble();
      return moodChart.bottom - moodChart.height * normalised;
    }

    _paintActivityBand(
      canvas,
      activityIds: _orderedActivityIds(),
      left: moodChart.left,
      right: moodChart.right,
      top: moodChart.bottom + 8,
      height: activityBandHeight - 8,
      xCoordinateForPointIndex: xCoordinateForPointIndex,
    );

    final Path linePath = Path();
    for (var index = 0; index < points.length; index++) {
      final Offset point = Offset(
        xCoordinateForPointIndex(index),
        yCoordinateForMoodValue(points[index].mood),
      );
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
      final MoodMedicineTrendPoint item = points[index];
      final bool isHighlighted =
          highlightedActivityId != null &&
          item.activityIds.contains(highlightedActivityId);
      final Offset point = Offset(
        xCoordinateForPointIndex(index),
        yCoordinateForMoodValue(item.mood),
      );
      final Color highlightedColor = highlightedActivityId == null
          ? fallbackActivityColor
          : MoodMedicineContent.resolveActivityColor(
              highlightedActivityId!,
              palette: activityColors,
              fallback: fallbackActivityColor,
            );
      canvas.drawCircle(
        point,
        isHighlighted ? 7 : 5,
        Paint()..color = isHighlighted ? highlightedColor : lineColor,
      );
      canvas.drawCircle(
        point,
        math.max(1, isHighlighted ? 3 : 2),
        Paint()..color = pointCenterColor,
      );
    }
  }

  List<String> _orderedActivityIds() {
    final Set<String> presentIds = points
        .expand((MoodMedicineTrendPoint point) => point.activityIds)
        .toSet();
    final List<String> customIds =
        presentIds
            .where((String id) => !activityColors.containsKey(id))
            .toList()
          ..sort();
    return <String>[
      ...activityColors.keys.where(presentIds.contains),
      ...customIds,
    ];
  }

  void _paintActivityBand(
    Canvas canvas, {
    required List<String> activityIds,
    required double left,
    required double right,
    required double top,
    required double height,
    required double Function(int index) xCoordinateForPointIndex,
  }) {
    if (activityIds.isEmpty || height <= 0) {
      return;
    }
    var gap = 1.0;
    var laneHeight =
        (height - gap * (activityIds.length - 1)) / activityIds.length;
    if (laneHeight < 1) {
      gap = 0;
      laneHeight = height / activityIds.length;
    }
    final double pointSpacing = points.length < 2
        ? 8
        : (right - left) / (points.length - 1);
    final double markerWidth = math.min(8, math.max(1, pointSpacing * 0.7));
    for (var pointIndex = 0; pointIndex < points.length; pointIndex++) {
      final MoodMedicineTrendPoint point = points[pointIndex];
      for (var laneIndex = 0; laneIndex < activityIds.length; laneIndex++) {
        final String activityId = activityIds[laneIndex];
        if (!point.activityIds.contains(activityId)) {
          continue;
        }
        final bool isDimmed =
            highlightedActivityId != null &&
            highlightedActivityId != activityId;
        final Color color = MoodMedicineContent.resolveActivityColor(
          activityId,
          palette: activityColors,
          fallback: fallbackActivityColor,
        ).withValues(alpha: isDimmed ? 0.45 : 1);
        final double y = top + laneIndex * (laneHeight + gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(
                xCoordinateForPointIndex(pointIndex),
                y + laneHeight / 2,
              ),
              width: markerWidth,
              height: laneHeight,
            ),
            const Radius.circular(1),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MoodMedicineTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.fallbackActivityColor != fallbackActivityColor ||
        oldDelegate.pointCenterColor != pointCenterColor ||
        oldDelegate.activityColors != activityColors ||
        oldDelegate.highlightedActivityId != highlightedActivityId;
  }
}
