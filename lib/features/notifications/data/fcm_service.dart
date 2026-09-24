import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, visibleForTesting;
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/notifications/data/device_token_store.dart';
import 'package:mazilon/features/notifications/data/fcm_message_listener.dart';
import 'package:mazilon/features/notifications/data/local_notification_service.dart';
import 'package:mazilon/features/notifications/data/notification_error_reporter.dart';
import 'package:mazilon/features/notifications/data/notification_platform_policy.dart';

class FcmService {
  static bool _isInitialized = false;
  static bool _listenersRegistered = false;
  static Future<void>? _initialization;
  // This changes only through the test reset hook. It prevents a delayed
  // platform fake from changing the state of the next test's initialization.
  static int _testResetGeneration = 0;

  @visibleForTesting
  static Future<NotificationSettings> Function()?
  debugRequestPermissionOverride;
  @visibleForTesting
  static Future<NotificationSettings> Function()?
  debugGetNotificationSettingsOverride;
  @visibleForTesting
  static Future<void> Function()? debugInitializeLocalNotificationsOverride;
  @visibleForTesting
  static Future<void> Function(int notificationId)?
  debugCancelLegacyLocalNotificationOverride;
  @visibleForTesting
  static Future<void> Function()?
  debugCancelAllLegacyLocalNotificationsOverride;
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
  static Future<RemoteMessage?> Function()? debugGetInitialMessageOverride;

  /// UI-owned action invoked when a notification is opened.
  static void Function()? onNotificationTap;

  @visibleForTesting
  static void resetForTesting() {
    _testResetGeneration++;
    _isInitialized = false;
    _listenersRegistered = false;
    _initialization = null;
    debugRequestPermissionOverride = null;
    debugGetNotificationSettingsOverride = null;
    debugInitializeLocalNotificationsOverride = null;
    debugCancelLegacyLocalNotificationOverride = null;
    debugCancelAllLegacyLocalNotificationsOverride = null;
    debugGetApnsTokenOverride = null;
    debugGetTokenOverride = null;
    debugGetCurrentUserIdOverride = null;
    debugSaveTokenOverride = null;
    debugRegisterListenersOverride = null;
    debugGetInitialMessageOverride = null;
    onNotificationTap = null;
  }

  static void _log(String message) {
    debugPrint('[FcmService] $message');
  }

  static bool supportsReminderSettings({
    bool? isWebOverride,
    TargetPlatform? platformOverride,
  }) => NotificationPlatformPolicy.supportsReminders(
    isWebOverride: isWebOverride,
    platformOverride: platformOverride,
  );

  static Future<void> cancelLegacyLocalNotification(int notificationId) async {
    final override = debugCancelLegacyLocalNotificationOverride;
    if (override != null) {
      await override(notificationId);
      return;
    }
    if (!supportsReminderSettings()) return;
    await LocalNotificationService.cancelLegacy(notificationId);
  }

