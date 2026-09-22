/// Trims custom-category entries and discards entries with an empty field.
List<MapEntry<String, String>> sanitizeAndFilterCustomCategoryEntries(
  List<MapEntry<String, String>> categories,
) {
  final sanitized = <MapEntry<String, String>>[];
  for (final entry in categories) {
    final title = entry.key.trim();
    final description = entry.value.trim();
    if (title.isEmpty || description.isEmpty) {
      continue;
    }
    sanitized.add(MapEntry(title, description));
  }
  return sanitized;
}

/// Whether two custom-category snapshots have identical ordered content.
bool customCategoriesMatch(
  List<MapEntry<String, String>> current,
  List<MapEntry<String, String>> candidate,
) {
  if (current.length != candidate.length) return false;
  for (var index = 0; index < candidate.length; index++) {
    if (current[index].key != candidate[index].key ||
        current[index].value != candidate[index].value) {
      return false;
    }
  }
  return true;
}
