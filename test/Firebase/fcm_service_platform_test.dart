import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(FcmService.resetForTesting);

  tearDown(() {
    FcmService.resetForTesting();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'reminder initialization is a no-op on unsupported native platforms',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await expectLater(FcmService.initialize(), completes);
      await expectLater(FcmService.onUserSignedIn(), completes);
    },
  );

  test('reminder support matrix includes only Android and iOS', () {
    for (final platform in TargetPlatform.values) {
      expect(
        FcmService.supportsReminderSettings(
          isWebOverride: false,
          platformOverride: platform,
        ),
        platform == TargetPlatform.android || platform == TargetPlatform.iOS,
        reason: 'unexpected support result for $platform',
      );
    }
    expect(
      FcmService.supportsReminderSettings(
        isWebOverride: true,
        platformOverride: TargetPlatform.android,
      ),
      isFalse,
    );
  });

  test('failed initialization can retry and listeners register once', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var permissionAttempts = 0;
    var listenerRegistrations = 0;
    FcmService.debugRequestPermissionOverride = () async {
      permissionAttempts++;
      if (permissionAttempts == 1) {
        throw StateError('messaging unavailable');
      }
      return _notificationSettings(AuthorizationStatus.authorized);
    };
    FcmService.debugInitializeLocalNotificationsOverride = () async {};
    FcmService.debugGetCurrentUserIdOverride = () => null;
    FcmService.debugGetTokenOverride = () async => null;
    FcmService.debugRegisterListenersOverride = () {
      listenerRegistrations++;
    };

    await expectLater(FcmService.initialize(), completes);
    await expectLater(FcmService.initialize(), completes);
    await expectLater(FcmService.initialize(), completes);

    expect(permissionAttempts, 2);
    expect(listenerRegistrations, 1);
  });

  test('concurrent initialization callers share one attempt', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final permission = Completer<NotificationSettings>();
    var permissionAttempts = 0;
    FcmService.debugRequestPermissionOverride = () {
      permissionAttempts++;
      return permission.future;
    };
    FcmService.debugInitializeLocalNotificationsOverride = () async {};
    FcmService.debugGetCurrentUserIdOverride = () => null;
    FcmService.debugGetTokenOverride = () async => null;
    FcmService.debugRegisterListenersOverride = () {};

    final first = FcmService.initialize();
    final second = FcmService.initialize();

    expect(permissionAttempts, 1);

    permission.complete(_notificationSettings(AuthorizationStatus.authorized));
    await Future.wait([first, second]);
  });

  test('iOS does not request an FCM token until APNs is ready', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var fcmTokenRequests = 0;
    _configureSuccessfulInitialization(
      apnsToken: null,
      getToken: () async {
        fcmTokenRequests++;
        return 'fcm-token';
      },
    );

    await expectLater(FcmService.initialize(), completes);

    expect(fcmTokenRequests, 0);
  });

  test('iOS requests an FCM token after APNs is ready', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var fcmTokenRequests = 0;
    _configureSuccessfulInitialization(
      apnsToken: 'apns-token',
      getToken: () async {
        fcmTokenRequests++;
        return 'fcm-token';
      },
    );

    await expectLater(FcmService.initialize(), completes);

    expect(fcmTokenRequests, 1);
  });

  test('Android requests an FCM token without querying APNs', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var apnsTokenRequests = 0;
    var fcmTokenRequests = 0;
    _configureSuccessfulInitialization(
      apnsToken: 'unused',
      getApnsToken: () async {
        apnsTokenRequests++;
        return 'unused';
      },
      getToken: () async {
        fcmTokenRequests++;
        return 'fcm-token';
      },
    );

    await expectLater(FcmService.initialize(), completes);

    expect(apnsTokenRequests, 0);
    expect(fcmTokenRequests, 1);
  });

  test('post-sign-in token refresh also waits for APNs on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    var fcmTokenRequests = 0;
    FcmService.debugGetCurrentUserIdOverride = () => 'uid-123';
    FcmService.debugGetApnsTokenOverride = () async => null;
    FcmService.debugGetTokenOverride = () async {
      fcmTokenRequests++;
      return 'fcm-token';
    };

    await expectLater(FcmService.onUserSignedIn(), completes);

    expect(fcmTokenRequests, 0);
  });
}

void _configureSuccessfulInitialization({
  required String? apnsToken,
  Future<String?> Function()? getApnsToken,
  required Future<String?> Function() getToken,
}) {
  FcmService.debugRequestPermissionOverride = () async =>
      _notificationSettings(AuthorizationStatus.authorized);
  FcmService.debugInitializeLocalNotificationsOverride = () async {};
  FcmService.debugGetCurrentUserIdOverride = () => null;
  FcmService.debugGetApnsTokenOverride = getApnsToken ?? () async => apnsToken;
  FcmService.debugGetTokenOverride = getToken;
  FcmService.debugRegisterListenersOverride = () {};
}

NotificationSettings _notificationSettings(AuthorizationStatus status) {
  return NotificationSettings(
    alert: AppleNotificationSetting.enabled,
    announcement: AppleNotificationSetting.disabled,
    authorizationStatus: status,
    badge: AppleNotificationSetting.enabled,
    carPlay: AppleNotificationSetting.disabled,
    criticalAlert: AppleNotificationSetting.disabled,
    lockScreen: AppleNotificationSetting.enabled,
    notificationCenter: AppleNotificationSetting.enabled,
    showPreviews: AppleShowPreviewSetting.always,
    sound: AppleNotificationSetting.enabled,
    timeSensitive: AppleNotificationSetting.disabled,
    providesAppNotificationSettings: AppleNotificationSetting.disabled,
  );
}
