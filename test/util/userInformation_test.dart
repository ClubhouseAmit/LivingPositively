import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

class _FakePersistentMemoryService implements PersistentMemoryService {
  final Map<String, dynamic> stored = {};
  final List<MapEntry<String, dynamic>> writes = [];

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
      String key, PersistentMemoryType type, dynamic value) async {
    stored[key] = value;
    writes.add(MapEntry(key, value));
  }
}

void main() {
  late _FakePersistentMemoryService fakeService;

  setUp(() {
    fakeService = _FakePersistentMemoryService();
  });

  UserInformation buildUser() => UserInformation(service: fakeService);

  group('UserInformation default constructor', () {
    test('initializes with sensible defaults', () {
      final u = buildUser();
      expect(u.name, '');
      expect(u.gender, '');
      expect(u.binary, isFalse);
      expect(u.notificationHour, 12);
      expect(u.notificationMinute, 0);
      expect(u.disclaimerSigned, isFalse);
      expect(u.loggedIn, isFalse);
      expect(u.userId, '');
      expect(u.difficultEvents, isEmpty);
      expect(u.makeSafer, isEmpty);
      expect(u.feelBetter, isEmpty);
      expect(u.distractions, isEmpty);
      expect(u.positiveTraits, isEmpty);
      expect(u.thanks, isEmpty);
    });
  });

  group('UserInformation.reset', () {
    test('clears all mutable fields and applies provided locale', () {
      final u = UserInformation(
        service: fakeService,
        gender: 'male',
        name: 'Alice',
        age: '30',
        binary: true,
        location: 'IL',
        notificationHour: 9,
        notificationMinute: 30,
        difficultEvents: const ['a'],
        makeSafer: const ['b'],
        feelBetter: const ['c'],
        distractions: const ['d'],
        positiveTraits: const ['kind'],
        disclaimerSigned: true,
        loggedIn: true,
        userId: 'uid-1',
        thanks: const {
          'thanks': ['t1'],
          'dates': ['2024-01-01'],
        },
      );

      var notified = 0;
      u.addListener(() => notified++);

      u.reset('he');

      expect(u.localeName, 'he');
      expect(u.location, '');
      expect(u.gender, '');
      expect(u.name, '');
      expect(u.age, '');
      expect(u.binary, isFalse);
      expect(u.notificationHour, 12);
      expect(u.notificationMinute, 0);
      expect(u.disclaimerSigned, isFalse);
      expect(u.loggedIn, isFalse);
      expect(u.userId, '');
      expect(u.difficultEvents, isEmpty);
      expect(u.makeSafer, isEmpty);
      expect(u.feelBetter, isEmpty);
      expect(u.distractions, isEmpty);
      expect(u.thanks, isEmpty);
      expect(u.positiveTraits, isEmpty);
      expect(notified, 1);
    });
  });

  group('update methods that persist', () {
    test('updateGender notifies and persists', () async {
      final u = buildUser();
      var notified = 0;
      u.addListener(() => notified++);

      u.updateGender('female');
      // Allow inner microtask to flush
      await Future<void>.delayed(Duration.zero);

      expect(u.gender, 'female');
      expect(notified, 1);
      expect(fakeService.stored['gender'], 'female');
    });

    test('updateName persists and notifies', () async {
      final u = buildUser();
      u.updateName('Bob');
      await Future<void>.delayed(Duration.zero);
      expect(u.name, 'Bob');
      expect(fakeService.stored['name'], 'Bob');
    });

    test('updateAge persists', () async {
      final u = buildUser();
      u.updateAge('25');
      await Future<void>.delayed(Duration.zero);
      expect(u.age, '25');
      expect(fakeService.stored['age'], '25');
    });

    test('updateBinary persists Bool', () async {
      final u = buildUser();
      u.updateBinary(true);
      await Future<void>.delayed(Duration.zero);
      expect(u.binary, isTrue);
      expect(fakeService.stored['binary'], isTrue);
    });

    test('updateNotificationHour persists Int', () async {
      final u = buildUser();
      u.updateNotificationHour(8);
      await Future<void>.delayed(Duration.zero);
      expect(u.notificationHour, 8);
      expect(fakeService.stored['notificationHour'], 8);
    });

    test('updateNotificationMinute persists Int', () async {
      final u = buildUser();
      u.updateNotificationMinute(45);
      await Future<void>.delayed(Duration.zero);
      expect(u.notificationMinute, 45);
      expect(fakeService.stored['notificationMinute'], 45);
    });

    test('updatePositiveTraits stores StringList copy', () async {
      final u = buildUser();
      final input = ['kind', 'curious'];
      u.updatePositiveTraits(input);
      await Future<void>.delayed(Duration.zero);
      expect(u.positiveTraits, ['kind', 'curious']);
      // Ensure copy: mutating input must not change stored value.
      input.add('extra');
      expect(u.positiveTraits, ['kind', 'curious']);
      expect(fakeService.stored['positiveTraits'], isA<List<String>>());
    });

    test('updateThanks persists thanks and dates lists', () async {
      final u = buildUser();
      u.updateThanks({
        'thanks': ['t1', 't2'],
        'dates': ['d1', 'd2'],
      });
      await Future<void>.delayed(Duration.zero);
      expect(u.thanks['thanks'], ['t1', 't2']);
      expect(u.thanks['dates'], ['d1', 'd2']);
      expect(fakeService.stored['thankYous'], ['t1', 't2']);
      expect(fakeService.stored['dates'], ['d1', 'd2']);
    });

    test('updateThanks with missing keys defaults to empty lists', () async {
      final u = buildUser();
      u.updateThanks(<String, List<String>>{});
      await Future<void>.delayed(Duration.zero);
      expect(u.thanks['thanks'], <String>[]);
      expect(u.thanks['dates'], <String>[]);
    });
  });

  group('update methods that only notify', () {
    test('updateDifficultEvents', () {
      final u = buildUser();
      var notified = 0;
      u.addListener(() => notified++);
      u.updateDifficultEvents(['x']);
      expect(u.difficultEvents, ['x']);
      expect(notified, 1);
    });

    test('updateMakeSafer', () {
      final u = buildUser();
      u.updateMakeSafer(['y']);
      expect(u.makeSafer, ['y']);
    });

    test('updateFeelBetter', () {
      final u = buildUser();
      u.updateFeelBetter(['z']);
      expect(u.feelBetter, ['z']);
    });

    test('updateDistractions', () {
      final u = buildUser();
      u.updateDistractions(['d']);
      expect(u.distractions, ['d']);
    });

    test('updateDisclaimerSigned', () {
      final u = buildUser();
      u.updateDisclaimerSigned(true);
      expect(u.disclaimerSigned, isTrue);
    });

    test('updateLoggedIn', () {
      final u = buildUser();
      u.updateLoggedIn(true);
      expect(u.loggedIn, isTrue);
    });

    test('updateUserId', () {
      final u = buildUser();
      u.updateUserId('uid-7');
      expect(u.userId, 'uid-7');
    });

    test('updateLocaleName', () {
      final u = buildUser();
      u.updateLocaleName('en');
      expect(u.localeName, 'en');
    });

    test('updateLocation', () {
      final u = buildUser();
      u.updateLocation('US');
      expect(u.location, 'US');
    });
  });
}