  static Future<void> cancelAllLegacyLocalNotifications() async {
    final override = debugCancelAllLegacyLocalNotificationsOverride;
    if (override != null) {
      await override();
      return;
    }
    if (!supportsReminderSettings() ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    await LocalNotificationService.cancelAllLegacy();
  }

  static Future<bool> hasPermission() async {
    try {
      final settings =
          await (debugGetNotificationSettingsOverride ??
              FirebaseMessaging.instance.getNotificationSettings)();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Whether the OS can still present its initial notification prompt.
  static Future<bool> canRequestPermission() async {
    try {
      final settings =
          await (debugGetNotificationSettingsOverride ??
              FirebaseMessaging.instance.getNotificationSettings)();
      return settings.authorizationStatus == AuthorizationStatus.notDetermined;
    } catch (_) {
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

    return _startInitialization(requestPermission: false);
  }

  static void onAppResumed() {
    unawaited(initialize());
  }

  static Future<bool> requestPermissionAndInitialize() async {
    if (!supportsReminderSettings()) return false;
    if (_isInitialized) {
      if (await hasPermission()) return true;
      // The user can revoke notification permission while the app is in the
      // background. Do not report a stale successful initialization.
      _isInitialized = false;
    }
    final pendingInitialization = _initialization;
    if (pendingInitialization != null) {
      await pendingInitialization;
      if (_isInitialized) return true;
    }
    final initialization = _startInitialization(requestPermission: true);
    await initialization;
    return _isInitialized;
  }

  static Future<void> _startInitialization({required bool requestPermission}) {
    final resetGeneration = _testResetGeneration;
    late final Future<void> initialization;
    initialization =
        _initializeWithReporting(
          requestPermission: requestPermission,
          resetGeneration: resetGeneration,
        ).whenComplete(() {
          if (identical(_initialization, initialization)) {
            _initialization = null;
          }
        });
    _initialization = initialization;
    return initialization;
  }

  static Future<void> _initializeWithReporting({
    required bool requestPermission,
    required int resetGeneration,
  }) async {
    try {
      final platformReady = await _initializeOnce(
        requestPermission: requestPermission,
        resetGeneration: resetGeneration,
      );
      if (platformReady && resetGeneration == _testResetGeneration) {
        _isInitialized = true;
      }
    } catch (error, stackTrace) {
      _reportFailure(error, stackTrace);
    }
  }

  static Future<bool> _initializeOnce({
    required bool requestPermission,
    required int resetGeneration,
  }) async {
    _log('Initializing...');
    final settings = requestPermission
        ? await _requestPermission()
        : await (debugGetNotificationSettingsOverride ??
              FirebaseMessaging.instance.getNotificationSettings)();
    _log('Permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      _log('Permission denied — aborting initialization.');
      return false;
    }
    if (resetGeneration != _testResetGeneration) return false;

    await (debugInitializeLocalNotificationsOverride ??
        _initializeLocalNotifications)();
    _log('Local notifications initialized.');
    if (resetGeneration != _testResetGeneration) return false;

    final tokenResult = await _getTokenWhenPlatformReady();
    if (!tokenResult.isPlatformReady) {
      return false;
    }
    if (resetGeneration != _testResetGeneration) return false;
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

  static Future<NotificationSettings> _requestPermission() async {
    _log('Asking permission');
    final settings =
        await (debugRequestPermissionOverride ??
            () => FirebaseMessaging.instance.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            ))();
    _log('Finished asking permission');
    return settings;
  }

  static Future<void> _initializeLocalNotifications() =>
      LocalNotificationService.initialize();

  // Called after a successful sign-in so the new UID is stored with its FCM token.
  static Future<void> onUserSignedIn() async {
    if (!supportsReminderSettings()) return;
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) return;
    }
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
      _isInitialized = false;
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
    final registerListeners = debugRegisterListenersOverride;
    if (registerListeners != null) {
      registerListeners();
      if (debugGetInitialMessageOverride != null) {
        _setupInitialMessage();
      }
    } else {
      _registerMessagingListeners();
    }
    _listenersRegistered = true;
  }

  static void _registerMessagingListeners() {
    FcmMessageListener.register(
      onTokenRefresh: _handleTokenRefresh,
      onOpened: handleInitialMessage,
      onFailure: _reportFailure,
    );
    _setupInitialMessage();
  }

  static void _setupInitialMessage() {
    unawaited(
      FcmMessageListener.handleInitialMessage(
        getInitialMessage:
            debugGetInitialMessageOverride ??
            FirebaseMessaging.instance.getInitialMessage,
        onOpened: handleInitialMessage,
        onFailure: _reportFailure,
      ),
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

  static void _reportFailure(Object error, StackTrace stackTrace) =>
      NotificationErrorReporter.report(error, stackTrace);

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
      await DeviceTokenStore.save(deviceId, token);
      _log('Token saved to Firestore successfully.');
      return true;
    } catch (error, stackTrace) {
      _log('Failed to save token to Firestore: $error');
      _reportFailure(error, stackTrace);
      return false;
    }
  }

  static void handleInitialMessage(RemoteMessage message) {
    _log(
      'App launched from terminated state via notification — data: ${message.data}',
    );
    _handleNotificationTap(message);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    onNotificationTap?.call();
  }
}
