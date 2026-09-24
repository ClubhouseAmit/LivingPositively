import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text_field.dart';

/// Date as `YYYY-MM-DD` text. No calendar overlay — add when a picker is
/// actually needed.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    this.controller,
    this.onChanged,
    this.error = false,
  });

  final TextEditingController? controller;
  final ValueChanged<DateTime>? onChanged;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      placeholder: 'YYYY-MM-DD',
      keyboardType: TextInputType.datetime,
      error: error,
      onChanged: _parse,
    );
  }

  void _parse(String text) {
    final DateTime? parsed = DateTime.tryParse(text);
    if (parsed != null) {
      onChanged?.call(parsed);
    }
  }
}
