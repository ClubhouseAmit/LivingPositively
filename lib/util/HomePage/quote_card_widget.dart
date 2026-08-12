import 'package:flutter/material.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/l10n/app_localizations.dart';

class QuoteCardWidget extends StatelessWidget {
  final String quote;
  final VoidCallback? onClose;
  final VoidCallback? onRefresh;

  const QuoteCardWidget({
    required this.quote,
    this.onClose,
    this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Close button positioned above the card on the right
          if (onClose != null)
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: AppSpacing.xs, end: AppSpacing.xs),
              child: Tooltip(
                message: AppLocalizations.of(context)!.dismissQuoteTooltip,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  onPressed: onClose,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          // Main card with quotes watermark
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              color: colorScheme.primary,
              child: Stack(
                children: [
                  // Decorative quotation mark graphic anchored to end (right in LTR, left in RTL)
                  PositionedDirectional(
                    end: 4,
                    bottom: -15,
                    child: CustomPaint(
                      size: const Size(100, 80),
                      painter: _DoubleQuotePainter(
                        color: colorScheme.onPrimary.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      80.0, // Space so text doesn't overlap heavy quote mark area completely
                      AppSpacing.lg,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (onRefresh != null)
                          Padding(
                            padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
                            child: Tooltip(
                              message: AppLocalizations.of(context)!.refreshQuoteTooltip,
                              child: IconButton(
                                icon: const Icon(Icons.autorenew),
                                iconSize: 26,
                                color: colorScheme.onPrimary,
                                onPressed: onRefresh,
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            quote,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                      ],
                    ),
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

class _DoubleQuotePainter extends CustomPainter {
  final Color color;

  _DoubleQuotePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final markWidth = size.height * 0.52;
    _drawSingleQuote(canvas, paint, Offset(0, 0), markWidth, size.height);
    _drawSingleQuote(canvas, paint, Offset(size.width * 0.48, 0), markWidth, size.height);
  }

  void _drawSingleQuote(Canvas canvas, Paint paint, Offset offset, double width, double height) {
    final path = Path();
    final cx = offset.dx + width * 0.5;
    final cy = offset.dy + height * 0.35;
    final r = width * 0.5;

    // Outer circle head + curved tail down-left
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    final tail = Path()
      ..moveTo(offset.dx + width, cy)
      ..cubicTo(
        offset.dx + width, cy + height * 0.45,
        offset.dx + width * 0.3, offset.dy + height,
        offset.dx, offset.dy + height,
      )
      ..cubicTo(
        offset.dx + width * 0.4, offset.dy + height * 0.75,
        offset.dx + width * 0.5, cy + r * 0.5,
        offset.dx + width * 0.5, cy,
      )
      ..close();

    final combined = Path.combine(PathOperation.union, path, tail);
    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(covariant _DoubleQuotePainter oldDelegate) =>
      oldDelegate.color != color;
}
