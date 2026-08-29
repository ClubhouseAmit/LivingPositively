import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';

/// Localized educational content for a default Mood Medicine activity.
final class MoodMedicineActivityContent {
  const MoodMedicineActivityContent({
    required this.id,
    required this.label,
    required this.description,
    required this.guidance,
    required this.sourceLabel,
    required this.sourceUri,
    required this.icon,
  });

  /// Stable nonlocalized activity identifier persisted with check-ins.
  final String id;

  /// Localized activity label.
  final String label;

  /// Localized, non-diagnostic description of the activity.
  final String description;

  /// Localized educational guidance, including authoritative doses where known.
  final String guidance;

  /// Localized title for the external educational source.
  final String sourceLabel;

  /// Authoritative external source for the educational guidance.
  final Uri sourceUri;

  /// Visual identifier for the activity in the feature UI.
  final IconData icon;
}

/// Localized explanatory item in the D.O.S.E. education card.
final class MoodMedicineDoseContent {
  const MoodMedicineDoseContent({
    required this.title,
    required this.description,
  });

  /// Localized name of the neurotransmitter or hormone system.
  final String title;

  /// Localized educational explanation.
  final String description;
}

/// The feature-local source-backed activity and D.O.S.E. catalogue.
///
/// The stable IDs in this class are part of the Mood Medicine local snapshot.
/// They deliberately remain unlocalized so that a saved entry can be rendered
/// in any supported locale.
final class MoodMedicineContent {
  MoodMedicineContent._();

  static const String physicalActivityId = 'physical_activity';
  static const String restorativeSleepId = 'restorative_sleep';
  static const String nourishingMealId = 'nourishing_meal';
  static const String socialConnectionId = 'social_connection';
  static const String daylightNatureId = 'daylight_nature';
  static const String musicId = 'music';
  static const String laughterId = 'laughter';
  static const String actsOfKindnessId = 'acts_of_kindness';

  /// Ordered stable IDs for the eight default activities.
  static const List<String> defaultActivityIds = <String>[
    physicalActivityId,
    restorativeSleepId,
    nourishingMealId,
    socialConnectionId,
    daylightNatureId,
    musicId,
    laughterId,
    actsOfKindnessId,
  ];

  static final Uri _whoPhysicalActivityUri = Uri.parse(
    'https://www.who.int/news-room/fact-sheets/detail/physical-activity',
  );
  static final Uri _cdcSleepUri = Uri.parse(
    'https://www.cdc.gov/sleep/about/index.html',
  );
  static final Uri _nimhSelfCareUri = Uri.parse(
    'https://www.nimh.nih.gov/health/topics/caring-for-your-mental-health',
  );
  static final Uri _cdcConnectionUri = Uri.parse(
    'https://www.cdc.gov/social-connectedness/improving/index.html',
  );

