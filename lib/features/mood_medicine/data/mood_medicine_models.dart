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

/// Explains why a persisted Mood Medicine snapshot cannot be recovered safely.
enum MoodMedicineSnapshotDecodeFailure {
  /// The root JSON value or an expected envelope field has the wrong shape.
  malformedEnvelope,

  /// The stored payload names a schema version this build does not support.
  unsupportedVersion,

  /// A custom activity or check-in record is invalid or internally inconsistent.
  malformedRecord,
}

/// Thrown when [MoodMedicineSnapshot.decode] rejects untrusted local data.
///
/// Callers should preserve the original stored value and ask the person to
/// explicitly discard it rather than replacing it with an empty snapshot.
final class MoodMedicineSnapshotDecodeException implements Exception {
  /// Creates a strict decoding failure with its category and optional cause.
  const MoodMedicineSnapshotDecodeException(this.failure, [this.cause]);

  /// The category the recovery UI can present without inspecting raw JSON.
  final MoodMedicineSnapshotDecodeFailure failure;

  /// The underlying parser error when one is available.
  final Object? cause;

  @override
  String toString() => 'MoodMedicineSnapshotDecodeException($failure)';
}

/// Formats a [DateTime] as the feature's local calendar-day key.
String moodMedicineLocalDayKey(DateTime value) {
  final DateTime local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

/// A user-created activity that can be selected in future check-ins.
final class MoodMedicineCustomActivity {
  /// Creates a custom activity with a stable identifier and visible label.
  MoodMedicineCustomActivity({required String id, required String label})
    : id = id.trim(),
      label = label.trim() {
    if (this.id.isEmpty || this.label.isEmpty) {
      throw ArgumentError('Custom activities need an id and a label.');
    }
    if (moodMedicineDefaultActivityIds.contains(this.id)) {
      throw ArgumentError('Custom activity ids cannot replace default ids.');
    }
  }

  /// Stable, nonlocalized identifier.
  final String id;

  /// The current editable label.
  final String label;

  /// Encodes this user-created activity for the feature-local snapshot.
  Map<String, Object> toJson() => <String, Object>{'id': id, 'label': label};

  /// Best-effort legacy parser retained for callers that do not decode storage.
  ///
  /// Snapshot storage uses [MoodMedicineSnapshot.decode], which is strict.
  static MoodMedicineCustomActivity? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final String id = _trimmedString(value['id']);
    final String label = _trimmedString(value['label']);
    if (id.isEmpty || label.isEmpty) {
      return null;
    }
    try {
      return MoodMedicineCustomActivity(id: id, label: label);
    } on ArgumentError {
      return null;
    }
  }

  /// Returns this activity with an updated visible [label].
  MoodMedicineCustomActivity copyWith({String? label}) =>
      MoodMedicineCustomActivity(id: id, label: label ?? this.label);
}

/// An immutable check-in draft retained after a persistence failure.
final class MoodMedicineCheckInDraft {
  /// Creates a normalized, immutable check-in draft.
  MoodMedicineCheckInDraft({
    required this.mood,
    Iterable<String> emotionIds = const <String>[],
    Iterable<String> activityIds = const <String>[],
    String? note,
  }) : emotionIds = List<String>.unmodifiable(_normalizeIds(emotionIds)),
       activityIds = List<String>.unmodifiable(_normalizeIds(activityIds)),
       note = _optionalTrimmedString(note);

  /// Selected mood value, validated by the view model before saving.
  final int mood;

  /// Selected nonlocalized emotion identifiers.
  final List<String> emotionIds;

  /// Selected default or active custom activity identifiers.
  final List<String> activityIds;

  /// Optional private journal text.
  final String? note;
}

/// One timestamped, local-day-aware mood check-in.
final class MoodMedicineEntry {
  /// Creates an immutable check-in entry.
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

  /// Stable entry identifier.
  final String id;

  /// UTC timestamp recorded when the person completed this check-in.
  final DateTime occurredAtUtc;

  /// Local calendar day captured at check-in time.
  final String localDayKey;

