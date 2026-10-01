import 'package:flutter/material.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Compact reminder switch using the app's theme colors.
class ReminderSwitch extends StatelessWidget {
  const ReminderSwitch({
    required this.value,
    required this.label,
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final bool value;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      toggled: value,
      enabled: onPressed != null,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 55,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.badge),
            gradient: value
                ? LinearGradient(colors: [colors.primary, colors.secondary])
                : null,
            color: value ? null : colors.surfaceContainerHighest,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.hairline + AppSpacing.hairline,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
