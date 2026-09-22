part of 'fcm_scheduled_notification_service.dart';

Future<bool> _registerNotification({
  required UserInformation userInformation,
  required String typeId,
  required int hour,
  required int minute,
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
    if (idToken == null) return false;
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
      mutationVersion: mutationVersion,
      post: post,
    );

    if (response.statusCode == 200) {
      final nextMutationVersion = _successfulMutationVersion(
        response,
        mutationVersion,
      );
      if (nextMutationVersion == null) return false;
      _log('Notification registered successfully.');
      if (!persistLocalPreference) return true;
      return await _persistRegisteredPreference(
        userInformation: userInfo,
        typeId: typeId,
        hour: hour,
        minute: minute,
        idToken: idToken,
        post: post,
        resetEpoch: resetEpoch,
        nextMutationVersion: nextMutationVersion,
      );
    } else {
      _log(
        'registerNotification failed: ${response.statusCode} ${response.body}',
      );
      return false;
    }
  } catch (error, stackTrace) {
    _reportNotificationFailure(
      'registerNotification error',
      error,
      stackTrace,
    );
    return false;
  }
}

Future<http.Response> _postRegistration({
  required String idToken,
  required String typeId,
  required int hour,
  required int minute,
  required String locale,
  required String gender,
  required int mutationVersion,
  NotificationHttpPost? post,
}) => (post ?? FcmScheduledNotificationService.debugPostOverride ?? http.post)(
  Uri.parse(
    '${FcmScheduledNotificationService._functionsBaseUrl}/registerNotification',
  ),
  headers: {
    'Authorization': 'Bearer $idToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'typeId': typeId,
    'hour': hour,
    'minute': minute,
    'locale': locale,
    'gender': gender,
    'expectedMutationVersion': mutationVersion,
  }),
).timeout(FcmScheduledNotificationService._networkTimeout);

Future<bool> _persistRegisteredPreference({
  required UserInformation userInformation,
  required String typeId,
  required int hour,
  required int minute,
  required String idToken,
  required int resetEpoch,
  required int nextMutationVersion,
  NotificationHttpPost? post,
}) async {
  final preferences = NotificationRepository.forService(
    userInformation.service,
  );
  final previousPreference = preferences.getPreference(typeId);
  try {
    await preferences
        .setPreference(
          typeId,
          NotificationPreference(hour: hour, minute: minute),
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
  NotificationPreference? preference,
) async {
  try {
    final preferences = NotificationRepository.forService(
      userInformation.service,
    );
    final write = preference == null
        ? preferences.clearPreference(typeId)
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

/// Cancels the scheduled notification for [typeId].
///
/// Set [requireNoActiveDeliveryPermit] for actions, such as sign-out, that
/// must not complete after the scheduler has claimed a delivery. The call is
/// serialized with registration and returns `false` if its remote mutation,
/// local persistence, or required compensation cannot complete.
