import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/notification_preference.dart';
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
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
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
      expect(u.notificationPreferences, isEmpty);
      expect(u.darkModePreference, DarkModePreference.alwaysLight);
      expect(u.darkModeStartHour, 22);
      expect(u.darkModeStartMinute, 0);
      expect(u.darkModeEndHour, 6);
      expect(u.darkModeEndMinute, 0);
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
        notificationPreferences: const {
          'default': NotificationPreference(hour: 9, minute: 30),
        },
        darkModePreference: DarkModePreference.alwaysDark,
        darkModeStartHour: 20,
        darkModeStartMinute: 15,
        darkModeEndHour: 7,
        darkModeEndMinute: 45,
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
      expect(u.notificationPreferences, isEmpty);
      expect(u.darkModePreference, DarkModePreference.alwaysLight);
      expect(u.darkModeStartHour, 22);
      expect(u.darkModeStartMinute, 0);
      expect(u.darkModeEndHour, 6);
      expect(u.darkModeEndMinute, 0);
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

    test('setNotificationPreference persists the FCM schedule', () async {
      final u = buildUser();
      u.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 45),
      );
      await Future<void>.delayed(Duration.zero);
      expect(u.getNotificationPreference('default')?.hour, 8);
      expect(
        fakeService.stored['notificationPreferences'],
        '{"default":{"hour":8,"minute":45}}',
      );
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

  group('dark mode settings', () {
    test('persists the selected preference and complete schedule', () async {
      final u = buildUser();
      var notified = 0;
      u.addListener(() => notified++);

      await u.updateDarkModeSettings(
        preference: DarkModePreference.scheduled,
        startHour: 21,
        startMinute: 30,
        endHour: 6,
        endMinute: 15,
      );

      expect(u.darkModePreference, DarkModePreference.scheduled);
      expect(u.darkModeStartHour, 21);
      expect(u.darkModeStartMinute, 30);
      expect(u.darkModeEndHour, 6);
      expect(u.darkModeEndMinute, 15);
      expect(notified, 1);
      expect(fakeService.stored['darkModePreference'], 'scheduled');
      expect(fakeService.stored['darkModeStartHour'], 21);
      expect(fakeService.stored['darkModeStartMinute'], 30);
      expect(fakeService.stored['darkModeEndHour'], 6);
      expect(fakeService.stored['darkModeEndMinute'], 15);
    });

    test('uses device-local time for an overnight schedule', () {
      final u = buildUser()
        ..restoreDarkModeSettings(
          preference: DarkModePreference.scheduled,
          startHour: 22,
          startMinute: 0,
          endHour: 6,
          endMinute: 0,
        );

      expect(u.usesDarkModeAt(DateTime(2026, 7, 27, 21, 59)), isFalse);
      expect(u.usesDarkModeAt(DateTime(2026, 7, 27, 22)), isTrue);
      expect(u.usesDarkModeAt(DateTime(2026, 7, 28, 5, 59)), isTrue);
      expect(u.usesDarkModeAt(DateTime(2026, 7, 28, 6)), isFalse);
    });

    test('supports schedules that do not cross midnight', () {
      final u = buildUser()
        ..restoreDarkModeSettings(
          preference: DarkModePreference.scheduled,
          startHour: 8,
          startMinute: 0,
          endHour: 20,
          endMinute: 0,
        );

      expect(u.usesDarkModeAt(DateTime(2026, 7, 27, 7, 59)), isFalse);
      expect(u.usesDarkModeAt(DateTime(2026, 7, 27, 8)), isTrue);
      expect(u.usesDarkModeAt(DateTime(2026, 7, 27, 19, 59)), isTrue);
      expect(u.usesDarkModeAt(DateTime(2026, 7, 27, 20)), isFalse);
    });

    test('always-light and always-dark preferences override the schedule', () {
      final u = buildUser();

      u.restoreDarkModeSettings(
        preference: DarkModePreference.alwaysLight,
        startHour: 0,
        endHour: 0,
      );
      expect(u.usesDarkModeAt(DateTime(2026, 7, 27, 23)), isFalse);

      u.restoreDarkModeSettings(
        preference: DarkModePreference.alwaysDark,
        startHour: 0,
        endHour: 0,
      );
      expect(u.usesDarkModeAt(DateTime(2026, 7, 27, 12)), isTrue);
    });

    test('returns the next start or end boundary for scheduled mode', () {
      final u = buildUser()
        ..restoreDarkModeSettings(
          preference: DarkModePreference.scheduled,
          startHour: 22,
          endHour: 6,
        );

      expect(
        u.nextDarkModeBoundaryAfter(DateTime(2026, 7, 27, 21, 59)),
        DateTime(2026, 7, 27, 22),
      );
      expect(
        u.nextDarkModeBoundaryAfter(DateTime(2026, 7, 27, 22)),
        DateTime(2026, 7, 28, 6),
      );
    });

    test('restores safe defaults for invalid persisted schedule values', () {
      final u = buildUser()
        ..restoreDarkModeSettings(
          preference: DarkModePreference.scheduled,
          startHour: 25,
          startMinute: -1,
          endHour: 24,
          endMinute: 60,
        );

      expect(u.darkModeStartHour, 22);
      expect(u.darkModeStartMinute, 0);
      expect(u.darkModeEndHour, 6);
      expect(u.darkModeEndMinute, 0);
    });
  });
}
