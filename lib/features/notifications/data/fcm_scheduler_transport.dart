part of 'fcm_scheduled_notification_service.dart';

Map<String, String> _notificationHeaders(String idToken) => {
  'Authorization': 'Bearer $idToken',
  'Content-Type': 'application/json',
};

bool _isReminderLimitResponse(http.Response response) {
  if (response.statusCode != 429) return false;
  try {
    final body = jsonDecode(response.body);
    return body is Map<String, dynamic> &&
        body['error'] == 'REMINDER_LIMIT_REACHED';
  } on FormatException {
    return false;
  }
}

/// Reads the server's default reminder without changing its schedule.
Future<
  ({bool succeeded, NotificationPreference? schedule, int mutationVersion})
>
readDefaultReminderSchedule({
  required UserInformation userInformation,
  Future<String?> Function()? idTokenProvider,
  NotificationHttpPost? post,
}) {
  if (!userInformation.loggedIn) {
    return Future.value((succeeded: false, schedule: null, mutationVersion: 0));
  }
  return _enqueue(
    () => _readDefaultReminderSchedule(
      idTokenProvider: idTokenProvider,
      post: post,
    ),
  );
}

Future<
  ({bool succeeded, NotificationPreference? schedule, int mutationVersion})
>
_readDefaultReminderSchedule({
  Future<String?> Function()? idTokenProvider,
  NotificationHttpPost? post,
}) async {
  try {
    final idToken = await (idTokenProvider ?? _getIdToken)().timeout(
      FcmScheduledNotificationService._networkTimeout,
    );
    if (idToken == null) {
      return (succeeded: false, schedule: null, mutationVersion: 0);
    }
    final response =
        await (post ??
                FcmScheduledNotificationService.debugPostOverride ??
                http.post)(
              Uri.parse(
                '${FcmScheduledNotificationService._functionsBaseUrl}/getNotificationMutationVersion',
              ),
              headers: {
                'Authorization': 'Bearer $idToken',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'typeId': 'default'}),
            )
            .timeout(FcmScheduledNotificationService._networkTimeout);
    if (response.statusCode != 200) {
      return (succeeded: false, schedule: null, mutationVersion: 0);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || !decoded.containsKey('schedule')) {
      return (succeeded: false, schedule: null, mutationVersion: 0);
    }
    final version = decoded['mutationVersion'];
    if (version is! int || version < 0) {
      return (succeeded: false, schedule: null, mutationVersion: 0);
    }
    if (decoded['schedule'] == null) {
      return (succeeded: true, schedule: null, mutationVersion: version);
    }
    final schedule = decoded['schedule'];
    if (schedule is! Map<String, dynamic>) {
      return (succeeded: false, schedule: null, mutationVersion: 0);
    }
    final hour = schedule['hour'];
    final minute = schedule['minute'];
    if (hour is! int ||
        hour < 0 ||
        hour > 23 ||
        minute is! int ||
        minute < 0 ||
        minute > 59) {
      return (succeeded: false, schedule: null, mutationVersion: 0);
    }
    return (
      succeeded: true,
      schedule: NotificationPreference(hour: hour, minute: minute),
      mutationVersion: version,
    );
  } catch (error, stackTrace) {
    _reportNotificationFailure(
      'Unable to read default reminder',
      error,
      stackTrace,
    );
    return (succeeded: false, schedule: null, mutationVersion: 0);
  }
}

Future<bool> _migrateLegacyDefaultSchedule({
  required UserInformation userInformation,
  required NotificationPreference legacyPreference,
  required int resetEpoch,
  Future<String?> Function()? idTokenProvider,
  NotificationHttpPost? post,
}) async {
  final status = await _readDefaultReminderSchedule(
    idTokenProvider: idTokenProvider,
    post: post,
  );
  if (!status.succeeded ||
      resetEpoch != FcmScheduledNotificationService._resetEpoch) {
    return false;
  }
  final repository = NotificationRepository.forService(userInformation.service);
  if (status.schedule case final serverSchedule?) {
    await repository
        .setPreference('default', serverSchedule)
        .timeout(
          FcmScheduledNotificationService._legacyMigrationOperationTimeout,
        );
    return true;
  }
  if (status.mutationVersion > 0) {
    await repository
        .clearPreferenceAfterFailedRegistration(
          'default',
          previousDefaultOptOut: repository.defaultOptOut,
        )
        .timeout(
          FcmScheduledNotificationService._legacyMigrationOperationTimeout,
        );
    return true;
  }
  return _registerNotification(
    userInformation: userInformation,
    typeId: 'default',
    hour: legacyPreference.hour,
    minute: legacyPreference.minute,
    idTokenProvider: idTokenProvider,
    post: post,
    resetEpoch: resetEpoch,
    expectedMutationVersion: status.mutationVersion,
  );
}

void _log(String message) =>
    debugPrint('[FcmScheduledNotificationService] $message');

String _notificationHttpFailureDescription(http.Response response) {
  const maxReasonLength = 200;
  final body = response.body;
  final truncated = body.length > maxReasonLength;
  final excerpt = truncated ? body.substring(0, maxReasonLength) : body;
  final reason = excerpt.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ').trim();
  if (reason.isEmpty) {
    return truncated
        ? 'HTTP ${response.statusCode}: ...'
        : 'HTTP ${response.statusCode}';
  }
  return 'HTTP ${response.statusCode}: $reason${truncated ? '...' : ''}';
}

