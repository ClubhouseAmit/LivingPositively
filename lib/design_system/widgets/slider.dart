import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system slider. [value] is in `[min, max]`.
class Slider extends StatelessWidget {
  const Slider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final double span = max - min;
    final double t = span == 0 ? 0 : ((value - min) / span).clamp(0, 1);
    return Semantics(
      slider: true,
      enabled: onChanged != null,
      value: '${(t * 100).round()}%',
      child: SizedBox(
        height: AppSpacing.xl,
        width: double.infinity,
        child: LayoutBuilder(builder: _trackFor),
      ),
    );
  }

  Widget _trackFor(BuildContext context, BoxConstraints constraints) {
    final double span = max - min;
    final double next = span == 0 ? 0 : ((value - min) / span).clamp(0, 1);
    return _Track(
      t: next,
      width: constraints.maxWidth,
      onChanged: onChanged,
      min: min,
      max: max,
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.t,
    required this.width,
    required this.min,
    required this.max,
    this.onChanged,
  });

  final double t;
  final double width;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  void _at(Offset local) {
    if (onChanged == null || width == 0) {
      return;
    }
    final double next = (local.dx / width).clamp(0, 1);
    onChanged!(min + next * (max - min));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _at(details.localPosition),
      onHorizontalDragUpdate: (details) => _at(details.localPosition),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          const SizedBox(
            height: AppSpacing.xs,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.progressTrack,
                borderRadius: BorderRadius.all(Radius.circular(AppRadii.badge)),
              ),
            ),
          ),
          FractionallySizedBox(
            widthFactor: t,
            child: const SizedBox(
              height: AppSpacing.xs,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppRadii.badge),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment(t * 2 - 1, 0),
            child: const SizedBox.square(
              dimension: AppSpacing.lg,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
