import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

class _MemoryService implements PersistentMemoryService {
  final Map<String, dynamic> values;

  _MemoryService(this.values);

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (values.containsKey(key)) {
      return values[key];
    }
    if (type == PersistentMemoryType.StringList) {
      return <String>[];
    }
    if (type == PersistentMemoryType.String) {
      return '';
    }
    if (type == PersistentMemoryType.Bool) {
      return false;
    }
    return null;
  }

  @override
  Future<void> reset() async {
    values.clear();
  }

  @override
  Future<void> setItem(
      String key, PersistentMemoryType type, dynamic value) async {
    values[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('organizeDataForFile appends custom categories with original text',
      () async {
    getIt.registerLazySingleton<PersistentMemoryService>(
      () => _MemoryService({
        'userSelectionPersonalPlan-DifficultEvents': <String>[],
        'userSelectionPersonalPlan-MakeSafer': <String>['standard answer'],
        'userSelectionPersonalPlan-FeelBetter': <String>[],
        'userSelectionPersonalPlan-Distractions': <String>[],
        'userSelectionPersonalPlan-SafeEnvironment': <String>[
          'safe environment answer',
        ],
        'PhonePageSavedPhoneNames': <String>[],
        'PhonePageSavedPhoneNumbers': <String>[],
        'name': '',
        'customCategoryTitles': <String>[
          'כותרת מקורית שלי',
          'Second free title',
        ],
        'customCategoryDescriptions': <String>[
          'טקסט חופשי בעברית שלא מתורגם',
          'English text remains English',
        ],
      }),
    );

    final result = await FileServiceImpl().organizeDataForFile(
      [
        'symptoms title',
        'triggers title',
        'wellness title',
        'environmental support title',
        'phones title',
        'safe environment title',
      ],
      [
        'symptoms subtitle',
        'triggers subtitle',
        'wellness subtitle',
        'environmental support subtitle',
        'phones subtitle',
        'safe environment subtitle',
      ],
      const {},
      'My Personal Plan',
    );

    expect(result['titles'], [
      'environmental support title',
      'safe environment title',
      'כותרת מקורית שלי',
      'Second free title',
    ]);
    expect(result['subTitles'], [
      'environmental support subtitle',
      'safe environment subtitle',
      '',
      '',
    ]);
    expect(result['realData'], [
      ['standard answer'],
      ['safe environment answer'],
      ['טקסט חופשי בעברית שלא מתורגם'],
      ['English text remains English'],
    ]);
  });

  test('organizeDataForFile supports a custom-only plan', () async {
    getIt.registerLazySingleton<PersistentMemoryService>(
      () => _MemoryService({
        'customCategoryTitles': <String>['Only custom title'],
        'customCategoryDescriptions': <String>['Only custom notes'],
      }),
    );

    final result = await FileServiceImpl().organizeDataForFile(
      [
        'symptoms',
        'triggers',
        'wellness',
        'environmental support',
        'phones',
        'safe environment',
      ],
      [
        'symptoms sub',
        'triggers sub',
        'wellness sub',
        'environmental support sub',
        'phones sub',
        'safe environment sub',
      ],
      const {},
      'My Personal Plan',
    );

    expect(result['titles'], ['Only custom title']);
    expect(result['subTitles'], ['']);
    expect(result['realData'], [
      ['Only custom notes'],
    ]);
  });

  test('organizeDataForFile ignores incomplete custom category rows', () async {
    getIt.registerLazySingleton<PersistentMemoryService>(
      () => _MemoryService({
        'userSelectionPersonalPlan-FeelBetter': <String>['standard item'],
        'customCategoryTitles': <String>[
          'Valid custom title',
          '',
          'Title without description',
          'Another valid title',
        ],
        'customCategoryDescriptions': <String>[
          'Valid custom notes',
          'Description without title',
          '',
          'Another valid note',
        ],
      }),
    );

    final result = await FileServiceImpl().organizeDataForFile(
      [
        'symptoms',
        'triggers',
        'wellness',
        'environmental support',
        'phones',
        'safe environment',
      ],
      [
        'symptoms sub',
        'triggers sub',
        'wellness sub',
        'environmental support sub',
        'phones sub',
        'safe environment sub',
      ],
      const {},
      'My Personal Plan',
    );

    expect(result['titles'], [
      'wellness',
      'Valid custom title',
      'Another valid title',
    ]);
    expect(result['subTitles'], [
      'wellness sub',
      '',
      '',
    ]);
    expect(result['realData'], [
      ['standard item'],
      ['Valid custom notes'],
      ['Another valid note'],
    ]);
  });

  test('organizeDataForFile handles missing custom category keys', () async {
    getIt.registerLazySingleton<PersistentMemoryService>(
      () => _MemoryService({
        'PhonePageSavedPhoneNames': <String>['Friend'],
        'PhonePageSavedPhoneNumbers': <String>['0501234567'],
      }),
    );

    final result = await FileServiceImpl().organizeDataForFile(
      [
        'symptoms',
        'triggers',
        'wellness',
        'environmental support',
        'phones',
        'safe environment',
      ],
      [
        'symptoms sub',
        'triggers sub',
        'wellness sub',
        'environmental support sub',
        'phones sub',
        'safe environment sub',
      ],
      const {},
      'My Personal Plan',
    );

    expect(result['titles'], ['phones']);
    expect(result['subTitles'], ['phones sub']);
    expect(result['realData'], [
      ['Friend:0501234567'],
    ]);
  });
}
