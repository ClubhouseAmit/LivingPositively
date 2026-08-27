import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations_ar.dart';
import 'package:mazilon/l10n/app_localizations_en.dart';
import 'package:mazilon/l10n/app_localizations_he.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';
import 'package:mazilon/util/dreams_and_goals_selection.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/notification_preference.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_support/contract_persistent_memory_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeLogger implements IncidentLoggerService {
  _FakeLogger({this.captureLogGate, this.throwOnCaptureLog = false});

  final Future<void>? captureLogGate;
  final bool throwOnCaptureLog;
  final List<dynamic> capturedExceptions = <dynamic>[];
  final List<StackTrace?> capturedStackTraces = <StackTrace?>[];
  final Completer<void> captureLogStarted = Completer<void>();
  final Completer<void> captureLogCompleted = Completer<void>();

  @override
  Future<void> initializeSentry(_) async {}

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    capturedExceptions.add(exception);
    capturedStackTraces.add(stackTrace);
    if (!captureLogStarted.isCompleted) {
      captureLogStarted.complete();
    }
    try {
      final Future<void>? gate = captureLogGate;
      if (gate != null) {
        await gate;
      }
      if (throwOnCaptureLog) {
        throw StateError('Incident logging failed.');
      }
    } finally {
      if (!captureLogCompleted.isCompleted) {
        captureLogCompleted.complete();
      }
    }
  }
}

/// A fake [PersistentMemoryService] backed by an in-memory map.
final class _FakeMemory extends ContractPersistentMemoryService {
  bool failDreamsAndGoalsWrites;

  _FakeMemory(
    Map<String, dynamic> store, {
    this.failDreamsAndGoalsWrites = false,
  }) : super(store: store) {
    onMissingRead = (_, _) => null;
    onPersist = (key, _, _) {
      if (failDreamsAndGoalsWrites &&
          _dreamsAndGoalsStorageKeys.contains(key)) {
        throw StateError('Dreams and Goals storage is unavailable.');
      }
    };
  }
}

const Set<String> _dreamsAndGoalsStorageKeys = <String>{
  dreamsAndGoalsSelectionStorageKey,
  dreamsAndGoalsSelectionSourcesStorageKey,
  dreamsAndGoalsCustomSelectionsStorageKey,
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

_FakeMemory _registerFakes({
  required Map<String, dynamic> store,
  bool failDreamsAndGoalsWrites = false,
}) {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<IncidentLoggerService>()) {
    getIt.unregister<IncidentLoggerService>();
  }
  if (getIt.isRegistered<PersistentMemoryService>()) {
    getIt.unregister<PersistentMemoryService>();
  }
  final memory = _FakeMemory(
    store,
    failDreamsAndGoalsWrites: failDreamsAndGoalsWrites,
  );
  getIt.registerSingleton<IncidentLoggerService>(_FakeLogger());
  getIt.registerSingleton<PersistentMemoryService>(memory);
  return memory;
}

