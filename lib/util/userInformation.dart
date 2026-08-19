import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/dreams_and_goals_selection.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

enum DarkModePreference { alwaysLight, alwaysDark, scheduled }

//this it the user's information class, with it we store and display it across the app
class UserInformation with ChangeNotifier {
  String localeName;
  String gender;
  String name;
  String age;
  String location;
  bool binary;
  bool disclaimerSigned;
  List<String> difficultEvents;
  List<String> positiveTraits;
  List<String> makeSafer;
  List<String> feelBetter;
  List<String> distractions;
  List<String> safeEnvironment;
  List<String> dreamsAndGoals;
  List<String> dreamsAndGoalsSelectionSources;
  bool loggedIn;
  String userId;
  int notificationMinute;
  int notificationHour;
  String notificationMessage;
  DarkModePreference darkModePreference;
  int darkModeStartHour;
  int darkModeStartMinute;
  int darkModeEndHour;
  int darkModeEndMinute;
  Map<String, List<String>> thanks;
  PersistentMemoryService service; // Get the persistent memory service instance
  Future<void> _pendingDreamsAndGoalsSave = Future<void>.value();
  int _dreamsAndGoalsSaveRevision = 0;
  int? _pendingDreamsAndGoalsCustomConflictResolutionRevision;

  UserInformation({
    this.location = '',
    this.thanks = const <String, List<String>>{},
    this.positiveTraits = const [],
    this.localeName = '',
    this.notificationHour = 12,
    this.notificationMinute = 0,
    this.notificationMessage = '',
    this.darkModePreference = DarkModePreference.alwaysLight,
    this.darkModeStartHour = 22,
    this.darkModeStartMinute = 0,
    this.darkModeEndHour = 6,
    this.darkModeEndMinute = 0,
    this.gender = '',
    this.name = '',
    this.age = '',
    this.binary = false,
    this.difficultEvents = const [],
    this.makeSafer = const [],
    this.feelBetter = const [],
    this.distractions = const [],
    this.safeEnvironment = const [],
    this.dreamsAndGoals = const [],
    this.dreamsAndGoalsSelectionSources = const [],
    this.disclaimerSigned = false,
    this.loggedIn = false,
    this.userId = '',
    PersistentMemoryService? service,
  }) : service = service ?? GetIt.instance<PersistentMemoryService>();

  void reset(String locale) {
    location = '';
    notificationHour = 12;
    notificationMinute = 0;
    notificationMessage = '';
    darkModePreference = DarkModePreference.alwaysLight;
    darkModeStartHour = 22;
    darkModeStartMinute = 0;
    darkModeEndHour = 6;
    darkModeEndMinute = 0;
    gender = '';
    name = '';
    age = '';
    binary = false;
    disclaimerSigned = false;
    difficultEvents = [];
    makeSafer = [];
    feelBetter = [];
    distractions = [];
    safeEnvironment = [];
    dreamsAndGoals = [];
    dreamsAndGoalsSelectionSources = [];
    _pendingDreamsAndGoalsCustomConflictResolutionRevision = null;
    // An in-flight snapshot cannot be cancelled safely. Queue the empty
    // snapshot behind it so reset is always the final local Dreams state.
    _dreamsAndGoalsSaveRevision++;
    unawaited(_saveInBackground(queueDreamsAndGoalsSave));
    loggedIn = false;
    userId = '';
    thanks = {};
    positiveTraits = [];
    localeName = locale;

    notifyListeners();
  }

  /// Observes non-critical legacy writes so a storage failure cannot escape an
  /// async `void` setter. Dreams and Goals writes deliberately use their
  /// queue instead, because those errors must reach the visible retry UI.
  Future<void> _saveInBackground(Future<void> Function() save) async {
    try {
      await save();
    } catch (error, stackTrace) {
      try {
        await GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      } catch (_) {
        // Persistence already attempted its own logging. Never create a new
        // uncaught async error while reporting a background-write failure.
      }
    }
  }

