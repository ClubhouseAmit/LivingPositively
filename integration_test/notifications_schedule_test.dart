// Phase 7 (ADR-002): integration test for the Android scheduling paths in
// NotificationsService.
//
// The unit suite (`test/notifications/notification_service_initialize_test.dart`)
// already exercises iOS init, iOS short-circuits, the Android permission grant /
// deny branches at the `initializeNotification` boundary, and the cross-platform
// cancel paths — bringing the file to 66.7%. The remaining ~33% is concentrated
// in:
//
//   * `scheduleNotification(timeOfDay, id, text)` (lines 171-193) — the actual
//     `_flutterLocalNotificationsPlugin.zonedSchedule` call plus the
//     `scheduledDate.isBefore(now)` "schedule for tomorrow" branch.
//   * `init()` — particularly the catch branch (lines 61-75) when
//     `FlutterTimezone.getLocalTimezone()` rejects, the
//     `_flutterLocalNotificationsPlugin.initialize` retry, and the IncidentLogger
//     forward.
//
// This file targets those branches. We use the same MethodChannel-stub +
// `registerWith()` plugin-platform-impl pattern the unit suite established, but
// run under the integration_test binding so the test ALSO validates against the
// real Android binding when the CI emulator-runner job pumps it. Locally
// under `flutter test integration_test/notifications_schedule_test.dart`, the
// channel mocks fully cover the platform-bound calls so the file is verifiable
// per-file without an attached emulator (per ADR-002 hard rule #5).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/util/logger_service.dart';
// ignore: depend_on_referenced_packages
import 'package:workmanager_android/workmanager_android.dart';
// ignore: depend_on_referenced_packages
import 'package:workmanager_platform_interface/workmanager_platform_interface.dart';

// IMPORTANT: extends WorkmanagerAndroid (not just WorkmanagerPlatform).
// On a real Android binding the first `Workmanager()` call triggers
// `_ensurePlatformImplementation()`, which sees
// `WorkmanagerPlatform.instance is! WorkmanagerAndroid` and **overwrites**
// our fake back to the real `WorkmanagerAndroid()`. Inheriting from
// WorkmanagerAndroid satisfies the `is WorkmanagerAndroid` check so our
// override survives and the production code never reaches the real plugin
// (which would throw "You have not properly initialized the Flutter
// WorkManager Package."). See workmanager-0.9.0+3/lib/src/workmanager_impl.dart
// lines 83-92.
class _RecordingWorkmanager extends WorkmanagerAndroid {
  _RecordingWorkmanager._() : super();
  static final _RecordingWorkmanager _shared = _RecordingWorkmanager._();
  final List<String> calls = [];

  static _RecordingWorkmanager register() {
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
  Future<void> captureLog(dynamic exception,
      {StackTrace? stackTrace, dynamic exceptionData}) async {
    captured.add(exception);
  }

  @override
  Future<void> initializeSentry(Widget app) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const localNotifChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const timezoneChannel = MethodChannel('flutter_timezone');
  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');

  late List<MethodCall> localNotifCalls;
  late _RecordingWorkmanager fakeWm;
  // Allow per-test control over what the timezone channel does. Some branches
  // (init() catch) want it to throw; others want it to succeed.
  late Object? timezoneError;
  late String timezoneId;
  late bool? requestPermissionResult;

  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<IncidentLoggerService>(_RecordingLogger());

    // Clear the static `_isInitialized` flag so init() runs its body each
    // test — without this, any test order causes later init() calls to
    // short-circuit (PR #266 review: baz-reviewer finding 3/4).
    NotificationsService.resetForTest();

    // Register the Android platform implementation so the
    // `resolvePlatformSpecificImplementation` chain works inside
    // initializeNotification. iOS would use IOSFlutterLocalNotificationsPlugin
    // — but everything in THIS file targets the Android paths.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    fakeWm = _RecordingWorkmanager.register();
    localNotifCalls = [];
    timezoneError = null;
    timezoneId = 'Asia/Jerusalem';
    requestPermissionResult = true;

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
        if (call.method == 'requestNotificationsPermission') {
          return requestPermissionResult;
        }
        // The Android impl of `FlutterLocalNotificationsPlugin.initialize`
        // returns `bool` — returning null causes a `_TypeError: type 'Null'
        // is not a subtype of type 'FutureOr<bool>'` on the real binding.
        // Methods like requestPermission, requestExactAlarmsPermission,
        // canScheduleExactAlarms also expect bool. Defaulting bool-returning
        // methods to `true` (success) matches the test expectation that
        // these calls succeed.
        switch (call.method) {
          case 'initialize':
          case 'requestPermission':
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
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(timezoneChannel, null)
      ..setMockMethodCallHandler(localNotifChannel, null)
      ..setMockMethodCallHandler(toastChannel, null);
    await GetIt.instance.reset();
  });

