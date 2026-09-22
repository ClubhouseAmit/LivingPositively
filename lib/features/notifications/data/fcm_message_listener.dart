import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mazilon/features/notifications/data/local_notification_service.dart';

/// Connects FCM message streams to the notification lifecycle callbacks.
final class FcmMessageListener {
  const FcmMessageListener._();

  static void register({
    required Future<void> Function(String token) onTokenRefresh,
    required void Function(RemoteMessage message) onOpened,
    required void Function(Object error, StackTrace stackTrace) onFailure,
  }) {
    LocalNotificationService.listenForForegroundMessages(onFailure);
    FirebaseMessaging.onMessageOpenedApp.listen(onOpened);
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => unawaited(onTokenRefresh(token)),
    );
  }

  static Future<void> handleInitialMessage({
    required Future<RemoteMessage?> Function() getInitialMessage,
    required void Function(RemoteMessage message) onOpened,
    required void Function(Object error, StackTrace stackTrace) onFailure,
  }) async {
    try {
      final message = await getInitialMessage();
      if (message != null) onOpened(message);
    } catch (error, stackTrace) {
      onFailure(error, stackTrace);
    }
  }
}
