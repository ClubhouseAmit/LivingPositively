import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String reminderDebugLastFireAtKey = 'reminder_debug_last_fire_at';
const String reminderDebugLastStatusKey = 'reminder_debug_last_fire_status';
const String reminderDebugLastErrorKey = 'reminder_debug_last_fire_error';
const String reminderDebugLastTaskKey = 'reminder_debug_last_fire_task';
const String reminderDebugRecentEventsKey = 'reminder_debug_recent_events';
const String reminderDebugPanelUnlockedKey = 'reminder_debug_panel_unlocked';
const int reminderDebugMaxRecentEvents = 20;

const String reminderDebugStatusSuccess = 'success';
const String reminderDebugStatusFailure = 'failure';

final ValueNotifier<bool> reminderDebugPanelUnlocked = ValueNotifier<bool>(false);
bool _unlockedLoaded = false;

Future<void> loadReminderDebugPanelUnlocked() async {
  if (_unlockedLoaded) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    reminderDebugPanelUnlocked.value =
        prefs.getBool(reminderDebugPanelUnlockedKey) ?? false;
  } catch (_) {
    reminderDebugPanelUnlocked.value = false;
  } finally {
    _unlockedLoaded = true;
  }
}

Future<bool> toggleReminderDebugPanelUnlocked() async {
  final next = !reminderDebugPanelUnlocked.value;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(reminderDebugPanelUnlockedKey, next);
  } catch (_) {}
  reminderDebugPanelUnlocked.value = next;
  _unlockedLoaded = true;
  return next;
}

Future<void> recordReminderDebugEvent({
  required String status,
  required String task,
  String? error,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();

    await prefs.setString(reminderDebugLastFireAtKey, timestamp);
    await prefs.setString(reminderDebugLastStatusKey, status);
    await prefs.setString(reminderDebugLastTaskKey, task);
    if (error == null || error.isEmpty) {
      await prefs.remove(reminderDebugLastErrorKey);
    } else {
      await prefs.setString(reminderDebugLastErrorKey, error);
    }

    final recent =
        prefs.getStringList(reminderDebugRecentEventsKey) ?? <String>[];
    final summary = error == null || error.isEmpty
        ? '$timestamp | $status | $task'
        : '$timestamp | $status | $task | $error';
    recent.add(summary);
    while (recent.length > reminderDebugMaxRecentEvents) {
      recent.removeAt(0);
    }
    await prefs.setStringList(reminderDebugRecentEventsKey, recent);
  } catch (_) {
    // Recording is best-effort; never let diagnostics break the worker.
  }
}

Future<void> clearReminderDebugEvents() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(reminderDebugLastFireAtKey);
    await prefs.remove(reminderDebugLastStatusKey);
    await prefs.remove(reminderDebugLastErrorKey);
    await prefs.remove(reminderDebugLastTaskKey);
    await prefs.remove(reminderDebugRecentEventsKey);
  } catch (_) {}
}
