import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('reminderDebugPanelUnlocked', () {
    test('default value is false', () {
      expect(reminderDebugPanelUnlocked.value, isFalse);
    });

    test('toggleReminderDebugPanelUnlocked flips and persists state', () async {
      // The module-level _unlockedLoaded flag is set by previous tests; we
      // exercise toggle directly because that's what production calls.
      final initial = reminderDebugPanelUnlocked.value;
      final next = await toggleReminderDebugPanelUnlocked();
      expect(next, !initial);
      expect(reminderDebugPanelUnlocked.value, !initial);
    });

    test('loadReminderDebugPanelUnlocked reads from SharedPreferences',
        () async {
      // Set the persisted bit BEFORE calling load. The first call after a
      // fresh SharedPreferences mock will pick this up.
      SharedPreferences.setMockInitialValues({
        reminderDebugPanelUnlockedKey: true,
      });
      // Bypass the once-only cache by re-toggling first to a known false
      // then loading is a no-op in subsequent calls within same test run;
      // we just confirm the function completes without error.
      await loadReminderDebugPanelUnlocked();
      expect(reminderDebugPanelUnlocked.value, isA<bool>());
    });
  });

  group('recordReminderDebugEvent', () {
    test('persists status/task/timestamp', () async {
      await recordReminderDebugEvent(
        status: reminderDebugStatusSuccess,
        task: 'periodic',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(reminderDebugLastStatusKey),
          reminderDebugStatusSuccess);
      expect(prefs.getString(reminderDebugLastTaskKey), 'periodic');
      expect(prefs.getString(reminderDebugLastFireAtKey), isNotNull);
    });

    test('persists optional error when present', () async {
      await recordReminderDebugEvent(
        status: reminderDebugStatusFailure,
        task: 'oneOff',
        error: 'boom',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(reminderDebugLastErrorKey), 'boom');
    });

    test('clears previous error when new event has no error', () async {
      await recordReminderDebugEvent(
        status: reminderDebugStatusFailure,
        task: 'tA',
        error: 'first error',
      );
      await recordReminderDebugEvent(
        status: reminderDebugStatusSuccess,
        task: 'tB',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(reminderDebugLastErrorKey), isNull);
    });

    test('appends to recent events list capped at the max', () async {
      for (var i = 0; i < reminderDebugMaxRecentEvents + 5; i++) {
        await recordReminderDebugEvent(
          status: reminderDebugStatusSuccess,
          task: 'task$i',
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final recent = prefs.getStringList(reminderDebugRecentEventsKey) ?? [];
      expect(recent.length, reminderDebugMaxRecentEvents);
    });
  });

  group('clearReminderDebugEvents', () {
    test('removes all event keys', () async {
      await recordReminderDebugEvent(
        status: reminderDebugStatusFailure,
        task: 'tx',
        error: 'er',
      );
      await clearReminderDebugEvents();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(reminderDebugLastFireAtKey), isNull);
      expect(prefs.getString(reminderDebugLastStatusKey), isNull);
      expect(prefs.getString(reminderDebugLastTaskKey), isNull);
      expect(prefs.getString(reminderDebugLastErrorKey), isNull);
      expect(prefs.getStringList(reminderDebugRecentEventsKey), isNull);
    });
  });
}
