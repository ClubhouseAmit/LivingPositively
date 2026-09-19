import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system determinate progress primitive.
///
/// Shape from Forui `FDeterminateProgress` (MIT) + DESIGN.md §3.5: a
/// `AppSpacing.xs` track in `AppColors.progressTrack` with a
/// `AppColors.primary` fill. Built on `DecoratedBox`, not Material's
/// `LinearProgressIndicator`.
///
/// [value] is 0.0–1.0.
class Progress extends StatelessWidget {
  const Progress({super.key, required this.value, this.semanticsLabel});

  final double value;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0, 1);
    return Semantics(
      label: semanticsLabel,
      value: '${(clamped * 100).round()}%',
      child: SizedBox(
        height: AppSpacing.xs,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.progressTrack,
            borderRadius: BorderRadius.circular(AppRadii.badge),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: clamped,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.badge),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
