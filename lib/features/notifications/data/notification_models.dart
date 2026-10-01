import 'package:mazilon/l10n/app_localizations.dart';

const maxRemindersPerUser = 32;

/// The server refused another schedule because this account is at capacity.
class NotificationReminderLimitException implements Exception {
  const NotificationReminderLimitException();
}

/// A validated local time for an enabled scheduled notification.
class NotificationPreference {
  const NotificationPreference({
    required this.hour,
    required this.minute,
  }) : staticTitle = null,
       staticBody = null;

  const NotificationPreference.withContent({
    required this.hour,
    required this.minute,
    required this.staticTitle,
    required this.staticBody,
  });

  final int hour;
  final int minute;
  final String? staticTitle;
  final String? staticBody;

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'minute': minute,
    if (staticTitle != null) 'staticTitle': staticTitle,
    if (staticBody != null) 'staticBody': staticBody,
  };

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    final hour = _parseInt(json['hour']);
    final minute = _parseInt(json['minute']);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('Invalid notification preference time');
    }
    final title = json['staticTitle'];
    final body = json['staticBody'];
    if ((title != null && (title is! String || title.length > 100)) ||
        (body != null && (body is! String || body.length > 240))) {
      throw const FormatException('Invalid notification content');
    }
    if (title == null && body == null) {
      return NotificationPreference(hour: hour, minute: minute);
    }
    return NotificationPreference.withContent(
      hour: hour,
      minute: minute,
      staticTitle: title as String?,
      staticBody: body as String?,
    );
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// A custom reminder's identity and presentation, retained while disabled.
class CustomReminder {
  const CustomReminder({
    required this.id,
    required this.emoji,
    required this.label,
    required this.hour,
    required this.minute,
  });

  final String id;
  final String emoji;
  final String label;
  final int hour;
  final int minute;

  Map<String, Object> toJson() => {
    'id': id,
    'emoji': emoji,
    'label': label,
    'hour': hour,
    'minute': minute,
  };

  factory CustomReminder.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final emoji = json['emoji'];
    final label = json['label'];
    final hour = json['hour'];
    final minute = json['minute'];
    if (id is! String ||
        !RegExp(r'^custom_[A-Za-z0-9_-]{1,40}$').hasMatch(id) ||
        emoji is! String ||
        emoji.runes.length > 16 ||
        label is! String ||
        label.trim().isEmpty ||
        label.length > 240 ||
        hour is! int ||
        hour < 0 ||
        hour > 23 ||
        minute is! int ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('Invalid custom reminder');
    }
    return CustomReminder(
      id: id,
      emoji: emoji,
      label: label,
      hour: hour,
      minute: minute,
    );
  }
}

enum QuickReminderType {
  exercise('quick_exercise'),
  pills('quick_pills'),
  meditate('quick_meditate'),
  water('quick_water'),
  read('quick_read'),
  sleep('quick_sleep'),
  journal('quick_journal'),
  stretch('quick_stretch'),
  breathe('quick_breathe'),
  music('quick_music'),
  friend('quick_friend');

  const QuickReminderType(this.id);

  final String id;

  String label(AppLocalizations locale) => switch (this) {
    QuickReminderType.exercise => locale.reminderQuickExercise,
    QuickReminderType.pills => locale.reminderQuickPills,
    QuickReminderType.meditate => locale.reminderQuickMeditate,
    QuickReminderType.water => locale.reminderQuickWater,
    QuickReminderType.read => locale.reminderQuickRead,
    QuickReminderType.sleep => locale.reminderQuickSleep,
    QuickReminderType.journal => locale.reminderQuickJournal,
    QuickReminderType.stretch => locale.reminderQuickStretch,
    QuickReminderType.breathe => locale.reminderQuickBreathe,
    QuickReminderType.music => locale.reminderQuickMusic,
    QuickReminderType.friend => locale.reminderQuickFriend,
  };
}