  /// Mood from one through five.
  final int mood;

  /// Selected nonlocalized emotion identifiers.
  final List<String> emotionIds;

  /// Selected default, active custom, or historically labelled custom ids.
  final List<String> activityIds;

  /// Optional private journal text.
  final String? note;

  /// Last-known labels for custom activities on this particular entry.
  ///
  /// They deliberately remain unchanged when an activity is edited or deleted.
  final Map<String, String> customActivityLabelSnapshots;

  /// Encodes this entry for the feature-local snapshot.
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

  /// Best-effort legacy parser retained for non-storage callers.
  ///
  /// Snapshot storage uses [MoodMedicineSnapshot.decode], which rejects an
  /// invalid record rather than dropping it.
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
        note: value['note'] is String ? value['note'] as String : null,
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
  /// Creates a valid version-one Mood Medicine snapshot.
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
       ) {
    if (version != moodMedicineSnapshotVersion) {
      throw ArgumentError.value(
        version,
        'version',
        'Only schema v$moodMedicineSnapshotVersion is supported.',
      );
    }
    _validateEntryActivityReferences();
  }

  /// Creates the feature's canonical empty v1 snapshot.
  const MoodMedicineSnapshot.empty()
    : version = moodMedicineSnapshotVersion,
      hiddenDefaultActivityIds = const <String>{},
      customActivities = const <MoodMedicineCustomActivity>[],
      entries = const <MoodMedicineEntry>[];

  /// Persisted schema version.
  final int version;

  /// Built-in activity ids intentionally hidden from future check-ins.
  final Set<String> hiddenDefaultActivityIds;

  /// Active user-created activities.
  final List<MoodMedicineCustomActivity> customActivities;

  /// Immutable history of saved check-ins.
  final List<MoodMedicineEntry> entries;

  /// Returns the active custom activity with [id], if it exists.
  MoodMedicineCustomActivity? customActivityForId(String id) {
    for (final MoodMedicineCustomActivity activity in customActivities) {
      if (activity.id == id) {
        return activity;
      }
    }
    return null;
  }

  /// Returns a v1 snapshot with the supplied fields replaced.
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

  /// Encodes the v1 snapshot envelope without changing its version.
  Map<String, Object> toJson() => <String, Object>{
    'version': version,
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

  /// Serializes this atomic snapshot for feature-local persistence.
  String encode() => jsonEncode(toJson());

  /// Strictly decodes a v1 snapshot from untrusted local storage.
  ///
  /// Empty strings are not accepted here because the repository distinguishes
  /// a missing value from corrupt data before calling this method. Every
  /// envelope field and nested record must be well formed; no data is silently
  /// dropped or converted to an empty history.
  static MoodMedicineSnapshot decode(String raw) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedEnvelope,
        error,
      );
    }

    final Map<String, Object?> envelope = _strictMap(
      decoded,
      MoodMedicineSnapshotDecodeFailure.malformedEnvelope,
    );
    final Object? version = envelope['version'];
    if (version is! int) {
      throw const MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedEnvelope,
      );
    }
    if (version != moodMedicineSnapshotVersion) {
      throw const MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.unsupportedVersion,
      );
    }

    final List<Object?> hiddenDefaultActivityIds = _strictList(
      envelope['hiddenDefaultActivityIds'],
      MoodMedicineSnapshotDecodeFailure.malformedEnvelope,
    );
    final List<Object?> customActivities = _strictList(
      envelope['customActivities'],
      MoodMedicineSnapshotDecodeFailure.malformedEnvelope,
    );
    final List<Object?> entries = _strictList(
      envelope['entries'],
      MoodMedicineSnapshotDecodeFailure.malformedEnvelope,
    );

    final Set<String> parsedHidden = _parseHiddenDefaultActivityIds(
      hiddenDefaultActivityIds,
    );
    final List<MoodMedicineCustomActivity> parsedCustomActivities =
        _parseCustomActivities(customActivities);
    final Set<String> activeCustomIds = parsedCustomActivities
        .map((MoodMedicineCustomActivity activity) => activity.id)
        .toSet();
    final List<MoodMedicineEntry> parsedEntries = _parseEntries(
      entries,
      activeCustomIds: activeCustomIds,
    );

    try {
      return MoodMedicineSnapshot(
        version: version,
        hiddenDefaultActivityIds: parsedHidden,
        customActivities: parsedCustomActivities,
        entries: parsedEntries,
      );
    } on ArgumentError catch (error) {
      throw MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedRecord,
        error,
      );
    }
  }

  void _validateEntryActivityReferences() {
    final Set<String> activeCustomIds = customActivities
        .map((MoodMedicineCustomActivity activity) => activity.id)
        .toSet();
    final Set<String> entryIds = <String>{};
    for (final MoodMedicineEntry entry in entries) {
      if (!entryIds.add(entry.id)) {
        throw ArgumentError('Mood Medicine entry ids must be unique.');
      }
      for (final String activityId in entry.activityIds) {
        if (moodMedicineDefaultActivityIds.contains(activityId) ||
            activeCustomIds.contains(activityId)) {
          continue;
        }
        if (!entry.customActivityLabelSnapshots.containsKey(activityId)) {
          throw ArgumentError(
            'Historical custom activities require an entry label snapshot.',
          );
        }
      }
      for (final String snapshotId in entry.customActivityLabelSnapshots.keys) {
        if (moodMedicineDefaultActivityIds.contains(snapshotId)) {
          throw ArgumentError(
            'Default activities cannot have custom label snapshots.',
          );
        }
        if (!entry.activityIds.contains(snapshotId)) {
          throw ArgumentError(
            'Custom activity label snapshots must belong to the entry.',
          );
        }
      }
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

Map<String, Object?> _strictMap(
  Object? value,
  MoodMedicineSnapshotDecodeFailure failure,
) {
  if (value is! Map) {
    throw MoodMedicineSnapshotDecodeException(failure);
  }
  final Map<String, Object?> result = <String, Object?>{};
  value.forEach((Object? key, Object? nestedValue) {
    if (key is! String) {
      throw MoodMedicineSnapshotDecodeException(failure);
    }
    result[key] = nestedValue;
  });
  return result;
}

List<Object?> _strictList(
  Object? value,
  MoodMedicineSnapshotDecodeFailure failure,
) {
  if (value is! List) {
    throw MoodMedicineSnapshotDecodeException(failure);
  }
  return List<Object?>.unmodifiable(value);
}

Set<String> _parseHiddenDefaultActivityIds(List<Object?> values) {
  final Set<String> result = <String>{};
  for (final Object? value in values) {
    final String id = _strictNonEmptyString(
      value,
      MoodMedicineSnapshotDecodeFailure.malformedEnvelope,
    );
    if (!moodMedicineDefaultActivityIds.contains(id) || !result.add(id)) {
      throw const MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedEnvelope,
      );
    }
  }
  return result;
}

List<MoodMedicineCustomActivity> _parseCustomActivities(List<Object?> values) {
  final Set<String> ids = <String>{};
  final List<MoodMedicineCustomActivity> result =
      <MoodMedicineCustomActivity>[];
  for (final Object? value in values) {
    final Map<String, Object?> record = _strictMap(
      value,
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    final String id = _strictNonEmptyString(
      record['id'],
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    final String label = _strictNonEmptyString(
      record['label'],
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    if (!ids.add(id)) {
      throw const MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedRecord,
      );
    }
    try {
      result.add(MoodMedicineCustomActivity(id: id, label: label));
    } on ArgumentError catch (error) {
      throw MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedRecord,
        error,
      );
    }
  }
  return List<MoodMedicineCustomActivity>.unmodifiable(result);
}

List<MoodMedicineEntry> _parseEntries(
  List<Object?> values, {
  required Set<String> activeCustomIds,
}) {
  final Set<String> ids = <String>{};
  final List<MoodMedicineEntry> result = <MoodMedicineEntry>[];
  for (final Object? value in values) {
    final Map<String, Object?> record = _strictMap(
      value,
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    final String id = _strictNonEmptyString(
      record['id'],
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    final String occurredAtRaw = _strictNonEmptyString(
      record['occurredAtUtc'],
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    final DateTime? occurredAt = DateTime.tryParse(occurredAtRaw);
    final String localDayKey = _strictNonEmptyString(
      record['localDayKey'],
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    final int? mood = _validMood(record['mood']);
    if (!ids.add(id) ||
        occurredAt == null ||
        !occurredAt.isUtc ||
        !isMoodMedicineLocalDayKey(localDayKey) ||
        mood == null) {
      throw const MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedRecord,
      );
    }
    final List<String> emotionIds = _strictIdList(
      record['emotionIds'],
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    final List<String> activityIds = _strictIdList(
      record['activityIds'],
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    final Map<String, String> snapshots = _strictLabelSnapshots(
      record['customActivityLabelSnapshots'],
    );
    final Object? noteValue = record['note'];
    if (noteValue != null && noteValue is! String) {
      throw const MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedRecord,
      );
    }
    if (noteValue is String && noteValue.trim().isEmpty) {
      throw const MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedRecord,
      );
    }

    final Set<String> activitySet = activityIds.toSet();
    if (snapshots.keys.any(
      (String id) =>
          moodMedicineDefaultActivityIds.contains(id) ||
          !activitySet.contains(id),
    )) {
      throw const MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedRecord,
      );
    }
    for (final String activityId in activityIds) {
      if (moodMedicineDefaultActivityIds.contains(activityId) ||
          activeCustomIds.contains(activityId)) {
        continue;
      }
      if (!snapshots.containsKey(activityId)) {
        throw const MoodMedicineSnapshotDecodeException(
          MoodMedicineSnapshotDecodeFailure.malformedRecord,
        );
      }
    }

    try {
      result.add(
        MoodMedicineEntry(
          id: id,
          occurredAtUtc: occurredAt,
          localDayKey: localDayKey,
          mood: mood,
          emotionIds: emotionIds,
          activityIds: activityIds,
          note: noteValue as String?,
          customActivityLabelSnapshots: snapshots,
        ),
      );
    } on ArgumentError catch (error) {
      throw MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedRecord,
        error,
      );
    }
  }
  return List<MoodMedicineEntry>.unmodifiable(result);
}

String _strictNonEmptyString(
  Object? value,
  MoodMedicineSnapshotDecodeFailure failure,
) {
  if (value is! String || value.trim().isEmpty) {
    throw MoodMedicineSnapshotDecodeException(failure);
  }
  return value.trim();
}

List<String> _strictIdList(
  Object? value,
  MoodMedicineSnapshotDecodeFailure failure,
) {
  final List<Object?> values = _strictList(value, failure);
  final Set<String> ids = <String>{};
  for (final Object? nested in values) {
    final String id = _strictNonEmptyString(nested, failure);
    if (!ids.add(id)) {
      throw MoodMedicineSnapshotDecodeException(failure);
    }
  }
  return List<String>.unmodifiable(ids);
}

Map<String, String> _strictLabelSnapshots(Object? value) {
  if (value == null) {
    return const <String, String>{};
  }
  final Map<String, Object?> raw = _strictMap(
    value,
    MoodMedicineSnapshotDecodeFailure.malformedRecord,
  );
  final Map<String, String> result = <String, String>{};
  for (final MapEntry<String, Object?> entry in raw.entries) {
    final String id = _strictNonEmptyString(
      entry.key,
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    final String label = _strictNonEmptyString(
      entry.value,
      MoodMedicineSnapshotDecodeFailure.malformedRecord,
    );
    if (result.containsKey(id)) {
      throw const MoodMedicineSnapshotDecodeException(
        MoodMedicineSnapshotDecodeFailure.malformedRecord,
      );
    }
    result[id] = label;
  }
  return Map<String, String>.unmodifiable(result);
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
