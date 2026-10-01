import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';

/// A fixed quick reminder shown on the settings page.
final class QuickReminderPreset {
  const QuickReminderPreset(this.id, this.emoji, this.label);

  final String id;
  final String emoji;
  final String label;
}

List<QuickReminderPreset> quickReminderPresets(AppLocalizations locale) => [
  QuickReminderPreset(
    QuickReminderType.exercise.id,
    '💪🏻',
    QuickReminderType.exercise.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.pills.id,
    '💊',
    QuickReminderType.pills.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.meditate.id,
    '🧘🏻‍♀️',
    QuickReminderType.meditate.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.water.id,
    '💧',
    QuickReminderType.water.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.read.id,
    '📖',
    QuickReminderType.read.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.sleep.id,
    '🌙',
    QuickReminderType.sleep.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.journal.id,
    '📓',
    QuickReminderType.journal.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.stretch.id,
    '🤸',
    QuickReminderType.stretch.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.breathe.id,
    '🌬️',
    QuickReminderType.breathe.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.music.id,
    '🎵',
    QuickReminderType.music.label(locale),
  ),
  QuickReminderPreset(
    QuickReminderType.friend.id,
    '🤝',
    QuickReminderType.friend.label(locale),
  ),
];
