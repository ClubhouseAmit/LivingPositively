import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
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
  PersistentMemoryService service; // Get the persistent memory service instance
  Future<void> _notificationPreferencesWrite = Future<void>.value();

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
    this.disclaimerSigned = false,
    this.loggedIn = false,
    this.authDecisionMade = false,
    this.userId = '',
    this.email = '',
    this.displayName = '',
    PersistentMemoryService? service,
  }) : service = service ?? GetIt.instance<PersistentMemoryService>();

  void reset(String locale) {
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
    loggedIn = false;
    authDecisionMade = false;
    userId = '';
    email = '';
    displayName = '';
    thanks = {};
    positiveTraits = [];
    localeName = locale;

    notifyListeners();
  }

  void updateGender(String text) {
    void saveGender(String value) async {
      await service.setItem('gender', PersistentMemoryType.String, value);
    }

    gender = text;
    saveGender(text);
    notifyListeners();
  }

  void updateName(String text) {
    void saveName(String value) async {
      await service.setItem('name', PersistentMemoryType.String, value);
    }

    name = text;
    saveName(text);
    notifyListeners();
  }

  void updateAge(String text) {
    void saveAge(String value) async {
      await service.setItem('age', PersistentMemoryType.String, value);
    }

    age = text;
    saveAge(text);
    notifyListeners();
  }

  void updateBinary(bool value) {
    void saveBinary(bool value) async {
      await service.setItem('binary', PersistentMemoryType.Bool, value);
    }

    binary = value;
    saveBinary(value);
    notifyListeners();
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

  void updateDisclaimerSigned(bool value) {
    disclaimerSigned = value;
    notifyListeners();
  }

  void updateLoggedIn(bool value) {
    loggedIn = value;
    service.setItem('loggedIn', PersistentMemoryType.Bool, value);
    notifyListeners();
  }

  void updateAuthDecisionMade(bool value) {
    authDecisionMade = value;
    service.setItem('authDecisionMade', PersistentMemoryType.Bool, value);
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
    service.setItem('userId', PersistentMemoryType.String, value);
    notifyListeners();
  }

  NotificationPreference? getNotificationPreference(String typeId) =>
      notificationPreferences[typeId];

  void setNotificationPreference(String typeId, NotificationPreference pref) {
    notificationPreferences = {...notificationPreferences, typeId: pref};
    _saveNotificationPreferences();
    notifyListeners();
  }

  void clearNotificationPreference(String typeId) {
    notificationPreferences = Map.from(notificationPreferences)..remove(typeId);
    _saveNotificationPreferences();
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

  void _saveNotificationPreferences() {
    final encoded = jsonEncode(
      notificationPreferences.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    );
    final previousWrite = _notificationPreferencesWrite;
    _notificationPreferencesWrite = () async {
      try {
        await previousWrite;
      } on Object {
        // A failed older write must not prevent the latest state from saving.
      }
      await service.setItem(
        'notificationPreferences',
        PersistentMemoryType.String,
        encoded,
      );
    }();
  }

  void updateLocaleName(String value) {
    localeName = value;
    notifyListeners();
  }

  void updatePositiveTraits(List<String> value) {
    Future<void> savePositiveTraits(List<String> traits) async {
      await service.setItem(
        'positiveTraits',
        PersistentMemoryType.StringList,
        traits,
      );
    }

    positiveTraits = [...value];
    savePositiveTraits(value);
    notifyListeners();
  }

  void updateThanks(Map<String, List<String>> value) {
    Future<void> saveThanks(List<String> thanks, List<String> dates) async {
      await service.setItem(
        'thankYous',
        PersistentMemoryType.StringList,
        thanks,
      );
      await service.setItem('dates', PersistentMemoryType.StringList, dates);
    }

    thanks = {"thanks": value["thanks"] ?? [], "dates": value["dates"] ?? []};
    saveThanks(value["thanks"] ?? [], value["dates"] ?? []);
    notifyListeners();
  }

  void updateLocation(String value) {
    location = value;

    notifyListeners();
  }
}
