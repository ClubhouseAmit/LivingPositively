import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Design-system switch. Built on `DecoratedBox`, not `CupertinoSwitch`.
class Switch extends StatelessWidget {
  const Switch({
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
      toggled: value,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Track(value: value),
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

class _Track extends StatelessWidget {
  const _Track({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.xxxl + AppSpacing.lg,
      height: AppSpacing.xl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.neutralLight,
          borderRadius: BorderRadius.circular(AppRadii.badge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 100),
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: const SizedBox.square(
              dimension: AppSpacing.md,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
