import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system checkbox. `onChanged: null` disables it.
class Checkbox extends StatelessWidget {
  const Checkbox({
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
      label: label,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Box(value: value),
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

class _Box extends StatelessWidget {
  const _Box({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSpacing.xl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          border: value ? null : Border.all(color: AppColors.neutralDark),
        ),
        child: value
            ? const Center(
                child: Text(
                  '✓',
                  style: AppTextStyle.labelSmall,
                  color: AppColors.onPrimary,
                  textAlign: TextAlign.center,
                ),
              )
            : null,
      ),
    );
  }
}
