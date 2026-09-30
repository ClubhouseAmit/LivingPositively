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
  final settings = jsonDecode(expanded);
  if (settings is! Map) {
    throw const FormatException('Invalid reminder settings');
  }
  final merged = Map<String, dynamic>.from(settings)..remove('default');
  for (final entry in decoded.entries) {
    if (entry.key is String && entry.value is Map) {
      final previous = merged[entry.key];
      merged[entry.key as String] = {
        if (previous is Map) ...Map<String, dynamic>.from(previous),
        ...Map<String, dynamic>.from(entry.value as Map),
      };
    }
  }
  merged['__defaultOptOut'] = !decoded.containsKey('default');
  return jsonEncode(merged);
}
