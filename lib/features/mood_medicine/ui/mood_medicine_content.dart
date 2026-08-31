import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';

final class _MoodMedicineActivityPaletteEntry {
  const _MoodMedicineActivityPaletteEntry(this.id, this.color);

  final String id;
  final Color color;
}

/// Localized educational content for a default Mood Medicine activity.
final class MoodMedicineActivityContent {
  const MoodMedicineActivityContent({
    required this.id,
    required this.color,
    required this.label,
    required this.description,
    required this.guidance,
    required this.sourceLabel,
    required this.sourceUri,
    required this.icon,
  });

  /// Stable nonlocalized activity identifier persisted with check-ins.
  final String id;

  /// Feature-local colour cue based on the approved Mood Medicine design.
  ///
  /// UI must pair this with the localized [label], rather than conveying an
  /// activity through colour alone.
  final Color color;

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

/// Stable, nonlocalized categories used to colour the D.O.S.E. education card.
enum MoodMedicineDoseKind { dopamine, oxytocin, serotonin, endorphins }

/// Localized explanatory item in the D.O.S.E. education card.
final class MoodMedicineDoseContent {
  const MoodMedicineDoseContent({
    required this.kind,
    required this.color,
    required this.title,
    required this.description,
  });

  /// Stable category for this D.O.S.E. education item.
  final MoodMedicineDoseKind kind;

  /// Feature-local colour cue based on the approved Mood Medicine design.
  final Color color;

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

  /// Ordered default activity IDs and their PDF-derived colour cues.
  ///
  /// This palette is the single source for both [defaultActivityIds] and
  /// [activityColors]. Custom activities deliberately remain outside it: their
  /// persisted labels remain the accessible identifier and the UI uses its
  /// themed fallback.
  static const List<_MoodMedicineActivityPaletteEntry>
  _activityPalette = <_MoodMedicineActivityPaletteEntry>[
    _MoodMedicineActivityPaletteEntry(physicalActivityId, Color(0xFF1875D1)),
    _MoodMedicineActivityPaletteEntry(restorativeSleepId, Color(0xFF993399)),
    _MoodMedicineActivityPaletteEntry(nourishingMealId, Color(0xFFFFD54E)),
    _MoodMedicineActivityPaletteEntry(socialConnectionId, Color(0xFFF34235)),
    _MoodMedicineActivityPaletteEntry(daylightNatureId, Color(0xFF7BB241)),
    _MoodMedicineActivityPaletteEntry(musicId, Color(0xFF0899CC)),
    _MoodMedicineActivityPaletteEntry(laughterId, Color(0xFFFF8642)),
    _MoodMedicineActivityPaletteEntry(actsOfKindnessId, Color(0xFFFE9701)),
  ];

  /// Ordered stable IDs for the eight default activities.
  static final List<String> defaultActivityIds = List<String>.unmodifiable(
    _activityPalette.map((entry) => entry.id),
  );

  /// Colour cues for the eight default activities.
  static final Map<String, Color> activityColors =
      Map<String, Color>.unmodifiable(<String, Color>{
        for (final _MoodMedicineActivityPaletteEntry entry in _activityPalette)
          entry.id: entry.color,
      });

  /// Resolves an activity colour from [palette], using [fallback] for custom
  /// activities that do not have a fixed palette colour.
  static Color resolveActivityColor(
    String activityId, {
    required Map<String, Color> palette,
    required Color fallback,
  }) {
    return palette[activityId] ?? fallback;
  }

