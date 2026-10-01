part of 'fcm_scheduled_notification_service.dart';

/// Registers a user-selected quick or custom reminder with static content.
Future<bool> registerTextReminder({
  required UserInformation userInformation,
  required String typeId,
  required int hour,
  required int minute,
  required String title,
  required String body,
}) {
  final resetEpoch = FcmScheduledNotificationService._resetEpoch;
  return _enqueue(
    () => _registerNotification(
      userInformation: userInformation,
      typeId: typeId,
      hour: hour,
      minute: minute,
      staticTitle: title,
      staticBody: body,
      resetEpoch: resetEpoch,
    ),
  );
}

/// Restores a paused schedule only if no newer choice replaced it in the queue.
Future<bool> registerPausedTextReminder({
  required UserInformation userInformation,
  required String typeId,
  required NotificationPreference? Function() currentPreference,
  required String Function(NotificationPreference) bodyFor,
}) {
  final resetEpoch = FcmScheduledNotificationService._resetEpoch;
  return _enqueue(() {
    final preference = currentPreference();
    if (preference == null) return Future.value(true);
    return _registerNotification(
      userInformation: userInformation,
      typeId: typeId,
      hour: preference.hour,
      minute: preference.minute,
      staticTitle: preference.staticTitle ?? 'Living Positively',
      staticBody: bodyFor(preference),
      resetEpoch: resetEpoch,
    );
  });
}

Future<bool> _registerNotification({
  required UserInformation userInformation,
  required String typeId,
  required int hour,
  required int minute,
  String? staticTitle,
  String? staticBody,
  Future<String?> Function()? idTokenProvider,
  NotificationHttpPost? post,
  required int resetEpoch,
  bool allowUnsupportedPlatform = false,
  bool persistLocalPreference = true,
  int? expectedMutationVersion,
}) async {
  if (!allowUnsupportedPlatform && !FcmService.supportsReminderSettings()) {
    return false;
  }
  if (resetEpoch != FcmScheduledNotificationService._resetEpoch) return false;
  _log(
    'Registering notification: typeId=$typeId, hour=$hour, minute=$minute',
  );
  final userInfo = userInformation;
  final locale = _notificationLocale(userInfo.localeName);
  if (locale == null) {
    _log('Unsupported notification locale: ${userInfo.localeName}');
    return false;
  }
  final rawGender = userInfo.gender;
  final gender = (rawGender == 'male' || rawGender == 'female')
      ? rawGender
      : 'other';

  try {
    final idToken = await (idTokenProvider ?? _getIdToken)().timeout(
      FcmScheduledNotificationService._networkTimeout,
    );
    if (idToken == null) {
      _reportNotificationFailure(
        'registerNotification authentication unavailable',
        StateError('Notification registration has no authentication token.'),
        StackTrace.current,
      );
      return false;
    }
    if (resetEpoch != FcmScheduledNotificationService._resetEpoch) return false;
    final mutationVersion =
        expectedMutationVersion ??
        await _getNotificationMutationVersion(
          idToken: idToken,
          typeId: typeId,
          post: post,
        );
    if (mutationVersion == null ||
        resetEpoch != FcmScheduledNotificationService._resetEpoch) {
      return false;
    }
    final response = await _postRegistration(
      idToken: idToken,
      typeId: typeId,
      hour: hour,
      minute: minute,
      locale: locale,
      gender: gender,
      staticTitle: staticTitle,
      staticBody: staticBody,
      mutationVersion: mutationVersion,
      post: post,
    );

    if (staticTitle != null && _isReminderLimitResponse(response)) {
      throw const NotificationReminderLimitException();
    }
    if (response.statusCode != 200) {
      _reportNotificationFailure(
        'registerNotification HTTP failure',
        StateError(
          'Notification registration returned '
          '${_notificationHttpFailureDescription(response)}.',
        ),
        StackTrace.current,
      );
      return false;
    }
    return await _finishRegistration(
      response: response,
      mutationVersion: mutationVersion,
      userInformation: userInfo,
      typeId: typeId,
      hour: hour,
      minute: minute,
      staticTitle: staticTitle,
      staticBody: staticBody,
      idToken: idToken,
      post: post,
      resetEpoch: resetEpoch,
      persistLocalPreference: persistLocalPreference,
    );
  } on NotificationReminderLimitException {
    rethrow;
  } catch (error, stackTrace) {
    _reportNotificationFailure(
      'registerNotification error',
      error,
      stackTrace,
    );
    return false;
  }
}

Future<bool> _finishRegistration({
  required http.Response response,
  required int mutationVersion,
  required UserInformation userInformation,
  required String typeId,
  required int hour,
  required int minute,
  String? staticTitle,
  String? staticBody,
  required String idToken,
  NotificationHttpPost? post,
  required int resetEpoch,
  required bool persistLocalPreference,
}) async {
  final nextVersion = _successfulMutationVersion(response, mutationVersion);
  if (nextVersion == null) {
    _reportNotificationFailure(
      'registerNotification invalid success response',
      StateError('Notification registration returned an invalid version.'),
      StackTrace.current,
    );
    return false;
  }
  _log('Notification registered successfully.');
  if (!persistLocalPreference) return true;
  return _persistRegisteredPreference(
    userInformation: userInformation,
    typeId: typeId,
    hour: hour,
    minute: minute,
    staticTitle: staticTitle,
    staticBody: staticBody,
    idToken: idToken,
    post: post,
    resetEpoch: resetEpoch,
    nextMutationVersion: nextVersion,
  );
}