  void updateGender(String text) {
    gender = text;
    unawaited(
      _saveInBackground(
        () => service.setItem('gender', PersistentMemoryType.String, text),
      ),
    );
    notifyListeners();
  }

  void updateName(String text) {
    name = text;
    unawaited(
      _saveInBackground(
        () => service.setItem('name', PersistentMemoryType.String, text),
      ),
    );
    notifyListeners();
  }

  void updateAge(String text) {
    age = text;
    unawaited(
      _saveInBackground(
        () => service.setItem('age', PersistentMemoryType.String, text),
      ),
    );
    notifyListeners();
  }

  void updateBinary(bool value) {
    binary = value;
    unawaited(
      _saveInBackground(
        () => service.setItem('binary', PersistentMemoryType.Bool, value),
      ),
    );
    notifyListeners();
  }

  Future<void> updateGenderAndBinary({required String gender, required bool isBinary}) async {
    this.gender = gender;
    binary = isBinary;
    notifyListeners();

    await Future.wait([
      service.setItem('gender', PersistentMemoryType.String, gender),
      service.setItem('binary', PersistentMemoryType.Bool, isBinary),
    ]);
  }

  void updateDifficultEvents(List<String> value) {
    difficultEvents = value;
    notifyListeners();
  }

  void updateMakeSafer(List<String> value) {
    makeSafer = value;
    notifyListeners();
  }

  void updateFeelBetter(List<String> value) {
    feelBetter = value;
    notifyListeners();
  }

  void updateDistractions(List<String> value) {
    distractions = value;
    notifyListeners();
  }

  void updateSafeEnvironment(List<String> value) {
    safeEnvironment = value;
    notifyListeners();
  }

  /// Replaces Dreams and Goals state using defensively copied positional data.
  ///
  /// When [selectionSources] is supplied, it must contain exactly one source
  /// per item in [value] or an [ArgumentError] is thrown before any state is
  /// changed. Omitting it deliberately clears source metadata.
  void updateDreamsAndGoals(
    List<String> value, {
    List<String>? selectionSources,
  }) {
    final List<String> valueCopy = List<String>.from(value);
    late final List<String> sourceCopy;
    if (selectionSources == null) {
      sourceCopy = <String>[];
    } else {
      if (selectionSources.length != valueCopy.length) {
        throw ArgumentError.value(
          selectionSources,
          'selectionSources',
          'Must contain one source for every Dreams and Goals value.',
        );
      }
      sourceCopy = normalizeDreamsAndGoalsSelectionSources(
        valueCopy,
        List<String>.from(selectionSources),
      );
    }
    dreamsAndGoals = valueCopy;
    dreamsAndGoalsSelectionSources = sourceCopy;
    _dreamsAndGoalsSaveRevision++;
    // A conflict choice stays gated until the newest replacement snapshot is
    // durably written. If another model mutation arrives before that write
    // succeeds, retry the current state rather than letting the old revision
    // clear the gate.
    if (_pendingDreamsAndGoalsCustomConflictResolutionRevision != null) {
      _pendingDreamsAndGoalsCustomConflictResolutionRevision =
          _dreamsAndGoalsSaveRevision;
    }
    notifyListeners();
  }

  /// The latest serialized Dreams and Goals save, including queued snapshots.
  Future<void> get pendingDreamsAndGoalsSave => _pendingDreamsAndGoalsSave;

  /// Revision captured with a Dreams and Goals persistence snapshot.
  int get dreamsAndGoalsSaveRevision => _dreamsAndGoalsSaveRevision;

  /// Selection-row indexes whose normalized source is explicitly `custom`.
  ///
  /// This derives candidates without mutating stored model state, so callers
  /// should first await [repairDreamsAndGoalsSelectionSources] when they need
  /// the repaired source list persisted before rendering a recovery choice.
  List<int> get dreamsAndGoalsCustomSelectionIndexes {
    final List<String> normalizedSources =
        normalizeDreamsAndGoalsSelectionSources(
          dreamsAndGoals,
          dreamsAndGoalsSelectionSources,
        );
    return List<int>.unmodifiable(<int>[
      for (final (int index, String source) in normalizedSources.indexed)
        if (source == dreamsAndGoalsCustomSelectionSource) index,
    ]);
  }

