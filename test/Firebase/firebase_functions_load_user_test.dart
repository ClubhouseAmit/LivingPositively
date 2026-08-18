import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeLogger implements IncidentLoggerService {
  @override
  Future<void> initializeSentry(_) async {}
  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {}
}

/// A fake [PersistentMemoryService] backed by an in-memory map.
class _FakeMemory implements PersistentMemoryService {
  final Map<String, dynamic> _store;

  _FakeMemory(this._store);

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    return _store[key];
  }

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {}

  @override
  Future<void> reset() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _registerFakes({required Map<String, dynamic> store}) {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<IncidentLoggerService>()) {
    getIt.unregister<IncidentLoggerService>();
  }
  if (getIt.isRegistered<PersistentMemoryService>()) {
    getIt.unregister<PersistentMemoryService>();
  }
  getIt.registerSingleton<IncidentLoggerService>(_FakeLogger());
  getIt.registerSingleton<PersistentMemoryService>(_FakeMemory(store));
}

void _unregisterFakes() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<PersistentMemoryService>()) {
    getIt.unregister<PersistentMemoryService>();
  }
  if (getIt.isRegistered<IncidentLoggerService>()) {
    getIt.unregister<IncidentLoggerService>();
  }
}

UserInformation _makeUserInfo() {
  // Provide the PersistentMemoryService explicitly so the constructor
  // does not hit GetIt before it is set up in tests.
  return UserInformation(service: GetIt.instance<PersistentMemoryService>());
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(_unregisterFakes);

  group('loadUserInformation – populated values', () {
    test('propagates all scalar string/bool/int fields', () async {
      _registerFakes(
        store: {
          'name': 'Alice',
          'gender': 'female',
          'binary': false,
          'loggedIn': true,
          'age': '25',
          'userId': 'uid-123',
          'location': 'TLV',
          'disclaimerConfirmed': true,
          'notificationMinute': 30,
          'notificationHour': 9,
          'darkModePreference': 'scheduled',
          'darkModeStartHour': 21,
          'darkModeStartMinute': 30,
          'darkModeEndHour': 6,
          'darkModeEndMinute': 15,
          'localeName': 'he',
          'userSelectionPersonalPlan-DifficultEvents': ['event1'],
          'userSelectionPersonalPlan-MakeSafer': ['safer1'],
          'userSelectionPersonalPlan-FeelBetter': ['better1'],
          'userSelectionPersonalPlan-Distractions': ['dist1'],
          'userSelectionPersonalPlan-SafeEnvironment': ['safe1'],
          'userSelectionPersonalPlan-DreamsAndGoals': ['dream1'],
          'positiveTraits': ['brave'],
          'thankYous': ['thanks1'],
          'dates': ['2024-01-01'],
        },
      );

      final userInfo = _makeUserInfo();
      await loadUserInformation(userInfo, 'en');

      expect(userInfo.name, equals('Alice'));
      expect(userInfo.gender, equals('female'));
      expect(userInfo.binary, isFalse);
      expect(userInfo.loggedIn, isTrue);
      expect(userInfo.age, equals('25'));
      expect(userInfo.userId, equals('uid-123'));
      expect(userInfo.location, equals('TLV'));
      expect(userInfo.disclaimerSigned, isTrue);
      expect(userInfo.notificationMinute, equals(30));
      expect(userInfo.notificationHour, equals(9));
      expect(userInfo.darkModePreference, DarkModePreference.scheduled);
      expect(userInfo.darkModeStartHour, equals(21));
      expect(userInfo.darkModeStartMinute, equals(30));
      expect(userInfo.darkModeEndHour, equals(6));
      expect(userInfo.darkModeEndMinute, equals(15));
      expect(userInfo.localeName, equals('he'));
    });

    test('propagates list fields', () async {
      _registerFakes(
        store: {
          'name': '',
          'gender': '',
          'binary': false,
          'loggedIn': false,
          'age': '',
          'userId': '',
          'location': '',
          'disclaimerConfirmed': false,
          'notificationMinute': 0,
          'notificationHour': 12,
          'localeName': 'en',
          'userSelectionPersonalPlan-DifficultEvents': ['de1', 'de2'],
          'userSelectionPersonalPlan-MakeSafer': ['ms1'],
          'userSelectionPersonalPlan-FeelBetter': ['fb1'],
          'userSelectionPersonalPlan-Distractions': ['d1', 'd2'],
          'userSelectionPersonalPlan-SafeEnvironment': ['se1', 'se2'],
          'userSelectionPersonalPlan-DreamsAndGoals': ['dg1', 'dg2'],
          'positiveTraits': ['kind', 'bold'],
          'thankYous': ['t1', 't2'],
          'dates': ['2024-01-01', '2024-02-01'],
        },
      );

      final userInfo = _makeUserInfo();
      await loadUserInformation(userInfo, 'en');

      expect(userInfo.difficultEvents, equals(['de1', 'de2']));
      expect(userInfo.makeSafer, equals(['ms1']));
      expect(userInfo.feelBetter, equals(['fb1']));
      expect(userInfo.distractions, equals(['d1', 'd2']));
      expect(userInfo.safeEnvironment, equals(['se1', 'se2']));
      expect(userInfo.dreamsAndGoals, equals(['dg1', 'dg2']));
      expect(userInfo.positiveTraits, equals(['kind', 'bold']));
      expect(userInfo.thanks['thanks'], equals(['t1', 't2']));
      expect(userInfo.thanks['dates'], equals(['2024-01-01', '2024-02-01']));
    });
  });

  group('loadUserInformation – empty / null defaults', () {
    test(
      'uses the default schedule when saved values are absent or invalid',
      () async {
        _registerFakes(
          store: {
            'darkModePreference': 'scheduled',
            'darkModeStartHour': 'not-an-int',
          },
        );

        final userInfo = _makeUserInfo();
        await loadUserInformation(userInfo, 'en');

        expect(userInfo.darkModePreference, DarkModePreference.scheduled);
        expect(userInfo.darkModeStartHour, 22);
        expect(userInfo.darkModeStartMinute, 0);
        expect(userInfo.darkModeEndHour, 6);
        expect(userInfo.darkModeEndMinute, 0);
      },
    );

    test(
      'uses the default schedule with missing SharedPreferences Int values',
      () async {
        SharedPreferences.setMockInitialValues({
          'darkModePreference': 'scheduled',
        });
        GetIt.instance.registerSingleton<IncidentLoggerService>(_FakeLogger());
        final memory = SharedPreferencesService();
        GetIt.instance.registerSingleton<PersistentMemoryService>(memory);

        final userInfo = UserInformation(service: memory);
        await loadUserInformation(userInfo, 'en');

        expect(userInfo.darkModePreference, DarkModePreference.scheduled);
        expect(userInfo.darkModeStartHour, 22);
        expect(userInfo.darkModeStartMinute, 0);
        expect(userInfo.darkModeEndHour, 6);
        expect(userInfo.darkModeEndMinute, 0);
      },
    );

    test('uses defaults when all keys return null', () async {
      _registerFakes(store: {}); // all getItem calls return null

      final userInfo = _makeUserInfo();
      await loadUserInformation(userInfo, 'fr');

      expect(userInfo.name, equals(''));
      expect(userInfo.gender, equals(''));
      expect(userInfo.binary, isFalse);
      expect(userInfo.loggedIn, isFalse);
      expect(userInfo.age, equals(''));
      expect(userInfo.userId, equals(''));
      expect(userInfo.location, equals(''));
      expect(userInfo.disclaimerSigned, isFalse);
      expect(userInfo.notificationMinute, equals(0));
      expect(userInfo.notificationHour, equals(12));
      expect(userInfo.darkModePreference, DarkModePreference.alwaysLight);
      expect(userInfo.darkModeStartHour, equals(22));
      expect(userInfo.darkModeStartMinute, equals(0));
      expect(userInfo.darkModeEndHour, equals(6));
      expect(userInfo.darkModeEndMinute, equals(0));
      expect(userInfo.difficultEvents, equals([]));
      expect(userInfo.makeSafer, equals([]));
      expect(userInfo.feelBetter, equals([]));
      expect(userInfo.distractions, equals([]));
      expect(userInfo.safeEnvironment, equals([]));
      expect(userInfo.dreamsAndGoals, equals([]));
      expect(userInfo.positiveTraits, equals([]));
    });

    test('uses locale arg when savedLocale is null', () async {
      _registerFakes(store: {'localeName': null});

      final userInfo = _makeUserInfo();
      await loadUserInformation(userInfo, 'de');

      expect(userInfo.localeName, equals('de'));
    });

    test('uses locale arg when savedLocale is empty string', () async {
      _registerFakes(store: {'localeName': ''});

      final userInfo = _makeUserInfo();
      await loadUserInformation(userInfo, 'es');

      expect(userInfo.localeName, equals('es'));
    });

    test('uses saved locale when it is non-empty', () async {
      _registerFakes(store: {'localeName': 'he'});

      final userInfo = _makeUserInfo();
      await loadUserInformation(userInfo, 'en');

      expect(userInfo.localeName, equals('he'));
    });
  });
}
