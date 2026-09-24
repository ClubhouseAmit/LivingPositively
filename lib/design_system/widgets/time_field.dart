import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/widgets/text_field.dart';

/// Time as `HH:MM` text. [onChanged] is minutes since midnight.
/// No clock overlay — add when a picker is actually needed.
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    this.controller,
    this.onChanged,
    this.error = false,
  });

  final TextEditingController? controller;
  final ValueChanged<int>? onChanged;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      placeholder: 'HH:MM',
      keyboardType: TextInputType.datetime,
      error: error,
      onChanged: _parse,
    );
  }

  void _parse(String text) {
    final List<String> parts = text.split(':');
    if (parts.length != 2) {
      return;
    }
    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return;
    }
    onChanged?.call(hour * 60 + minute);
  }
}
