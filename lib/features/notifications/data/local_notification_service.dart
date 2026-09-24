import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mazilon/features/notifications/data/reminder_debug_recorder.dart';

/// Owns the platform-local display channel and legacy reminder cancellation.
final class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'LPNotificationServiceID',
    'LP Notifications',
    description: 'Living Positively reminder notifications',
    importance: Importance.max,
  );

  static const _foregroundDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'LPNotificationServiceID',
      'LP Notifications',
      channelDescription: 'Living Positively reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> initialize() async {
    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Firebase Messaging owns the permission prompt on Apple platforms.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestProvisionalPermission: false,
          requestCriticalPermission: false,
          requestProvidesAppNotificationSettings: false,
        ),
      ),
    );
    // Darwin returns false when all permission requests are disabled.
    if (initialized == null ||
        (defaultTargetPlatform == TargetPlatform.android && !initialized)) {
      throw StateError('Local notification plugin did not initialize.');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_androidChannel);
    }
  }

  static Future<void> showForeground(String title, String body) => _plugin.show(
    id: 1,
    title: title,
    body: body,
    notificationDetails: _foregroundDetails,
  );

  static void listenForForegroundMessages(
    void Function(Object error, StackTrace stackTrace) onFailure,
  ) {
    FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title ?? 'Living Positively';
      final body = message.notification?.body ?? '';
      try {
        await showForeground(title, body);
        unawaited(
          recordReminderDebugEvent(
            status: reminderDebugStatusSuccess,
            task: 'fcm_foreground_message',
          ),
        );
      } catch (error, stackTrace) {
        unawaited(
          recordReminderDebugEvent(
            status: reminderDebugStatusFailure,
            task: 'fcm_foreground_message',
            error: error.toString(),
          ),
        );
        onFailure(error, stackTrace);
      }
    });
  }

  static Future<void> cancelLegacy(int notificationId) =>
      _plugin.cancel(id: notificationId);

  static Future<void> cancelAllLegacy() => _plugin.cancelAll();
}
