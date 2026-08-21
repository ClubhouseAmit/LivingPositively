import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';
import 'package:mazilon/util/userInformation.dart';

const String customCategoryTitlesKey = 'customCategoryTitles';
const String customCategoryDescriptionsKey = 'customCategoryDescriptions';

/// Resolves the effective [PersistentMemoryService] with fallback precedence:
/// 1. [explicitService] (caller or widget override)
/// 2. [userInformation.service]
/// 3. [GetIt] registered instance
PersistentMemoryService? resolvePersistentMemoryService({
  PersistentMemoryService? explicitService,
  UserInformation? userInformation,
}) {
  if (explicitService != null) {
    return explicitService;
  }
  if (userInformation != null) {
    return userInformation.service;
  }
  if (GetIt.instance.isRegistered<PersistentMemoryService>()) {
    return GetIt.instance<PersistentMemoryService>();
  }
  return null;
}

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
Future<List<MapEntry<String, String>>> loadCustomCategoriesFromStorage({
  PersistentMemoryService? memoryService,
}) async {
  if (memoryService == null) {
    return const <MapEntry<String, String>>[];
  }
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
  await memoryService.setItem(
    customCategoryTitlesKey,
    PersistentMemoryType.StringList,
    sanitized.map((category) => category.key).toList(),
  );
  await memoryService.setItem(
    customCategoryDescriptionsKey,
    PersistentMemoryType.StringList,
    sanitized.map((category) => category.value).toList(),
  );
}
