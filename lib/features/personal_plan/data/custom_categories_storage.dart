import 'dart:convert';

import 'package:mazilon/features/personal_plan/data/custom_categories_models.dart';
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';

/// Serializes this model's custom-category writes and retains its last retry.
///
/// A failed write reaches its caller, while later revisions may still proceed.
final class CustomCategoriesSaveQueue {
  Future<void> _pending = Future<void>.value();
  Future<void>? _tail;
  List<MapEntry<String, String>>? _snapshot;
  PersistentMemoryService? _source;
  int _revision = 0;

  int get revision => _revision;
  Future<void> get pending => _pending;

  void invalidate() {
    _revision++;
  }

  ({int revision, Future<void> save}) queue(
    List<MapEntry<String, String>> categories,
    PersistentMemoryService source,
  ) {
    final snapshot = List<MapEntry<String, String>>.unmodifiable(categories);
    _snapshot = snapshot;
    _source = source;
    final revision = ++_revision;
    final previous = _tail;
    final save = previous == null
        ? saveCustomCategoriesToStorage(snapshot, memoryService: source)
        : previous.then(
            (_) =>
                saveCustomCategoriesToStorage(snapshot, memoryService: source),
          );
    _pending = save;
    final continued = save.catchError((Object _) {});
    _tail = continued;
    continued.whenComplete(() {
      if (identical(_tail, continued)) _tail = null;
    });
    return (revision: revision, save: save);
  }

  Future<void> retry(
    int expectedRevision,
    Future<void> Function(List<MapEntry<String, String>>) save,
  ) {
    final snapshot = _snapshot;
    if (expectedRevision != _revision || snapshot == null) return _pending;
    return save(snapshot);
  }

  Future<void> awaitOrRetry(
    Future<void> Function(
      List<MapEntry<String, String>>,
      PersistentMemoryService,
    )
    save,
  ) async {
    try {
      await _pending;
    } catch (error, stackTrace) {
      final snapshot = _snapshot;
      final source = _source;
      if (snapshot == null || source == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      await save(snapshot, source);
    }
  }
}

/// Canonical JSON snapshot key for custom categories.
const String customCategoriesKey = 'customCategories';

/// Legacy title-list key retained for older readers.
const String customCategoryTitlesKey = 'customCategoryTitles';

/// Legacy description-list key retained for older readers.
const String customCategoryDescriptionsKey = 'customCategoryDescriptions';

/// Commit marker fencing the two legacy mirror lists.
const String customCategoriesLegacyCommitKey = 'customCategoriesLegacyCommit';

String _encodeCustomCategories(List<MapEntry<String, String>> categories) =>
    jsonEncode(
      categories
          .map((entry) => {'title': entry.key, 'description': entry.value})
          .toList(),
    );

List<MapEntry<String, String>> _decodeCustomCategories(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! List) {
    throw const FormatException(
      'Custom category snapshot must contain a JSON list.',
    );
  }
  final entries = <MapEntry<String, String>>[];
  for (final item in decoded) {
    if (item is Map) {
      entries.add(
        MapEntry(
          item['title']?.toString() ?? '',
          item['description']?.toString() ?? '',
        ),
      );
    }
  }
  return sanitizeAndFilterCustomCategoryEntries(entries);
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

/// Loads and parses custom category entries from [memoryService].
///
/// Attempts to load the canonical single-key JSON snapshot from
/// [customCategoriesKey] first. If missing or invalid, falls back to the
/// legacy [customCategoryTitlesKey] and [customCategoryDescriptionsKey] lists.
/// Once [customCategoriesLegacyCommitKey] exists, the legacy lists are used
/// only when their normalized content matches that commit marker.
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
  final canonical = _parseCanonicalCustomCategories(rawJson);
  if (canonical != null) return canonical;

  return parseCustomCategoriesSnapshot({
    customCategoriesKey: rawJson,
    customCategoryTitlesKey: await memoryService.getItem(
      customCategoryTitlesKey,
      PersistentMemoryType.StringList,
    ),
    customCategoryDescriptionsKey: await memoryService.getItem(
      customCategoryDescriptionsKey,
      PersistentMemoryType.StringList,
    ),
    customCategoriesLegacyCommitKey: await memoryService.getItem(
      customCategoriesLegacyCommitKey,
      PersistentMemoryType.String,
    ),
  });
}

/// Parses categories from an already captured set of storage values.
List<MapEntry<String, String>> parseCustomCategoriesSnapshot(
  Map<String, Object?> values,
) {
  final canonical = _parseCanonicalCustomCategories(
    values[customCategoriesKey],
  );
  if (canonical != null) return canonical;
  final legacyCategories = sanitizeAndFilterCustomCategories(
    TypeUtils.castToStringList(values[customCategoryTitlesKey]),
    TypeUtils.castToStringList(values[customCategoryDescriptionsKey]),
  );
  final rawCommit = values[customCategoriesLegacyCommitKey];
  if (rawCommit is String && rawCommit.trim().isNotEmpty) {
    final committed = _parseCanonicalCustomCategories(rawCommit);
    if (committed == null ||
        _encodeCustomCategories(committed) !=
            _encodeCustomCategories(legacyCategories)) {
      return const [];
    }
  }
  return legacyCategories;
}

List<MapEntry<String, String>>? _parseCanonicalCustomCategories(
  Object? rawJson,
) {
  if (rawJson is String && rawJson.trim().isNotEmpty) {
    try {
      return _decodeCustomCategories(rawJson);
    } on FormatException {
      // Fall through to legacy keys on decode error
    }
  }

  return null;
}

/// Persists custom category entries into [memoryService].
///
/// Persists the canonical JSON snapshot under [customCategoriesKey], updates
/// the legacy [customCategoryTitlesKey] and [customCategoryDescriptionsKey]
/// mirrors, and advances [customCategoriesLegacyCommitKey] last. The final
/// marker prevents current readers from pairing legacy lists from different
/// writes after a partial failure.
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
  final jsonPayload = _encodeCustomCategories(sanitized);

  // Write the canonical snapshot first, then the legacy mirrors, and advance
  // the legacy commit marker last. The marker fences readers that must fall
  // back to the two legacy lists after a partial or failed mirror write.
  await memoryService.setItem(
    customCategoriesKey,
    PersistentMemoryType.String,
    jsonPayload,
  );
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
  await memoryService.setItem(
    customCategoriesLegacyCommitKey,
    PersistentMemoryType.String,
    jsonPayload,
  );
}
