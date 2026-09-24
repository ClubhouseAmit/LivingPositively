import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text_field.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Fixed-length one-time-code field. Advances focus as digits are typed.
class OtpField extends StatefulWidget {
  const OtpField({super.key, this.length = 6, this.onCompleted});

  final int length;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _nodes = List<FocusNode>.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    for (final FocusNode n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String text) {
    final String digit = text.isEmpty ? '' : text.substring(text.length - 1);
    if (_controllers[index].text != digit) {
      _controllers[index].value = TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: digit.length),
      );
    }
    if (digit.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    if (digit.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    final String code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < widget.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _cell(i)),
        ],
      ],
    );
  }

  Widget _cell(int index) {
    return TextField(
      controller: _controllers[index],
      focusNode: _nodes[index],
      keyboardType: TextInputType.number,
      onChanged: (String text) => _onChanged(index, text),
    );
  }
}
