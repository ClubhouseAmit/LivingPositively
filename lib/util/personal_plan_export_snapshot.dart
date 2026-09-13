import 'dart:convert';

import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';

/// An immutable, request-owned copy of every Personal Plan section.
///
/// This is an in-memory export value, not a new persisted data format. Capture
/// reads one explicit source and never stages model values into another store.
final class PersonalPlanExportSnapshot {
  PersonalPlanExportSnapshot._(Map<String, List<String>> values)
    : data = Map<String, List<String>>.unmodifiable({
        for (final entry in values.entries)
          entry.key: List<String>.unmodifiable(entry.value),
      });

  /// Frozen section data consumed directly by the PDF renderer.
  final Map<String, List<String>> data;

  /// Exact content identity for coalescing equivalent in-flight downloads.
  String get fingerprint => jsonEncode(data);

  static const _selectionKeys = {
    'DifficultEvents': 'userSelectionPersonalPlan-DifficultEvents',
    'MakeSafer': 'userSelectionPersonalPlan-MakeSafer',
    'FeelBetter': 'userSelectionPersonalPlan-FeelBetter',
    'Distractions': 'userSelectionPersonalPlan-Distractions',
    'SafeEnvironment': 'userSelectionPersonalPlan-SafeEnvironment',
    'DreamsAndGoals': 'userSelectionPersonalPlan-DreamsAndGoals',
    'phoneNames': 'PhonePageSavedPhoneNames',
    'phoneNumbers': 'PhonePageSavedPhoneNumbers',
  };

  /// Waits for accepted writes and captures all fields behind one read barrier.
  ///
  /// Read or prior-save failures propagate; no partial snapshot is returned.
  static Future<PersonalPlanExportSnapshot> capture(
    PersistentMemoryService source,
  ) async {
    final values = await source.readSnapshot({
      for (final key in _selectionKeys.values)
        key: PersistentMemoryType.StringList,
      customCategoriesKey: PersistentMemoryType.String,
      customCategoryTitlesKey: PersistentMemoryType.StringList,
      customCategoryDescriptionsKey: PersistentMemoryType.StringList,
      customCategoriesLegacyCommitKey: PersistentMemoryType.String,
    });
    final categories = parseCustomCategoriesSnapshot(values);
    final phoneNames = TypeUtils.castToStringList(
      values[_selectionKeys['phoneNames']],
    );
    final phoneNumbers = TypeUtils.castToStringList(
      values[_selectionKeys['phoneNumbers']],
    );
    final contactCount = phoneNames.length < phoneNumbers.length
        ? phoneNames.length
        : phoneNumbers.length;
    final snapshot = PersonalPlanExportSnapshot._({
      for (final entry in _selectionKeys.entries)
        if (entry.key != 'phoneNames' && entry.key != 'phoneNumbers')
          entry.key: TypeUtils.castToStringList(values[entry.value]),
      'phoneNames': phoneNames.take(contactCount).toList(),
      'phoneNumbers': phoneNumbers.take(contactCount).toList(),
      'customCategoryTitles': [for (final category in categories) category.key],
      'customCategoryDescriptions': [
        for (final category in categories) category.value,
      ],
    });
    return snapshot;
  }
}
