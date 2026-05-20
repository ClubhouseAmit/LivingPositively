import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform, visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

class NotificationsService {
  static bool _isInitialized = false;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Test-only hook: clears the `_isInitialized` guard so `init()` will run
  /// its body again on the next call. Required by integration tests that
  /// exercise the timezone-error catch branch — the static flag is set by
  /// any prior `init()` call in the same isolate and would otherwise cause
  /// subsequent `init()` invocations to short-circuit and skip the branch
  /// under test. Per PR #266 review (baz-reviewer finding 3/4).
  @visibleForTesting
  static void resetForTest() {
    _isInitialized = false;
  }

  static const InitializationSettings _initializationSettings =
      InitializationSettings(
    android: AndroidInitializationSettings(
        '@mipmap/ic_launcher'), // Replace with your actual icon name
    iOS: DarwinInitializationSettings(),
  );

  static bool supportsReminderSettings({
    bool? isWebOverride,
    TargetPlatform? platformOverride,
  }) {
    final isWeb = isWebOverride ?? kIsWeb;
    if (isWeb) {
      return false;
    }

    final platform = platformOverride ?? defaultTargetPlatform;
    return platform == TargetPlatform.android;
  }

  static Future<void> init() async {
    if (_isInitialized) {
      // Already initialized, no need to initialize again
      return;
    }

    tz_data.initializeTimeZones();
    // Get the device's current time zone
    try {
      final TimezoneInfo timeZoneName =
          await FlutterTimezone.getLocalTimezone();
      //  String currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();

      // Set the local time zone

      tz.setLocalLocation(
          tz.getLocation(timeZoneName.identifier ?? "Asia/Jerusalem"));
      await _flutterLocalNotificationsPlugin
          .initialize(settings: _initializationSettings);
      _isInitialized = true;
    } catch (error, stackTrace) {
      tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));
      await _flutterLocalNotificationsPlugin
          .initialize(settings: _initializationSettings);
      _isInitialized = true;
      try {
        IncidentLoggerService loggerService =
            GetIt.instance<IncidentLoggerService>();
        await loggerService.captureLog(
          error,
          stackTrace: stackTrace,
        );
      } catch (e) {
        debugPrint("Failed to log the error: $e");
      }
    }
  }

  static Future<void> showNotification(String title, String body) async {
    debugPrint("trying to show notification");

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('exampleID', 'ShowExampleChannelTitle',
            channelDescription:
                'This is a channel for the user to show an example notification',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await _flutterLocalNotificationsPlugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'item x');
  }

  static TimeOfDay calculateTime(int h, int m) {
    return TimeOfDay(hour: h, minute: m);
  }

  static Future<void> initializeNotification(List<String> quotes, int hour,
      int minute, Function createText, AppLocalizations appLocale) async {
    if (!supportsReminderSettings()) {
      return;
    }

    final bool? grantedNotificationPermission;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
    } else {
      grantedNotificationPermission = false;
    }
    if (grantedNotificationPermission != null &&
        grantedNotificationPermission == false) {
      showToast(message: appLocale.noPermissionAllowedText);
      //if there are no permissions granted, or no permissions, the rest of the function should not run
      return;
    }
    TimeOfDay calculatedTime = calculateTime(hour, minute);
    String id = "${calculatedTime.hour}${calculatedTime.minute}";

    await cancelNotifications(null, cancelWorker: true);
    Workmanager().registerOneOffTask(
      id,
      "NotificationWorker${calculatedTime.hour}${calculatedTime.minute}",
      inputData: {
        "text": quotes,
        "timeHour": hour,
        "timeMinute": minute,
        "id": id
      },
    );
    Workmanager().registerPeriodicTask(
      id,
      "NotificationWorker${calculatedTime.hour}${calculatedTime.minute}Periodic",
      inputData: {
        "text": quotes,
        "timeHour": hour,
        "timeMinute": minute,
        "id": id
      },
      frequency: Duration(days: 1),
    );

    var message = createText(
        '${hour < 10 ? "0$hour" : hour}:${minute < 10 ? "0$minute" : minute}');
    showToast(message: message);
  }

  static Future<void> updateNotification(
      UserInformation userInfo, AppLocalizations appLocale) async {
    if (!supportsReminderSettings()) {
      return;
    }

    var hour = userInfo.notificationHour;
    var minute = userInfo.notificationMinute;
    var newQuotes = retrieveInspirationalQuotes(appLocale, userInfo.gender);
    await initializeNotification(newQuotes, hour, minute,
        appLocale.notifyOnscheduledNotification, appLocale);
  }

  static Future<void> scheduleNotification(
      TimeOfDay timeOfDay, String id, String text) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month,
        now.day, timeOfDay.hour, timeOfDay.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: int.parse(id),
      title: 'Living Positively',
      body: text,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
              'LPNotificationServiceID', 'LP Notifications',
              channelDescription:
                  'LP Notifications allows you to receive daily reminders from the Mazilon app to keep track of your mental health')),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel a specific notification
  static Future<void> cancelNotifications(int? id,
      {bool cancelWorker = false}) async {
    if (cancelWorker && !kIsWeb) {
      await Workmanager().cancelAll();
    }
    if (id == null) {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } else {
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    }
    debugPrint('Notification with ID $id cancelled');
  }

  // Cancel all notifications
}
