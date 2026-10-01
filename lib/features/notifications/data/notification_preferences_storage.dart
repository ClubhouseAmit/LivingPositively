import 'dart:convert';

import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';

/// Restores the primary blob if saving its compatibility copy fails.
Future<void> persistNotificationSnapshot(
  PersistentMemoryService memory,
  String encoded,
) async {
  final snapshot = await memory.readSnapshot({
    'notificationPreferences': PersistentMemoryType.String,
  });
  final previous = snapshot['notificationPreferences'];
  await memory.setItem(
    'notificationPreferences',
    PersistentMemoryType.String,
    encoded,
  );
  try {
    await memory.setItem(
      'notificationReminderSettings',
      PersistentMemoryType.String,
      encoded,
    );
  } catch (_) {
    await memory.setItem(
      'notificationPreferences',
      PersistentMemoryType.String,
      previous is String ? previous : '{}',
    );
    rethrow;
  }
}

/// Recovers expanded choices after an older client replaces the legacy map.
String? mergeNotificationSnapshots(String? legacy, String? expanded) {
  if (expanded == null || expanded.isEmpty) return legacy;
  final decoded = legacy == null || legacy.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(legacy);
  if (decoded is! Map) throw const FormatException('Invalid preferences');
  if (decoded.containsKey('__customReminders')) return legacy;
  final Map<String, dynamic> settings;
  try {
    final value = jsonDecode(expanded);
    if (value is! Map<String, dynamic>) return legacy;
    settings = value;
  } on FormatException {
    return legacy;
  }
  if (!_validNotificationOwnership(settings)) return legacy;
  // Older writers omit ownership, so their entries cannot be attributed to
  // an account in the retained snapshot without a matching active owner.
  final sameOwner =
      settings['__activeAccountUid'] is String &&
      settings['__activeAccountUid'] == decoded['__activeAccountUid'];
  if (!sameOwner &&
      (settings['__activeAccountUid'] != null ||
          settings['__pausedAccountOwnerUid'] != null ||
          (settings['__accountSnapshots'] is Map &&
              (settings['__accountSnapshots'] as Map).isNotEmpty))) {
    return expanded;
  }
  final merged = Map<String, dynamic>.from(settings)..remove('default');
  for (final entry in decoded.entries) {
    if (entry.key is String &&
        !(entry.key as String).startsWith('__') &&
        entry.value is Map) {
      final previous = merged[entry.key];
      merged[entry.key as String] = {
        if (previous is Map) ...Map<String, dynamic>.from(previous),
        ...Map<String, dynamic>.from(entry.value as Map),
      };
    }
  }
  merged['__defaultOptOut'] = decoded['__defaultOptOut'] is bool
      ? decoded['__defaultOptOut']
      : !decoded.containsKey('default');
  if (merged['__defaultOptOut'] == true) merged.remove('default');
  return jsonEncode(merged);
}

bool _validNotificationOwnership(Map<String, dynamic> settings) {
  for (final field in ['__activeAccountUid', '__pausedAccountOwnerUid']) {
    final owner = settings[field];
    if (owner != null && (owner is! String || owner.trim().isEmpty)) {
      return false;
    }
  }
  final snapshots = settings['__accountSnapshots'];
  if (snapshots == null) return true;
  if (snapshots is! Map<String, dynamic>) return false;
  for (final entry in snapshots.entries) {
    if (entry.key.trim().isEmpty || entry.value is! String) return false;
    try {
      final snapshot = jsonDecode(entry.value as String);
      if (snapshot is! Map<String, dynamic>) return false;
      final owner = snapshot['__activeAccountUid'];
      if (owner != null && owner != entry.key) return false;
    } on FormatException {
      return false;
    }
  }
  return true;
}