  /// Whether more than one custom Dreams and Goals row requires user choice.
  bool get hasDreamsAndGoalsCustomConflict =>
      dreamsAndGoalsCustomSelectionIndexes.length > 1;

  /// Whether a user-selected custom-goal resolution still needs persistence.
  ///
  /// A selected row replaces the conflicting rows in memory immediately so
  /// the person's explicit choice is never lost. Consumers must keep editing
  /// and sharing gated while this is true, because the chosen snapshot has not
  /// yet been saved locally.
  bool get hasPendingDreamsAndGoalsCustomConflictResolution =>
      _pendingDreamsAndGoalsCustomConflictResolutionRevision != null;

  /// Whether Dreams and Goals must stay behind the custom-conflict recovery
  /// gate before it can be edited, exported, or completed.
  bool get requiresDreamsAndGoalsCustomConflictRecovery =>
      hasDreamsAndGoalsCustomConflict ||
      hasPendingDreamsAndGoalsCustomConflictResolution;

  /// Keeps [retainedSelectionIndex]'s custom row and all catalogue rows.
  ///
  /// The chosen index must identify a row whose normalized source is `custom`.
  /// Invalid indexes and catalogue-row choices throw [ArgumentError] before
  /// changing the model. A valid choice updates the model, then persists the
  /// queued immutable three-key snapshot before this future completes. If that
  /// save fails, the selected in-memory snapshot remains available behind
  /// [hasPendingDreamsAndGoalsCustomConflictResolution] until a retry saves
  /// the latest revision.
  ///
  /// Calling this when there is no multiple-custom conflict is a no-op after
  /// validating the chosen custom row.
  Future<void> resolveDreamsAndGoalsCustomConflict(
    int retainedSelectionIndex,
  ) async {
    final List<String> normalizedSources =
        normalizeDreamsAndGoalsSelectionSources(
          dreamsAndGoals,
          dreamsAndGoalsSelectionSources,
        );
    if (retainedSelectionIndex < 0 ||
        retainedSelectionIndex >= normalizedSources.length ||
        normalizedSources[retainedSelectionIndex] !=
            dreamsAndGoalsCustomSelectionSource) {
      throw ArgumentError.value(
        retainedSelectionIndex,
        'retainedSelectionIndex',
        'Must identify a custom Dreams and Goals row.',
      );
    }

    final int customSelectionCount = normalizedSources
        .where(
          (String source) => source == dreamsAndGoalsCustomSelectionSource,
        )
        .length;
    if (customSelectionCount <= 1) {
      return;
    }

    final List<String> retainedSelections = <String>[];
    final List<String> retainedSources = <String>[];
    for (final (int index, String selection) in dreamsAndGoals.indexed) {
      final String source = normalizedSources[index];
      if (source != dreamsAndGoalsCustomSelectionSource ||
          index == retainedSelectionIndex) {
        retainedSelections.add(selection);
        retainedSources.add(source);
      }
    }

    // Mark the next model revision before notifying listeners through
    // updateDreamsAndGoals. That keeps every consumer behind the recovery
    // gate from the first frame containing the chosen in-memory snapshot.
    _pendingDreamsAndGoalsCustomConflictResolutionRevision =
        _dreamsAndGoalsSaveRevision + 1;
    updateDreamsAndGoals(retainedSelections, selectionSources: retainedSources);
    await queueDreamsAndGoalsSave();
  }

