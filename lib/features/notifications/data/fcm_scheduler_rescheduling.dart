part of 'fcm_scheduled_notification_service.dart';

/// Refreshes a locale using the enabled preference when its queue turn starts.
Future<bool> rescheduleEnabledReminder({
  required UserInformation userInformation,
  required String typeId,
  required NotificationPreference? Function() currentPreference,
  String? staticBody,
}) {
  final resetEpoch = FcmScheduledNotificationService._resetEpoch;
  return _enqueue(() {
    final preference = currentPreference();
    // A preceding cancellation completes the refresh without re-enabling it.
    if (preference == null) return Future.value(true);
    return _registerNotification(
      userInformation: userInformation,
      typeId: typeId,
      hour: preference.hour,
      minute: preference.minute,
      staticTitle: staticBody == null
          ? null
          : preference.staticTitle ?? 'Living Positively',
      staticBody: staticBody,
      resetEpoch: resetEpoch,
    );
  });
}
