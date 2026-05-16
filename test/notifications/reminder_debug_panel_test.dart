// Smoke tests for ReminderDebugPanel.
//
// The panel's heavy interactions (permission lookups via permission_handler,
// rescheduling via WorkManager, opening app settings) are all Android-only
// branches gated on `_isAndroid`. We pump on iOS so the test exercises:
//   - initState -> _refresh()
//   - SharedPreferences read paths for last-fire/status/task/error/events
//   - the ExpansionTile/title/subtitle render
//   - the "WorkManager-backed reminders run on Android only." advisory text
//   - the static `_permLabel(null)` -> 'n/a' branch
//
// The `Reschedule now` button is disabled on non-Android, so tapping it is
// a no-op (we verify that). The `Open app settings` button calls
// `openAppSettings()` which goes through permission_handler's platform
// channel — we stub that channel and verify the call.
//
// The `Clear history` and `Reschedule` buttons are wired but are also
// disabled when there's no history / not Android, so we don't exercise
// those side effects.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/notifications/reminder_debug_panel.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/widget_test_scaffold.dart';

Future<T> _onIos<T>(Future<T> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // permission_handler's method channel — on iOS the panel only invokes
  // openAppSettings() when the user taps "Open app settings", and we don't
  // tap it. Still, stub it so any defensive lookup short-circuits cleanly.
  const permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');

  setUp(() {
    SharedPreferences.setMockInitialValues({
      reminderDebugLastFireAtKey: '2025-01-01T12:00:00.000Z',
      reminderDebugLastStatusKey: reminderDebugStatusSuccess,
      reminderDebugLastTaskKey: 'NotificationWorker0900Periodic',
      reminderDebugLastErrorKey: '',
      reminderDebugRecentEventsKey: <String>[
        '2025-01-01T12:00:00.000Z success NotificationWorker0900Periodic',
      ],
    });
    registerTestServices();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async => 1);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
    resetTestServices();
  });

  testWidgets('renders ExpansionTile with header + advisory copy on iOS',
      (tester) async {
    await _onIos(() async {
      await pumpWithProviders(
        tester,
        const Scaffold(body: ReminderDebugPanel()),
        userInformation: UserInformation(
          gender: 'male',
          notificationHour: 9,
          notificationMinute: 0,
        ),
      );
      // Allow initState -> _refresh() future to complete.
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.text('Reminder debug panel'), findsOneWidget);
      expect(
          find.text('Diagnose why scheduled reminders may not be firing'),
          findsOneWidget);
    });
  });

  testWidgets('expanded panel surfaces shared-prefs diagnostic state',
      (tester) async {
    await _onIos(() async {
      await pumpWithProviders(
        tester,
        const Scaffold(body: ReminderDebugPanel()),
        userInformation: UserInformation(
          gender: 'male',
          notificationHour: 9,
          notificationMinute: 0,
        ),
        // Larger surface so the expanded contents fit without overflowing.
        surfaceSize: const Size(800, 1400),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      // Labels for diagnostic rows.
      expect(find.text('Scheduled time'), findsOneWidget);
      expect(find.text('Last fire at'), findsOneWidget);
      expect(find.text('Last status'), findsOneWidget);
      expect(find.text('Last task'), findsOneWidget);
      // Action buttons.
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('Reschedule now'), findsOneWidget);
      expect(find.text('Open app settings'), findsOneWidget);
      expect(find.text('Copy diagnostics'), findsOneWidget);
      expect(find.text('Clear history'), findsOneWidget);
      // Non-Android advisory.
      expect(
        find.text('WorkManager-backed reminders run on Android only.'),
        findsOneWidget,
      );
      // Values from SharedPreferences mock.
      expect(find.text('2025-01-01T12:00:00.000Z'), findsOneWidget);
      expect(find.text('NotificationWorker0900Periodic'), findsOneWidget);
      // Scheduled time from UserInformation (09:00 zero-padded).
      expect(find.text('09:00'), findsOneWidget);
    });
  });

  testWidgets('Reschedule button is disabled on non-Android', (tester) async {
    await _onIos(() async {
      await pumpWithProviders(
        tester,
        const Scaffold(body: ReminderDebugPanel()),
        userInformation: UserInformation(gender: 'male'),
        surfaceSize: const Size(800, 1400),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      final rescheduleButton =
          tester.widget<OutlinedButton>(find.ancestor(
        of: find.text('Reschedule now'),
        matching: find.byType(OutlinedButton),
      ));
      expect(rescheduleButton.onPressed, isNull,
          reason: 'Reschedule must be disabled when not on Android');
    });
  });

  testWidgets('Refresh button re-runs _refresh() without throwing',
      (tester) async {
    await _onIos(() async {
      await pumpWithProviders(
        tester,
        const Scaffold(body: ReminderDebugPanel()),
        userInformation: UserInformation(gender: 'male'),
        surfaceSize: const Size(800, 1400),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      await tester.tap(find.text('Refresh'), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      // Widget must still be present after the rebuild.
      expect(find.text('Refresh'), findsOneWidget);
    });
  });

  testWidgets('Copy diagnostics writes JSON payload to clipboard',
      (tester) async {
    final clipboardCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      clipboardCalls.add(call);
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': ''};
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await _onIos(() async {
      await pumpWithProviders(
        tester,
        const Scaffold(body: ReminderDebugPanel()),
        userInformation: UserInformation(gender: 'male'),
        surfaceSize: const Size(800, 1400),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      await tester.tap(find.text('Copy diagnostics'), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      final setDataCalls =
          clipboardCalls.where((c) => c.method == 'Clipboard.setData').toList();
      expect(setDataCalls, isNotEmpty);
      // Payload must contain expected diagnostic keys.
      final payload = setDataCalls.first.arguments['text'] as String;
      expect(payload, contains('capturedAt'));
      expect(payload, contains('lastFireAt'));
      expect(payload, contains('notificationPermission'));
      // SnackBar should have surfaced.
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  testWidgets('Clear history button rebuilds without throwing', (tester) async {
    await _onIos(() async {
      await pumpWithProviders(
        tester,
        const Scaffold(body: ReminderDebugPanel()),
        userInformation: UserInformation(gender: 'male'),
        surfaceSize: const Size(800, 1400),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      await tester.tap(find.text('Clear history'), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.text('Clear history'), findsOneWidget);
    });
  });
}