Future<http.Response> _postRegistration({
  required String idToken,
  required String typeId,
  required int hour,
  required int minute,
  required String locale,
  required String gender,
  String? staticTitle,
  String? staticBody,
  required int mutationVersion,
  NotificationHttpPost? post,
}) => (post ?? FcmScheduledNotificationService.debugPostOverride ?? http.post)(
  Uri.parse(
    '${FcmScheduledNotificationService._functionsBaseUrl}/registerNotification',
  ),
  headers: _notificationHeaders(idToken),
  body: _registrationBody(
    typeId,
    hour,
    minute,
    locale,
    gender,
    staticTitle,
    staticBody,
    mutationVersion,
  ),
).timeout(FcmScheduledNotificationService._networkTimeout);

String _registrationBody(
  String typeId,
  int hour,
  int minute,
  String locale,
  String gender,
  String? staticTitle,
  String? staticBody,
  int mutationVersion,
) => jsonEncode({
  'typeId': typeId,
  'hour': hour,
  'minute': minute,
  'locale': locale,
  'gender': gender,
  'staticTitle': ?staticTitle,
  'staticBody': ?staticBody,
  'expectedMutationVersion': mutationVersion,
});

Future<bool> _persistRegisteredPreference({
  required UserInformation userInformation,
  required String typeId,
  required int hour,
  required int minute,
  String? staticTitle,
  String? staticBody,
  required String idToken,
  required int resetEpoch,
  required int nextMutationVersion,
  NotificationHttpPost? post,
}) async {
  final preferences = NotificationRepository.forService(
    userInformation.service,
  );
  final previousPreference = preferences.getPreference(typeId);
  final previousDefaultOptOut = preferences.defaultOptOut;
  final previousPaused = preferences.pausedAccountRemindersFor(
    userInformation.userId,
  )[typeId];
  try {
    await preferences
        .setPreference(
          typeId,
          NotificationPreference.withContent(
            hour: hour,
            minute: minute,
            staticTitle: staticTitle,
            staticBody: staticBody,
          ),
        )
        .timeout(
          FcmScheduledNotificationService._legacyMigrationOperationTimeout,
        );
    return true;
  } catch (error, stackTrace) {
    _reportNotificationFailure(
      'Unable to persist registered notification',
      error,
      stackTrace,
    );
    await _restoreLocalNotificationPreference(
      userInformation,
      typeId,
      previousPreference,
      previousDefaultOptOut: previousDefaultOptOut,
      previousPaused: previousPaused,
    );
    final compensationVersion = previousPreference == null
        ? await _cancelRemoteNotification(
            idToken: idToken,
            typeId: typeId,
            post: post,
            expectedMutationVersion: nextMutationVersion,
          )
        : await _registerNotification(
            userInformation: userInformation,
            typeId: typeId,
            hour: previousPreference.hour,
            minute: previousPreference.minute,
            staticTitle: previousPreference.staticTitle,
            staticBody: previousPreference.staticBody,
            idTokenProvider: () async => idToken,
            post: post,
            resetEpoch: resetEpoch,
            allowUnsupportedPlatform: true,
            persistLocalPreference: false,
            expectedMutationVersion: nextMutationVersion,
          );
    final compensated = compensationVersion is bool
        ? compensationVersion
        : compensationVersion != null;
    if (!compensated) {
      _log('Unable to compensate a notification registration failure.');
    }
    return false;
  }
}

Future<int?> _cancelRemoteNotification({
  required String idToken,
  required String typeId,
  NotificationHttpPost? post,
  required int expectedMutationVersion,
}) async {
  try {
    final response =
        await (post ??
                FcmScheduledNotificationService.debugPostOverride ??
                http.post)(
              Uri.parse(
                '${FcmScheduledNotificationService._functionsBaseUrl}/cancelNotification',
              ),
              headers: {
                'Authorization': 'Bearer $idToken',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'typeId': typeId,
                'expectedMutationVersion': expectedMutationVersion,
              }),
            )
            .timeout(FcmScheduledNotificationService._networkTimeout);
    return response.statusCode == 200
        ? _successfulMutationVersion(response, expectedMutationVersion)
        : null;
  } catch (error, stackTrace) {
    _reportNotificationFailure(
      'Unable to compensate a notification registration failure',
      error,
      stackTrace,
    );
    return null;
  }
}

Future<bool> _restoreLocalNotificationPreference(
  UserInformation userInformation,
  String typeId,
  NotificationPreference? preference, {
  bool? previousDefaultOptOut,
  NotificationPreference? previousPaused,
}) async {
  try {
    final preferences = NotificationRepository.forService(
      userInformation.service,
    );
    final write = previousPaused != null
        ? preferences.restorePausedAfterFailedRegistration(
            typeId,
            previousPaused,
            userInformation.userId,
          )
        : preference == null
        ? preferences.clearPreferenceAfterFailedRegistration(
            typeId,
            previousDefaultOptOut:
                previousDefaultOptOut ?? preferences.defaultOptOut,
          )
        : preferences.setPreference(typeId, preference);
    await write.timeout(
      FcmScheduledNotificationService._legacyMigrationOperationTimeout,
    );
    return true;
  } catch (error, stackTrace) {
    _reportNotificationFailure(
      'Unable to restore a local notification preference',
      error,
      stackTrace,
    );
    return false;
  }
}
