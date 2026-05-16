// Direct tests for `NotificationsService.initializeNotification` and
// `cancelNotifications` — the platform-bound branches that were marked
// "integration-test territory" in round 3.
//
// Strategy: reuse the round-2 pattern from `set_notification_widget_test.dart`
// (register a real plugin implementation via `registerWith()`, stub the
// method channel, override the WorkmanagerPlatform with a recording fake)
// but call the static service entry-points directly instead of via the
// widget tree. This exercises the platform branches without needing a full
// MaterialApp + provider scaffold.
//
// `FlutterLocalNotificationsPlatform.instance` is a single static slot — the
// last `registerWith()` call wins. Each test sets the impl explicitly per
// platform inside `_onPlatform`, so the tests can run in any order without
// leaking state across each other.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:workmanager_platform_interface/workmanager_platform_interface.dart';

class _FakeWorkmanager extends WorkmanagerPlatform {
  _FakeWorkmanager._() : super();
  static final _FakeWorkmanager _shared = _FakeWorkmanager._();
  final List<String> calls = [];

  static _FakeWorkmanager register() {
    WorkmanagerPlatform.instance = _shared;
    _shared.calls.clear();
    return _shared;
  }

  @override
  Future<void> initialize(Function callbackDispatcher,
      {bool isInDebugMode = false}) async {
    calls.add('initialize');
  }

  @override
  Future<void> registerOneOffTask(String uniqueName, String taskName,
      {Map<String, dynamic>? inputData,
      Duration? initialDelay,
      Constraints? constraints,
      ExistingWorkPolicy? existingWorkPolicy,
      BackoffPolicy? backoffPolicy,
      Duration? backoffPolicyDelay,
      String? tag,
      OutOfQuotaPolicy? outOfQuotaPolicy}) async {
    calls.add('registerOneOffTask:$uniqueName:$taskName');
  }

  @override
  Future<void> registerPeriodicTask(String uniqueName, String taskName,
      {Duration? frequency,
      Duration? flexInterval,
      Map<String, dynamic>? inputData,
      Duration? initialDelay,
      Constraints? constraints,
      ExistingPeriodicWorkPolicy? existingWorkPolicy,
      BackoffPolicy? backoffPolicy,
      Duration? backoffPolicyDelay,
      String? tag}) async {
    calls.add('registerPeriodicTask:$uniqueName:$taskName');
  }

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
  }

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {
    calls.add('cancelByUniqueName:$uniqueName');
  }

  @override
  Future<void> cancelByTag(String tag) async {
    calls.add('cancelByTag:$tag');
  }
}

