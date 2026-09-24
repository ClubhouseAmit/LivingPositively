import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_preferences_repository.dart';
import 'package:mazilon/features/notifications/data/reminder_debug_recorder.dart';
import 'package:mazilon/util/userInformation.dart';

export 'package:mazilon/features/notifications/data/notification_preferences_repository.dart';

/// Coordinates scheduling and diagnostics through the preference owner.
extension NotificationRepositoryScheduling on NotificationRepository {
  Future<ReminderDebugSnapshot> readDebugSnapshot() =>
      readReminderDebugSnapshot();

  Future<void> clearDebugHistory() => clearReminderDebugEvents();

  Future<bool> rescheduleDefaultReminder(UserInformation userInformation) {
    final preference = getPreference('default');
    if (preference == null) return Future<bool>.value(false);
    return FcmScheduledNotificationService.registerNotification(
      userInformation: userInformation,
      typeId: 'default',
      hour: preference.hour,
      minute: preference.minute,
    );
  }

  /// Cancels the default schedule before local account data is reset.
  Future<bool> cancelDefaultForReset({
    required UserInformation userInformation,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    void Function(NotificationPreference? remotePreference)?
    onRemoteScheduleCancelled,
  }) {
    return FcmScheduledNotificationService.cancelDefaultForReset(
      userInformation: userInformation,
      idTokenProvider: idTokenProvider,
      post: post,
      onRemoteScheduleCancelled: onRemoteScheduleCancelled,
    );
  }

  /// Cancels the default schedule before the authenticated session ends.
  Future<bool> cancelDefaultForSignOut({
    required UserInformation userInformation,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    Future<void> Function(int notificationId)? legacyNotificationCanceller,
    void Function(NotificationPreference? remotePreference)?
    onRemoteScheduleCancelled,
  }) {
    return FcmScheduledNotificationService.cancelDefaultForSignOut(
      userInformation: userInformation,
      idTokenProvider: idTokenProvider,
      post: post,
      legacyNotificationCanceller: legacyNotificationCanceller,
      onRemoteScheduleCancelled: onRemoteScheduleCancelled,
    );
  }

  /// Restores a cancelled remote schedule after reset or sign-out fails.
  Future<bool> restoreDefaultReminderAfterResetFailure({
    required UserInformation userInformation,
    NotificationPreference? previousPreference,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
  }) {
    return FcmScheduledNotificationService.restoreDefaultReminderAfterResetFailure(
      userInformation: userInformation,
      previousPreference: previousPreference,
      idTokenProvider: idTokenProvider,
      post: post,
    );
  }
}
