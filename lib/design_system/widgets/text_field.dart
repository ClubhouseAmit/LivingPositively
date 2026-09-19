import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/tokens/type_scale.dart';

/// Design-system text field.
///
/// Built on `EditableText` (`widgets.dart`), not Material's `TextField`.
/// Height `AppSpacing.input`, radius `AppRadii.input` — DESIGN.md §3.4.
class TextField extends StatefulWidget {
  const TextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.error = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool error;

  @override
  State<TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<TextField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  late final bool _ownsController;
  late final bool _ownsFocus;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _ownsFocus = widget.focusNode == null;
    _focus = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocus) {
      _focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      enabled: widget.enabled,
      label: widget.placeholder,
      child: GestureDetector(
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: SizedBox(
          height: AppSpacing.input,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadii.input),
              border: Border.all(
                color: widget.error ? AppColors.error : AppColors.neutralLight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  ListenableBuilder(
                    listenable: _controller,
                    builder: _placeholder,
                  ),
                  _editor(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, Widget? child) {
    if (_controller.text.isNotEmpty || widget.placeholder == null) {
      return const SizedBox.shrink();
    }
    return Text(
      widget.placeholder!,
      style: AppTextStyle.titleSmall,
      color: AppColors.onSurface.withValues(alpha: 0.5),
    );
  }

  Widget _editor() {
    return EditableText(
      controller: _controller,
      focusNode: _focus,
      readOnly: !widget.enabled,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType ?? TextInputType.text,
      style: AppTypeScale.titleSmall.copyWith(color: AppColors.onSurface),
      cursorColor: AppColors.primary,
      backgroundCursorColor: AppColors.neutralLight,
      onChanged: widget.onChanged,
      maxLines: 1,
    );
  }
}
