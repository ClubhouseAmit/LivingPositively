import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';

import '../form/shareform_test.mocks.dart';

List<List<String>> _toPairs(List<MapEntry<String, String>> entries) =>
    entries.map((e) => [e.key, e.value]).toList();

void main() {
  setUp(() async {
    await GetIt.instance.reset();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('custom_categories_storage', () {
    test('sanitizeAndFilterCustomCategoryEntries and sanitizeAndFilterCustomCategories trim and remove empty entries', () {
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
    });

    test('resolvePersistentMemoryService respects precedence', () async {
      final explicit = MockPersistentMemoryService();
      final userMemory = MockPersistentMemoryService();
      final getItMemory = MockPersistentMemoryService();

      final user = UserInformation(service: userMemory);
      GetIt.instance.registerSingleton<PersistentMemoryService>(getItMemory);

      // 1. Explicit takes highest priority
      expect(
        resolvePersistentMemoryService(
          explicitService: explicit,
          userInformation: user,
        ),
        same(explicit),
      );

      // 2. UserInformation takes next priority
      expect(
        resolvePersistentMemoryService(userInformation: user),
        same(userMemory),
      );

      // 3. GetIt fallback
      expect(
        resolvePersistentMemoryService(),
        same(getItMemory),
      );

      // 4. Null when none available
      await GetIt.instance.reset();
      expect(
        resolvePersistentMemoryService(),
        isNull,
      );
    });

    test('loadCustomCategoriesFromStorage returns sanitized categories', () async {
      final mock = MockPersistentMemoryService();
      when(mock.getItem('customCategoryTitles', PersistentMemoryType.StringList))
          .thenAnswer((_) async => ['Cat 1', '   ', 'Cat 2']);
      when(mock.getItem('customCategoryDescriptions', PersistentMemoryType.StringList))
          .thenAnswer((_) async => ['Desc 1', 'Desc 2', '   ']);

      final result = await loadCustomCategoriesFromStorage(memoryService: mock);
      expect(_toPairs(result), [
        ['Cat 1', 'Desc 1'],
      ]);
    });

    test('saveCustomCategoriesToStorage saves sanitized lists or throws on null', () async {
      final mock = MockPersistentMemoryService();
      when(mock.setItem(any, any, any)).thenAnswer((_) async => true);

      await saveCustomCategoriesToStorage(
        [
          const MapEntry('Title 1', 'Desc 1'),
          const MapEntry('', 'Empty Title'),
        ],
        memoryService: mock,
      );

      verify(mock.setItem('customCategoryTitles', PersistentMemoryType.StringList, ['Title 1'])).called(1);
      verify(mock.setItem('customCategoryDescriptions', PersistentMemoryType.StringList, ['Desc 1'])).called(1);

      expect(
        () => saveCustomCategoriesToStorage([const MapEntry('A', 'B')], memoryService: null),
        throwsA(isA<StateError>()),
      );
    });

    test('UserInformation loadCustomCategories and saveCustomCategories', () async {
      final mock = MockPersistentMemoryService();
      when(mock.getItem('customCategoryTitles', PersistentMemoryType.StringList))
          .thenAnswer((_) async => ['Saved Title']);
      when(mock.getItem('customCategoryDescriptions', PersistentMemoryType.StringList))
          .thenAnswer((_) async => ['Saved Desc']);
      when(mock.setItem(any, any, any)).thenAnswer((_) async => true);

      final user = UserInformation(service: mock);
      await user.loadCustomCategories();
      expect(_toPairs(user.customCategories), [
        ['Saved Title', 'Saved Desc'],
      ]);

      user.customCategories = [
        const MapEntry('New Title', 'New Desc'),
      ];
      await user.saveCustomCategories();

      verify(mock.setItem('customCategoryTitles', PersistentMemoryType.StringList, ['New Title'])).called(1);
      verify(mock.setItem('customCategoryDescriptions', PersistentMemoryType.StringList, ['New Desc'])).called(1);
    });
  });
}
