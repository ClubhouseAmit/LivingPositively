import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/logger_service.dart';

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

  static Future<bool> hasPermission() async {
    final settings =
        await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) {
      _log('Already initialized, skipping.');
      return;
    }
    _isInitialized = true;
    _log('Initializing...');
    _log("Asking permission");
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _log("finished Asking permission");
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

    final uid = GetIt.instance<FirebaseAuth>().currentUser?.uid;
    final token = await FirebaseMessaging.instance.getToken();

    _log('=== FCM Ready ===');
    _log('UID       : $uid');
    _log('FCM Token : $token');
    _log('=================');

    if (uid != null && token != null) await _saveTokenToFirestore(uid, token);

    _setupForegroundHandler();
    _setupOnMessageOpenedApp();

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      final uid = GetIt.instance<FirebaseAuth>().currentUser?.uid;
      if (uid != null) {
        _log('FCM token refreshed: $newToken');
        _saveTokenToFirestore(uid, newToken);
      }
    });

    _log('Initialization complete.');
  }

  // Called after a successful sign-in so the new UID is stored with its FCM token.
  static Future<void> onUserSignedIn() async {
    if (kIsWeb) return;
    final uid = GetIt.instance<FirebaseAuth>().currentUser?.uid;
    final token = await FirebaseMessaging.instance.getToken();
    if (uid != null && token != null) {
      _log('Saving token after sign-in for $uid');
      await _saveTokenToFirestore(uid, token);
    }
  }

  static Future<void> _saveTokenToFirestore(
      String deviceId, String token) async {
    _log('Saving token to Firestore for device $deviceId...');
    try {
      await FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
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
      _log(
          'Foreground message received — title: "$title", body: "$body", data: ${message.data}');
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
    _log(
        'App launched from terminated state via notification — data: ${message.data}');
    _handleNotificationTap(message);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    _log('Handling notification tap — navigating to root.');
    final navigatorKey = GetIt.instance<GlobalKey<NavigatorState>>();
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