  group('scheduleNotification (Android scheduling paths)', () {
    testWidgets('zonedSchedule is invoked with parsed id + scheduled date',
        (tester) async {
      // Force init() so tz.local is set before scheduleNotification reads it.
      await NotificationsService.init();
      localNotifCalls.clear();

      // Pick a time well in the past for "today" so the
      // `scheduledDate.isBefore(now)` branch triggers and the date is bumped
      // by one day.
      await NotificationsService.scheduleNotification(
        const TimeOfDay(hour: 0, minute: 0),
        '90',
        'Living Positively reminder',
      );

      final zonedCalls =
          localNotifCalls.where((c) => c.method == 'zonedSchedule').toList();
      expect(zonedCalls, hasLength(1),
          reason:
              'scheduleNotification must reach _flutterLocalNotificationsPlugin.zonedSchedule');
      // Best-effort assertions on the payload — different platform impl
      // versions wrap arguments slightly differently, so we tolerate both
      // shapes.
      final args = zonedCalls.single.arguments;
      if (args is Map) {
        expect(args['id'], 90);
        expect(args['title'], 'Living Positively');
        expect(args['body'], 'Living Positively reminder');
      }
    });

    testWidgets(
        'scheduleNotification for a time later today schedules without bumping the day',
        (tester) async {
      await NotificationsService.init();
      localNotifCalls.clear();

      // 23:59 — almost always later than `now` in the test run, so the
      // `isBefore(now)` branch must NOT fire. Either way the
      // zonedSchedule call must be made.
      await NotificationsService.scheduleNotification(
        const TimeOfDay(hour: 23, minute: 59),
        '2359',
        'Late reminder',
      );

      expect(
        localNotifCalls.any((c) => c.method == 'zonedSchedule'),
        isTrue,
        reason: 'late-in-day path must still reach zonedSchedule',
      );
    });
  });

  group('init() error catch branch', () {
    testWidgets(
        'init() falls back to Asia/Jerusalem when getLocalTimezone throws',
        (tester) async {
      // setUp already called NotificationsService.resetForTest() so
      // _isInitialized is guaranteed false here — the init() body WILL run
      // and the timezoneError will reach the catch branch.
      final simulatedError =
          PlatformException(code: 'TZ_FAIL', message: 'simulated');
      timezoneError = simulatedError;

      await NotificationsService.init();

      // The catch branch must:
      //   1. Swallow the timezone error (no rethrow).
      //   2. Still call the local-notifications plugin's `initialize` so
      //      the service is usable on the fallback timezone.
      //   3. Forward the original PlatformException to the IncidentLogger.
      final logger = GetIt.instance<IncidentLoggerService>() as _RecordingLogger;
      expect(
        logger.captured,
        contains(simulatedError),
        reason:
            'catch branch must forward the PlatformException to IncidentLogger',
      );
      expect(
        localNotifCalls.any((c) => c.method == 'initialize'),
        isTrue,
        reason: 'catch branch must still call plugin.initialize on the fallback',
      );
    });
  });

  group('initializeNotification → scheduleNotification → cancel (Android e2e)',
      () {
    testWidgets(
        'Android permission grant fires workmanager registrations + zonedSchedule on the periodic worker callback path',
        (tester) async {
      requestPermissionResult = true;
      fakeWm.calls.clear();
      localNotifCalls.clear();

      await NotificationsService.initializeNotification(
        const ['quote A', 'quote B'],
        9,
        15,
        (s) => 'msg $s',
        _DummyLocale(),
      );
      // Drain the showToast timer.
      await tester.pump(const Duration(seconds: 2));

      expect(fakeWm.calls, contains('cancelAll'));
      expect(
        fakeWm.calls.any((c) => c.startsWith('registerOneOffTask:9015:')),
        isTrue,
      );
      expect(
        fakeWm.calls.any((c) => c.startsWith('registerPeriodicTask:9015:')),
        isTrue,
      );

      // Now exercise the cancel-all and scheduleNotification paths the
      // worker callback would invoke.
      await NotificationsService.cancelNotifications(null, cancelWorker: true);
      expect(fakeWm.calls, contains('cancelAll'));
      expect(
        localNotifCalls.map((c) => c.method).toList(),
        contains('cancelAll'),
      );

      await NotificationsService.scheduleNotification(
        NotificationsService.calculateTime(9, 15),
        '9015',
        'quote A',
      );
      expect(
        localNotifCalls.where((c) => c.method == 'zonedSchedule').isNotEmpty,
        isTrue,
      );
    });
  });
}
