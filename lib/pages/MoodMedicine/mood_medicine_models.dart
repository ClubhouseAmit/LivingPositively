import 'dart:collection';
import 'dart:convert';

/// The only persisted schema supported by the Mood Medicine feature.
const int moodMedicineSnapshotVersion = 1;

/// Stable, non-localized identifiers for the eight built-in activities.
///
/// Labels and explanatory content intentionally live in the presentation layer.
const Set<String> moodMedicineDefaultActivityIds = <String>{
  'physical_activity',
  'restorative_sleep',
  'nourishing_meal',
  'social_connection',
  'daylight_nature',
  'music',
  'laughter',
  'acts_of_kindness',
};

/// Formats a [DateTime] as the feature's local calendar-day key.
String moodMedicineLocalDayKey(DateTime value) {
  final DateTime local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// A user-created activity that can be selected in future check-ins.
final class MoodMedicineCustomActivity {
  MoodMedicineCustomActivity({required String id, required String label})
    : id = id.trim(),
      label = label.trim() {
    if (this.id.isEmpty || this.label.isEmpty) {
      throw ArgumentError('Custom activities need an id and a label.');
    }
  }

  final String id;
  final String label;

  Map<String, Object> toJson() => <String, Object>{'id': id, 'label': label};

  static MoodMedicineCustomActivity? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final String id = _trimmedString(value['id']);
    final String label = _trimmedString(value['label']);
    if (id.isEmpty || label.isEmpty) {
      return null;
    }
    return MoodMedicineCustomActivity(id: id, label: label);
  }

  MoodMedicineCustomActivity copyWith({String? label}) =>
      MoodMedicineCustomActivity(id: id, label: label ?? this.label);
}

/// An immutable check-in draft retained after a persistence failure.
final class MoodMedicineCheckInDraft {
  MoodMedicineCheckInDraft({
    required this.mood,
    Iterable<String> emotionIds = const <String>[],
    Iterable<String> activityIds = const <String>[],
    String? note,
  }) : emotionIds = List<String>.unmodifiable(_normalizeIds(emotionIds)),
       activityIds = List<String>.unmodifiable(_normalizeIds(activityIds)),
       note = _optionalTrimmedString(note);

  final int mood;
  final List<String> emotionIds;
  final List<String> activityIds;
  final String? note;
}

/// One timestamped, local-day-aware mood check-in.
final class MoodMedicineEntry {
  MoodMedicineEntry({
    required String id,
    required DateTime occurredAtUtc,
    required String localDayKey,
    required this.mood,
    Iterable<String> emotionIds = const <String>[],
    Iterable<String> activityIds = const <String>[],
    String? note,
    Map<String, String> customActivityLabelSnapshots = const <String, String>{},
  }) : id = id.trim(),
       occurredAtUtc = occurredAtUtc.toUtc(),
       localDayKey = localDayKey.trim(),
       emotionIds = List<String>.unmodifiable(_normalizeIds(emotionIds)),
       activityIds = List<String>.unmodifiable(_normalizeIds(activityIds)),
       note = _optionalTrimmedString(note),
       customActivityLabelSnapshots = UnmodifiableMapView<String, String>(
         _normalizeLabelSnapshots(customActivityLabelSnapshots),
       ) {
    if (this.id.isEmpty ||
        !isMoodMedicineLocalDayKey(this.localDayKey) ||
        mood < 1 ||
        mood > 5) {
      throw ArgumentError('Mood entries need valid ids, days, and moods.');
    }
  }

  final String id;
  final DateTime occurredAtUtc;
  final String localDayKey;
  final int mood;
  final List<String> emotionIds;
  final List<String> activityIds;
  final String? note;

