import 'dart:convert';

import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';

const String customCategoriesKey = 'customCategories';
const String customCategoryTitlesKey = 'customCategoryTitles';
const String customCategoryDescriptionsKey = 'customCategoryDescriptions';

/// Trims and filters pairs of titles and descriptions, discarding empty entries.
List<MapEntry<String, String>> sanitizeAndFilterCustomCategories(
  List<String> titles,
  List<String> descriptions,
) {
  final loadedCategories = <MapEntry<String, String>>[];
  for (var i = 0; i < titles.length && i < descriptions.length; i++) {
    final title = titles[i].trim();
    final description = descriptions[i].trim();
    if (title.isEmpty || description.isEmpty) {
      continue;
    }
    loadedCategories.add(MapEntry(title, description));
  }
  return loadedCategories;
}

/// Trims and filters custom category MapEntry items, discarding empty entries.
List<MapEntry<String, String>> sanitizeAndFilterCustomCategoryEntries(
  List<MapEntry<String, String>> categories,
) {
  final loadedCategories = <MapEntry<String, String>>[];
  for (final entry in categories) {
    final title = entry.key.trim();
    final description = entry.value.trim();
    if (title.isEmpty || description.isEmpty) {
      continue;
    }
    loadedCategories.add(MapEntry(title, description));
  }
  return loadedCategories;
}

/// Loads and parses custom category entries from [memoryService].
///
/// Attempts to load the atomic single-key JSON snapshot from [customCategoriesKey]
/// first. If missing or invalid, falls back to loading and pairing the legacy
/// [customCategoryTitlesKey] and [customCategoryDescriptionsKey] lists.
Future<List<MapEntry<String, String>>> loadCustomCategoriesFromStorage({
  PersistentMemoryService? memoryService,
}) async {
  if (memoryService == null) {
    return const <MapEntry<String, String>>[];
  }

  // 1. Try atomic JSON snapshot first
  final rawJson = await memoryService.getItem(
    customCategoriesKey,
    PersistentMemoryType.String,
  );
  if (rawJson is String && rawJson.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        final result = <MapEntry<String, String>>[];
        for (final item in decoded) {
          if (item is Map) {
            final title = item['title']?.toString() ?? '';
            final description = item['description']?.toString() ?? '';
            result.add(MapEntry(title, description));
          }
        }
        return sanitizeAndFilterCustomCategoryEntries(result);
      }
    } catch (_) {
      // Fall through to legacy keys on decode error
    }
  }

  // 2. Fallback to separate legacy keys for backward compatibility
  final titles = TypeUtils.castToStringList(
    await memoryService.getItem(
      customCategoryTitlesKey,
      PersistentMemoryType.StringList,
    ),
  );
  final descriptions = TypeUtils.castToStringList(
    await memoryService.getItem(
      customCategoryDescriptionsKey,
      PersistentMemoryType.StringList,
    ),
  );
  return sanitizeAndFilterCustomCategories(titles, descriptions);
}

/// Persists custom category entries into [memoryService].
///
/// Persists the atomic JSON snapshot under [customCategoriesKey] and updates the
/// legacy [customCategoryTitlesKey] and [customCategoryDescriptionsKey] lists
/// in a single coordinated write.
/// Throws a [StateError] if [memoryService] is `null`.
Future<void> saveCustomCategoriesToStorage(
  List<MapEntry<String, String>> categories, {
  PersistentMemoryService? memoryService,
}) async {
  if (memoryService == null) {
    throw StateError(
      'Persistent memory service is unavailable to save custom categories.',
    );
  }
  final sanitized = sanitizeAndFilterCustomCategoryEntries(categories);
  final jsonPayload = jsonEncode(
    sanitized.map((e) => {'title': e.key, 'description': e.value}).toList(),
  );

  await Future.wait([
    memoryService.setItem(
      customCategoriesKey,
      PersistentMemoryType.String,
      jsonPayload,
    ),
    memoryService.setItem(
      customCategoryTitlesKey,
      PersistentMemoryType.StringList,
      sanitized.map((category) => category.key).toList(),
    ),
    memoryService.setItem(
      customCategoryDescriptionsKey,
      PersistentMemoryType.StringList,
      sanitized.map((category) => category.value).toList(),
    ),
  ]);
}
