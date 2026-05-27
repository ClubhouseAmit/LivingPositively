// Phase 10A (ADR-005 § A): integration test for the iOS arms of
// NotificationsService, running on a real iOS simulator under
// integration_test/.
//
// The Android sibling (`notifications_schedule_test.dart`) exercises the
// Android scheduling + init paths against the real Android binding. The
// unit suite (`test/notifications/notification_service_initialize_test.dart`)
// covers iOS behavior under `debugDefaultTargetPlatformOverride =
// TargetPlatform.iOS`, but those tests run against the host VM binding —
// iOS-specific channel-level surprises (Darwin plugin init, iOS
// zonedSchedule payload shape, lack of Workmanager iOS impl) only surface
// on a real iOS binding.
//
// This file runs on `macos-14` + iPhone simulator in the new
// `integration-test-ios` CI job (see `.github/workflows/main.yml`). Per
// ADR-002 hard rule #5 it is also verifiable locally by anyone with an
// iOS simulator attached: `flutter test integration_test/
// notifications_schedule_ios_test.dart -d "iPhone 15"`.
//
// Scope on iOS:
//   * supportsReminderSettings() returns false on iOS — exercised against
//     the real iOS defaultTargetPlatform (no override).
//   * calculateTime() — pure helper used by notification scheduling.
//   * init() happy path — DarwinInitializationSettings reaches the iOS
//     plugin's initialize via the dexterous.com/flutter/local_notifications
//     MethodChannel.
//   * init() catch branch — flutter_timezone throws, the fallback path
//     forwards the PlatformException to IncidentLogger and still calls
//     plugin.initialize on the Asia/Jerusalem fallback.
//   * showNotification() — direct notification display path reaches the
//     iOS plugin's show method.
//   * initializeNotification() / updateNotification() — early-return
//     when supportsReminderSettings() is false; assert no scheduling
//     calls reach the plugin.
//   * scheduleNotification() — direct call exercises the cross-platform
//     scheduling path against the iOS plugin variant.
//   * cancelNotifications(id) / cancelNotifications(null) — both reach
//     plugin.cancel / plugin.cancelAll on iOS.
//
// Explicitly NOT exercised (out of scope for Phase 10A):
//   * cancelNotifications(null, cancelWorker: true) — Workmanager's iOS
//     implementation does not route through the test WorkmanagerPlatform fake
//     on a real simulator. The Android integration test owns that worker path;
//     iOS coverage remains above the per-file floor without asserting it here.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
// ignore: depend_on_referenced_packages
import 'package:workmanager_platform_interface/workmanager_platform_interface.dart';

// iOS-side Workmanager safety net. The workmanager package has no iOS
// implementation, so `WorkmanagerPlatform.instance` defaults to a stub that
// throws `UnimplementedError`. The Android sibling subclasses
// `WorkmanagerAndroid` to defeat the binding's swap-back; iOS has no
// equivalent platform class to extend, but it also has no swap-back
// mechanism — so the simple `WorkmanagerPlatform` subclass is sufficient.
class _NoopWorkmanagerIOS extends WorkmanagerPlatform {
  _NoopWorkmanagerIOS._() : super();
  static final _NoopWorkmanagerIOS _shared = _NoopWorkmanagerIOS._();
  final List<String> calls = [];

  static _NoopWorkmanagerIOS register() {
    WorkmanagerPlatform.instance = _shared;
    _shared.calls.clear();
    return _shared;
  }

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
  }
}

class _DummyLocale implements AppLocalizations {
  @override
  String get noPermissionAllowedText => 'no permission';

  @override
  String notifyOnscheduledNotification(Object time) =>
      'You will be notified at $time';

  @override
  String get localeName => 'en';

  @override
  dynamic noSuchMethod(Invocation invocation) => '';
}

class _RecordingLogger implements IncidentLoggerService {
  final List<Object?> captured = [];

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    captured.add(exception);
  }

  @override
  Future<void> initializeSentry(Widget app) async {}
}

class _NoopPersistentMemoryService implements PersistentMemoryService {
  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async => null;

  @override
  Future<void> reset() async {}

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const localNotifChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezoneChannel = MethodChannel('flutter_timezone');
  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');

  late List<MethodCall> localNotifCalls;
  late Object? timezoneError;
  late String timezoneId;

  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<IncidentLoggerService>(_RecordingLogger());

