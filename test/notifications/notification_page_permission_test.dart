import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/pages/notification_page.dart';
import 'package:mazilon/features/notifications/ui/notification_toggle_card.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/notifications/data/fcm_service.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';
import '../Firebase/firebase_auth_service_test.mocks.dart';

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
    FcmScheduledNotificationService.resetForTesting();
    user = UserInformation(loggedIn: true, gender: 'other', localeName: 'en');
    FcmService.debugInitializeLocalNotificationsOverride = () async {};
    FcmService.debugGetCurrentUserIdOverride = () => null;
    FcmService.debugGetTokenOverride = () async => 'fcm-token';
    FcmService.debugRegisterListenersOverride = () {};
  });

  tearDown(() async {
    FcmScheduledNotificationService.resetForTesting();
    if (apnsToken case final pending? when !pending.isCompleted) {
      pending.complete(null);
      await Future<void>.delayed(Duration.zero);
    }
    FcmService.resetForTesting();
    resetTestServices();
  });

  group('NotificationPage push registration', () {
    for (final changingTime in [false, true]) {
      testWidgets(
        'should reject ${changingTime ? 'time changes' : 'enabling'} '
        'when iOS push registration is unavailable',
        (tester) async {
          await _onPlatform(TargetPlatform.iOS, () async {
            final auth = MockFirebaseAuth();
            final firebaseUser = MockUser();
            when(auth.currentUser).thenReturn(firebaseUser);
            when(firebaseUser.isAnonymous).thenReturn(false);
            when(firebaseUser.getIdToken()).thenAnswer((_) async => 'id-token');
            GetIt.instance.registerSingleton<FirebaseAuth>(auth);
            FcmService.debugGetApnsTokenOverride = () async => null;
            FcmService.debugGetNotificationSettingsOverride = () async =>
                _settings(AuthorizationStatus.authorized);
            FcmService.debugRequestPermissionOverride = () async =>
                _settings(AuthorizationStatus.authorized);
            final requests = <String>[];
            FcmScheduledNotificationService.debugPostOverride =
                (url, {headers, body, encoding}) async {
                  requests.add(url.path);
                  return http.Response(
                    url.path.endsWith('/getNotificationMutationVersion')
                        ? '{"mutationVersion":0}'
                        : '{"mutationVersion":1}',
                    200,
                  );
                };
            final repository = NotificationRepository.forService(user.service);
            if (changingTime) {
              repository.restorePreferences({
                'default': const NotificationPreference(hour: 17, minute: 36),
              });
            }
            await pumpWithProviders(
              tester,
              const NotificationPage(),
              userInformation: user,
            );
            await tester.pump();
            final card = tester.widget<NotificationToggleCard>(
              find.byType(NotificationToggleCard),
            );
            final applied = changingTime
                ? await card.onTimeSelected!(
                    const TimeOfDay(hour: 18, minute: 0),
                  )
                : await card.onToggle!(true);
            await tester.pump();
            expect(applied, isFalse);
            expect(requests, isEmpty);
            expect(find.text('Something went wrong.'), findsOneWidget);
            expect(
              repository.getPreference('default')?.hour,
              changingTime ? 17 : null,
            );
            FcmService.debugGetApnsTokenOverride = () async => 'apns-token';
            final retried = changingTime
                ? await card.onTimeSelected!(
                    const TimeOfDay(hour: 18, minute: 0),
                  )
                : await card.onToggle!(true);
            expect(retried, isTrue);
            expect(requests, [
              '/getNotificationMutationVersion',
              '/registerNotification',
            ]);
            expect(
              repository.getPreference('default')?.hour,
              changingTime ? 18 : 8,
            );
          });
        },
      );
    }
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

        final enableButton = tester.widget<Button>(find.byType(Button).first);
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
        final cancelButton = tester.widget<Button>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Button &&
                widget.label == 'Cancel current notification',
          ),
        );
        expect(cancelButton.onPressed, isNotNull);
      });
    },
  );

  testWidgets(
    'NotificationPage should show blocked settings instead of time picker for an existing reminder',
    (tester) async {
      await _onPlatform(TargetPlatform.android, () async {
        NotificationRepository.forService(user.service).restorePreferences({
          'default': const NotificationPreference(hour: 8, minute: 30),
        });
        FcmService.debugGetNotificationSettingsOverride = () async =>
            _settings(AuthorizationStatus.denied);

        await pumpWithProviders(
          tester,
          const NotificationPage(),
          userInformation: user,
        );
        await tester.pump();

        expect(find.text('Notifications Blocked'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);
        expect(find.text('Cancel current notification'), findsOneWidget);
        expect(find.byType(NotificationToggleCard), findsNothing);
      });
    },
  );

  testWidgets(
    'NotificationPage should report failed cancellation when permission is denied',
    (tester) async {
      await _onPlatform(TargetPlatform.android, () async {
        NotificationRepository.forService(user.service).restorePreferences({
          'default': const NotificationPreference(hour: 8, minute: 30),
        });
        FcmService.debugGetNotificationSettingsOverride = () async =>
            _settings(AuthorizationStatus.denied);

        await pumpWithProviders(
          tester,
          const NotificationPage(),
          userInformation: user,
        );
        await tester.pump();
        await tester.tap(find.text('Cancel current notification'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Something went wrong.'), findsOneWidget);
        expect(
          NotificationRepository.forService(user.service).getPreference(
            'default',
          ),
          isNotNull,
        );
      });
    },
  );

  testWidgets(
    'NotificationPage should show blocked settings when permission is revoked before a time change',
    (tester) async {
      await _onPlatform(TargetPlatform.android, () async {
        NotificationRepository.forService(user.service).restorePreferences({
          'default': const NotificationPreference(hour: 8, minute: 30),
        });
        var permission = AuthorizationStatus.authorized;
        FcmService.debugGetNotificationSettingsOverride = () async =>
            _settings(permission);

        await pumpWithProviders(
          tester,
          const NotificationPage(),
          userInformation: user,
        );
        await tester.pump();
        final card = tester.widget<NotificationToggleCard>(
          find.byType(NotificationToggleCard),
        );

        permission = AuthorizationStatus.denied;
        expect(
          await card.onTimeSelected!(const TimeOfDay(hour: 9, minute: 15)),
          isFalse,
        );
        await tester.pump();

        expect(find.text('Notifications Blocked'), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);
        expect(find.text('Something went wrong.'), findsNothing);
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
