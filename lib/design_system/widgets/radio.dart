import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system radio. Grouping is the caller's: pass `value == option`.
class Radio extends StatelessWidget {
  const Radio({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;
    return Semantics(
      checked: value,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      label: label,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(value: value),
            if (label != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(label!, color: AppColors.onSurface),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSpacing.xl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.neutralDark),
          color: AppColors.white,
        ),
        child: Center(
          child: SizedBox.square(
            dimension: AppSpacing.sm,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? AppColors.primary : const Color(0x00000000),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
