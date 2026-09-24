part of 'fcm_scheduled_notification_service.dart';

Future<bool> _cancelNotification({
  required UserInformation userInformation,
  required String typeId,
  Future<String?> Function()? idTokenProvider,
  NotificationHttpPost? post,
  required int resetEpoch,
  bool resetFence = false,
  Future<void> Function(int notificationId)? legacyNotificationCanceller,
  void Function(NotificationPreference? remotePreference)?
  onRemoteScheduleCancelled,
}) async {
  if (resetEpoch != FcmScheduledNotificationService._resetEpoch) return false;
  _log('Cancelling notification: typeId=$typeId');
  final userInfo = userInformation;
  try {
    final idToken = await (idTokenProvider ?? _getIdToken)().timeout(
      FcmScheduledNotificationService._networkTimeout,
    );
    if (idToken == null) return false;
    if (resetEpoch != FcmScheduledNotificationService._resetEpoch) return false;
    final expectedMutationVersion = await _getNotificationMutationVersion(
      idToken: idToken,
      typeId: typeId,
      post: post,
    );
    if (expectedMutationVersion == null ||
        resetEpoch != FcmScheduledNotificationService._resetEpoch) {
      return false;
    }
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
                if (resetFence) 'resetFence': true,
              }),
            )
            .timeout(FcmScheduledNotificationService._networkTimeout);

    if (response.statusCode == 200) {
      return await _finishCancellation(
        userInformation: userInfo,
        typeId: typeId,
        response: response,
        expectedMutationVersion: expectedMutationVersion,
        idToken: idToken,
        post: post,
        resetEpoch: resetEpoch,
        legacyNotificationCanceller: legacyNotificationCanceller,
        onRemoteScheduleCancelled: onRemoteScheduleCancelled,
      );
    } else {
      _log(
        'cancelNotification failed: ${response.statusCode} ${response.body}',
      );
      return false;
    }
  } catch (error, stackTrace) {
    _reportNotificationFailure('cancelNotification error', error, stackTrace);
    return false;
  }
}

Future<bool> _finishCancellation({
  required UserInformation userInformation,
  required String typeId,
  required http.Response response,
  required int expectedMutationVersion,
  required String idToken,
  required int resetEpoch,
  NotificationHttpPost? post,
  Future<void> Function(int)? legacyNotificationCanceller,
  void Function(NotificationPreference?)? onRemoteScheduleCancelled,
}) async {
  final nextVersion = _successfulMutationVersion(
    response,
    expectedMutationVersion,
  );
  if (nextVersion == null) return false;
  final cancelledSchedule = _cancelledSchedulePreference(response);
  onRemoteScheduleCancelled?.call(cancelledSchedule);
  _log('Notification cancelled successfully.');
  if (typeId == 'default' &&
      !await _retireLegacyAfterCancellation(
        userInformation: userInformation,
        typeId: typeId,
        cancelledSchedule: cancelledSchedule,
        idToken: idToken,
        post: post,
        resetEpoch: resetEpoch,
        nextVersion: nextVersion,
        legacyNotificationCanceller: legacyNotificationCanceller,
      )) {
    return false;
  }
  return _clearPreferenceAfterCancellation(
    userInformation: userInformation,
    typeId: typeId,
    cancelledSchedule: cancelledSchedule,
    idToken: idToken,
    post: post,
    resetEpoch: resetEpoch,
    nextVersion: nextVersion,
  );
}

Future<bool> _retireLegacyAfterCancellation({
  required UserInformation userInformation,
  required String typeId,
  required NotificationPreference? cancelledSchedule,
  required String idToken,
  required int resetEpoch,
  required int nextVersion,
  NotificationHttpPost? post,
  Future<void> Function(int)? legacyNotificationCanceller,
}) async {
  var handled = false;
  try {
    await _cancelLegacyDefaultReminder(
      userInformation,
      legacyNotificationCanceller,
    );
    handled = await _markLegacyDefaultReminderHandled(userInformation);
  } catch (error) {
    _log('Unable to retire the legacy local reminder: $error');
  }
  if (handled) return true;
  await _restoreCancelledSchedule(
    userInformation: userInformation,
    typeId: typeId,
    cancelledSchedule: cancelledSchedule,
    idToken: idToken,
    post: post,
    resetEpoch: resetEpoch,
    nextVersion: nextVersion,
    failureMessage:
        'Unable to compensate a failed legacy reminder cancellation.',
  );
  return false;
}

