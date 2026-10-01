import 'dart:async';
import 'dart:convert';

import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_preferences_storage.dart';
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';

/// Owns notification preference state and its persisted JSON representation.
class NotificationRepository {
  NotificationRepository._(this._memory);

  static final Expando<NotificationRepository> _instances =
      Expando<NotificationRepository>('notification repositories');

  factory NotificationRepository.forService(PersistentMemoryService memory) =>
      _instances[memory] ??= NotificationRepository._(memory);

  final PersistentMemoryService _memory;
  Map<String, NotificationPreference> _preferences = const {};
  Map<String, NotificationPreference> _savedTimes = const {};
  Set<String> _pausedAccountReminders = const {};
  String? _pausedAccountOwnerUid;
  String? _activeAccountUid;
  Map<String, String> _accountSnapshots = const {};
  List<CustomReminder> _customReminders = const [];
  bool _use24HourFormat = true;
  bool _defaultOptOut = false;
  Future<void>? _pendingWrite;

  Map<String, NotificationPreference> get preferences =>
      Map.unmodifiable(_preferences);

  List<CustomReminder> get customReminders =>
      List.unmodifiable(_customReminders);

  bool get use24HourFormat => _use24HourFormat;

  bool get defaultOptOut => _defaultOptOut;

  bool isActiveAccount(String uid) =>
      uid.isNotEmpty && _activeAccountUid == uid;

  Future<void> activateAccount(String uid) async {
    if (uid.isEmpty) throw ArgumentError.value(uid, 'uid');
    if (_activeAccountUid == uid) return;
    if (_activeAccountUid case final previousUid?) {
      _accountSnapshots = {
        ..._accountSnapshots,
        previousUid: _encodePreferences(includeSnapshots: false),
      };
      final snapshots = _accountSnapshots;
      restoreJson(snapshots[uid]);
      _accountSnapshots = snapshots;
    }
    _activeAccountUid = uid;
    await _persist();
  }

  Map<String, NotificationPreference> pausedAccountRemindersFor(String uid) =>
      uid.isEmpty || uid != _pausedAccountOwnerUid
      ? const {}
      : Map.unmodifiable({
          for (final entry in _savedTimes.entries)
            if (_pausedAccountReminders.contains(entry.key))
              entry.key: entry.value,
        });

  NotificationPreference? getPreference(String typeId) => _preferences[typeId];

  NotificationPreference? getSavedTime(String typeId) =>
      _preferences[typeId] ?? _savedTimes[typeId];

  /// Replaces in-memory state from an already-read persisted snapshot.
  void restorePreferences(Map<String, NotificationPreference> preferences) {
    _preferences = Map<String, NotificationPreference>.unmodifiable(
      preferences,
    );
  }

