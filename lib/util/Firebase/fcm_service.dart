import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/logger_service.dart';

class FcmService {
  static bool _isInitialized = false;
  static bool _listenersRegistered = false;
  static Future<void>? _initialization;

  @visibleForTesting
  static Future<NotificationSettings> Function()?
  debugRequestPermissionOverride;

  @visibleForTesting
  static Future<void> Function()? debugInitializeLocalNotificationsOverride;

  @visibleForTesting
  static Future<String?> Function()? debugGetApnsTokenOverride;

  @visibleForTesting
  static Future<String?> Function()? debugGetTokenOverride;

  @visibleForTesting
  static String? Function()? debugGetCurrentUserIdOverride;

  @visibleForTesting
  static Future<bool> Function(String deviceId, String token)?
  debugSaveTokenOverride;

  @visibleForTesting
  static void Function()? debugRegisterListenersOverride;

  @visibleForTesting
  static void resetForTesting() {
    _isInitialized = false;
    _listenersRegistered = false;
    _initialization = null;
    debugRequestPermissionOverride = null;
    debugInitializeLocalNotificationsOverride = null;
    debugGetApnsTokenOverride = null;
    debugGetTokenOverride = null;
    debugGetCurrentUserIdOverride = null;
    debugSaveTokenOverride = null;
    debugRegisterListenersOverride = null;
  }

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

  static bool supportsReminderSettings({
    bool? isWebOverride,
    TargetPlatform? platformOverride,
  }) {
    final isWeb = isWebOverride ?? kIsWeb;
    if (isWeb) {
      return false;
    }
    final platform = platformOverride ?? defaultTargetPlatform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  static Future<bool> hasPermission() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } on FirebaseException {
      return false;
    }
  }

  static Future<void> initialize() {
    if (!supportsReminderSettings()) return Future<void>.value();
    if (_isInitialized) {
      _log('Already initialized, skipping.');
      return Future<void>.value();
    }
    final pendingInitialization = _initialization;
    if (pendingInitialization != null) {
      return pendingInitialization;
    }

    final initialization = _initializeWithReporting();
    _initialization = initialization;
    return initialization;
  }

  static void onAppResumed() {
    unawaited(initialize());
  }

  static Future<void> _initializeWithReporting() async {
    try {
      final platformReady = await _initializeOnce();
      if (platformReady) {
        _isInitialized = true;
      }
    } catch (error, stackTrace) {
      _reportFailure(error, stackTrace);
    } finally {
      _initialization = null;
    }
  }

  static Future<bool> _initializeOnce() async {
    _log('Initializing...');
    _log('Asking permission');
    final settings =
        await (debugRequestPermissionOverride ??
            () => FirebaseMessaging.instance.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            ))();
    _log('Finished asking permission');
    _log('Permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _log('Permission denied — aborting initialization.');
      return false;
    }

    await (debugInitializeLocalNotificationsOverride ??
        () async {
          await _localNotifications.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(),
            ),
          );
        })();
    _log('Local notifications initialized.');

    final tokenResult = await _getTokenWhenPlatformReady();
    if (!tokenResult.isPlatformReady) {
      return false;
    }
    final uid = _currentUserId();
    final token = tokenResult.token;

    _log('=== FCM Ready ===');
    _log('UID       : $uid');
    _log('FCM token available: ${token != null}');
    _log('=================');

    _registerListenersOnce();

    if (token == null) {
      _log('FCM token is not ready; initialization will be retried.');
      return false;
    }

    if (uid != null && !await _saveTokenToFirestore(uid, token)) {
      return false;
    }

    _log('Initialization complete.');
    return true;
  }

  // Called after a successful sign-in so the new UID is stored with its FCM token.
  static Future<void> onUserSignedIn() async {
    if (!supportsReminderSettings()) return;
    try {
      final uid = _currentUserId();
      final tokenResult = await _getTokenWhenPlatformReady();
      final token = tokenResult.token;
      if (!tokenResult.isPlatformReady || token == null) {
        _isInitialized = false;
        return;
      }
      if (uid != null) {
        _log('Saving token after sign-in for $uid');
        if (!await _saveTokenToFirestore(uid, token)) {
          _isInitialized = false;
        }
      }
    } catch (error, stackTrace) {
      _reportFailure(error, stackTrace);
    }
  }

  static Future<({bool isPlatformReady, String? token})>
  _getTokenWhenPlatformReady() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken =
          await (debugGetApnsTokenOverride ??
              FirebaseMessaging.instance.getAPNSToken)();
      if (apnsToken == null) {
        _log('APNs token is not ready; deferring the FCM token request.');
        return (isPlatformReady: false, token: null);
      }
    }

    final token =
        await (debugGetTokenOverride ?? FirebaseMessaging.instance.getToken)();
    return (isPlatformReady: true, token: token);
  }

  static String? _currentUserId() {
    final override = debugGetCurrentUserIdOverride;
    if (override != null) return override();
    if (!GetIt.instance.isRegistered<FirebaseAuth>()) return null;
    return GetIt.instance<FirebaseAuth>().currentUser?.uid;
  }

  static void _registerListenersOnce() {
    if (_listenersRegistered) return;
    (debugRegisterListenersOverride ?? _registerMessagingListeners)();
    _listenersRegistered = true;
  }

  static void _registerMessagingListeners() {
    _setupForegroundHandler();
    _setupOnMessageOpenedApp();

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) => unawaited(_handleTokenRefresh(newToken)),
    );
  }

  static Future<void> _handleTokenRefresh(String newToken) async {
    try {
      final uid = _currentUserId();
      if (uid == null) return;
      _log('FCM token refreshed.');
      if (!await _saveTokenToFirestore(uid, newToken)) {
        _isInitialized = false;
      }
    } catch (error, stackTrace) {
      _isInitialized = false;
      _reportFailure(error, stackTrace);
    }
  }

  static void _reportFailure(Object error, StackTrace stackTrace) {
    _log('FCM operation failed: $error');
    if (!GetIt.instance.isRegistered<IncidentLoggerService>()) return;
    try {
      unawaited(
        Future<void>.sync(
          () => GetIt.instance<IncidentLoggerService>().captureLog(
            error,
            stackTrace: stackTrace,
          ),
        ).catchError((Object loggerError, StackTrace _) {
          _log('Failed to report FCM operation: $loggerError');
        }),
      );
    } catch (loggerError) {
      _log('Failed to report FCM operation: $loggerError');
    }
  }

  static Future<bool> _saveTokenToFirestore(
    String deviceId,
    String token,
  ) async {
    _log('Saving token to Firestore for device $deviceId...');
    try {
      final override = debugSaveTokenOverride;
      if (override != null) {
        return await override(deviceId, token);
      }
      await FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
        'fcmToken': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log('Token saved to Firestore successfully.');
      return true;
    } catch (error, stackTrace) {
      _log('Failed to save token to Firestore: $error');
      try {
        GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      } catch (_) {}
      return false;
    }
  }

  static void _setupForegroundHandler() {
    _log('Setting up foreground message handler.');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Living Positively';
      final body = message.notification?.body ?? '';
      _log(
        'Foreground message received — title: "$title", body: "$body", data: ${message.data}',
      );
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
      'App launched from terminated state via notification — data: ${message.data}',
    );
    _handleNotificationTap(message);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    _log('Handling notification tap — navigating to root.');
    final navigatorKey = GetIt.instance<GlobalKey<NavigatorState>>();
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
