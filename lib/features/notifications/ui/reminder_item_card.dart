import 'package:flutter/material.dart' hide Text;
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/features/notifications/ui/reminder_switch.dart';

/// Displays one independently scheduled quick or custom reminder.
class ReminderItemCard extends StatefulWidget {
  const ReminderItemCard({
    required this.emoji,
    required this.label,
    required this.time,
    required this.enabled,
    required this.use24HourFormat,
    required this.onToggle,
    required this.onTimeChanged,
    this.onRemove,
    this.removeLabel,
    super.key,
  });

  final String emoji;
  final String label;
  final TimeOfDay time;
  final bool enabled;
  final bool use24HourFormat;
  final Future<bool> Function(bool) onToggle;
  final Future<bool> Function(TimeOfDay) onTimeChanged;
  final Future<bool> Function()? onRemove;
  final String? removeLabel;

  @override
  State<ReminderItemCard> createState() => _ReminderItemCardState();
}

class _ReminderItemCardState extends State<ReminderItemCard> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onToggle(value);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime() async {
    if (_busy) return;
    final use24HourFormat = widget.use24HourFormat;
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.time,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: use24HourFormat,
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onTimeChanged(picked);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    if (_busy || widget.onRemove == null) return;
    setState(() => _busy = true);
    try {
      await widget.onRemove!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final use24Hour = widget.use24HourFormat;
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(
      widget.time,
      alwaysUse24HourFormat: use24Hour,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: widget.enabled
            ? colors.primary.withValues(alpha: 0.08)
            : colors.primary.withValues(alpha: 0.03),
        border: Border.all(
          color: widget.enabled
              ? colors.primary
              : colors.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Text(widget.emoji, style: AppTextStyle.titleLarge),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _content(context, formatted)),
          if (widget.onRemove != null)
            IconButton(
              tooltip: widget.removeLabel,
              onPressed: _busy ? null : _remove,
              icon: const Icon(Icons.close),
            ),
          ReminderSwitch(
            value: widget.enabled,
            label: widget.label,
            busy: _busy,
            onPressed: _busy ? null : () => _toggle(!widget.enabled),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, String formatted) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.label,
        style: AppTextStyle.titleSmall,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      if (widget.enabled)
        Semantics(
          button: true,
          label: formatted,
          child: GestureDetector(
            onTap: _busy ? null : _pickTime,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: AppSpacing.lg,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    formatted,
                    style: AppTextStyle.labelSmall,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: AppSpacing.lg,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
