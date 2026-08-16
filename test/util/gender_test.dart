import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/l10n/app_localizations_en.dart';
import 'package:mazilon/util/gender.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

class _FakePersistentMemoryService implements PersistentMemoryService {
  final Map<String, dynamic> stored = {};

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    return stored[key];
  }

  @override
  Future<void> reset() async {
    stored.clear();
  }

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    stored[key] = value;
  }
}

void main() {
  final AppLocalizations locale = AppLocalizationsEn();

  UserInformation buildUser({String gender = '', bool binary = false}) =>
      UserInformation(
        gender: gender,
        binary: binary,
        service: _FakePersistentMemoryService(),
      );

  group('Gender.of', () {
    test('reads the two stored fields back into a choice', () {
      expect(Gender.of(buildUser(gender: 'male')), Gender.male);
      expect(Gender.of(buildUser(gender: 'female')), Gender.female);
      expect(Gender.of(buildUser(binary: true)), Gender.nonBinary);
      expect(Gender.of(buildUser()), Gender.unspecified);
    });

    test('lets binary win over a stale gender code', () {
      expect(
        Gender.of(buildUser(gender: 'male', binary: true)),
        Gender.nonBinary,
      );
    });
  });

  group('Gender.applyTo', () {
    test('round-trips every choice through the stored fields and persistent memory', () async {
      for (final gender in Gender.values) {
        final memory = _FakePersistentMemoryService();
        final user = UserInformation(
          gender: 'female', 
          binary: false, 
          service: memory,
        );
        await gender.applyTo(user);
        
        expect(Gender.of(user), gender);
        expect(memory.stored['gender'], gender.code);
        expect(memory.stored['binary'], gender == Gender.nonBinary);
      }
    });

    test('clears the gender code for the two non-binary-field choices', () async {
      final memory = _FakePersistentMemoryService();
      final user = UserInformation(
        gender: 'male', 
        binary: false, 
        service: memory,
      );

      await Gender.nonBinary.applyTo(user);
      expect(user.gender, '');
      expect(user.binary, isTrue);
      expect(memory.stored['gender'], '');
      expect(memory.stored['binary'], isTrue);

      await Gender.unspecified.applyTo(user);
      expect(user.gender, '');
      expect(user.binary, isFalse);
      expect(memory.stored['gender'], '');
      expect(memory.stored['binary'], isFalse);
    });
  });

  group('labels', () {
    test('lists the four choices in dropdown order', () {
      expect(Gender.labels(locale), [
        locale.male,
        locale.female,
        locale.nonBinary,
        locale.notWillingToSay,
      ]);
    });

    test('fromLabel is the inverse of label', () {
      for (final gender in Gender.values) {
        expect(Gender.fromLabel(gender.label(locale), locale), gender);
      }
    });

    test('fromLabel returns null for a label that is not a choice', () {
      expect(Gender.fromLabel('not a gender', locale), isNull);
    });
  });

  group('listKey', () {
    test('keeps male and female and folds the rest into other', () {
      expect(Gender.male.listKey, 'male');
      expect(Gender.female.listKey, 'female');
      expect(Gender.nonBinary.listKey, 'other');
      expect(Gender.unspecified.listKey, 'other');
    });

    test('fromCode maps stored codes, unknown ones included', () {
      expect(Gender.fromCode('male'), Gender.male);
      expect(Gender.fromCode('female'), Gender.female);
      expect(Gender.fromCode(''), Gender.unspecified);
      expect(Gender.fromCode('something else'), Gender.unspecified);
    });
  });
}