  /// Queues an immutable three-key snapshot after any prior Dreams save.
  ///
  /// A failed older write does not block a later snapshot: each new save
  /// continues after the previous error so the latest queued state wins.
  Future<void> queueDreamsAndGoalsSave() {
    final DreamsAndGoalsPersistenceSnapshot snapshot =
        DreamsAndGoalsPersistenceSnapshot.fromSelections(
          dreamsAndGoals,
          dreamsAndGoalsSelectionSources,
        );
    final int snapshotRevision = _dreamsAndGoalsSaveRevision;
    final Future<void> nextSave = _pendingDreamsAndGoalsSave
        .catchError((Object _) {})
        .then(
          (_) => persistDreamsAndGoalsSnapshot(service, snapshot),
        );
    final Future<void> trackedSave = nextSave.then((_) {
      if (_pendingDreamsAndGoalsCustomConflictResolutionRevision ==
              snapshotRevision &&
          _dreamsAndGoalsSaveRevision == snapshotRevision) {
        _pendingDreamsAndGoalsCustomConflictResolutionRevision = null;
        notifyListeners();
      }
    });
    _pendingDreamsAndGoalsSave = trackedSave;
    return trackedSave;
  }

  /// Retries [revision] only when it is still the current Dreams selection.
  ///
  /// A newer edit has already queued its own snapshot, so retrying an older
  /// failure merely returns the current pending save instead of overwriting it.
  Future<void> retryDreamsAndGoalsSave(int revision) {
    if (revision != _dreamsAndGoalsSaveRevision) {
      return _pendingDreamsAndGoalsSave;
    }
    return queueDreamsAndGoalsSave();
  }

  /// Retries the latest chosen custom-conflict snapshot, if one is pending.
  ///
  /// The shared save queue clears the pending recovery gate only after the
  /// current revision's three-key snapshot succeeds.
  Future<void> retryDreamsAndGoalsCustomConflictResolution() {
    if (!hasPendingDreamsAndGoalsCustomConflictResolution) {
      return Future<void>.value();
    }
    return retryDreamsAndGoalsSave(_dreamsAndGoalsSaveRevision);
  }

  /// Loads Dreams and Goals state from local storage and repairs stale
  /// provenance metadata through this model's injected storage service.
  ///
  /// The localized [selections] stay in their saved order. Source tokens and
  /// the custom-only list are normalized into one immutable snapshot; multiple
  /// explicit custom rows intentionally remain until the user resolves that
  /// conflict. The three-key snapshot is queued only when either stored
  /// metadata list differs from the repaired values.
  Future<void> hydrateDreamsAndGoalsFromStorage(
    List<String> selections, {
    required List<String> storedSelectionSources,
    required List<String> storedCustomSelections,
  }) async {
    final DreamsAndGoalsPersistenceSnapshot snapshot =
        DreamsAndGoalsPersistenceSnapshot.fromSelections(
          selections,
          normalizeDreamsAndGoalsSelectionSources(
            selections,
            storedSelectionSources,
          ),
        );
    if (!listEquals(dreamsAndGoals, snapshot.selections) ||
        !listEquals(
          dreamsAndGoalsSelectionSources,
          snapshot.selectionSources,
        )) {
      updateDreamsAndGoals(
        snapshot.selections,
        selectionSources: snapshot.selectionSources,
      );
    }
    if (listEquals(storedSelectionSources, snapshot.selectionSources) &&
        listEquals(storedCustomSelections, snapshot.customSelections)) {
      return;
    }
    await queueDreamsAndGoalsSave();
  }

  /// Repairs in-memory Dreams and Goals sources outside the widget build
  /// lifecycle without collapsing multiple explicit custom rows. Storage
  /// hydration should use [hydrateDreamsAndGoalsFromStorage] so it can also
  /// repair custom metadata.
  Future<void> repairDreamsAndGoalsSelectionSources() {
    return hydrateDreamsAndGoalsFromStorage(
      dreamsAndGoals,
      storedSelectionSources: dreamsAndGoalsSelectionSources,
      storedCustomSelections: dreamsAndGoalsCustomItems(
        dreamsAndGoals,
        dreamsAndGoalsSelectionSources,
      ),
    );
  }

