import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Widget;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/logger_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FcmService', () {
    setUp(() async {
      await GetIt.instance.reset();
      FcmService.resetForTesting();
      FcmService.debugGetNotificationSettingsOverride = () async =>
          _notificationSettings(AuthorizationStatus.authorized);
    });

    tearDown(() async {
      FcmService.resetForTesting();
      debugDefaultTargetPlatformOverride = null;
      await GetIt.instance.reset();
    });

    test(
      'should reminder initialization is a no-op on unsupported native platforms',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        await expectLater(FcmService.initialize(), completes);
        await expectLater(FcmService.onUserSignedIn(), completes);
      },
    );

    test('should reminder support matrix includes only Android and iOS', () {
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

    test(
      'should failed initialization can retry and listeners register once',
      () async {
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
        FcmService.debugGetTokenOverride = () async => 'fcm-token';
        FcmService.debugRegisterListenersOverride = () {
          listenerRegistrations++;
        };

        await expectLater(
          FcmService.requestPermissionAndInitialize(),
          completes,
        );
        await expectLater(
          FcmService.requestPermissionAndInitialize(),
          completes,
        );
        await expectLater(
          FcmService.requestPermissionAndInitialize(),
          completes,
        );

        expect(permissionAttempts, 2);
        expect(listenerRegistrations, 1);
      },
    );

    test(
      'should only an explicit reminder action requests permission',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        var permissionAttempts = 0;
        var tokenRequests = 0;
        var listenerRegistrations = 0;
        FcmService.debugGetNotificationSettingsOverride = () async =>
            _notificationSettings(AuthorizationStatus.denied);
        FcmService.debugRequestPermissionOverride = () async {
          permissionAttempts++;
          return _notificationSettings(AuthorizationStatus.authorized);
        };
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () => null;
        FcmService.debugGetTokenOverride = () async {
          tokenRequests++;
          return 'fcm-token';
        };
        FcmService.debugRegisterListenersOverride = () {
          listenerRegistrations++;
        };

        await FcmService.initialize();
        await FcmService.onUserSignedIn();
        expect(permissionAttempts, 0);

        await FcmService.requestPermissionAndInitialize();
        await FcmService.initialize();

        expect(permissionAttempts, 1);
        expect(tokenRequests, 1);
        expect(listenerRegistrations, 1);
      },
    );

    test(
      'should a reminder action rechecks permission after it was revoked',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        var permissionRequests = 0;
        var permissionIsGranted = true;
        FcmService.debugGetNotificationSettingsOverride = () async =>
            _notificationSettings(
              permissionIsGranted
                  ? AuthorizationStatus.authorized
                  : AuthorizationStatus.denied,
            );
        FcmService.debugRequestPermissionOverride = () async {
          permissionRequests++;
          return _notificationSettings(AuthorizationStatus.denied);
        };
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () => null;
        FcmService.debugGetTokenOverride = () async => 'fcm-token';
        FcmService.debugRegisterListenersOverride = () {};

        await FcmService.initialize();
        permissionIsGranted = false;

        await expectLater(
          FcmService.requestPermissionAndInitialize(),
          completion(isFalse),
        );
        expect(permissionRequests, 1);
      },
    );

    test(
      'should a null FCM token remains retryable without duplicate listeners',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        var tokenRequests = 0;
        var listenerRegistrations = 0;
        _configureSuccessfulInitialization(
          apnsToken: 'unused',
          getToken: () async {
            tokenRequests++;
            return tokenRequests == 1 ? null : 'fcm-token';
          },
        );
        FcmService.debugRegisterListenersOverride = () {
          listenerRegistrations++;
        };

        await FcmService.initialize();
        await FcmService.initialize();
        await FcmService.initialize();

        expect(tokenRequests, 2);
        expect(listenerRegistrations, 1);
      },
    );

    test(
      'should failed current-token save retries without duplicate listeners',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        var tokenRequests = 0;
        var saveAttempts = 0;
        var listenerRegistrations = 0;
        FcmService.debugRequestPermissionOverride = () async =>
            _notificationSettings(AuthorizationStatus.authorized);
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () => 'uid-123';
        FcmService.debugGetTokenOverride = () async {
          tokenRequests++;
          return 'fcm-token';
        };
        FcmService.debugSaveTokenOverride = (deviceId, token) async {
          saveAttempts++;
          return saveAttempts > 1;
        };
        FcmService.debugRegisterListenersOverride = () {
          listenerRegistrations++;
        };

        await FcmService.initialize();
        await FcmService.initialize();
        await FcmService.initialize();

        expect(tokenRequests, 2);
        expect(saveAttempts, 2);
        expect(listenerRegistrations, 1);
      },
    );

    test(
      'should concurrent initialization callers share one attempt',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final settings = Completer<NotificationSettings>();
        var settingsReads = 0;
        FcmService.debugGetNotificationSettingsOverride = () {
          settingsReads++;
          return settings.future;
        };
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () => null;
        FcmService.debugGetTokenOverride = () async => null;
        FcmService.debugRegisterListenersOverride = () {};

        final first = FcmService.initialize();
        final second = FcmService.initialize();

        expect(settingsReads, 1);

        settings.complete(
          _notificationSettings(AuthorizationStatus.authorized),
        );
        await Future.wait([first, second]);
      },
    );

    test(
      'should initial-message lookup runs once with listener registration',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        var initialMessageReads = 0;
        _configureSuccessfulInitialization(
          apnsToken: 'unused',
          getToken: () async => 'fcm-token',
        );
        FcmService.debugRegisterListenersOverride = () {};
        FcmService.debugGetInitialMessageOverride = () async {
          initialMessageReads++;
          return null;
        };

        await FcmService.initialize();
        await Future<void>.delayed(Duration.zero);
        await FcmService.initialize();

        expect(initialMessageReads, 1);
      },
    );

    test('should coalesced sign-in saves the token for the new user', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      String? uid;
      var tokenRequests = 0;
      var listenerRegistrations = 0;
      final savedTokens = <String>[];
      late Future<void> signIn;
      FcmService.debugRequestPermissionOverride = () async =>
          _notificationSettings(AuthorizationStatus.authorized);
      FcmService.debugInitializeLocalNotificationsOverride = () async {};
      FcmService.debugGetCurrentUserIdOverride = () => uid;
      FcmService.debugGetTokenOverride = () async {
        tokenRequests++;
        return 'fcm-token';
      };
      FcmService.debugSaveTokenOverride = (deviceId, token) async {
        savedTokens.add('$deviceId:$token');
        return true;
      };
      FcmService.debugRegisterListenersOverride = () {
        listenerRegistrations++;
        uid = 'uid-123';
        signIn = FcmService.onUserSignedIn();
      };

      await FcmService.initialize();
      await signIn;

      expect(tokenRequests, 2);
      expect(savedTokens, ['uid-123:fcm-token']);
      expect(listenerRegistrations, 1);
    });

    test(
      'should iOS does not request an FCM token until APNs is ready',
      () async {
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
      },
    );

    test(
      'should iOS local plugin initialization without a permission request still checks APNs',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        const channel = MethodChannel(
          'dexterous.com/flutter/local_notifications',
        );
        MethodCall? initializationCall;
        var apnsTokenRequests = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              initializationCall = call;
              return false;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null),
        );
        IOSFlutterLocalNotificationsPlugin.registerWith();
        FcmService.debugRequestPermissionOverride = () async =>
            _notificationSettings(AuthorizationStatus.authorized);
        FcmService.debugGetCurrentUserIdOverride = () => null;
        FcmService.debugGetApnsTokenOverride = () async {
          apnsTokenRequests++;
          return null;
        };
        FcmService.debugGetTokenOverride = () async => 'unexpected-token';
        FcmService.debugRegisterListenersOverride = () {};

        await expectLater(FcmService.initialize(), completes);

        expect(initializationCall?.method, 'initialize');
        final arguments =
            initializationCall?.arguments as Map<Object?, Object?>;
        expect(arguments['requestAlertPermission'], isFalse);
        expect(arguments['requestSoundPermission'], isFalse);
        expect(arguments['requestBadgePermission'], isFalse);
        expect(arguments['requestProvisionalPermission'], isFalse);
        expect(arguments['requestCriticalPermission'], isFalse);
        expect(arguments['requestProvidesAppNotificationSettings'], isFalse);
        expect(apnsTokenRequests, 1);
      },
    );

    test('should iOS requests an FCM token after APNs is ready', () async {
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

    test(
      'should Android requests an FCM token without querying APNs',
      () async {
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
      },
    );

    test(
      'should post-sign-in token refresh also waits for APNs on iOS',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        var fcmTokenRequests = 0;
        FcmService.debugRequestPermissionOverride = () async =>
            _notificationSettings(AuthorizationStatus.authorized);
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () => 'uid-123';
        FcmService.debugGetApnsTokenOverride = () async => null;
        FcmService.debugGetTokenOverride = () async {
          fcmTokenRequests++;
          return 'fcm-token';
        };
        FcmService.debugRegisterListenersOverride = () {};

        await expectLater(FcmService.onUserSignedIn(), completes);

        expect(fcmTokenRequests, 0);
      },
    );

    test(
      'should incomplete iOS initialization is completed during sign-in',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        String? uid;
        var apnsTokenRequests = 0;
        var tokenRequests = 0;
        var listenerRegistrations = 0;
        final savedTokens = <String>[];
        FcmService.debugRequestPermissionOverride = () async =>
            _notificationSettings(AuthorizationStatus.authorized);
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () => uid;
        FcmService.debugGetApnsTokenOverride = () async {
          apnsTokenRequests++;
          return apnsTokenRequests == 1 ? null : 'apns-token';
        };
        FcmService.debugGetTokenOverride = () async {
          tokenRequests++;
          return 'fcm-token';
        };
        FcmService.debugSaveTokenOverride = (deviceId, token) async {
          savedTokens.add('$deviceId:$token');
          return true;
        };
        FcmService.debugRegisterListenersOverride = () {
          listenerRegistrations++;
        };

        await FcmService.initialize();
        uid = 'uid-123';
        await FcmService.onUserSignedIn();

        expect(apnsTokenRequests, 3);
        expect(tokenRequests, 2);
        expect(savedTokens, ['uid-123:fcm-token', 'uid-123:fcm-token']);
        expect(listenerRegistrations, 1);
      },
    );

    test(
      'should sign-in does not bypass denied permission with a raw token read',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        var tokenRequests = 0;
        FcmService.debugGetNotificationSettingsOverride = () async {
          return _notificationSettings(AuthorizationStatus.denied);
        };
        FcmService.debugGetCurrentUserIdOverride = () => 'uid-123';
        FcmService.debugGetTokenOverride = () async {
          tokenRequests++;
          return 'fcm-token';
        };

        await FcmService.initialize();
        await FcmService.onUserSignedIn();

        expect(tokenRequests, 0);
      },
    );

    test(
      'should token-save failure contains a rejecting incident logger',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final logger = _RejectingIncidentLogger();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        FcmService.debugRequestPermissionOverride = () async =>
            _notificationSettings(AuthorizationStatus.authorized);
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () => 'uid-123';
        FcmService.debugGetTokenOverride = () async => 'fcm-token';
        FcmService.debugSaveTokenOverride = (deviceId, token) async {
          throw StateError('Firestore unavailable');
        };
        FcmService.debugRegisterListenersOverride = () {};

        await expectLater(FcmService.initialize(), completes);
        await Future<void>.delayed(Duration.zero);

        expect(logger.captureCalls, 1);
      },
    );

    test(
      'should post-sign-in save failure makes app-resume retry initialization',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        var uid = <String?>[null, 'uid-123', 'uid-123'].iterator;
        var tokenRequests = 0;
        var saveAttempts = 0;
        var listenerRegistrations = 0;
        FcmService.debugRequestPermissionOverride = () async =>
            _notificationSettings(AuthorizationStatus.authorized);
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () {
          uid.moveNext();
          return uid.current;
        };
        FcmService.debugGetTokenOverride = () async {
          tokenRequests++;
          return 'fcm-token';
        };
        FcmService.debugSaveTokenOverride = (deviceId, token) async {
          saveAttempts++;
          return saveAttempts > 1;
        };
        FcmService.debugRegisterListenersOverride = () {
          listenerRegistrations++;
        };

        await FcmService.initialize();
        await FcmService.onUserSignedIn();
        FcmService.onAppResumed();
        await Future<void>.delayed(Duration.zero);

        expect(tokenRequests, 3);
        expect(saveAttempts, 2);
        expect(listenerRegistrations, 1);
      },
    );

    test(
      'should post-sign-in token exception makes app-resume retry initialization',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        String? uid;
        var tokenRequests = 0;
        var listenerRegistrations = 0;
        FcmService.debugRequestPermissionOverride = () async =>
            _notificationSettings(AuthorizationStatus.authorized);
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () => uid;
        FcmService.debugGetTokenOverride = () async {
          tokenRequests++;
          if (tokenRequests == 2) {
            throw StateError('token read failed');
          }
          return 'fcm-token';
        };
        FcmService.debugSaveTokenOverride = (deviceId, token) async => true;
        FcmService.debugRegisterListenersOverride = () {
          listenerRegistrations++;
        };

        await FcmService.initialize();
        uid = 'uid-123';
        await FcmService.onUserSignedIn();
        FcmService.onAppResumed();
        await Future<void>.delayed(Duration.zero);

        expect(tokenRequests, 3);
        expect(listenerRegistrations, 1);
      },
    );

    test(
      'should app resume invokes a retry after an initialization failure',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final retryCompleted = Completer<void>();
        var settingsReads = 0;
        FcmService.debugGetNotificationSettingsOverride = () async {
          settingsReads++;
          if (settingsReads == 1) {
            throw StateError('messaging unavailable');
          }
          return _notificationSettings(AuthorizationStatus.authorized);
        };
        FcmService.debugInitializeLocalNotificationsOverride = () async {};
        FcmService.debugGetCurrentUserIdOverride = () => null;
        FcmService.debugGetTokenOverride = () async => 'fcm-token';
        FcmService.debugRegisterListenersOverride = retryCompleted.complete;

        await FcmService.initialize();
        FcmService.onAppResumed();
        await retryCompleted.future;

        expect(settingsReads, 2);
      },
    );
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

class _RejectingIncidentLogger implements IncidentLoggerService {
  int captureCalls = 0;

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) {
    captureCalls++;
    return Future<void>.error(StateError('logger unavailable'));
  }

  @override
  Future<void> initializeSentry(Widget MyApp) async {}
}
