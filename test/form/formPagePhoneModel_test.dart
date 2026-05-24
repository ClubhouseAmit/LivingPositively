import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopLogger implements IncidentLoggerService {
  @override
  Future<void> initializeSentry(_) async {}
  @override
  Future<void> captureLog(dynamic _,
      {StackTrace? stackTrace, dynamic exceptionData}) async {}
}

PhonePageData _make({String key = 'TestPhones'}) => PhonePageData(
      key: key,
      phoneNames: ['Mom', 'Dad'],
      phoneNumbers: ['111', '222'],
      header: 'h',
      subTitle: 's',
      midTitle: 'm',
      phoneNameTitle: 'name',
      phoneNumberTitle: 'number',
      savedPhoneNames: <String>[],
      savedPhoneNumbers: <String>[],
      phoneDescription: <String>[],
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
      GetIt.instance.unregister<IncidentLoggerService>();
    }
    if (GetIt.instance.isRegistered<PersistentMemoryService>()) {
      GetIt.instance.unregister<PersistentMemoryService>();
    }
    GetIt.instance.registerSingleton<IncidentLoggerService>(_NoopLogger());
    GetIt.instance
        .registerSingleton<PersistentMemoryService>(SharedPreferencesService());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('PhonePageData CRUD', () {
    test('addItem appends to saved lists', () async {
      final p = _make();
      await Future<void>.delayed(Duration.zero);
      p.addItem('Sis', '333');
      expect(p.savedPhoneNames, contains('Sis'));
      expect(p.savedPhoneNumbers, contains('333'));
    });

    test('removeItemAt removes by index', () async {
      final p = _make();
      p.addItem('A', '1');
      p.addItem('B', '2');
      p.removeItemAt(0);
      expect(p.savedPhoneNames, ['B']);
      expect(p.savedPhoneNumbers, ['2']);
    });

    test('removeItemAt is a no-op for out-of-range index', () {
      final p = _make();
      p.addItem('A', '1');
      p.removeItemAt(99);
      expect(p.savedPhoneNames, ['A']);
    });

    test('removeItem removes by value (both lists)', () {
      final p = _make();
      p.addItem('A', '1');
      p.addItem('B', '2');
      p.removeItem('A', '1');
      expect(p.savedPhoneNames, ['B']);
    });

    test('replaceItem swaps in-place', () {
      final p = _make();
      p.addItem('A', '1');
      p.replaceItem(0, 'A2', '11');
      expect(p.savedPhoneNames, ['A2']);
      expect(p.savedPhoneNumbers, ['11']);
    });

    test('replaceItem is a no-op for out-of-range index', () {
      final p = _make();
      p.addItem('A', '1');
      p.replaceItem(5, 'X', 'Y');
      expect(p.savedPhoneNames, ['A']);
    });

    test('reset clears saved lists', () {
      final p = _make();
      p.addItem('A', '1');
      p.reset();
      expect(p.savedPhoneNames, isEmpty);
      expect(p.savedPhoneNumbers, isEmpty);
    });

    test('update() notifies listeners', () {
      final p = _make();
      var notifications = 0;
      p.addListener(() => notifications++);
      p.update();
      expect(notifications, greaterThan(0));
    });
  });

  group('PhonePageData JSON', () {
    test('toJson includes all fields', () {
      final p = _make();
      final json = p.toJson();
      expect(json['key'], 'TestPhones');
      expect(json['header'], 'h');
      expect(json['phoneNames'], ['Mom', 'Dad']);
      expect(json['savedPhoneNames'], <String>[]);
    });

    test('fromJson roundtrips', () {
      final original = _make(key: 'rt');
      original.addItem('Saved', '999');
      final json = original.toJson();
      final restored = PhonePageData.fromJson(json);
      expect(restored.key, 'rt');
      expect(restored.savedPhoneNames, ['Saved']);
      expect(restored.savedPhoneNumbers, ['999']);
    });

    test('updateFromJson updates fields and falls back to existing', () {
      final p = _make();
      p.updateFromJson({
        'header': 'NEW HEADER',
        'phoneNames': ['only'],
        // Other keys missing -> existing values retained
      });
      expect(p.header, 'NEW HEADER');
      expect(p.phoneNames, ['only']);
      expect(p.subTitle, 's'); // unchanged
    });

    test('updateFromJson with all-null preserves state', () {
      final p = _make();
      p.updateFromJson(<String, dynamic>{});
      expect(p.header, 'h');
      expect(p.phoneNames, ['Mom', 'Dad']);
    });
  });

  group('PhonePageData persistence', () {
    test('addItem then loadItemsFromPrefs returns saved values', () async {
      final p = _make(key: 'persistKey');
      p.addItem('A', '1');
      // Allow saveItemsToPrefs futures to settle
      await Future<void>.delayed(Duration.zero);
      // Build a fresh instance and force load
      final p2 = PhonePageData(
        key: 'persistKey',
        phoneNames: <String>[],
        phoneNumbers: <String>[],
        header: '',
        subTitle: '',
        midTitle: '',
        phoneNameTitle: '',
        phoneNumberTitle: '',
        savedPhoneNames: <String>[],
        savedPhoneNumbers: <String>[],
        phoneDescription: <String>[],
      );
      await p2.loadItemsFromPrefs();
      expect(p2.savedPhoneNames, ['A']);
      expect(p2.savedPhoneNumbers, ['1']);
    });
  });
}
