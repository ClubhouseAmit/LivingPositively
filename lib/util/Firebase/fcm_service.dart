import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:uuid/uuid.dart';

class FcmService {
  static bool _isInitialized = false;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _foregroundNotificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'LPNotificationServiceID',
      'LP Notifications',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static void _log(String message) {
    debugPrint('[FcmService] $message');
  }

  static Future<void> initialize() async {
    if (_isInitialized) {
      _log('Already initialized, skipping.');
      return;
    }
    _isInitialized = true;
    _log('Initializing...');

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _log('Permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _log('Permission denied — aborting initialization.');
      return;
    }

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _log('Local notifications initialized.');

    final deviceId = await _getOrCreateDeviceId();
    _log('Device ID: $deviceId');

    final token = await FirebaseMessaging.instance.getToken();
    _log('FCM token: $token');
    if (token != null) await _saveTokenToFirestore(deviceId, token);

    _setupForegroundHandler();
    _setupOnMessageOpenedApp();

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _log('FCM token refreshed: $newToken');
      _saveTokenToFirestore(deviceId, newToken);
    });

    _log('Initialization complete.');
  }

  static Future<String> _getOrCreateDeviceId() async {
    final prefs = GetIt.instance<PersistentMemoryService>();
    final existing =
        await prefs.getItem('deviceId', PersistentMemoryType.String) as String;
    if (existing.isNotEmpty) {
      _log('Found existing device ID: $existing');
      debugPrint('[FcmService] Device already has a unique ID: $existing');
      return existing;
    }

    final id = const Uuid().v4();
    _log('Created new device ID: $id');
    await prefs.setItem('deviceId', PersistentMemoryType.String, id);
    return id;
  }

  static Future<void> _saveTokenToFirestore(
      String deviceId, String token) async {
    _log('Saving token to Firestore for device $deviceId...');
    try {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(deviceId)
          .set({
        'fcmToken': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log('Token saved to Firestore successfully.');
    } catch (error, stackTrace) {
      _log('Failed to save token to Firestore: $error');
      try {
        GetIt.instance<IncidentLoggerService>()
            .captureLog(error, stackTrace: stackTrace);
      } catch (_) {}
    }
  }

  static void _setupForegroundHandler() {
    _log('Setting up foreground message handler.');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Living Positively';
      final body = message.notification?.body ?? '';
      _log('Foreground message received — title: "$title", body: "$body", data: ${message.data}');
      await _localNotifications.show(
        id: 1,
        title: title,
        body: body,
        notificationDetails: _foregroundNotificationDetails,
      );
      _log('Local notification shown.');
    });
  }

  static void _setupOnMessageOpenedApp() {
    _log('Setting up onMessageOpenedApp handler.');
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log('App opened from background notification — data: ${message.data}');
      _handleNotificationTap(message);
    });
  }

  static void handleInitialMessage(RemoteMessage message) {
    _log('App launched from terminated state via notification — data: ${message.data}');
    _handleNotificationTap(message);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    _log('Handling notification tap — navigating to root.');
    final navigatorKey = GetIt.instance<GlobalKey<NavigatorState>>();
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
