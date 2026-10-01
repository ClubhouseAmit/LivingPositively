import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/features/auth/data/auth_repository.dart';
import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/pages/notification_page.dart';
import 'package:mazilon/features/notifications/ui/notification_toggle_card.dart';
import 'package:mazilon/features/notifications/ui/reminder_item_card.dart';
import 'package:mazilon/features/notifications/ui/reminder_switch.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/fcm_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';

import '../auth/auth_page_interactions_test.mocks.dart';
import '../helpers/widget_test_scaffold.dart';

final class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

final class _MockUserCredential extends Mock implements UserCredential {}

final class _FailingActivationMemory extends FakePersistentMemoryService {
  _FailingActivationMemory() {
    onPersist = (key, _, _) {
      if (key == 'notificationPreferences') {
        throw StateError('notification storage unavailable');
      }
    };
  }
}

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
    if (apnsToken case final pending? when !pending.isCompleted) {
      pending.complete(null);
      await Future<void>.delayed(Duration.zero);
    }
    AuthService.debugSignInWithEmailOverride = null;
    FcmService.resetForTesting();
    FcmScheduledNotificationService.resetForTesting();
    resetTestServices();
  });

  group('NotificationPage authentication', () {
    testWidgets('should show reminders immediately after sign-in', (
      tester,
    ) async {
      user = UserInformation(gender: 'other', localeName: 'en');
      final firebaseUser = MockUser();
      final credential = _MockUserCredential();
      final firebaseAuth = _MockFirebaseAuth();
      when(credential.user).thenReturn(firebaseUser);
      when(firebaseUser.uid).thenReturn('uid-123');
      when(firebaseUser.email).thenReturn('person@example.com');
      when(firebaseUser.displayName).thenReturn('Person');
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.getIdToken()).thenAnswer((_) async => 'id-token');
      when(firebaseAuth.currentUser).thenReturn(firebaseUser);
      GetIt.instance
        ..registerSingleton<FirebaseFirestore>(FakeFirebaseFirestore())
        ..registerSingleton<FirebaseAuth>(firebaseAuth);
      AuthService.debugSignInWithEmailOverride = (_, _) async => credential;
      FcmScheduledNotificationService
          .debugLegacyDefaultReminderMigrationOverride = (
        _,
      ) async {};
      FcmScheduledNotificationService.debugPostOverride =
          (
            _, {
            headers,
            body,
            encoding,
          }) async => http.Response(
            '{"schedule":{"hour":9,"minute":30},"mutationVersion":1}',
            200,
          );
      FcmService.debugGetNotificationSettingsOverride = () async =>
          _settings(AuthorizationStatus.authorized);
      FcmService.debugGetApnsTokenOverride = () async => 'apns-token';

      await _onPlatform(TargetPlatform.iOS, () async {
        await pumpWithProviders(
          tester,
          const NotificationPage(),
          userInformation: user,
          surfaceSize: const Size(1024, 1800),
        );
        await tester.tap(find.widgetWithText(Button, 'Sign In'));
        await tester.pumpAndSettle();
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'person@example.com');
        await tester.enterText(fields.at(1), 'secret');
        await tester.tap(find.widgetWithText(Button, 'Sign In'));
        await tester.pumpAndSettle();

        final repository = NotificationRepository.forService(user.service);
        expect(find.byType(NotificationToggleCard), findsOneWidget);
        expect(repository.isActiveAccount('uid-123'), isTrue);
        expect(repository.getPreference('default')?.hour, 9);
        expect(repository.getPreference('default')?.minute, 30);
      });
    });

    testWidgets('should leave loading state when account activation fails', (
      tester,
    ) async {
      final memory = _FailingActivationMemory();
      user = UserInformation(
        service: memory,
        loggedIn: true,
        userId: 'uid-123',
        gender: 'other',
        localeName: 'en',
      );
      NotificationRepository.forService(memory).restoreJson('{}');
      FcmService.debugGetNotificationSettingsOverride = () async =>
          _settings(AuthorizationStatus.authorized);

      await _onPlatform(TargetPlatform.iOS, () async {
        await pumpWithProviders(
          tester,
          const NotificationPage(),
          userInformation: user,
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(NotificationToggleCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
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
        expect(
          tester
              .widget<ReminderSwitch>(find.byType(ReminderSwitch).first)
              .value,
          isFalse,
        );

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

  testWidgets('NotificationPage lists every quick reminder', (tester) async {
    await _onPlatform(TargetPlatform.iOS, () async {
      FcmService.debugGetNotificationSettingsOverride = () async =>
          _settings(AuthorizationStatus.denied);
      await pumpWithProviders(
        tester,
        const NotificationPage(),
        userInformation: user,
      );
      await tester.pump();

      expect(find.byType(ReminderItemCard), findsNWidgets(11));
      expect(find.text('Play Music'), findsOneWidget);
      expect(find.text('Connect with a Friend'), findsOneWidget);
    });
  });

  testWidgets('NotificationPage fits a narrow phone in English', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _onPlatform(TargetPlatform.iOS, () async {
      FcmService.debugGetNotificationSettingsOverride = () async =>
          _settings(AuthorizationStatus.denied);
      await pumpWithProviders(
        tester,
        const NotificationPage(),
        userInformation: user,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
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
