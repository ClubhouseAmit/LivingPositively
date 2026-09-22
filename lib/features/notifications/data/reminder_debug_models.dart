const String reminderDebugLastFireAtKey = 'reminder_debug_last_fire_at';
const String reminderDebugLastStatusKey = 'reminder_debug_last_fire_status';
const String reminderDebugLastErrorKey = 'reminder_debug_last_fire_error';
const String reminderDebugLastTaskKey = 'reminder_debug_last_fire_task';
const String reminderDebugRecentEventsKey = 'reminder_debug_recent_events';
const String reminderDebugPanelUnlockedKey = 'reminder_debug_panel_unlocked';
const int reminderDebugMaxRecentEvents = 20;

const String reminderDebugStatusSuccess = 'success';
const String reminderDebugStatusFailure = 'failure';

/// Persisted diagnostics shown to the user in the reminder debug panel.
class ReminderDebugSnapshot {
  const ReminderDebugSnapshot({
    this.lastFireAt,
    this.lastStatus,
    this.lastError,
    this.lastTask,
    this.recentEvents = const [],
  });

  final String? lastFireAt;
  final String? lastStatus;
  final String? lastError;
  final String? lastTask;
  final List<String> recentEvents;
}