  /// Parses persisted state, ignoring malformed entries without overwriting it.
  void restoreJson(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      restorePreferences(const {});
      _customReminders = const [];
      _savedTimes = const {};
      _pausedAccountReminders = const {};
      _pausedAccountOwnerUid = null;
      _activeAccountUid = null;
      _accountSnapshots = const {};
      _use24HourFormat = true;
      _defaultOptOut = false;
      return;
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException(
        'notificationPreferences must be a JSON object',
      );
    }
    final restored = <String, NotificationPreference>{};
    final custom = <CustomReminder>[];
    if (decoded['__customReminders'] case final List<dynamic> entries) {
      for (final entry in entries) {
        if (entry is! Map) continue;
        try {
          custom.add(CustomReminder.fromJson(Map<String, dynamic>.from(entry)));
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
    }
    _customReminders = List.unmodifiable(custom);
    _use24HourFormat = decoded['__use24HourFormat'] != false;
    final saved = <String, NotificationPreference>{};
    if (decoded['__savedTimes'] case final Map<dynamic, dynamic> entries) {
      for (final entry in entries.entries) {
        if (entry.key is! String || entry.value is! Map) continue;
        try {
          saved[entry.key as String] = NotificationPreference.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
    }
    _savedTimes = Map.unmodifiable(saved);
    _pausedAccountReminders = {
      if (decoded['__pausedAccountReminders'] case final List<dynamic> ids)
        for (final id in ids)
          if (id is String && id != 'default' && saved.containsKey(id)) id,
    };
    _restoreAccountMetadata(decoded);
    for (final entry in decoded.entries) {
      if (entry.key is! String || entry.value is! Map) continue;
      try {
        restored[entry.key as String] = NotificationPreference.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    restorePreferences(restored);
    _defaultOptOut = decoded.containsKey('__defaultOptOut')
        ? decoded['__defaultOptOut'] == true
        : !restored.containsKey('default');
  }

  void _restoreAccountMetadata(Map<dynamic, dynamic> decoded) {
    _pausedAccountOwnerUid = decoded['__pausedAccountOwnerUid'] is String
        ? decoded['__pausedAccountOwnerUid'] as String
        : null;
    _activeAccountUid = decoded['__activeAccountUid'] is String
        ? decoded['__activeAccountUid'] as String
        : null;
    _accountSnapshots = {
      if (decoded['__accountSnapshots']
          case final Map<dynamic, dynamic> entries)
        for (final entry in entries.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
    };
  }

  /// Keeps expanded state when an older client rewrites the legacy blob.
  void restorePersistedJson(String? legacy, String? expanded) {
    restoreJson(mergeNotificationSnapshots(legacy, expanded));
  }

  Future<void> restorePersistedState(String? legacy) async {
    final expanded = await _memory.getItem(
      'notificationReminderSettings',
      PersistentMemoryType.String,
    );
    restorePersistedJson(legacy, expanded as String?);
  }

  Future<void> setPreference(
    String typeId,
    NotificationPreference preference,
  ) {
    _preferences = {..._preferences, typeId: preference};
    if (_pausedAccountReminders.contains(typeId)) {
      _pausedAccountReminders = {..._pausedAccountReminders}..remove(typeId);
      _savedTimes = {..._savedTimes}..remove(typeId);
      if (_pausedAccountReminders.isEmpty) _pausedAccountOwnerUid = null;
    }
    if (typeId == 'default') _defaultOptOut = false;
    return _persist();
  }

  Future<void> clearPreference(String typeId) =>
      _clearPreference(typeId, markDefaultOptOut: true);

  /// Account transitions retire remote schedules without changing the choice.
  Future<void> clearPreferenceForAccountTransition(String typeId) {
    if (typeId == 'default') {
      return _clearPreference(
        typeId,
        markDefaultOptOut: false,
        clearSavedTime: true,
      );
    }
    final previous = _preferences[typeId];
    if (previous != null) {
      _savedTimes = {..._savedTimes, typeId: previous};
      _pausedAccountReminders = {..._pausedAccountReminders, typeId};
      _pausedAccountOwnerUid = _activeAccountUid;
    }
    return _clearPreference(typeId, markDefaultOptOut: false);
  }

  Future<void> clearPausedAccountReminder(String typeId) {
    _pausedAccountReminders = {..._pausedAccountReminders}..remove(typeId);
    return _persist();
  }

  /// Compensates registration without recording a user opt-out.
  Future<void> clearPreferenceAfterFailedRegistration(
    String typeId, {
    required bool previousDefaultOptOut,
  }) {
    if (typeId == 'default') _defaultOptOut = previousDefaultOptOut;
    return _clearPreference(typeId, markDefaultOptOut: false);
  }

  /// Restores a paused choice when its replacement could not be saved.
  Future<void> restorePausedAfterFailedRegistration(
    String typeId,
    NotificationPreference preference,
    String uid,
  ) {
    _preferences = {..._preferences}..remove(typeId);
    _savedTimes = {..._savedTimes, typeId: preference};
    _pausedAccountReminders = {..._pausedAccountReminders, typeId};
    _pausedAccountOwnerUid = uid;
    return _persist();
  }

  Future<void> _clearPreference(
    String typeId, {
    required bool markDefaultOptOut,
    bool clearSavedTime = false,
  }) {
    final previous = _preferences[typeId];
    if (typeId == 'default' && clearSavedTime) {
      _savedTimes = {..._savedTimes}..remove(typeId);
    } else if (previous != null && markDefaultOptOut) {
      _savedTimes = {..._savedTimes, typeId: previous};
    }
    if (typeId == 'default' && markDefaultOptOut) _defaultOptOut = true;
    if (markDefaultOptOut) {
      _pausedAccountReminders = {..._pausedAccountReminders}..remove(typeId);
    }
    _preferences = {..._preferences}..remove(typeId);
    return _persist();
  }

  Future<void> setSavedTime(String typeId, NotificationPreference preference) {
    _savedTimes = {..._savedTimes, typeId: preference};
    return _persist();
  }

  Future<void> setCustomReminder(CustomReminder reminder) {
    final updated = [..._customReminders];
    final index = updated.indexWhere((item) => item.id == reminder.id);
    if (index < 0) {
      updated.add(reminder);
    } else {
      updated[index] = reminder;
    }
    _customReminders = List.unmodifiable(updated);
    return _persist();
  }

  /// Saves a custom definition and its inactive time together before scheduling.
  Future<void> setCustomReminderTime(CustomReminder reminder) async {
    final previous = _customReminders
        .where((item) => item.id == reminder.id)
        .firstOrNull;
    final previousTime = _savedTimes[reminder.id];
    final saved = getSavedTime(reminder.id);
    _savedTimes = {
      ..._savedTimes,
      reminder.id: NotificationPreference.withContent(
        hour: reminder.hour,
        minute: reminder.minute,
        staticTitle: saved?.staticTitle,
        staticBody: saved?.staticBody,
      ),
    };
    try {
      await setCustomReminder(reminder);
    } catch (_) {
      _customReminders = List.unmodifiable([
        for (final item in _customReminders)
          if (item.id != reminder.id) item else ?previous,
      ]);
      _savedTimes = {..._savedTimes}..remove(reminder.id);
      if (previousTime != null) {
        _savedTimes = {..._savedTimes, reminder.id: previousTime};
      }
      await _persist();
      rethrow;
    }
  }

  Future<void> removeCustomReminder(String id) {
    _customReminders = List.unmodifiable(
      _customReminders.where((item) => item.id != id),
    );
    _savedTimes = {..._savedTimes}..remove(id);
    _pausedAccountReminders = {..._pausedAccountReminders}..remove(id);
    return _persist();
  }

  Future<void> setUse24HourFormat(bool value) {
    _use24HourFormat = value;
    return _persist();
  }

  String _encodePreferences({required bool includeSnapshots}) => jsonEncode({
    ..._preferences.map((key, value) => MapEntry(key, value.toJson())),
    '__customReminders': _customReminders.map((item) => item.toJson()).toList(),
    '__savedTimes': _savedTimes.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    '__use24HourFormat': _use24HourFormat,
    '__defaultOptOut': _defaultOptOut,
    '__pausedAccountReminders': _pausedAccountReminders.toList(),
    '__pausedAccountOwnerUid': _pausedAccountOwnerUid,
    '__activeAccountUid': _activeAccountUid,
    if (includeSnapshots) '__accountSnapshots': _accountSnapshots,
  });

  Future<void> _persist() {
    final encoded = _encodePreferences(includeSnapshots: true);
    final previous = _pendingWrite;
    final write = previous == null
        ? persistNotificationSnapshot(_memory, encoded)
        : previous
              .catchError((Object _) {})
              .then<void>(
                (_) => persistNotificationSnapshot(_memory, encoded),
              );
    _pendingWrite = write;
    unawaited(
      write.then<void>(
        (_) {
          if (identical(_pendingWrite, write)) _pendingWrite = null;
        },
        onError: (Object _, StackTrace _) {
          if (identical(_pendingWrite, write)) _pendingWrite = null;
        },
      ),
    );
    return write;
  }
}
