import 'dart:async';
import 'dart:convert';

import 'package:mazilon/features/notifications/data/notification_models.dart';
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
  Future<void>? _pendingWrite;

  Map<String, NotificationPreference> get preferences =>
      Map.unmodifiable(_preferences);

  NotificationPreference? getPreference(String typeId) => _preferences[typeId];

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
      return;
    }
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException(
        'notificationPreferences must be a JSON object',
      );
    }
    final restored = <String, NotificationPreference>{};
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
  }

  Future<void> setPreference(
    String typeId,
    NotificationPreference preference,
  ) {
    _preferences = {..._preferences, typeId: preference};
    return _persist();
  }

  Future<void> clearPreference(String typeId) {
    _preferences = {..._preferences}..remove(typeId);
    return _persist();
  }

  Future<void> _persist() {
    final encoded = jsonEncode(
      _preferences.map((key, value) => MapEntry(key, value.toJson())),
    );
    final previous = _pendingWrite;
    final write = previous == null
        ? _memory.setItem(
            'notificationPreferences',
            PersistentMemoryType.String,
            encoded,
          )
        : previous
              .catchError((Object _) {})
              .then<void>(
                (_) => _memory.setItem(
                  'notificationPreferences',
                  PersistentMemoryType.String,
                  encoded,
                ),
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
