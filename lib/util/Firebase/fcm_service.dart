import 'dart:io';

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

    final uid = await _getOrCreateUid();
    final token = await FirebaseMessaging.instance.getToken();

    final idToken = await GetIt.instance<FirebaseAuth>().currentUser?.getIdToken();

    _log('=== FCM Ready ===');
    _log('UID       : $uid');
    _log('FCM Token : $token');
    _log('ID Token  : $idToken');
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

  static Future<String?> _getOrCreateUid() async {
    try {
      final auth = GetIt.instance<FirebaseAuth>();
      if (auth.currentUser == null) {
        _log('No existing auth user — signing in anonymously...');
        await auth.signInAnonymously();
      } else {
        _log('Existing anonymous user: ${auth.currentUser!.uid}');
      }
      return auth.currentUser?.uid;
    } catch (e) {
      _log('Anonymous sign-in failed (offline?): $e');
      return null;
    }
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