Future<T> _onAndroid<T>(Future<T> Function() body) async {
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<T> _onIos<T>(Future<T> Function() body) async {
  IOSFlutterLocalNotificationsPlugin.registerWith();
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const localNotifChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const timezoneChannel = MethodChannel('flutter_timezone');
  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');

  late List<MethodCall> localNotifCalls;
  late _FakeWorkmanager fakeWm;
  // Per-test override returned for requestNotificationsPermission so we can
  // exercise the permission-grant / permission-deny branches.
  late bool? requestPermissionResult;

  setUp(() {
    fakeWm = _FakeWorkmanager.register();
    localNotifCalls = [];
    requestPermissionResult = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(timezoneChannel, (call) async {
        if (call.method == 'getLocalTimezone') return 'UTC';
        return null;
      })
      ..setMockMethodCallHandler(localNotifChannel, (call) async {
        localNotifCalls.add(call);
        if (call.method == 'requestNotificationsPermission') {
          return requestPermissionResult;
        }
        return null;
      })
      ..setMockMethodCallHandler(toastChannel, (call) async => true);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(timezoneChannel, null)
      ..setMockMethodCallHandler(localNotifChannel, null)
      ..setMockMethodCallHandler(toastChannel, null);
  });

  group('cancelNotifications', () {
    testWidgets('cancel-all (id=null) hits plugin.cancelAll', (tester) async {
      await _onIos(() async {
        localNotifCalls.clear();
        await NotificationsService.cancelNotifications(null);
        expect(localNotifCalls.map((c) => c.method).toList(),
            contains('cancelAll'));
        // cancelWorker defaults to false → no workmanager touch.
        expect(fakeWm.calls.where((c) => c.startsWith('cancel')).toList(),
            isEmpty);
      });
    });

    testWidgets('cancel by id routes to plugin.cancel on iOS',
        (tester) async {
      await _onIos(() async {
        localNotifCalls.clear();
        await NotificationsService.cancelNotifications(42);
        expect(
            localNotifCalls.map((c) => c.method).toList(), contains('cancel'));
      });
    });

    testWidgets('cancelWorker=true also calls workmanager.cancelAll',
        (tester) async {
      await _onIos(() async {
        fakeWm.calls.clear();
        await NotificationsService.cancelNotifications(null,
            cancelWorker: true);
        expect(fakeWm.calls, contains('cancelAll'));
      });
    });
  });

  group('init() timezone branches', () {
    testWidgets('init() with timezone resolved successfully', (tester) async {
      await _onIos(() async {
        // First call may flip _isInitialized; second call should be a no-op
        // that still completes.
        await NotificationsService.init();
        await NotificationsService.init();
      });
    });
  });

  group('initializeNotification platform branches', () {
    testWidgets('iOS short-circuits at supportsReminderSettings guard',
        (tester) async {
      await _onIos(() async {
        fakeWm.calls.clear();
        await NotificationsService.initializeNotification(
          const ['quote1'],
          9,
          0,
          (s) => 'msg $s',
          _DummyLocale(),
        );
        // No workmanager registrations on iOS.
        expect(fakeWm.calls.where((c) => c.startsWith('register')).toList(),
            isEmpty);
      });
    });

    testWidgets('Android permission grant → workmanager registrations fire',
        (tester) async {
      await _onAndroid(() async {
        requestPermissionResult = true;
        fakeWm.calls.clear();
        localNotifCalls.clear();

        await NotificationsService.initializeNotification(
          const ['quote1'],
          9,
          0,
          (s) => 'msg $s',
          _DummyLocale(),
        );
        // showToast schedules a Fluttertoast timer; advance the binding so it
        // fires and no Timer is left pending at teardown.
        await tester.pump(const Duration(seconds: 2));

        // The Android branch first cancels via workmanager (cancelWorker:true).
        expect(fakeWm.calls, contains('cancelAll'));
        expect(
          fakeWm.calls.any((c) => c.startsWith('registerOneOffTask:')),
          isTrue,
          reason: 'Android permission-granted branch must register one-off task',
        );
        expect(
          fakeWm.calls.any((c) => c.startsWith('registerPeriodicTask:')),
          isTrue,
          reason:
              'Android permission-granted branch must register periodic task',
        );
        // The permission was asked through the local-notifications channel.
        expect(
          localNotifCalls.map((c) => c.method).toList(),
          contains('requestNotificationsPermission'),
        );
      });
    });

    testWidgets('Android permission DENIED — no workmanager registrations',
        (tester) async {
      await _onAndroid(() async {
        requestPermissionResult = false;
        fakeWm.calls.clear();
        localNotifCalls.clear();

        await NotificationsService.initializeNotification(
          const ['quote1'],
          14,
          5,
          (s) => 'msg $s',
          _DummyLocale(),
        );
        await tester.pump(const Duration(seconds: 2));

        // Permission was asked.
        expect(
          localNotifCalls.map((c) => c.method).toList(),
          contains('requestNotificationsPermission'),
        );
        // But no workmanager registrations.
        expect(
          fakeWm.calls.where((c) => c.startsWith('register')).toList(),
          isEmpty,
        );
      });
    });
  });
}

// Minimal AppLocalizations stand-in. The production code touches only
// `noPermissionAllowedText` and `notifyOnscheduledNotification`. Other
// members fall through to `noSuchMethod` returning an empty string.
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
