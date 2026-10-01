import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_preferences_repository.dart';
import 'package:mazilon/features/notifications/data/reminder_debug_recorder.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/l10n/app_localizations_ar.dart';
import 'package:mazilon/l10n/app_localizations_en.dart';
import 'package:mazilon/l10n/app_localizations_he.dart';
import 'package:mazilon/util/userInformation.dart';

export 'package:mazilon/features/notifications/data/notification_preferences_repository.dart';

/// Coordinates scheduling and diagnostics through the preference owner.
extension NotificationRepositoryScheduling on NotificationRepository {
  Future<ReminderDebugSnapshot> readDebugSnapshot() =>
      readReminderDebugSnapshot();

  Future<void> clearDebugHistory() => clearReminderDebugEvents();

  Future<bool> rescheduleDefaultReminder(UserInformation userInformation) =>
      rescheduleEnabledReminder(
        userInformation: userInformation,
        typeId: 'default',
        currentPreference: () => getPreference('default'),
      );

  /// Refreshes a static schedule after the app locale changes.
  Future<bool> rescheduleTextReminder(
    UserInformation userInformation,
    String typeId,
    String body,
  ) => rescheduleEnabledReminder(
    userInformation: userInformation,
    typeId: typeId,
    currentPreference: () => getPreference(typeId),
    staticBody: body,
  );

  /// Cancels fixed quick IDs and known custom schedules, including missing acks.
  Future<bool> cancelOtherReminders(
    UserInformation userInformation,
    Map<String, NotificationPreference> snapshot,
  ) async {
    final ids = <String>{
      ...QuickReminderType.values.map((type) => type.id),
      ...snapshot.keys.where((id) => id != 'default'),
      ...pausedAccountRemindersFor(userInformation.userId).keys,
      ...customReminders.map((reminder) => reminder.id),
    };
    for (final id in ids) {
      final cancelled =
          await FcmScheduledNotificationService.cancelNotification(
            userInformation: userInformation,
            typeId: id,
            requireNoActiveDeliveryPermit: true,
          );
      if (!cancelled) return false;
    }
    return true;
  }

  /// Restores a snapshot after reset or sign-out fails.
  Future<bool> restoreSchedules(
    UserInformation userInformation,
    Map<String, NotificationPreference> snapshot,
  ) async {
    final locale = _reminderLocalizations(userInformation.localeName);
    var restored = true;
    for (final entry in snapshot.entries) {
      final preference = entry.value;
      try {
        final applied = entry.key == 'default'
            ? await FcmScheduledNotificationService.registerNotification(
                userInformation: userInformation,
                typeId: entry.key,
                hour: preference.hour,
                minute: preference.minute,
              )
            : await registerTextReminder(
                userInformation: userInformation,
                typeId: entry.key,
                hour: preference.hour,
                minute: preference.minute,
                title: preference.staticTitle ?? 'Living Positively',
                body: _restoredReminderBody(entry.key, preference, locale),
              );
        restored = applied && restored;
      } on NotificationReminderLimitException {
        restored = false;
      }
    }
    return restored;
  }

  Future<bool> resumePausedReminders(UserInformation userInformation) async {
    final locale = _reminderLocalizations(userInformation.localeName);
    final uid = userInformation.userId;
    var restored = true;
    for (final entry in pausedAccountRemindersFor(uid).entries) {
      final current = pausedAccountRemindersFor(uid)[entry.key];
      if (current == null) continue;
      try {
        final applied = await registerPausedTextReminder(
          userInformation: userInformation,
          typeId: entry.key,
          currentPreference: () => pausedAccountRemindersFor(uid)[entry.key],
          bodyFor: (preference) =>
              _restoredReminderBody(entry.key, preference, locale),
        );
        restored = applied && restored;
      } catch (_) {
        restored = false;
      }
    }
    return restored;
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

AppLocalizations _reminderLocalizations(String localeName) {
  final language = localeName.trim().split(RegExp('[-_]')).first.toLowerCase();
  return switch (language) {
    'ar' => AppLocalizationsAr(),
    'en' => AppLocalizationsEn(),
    _ => AppLocalizationsHe(),
  };
}

String _restoredReminderBody(
  String typeId,
  NotificationPreference preference,
  AppLocalizations locale,
) {
  for (final type in QuickReminderType.values) {
    if (type.id == typeId) return type.label(locale);
  }
  return switch ((preference.staticBody, preference.staticTitle)) {
    (final body?, _) when body.trim().isNotEmpty => body,
    (_, final title?) when title.trim().isNotEmpty => title,
    _ => 'Living Positively',
  };
}
