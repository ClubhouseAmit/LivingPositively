import 'package:flutter/material.dart' hide Text;
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/notifications/ui/custom_reminder_form.dart';
import 'package:mazilon/features/notifications/ui/reminder_item_card.dart';
import 'package:mazilon/features/notifications/ui/reminder_quick_presets.dart';
import 'package:mazilon/l10n/app_localizations.dart';

/// Additional controls on the existing reminders settings page.
class ReminderSettingsPanel extends StatefulWidget {
  const ReminderSettingsPanel({
    required this.repository,
    required this.onRegister,
    required this.onCancel,
    required this.onFailure,
    required this.onFormatChanged,
    super.key,
  });

  final NotificationRepository repository;
  final Future<bool> Function(String, TimeOfDay, String, String) onRegister;
  final Future<bool> Function(String) onCancel;
  final VoidCallback onFailure;
  final VoidCallback onFormatChanged;

  @override
  State<ReminderSettingsPanel> createState() => _ReminderSettingsPanelState();
}

class _ReminderSettingsPanelState extends State<ReminderSettingsPanel> {
  int _nextCustomId = 0;

  TimeOfDay _timeFor(String id) {
    final preference = widget.repository.getSavedTime(id);
    return preference == null
        ? const TimeOfDay(hour: 8, minute: 0)
        : TimeOfDay(hour: preference.hour, minute: preference.minute);
  }

  Future<bool> _setEnabled(
    String id,
    String label,
    bool enabled,
    TimeOfDay time, {
    bool rethrowLimit = false,
  }) async {
    if (enabled &&
        widget.repository.getPreference(id) == null &&
        widget.repository.preferences.length >= maxRemindersPerUser) {
      _showLimitReached();
      return false;
    }
    bool applied;
    try {
      applied = enabled
          ? await widget.onRegister(id, time, 'Living Positively', label)
          : await widget.onCancel(id);
    } on NotificationReminderLimitException {
      if (rethrowLimit) rethrow;
      _showLimitReached();
      return false;
    }
    if (applied && mounted) {
      setState(() {});
    } else if (!applied) {
      widget.onFailure();
    }
    return applied;
  }

  Future<bool> _setTime(String id, String label, TimeOfDay time) async {
    final enabled = widget.repository.getPreference(id) != null;
    if (enabled) return _setEnabled(id, label, true, time);
    try {
      final previous = widget.repository.getSavedTime(id);
      await widget.repository.setSavedTime(
        id,
        NotificationPreference.withContent(
          hour: time.hour,
          minute: time.minute,
          staticTitle: previous?.staticTitle,
          staticBody: previous?.staticBody,
        ),
      );
      if (mounted) setState(() {});
      return true;
    } catch (_) {
      widget.onFailure();
      return false;
    }
  }

  Future<bool> _addCustom(
    String emoji,
    String label,
    TimeOfDay time,
  ) async {
    if (widget.repository.preferences.length >= maxRemindersPerUser) {
      _showLimitReached();
      return false;
    }
    final id =
        'custom_${DateTime.now().microsecondsSinceEpoch}_${_nextCustomId++}';
    final reminder = CustomReminder(
      id: id,
      emoji: emoji.isEmpty ? '✨' : emoji,
      label: label,
      hour: time.hour,
      minute: time.minute,
    );
    try {
      await widget.repository.setCustomReminder(reminder);
    } catch (_) {
      widget.onFailure();
      return false;
    }
    if (!mounted) return false;
    setState(() {});
    try {
      await _setEnabled(id, label, true, time, rethrowLimit: true);
    } on NotificationReminderLimitException {
      try {
        await widget.repository.removeCustomReminder(id);
      } catch (_) {
        widget.onFailure();
        return false;
      }
      if (mounted) setState(() {});
      _showLimitReached();
      return false;
    }
    if (mounted) setState(() {});
    return true;
  }