  /// Returns the eight default activities in their display order.
  static List<MoodMedicineActivityContent> activities(AppLocalizations l10n) {
    return <MoodMedicineActivityContent>[
      MoodMedicineActivityContent(
        id: physicalActivityId,
        label: l10n.moodMedicineActivityPhysicalActivity,
        description: l10n.moodMedicineActivityPhysicalActivityDescription,
        guidance: l10n.moodMedicineActivityPhysicalActivityGuidance,
        sourceLabel: l10n.moodMedicineSourceWhoPhysicalActivity,
        sourceUri: _whoPhysicalActivityUri,
        icon: Icons.directions_walk_rounded,
      ),
      MoodMedicineActivityContent(
        id: restorativeSleepId,
        label: l10n.moodMedicineActivityRestorativeSleep,
        description: l10n.moodMedicineActivityRestorativeSleepDescription,
        guidance: l10n.moodMedicineActivityRestorativeSleepGuidance,
        sourceLabel: l10n.moodMedicineSourceCdcSleep,
        sourceUri: _cdcSleepUri,
        icon: Icons.bedtime_rounded,
      ),
      MoodMedicineActivityContent(
        id: nourishingMealId,
        label: l10n.moodMedicineActivityNourishingMeal,
        description: l10n.moodMedicineActivityNourishingMealDescription,
        guidance: l10n.moodMedicineActivityNourishingMealGuidance,
        sourceLabel: l10n.moodMedicineSourceNimhSelfCare,
        sourceUri: _nimhSelfCareUri,
        icon: Icons.restaurant_rounded,
      ),
      MoodMedicineActivityContent(
        id: socialConnectionId,
        label: l10n.moodMedicineActivitySocialConnection,
        description: l10n.moodMedicineActivitySocialConnectionDescription,
        guidance: l10n.moodMedicineActivitySocialConnectionGuidance,
        sourceLabel: l10n.moodMedicineSourceCdcConnection,
        sourceUri: _cdcConnectionUri,
        icon: Icons.people_alt_rounded,
      ),
      MoodMedicineActivityContent(
        id: daylightNatureId,
        label: l10n.moodMedicineActivityDaylightNature,
        description: l10n.moodMedicineActivityDaylightNatureDescription,
        guidance: l10n.moodMedicineActivityDaylightNatureGuidance,
        sourceLabel: l10n.moodMedicineSourceNimhSelfCare,
        sourceUri: _nimhSelfCareUri,
        icon: Icons.wb_sunny_outlined,
      ),
      MoodMedicineActivityContent(
        id: musicId,
        label: l10n.moodMedicineActivityMusic,
        description: l10n.moodMedicineActivityMusicDescription,
        guidance: l10n.moodMedicineActivityMusicGuidance,
        sourceLabel: l10n.moodMedicineSourceNimhSelfCare,
        sourceUri: _nimhSelfCareUri,
        icon: Icons.music_note_rounded,
      ),
      MoodMedicineActivityContent(
        id: laughterId,
        label: l10n.moodMedicineActivityLaughter,
        description: l10n.moodMedicineActivityLaughterDescription,
        guidance: l10n.moodMedicineActivityLaughterGuidance,
        sourceLabel: l10n.moodMedicineSourceNimhSelfCare,
        sourceUri: _nimhSelfCareUri,
        icon: Icons.sentiment_very_satisfied_outlined,
      ),
      MoodMedicineActivityContent(
        id: actsOfKindnessId,
        label: l10n.moodMedicineActivityActsOfKindness,
        description: l10n.moodMedicineActivityActsOfKindnessDescription,
        guidance: l10n.moodMedicineActivityActsOfKindnessGuidance,
        sourceLabel: l10n.moodMedicineSourceCdcConnection,
        sourceUri: _cdcConnectionUri,
        icon: Icons.volunteer_activism_rounded,
      ),
    ];
  }

  /// Returns the default activity with [id], or null if [id] is not known.
  static MoodMedicineActivityContent? activityFor(
    AppLocalizations l10n,
    String id,
  ) {
    for (final MoodMedicineActivityContent activity in activities(l10n)) {
      if (activity.id == id) {
        return activity;
      }
    }
    return null;
  }

  /// Returns localized items for the D.O.S.E. education card.
  static List<MoodMedicineDoseContent> doseItems(AppLocalizations l10n) {
    return <MoodMedicineDoseContent>[
      MoodMedicineDoseContent(
        title: l10n.moodMedicineDoseDopamine,
        description: l10n.moodMedicineDoseDopamineDescription,
      ),
      MoodMedicineDoseContent(
        title: l10n.moodMedicineDoseOxytocin,
        description: l10n.moodMedicineDoseOxytocinDescription,
      ),
      MoodMedicineDoseContent(
        title: l10n.moodMedicineDoseSerotonin,
        description: l10n.moodMedicineDoseSerotoninDescription,
      ),
      MoodMedicineDoseContent(
        title: l10n.moodMedicineDoseEndorphins,
        description: l10n.moodMedicineDoseEndorphinsDescription,
      ),
    ];
  }
}
