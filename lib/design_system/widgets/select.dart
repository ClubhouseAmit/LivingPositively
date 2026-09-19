import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/popover.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// String select. Opens [Popover] with [options].
class Select extends StatelessWidget {
  const Select({
    super.key,
    required this.options,
    this.value,
    this.placeholder = 'Select',
    this.onChanged,
  });

  final List<String> options;
  final String? value;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Popover(
      overlay: _menu,
      child: _Field(text: value ?? placeholder),
    );
  }

  Widget _menu(VoidCallback close) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final String option in options)
          _Option(
            label: option,
            selected: option == value,
            onTap: () {
              onChanged?.call(option);
              close();
            },
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.input,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.input),
          border: Border.all(color: AppColors.neutralLight),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(text, style: AppTextStyle.titleSmall),
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: selected ? AppColors.secondary : const Color(0x00000000),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(label, style: AppTextStyle.bodyLarge),
        ),
      ),
    );
  }
}