  void _showLimitReached() {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reminderLimitReached),
        ),
      );
  }

  Future<bool> _removeCustom(CustomReminder reminder) async {
    if (!await widget.onCancel(reminder.id)) {
      widget.onFailure();
      return false;
    }
    try {
      await widget.repository.removeCustomReminder(reminder.id);
    } catch (_) {
      widget.onFailure();
      return false;
    }
    if (mounted) setState(() {});
    return true;
  }

  Future<void> _changeFormat(bool use24Hour) async {
    try {
      await widget.repository.setUse24HourFormat(use24Hour);
    } catch (_) {
      widget.onFailure();
      return;
    }
    if (!mounted) return;
    setState(() {});
    widget.onFormatChanged();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final quick = quickReminderPresets(locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        if (MediaQuery.sizeOf(context).width < 600) ...[
          _formatControl(locale),
          const SizedBox(height: AppSpacing.xxl),
        ],
        _sectionLabel('⚡ ${locale.reminderQuickSection}'),
        const SizedBox(height: AppSpacing.sm),
        for (final preset in quick) ...[
          _quickCard(preset),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.lg),
        CustomPaint(
          painter: _DashedDividerPainter(Theme.of(context).colorScheme.outline),
          child: const SizedBox(height: AppSpacing.hairline),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _sectionLabel(locale.reminderCustomSection),
        const SizedBox(height: AppSpacing.sm),
        CustomReminderForm(
          use24HourFormat: widget.repository.use24HourFormat,
          onAdd: _addCustom,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final reminder in widget.repository.customReminders) ...[
          _customCard(reminder, locale),
          const SizedBox(height: AppSpacing.sm),
        ],
        _summary(locale, quick),
      ],
    );
  }

  Widget _formatControl(AppLocalizations locale) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Text(locale.reminderAmPmFormat, style: AppTextStyle.labelSmall),
      Switch(
        value: widget.repository.use24HourFormat,
        onChanged: _changeFormat,
      ),
      Text(locale.reminderHourFormat, style: AppTextStyle.labelSmall),
    ],
  );

  Widget _sectionLabel(String value) => Text(
    value.toUpperCase(),
    style: AppTextStyle.labelSmall,
    color: Theme.of(context).colorScheme.primary,
  );

  Widget _quickCard(QuickReminderPreset preset) => ReminderItemCard(
    key: ValueKey(preset.id),
    emoji: preset.emoji,
    label: preset.label,
    time: _timeFor(preset.id),
    enabled: widget.repository.getPreference(preset.id) != null,
    use24HourFormat: widget.repository.use24HourFormat,
    onToggle: (value) => _setEnabled(
      preset.id,
      preset.label,
      value,
      _timeFor(preset.id),
    ),
    onTimeChanged: (time) => _setTime(preset.id, preset.label, time),
  );

  Widget _customCard(CustomReminder reminder, AppLocalizations locale) {
    final enabled = widget.repository.getPreference(reminder.id) != null;
    final time = enabled
        ? _timeFor(reminder.id)
        : TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    return ReminderItemCard(
      key: ValueKey(reminder.id),
      emoji: reminder.emoji,
      label: reminder.label,
      time: time,
      enabled: enabled,
      use24HourFormat: widget.repository.use24HourFormat,
      onToggle: (value) => _setEnabled(
        reminder.id,
        reminder.label,
        value,
        time,
      ),
      onTimeChanged: (picked) => _setCustomTime(reminder, picked),
      onRemove: () => _removeCustom(reminder),
      removeLabel: locale.reminderRemove,
    );
  }

  Future<bool> _setCustomTime(CustomReminder reminder, TimeOfDay time) async {
    final applied = await _setTime(reminder.id, reminder.label, time);
    if (!applied) return false;
    try {
      await widget.repository.setCustomReminder(
        CustomReminder(
          id: reminder.id,
          emoji: reminder.emoji,
          label: reminder.label,
          hour: time.hour,
          minute: time.minute,
        ),
      );
    } catch (_) {
      widget.onFailure();
      return false;
    }
    if (mounted) setState(() {});
    return true;
  }

  Widget _summary(
    AppLocalizations locale,
    List<QuickReminderPreset> quick,
  ) {
    final preferences = widget.repository.preferences;
    if (preferences.isEmpty) return const SizedBox.shrink();
    final labels = {
      'default': locale.reminderAppTitle,
      for (final preset in quick) preset.id: preset.label,
      for (final custom in widget.repository.customReminders)
        custom.id: custom.label,
    };
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xxl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.07),
        border: Border.all(color: colors.secondary),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(locale.reminderActiveSection),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in preferences.entries)
            if (labels.containsKey(entry.key))
              _summaryRow(labels[entry.key]!, entry.value),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, NotificationPreference preference) {
    final time = TimeOfDay(hour: preference.hour, minute: preference.minute);
    final formatted = MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: widget.repository.use24HourFormat,
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyle.bodySmall)),
          Text(formatted, style: AppTextStyle.labelSmall),
        ],
      ),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppSpacing.hairline;
    for (var x = 0.0; x < size.width; x += AppSpacing.md) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + AppSpacing.sm).clamp(0, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