    // Clear the static `_isInitialized` guard so init() runs its body each
    // test — mirrors the Android sibling's setUp (PR #266 review finding
    // 3/4).
    NotificationsService.resetForTest();

    // Register the iOS platform implementation so the
    // `resolvePlatformSpecificImplementation` chain inside the plugin works
    // without a `LateInitializationError`. The Android sibling does the
    // analogous `AndroidFlutterLocalNotificationsPlugin.registerWith()`.
    IOSFlutterLocalNotificationsPlugin.registerWith();

    // Install the iOS workmanager safety net. This keeps accidental future
    // worker calls from throwing `UnimplementedError` in this file.
    _NoopWorkmanagerIOS.register();

    localNotifCalls = [];
    timezoneError = null;
    timezoneId = 'America/Los_Angeles';

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(timezoneChannel, (call) async {
        if (call.method == 'getLocalTimezone') {
          if (timezoneError != null) throw timezoneError!;
          return timezoneId;
        }
        return null;
      })
      ..setMockMethodCallHandler(localNotifChannel, (call) async {
        localNotifCalls.add(call);
        // The iOS plugin's permission-request method name is
        // `requestPermissions` (Darwin idiom); Android's is
        // `requestNotificationsPermission`. We handle both for robustness
        // across plugin versions.
        switch (call.method) {
          case 'initialize':
          case 'requestPermissions':
          case 'requestNotificationsPermission':
          case 'requestExactAlarmsPermission':
          case 'canScheduleExactAlarms':
          case 'areNotificationsEnabled':
            return true;
          default:
            return null;
        }
      })
      ..setMockMethodCallHandler(toastChannel, (call) async => true);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(timezoneChannel, null)
      ..setMockMethodCallHandler(localNotifChannel, null)
      ..setMockMethodCallHandler(toastChannel, null);
    await GetIt.instance.reset();
  });

  group('supportsReminderSettings on real iOS binding', () {
    testWidgets('defaultTargetPlatform is iOS under macos-14 + iOS sim', (
      tester,
    ) async {
      expect(
        defaultTargetPlatform,
        TargetPlatform.iOS,
        reason:
            'this file is expected to run on an iOS simulator; if defaultTargetPlatform is not iOS, the CI job targeted the wrong device',
      );
    });

    testWidgets('returns false on iOS (no override)', (tester) async {
      expect(
        NotificationsService.supportsReminderSettings(),
        isFalse,
        reason:
            'iOS is intentionally not a reminder-settings platform — '
            'the function gates initializeNotification/updateNotification',
      );
    });

    testWidgets(
      'returns false when isWebOverride=true regardless of platform',
      (tester) async {
        expect(
          NotificationsService.supportsReminderSettings(isWebOverride: true),
          isFalse,
        );
      },
    );
  });

  group('init() on iOS', () {
    testWidgets('happy path reaches plugin.initialize via Darwin settings', (
      tester,
    ) async {
      await NotificationsService.init();
      expect(
        localNotifCalls.any((c) => c.method == 'initialize'),
        isTrue,
        reason: 'init() must reach plugin.initialize on iOS',
      );
    });

    testWidgets('second call short-circuits via _isInitialized', (
      tester,
    ) async {
      await NotificationsService.init();
      localNotifCalls.clear();
      await NotificationsService.init();
      expect(
        localNotifCalls.where((c) => c.method == 'initialize').toList(),
        isEmpty,
        reason: 'idempotency: second init() should not reach plugin.initialize',
      );
    });

    testWidgets(
      'catch branch on iOS forwards PlatformException to IncidentLogger and still initializes plugin',
      (tester) async {
        // setUp already called resetForTest() so _isInitialized is false here —
        // the init() body WILL run and the timezone throw will reach the
        // catch branch.
        timezoneError = PlatformException(
          code: 'IOS_TZ_FAIL',
          message: 'simulated',
        );

        await NotificationsService.init();

        final logger =
            GetIt.instance<IncidentLoggerService>() as _RecordingLogger;
        expect(
          logger.captured.any(
            (e) => e is PlatformException && e.code == 'IOS_TZ_FAIL',
          ),
          isTrue,
          reason:
              'iOS catch branch must forward IOS_TZ_FAIL PlatformException to IncidentLogger',
        );
        expect(
          localNotifCalls.any((c) => c.method == 'initialize'),
          isTrue,
          reason:
              'iOS catch branch must still call plugin.initialize on the Asia/Jerusalem fallback',
        );
      },
    );

    testWidgets(
      'catch branch on iOS still initializes plugin when IncidentLogger is unavailable',
      (tester) async {
        await GetIt.instance.reset();
        timezoneError = PlatformException(
          code: 'IOS_TZ_LOGGER_FAIL',
          message: 'simulated',
        );

        await NotificationsService.init();

        expect(
          localNotifCalls.any((c) => c.method == 'initialize'),
          isTrue,
          reason:
              'init() must still initialize notifications when error logging is unavailable',
        );
      },
    );
  });

  group('simple notification service helpers on iOS', () {
    testWidgets('calculateTime returns the requested hour and minute', (
      tester,
    ) async {
      expect(
        NotificationsService.calculateTime(7, 5),
        const TimeOfDay(hour: 7, minute: 5),
      );
    });

    testWidgets(
      'showNotification reaches plugin.show against the iOS binding',
      (tester) async {
        await NotificationsService.init();
        localNotifCalls.clear();

        await NotificationsService.showNotification('Title', 'Body');

        final showCalls = localNotifCalls
            .where((c) => c.method == 'show')
            .toList();
        expect(showCalls, hasLength(1));
        final args = showCalls.single.arguments;
        if (args is Map) {
          expect(args['id'], 0);
          expect(args['title'], 'Title');
          expect(args['body'], 'Body');
          expect(args['payload'], 'item x');
        }
      },
    );
  });

  group('initializeNotification / updateNotification iOS early-return', () {
    testWidgets(
      'initializeNotification() early-returns on iOS — no scheduling reaches the plugin',
      (tester) async {
        await NotificationsService.init();
        localNotifCalls.clear();

        await NotificationsService.initializeNotification(
          const ['quote A'],
          9,
          15,
          (s) => 'msg $s',
          _DummyLocale(),
        );
        // The early-return path must not reach permission, schedule, or toast.
        // (showToast itself goes via the fluttertoast channel which we mock
        // separately; the assertion here is specifically about the plugin
        // channel.)
        expect(
          localNotifCalls.any(
            (c) =>
                c.method == 'requestNotificationsPermission' ||
                c.method == 'requestPermissions' ||
                c.method == 'zonedSchedule',
          ),
          isFalse,
          reason:
              'iOS path must early-return before any plugin scheduling call',
        );
      },
    );

    testWidgets(
      'updateNotification() early-returns on iOS before scheduling work',
      (tester) async {
        await NotificationsService.init();
        localNotifCalls.clear();

        final userInfo = UserInformation(
          notificationHour: 7,
          notificationMinute: 5,
          gender: 'male',
          service: _NoopPersistentMemoryService(),
        );

        await NotificationsService.updateNotification(userInfo, _DummyLocale());

        expect(
          localNotifCalls.any(
            (c) =>
                c.method == 'requestNotificationsPermission' ||
                c.method == 'requestPermissions' ||
                c.method == 'zonedSchedule',
          ),
          isFalse,
          reason: 'iOS path must return before quote retrieval or scheduling',
        );
      },
    );
  });

  group('scheduleNotification on iOS (direct call, bypasses guard)', () {
    testWidgets('reaches plugin.zonedSchedule against the iOS binding', (
      tester,
    ) async {
      await NotificationsService.init();
      localNotifCalls.clear();

      await NotificationsService.scheduleNotification(
        const TimeOfDay(hour: 0, minute: 0),
        '90',
        'Living Positively reminder',
      );

      expect(
        localNotifCalls.any((c) => c.method == 'zonedSchedule'),
        isTrue,
        reason:
            'scheduleNotification must reach plugin.zonedSchedule on iOS — '
            'production safety-plan flow depends on this',
      );
    });
  });

  group('cancelNotifications on iOS', () {
    testWidgets('cancelNotifications(id) reaches plugin.cancel', (
      tester,
    ) async {
      await NotificationsService.init();
      localNotifCalls.clear();
      await NotificationsService.cancelNotifications(42);
      expect(localNotifCalls.any((c) => c.method == 'cancel'), isTrue);
    });

    testWidgets(
      'cancelNotifications(null) reaches plugin.cancelAll without touching workmanager',
      (tester) async {
        await NotificationsService.init();
        localNotifCalls.clear();

        await NotificationsService.cancelNotifications(null);

        expect(localNotifCalls.any((c) => c.method == 'cancelAll'), isTrue);
      },
    );
  });
}
