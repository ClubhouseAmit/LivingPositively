import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/ui/reminder_quick_presets.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/userInformation.dart';

int _refreshGeneration = 0;

/// Refreshes active FCM schedules after the app's existing language switch.
Future<void> rescheduleNotificationsForLocale(
  UserInformation userInformation,
  AppLocalizations locale,
) async {
  final generation = ++_refreshGeneration;
  if (!userInformation.loggedIn) return;
  for (var attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(Duration(seconds: attempt == 1 ? 5 : 30));
    }
    if (generation != _refreshGeneration) return;
    if (await _refreshSchedules(userInformation, locale)) return;
  }
}

Future<bool> _refreshSchedules(
  UserInformation userInformation,
  AppLocalizations locale,
) async {
  final repository = NotificationRepository.forService(userInformation.service);
  final labels = {
    for (final preset in quickReminderPresets(locale)) preset.id: preset.label,
    for (final reminder in repository.customReminders)
      reminder.id: reminder.label,
  };
  var complete = true;
  for (final entry in repository.preferences.entries) {
    if (entry.key == 'default') {
      complete =
          await repository.rescheduleDefaultReminder(userInformation) &&
          complete;
      continue;
    }
    final body = labels[entry.key] ?? entry.value.staticBody;
    if (body == null) continue;
    try {
      complete =
          await repository.rescheduleTextReminder(
            userInformation,
            entry.key,
            body,
          ) &&
          complete;
    } on NotificationReminderLimitException {
      complete = false;
    }
  }
  return complete;
}
