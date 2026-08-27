import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';
import '../test_support/contract_persistent_memory_service.dart';
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
      OutOfQuotaPolicy? outOfQuotaPolicy,
      ForegroundServiceConfig? foregroundServiceConfig,
      bool expedited = false}) async {
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
      String? tag,
      ForegroundServiceConfig? foregroundServiceConfig}) async {
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

final class _NoopPersistentMemoryService extends ContractPersistentMemoryService {
  _NoopPersistentMemoryService() {
    onMissingRead = (_, _) => null;
  }
}

Future<void> _runWithAndroidTarget(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('FCM reminder settings are available on supported mobile platforms', () {
    expect(
      FcmService.supportsReminderSettings(
        platformOverride: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      FcmService.supportsReminderSettings(platformOverride: TargetPlatform.iOS),
      isTrue,
    );
  });
}
