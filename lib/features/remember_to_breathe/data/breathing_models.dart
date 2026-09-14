import 'dart:convert';

/// The three supported breathing sequences.
enum BreathingPattern { basic, box, custom }

/// Phases of a complete breathing cycle.
enum BreathingPhase { inhale, holdInhale, exhale, holdExhale }

/// Stable identifiers for bundled backgrounds and the retained personal photo.
enum BreathingBackground {
  forest,
  mountains,
  cosmos,
  beach,
  flowers,
  sunset,
  house,
  monastery,
  personal,
}

/// A person's local breathing preferences.
final class BreathingSettings {
  /// Creates preferences using the quick-start defaults.
  const BreathingSettings({
    this.inhaleDuration = const Duration(seconds: 3),
    this.exhaleDuration = const Duration(seconds: 3),
    this.background = BreathingBackground.forest,
    this.personalPhotoBase64,
    this.showCircle = true,
    this.showText = true,
  });

  final Duration inhaleDuration;
  final Duration exhaleDuration;
  final BreathingBackground background;

  /// One normalized PNG retained on this device; never a file path or URL.
  final String? personalPhotoBase64;
  final bool showCircle;
  final bool showText;

  /// Changes supplied preferences, retaining the personal photo by default.
  ///
  /// Null means retain the existing value. Selecting a preset keeps the photo
  /// available for later reuse; app-data reset removes the retained snapshot.
  BreathingSettings copyWith({
    Duration? inhaleDuration,
    Duration? exhaleDuration,
    BreathingBackground? background,
    String? personalPhotoBase64,
    bool? showCircle,
    bool? showText,
  }) {
    final settings = BreathingSettings(
      inhaleDuration: inhaleDuration ?? this.inhaleDuration,
      exhaleDuration: exhaleDuration ?? this.exhaleDuration,
      background: background ?? this.background,
      personalPhotoBase64: personalPhotoBase64 ?? this.personalPhotoBase64,
      showCircle: showCircle ?? this.showCircle,
      showText: showText ?? this.showText,
    );
    settings._validate();
    return settings;
  }

  // Synchronous schema validation checks size, base64 and the PNG signature.
  // The store additionally decodes the image before accepting reads or writes.
  void _validate() {
    for (final duration in [inhaleDuration, exhaleDuration]) {
      if (duration < const Duration(seconds: 3) ||
          duration > const Duration(seconds: 9)) {
        throw const FormatException('Invalid breathing duration.');
      }
    }
    final photo = personalPhotoBase64;
    if (photo != null) {
      if (photo.length > 699052) {
        throw const FormatException('Invalid retained photo size.');
      }
      final bytes = base64Decode(photo);
      const signature = [137, 80, 78, 71, 13, 10, 26, 10];
      if (bytes.length > 512 * 1024 ||
          bytes.length < signature.length ||
          !Iterable<int>.generate(
            signature.length,
          ).every((index) => bytes[index] == signature[index])) {
        throw const FormatException('Invalid retained photo.');
      }
    }
    if (background == BreathingBackground.personal && photo == null) {
      throw const FormatException('A personal background needs a photo.');
    }
  }

  /// Encodes validated settings without losing measured duration precision.
  Map<String, Object?> toJson() {
    _validate();
    return {
      'inhaleMicroseconds': inhaleDuration.inMicroseconds,
      'exhaleMicroseconds': exhaleDuration.inMicroseconds,
      'background': background.name,
      'personalPhotoBase64': personalPhotoBase64,
      'showCircle': showCircle,
      'showText': showText,
    };
  }

  /// Strictly decodes a complete settings record.
  factory BreathingSettings.fromJson(Map<String, dynamic> json) {
    if (json case {
      'inhaleMicroseconds': int inhale,
      'exhaleMicroseconds': int exhale,
      'background': String background,
      'personalPhotoBase64': final Object? photo,
      'showCircle': bool showCircle,
      'showText': bool showText,
    } when photo == null || photo is String) {
      final settings = BreathingSettings(
        inhaleDuration: Duration(microseconds: inhale),
        exhaleDuration: Duration(microseconds: exhale),
        background: _enumValue(BreathingBackground.values, background),
        personalPhotoBase64: photo as String?,
        showCircle: showCircle,
        showText: showText,
      );
      settings._validate();
      return settings;
    }
    throw const FormatException('Invalid breathing settings.');
  }
}