  static const Color _dopamineColor = Color(0xFF009933);
  static const Color _oxytocinColor = Color(0xFF993399);
  static const Color _serotoninColor = Color(0xFFFF8642);
  static const Color _endorphinsColor = Color(0xFF0899CC);

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
        color: activityColors[physicalActivityId]!,
        label: l10n.moodMedicineActivityPhysicalActivity,
        description: l10n.moodMedicineActivityPhysicalActivityDescription,
        guidance: l10n.moodMedicineActivityPhysicalActivityGuidance,
        sourceLabel: l10n.moodMedicineSourceWhoPhysicalActivity,
        sourceUri: _whoPhysicalActivityUri,
        icon: Icons.directions_walk_rounded,
      ),
      MoodMedicineActivityContent(
        id: restorativeSleepId,
        color: activityColors[restorativeSleepId]!,
        label: l10n.moodMedicineActivityRestorativeSleep,
        description: l10n.moodMedicineActivityRestorativeSleepDescription,
        guidance: l10n.moodMedicineActivityRestorativeSleepGuidance,
        sourceLabel: l10n.moodMedicineSourceCdcSleep,
        sourceUri: _cdcSleepUri,
        icon: Icons.bedtime_rounded,
      ),
      MoodMedicineActivityContent(
        id: nourishingMealId,
        color: activityColors[nourishingMealId]!,
        label: l10n.moodMedicineActivityNourishingMeal,
        description: l10n.moodMedicineActivityNourishingMealDescription,
        guidance: l10n.moodMedicineActivityNourishingMealGuidance,
        sourceLabel: l10n.moodMedicineSourceNimhSelfCare,
        sourceUri: _nimhSelfCareUri,
        icon: Icons.restaurant_rounded,
      ),
      MoodMedicineActivityContent(
        id: socialConnectionId,
        color: activityColors[socialConnectionId]!,
        label: l10n.moodMedicineActivitySocialConnection,
        description: l10n.moodMedicineActivitySocialConnectionDescription,
        guidance: l10n.moodMedicineActivitySocialConnectionGuidance,
        sourceLabel: l10n.moodMedicineSourceCdcConnection,
        sourceUri: _cdcConnectionUri,
        icon: Icons.people_alt_rounded,
      ),
      MoodMedicineActivityContent(
        id: daylightNatureId,
        color: activityColors[daylightNatureId]!,
        label: l10n.moodMedicineActivityDaylightNature,
        description: l10n.moodMedicineActivityDaylightNatureDescription,
        guidance: l10n.moodMedicineActivityDaylightNatureGuidance,
        sourceLabel: l10n.moodMedicineSourceNimhSelfCare,
        sourceUri: _nimhSelfCareUri,
        icon: Icons.wb_sunny_outlined,
      ),
      MoodMedicineActivityContent(
        id: musicId,
        color: activityColors[musicId]!,
        label: l10n.moodMedicineActivityMusic,
        description: l10n.moodMedicineActivityMusicDescription,
        guidance: l10n.moodMedicineActivityMusicGuidance,
        sourceLabel: l10n.moodMedicineSourceNimhSelfCare,
        sourceUri: _nimhSelfCareUri,
        icon: Icons.music_note_rounded,
      ),
      MoodMedicineActivityContent(
        id: laughterId,
        color: activityColors[laughterId]!,
        label: l10n.moodMedicineActivityLaughter,
        description: l10n.moodMedicineActivityLaughterDescription,
        guidance: l10n.moodMedicineActivityLaughterGuidance,
        sourceLabel: l10n.moodMedicineSourceNimhSelfCare,
        sourceUri: _nimhSelfCareUri,
        icon: Icons.sentiment_very_satisfied_outlined,
      ),
      MoodMedicineActivityContent(
        id: actsOfKindnessId,
        color: activityColors[actsOfKindnessId]!,
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
        kind: MoodMedicineDoseKind.dopamine,
        color: _dopamineColor,
        title: l10n.moodMedicineDoseDopamine,
        description: l10n.moodMedicineDoseDopamineDescription,
      ),
      MoodMedicineDoseContent(
        kind: MoodMedicineDoseKind.oxytocin,
        color: _oxytocinColor,
        title: l10n.moodMedicineDoseOxytocin,
        description: l10n.moodMedicineDoseOxytocinDescription,
      ),
      MoodMedicineDoseContent(
        kind: MoodMedicineDoseKind.serotonin,
        color: _serotoninColor,
        title: l10n.moodMedicineDoseSerotonin,
        description: l10n.moodMedicineDoseSerotoninDescription,
      ),
      MoodMedicineDoseContent(
        kind: MoodMedicineDoseKind.endorphins,
        color: _endorphinsColor,
        title: l10n.moodMedicineDoseEndorphins,
        description: l10n.moodMedicineDoseEndorphinsDescription,
      ),
    ];
  }
}
