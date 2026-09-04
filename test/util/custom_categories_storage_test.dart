import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

List<List<String>> _toPairs(List<MapEntry<String, String>> entries) =>
    entries.map((e) => [e.key, e.value]).toList();

final class _WriteRecord {
  final String key;
  final PersistentMemoryType type;
  final dynamic value;

  const _WriteRecord(this.key, this.type, this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _WriteRecord) return false;
    if (key != other.key || type != other.type) return false;
    if (value is List && other.value is List) {
      final a = value as List;
      final b = other.value as List;
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return value == other.value;
  }

  @override
  int get hashCode => Object.hash(key, type, value);

  @override
  String toString() => '_WriteRecord($key, $type, $value)';
}

final class _FakeMemoryService implements PersistentMemoryService {
  final Map<String, dynamic> store;
  final List<_WriteRecord> writes = [];
  final Set<String>? allowedKeys;

  _FakeMemoryService({Map<String, dynamic>? initialStore, this.allowedKeys})
    : store = initialStore != null ? Map.from(initialStore) : {};

  @override
  Future<Map<String, Object?>> readSnapshot(
    Map<String, PersistentMemoryType> keys,
  ) => throw StateError('Unexpected export snapshot read in this test.');

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    return store[key];
  }

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (allowedKeys != null && !allowedKeys!.contains(key)) {
      throw StateError('Unexpected memory write for key: $key');
    }
    writes.add(_WriteRecord(key, type, value));
    store[key] = value;
  }

  @override
  Future<void> reset() async {
    store.clear();
  }
}

void main() {
  setUp(() async {
    await GetIt.instance.reset();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('custom_categories_storage', () {
    test(
      'sanitizeAndFilterCustomCategoryEntries and sanitizeAndFilterCustomCategories trim and remove empty entries',
      () {
        final input = [
          const MapEntry('  Title 1  ', '  Desc 1  '),
          const MapEntry('', 'Desc 2'),
          const MapEntry('Title 3', '   '),
          const MapEntry('Title 4', 'Desc 4'),
        ];

        final sanitizedEntries = sanitizeAndFilterCustomCategoryEntries(input);
        expect(_toPairs(sanitizedEntries), [
          ['Title 1', 'Desc 1'],
          ['Title 4', 'Desc 4'],
        ]);

        final sanitizedPairs = sanitizeAndFilterCustomCategories(
          ['  Title A  ', '', 'Title C'],
          ['  Desc A  ', 'Desc B', '   '],
        );
        expect(_toPairs(sanitizedPairs), [
          ['Title A', 'Desc A'],
        ]);
      },
    );

    test(
      'loadCustomCategoriesFromStorage reads atomic JSON snapshot first',
      () async {
        final fake = _FakeMemoryService(
          initialStore: {
            customCategoriesKey: jsonEncode([
              {'title': 'Atomic Title', 'description': 'Atomic Desc'},
            ]),
            customCategoryTitlesKey: ['Legacy Title'],
            customCategoryDescriptionsKey: ['Legacy Desc'],
          },
        );

        final result = await loadCustomCategoriesFromStorage(
          memoryService: fake,
        );
        expect(_toPairs(result), [
          ['Atomic Title', 'Atomic Desc'],
        ]);
      },
    );

    test(
      'loadCustomCategoriesFromStorage falls back to legacy separate keys',
      () async {
        final fake = _FakeMemoryService(
          initialStore: {
            customCategoryTitlesKey: ['Legacy Title 1', '  ', 'Legacy Title 2'],
            customCategoryDescriptionsKey: ['Legacy Desc 1', 'Desc 2', '  '],
          },
        );

        final result = await loadCustomCategoriesFromStorage(
          memoryService: fake,
        );
        expect(_toPairs(result), [
          ['Legacy Title 1', 'Legacy Desc 1'],
        ]);
      },
    );

    test(
      'saveCustomCategoriesToStorage saves atomic JSON snapshot and legacy lists with strict assertions',
      () async {
        final fake = _FakeMemoryService(
          allowedKeys: {
            customCategoriesKey,
            customCategoryTitlesKey,
            customCategoryDescriptionsKey,
          },
        );

        await saveCustomCategoriesToStorage([
          const MapEntry('  Title 1  ', '  Desc 1  '),
          const MapEntry('', 'Empty Title'),
          const MapEntry('Title 2', 'Desc 2'),
        ], memoryService: fake);

        expect(
          fake.writes,
          containsAll([
            _WriteRecord(
              customCategoriesKey,
              PersistentMemoryType.String,
              jsonEncode([
                {'title': 'Title 1', 'description': 'Desc 1'},
                {'title': 'Title 2', 'description': 'Desc 2'},
              ]),
            ),
            const _WriteRecord(
              customCategoryTitlesKey,
              PersistentMemoryType.StringList,
              ['Title 1', 'Title 2'],
            ),
            const _WriteRecord(
              customCategoryDescriptionsKey,
              PersistentMemoryType.StringList,
              ['Desc 1', 'Desc 2'],
            ),
          ]),
        );

        expect(
          () => saveCustomCategoriesToStorage([
            const MapEntry('A', 'B'),
          ], memoryService: null),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'UserInformation loadCustomCategories and saveCustomCategories',
      () async {
        final fake = _FakeMemoryService(
          initialStore: {
            customCategoryTitlesKey: ['Saved Title'],
            customCategoryDescriptionsKey: ['Saved Desc'],
          },
          allowedKeys: {
            customCategoriesKey,
            customCategoryTitlesKey,
            customCategoryDescriptionsKey,
          },
        );

        final user = UserInformation(service: fake);
        final loaded = await user.loadCustomCategories();
        expect(_toPairs(loaded), [
          ['Saved Title', 'Saved Desc'],
        ]);
        expect(_toPairs(user.customCategories), [
          ['Saved Title', 'Saved Desc'],
        ]);

        user.customCategories = [
          const MapEntry('  New Title  ', '  New Desc  '),
          const MapEntry('', 'Invalid'),
        ];
        await user.saveCustomCategories();

        expect(_toPairs(user.customCategories), [
          ['New Title', 'New Desc'],
        ]);

        expect(
          fake.writes,
          containsAll([
            _WriteRecord(
              customCategoriesKey,
              PersistentMemoryType.String,
              jsonEncode([
                {'title': 'New Title', 'description': 'New Desc'},
              ]),
            ),
            const _WriteRecord(
              customCategoryTitlesKey,
              PersistentMemoryType.StringList,
              ['New Title'],
            ),
            const _WriteRecord(
              customCategoryDescriptionsKey,
              PersistentMemoryType.StringList,
              ['New Desc'],
            ),
          ]),
        );
      },
    );

    test(
      'UserInformation.reset clears memory and persists empty custom categories',
      () async {
        final fake = _FakeMemoryService(
          initialStore: {
            customCategoryTitlesKey: ['Old Title'],
            customCategoryDescriptionsKey: ['Old Desc'],
          },
        );

        final user = UserInformation(service: fake);
        user.customCategories = [const MapEntry('Title', 'Desc')];

        await user.reset('en');

        expect(user.customCategories, isEmpty);
        expect(
          await fake.getItem(
            customCategoryTitlesKey,
            PersistentMemoryType.StringList,
          ),
          isEmpty,
        );
        expect(
          await fake.getItem(
            customCategoryDescriptionsKey,
            PersistentMemoryType.StringList,
          ),
          isEmpty,
        );
      },
    );
  });
}
