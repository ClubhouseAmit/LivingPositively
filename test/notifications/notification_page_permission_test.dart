import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/notifications/notification_page.dart';
import 'package:mazilon/pages/notifications/notification_toggle_card.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

NotificationSettings _settings(AuthorizationStatus status) {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;
  Completer<String?>? apnsToken;

  setUp(() {
    registerTestServices(locale: 'en');
    FcmService.resetForTesting();
    user = UserInformation(loggedIn: true, gender: 'other', localeName: 'en');
    FcmService.debugInitializeLocalNotificationsOverride = () async {};
    FcmService.debugGetCurrentUserIdOverride = () => null;
    FcmService.debugGetTokenOverride = () async => 'fcm-token';
    FcmService.debugRegisterListenersOverride = () {};
  });

  tearDown(() async {
    if (apnsToken case final pending? when !pending.isCompleted) {
      pending.complete(null);
      await Future<void>.delayed(Duration.zero);
    }
    FcmService.resetForTesting();
    resetTestServices();
  });

  testWidgets(
    'NotificationPage should show reminder controls before iOS token setup completes',
    (tester) async {
      await _onPlatform(TargetPlatform.iOS, () async {
        apnsToken = Completer<String?>();
        FcmService.debugGetNotificationSettingsOverride = () async =>
            _settings(AuthorizationStatus.authorized);
        FcmService.debugGetApnsTokenOverride = () => apnsToken!.future;

        await pumpWithProviders(
          tester,
          const NotificationPage(),
          userInformation: user,
        );
        await tester.pump();

        expect(apnsToken!.isCompleted, isFalse);
        expect(find.byType(NotificationToggleCard), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        apnsToken!.complete(null);
        await tester.pump();
        FcmService.resetForTesting();
      });
    },
  );

  testWidgets(
    'NotificationPage should disable permission request after the OS prompt is exhausted',
    (tester) async {
      await _onPlatform(TargetPlatform.iOS, () async {
        FcmService.debugGetNotificationSettingsOverride = () async =>
            _settings(AuthorizationStatus.denied);

        await pumpWithProviders(
          tester,
          const NotificationPage(),
          userInformation: user,
        );
        await tester.pump();

        final enableButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(enableButton.onPressed, isNull);
      });
    },
  );

  testWidgets(
    'NotificationPage should expose remote reminder cancellation when permission is denied',
    (tester) async {
      await _onPlatform(TargetPlatform.iOS, () async {
        FcmService.debugGetNotificationSettingsOverride = () async =>
            _settings(AuthorizationStatus.denied);

        await pumpWithProviders(
          tester,
          const NotificationPage(),
          userInformation: user,
        );
        await tester.pump();

        final cancelLabel = find.text('Cancel current notification');
        expect(cancelLabel, findsOneWidget);
        final cancelButton = tester.widget<OutlinedButton>(
          find.ancestor(of: cancelLabel, matching: find.byType(OutlinedButton)),
        );
        expect(cancelButton.onPressed, isNotNull);
      });
    },
  );
}

Future<T> _onPlatform<T>(
  TargetPlatform platform,
  Future<T> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}
