import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/dreams_and_goals_selection.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/notification_preference.dart';
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
  bool authDecisionMade;
  String userId;
  String email;
  String displayName;
  Map<String, NotificationPreference> notificationPreferences;
  DarkModePreference darkModePreference;
  int darkModeStartHour;
  int darkModeStartMinute;
  int darkModeEndHour;
  int darkModeEndMinute;
  Map<String, List<String>> thanks;
  List<MapEntry<String, String>> customCategories;
  PersistentMemoryService service; // Get the persistent memory service instance
  Future<void> _pendingDreamsAndGoalsSave = Future<void>.value();
  Future<void> _pendingCustomCategoriesSave = Future<void>.value();
  Future<void>? _customCategoriesWriteTail;
  Future<void>? _notificationPreferencesWrite;
  int _dreamsAndGoalsSaveRevision = 0;
  int _customCategoriesSaveRevision = 0;
  int _activeDreamsAndGoalsSavesCount = 0;

  /// Whether a Dreams and Goals persistence operation is currently pending.
  bool get isDreamsAndGoalsSavePending => _activeDreamsAndGoalsSavesCount > 0;

  /// In-flight custom categories persistence future.
  Future<void> get pendingCustomCategoriesSave => _pendingCustomCategoriesSave;

  UserInformation({
    this.location = '',
    this.thanks = const <String, List<String>>{},
    this.positiveTraits = const [],
    this.localeName = '',
    this.notificationPreferences = const {},
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
    this.customCategories = const [],
    this.disclaimerSigned = false,
    this.loggedIn = false,
    this.authDecisionMade = false,
    this.userId = '',
    this.email = '',
    this.displayName = '',
    PersistentMemoryService? service,
  }) : service = service ?? GetIt.instance<PersistentMemoryService>();

  /// Hydrates custom categories from [memoryService] (or the default [service]).
  Future<List<MapEntry<String, String>>> loadCustomCategories({
    PersistentMemoryService? memoryService,
  }) async {
    final effectiveMemoryService = memoryService ?? service;
    final int revisionAtLoadStart = _customCategoriesSaveRevision;
    final loaded = await loadCustomCategoriesFromStorage(
      memoryService: effectiveMemoryService,
    );
    // A load begun during initialization may complete after an interactive
    // save has started. That response reflects the old storage snapshot and
    // must not replace the newer in-memory categories.
    if (revisionAtLoadStart != _customCategoriesSaveRevision) {
      return customCategories;
    }
    customCategories = List<MapEntry<String, String>>.unmodifiable(loaded);
    notifyListeners();
    return customCategories;
  }

  /// Persists [categories] (or current [customCategories]) into [memoryService] (or the default [service]).
  Future<void> saveCustomCategories({
    List<MapEntry<String, String>>? categories,
    PersistentMemoryService? memoryService,
  }) async {
    final effectiveMemoryService = memoryService ?? service;
    final toSave = categories ?? customCategories;
    final sanitized = sanitizeAndFilterCustomCategoryEntries(toSave);
    final int revision = ++_customCategoriesSaveRevision;
    final previousWrite = _customCategoriesWriteTail;
    final Future<void> nextSave = previousWrite == null
        ? saveCustomCategoriesToStorage(
            sanitized,
            memoryService: effectiveMemoryService,
          )
        : previousWrite.then(
            (_) => saveCustomCategoriesToStorage(
              sanitized,
              memoryService: effectiveMemoryService,
            ),
          );
    // The caller must observe this write's failure so the UI can offer a
    // retry. A later write continues after that failure through the safe tail
    // below, while export preparation explicitly ignores an older
    // failed tail after it has finished.
    _pendingCustomCategoriesSave = nextSave;
    final Future<void> continuedWriteTail = nextSave.catchError((Object _) {});
    _customCategoriesWriteTail = continuedWriteTail;
    continuedWriteTail.whenComplete(() {
      if (identical(_customCategoriesWriteTail, continuedWriteTail)) {
        _customCategoriesWriteTail = null;
      }
    });
    await nextSave;
    if (revision != _customCategoriesSaveRevision) {
      return;
    }
    if (_matchesCustomCategories(sanitized)) {
      return;
    }
    customCategories = List<MapEntry<String, String>>.unmodifiable(sanitized);
    notifyListeners();
  }

  bool _matchesCustomCategories(List<MapEntry<String, String>> categories) {
    if (customCategories.length != categories.length) {
      return false;
    }
    for (var index = 0; index < categories.length; index++) {
      final MapEntry<String, String> current = customCategories[index];
      final MapEntry<String, String> candidate = categories[index];
      if (current.key != candidate.key || current.value != candidate.value) {
        return false;
      }
    }
    return true;
  }

  /// Clears user state and persists the empty Dreams and Goals snapshot.
  ///
  /// State observers receive the cleared state before this completes. The
  /// returned future completes only after the queued Dreams snapshot succeeds.
  Future<void> reset(String locale) async {
    location = '';
    notificationPreferences = {};
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
    customCategories = [];
    // An in-flight snapshot cannot be cancelled safely. Queue the empty
    // snapshots behind them so reset is always the final local state.
    _dreamsAndGoalsSaveRevision++;
    loggedIn = false;
    authDecisionMade = false;
    userId = '';
    email = '';
    displayName = '';
    thanks = {};
    positiveTraits = [];
    localeName = locale;

    notifyListeners();
    await Future.wait([
      queueDreamsAndGoalsSave(),
      saveCustomCategories(categories: const <MapEntry<String, String>>[]),
    ]);
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

  Future<void> updateGenderAndBinary({
    required String gender,
    required bool isBinary,
  }) async {
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
    notifyListeners();
  }

  /// The latest serialized Dreams and Goals save, including queued snapshots.
  Future<void> get pendingDreamsAndGoalsSave => _pendingDreamsAndGoalsSave;

  /// Revision captured with a Dreams and Goals persistence snapshot.
  int get dreamsAndGoalsSaveRevision => _dreamsAndGoalsSaveRevision;

  /// Queues an immutable three-key snapshot after any prior Dreams save.
  ///
  /// This stays with the shared injected [UserInformation] storage state,
  /// matching the existing model convention and keeping the wizard and Share
  /// surfaces synchronized around one revision-aware queue.
  ///
  /// A failed older write does not block a later snapshot: each new save
  /// continues after the previous error so the latest queued state wins.
  Future<void> queueDreamsAndGoalsSave() {
    final DreamsAndGoalsPersistenceSnapshot snapshot =
        DreamsAndGoalsPersistenceSnapshot.fromSelections(
          dreamsAndGoals,
          dreamsAndGoalsSelectionSources,
        );
    _activeDreamsAndGoalsSavesCount++;
    final Future<void> nextSave = _pendingDreamsAndGoalsSave
        .catchError((Object _) {})
        .then((_) => persistDreamsAndGoalsSnapshot(service, snapshot))
        .whenComplete(() {
          if (_activeDreamsAndGoalsSavesCount > 0) {
            _activeDreamsAndGoalsSavesCount--;
          }
        });
    // Keep the queue usable after a failed snapshot. A later save continues
    // through catchError above, while this tail retains the current write's
    // error for callers that must block navigation and offer a retry.
    _pendingDreamsAndGoalsSave = nextSave;
    return nextSave;
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

  /// Loads Dreams and Goals state from local storage and repairs stale
  /// provenance metadata through this model's injected storage service.
  ///
  /// The localized [selections] stay in their saved order. Source tokens and
  /// the custom-only list are normalized into one immutable snapshot. Multiple
  /// explicit custom rows remain in their original order. The three-key
  /// snapshot is queued only when either stored metadata list differs from the
  /// repaired values.
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
  /// lifecycle without altering explicit custom rows. Storage hydration should
  /// use [hydrateDreamsAndGoalsFromStorage] so it can also repair custom
  /// metadata.
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

  /// Persists Dreams and Goals snapshot combined with the disclaimer confirmation
  /// using this model's injected storage service.
  Future<void> saveDreamsAndGoalsWithDisclaimer({
    required int revision,
    required bool retry,
  }) {
    final Future<void> dreamsSave = retry
        ? retryDreamsAndGoalsSave(revision)
        : queueDreamsAndGoalsSave();
    final Future<void> disclaimerSave = Future<void>.sync(
      persistDisclaimerConfirmed,
    );
    return Future.wait<void>([dreamsSave, disclaimerSave]);
  }

  /// Updates category selections in memory and persists them through this
  /// model's injected storage service.
  Future<void> saveCategorySelection(
    String collectionName,
    List<String> items, {
    List<String>? selectionSources,
    void Function(int revision)? onDreamsSaveQueued,
  }) async {
    switch (collectionName) {
      case 'PersonalPlan-DifficultEvents':
        updateDifficultEvents([...items]);
        break;
      case 'PersonalPlan-MakeSafer':
        updateMakeSafer([...items]);
        break;
      case 'PersonalPlan-FeelBetter':
        updateFeelBetter([...items]);
        break;
      case 'PersonalPlan-Distractions':
        updateDistractions([...items]);
        break;
      case 'PersonalPlan-SafeEnvironment':
        updateSafeEnvironment([...items]);
        break;
      case 'PersonalPlan-DreamsAndGoals':
        updateDreamsAndGoals(
          items,
          selectionSources:
              selectionSources ??
              (listEquals(items, dreamsAndGoals)
                  ? dreamsAndGoalsSelectionSources
                  : normalizeDreamsAndGoalsSelectionSources(
                      items,
                      dreamsAndGoalsSelectionSources,
                    )),
        );
        final int revision = dreamsAndGoalsSaveRevision;
        onDreamsSaveQueued?.call(revision);
        await saveDreamsAndGoalsWithDisclaimer(
          revision: revision,
          retry: false,
        );
        return;
      default:
        throw ArgumentError.value(
          collectionName,
          'collectionName',
          'Unsupported Personal Plan category name.',
        );
    }
    await persistDisclaimerConfirmed();
    await service.setItem(
      'userSelection$collectionName',
      PersistentMemoryType.StringList,
      [...items],
    );
    await service.setItem(
      'addedStrings$collectionName',
      PersistentMemoryType.StringList,
      [...items],
    );
  }

  /// Awaits all pending saves and repairs Dreams and Goals selection sources
  /// until storage has a stable, normalized snapshot for Personal Plan export.
  Future<void> prepareForPersonalPlanExport() async {
    await _ignoreCompletedPersistenceFailure(_pendingCustomCategoriesSave);
    final bool needsRepair = !listEquals(
      dreamsAndGoalsSelectionSources,
      normalizeDreamsAndGoalsSelectionSources(
        dreamsAndGoals,
        dreamsAndGoalsSelectionSources,
      ),
    );
    if (!needsRepair && _activeDreamsAndGoalsSavesCount == 0) {
      await _ignoreCompletedPersistenceFailure(_pendingCustomCategoriesSave);
      return;
    }
    while (true) {
      await _ignoreCompletedPersistenceFailure(_pendingDreamsAndGoalsSave);
      final int revisionBeforeRepair = _dreamsAndGoalsSaveRevision;
      await repairDreamsAndGoalsSelectionSources();
      await _ignoreCompletedPersistenceFailure(_pendingDreamsAndGoalsSave);
      if (_dreamsAndGoalsSaveRevision == revisionBeforeRepair) {
        await _ignoreCompletedPersistenceFailure(_pendingDreamsAndGoalsSave);
        break;
      }
    }
    await _ignoreCompletedPersistenceFailure(_pendingCustomCategoriesSave);
  }

  /// Waits for a prior persistence attempt without replaying its error.
  ///
  /// Export preparation can repair or overwrite an older failed snapshot, so
  /// it must not be permanently blocked by that completed attempt.
  Future<void> _ignoreCompletedPersistenceFailure(Future<void> pending) {
    return pending.catchError((Object _) {});
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
    _savePersistedValue(
      () => service.setItem('loggedIn', PersistentMemoryType.Bool, value),
    );
    notifyListeners();
  }

  void updateAuthDecisionMade(bool value) {
    authDecisionMade = value;
    _savePersistedValue(
      () =>
          service.setItem('authDecisionMade', PersistentMemoryType.Bool, value),
    );
    notifyListeners();
  }

  void updateEmail(String value) {
    email = value;
    notifyListeners();
  }

  void updateDisplayName(String value) {
    displayName = value;
    notifyListeners();
  }

  void updateUserId(String value) {
    userId = value;
    _savePersistedValue(
      () => service.setItem('userId', PersistentMemoryType.String, value),
    );
    notifyListeners();
  }

  NotificationPreference? getNotificationPreference(String typeId) =>
      notificationPreferences[typeId];

  Future<void> setNotificationPreference(
    String typeId,
    NotificationPreference preference,
  ) {
    notificationPreferences = {...notificationPreferences, typeId: preference};
    final write = _saveNotificationPreferences();
    notifyListeners();
    return write;
  }

  Future<void> clearNotificationPreference(String typeId) {
    notificationPreferences = Map<String, NotificationPreference>.from(
      notificationPreferences,
    )..remove(typeId);
    final write = _saveNotificationPreferences();
    notifyListeners();
    return write;
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

  Future<void> _saveNotificationPreferences() {
    final encoded = jsonEncode(
      notificationPreferences.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    );
    final previousWrite = _notificationPreferencesWrite;
    final write = previousWrite == null
        ? service.setItem(
            'notificationPreferences',
            PersistentMemoryType.String,
            encoded,
          )
        : previousWrite
              .catchError((Object _) {
                // A failed older write must not prevent the latest state from
                // saving.
              })
              .then<void>(
                (_) => service.setItem(
                  'notificationPreferences',
                  PersistentMemoryType.String,
                  encoded,
                ),
              );
    _notificationPreferencesWrite = write;
    unawaited(
      write.then<void>(
        (_) {
          if (identical(_notificationPreferencesWrite, write)) {
            _notificationPreferencesWrite = null;
          }
        },
        onError: (Object _, StackTrace _) {
          if (identical(_notificationPreferencesWrite, write)) {
            _notificationPreferencesWrite = null;
          }
        },
      ),
    );
    return write;
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

  void _savePersistedValue(Future<void> Function() write) {
    unawaited(
      Future<void>.sync(write).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _reportPersistenceFailure(error, stackTrace);
      }),
    );
  }

  void _reportPersistenceFailure(Object error, StackTrace stackTrace) {
    if (!GetIt.instance.isRegistered<IncidentLoggerService>()) {
      debugPrint('Persistent user state write failed: $error');
      return;
    }
    unawaited(
      Future<void>.sync(
        () => GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        ),
      ).catchError((Object loggerError, StackTrace loggerStackTrace) {
        debugPrint(
          'Persistent user state failure reporting failed: $loggerError',
        );
      }),
    );
  }
}