/// One finished or explicitly stopped attempt, including optional ratings.
final class BreathingSession {
  /// Creates an attempt with its stable identity and monotonic revision.
  BreathingSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.pattern,
    required this.completedCycles,
    this.stressBefore,
    this.stressAfter,
    this.revision = 0,
  }) {
    if (id.trim().isEmpty ||
        completedCycles < 0 ||
        completedCycles > 8 ||
        revision < 0 ||
        endedAt.isBefore(startedAt)) {
      throw const FormatException('Invalid breathing session.');
    }
    for (final rating in [stressBefore, stressAfter]) {
      if (rating != null && (rating < 1 || rating > 10)) {
        throw const FormatException('Invalid stress rating.');
      }
    }
  }

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final BreathingPattern pattern;
  final int completedCycles;
  final int? stressBefore;
  final int? stressAfter;

  /// Older retries cannot replace a record with a higher revision.
  final int revision;

  bool get isComplete => completedCycles == 8;

  /// Updates rating or completion details without changing the attempt ID.
  ///
  /// Null means retain the existing value, including either optional rating.
  /// Clearing a rating requires a replacement session with a newer revision;
  /// the view model's updateAfterRating(null) operation handles that explicitly.
  BreathingSession copyWith({
    DateTime? endedAt,
    int? completedCycles,
    int? stressBefore,
    int? stressAfter,
    int? revision,
  }) => BreathingSession(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt ?? this.endedAt,
    pattern: pattern,
    completedCycles: completedCycles ?? this.completedCycles,
    stressBefore: stressBefore ?? this.stressBefore,
    stressAfter: stressAfter ?? this.stressAfter,
    revision: revision ?? this.revision,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt.toUtc().toIso8601String(),
    'pattern': pattern.name,
    'completedCycles': completedCycles,
    'isComplete': isComplete,
    'stressBefore': stressBefore,
    'stressAfter': stressAfter,
    'revision': revision,
  };

  /// Strictly decodes a saved attempt, preserving missing ratings as null.
  factory BreathingSession.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'id': String id,
          'startedAt': String startedAt,
          'endedAt': String endedAt,
          'pattern': String pattern,
          'completedCycles': int completedCycles,
          'isComplete': bool isComplete,
          'stressBefore': final Object? before,
          'stressAfter': final Object? after,
          'revision': int revision,
        }
        when (before == null || before is int) &&
            (after == null || after is int)) {
      if (isComplete != (completedCycles == 8)) {
        throw const FormatException('Inconsistent breathing completion.');
      }
      return BreathingSession(
        id: id,
        startedAt: _timestamp(startedAt),
        endedAt: _timestamp(endedAt),
        pattern: _enumValue(BreathingPattern.values, pattern),
        completedCycles: completedCycles,
        stressBefore: before as int?,
        stressAfter: after as int?,
        revision: revision,
      );
    }
    throw const FormatException('Invalid breathing session record.');
  }
}

/// The single versioned snapshot persisted through the shared memory service.
final class BreathingSnapshot {
  BreathingSnapshot({
    this.settings = const BreathingSettings(),
    Iterable<BreathingSession> sessions = const [],
  }) : sessions = List.unmodifiable(sessions);

  const BreathingSnapshot.empty()
    : settings = const BreathingSettings(),
      sessions = const [];

  static const int version = 1;
  final BreathingSettings settings;
  final List<BreathingSession> sessions;

  Map<String, Object?> toJson() => {
    'version': version,
    'settings': settings.toJson(),
    'sessions': sessions.map((session) => session.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory BreathingSnapshot.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid breathing snapshot envelope.');
    }
    return BreathingSnapshot.fromJson(decoded);
  }

  /// Rejects the entire snapshot if any record is malformed or duplicated.
  factory BreathingSnapshot.fromJson(Map<String, dynamic> json) {
    if (json case {
      'version': int storedVersion,
      'settings': Map<String, dynamic> settings,
      'sessions': List<dynamic> records,
    } when storedVersion == version) {
      final sessions = <BreathingSession>[];
      final ids = <String>{};
      for (final record in records) {
        if (record is! Map<String, dynamic>) {
          throw const FormatException('Invalid breathing session record.');
        }
        final session = BreathingSession.fromJson(record);
        if (!ids.add(session.id)) {
          throw const FormatException('Duplicate breathing session.');
        }
        sessions.add(session);
      }
      return BreathingSnapshot(
        settings: BreathingSettings.fromJson(settings),
        sessions: sessions,
      );
    }
    throw const FormatException('Invalid or unsupported breathing snapshot.');
  }
}

T _enumValue<T extends Enum>(List<T> values, String name) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  throw const FormatException('Invalid breathing identifier.');
}

DateTime _timestamp(String value) {
  final timestamp = DateTime.tryParse(value);
  // Our encoder emits canonical UTC, preventing normalized invalid dates.
  if (timestamp == null ||
      !timestamp.isUtc ||
      timestamp.toIso8601String() != value) {
    throw const FormatException('Invalid breathing timestamp.');
  }
  return timestamp;
}