  /// Persists the form completion disclaimer using this model's injected
  /// storage service.
  Future<void> persistDisclaimerConfirmed() {
    return service.setItem(
      'disclaimerConfirmed',
      PersistentMemoryType.Bool,
      true,
    );
  }

  /// Persists the completed-form marker using this model's injected storage
  /// service.
  Future<void> persistHasFilled() {
    return service.setItem('hasFilled', PersistentMemoryType.Bool, true);
  }

  void updateDisclaimerSigned(bool value) {
    disclaimerSigned = value;
    notifyListeners();
  }

  void updateLoggedIn(bool value) {
    loggedIn = value;
    notifyListeners();
  }

  void updateUserId(String value) {
    userId = value;
    notifyListeners();
  }

  void updateNotificationHour(int value) {
    notificationHour = value;
    unawaited(
      _saveInBackground(
        () => service.setItem(
          'notificationHour',
          PersistentMemoryType.Int,
          value,
        ),
      ),
    );
    notifyListeners();
  }

  void updateNotificationMinute(int value) {
    notificationMinute = value;
    unawaited(
      _saveInBackground(
        () => service.setItem(
          'notificationMinute',
          PersistentMemoryType.Int,
          value,
        ),
      ),
    );
    notifyListeners();
  }

  void updateNotificationMessage(String value) {
    notificationMessage = value;
    unawaited(
      _saveInBackground(
        () => service.setItem(
          'notificationMessage',
          PersistentMemoryType.String,
          value,
        ),
      ),
    );
    notifyListeners();
  }

  /// Returns whether the selected dark-mode preference is active at [now].
  ///
  /// Scheduled mode uses the device's local time. A schedule that crosses
  /// midnight (for example, 22:00 to 06:00) is supported. Equal start and
  /// end times intentionally mean dark mode remains enabled all day.
  bool usesDarkModeAt(DateTime now) {
    switch (darkModePreference) {
      case DarkModePreference.alwaysLight:
        return false;
      case DarkModePreference.alwaysDark:
        return true;
      case DarkModePreference.scheduled:
        final currentMinutes = now.hour * 60 + now.minute;
        final startMinutes = darkModeStartHour * 60 + darkModeStartMinute;
        final endMinutes = darkModeEndHour * 60 + darkModeEndMinute;

        if (startMinutes == endMinutes) {
          return true;
        }
        if (startMinutes < endMinutes) {
          return currentMinutes >= startMinutes && currentMinutes < endMinutes;
        }
        return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  /// Returns the next local schedule boundary after [now], or `null` when a
  /// schedule has no boundary because it is active for the entire day.
  DateTime? nextDarkModeBoundaryAfter(DateTime now) {
    if (darkModePreference != DarkModePreference.scheduled) {
      return null;
    }

    final startMinutes = darkModeStartHour * 60 + darkModeStartMinute;
    final endMinutes = darkModeEndHour * 60 + darkModeEndMinute;
    if (startMinutes == endMinutes) {
      return null;
    }

    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
      darkModeStartHour,
      darkModeStartMinute,
    );
    final todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      darkModeEndHour,
      darkModeEndMinute,
    );
    // Construct tomorrow from calendar fields rather than adding 24 hours, so
    // a daylight-saving transition still schedules the same local clock time.
    final tomorrowStart = DateTime(
      now.year,
      now.month,
      now.day + 1,
      darkModeStartHour,
      darkModeStartMinute,
    );
    final tomorrowEnd = DateTime(
      now.year,
      now.month,
      now.day + 1,
      darkModeEndHour,
      darkModeEndMinute,
    );

    final candidates = <DateTime>[
      todayStart,
      todayEnd,
      tomorrowStart,
      tomorrowEnd,
    ]..sort();

    return candidates.firstWhere((boundary) => boundary.isAfter(now));
  }

  static DarkModePreference? parseDarkModePreference(String? value) {
    for (final preference in DarkModePreference.values) {
      if (preference.name == value) {
        return preference;
      }
    }
    return null;
  }

