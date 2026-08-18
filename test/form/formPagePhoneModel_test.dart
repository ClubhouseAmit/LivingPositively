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
  Future<void> captureLog(
    dynamic _, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {}
}

class _ThrowingPersistentMemoryService implements PersistentMemoryService {
  int writeAttempts = 0;

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async =>
      <String>[];

  @override
  Future<void> reset() async {}

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    writeAttempts++;
    throw StateError('intentional contact persistence failure');
  }
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
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      SharedPreferencesService(),
    );
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

    test('addItem rejects empty names and non-dialable phone numbers', () {
      final p = _make();
      expect(p.addItem('', '333'), isFalse);
      expect(p.addItem('A', '1'), isFalse);
      expect(p.addItem('B', 'abc'), isFalse);
      expect(p.savedPhoneNames, isEmpty);
      expect(p.savedPhoneNumbers, isEmpty);
    });

    test('normalizes dialable phone numbers consistently', () {
      expect(
        PhonePageData.normalizeDialablePhoneNumber('+972 50 123 4567'),
        '+972501234567',
      );
      expect(
        PhonePageData.normalizeDialablePhoneNumber('0501234567'),
        '0501234567',
      );
      expect(
        PhonePageData.normalizeDialablePhoneNumber(
          '\u061C+972\u200E 50\u200F123\u202A-\u202B45\u202C67\u202D\u202E\u2066\u2067\u2068\u2069',
        ),
        '+972501234567',
      );
      expect(PhonePageData.normalizeDialablePhoneNumber('11'), '11');
      expect(PhonePageData.normalizeDialablePhoneNumber('*123#'), isNull);
      expect(PhonePageData.normalizeDialablePhoneNumber('1'), isNull);
    });

    test('canonicalizes phone numbers consistently', () {
      final cases = [
        (
          description: 'local number with a country dial code',
          value: '050 123 4567',
          dialCode: '+972',
          expected: '+972501234567',
        ),
        (
          description: 'minimum-length local number with a country dial code',
          value: '11',
          dialCode: '+1',
          expected: '+111',
        ),
        (
          description: 'below-minimum local number with a country dial code',
          value: '1',
          dialCode: '+1',
          expected: null,
        ),
        (
          description: 'maximum-length local number with a country dial code',
          value: '123456789012',
          dialCode: '+972',
          expected: '+972123456789012',
        ),
        (
          description:
              'local number exceeding the E.164 maximum with a country dial code',
          value: '1234567890123',
          dialCode: '+972',
          expected: null,
        ),
        (
          description: '00-prefixed international number without a dial code',
          value: '00972501234567',
          dialCode: null,
          expected: '+972501234567',
        ),
        (
          description: 'minimum-length 00-prefixed international number',
          value: '0012',
          dialCode: null,
          expected: '+12',
        ),
        (
          description: 'below-minimum 00-prefixed international number',
          value: '001',
          dialCode: null,
          expected: null,
        ),
        (
          description: 'maximum-length 00-prefixed international number',
          value: '00123456789012345',
          dialCode: null,
          expected: '+123456789012345',
        ),
        (
          description: '00-prefixed number exceeding the E.164 maximum',
          value: '001234567890123456',
          dialCode: null,
          expected: null,
        ),
        (
          description: 'explicit international number',
          value: '+1 (555) 123-4567',
          dialCode: '+972',
          expected: '+15551234567',
        ),
        (
          description: 'minimum-length E.164 number',
          value: '+12',
          dialCode: null,
          expected: '+12',
        ),
        (
          description: 'maximum-length E.164 number',
          value: '+123456789012345',
          dialCode: null,
          expected: '+123456789012345',
        ),
        (
          description: 'number longer than the E.164 maximum',
          value: '+1234567890123456',
          dialCode: null,
          expected: null,
        ),
        (
          description: 'malformed value',
          value: '*123#',
          dialCode: '+972',
          expected: null,
        ),
        (
          description: 'local number without a dial code',
          value: '0501234567',
          dialCode: null,
          expected: null,
        ),
        (
          description: 'invalid dial code',
          value: '501234567',
          dialCode: '+0',
          expected: null,
        ),
      ];

      for (final testCase in cases) {
        expect(
          PhonePageData.canonicalizePhoneNumber(
            testCase.value,
            testCase.dialCode,
          ),
          testCase.expected,
          reason: testCase.description,
        );
      }
    });

    test('addItem preserves unmatched legacy entries', () {
      final p = _make();
      p.savedPhoneNames = <String>['Paired', 'Name only'];
      p.savedPhoneNumbers = <String>['111'];

      expect(p.addItem('New contact', '222'), isFalse);
      expect(p.savedPhoneNames, ['Paired', 'Name only']);
      expect(p.savedPhoneNumbers, ['111']);
    });

    test(
      'saveItemsToPrefs preserves legacy non-dialable saved contacts',
      () async {
        final p = _make(key: 'legacyKey');
        await Future<void>.delayed(Duration.zero);
        p.savedPhoneNames = <String>['Legacy hotline'];
        p.savedPhoneNumbers = <String>['*123#'];

        expect(p.addItem('New contact', '111'), isTrue);
        await p.saveItemsToPrefs();

        expect(p.savedPhoneNames, ['Legacy hotline', 'New contact']);
        expect(p.savedPhoneNumbers, ['*123#', '111']);

        final p2 = PhonePageData(
          key: 'legacyKey',
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

        expect(p2.savedPhoneNames, ['Legacy hotline', 'New contact']);
        expect(p2.savedPhoneNumbers, ['*123#', '111']);
      },
    );

    test('removeItemAt removes by index', () async {
      final p = _make();
      p.addItem('A', '111');
      p.addItem('B', '222');
      p.removeItemAt(0);
      expect(p.savedPhoneNames, ['B']);
      expect(p.savedPhoneNumbers, ['222']);
    });

    test('removeItemAt is a no-op for out-of-range index', () {
      final p = _make();
      p.addItem('A', '111');
      p.removeItemAt(99);
      expect(p.savedPhoneNames, ['A']);
    });

    test('removeItem removes one exact pair when names or numbers repeat', () {
      final duplicateName = _make();
      duplicateName.addItem('Alex', '111');
      duplicateName.addItem('Blair', '222');
      duplicateName.addItem('Alex', '333');

      duplicateName.removeItem('Alex', '333');

      expect(duplicateName.savedPhoneNames, ['Alex', 'Blair']);
      expect(duplicateName.savedPhoneNumbers, ['111', '222']);

      final duplicateNumber = _make(key: 'DuplicateNumbers');
      duplicateNumber.addItem('Alex', '111');
      duplicateNumber.addItem('Blair', '222');
      duplicateNumber.addItem('Casey', '111');

      duplicateNumber.removeItem('Casey', '111');

      expect(duplicateNumber.savedPhoneNames, ['Alex', 'Blair']);
      expect(duplicateNumber.savedPhoneNumbers, ['111', '222']);
    });

    test('removeItem trims legacy values while preserving exact pairs', () {
      final p = _make();
      p.savedPhoneNames = <String>[' Alex ', 'Blair'];
      p.savedPhoneNumbers = <String>[' 111 ', '222'];

      p.removeItem('Alex', '111');

      expect(p.savedPhoneNames, ['Blair']);
      expect(p.savedPhoneNumbers, ['222']);
    });

    test('replaceItem swaps in-place', () {
      final p = _make();
      p.addItem('A', '111');
      p.replaceItem(0, 'A2', '11');
      expect(p.savedPhoneNames, ['A2']);
      expect(p.savedPhoneNumbers, ['11']);
    });

    test('replaceItem is a no-op for out-of-range index', () {
      final p = _make();
      p.addItem('A', '111');
      p.replaceItem(5, 'X', '999');
      expect(p.savedPhoneNames, ['A']);
    });

    test('replaceItem completes one explicit unmatched legacy contact', () {
      final missingNumber = _make();
      missingNumber.savedPhoneNames = <String>['Paired', 'Name only'];
      missingNumber.savedPhoneNumbers = <String>['111'];

      missingNumber.replaceItem(1, 'Name only', '222');

      expect(missingNumber.savedPhoneNames, ['Paired', 'Name only']);
      expect(missingNumber.savedPhoneNumbers, ['111', '222']);

      final missingName = _make(key: 'MissingName');
      missingName.savedPhoneNames = <String>['Paired'];
      missingName.savedPhoneNumbers = <String>['111', '222'];

      missingName.replaceItem(1, 'Number only', '222');

      expect(missingName.savedPhoneNames, ['Paired', 'Number only']);
      expect(missingName.savedPhoneNumbers, ['111', '222']);
    });

    test('reset clears saved lists', () {
      final p = _make();
      p.addItem('A', '111');
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
    test('should contain background contact persistence failures', () async {
      final failingMemory = _ThrowingPersistentMemoryService();
      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(failingMemory);

      final p = _make(key: 'failingPersistKey');
      await Future<void>.delayed(Duration.zero);
      expect(p.addItem('A', '111'), isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(failingMemory.writeAttempts, 1);
      expect(p.savedPhoneNames, <String>['A']);
      expect(p.savedPhoneNumbers, <String>['111']);
    });

    test('addItem then loadItemsFromPrefs returns saved values', () async {
      final p = _make(key: 'persistKey');
      p.addItem('A', '111');
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
      expect(p2.savedPhoneNumbers, ['111']);
    });
  });
}