void _reportNotificationFailure(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  _log('$operation: $error');
  if (!GetIt.instance.isRegistered<IncidentLoggerService>()) return;
  unawaited(
    Future<void>.sync(
      () => GetIt.instance<IncidentLoggerService>().captureLog(
        error,
        stackTrace: stackTrace,
      ),
    ).catchError((Object loggerError, StackTrace loggerStackTrace) {
      debugPrint(
        'Scheduled notification failure reporting failed: $loggerError',
      );
    }),
  );
}

Future<T> _enqueue<T>(Future<T> Function() operation) {
  final previousOperation = FcmScheduledNotificationService._operationQueue;
  final operationResult = previousOperation == null
      ? Future<T>.sync(operation)
      : previousOperation.then((_) => operation());
  final queueRelease = operationResult.then<void>(
    (_) {},
    onError: (Object _, StackTrace _) {},
  );
  FcmScheduledNotificationService._operationQueue = queueRelease;
  return operationResult.whenComplete(() => queueRelease);
}

Future<String?> _getIdToken() async {
  if (!GetIt.instance.isRegistered<FirebaseAuth>()) {
    _log('Warning: FirebaseAuth is not initialized, cannot get ID token.');
    return null;
  }
  final user = GetIt.instance<FirebaseAuth>().currentUser;
  if (user == null || user.isAnonymous) {
    _log('Warning: no authenticated user, cannot get ID token.');
    return null;
  }
  final token = await user.getIdToken();
  if (token == null) {
    _log('Warning: no authenticated user, cannot get ID token.');
  }
  return token;
}

Future<NotificationPreference?> _legacyDefaultReminderPreference(
  PersistentMemoryService memory, {
  bool requiresEnabledMarker = false,
}) async {
  if (requiresEnabledMarker) {
    final legacyReminderEnabled = await memory
        .getItem(
          FcmScheduledNotificationService._legacyDefaultReminderEnabledKey,
          PersistentMemoryType.Bool,
        )
        .timeout(
          FcmScheduledNotificationService._legacyMigrationOperationTimeout,
        );
    if (legacyReminderEnabled != true) return null;
  }
  final legacyHour = await memory
      .getItem('notificationHour', PersistentMemoryType.Int)
      .timeout(
        FcmScheduledNotificationService._legacyMigrationOperationTimeout,
      );
  final legacyMinute = await memory
      .getItem('notificationMinute', PersistentMemoryType.Int)
      .timeout(
        FcmScheduledNotificationService._legacyMigrationOperationTimeout,
      );
  final hasValidLegacyTime =
      legacyHour is int &&
      legacyHour >= 0 &&
      legacyHour <= 23 &&
      legacyMinute is int &&
      legacyMinute >= 0 &&
      legacyMinute <= 59;
  if (!hasValidLegacyTime) return null;
  return NotificationPreference(hour: legacyHour, minute: legacyMinute);
}

int _legacyLocalNotificationId(NotificationPreference preference) {
  return int.parse('${preference.hour}${preference.minute}');
}

/// Runs [migrateLegacyDefaultReminder] and reports, rather than propagates,
Future<int?> _getNotificationMutationVersion({
  required String idToken,
  required String typeId,
  NotificationHttpPost? post,
}) async {
  try {
    final response =
        await (post ??
                FcmScheduledNotificationService.debugPostOverride ??
                http.post)(
              Uri.parse(
                '${FcmScheduledNotificationService._functionsBaseUrl}/getNotificationMutationVersion',
              ),
              headers: {
                'Authorization': 'Bearer $idToken',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'typeId': typeId}),
            )
            .timeout(FcmScheduledNotificationService._networkTimeout);
    if (response.statusCode != 200) {
      _reportNotificationFailure(
        'getNotificationMutationVersion HTTP failure',
        StateError(
          'Notification version lookup returned '
          '${_notificationHttpFailureDescription(response)}.',
        ),
        StackTrace.current,
      );
      return null;
    }
    final body = jsonDecode(response.body);
    final mutationVersion = body is Map<String, dynamic>
        ? body['mutationVersion']
        : null;
    if (mutationVersion is int && mutationVersion >= 0) {
      return mutationVersion;
    }
    _reportNotificationFailure(
      'getNotificationMutationVersion invalid response',
      StateError('Notification version lookup returned an invalid body.'),
      StackTrace.current,
    );
    return null;
  } catch (error, stackTrace) {
    _reportNotificationFailure(
      'getNotificationMutationVersion error',
      error,
      stackTrace,
    );
    return null;
  }
}

int? _successfulMutationVersion(
  http.Response response,
  int expectedMutationVersion,
) {
  if (expectedMutationVersion == 9007199254740991) return null;
  try {
    final body = jsonDecode(response.body);
    final mutationVersion = body is Map<String, dynamic>
        ? body['mutationVersion']
        : null;
    if (mutationVersion is int &&
        mutationVersion == expectedMutationVersion + 1) {
      return mutationVersion;
    }
    if (body is Map<String, dynamic> &&
        body.length == 1 &&
        body['success'] == true) {
      // Older deployed Functions returned only this explicit success shape.
      return expectedMutationVersion + 1;
    }
    _log('Notification mutation returned an unexpected version.');
  } catch (_) {
    _log('Notification mutation returned an invalid body.');
  }
  return null;
}

NotificationPreference? _cancelledSchedulePreference(
  http.Response response,
) {
  try {
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return null;
    final schedule = body['schedule'];
    if (schedule is! Map<String, dynamic>) return null;
    return NotificationPreference.fromJson(schedule);
  } catch (_) {
    return null;
  }
}

String? _notificationLocale(String rawLocale) {
  final language = rawLocale.trim().split(RegExp('[-_]')).first.toLowerCase();
  return switch (language) {
    'he' || 'ar' || 'en' => language,
    '' => 'he',
    _ => null,
  };
}