  /// Last-known labels for custom activities on this particular entry.
  ///
  /// They deliberately remain unchanged when an activity is edited or deleted.
  final Map<String, String> customActivityLabelSnapshots;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
    'localDayKey': localDayKey,
    'mood': mood,
    'emotionIds': emotionIds,
    'activityIds': activityIds,
    if (note != null) 'note': note,
    if (customActivityLabelSnapshots.isNotEmpty)
      'customActivityLabelSnapshots': customActivityLabelSnapshots,
  };

  static MoodMedicineEntry? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final String id = _trimmedString(value['id']);
    final DateTime? occurredAt = DateTime.tryParse(
      _trimmedString(value['occurredAtUtc']),
    );
    final String localDayKey = _trimmedString(value['localDayKey']);
    final int? mood = _validMood(value['mood']);
    if (id.isEmpty ||
        occurredAt == null ||
        !isMoodMedicineLocalDayKey(localDayKey) ||
        mood == null) {
      return null;
    }

    try {
      return MoodMedicineEntry(
        id: id,
        occurredAtUtc: occurredAt,
        localDayKey: localDayKey,
        mood: mood,
        emotionIds: _stringList(value['emotionIds']),
        activityIds: _stringList(value['activityIds']),
        note: _optionalTrimmedString(value['note']?.toString()),
        customActivityLabelSnapshots: _stringMap(
          value['customActivityLabelSnapshots'],
        ),
      );
    } on ArgumentError {
      return null;
    }
  }
}

/// The atomic, versioned feature-local data snapshot.
final class MoodMedicineSnapshot {
  MoodMedicineSnapshot({
    this.version = moodMedicineSnapshotVersion,
    Iterable<String> hiddenDefaultActivityIds = const <String>[],
    Iterable<MoodMedicineCustomActivity> customActivities =
        const <MoodMedicineCustomActivity>[],
    Iterable<MoodMedicineEntry> entries = const <MoodMedicineEntry>[],
  }) : hiddenDefaultActivityIds = Set<String>.unmodifiable(
         _normalizeIds(
           hiddenDefaultActivityIds.where(
             moodMedicineDefaultActivityIds.contains,
           ),
         ),
       ),
       customActivities = List<MoodMedicineCustomActivity>.unmodifiable(
         _deduplicateCustomActivities(customActivities),
       ),
       entries = List<MoodMedicineEntry>.unmodifiable(
         _deduplicateEntries(entries),
       );

  const MoodMedicineSnapshot.empty()
    : version = moodMedicineSnapshotVersion,
      hiddenDefaultActivityIds = const <String>{},
      customActivities = const <MoodMedicineCustomActivity>[],
      entries = const <MoodMedicineEntry>[];

  final int version;
  final Set<String> hiddenDefaultActivityIds;
  final List<MoodMedicineCustomActivity> customActivities;
  final List<MoodMedicineEntry> entries;

  MoodMedicineCustomActivity? customActivityForId(String id) {
    for (final MoodMedicineCustomActivity activity in customActivities) {
      if (activity.id == id) {
        return activity;
      }
    }
    return null;
  }

  MoodMedicineSnapshot copyWith({
    Iterable<String>? hiddenDefaultActivityIds,
    Iterable<MoodMedicineCustomActivity>? customActivities,
    Iterable<MoodMedicineEntry>? entries,
  }) => MoodMedicineSnapshot(
    version: version,
    hiddenDefaultActivityIds:
        hiddenDefaultActivityIds ?? this.hiddenDefaultActivityIds,
    customActivities: customActivities ?? this.customActivities,
    entries: entries ?? this.entries,
  );

  Map<String, Object> toJson() => <String, Object>{
    'version': moodMedicineSnapshotVersion,
    'hiddenDefaultActivityIds': hiddenDefaultActivityIds.toList(
      growable: false,
    ),
    'customActivities': customActivities
        .map((MoodMedicineCustomActivity activity) => activity.toJson())
        .toList(growable: false),
    'entries': entries
        .map((MoodMedicineEntry entry) => entry.toJson())
        .toList(growable: false),
  };

  String encode() => jsonEncode(toJson());