  /// Applies a persisted setting without writing it back to local storage.
  /// Invalid stored times fall back to the default 22:00–06:00 schedule.
  void restoreDarkModeSettings({
    required DarkModePreference preference,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    darkModePreference = preference;
    darkModeStartHour = _validHourOrDefault(startHour, 22);
    darkModeStartMinute = _validMinuteOrDefault(startMinute, 0);
    darkModeEndHour = _validHourOrDefault(endHour, 6);
    darkModeEndMinute = _validMinuteOrDefault(endMinute, 0);
    notifyListeners();
  }

  /// Updates and persists the dark-mode preference and complete schedule.
  Future<void> updateDarkModeSettings({
    DarkModePreference? preference,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) async {
    if (startHour != null && !_isValidHour(startHour)) {
      throw ArgumentError.value(startHour, 'startHour', 'Must be 0 through 23');
    }
    if (endHour != null && !_isValidHour(endHour)) {
      throw ArgumentError.value(endHour, 'endHour', 'Must be 0 through 23');
    }
    if (startMinute != null && !_isValidMinute(startMinute)) {
      throw ArgumentError.value(
        startMinute,
        'startMinute',
        'Must be 0 through 59',
      );
    }
    if (endMinute != null && !_isValidMinute(endMinute)) {
      throw ArgumentError.value(endMinute, 'endMinute', 'Must be 0 through 59');
    }

    darkModePreference = preference ?? darkModePreference;
    darkModeStartHour = startHour ?? darkModeStartHour;
    darkModeStartMinute = startMinute ?? darkModeStartMinute;
    darkModeEndHour = endHour ?? darkModeEndHour;
    darkModeEndMinute = endMinute ?? darkModeEndMinute;
    notifyListeners();

    await Future.wait<void>([
      service.setItem(
        'darkModePreference',
        PersistentMemoryType.String,
        darkModePreference.name,
      ),
      service.setItem(
        'darkModeStartHour',
        PersistentMemoryType.Int,
        darkModeStartHour,
      ),
      service.setItem(
        'darkModeStartMinute',
        PersistentMemoryType.Int,
        darkModeStartMinute,
      ),
      service.setItem(
        'darkModeEndHour',
        PersistentMemoryType.Int,
        darkModeEndHour,
      ),
      service.setItem(
        'darkModeEndMinute',
        PersistentMemoryType.Int,
        darkModeEndMinute,
      ),
    ]);
  }

  static bool _isValidHour(int value) => value >= 0 && value <= 23;

  static bool _isValidMinute(int value) => value >= 0 && value <= 59;

  static int _validHourOrDefault(int? value, int defaultValue) {
    return value != null && _isValidHour(value) ? value : defaultValue;
  }

  static int _validMinuteOrDefault(int? value, int defaultValue) {
    return value != null && _isValidMinute(value) ? value : defaultValue;
  }

  void updateLocaleName(String value) {
    localeName = value;
    notifyListeners();
  }

  void updatePositiveTraits(List<String> value) {
    positiveTraits = [...value];
    unawaited(
      _saveInBackground(
        () => service.setItem(
          'positiveTraits',
          PersistentMemoryType.StringList,
          positiveTraits,
        ),
      ),
    );
    notifyListeners();
  }

  void updateThanks(Map<String, List<String>> value) {
    final savedThanks = List<String>.from(value['thanks'] ?? const <String>[]);
    final savedDates = List<String>.from(value['dates'] ?? const <String>[]);
    thanks = {'thanks': savedThanks, 'dates': savedDates};
    unawaited(
      _saveInBackground(() async {
        await service.setItem(
          'thankYous',
          PersistentMemoryType.StringList,
          savedThanks,
        );
        await service.setItem(
          'dates',
          PersistentMemoryType.StringList,
          savedDates,
        );
      }),
    );
    notifyListeners();
  }

  void updateLocation(String value) {
    location = value;
    unawaited(
      _saveInBackground(
        () => service.setItem('location', PersistentMemoryType.String, value),
      ),
    );
    notifyListeners();
  }
}