Future<bool> _clearPreferenceAfterCancellation({
  required UserInformation userInformation,
  required String typeId,
  required NotificationPreference? cancelledSchedule,
  required String idToken,
  required int resetEpoch,
  required int nextVersion,
  NotificationHttpPost? post,
}) async {
  try {
    await NotificationRepository.forService(userInformation.service)
        .clearPreference(typeId)
        .timeout(
          FcmScheduledNotificationService._legacyMigrationOperationTimeout,
        );
    return true;
  } catch (error) {
    _log('Unable to persist cancelled notification: $error');
    if (cancelledSchedule == null) {
      _log('Cannot compensate a cancellation without its remote schedule.');
      return false;
    }
    final restoredLocally = await _restoreLocalNotificationPreference(
      userInformation,
      typeId,
      cancelledSchedule,
    );
    await _restoreCancelledSchedule(
      userInformation: userInformation,
      typeId: typeId,
      cancelledSchedule: cancelledSchedule,
      idToken: idToken,
      post: post,
      resetEpoch: resetEpoch,
      nextVersion: nextVersion,
      failureMessage:
          'Unable to compensate a notification cancellation failure.',
    );
    if (!restoredLocally) {
      _log('Unable to restore local notification state after cancellation.');
    }
    return false;
  }
}

Future<bool> _restoreCancelledSchedule({
  required UserInformation userInformation,
  required String typeId,
  required NotificationPreference? cancelledSchedule,
  required String idToken,
  required int resetEpoch,
  required int nextVersion,
  required String failureMessage,
  NotificationHttpPost? post,
}) async {
  if (cancelledSchedule == null) {
    _log('Cannot compensate a cancellation without its remote schedule.');
    return false;
  }
  final restored = await _registerNotification(
    userInformation: userInformation,
    typeId: typeId,
    hour: cancelledSchedule.hour,
    minute: cancelledSchedule.minute,
    idTokenProvider: () async => idToken,
    post: post,
    resetEpoch: resetEpoch,
    allowUnsupportedPlatform: true,
    persistLocalPreference: false,
    expectedMutationVersion: nextVersion,
  );
  if (!restored) _log(failureMessage);
  return restored;
}

Future<bool> _markLegacyDefaultReminderHandled(
  UserInformation userInformation,
) async {
  try {
    await userInformation.service
        .setItem(
          FcmScheduledNotificationService._legacyDefaultReminderMigrationKey,
          PersistentMemoryType.Bool,
          true,
        )
        .timeout(
          FcmScheduledNotificationService._legacyMigrationOperationTimeout,
        );
    return true;
  } catch (error, stackTrace) {
    _reportNotificationFailure(
      'Unable to persist legacy reminder cancellation',
      error,
      stackTrace,
    );
    return false;
  }
}

Future<void> _cancelLegacyDefaultReminder(
  UserInformation userInformation,
  Future<void> Function(int notificationId)? legacyNotificationCanceller,
) async {
  final memory = userInformation.service;
  final migrated =
      await memory
          .getItem(
            FcmScheduledNotificationService._legacyDefaultReminderMigrationKey,
            PersistentMemoryType.Bool,
          )
          .timeout(
            FcmScheduledNotificationService._legacyMigrationOperationTimeout,
          ) ??
      false;
  if (migrated == true) return;

  // The legacy notification ID is part of the retired Android scheduler's
  // persisted contract. Only cancel it when its explicit enabled marker
  // proves that this device created that legacy alarm; stored time values
  // alone are also present on installs that never had an active reminder.
  final legacyPreference = await _legacyDefaultReminderPreference(
    memory,
    requiresEnabledMarker: true,
  );
  if (legacyPreference == null) return;
  await (legacyNotificationCanceller ??
          FcmService.cancelLegacyLocalNotification)(
        _legacyLocalNotificationId(legacyPreference),
      )
      .timeout(
        FcmScheduledNotificationService._legacyMigrationOperationTimeout,
      );
}