  /// Decodes untrusted local storage without allowing malformed records to
  /// break the feature. Unsupported schema versions intentionally start empty.
  static MoodMedicineSnapshot decode(String raw) {
    if (raw.trim().isEmpty) {
      return const MoodMedicineSnapshot.empty();
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['version'] != moodMedicineSnapshotVersion) {
        return const MoodMedicineSnapshot.empty();
      }
      return MoodMedicineSnapshot(
        hiddenDefaultActivityIds: _stringList(
          decoded['hiddenDefaultActivityIds'],
        ),
        customActivities: _customActivities(decoded['customActivities']),
        entries: _entries(decoded['entries']),
      );
    } on FormatException {
      return const MoodMedicineSnapshot.empty();
    } on TypeError {
      return const MoodMedicineSnapshot.empty();
    }
  }
}

/// Whether [value] is a real ISO local calendar day in `yyyy-MM-dd` form.
bool isMoodMedicineLocalDayKey(String value) {
  final RegExp match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  final RegExpMatch? result = match.firstMatch(value);
  if (result == null) {
    return false;
  }
  final int? year = int.tryParse(result.group(1)!);
  final int? month = int.tryParse(result.group(2)!);
  final int? day = int.tryParse(result.group(3)!);
  if (year == null || month == null || day == null) {
    return false;
  }
  final DateTime candidate = DateTime(year, month, day);
  return candidate.year == year &&
      candidate.month == month &&
      candidate.day == day;
}

List<String> _normalizeIds(Iterable<String> values) {
  final Set<String> unique = <String>{};
  for (final String value in values) {
    final String normalized = value.trim();
    if (normalized.isNotEmpty) {
      unique.add(normalized);
    }
  }
  return unique.toList(growable: false);
}

String _trimmedString(Object? value) => value is String ? value.trim() : '';

String? _optionalTrimmedString(String? value) {
  final String normalized = value?.trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

int? _validMood(Object? value) {
  final int? parsed = switch (value) {
    int number => number,
    num number when number == number.roundToDouble() => number.toInt(),
    _ => null,
  };
  return parsed != null && parsed >= 1 && parsed <= 5 ? parsed : null;
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) {
    return const <String>[];
  }
  return _normalizeIds(value.whereType<String>());
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return const <String, String>{};
  }
  final Map<String, String> result = <String, String>{};
  value.forEach((Object? key, Object? label) {
    final String normalizedKey = _trimmedString(key);
    final String normalizedLabel = _trimmedString(label);
    if (normalizedKey.isNotEmpty && normalizedLabel.isNotEmpty) {
      result[normalizedKey] = normalizedLabel;
    }
  });
  return result;
}

Map<String, String> _normalizeLabelSnapshots(Map<String, String> snapshots) =>
    _stringMap(snapshots);

List<MoodMedicineCustomActivity> _customActivities(Object? value) {
  if (value is! Iterable) {
    return const <MoodMedicineCustomActivity>[];
  }
  return _deduplicateCustomActivities(
    value
        .map(MoodMedicineCustomActivity.fromJson)
        .whereType<MoodMedicineCustomActivity>(),
  );
}

List<MoodMedicineEntry> _entries(Object? value) {
  if (value is! Iterable) {
    return const <MoodMedicineEntry>[];
  }
  return _deduplicateEntries(
    value.map(MoodMedicineEntry.fromJson).whereType<MoodMedicineEntry>(),
  );
}

List<MoodMedicineCustomActivity> _deduplicateCustomActivities(
  Iterable<MoodMedicineCustomActivity> activities,
) {
  final Set<String> ids = <String>{};
  return activities
      .where((MoodMedicineCustomActivity activity) => ids.add(activity.id))
      .toList(growable: false);
}

List<MoodMedicineEntry> _deduplicateEntries(
  Iterable<MoodMedicineEntry> entries,
) {
  final Set<String> ids = <String>{};
  return entries
      .where((MoodMedicineEntry entry) => ids.add(entry.id))
      .toList(growable: false);
}
