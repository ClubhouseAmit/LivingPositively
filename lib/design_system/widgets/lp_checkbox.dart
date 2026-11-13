import 'package:flutter/widgets.dart';

import 'package:mazilon/design_system/tokens/color_tokens.dart';

/// Figma `check-box-base` `rounded`.
enum LpCheckboxVariant {
  /// 28 square, radius 8, thick check.
  square,

  /// 24 circle, thin check. The one Figma `List` uses.
  rounded,
}

/// The LP-DS checkbox (Figma `check-box-base`, page "Checkbox" 3:2). A box
/// only: a row with a title is the caller's (or a later `ListRow`'s) job.
///
/// Checked is [value], state rather than a variant. Figma has no disabled or
/// pressed look yet, so [onChanged] is required. [semanticLabel] is required
/// because the box alone tells a screen reader nothing.
class LpCheckbox extends StatelessWidget {
  const LpCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.variant = LpCheckboxVariant.square,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;
  final LpCheckboxVariant variant;

  // Figma measurements, owned here like LpButtonSizes.
  static const squareSize = 28.0;
  static const squareRadius = 8.0;
  static const roundedSize = 24.0;
  static const roundedRadius = 99.0;
  static const border = 1.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      enabled: true,
      label: semanticLabel,
      onTap: () => onChanged(!value),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: _box(context.colors),
      ),
    );
  }

  Widget _box(AppColorTokens colors) {
    final bool rounded = variant == LpCheckboxVariant.rounded;
    // Figma draws the idle square in content/primary but the idle circle in
    // effect/hairline.
    final Color idleBorder = rounded
        ? colors.effectHairline
        : colors.contentPrimary;
    return SizedBox.square(
      dimension: rounded ? roundedSize : squareSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: value ? colors.contentPrimary : null,
          border: value ? null : Border.all(color: idleBorder, width: border),
          borderRadius: BorderRadius.circular(
            rounded ? roundedRadius : squareRadius,
          ),
        ),
        child: value
            ? CustomPaint(
                painter: _CheckPainter(
                  color: colors.surfaceCanvas,
                  rounded: rounded,
                ),
              )
            : null,
      ),
    );
  }
}

/// The Figma check mark, as its centerline in the box's own units (the
/// Figma box is 28 or 24), scaled to the painted size.
class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color, required this.rounded});

  final Color color;
  final bool rounded;

  static const _square = [
    Offset(5.06, 14.78),
    Offset(10.5, 20.2),
    Offset(22.95, 7.78),
  ];
  static const _squareStroke = 4.56;
  static const _rounded = [
    Offset(6.29, 12.5),
    Offset(9.77, 15.98),
    Offset(17.72, 8.03),
  ];
  static const _roundedStroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final double box = rounded ? LpCheckbox.roundedSize : LpCheckbox.squareSize;
    final double scale = size.width / box;
    final List<Offset> points = rounded ? _rounded : _square;
    canvas.drawPath(
      Path()..addPolygon([for (final p in points) p * scale], false),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = (rounded ? _roundedStroke : _squareStroke) * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.color != color || old.rounded != rounded;
}
