// Widget tests for lib/pages/notifications/notification_page.dart.
//
// NotificationPage wraps SetNotificationWidget + a long-press gesture on its
// header that toggles the ReminderDebugPanel unlock flag in SharedPreferences.
// We pump on iOS so the inner SetNotificationWidget's NotificationsService
// init short-circuits (supportsReminderSettings → false on iOS), keeping the
// test from touching WorkManager/permission flows. We follow the established
// pattern from `set_notification_widget_test.dart` for plugin/channel stubs.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/notifications/notification_page.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart'
    show reminderDebugPanelUnlocked, reminderDebugPanelUnlockedKey;
import 'package:mazilon/pages/notifications/set_notification_widget.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager_platform_interface/workmanager_platform_interface.dart';

import '../helpers/widget_test_scaffold.dart';

class _NoopWorkmanager extends WorkmanagerPlatform {
  _NoopWorkmanager._() : super();
  static final _NoopWorkmanager _shared = _NoopWorkmanager._();
  static _NoopWorkmanager register() {
    WorkmanagerPlatform.instance = _shared;
    return _shared;
  }

  @override
  Future<void> initialize(Function callbackDispatcher,
      {bool isInDebugMode = false}) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {}

  @override
  Future<void> cancelByTag(String tag) async {}

  @override
  Future<void> registerOneOffTask(String uniqueName, String taskName,
      {Map<String, dynamic>? inputData,
      Duration? initialDelay,
      Constraints? constraints,
      ExistingWorkPolicy? existingWorkPolicy,
      BackoffPolicy? backoffPolicy,
      Duration? backoffPolicyDelay,
      String? tag,
      OutOfQuotaPolicy? outOfQuotaPolicy}) async {}

  @override
  Future<void> registerPeriodicTask(String uniqueName, String taskName,
      {Duration? frequency,
      Duration? flexInterval,
      Map<String, dynamic>? inputData,
      Duration? initialDelay,
      Constraints? constraints,
      ExistingPeriodicWorkPolicy? existingWorkPolicy,
      BackoffPolicy? backoffPolicy,
      Duration? backoffPolicyDelay,
      String? tag}) async {}
}

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

  const localNotifChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const timezoneChannel = MethodChannel('flutter_timezone');
  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    IOSFlutterLocalNotificationsPlugin.registerWith();
    _NoopWorkmanager.register();
    registerTestServices();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(timezoneChannel, (call) async {
        if (call.method == 'getLocalTimezone') return 'UTC';
        return null;
      })
      ..setMockMethodCallHandler(localNotifChannel, (call) async => null)
      ..setMockMethodCallHandler(toastChannel, (call) async => true);
  });

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(timezoneChannel, null)
      ..setMockMethodCallHandler(localNotifChannel, null)
      ..setMockMethodCallHandler(toastChannel, null);
    resetTestServices();
  });

  testWidgets('renders SafeArea + SingleChildScrollView + SetNotificationWidget',
      (tester) async {
    await _onIos(() async {
      await pumpWithProviders(
        tester,
        const NotificationPage(),
        userInformation: UserInformation(
          gender: 'male',
          notificationHour: 9,
          notificationMinute: 0,
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(find.byType(NotificationPage), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.byType(SetNotificationWidget), findsOneWidget);
    });
  });

  testWidgets('long-press on the header toggles debug panel unlock flag',
      (tester) async {
    await _onIos(() async {
      // Seed prefs in the locked state (default).
      SharedPreferences.setMockInitialValues({});

      await pumpWithProviders(
        tester,
        const NotificationPage(),
        userInformation: UserInformation(gender: 'male'),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // The header is a GestureDetector wrapping a Text widget. Long-press
      // on the gesture detector.
      final headerGesture = find.byType(GestureDetector).first;
      await tester.longPress(headerGesture, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Toggle ran; the in-memory ValueNotifier flipped to unlocked AND the
      // SnackBar was shown by NotificationPage._toggleDebugUnlock.
      expect(reminderDebugPanelUnlocked.value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(reminderDebugPanelUnlockedKey), isTrue);

      // SnackBar should have been shown.
      expect(find.byType(SnackBar), findsOneWidget);

      // Restore in-memory flag so subsequent suites are not contaminated.
      reminderDebugPanelUnlocked.value = false;
      await prefs.setBool(reminderDebugPanelUnlockedKey, false);
    });
  });
}
