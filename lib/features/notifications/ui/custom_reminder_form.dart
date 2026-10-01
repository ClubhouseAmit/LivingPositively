import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/l10n/app_localizations.dart';

/// Collects the emoji, label, and time for a new personal reminder.
class CustomReminderForm extends StatefulWidget {
  const CustomReminderForm({
    required this.use24HourFormat,
    required this.onAdd,
    super.key,
  });

  final bool use24HourFormat;
  final Future<bool> Function(String emoji, String label, TimeOfDay time) onAdd;

  @override
  State<CustomReminderForm> createState() => _CustomReminderFormState();
}

class _CustomReminderFormState extends State<CustomReminderForm> {
  final _emoji = TextEditingController();
  final _label = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _saving = false;

  @override
  void dispose() {
    _emoji.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final use24HourFormat = widget.use24HourFormat;
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: use24HourFormat,
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final label = _label.text.trim();
    final emoji = _emoji.text.trim();
    if (_saving ||
        label.isEmpty ||
        label.length > 240 ||
        emoji.runes.length > 16) {
      return;
    }
    setState(() => _saving = true);
    try {
      final added = await widget.onAdd(emoji, label, _time);
      if (added && mounted) {
        _emoji.clear();
        _label.clear();
        setState(() => _time = const TimeOfDay(hour: 8, minute: 0));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(
      _time,
      alwaysUse24HourFormat: widget.use24HourFormat,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(width: AppSpacing.xxl * 3, child: _emojiField(locale)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _labelField(locale)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Button(
              label: formatted,
              variant: ButtonVariant.secondary,
              fullWidth: false,
              onPressed: _saving ? null : _pickTime,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Button(
                label: locale.reminderAdd,
                onPressed: _saving ? null : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _emojiField(AppLocalizations locale) => TextField(
    controller: _emoji,
    maxLength: 2,
    inputFormatters: [
      LengthLimitingTextInputFormatter(2),
      TextInputFormatter.withFunction(
        (oldValue, newValue) =>
            newValue.text.runes.length <= 16 ? newValue : oldValue,
      ),
    ],
    decoration: InputDecoration(labelText: locale.reminderEmojiLabel),
    textInputAction: TextInputAction.next,
  );

  Widget _labelField(AppLocalizations locale) => TextField(
    controller: _label,
    inputFormatters: [
      TextInputFormatter.withFunction(
        (oldValue, newValue) =>
            newValue.text.length <= 240 ? newValue : oldValue,
      ),
    ],
    textDirection: Directionality.of(context),
    decoration: InputDecoration(
      labelText: locale.reminderLabelLabel,
      counterText: '${_label.text.length}/240',
    ),
    onChanged: (_) => setState(() {}),
    textInputAction: TextInputAction.done,
    onSubmitted: (_) => _submit(),
  );
}
