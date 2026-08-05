import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(FcmService.resetForTesting);
  tearDown(FcmService.resetForTesting);

  testWidgets('iOS initialization defers FCM until APNs is ready', (_) async {
    expect(
      defaultTargetPlatform,
      TargetPlatform.iOS,
      reason: 'This integration target must execute on an iOS simulator.',
    );
    expect(debugDefaultTargetPlatformOverride, isNull);

    var permissionRequests = 0;
    var apnsTokenRequests = 0;
    var fcmTokenRequests = 0;
    var listenerRegistrations = 0;

    FcmService.debugRequestPermissionOverride = () async {
      permissionRequests++;
      return _authorizedNotificationSettings();
    };
    // Intentionally leave debugInitializeLocalNotificationsOverride unset.
    // This exercises the registered flutter_local_notifications iOS channel.
    FcmService.debugGetApnsTokenOverride = () async {
      apnsTokenRequests++;
      return null;
    };
    FcmService.debugGetTokenOverride = () async {
      fcmTokenRequests++;
      return 'unexpected-fcm-token';
    };
    FcmService.debugGetCurrentUserIdOverride = () => null;
    FcmService.debugRegisterListenersOverride = () {
      listenerRegistrations++;
    };

    await expectLater(
      FcmService.initialize().timeout(const Duration(seconds: 10)),
      completes,
    );

    expect(FcmService.debugInitializeLocalNotificationsOverride, isNull);
    expect(permissionRequests, 1);
    expect(apnsTokenRequests, 1);
    expect(fcmTokenRequests, 0);
    expect(listenerRegistrations, 0);
  });
}

NotificationSettings _authorizedNotificationSettings() {
  return const NotificationSettings(
    alert: AppleNotificationSetting.enabled,
    announcement: AppleNotificationSetting.disabled,
    authorizationStatus: AuthorizationStatus.authorized,
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