void _unregisterFakes() {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<PersistentMemoryService>()) {
    getIt.unregister<PersistentMemoryService>();
  }
  if (getIt.isRegistered<IncidentLoggerService>()) {
    getIt.unregister<IncidentLoggerService>();
  }
  if (getIt.isRegistered<FirebaseAuth>()) {
    getIt.unregister<FirebaseAuth>();
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

      final auth = GetIt.instance<FirebaseAuth>() as MockFirebaseAuth;
      final currentUser = MockUser();
      when(auth.currentUser).thenReturn(currentUser);
      when(currentUser.isAnonymous).thenReturn(false);
      when(currentUser.uid).thenReturn('uid-123');
      when(currentUser.email).thenReturn('alice@example.com');
      when(currentUser.displayName).thenReturn('Alice');

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
      expect(userInfo.notificationPreferences, isEmpty);
      expect(userInfo.darkModePreference, DarkModePreference.scheduled);
      expect(userInfo.darkModeStartHour, equals(21));
      expect(userInfo.darkModeStartMinute, equals(30));
      expect(userInfo.darkModeEndHour, equals(6));
      expect(userInfo.darkModeEndMinute, equals(15));
      expect(userInfo.localeName, equals('he'));
    });

    test(
      'requires authentication when a stored signed-in session is gone',
      () async {
        _registerFakes(
          store: {
            'loggedIn': true,
            'authDecisionMade': true,
            'userId': 'stale-uid',
          },
        );

        final userInfo = _makeUserInfo();
        await loadUserInformation(userInfo, 'en');

        expect(userInfo.loggedIn, isFalse);
        expect(userInfo.authDecisionMade, isFalse);
        expect(userInfo.userId, isEmpty);
        expect(userInfo.email, isEmpty);
        expect(userInfo.displayName, isEmpty);
      },
    );

    test(
      'preserves an explicit guest decision without a Firebase session',
      () async {
        _registerFakes(store: {'loggedIn': false, 'authDecisionMade': true});

        final userInfo = _makeUserInfo();
        await loadUserInformation(userInfo, 'en');

        expect(userInfo.loggedIn, isFalse);
        expect(userInfo.authDecisionMade, isTrue);
      },
    );

    test('loads valid notification preferences JSON', () async {
      _registerFakes(
        store: {
          'notificationPreferences': '{"default":{"hour":7,"minute":45}}',
        },
      );

      final userInfo = _makeUserInfo();
      await loadUserInformation(userInfo, 'en');

      expect(
        userInfo.getNotificationPreference('default')?.toJson(),
        const NotificationPreference(hour: 7, minute: 45).toJson(),
      );
    });

    test(
      'accepts numeric strings and whole JSON doubles in preferences',
      () async {
        _registerFakes(
          store: {
            'notificationPreferences': '{"default":{"hour":"7","minute":45.0}}',
          },
        );

        final userInfo = _makeUserInfo();
        await loadUserInformation(userInfo, 'en');

        expect(
          userInfo.getNotificationPreference('default')?.toJson(),
          const NotificationPreference(hour: 7, minute: 45).toJson(),
        );
      },
    );

    test('keeps valid preferences when another entry is malformed', () async {
      _registerFakes(
        store: {
          'notificationPreferences':
              '{"morning":{"hour":8,"minute":30},'
              '"invalidRange":{"hour":99,"minute":15},'
              '"invalidShape":"not-an-object"}',
        },
      );

      final userInfo = _makeUserInfo();
      await loadUserInformation(userInfo, 'en');

      expect(userInfo.notificationPreferences.keys, ['morning']);
      expect(
        userInfo.getNotificationPreference('morning')?.toJson(),
        const NotificationPreference(hour: 8, minute: 30).toJson(),
      );
    });

    test(
      'does not activate a reminder from legacy time for malformed JSON',
      () async {
        _registerFakes(
          store: {
            'notificationPreferences': '{not-json',
            'notificationHour': 6,
            'notificationMinute': 20,
          },
        );

        final userInfo = _makeUserInfo();
        await loadUserInformation(userInfo, 'en');

        expect(userInfo.notificationPreferences, isEmpty);
      },
    );

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

  group('loadUserInformation – Dreams and Goals source migration', () {
    test(
      'should migrate legacy English, Hebrew, and Arabic labels by id',
      () async {
        const englishGoal = 'Write and publish a book';
        const hebrewGoal = 'לכתוב ולהוציא לאור ספר';
        const arabicGoal = 'كتابة كتاب ونشره';
        final store = <String, dynamic>{
          'userSelectionPersonalPlan-DreamsAndGoals': <String>[
            englishGoal,
            hebrewGoal,
            arabicGoal,
            'My own goal',
          ],
          'addedStringsPersonalPlan-DreamsAndGoals': <String>[
            englishGoal,
            hebrewGoal,
            arabicGoal,
            'My own goal',
          ],
        };
        _registerFakes(store: store);

        final repairedMetadataStore = <String, dynamic>{};
        final userInfo = UserInformation(
          service: _FakeMemory(repairedMetadataStore),
        );
        await loadUserInformation(userInfo, 'en');

        const bookSource = 'catalogue:write-and-publish-a-book';
        expect(userInfo.dreamsAndGoalsSelectionSources, [
          bookSource,
          bookSource,
          bookSource,
          dreamsAndGoalsCustomSelectionSource,
        ]);
        expect(
          repairedMetadataStore[dreamsAndGoalsSelectionStorageKey],
          <String>[englishGoal, hebrewGoal, arabicGoal, 'My own goal'],
        );
        expect(
          repairedMetadataStore[dreamsAndGoalsSelectionSourcesStorageKey],
          <String>[
            bookSource,
            bookSource,
            bookSource,
            dreamsAndGoalsCustomSelectionSource,
          ],
        );
        expect(
          repairedMetadataStore[dreamsAndGoalsCustomSelectionsStorageKey],
          <String>['My own goal'],
        );
        expect(
          store.containsKey(dreamsAndGoalsSelectionSourcesStorageKey),
          isFalse,
        );
      },
    );

    test('should align all localized catalogue labels with immutable ids', () {
      final localizedCatalogues = <List<String>>[
        retrieveDreamsAndGoalsList(AppLocalizationsEn(), 'other'),
        retrieveDreamsAndGoalsList(AppLocalizationsHe(), 'other'),
        retrieveDreamsAndGoalsList(AppLocalizationsAr(), 'other'),
      ];
      final expectedSources = List<String>.generate(
        dreamsAndGoalsCatalogueIds.length,
        dreamsAndGoalsCatalogueSelectionSourceForIndex,
      );

      for (final catalogue in localizedCatalogues) {
        expect(catalogue, hasLength(dreamsAndGoalsCatalogueIds.length));
        expect(
          normalizeDreamsAndGoalsSelectionSources(catalogue, const <String>[]),
          expectedSources,
        );
      }
    });

    test(
      'should repair short, long, malformed, and out-of-range source rows',
      () {
        const selections = <String>[
          'Write and publish a book',
          'Learn a new language',
          'A saved own goal',
        ];

        expect(
          normalizeDreamsAndGoalsSelectionSources(selections, const <String>[]),
          [
            'catalogue:write-and-publish-a-book',
            'catalogue:learn-a-new-language',
            dreamsAndGoalsCustomSelectionSource,
          ],
        );
        expect(
          normalizeDreamsAndGoalsSelectionSources(selections, const <String>[
            'catalogue:write-and-publish-a-book',
          ]),
          [
            'catalogue:write-and-publish-a-book',
            'catalogue:learn-a-new-language',
            dreamsAndGoalsCustomSelectionSource,
          ],
        );
        expect(
          normalizeDreamsAndGoalsSelectionSources(selections, const <String>[
            'catalogue:write-and-publish-a-book',
            'catalogue:not-a-goal',
            'not-a-source',
            'custom',
          ]),
          [
            'catalogue:write-and-publish-a-book',
            'catalogue:learn-a-new-language',
            dreamsAndGoalsCustomSelectionSource,
          ],
        );
      },
    );

    test(
      'should continue startup and retain normalized state when repair fails',
      () async {
        final store = <String, dynamic>{
          dreamsAndGoalsSelectionStorageKey: <String>[
            'Write and publish a book',
            'My own goal',
          ],
          dreamsAndGoalsSelectionSourcesStorageKey: <String>[],
          dreamsAndGoalsCustomSelectionsStorageKey: <String>[],
          'location': 'Haifa',
          'disclaimerConfirmed': true,
          'notificationMinute': 45,
          'notificationHour': 8,
          'notificationMessage': 'Take a break',
          'localeName': 'he',
          'positiveTraits': <String>['Kind'],
          'thankYous': <String>['Thank you'],
          'dates': <String>['2026-08-19'],
        };
        final memory = _registerFakes(
          store: store,
          failDreamsAndGoalsWrites: true,
        );
        final logger = GetIt.instance<IncidentLoggerService>() as _FakeLogger;
        final userInfo = _makeUserInfo();

        await loadUserInformation(userInfo, 'en');

        expect(userInfo.dreamsAndGoals, <String>[
          'Write and publish a book',
          'My own goal',
        ]);
        expect(userInfo.dreamsAndGoalsSelectionSources, <String>[
          'catalogue:write-and-publish-a-book',
          dreamsAndGoalsCustomSelectionSource,
        ]);
        expect(userInfo.location, 'Haifa');
        expect(userInfo.disclaimerSigned, isTrue);
        expect(userInfo.notificationMinute, 45);
        expect(userInfo.notificationHour, 8);
        expect(userInfo.notificationMessage, 'Take a break');
        expect(userInfo.localeName, 'he');
        expect(userInfo.positiveTraits, <String>['Kind']);
        expect(userInfo.thanks, <String, List<String>>{
          'thanks': <String>['Thank you'],
          'dates': <String>['2026-08-19'],
        });
        expect(logger.capturedExceptions, hasLength(1));
        expect(logger.capturedExceptions.single, isA<StateError>());
        expect(logger.capturedStackTraces.single, isNotNull);

        memory.failDreamsAndGoalsWrites = false;
        await userInfo.retryDreamsAndGoalsSave(
          userInfo.dreamsAndGoalsSaveRevision,
        );

        expect(store[dreamsAndGoalsSelectionStorageKey], <String>[
          'Write and publish a book',
          'My own goal',
        ]);
        expect(store[dreamsAndGoalsSelectionSourcesStorageKey], <String>[
          'catalogue:write-and-publish-a-book',
          dreamsAndGoalsCustomSelectionSource,
        ]);
        expect(store[dreamsAndGoalsCustomSelectionsStorageKey], <String>[
          'My own goal',
        ]);
      },
    );
  });

  group('loadUserInformation – empty / null defaults', () {
    test(
      'uses the default schedule when saved values are absent',
      () async {
        _registerFakes(
          store: {
            'darkModePreference': 'scheduled',
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
      'defaults and logs an invalid typed SharedPreferences value',
      () async {
        SharedPreferences.setMockInitialValues({
          'darkModePreference': 'scheduled',
          'darkModeStartHour': 'not-an-int',
        });
        final logger = _FakeLogger();
        final memory = SharedPreferencesService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        GetIt.instance.registerSingleton<PersistentMemoryService>(memory);

        final userInfo = UserInformation(service: memory);
        await loadUserInformation(userInfo, 'en');
        await logger.captureLogCompleted.future;

        expect(userInfo.darkModePreference, DarkModePreference.scheduled);
        expect(userInfo.darkModeStartHour, 22);
        expect(userInfo.darkModeStartMinute, 0);
        expect(userInfo.darkModeEndHour, 6);
        expect(userInfo.darkModeEndMinute, 0);
        expect(logger.capturedExceptions, hasLength(1));
        expect(logger.capturedStackTraces.single, isNotNull);
      },
    );

    test(
      'returns a null fallback when logger capture fails for malformed storage',
      () async {
        SharedPreferences.setMockInitialValues({
          'darkModeStartHour': 'not-an-int',
        });
        final Completer<void> loggerGate = Completer<void>();
        final logger = _FakeLogger(
          captureLogGate: loggerGate.future,
          throwOnCaptureLog: true,
        );
        final memory = SharedPreferencesService();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        GetIt.instance.registerSingleton<PersistentMemoryService>(memory);

        final Future<dynamic> read = memory.getItem(
          'darkModeStartHour',
          PersistentMemoryType.Int,
        );
        bool readCompleted = false;
        unawaited(
          read.then<void>(
            (_) {
              readCompleted = true;
            },
            onError: (_, _) {
              readCompleted = true;
            },
          ),
        );
        await logger.captureLogStarted.future;
        await Future<void>.microtask(() {});
        expect(readCompleted, isFalse);
        expect(logger.captureLogCompleted.isCompleted, isFalse);

        loggerGate.complete();
        await logger.captureLogCompleted.future;

        expect(await read, isNull);
        expect(readCompleted, isTrue);
        expect(logger.capturedExceptions, hasLength(1));
        expect(logger.capturedStackTraces.single, isNotNull);
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
        await Future<void>.delayed(Duration.zero);

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
      expect(userInfo.notificationPreferences, isEmpty);
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
