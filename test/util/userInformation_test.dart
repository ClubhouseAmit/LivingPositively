import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/dreams_and_goals_selection.dart';
import 'package:mazilon/util/userInformation.dart';

import '../../test_support/contract_persistent_memory_service.dart';

base class _FakePersistentMemoryService
    extends ContractPersistentMemoryService {
  _FakePersistentMemoryService() {
    onMissingRead = (_, _) => null;
  }

  Map<String, dynamic> get stored => store;

  List<MapEntry<String, dynamic>> get writes => <MapEntry<String, dynamic>>[
    for (final ContractPersistentMemoryWrite write in completedWrites)
      MapEntry<String, dynamic>(write.key, write.value),
  ];

  void restoreDurableValue(String key) {
    final Object? previousValue = durableStore[key];
    if (previousValue == null) {
      store.remove(key);
      return;
    }
    store[key] = previousValue;
  }
}

final class _DelayedDreamsMemoryService extends _FakePersistentMemoryService {
  _DelayedDreamsMemoryService({this._failFirstEmptySelectionWrite = false}) {
    onPersist = (String key, PersistentMemoryType type, Object value) async {
      if (key != dreamsAndGoalsSelectionStorageKey) {
        return;
      }
      final List<String> snapshot = List<String>.from(value as Iterable);
      selectionWriteSnapshots.add(snapshot);
      if (_isFirstSelectionWrite) {
        _isFirstSelectionWrite = false;
        firstSelectionWriteStarted.complete();
        await _firstSelectionWrite.future;
      }
      if (_failFirstEmptySelectionWrite &&
          !_hasFailedEmptySelectionWrite &&
          snapshot.isEmpty) {
        _hasFailedEmptySelectionWrite = true;
        restoreDurableValue(key);
        throw StateError('Persistent memory failed.');
      }
    };
  }

  final Completer<void> _firstSelectionWrite = Completer<void>();
  final Completer<void> firstSelectionWriteStarted = Completer<void>();
  final List<List<String>> selectionWriteSnapshots = <List<String>>[];
  final bool _failFirstEmptySelectionWrite;
  bool _isFirstSelectionWrite = true;
  bool _hasFailedEmptySelectionWrite = false;

  void releaseFirstSelectionWrite() {
    if (!_firstSelectionWrite.isCompleted) {
      _firstSelectionWrite.complete();
    }
  }
}

final class _FailingPersistentMemoryService
    extends _FakePersistentMemoryService {
  _FailingPersistentMemoryService() {
    onPersist = (String key, PersistentMemoryType type, Object value) {
      restoreDurableValue(key);
      throw StateError('Persistent memory failed.');
    };
  }
}

final class _FailingFirstDreamsSelectionMemoryService
    extends _FakePersistentMemoryService {
  _FailingFirstDreamsSelectionMemoryService() {
    onPersist = (String key, PersistentMemoryType type, Object value) {
      if (key == dreamsAndGoalsSelectionStorageKey &&
          _shouldFailFirstDreamsSelectionWrite) {
        _shouldFailFirstDreamsSelectionWrite = false;
        restoreDurableValue(key);
        throw StateError('Persistent memory failed.');
      }
    };
  }

  bool _shouldFailFirstDreamsSelectionWrite = true;
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
      expect(u.safeEnvironment, isEmpty);
      expect(u.dreamsAndGoals, isEmpty);
      expect(u.dreamsAndGoalsSelectionSources, isEmpty);
      expect(u.positiveTraits, isEmpty);
      expect(u.thanks, isEmpty);
    });
  });

  group('UserInformation.reset', () {
    test('clears all mutable fields and applies provided locale', () async {
      final u = UserInformation(
        service: fakeService,
        gender: 'male',
        name: 'Alice',
        age: '30',
        binary: true,
        location: 'IL',
        notificationHour: 9,
        notificationMinute: 30,
        darkModePreference: DarkModePreference.alwaysDark,
        darkModeStartHour: 20,
        darkModeStartMinute: 15,
        darkModeEndHour: 7,
        darkModeEndMinute: 45,
        difficultEvents: const ['a'],
        makeSafer: const ['b'],
        feelBetter: const ['c'],
        distractions: const ['d'],
        safeEnvironment: const ['e'],
        dreamsAndGoals: const ['f'],
        dreamsAndGoalsSelectionSources: const ['custom'],
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

      await u.reset('he');

      expect(u.localeName, 'he');
      expect(u.location, '');
      expect(u.gender, '');
      expect(u.name, '');
      expect(u.age, '');
      expect(u.binary, isFalse);
      expect(u.notificationHour, 12);
      expect(u.notificationMinute, 0);
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
      expect(u.safeEnvironment, isEmpty);
      expect(u.dreamsAndGoals, isEmpty);
      expect(u.dreamsAndGoalsSelectionSources, isEmpty);
      expect(u.thanks, isEmpty);
      expect(u.positiveTraits, isEmpty);
      expect(notified, 1);
    });

    test(
      'queues an empty Dreams snapshot after a held earlier snapshot',
        () async {
      final delayedService = _DelayedDreamsMemoryService();
      final user = UserInformation(service: delayedService);
      user.updateDreamsAndGoals(
        <String>['My custom goal'],
        selectionSources: const <String>[dreamsAndGoalsCustomSelectionSource],
      );
      user.queueDreamsAndGoalsSave();
      await delayedService.firstSelectionWriteStarted.future;

      final Future<void> reset = user.reset('en');
      expect(user.dreamsAndGoals, isEmpty);
      expect(user.dreamsAndGoalsSelectionSources, isEmpty);

      delayedService.releaseFirstSelectionWrite();
      await reset;

      expect(
        delayedService.stored[dreamsAndGoalsSelectionStorageKey],
        isEmpty,
      );
      expect(
        delayedService.stored[dreamsAndGoalsSelectionSourcesStorageKey],
        isEmpty,
      );
      expect(
        delayedService.stored[dreamsAndGoalsCustomSelectionsStorageKey],
        isEmpty,
      );
      },
    );

    test(
      'does not leave a held stale custom snapshot persisted after the reset revision retries',
      () async {
        final delayedService = _DelayedDreamsMemoryService(
          failFirstEmptySelectionWrite: true,
        );
        final user = UserInformation(service: delayedService);
        user.updateDreamsAndGoals(
          <String>['My custom goal'],
          selectionSources: const <String>[dreamsAndGoalsCustomSelectionSource],
        );
        final Future<void> oldSave = user.queueDreamsAndGoalsSave();
        await delayedService.firstSelectionWriteStarted.future;

        final Future<void> reset = user.reset('en');
        expect(user.dreamsAndGoals, isEmpty);
        expect(user.dreamsAndGoalsSelectionSources, isEmpty);

        delayedService.releaseFirstSelectionWrite();
        await oldSave;
        await expectLater(reset, throwsA(isA<StateError>()));

        expect(delayedService.selectionWriteSnapshots, <List<String>>[
          <String>['My custom goal'],
          <String>[],
        ]);
        expect(
          delayedService.writes
              .map((MapEntry<String, dynamic> write) => write.key)
              .where((key) => key.contains('DreamsAndGoals'))
              .toList(),
          <String>[
            dreamsAndGoalsSelectionStorageKey,
            dreamsAndGoalsSelectionSourcesStorageKey,
            dreamsAndGoalsCustomSelectionsStorageKey,
          ],
        );
        expect(
          delayedService.stored[dreamsAndGoalsCustomSelectionsStorageKey],
          <String>['My custom goal'],
        );

        await user.retryDreamsAndGoalsSave(user.dreamsAndGoalsSaveRevision);

        expect(delayedService.selectionWriteSnapshots, <List<String>>[
          <String>['My custom goal'],
          <String>[],
          <String>[],
        ]);
        expect(
          delayedService.writes
              .map((MapEntry<String, dynamic> write) => write.key)
              .where((key) => key.contains('DreamsAndGoals'))
              .toList(),
          <String>[
            dreamsAndGoalsSelectionStorageKey,
            dreamsAndGoalsSelectionSourcesStorageKey,
            dreamsAndGoalsCustomSelectionsStorageKey,
            dreamsAndGoalsSelectionStorageKey,
            dreamsAndGoalsSelectionSourcesStorageKey,
            dreamsAndGoalsCustomSelectionsStorageKey,
          ],
        );
        expect(
          delayedService.stored[dreamsAndGoalsSelectionStorageKey],
          isEmpty,
        );
        expect(
          delayedService.stored[dreamsAndGoalsSelectionSourcesStorageKey],
          isEmpty,
        );
        expect(
          delayedService.stored[dreamsAndGoalsCustomSelectionsStorageKey],
          isEmpty,
        );
      },
    );

    test(
      'propagates an empty Dreams snapshot failure until the current revision retries',
      () async {
        final failingService = _FailingFirstDreamsSelectionMemoryService();
        final user = UserInformation(
          service: failingService,
          dreamsAndGoals: const <String>['My custom goal'],
          dreamsAndGoalsSelectionSources: const <String>[
            dreamsAndGoalsCustomSelectionSource,
          ],
        );

        final Future<void> reset = user.reset('en');

        expect(user.dreamsAndGoals, isEmpty);
        expect(user.dreamsAndGoalsSelectionSources, isEmpty);
        await expectLater(reset, throwsA(isA<StateError>()));
        expect(
          failingService.stored[dreamsAndGoalsSelectionStorageKey],
          isNull,
        );
        expect(
          failingService.stored[dreamsAndGoalsSelectionSourcesStorageKey],
          isNull,
        );
        expect(
          failingService.stored[dreamsAndGoalsCustomSelectionsStorageKey],
          isNull,
        );

        await user.retryDreamsAndGoalsSave(user.dreamsAndGoalsSaveRevision);

        expect(
          failingService.stored[dreamsAndGoalsSelectionStorageKey],
          isEmpty,
        );
        expect(
          failingService.stored[dreamsAndGoalsSelectionSourcesStorageKey],
          isEmpty,
        );
        expect(
          failingService.stored[dreamsAndGoalsCustomSelectionsStorageKey],
          isEmpty,
        );
      },
    );
  });

  group('update methods that persist', () {
    test(
      'should persist disclaimer and has-filled through its injected service',
      () async {
        final user = buildUser();

        await user.persistDisclaimerConfirmed();
        await user.persistHasFilled();

        expect(fakeService.stored['disclaimerConfirmed'], isTrue);
        expect(fakeService.stored['hasFilled'], isTrue);
      },
    );

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

    test(
      'background preference writes should contain persistence failures',
      () async {
        final user = UserInformation(
          service: _FailingPersistentMemoryService(),
        );

      user.updateGender('other');
      user.updateNotificationHour(9);
      await Future<void>.delayed(Duration.zero);

      expect(user.gender, 'other');
      expect(user.notificationHour, 9);
      },
    );

    test(
      'should hydrate and repair malformed Dreams source metadata through its injected service',
      () async {
        final user = UserInformation(service: fakeService);
        const selections = <String>[
          'Write and publish a book',
          'My custom dream',
        ];

        await user.hydrateDreamsAndGoalsFromStorage(
          selections,
          storedSelectionSources: const <String>[
            'catalogue:learn-a-new-language',
          ],
          storedCustomSelections: const <String>[],
        );

        expect(user.dreamsAndGoals, selections);
        expect(user.dreamsAndGoalsSelectionSources, const <String>[
          'catalogue:write-and-publish-a-book',
          dreamsAndGoalsCustomSelectionSource,
        ]);
        expect(
          fakeService.stored[dreamsAndGoalsSelectionStorageKey],
          selections,
        );
        expect(
          fakeService.stored[dreamsAndGoalsSelectionSourcesStorageKey],
          user.dreamsAndGoalsSelectionSources,
        );
        expect(
          fakeService.stored[dreamsAndGoalsCustomSelectionsStorageKey],
          const <String>['My custom dream'],
        );

        final writesAfterRepair = fakeService.writes.length;
        await user.hydrateDreamsAndGoalsFromStorage(
          selections,
          storedSelectionSources: user.dreamsAndGoalsSelectionSources,
          storedCustomSelections: const <String>['My custom dream'],
        );

        expect(fakeService.writes, hasLength(writesAfterRepair));
      },
    );

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

    test('updateSafeEnvironment', () {
      final u = buildUser();
      u.updateSafeEnvironment(['store medications safely']);
      expect(u.safeEnvironment, ['store medications safely']);
    });

    test('updateDreamsAndGoals keeps positional selection sources', () {
      final u = buildUser();
      u.updateDreamsAndGoals(
        ['Write and publish a book'],
        selectionSources: ['catalogue:write-and-publish-a-book'],
      );
      expect(u.dreamsAndGoals, ['Write and publish a book']);
      expect(u.dreamsAndGoalsSelectionSources, [
        'catalogue:write-and-publish-a-book',
      ]);
    });

    test('should defensively copy Dreams and Goals values and sources', () {
      final u = buildUser();
      final values = <String>['My original goal'];
      final sources = <String>[dreamsAndGoalsCustomSelectionSource];

      u.updateDreamsAndGoals(values, selectionSources: sources);
      values[0] = 'Changed outside the model';
      sources[0] = 'catalogue:write-and-publish-a-book';

      expect(u.dreamsAndGoals, <String>['My original goal']);
      expect(u.dreamsAndGoalsSelectionSources, <String>[
        dreamsAndGoalsCustomSelectionSource,
      ]);
    });

    test('should clear Dreams and Goals sources when they are omitted', () {
      final u = buildUser();
      u.updateDreamsAndGoals(
        <String>['Write and publish a book'],
        selectionSources: const <String>['catalogue:write-and-publish-a-book'],
      );

      u.updateDreamsAndGoals(<String>['A source-free legacy value']);

      expect(u.dreamsAndGoals, <String>['A source-free legacy value']);
      expect(u.dreamsAndGoalsSelectionSources, isEmpty);
    });

    test('should reject mismatched Dreams sources without mutating state', () {
      final u = buildUser();
      u.updateDreamsAndGoals(
        <String>['Write and publish a book'],
        selectionSources: const <String>['catalogue:write-and-publish-a-book'],
      );
      var notifications = 0;
      u.addListener(() => notifications++);

      expect(
        () => u.updateDreamsAndGoals(
          <String>['First new value', 'Second new value'],
          selectionSources: const <String>[dreamsAndGoalsCustomSelectionSource],
        ),
        throwsArgumentError,
      );

      expect(u.dreamsAndGoals, <String>['Write and publish a book']);
      expect(u.dreamsAndGoalsSelectionSources, const <String>[
        'catalogue:write-and-publish-a-book',
      ]);
      expect(notifications, 0);
    });

    test(
      'should preserve and persist multiple custom Dreams rows during hydration and repair',
      () async {
        final u = buildUser();
        const List<String> selections = <String>[
          'Write and publish a book',
          'First custom goal',
          'Learn a new language',
          'Second custom goal',
        ];
        const List<String> sources = <String>[
          'catalogue:write-and-publish-a-book',
          dreamsAndGoalsCustomSelectionSource,
          'catalogue:learn-a-new-language',
          dreamsAndGoalsCustomSelectionSource,
        ];

        await u.hydrateDreamsAndGoalsFromStorage(
          selections,
          storedSelectionSources: const <String>[],
          storedCustomSelections: const <String>[],
        );
        final int writesAfterHydration = fakeService.writes.length;
        await u.repairDreamsAndGoalsSelectionSources();

        expect(u.dreamsAndGoals, selections);
        expect(u.dreamsAndGoalsSelectionSources, sources);
        expect(
          fakeService.stored[dreamsAndGoalsSelectionStorageKey],
          selections,
        );
        expect(
          fakeService.stored[dreamsAndGoalsSelectionSourcesStorageKey],
          sources,
        );
        expect(
          fakeService.stored[dreamsAndGoalsCustomSelectionsStorageKey],
          const <String>['First custom goal', 'Second custom goal'],
    );
        expect(writesAfterHydration, 3);
        expect(fakeService.writes, hasLength(writesAfterHydration));
      },
    );

    test(
      'should serialize the latest Dreams snapshot after an older save',
      () async {
        final delayedService = _DelayedDreamsMemoryService();
        final u = UserInformation(service: delayedService);
        u.updateDreamsAndGoals(
          <String>['My custom goal'],
          selectionSources: const <String>[dreamsAndGoalsCustomSelectionSource],
        );
        final Future<void> firstSave = u.queueDreamsAndGoalsSave();
        await delayedService.firstSelectionWriteStarted.future;

        u.updateDreamsAndGoals(
          <String>['My custom goal', 'Write and publish a book'],
          selectionSources: const <String>[
            dreamsAndGoalsCustomSelectionSource,
            'catalogue:write-and-publish-a-book',
          ],
        );
        final Future<void> secondSave = u.queueDreamsAndGoalsSave();
        await Future<void>.delayed(Duration.zero);

        expect(delayedService.selectionWriteSnapshots, <List<String>>[
          <String>['My custom goal'],
        ]);

        delayedService.releaseFirstSelectionWrite();
        await firstSave;
        await secondSave;

        expect(delayedService.selectionWriteSnapshots, <List<String>>[
          <String>['My custom goal'],
          <String>['My custom goal', 'Write and publish a book'],
        ]);
        expect(
          delayedService.stored[dreamsAndGoalsSelectionStorageKey],
          <String>['My custom goal', 'Write and publish a book'],
        );
        expect(
          delayedService.stored[dreamsAndGoalsSelectionSourcesStorageKey],
          <String>[
            dreamsAndGoalsCustomSelectionSource,
            'catalogue:write-and-publish-a-book',
          ],
        );
        expect(
          delayedService.stored[dreamsAndGoalsCustomSelectionsStorageKey],
          <String>['My custom goal'],
        );
      },
    );

    test(
      'should complete each Dreams persistence key before starting the next',
      () async {
        final delayedService = _DelayedDreamsMemoryService();
        final u = UserInformation(service: delayedService)
          ..updateDreamsAndGoals(
            <String>['My custom goal'],
            selectionSources: const <String>[
              dreamsAndGoalsCustomSelectionSource,
            ],
          );

        final Future<void> save = u.queueDreamsAndGoalsSave();
        await delayedService.firstSelectionWriteStarted.future;

        expect(delayedService.writes, isEmpty);

        delayedService.releaseFirstSelectionWrite();
        await save;

        expect(
          delayedService.writes
              .map((MapEntry<String, dynamic> write) => write.key)
              .toList(),
          <String>[
            dreamsAndGoalsSelectionStorageKey,
            dreamsAndGoalsSelectionSourcesStorageKey,
            dreamsAndGoalsCustomSelectionsStorageKey,
          ],
        );
      },
    );

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

  group('saveCategorySelection and export preparation', () {
    test('throws ArgumentError for unsupported category name', () async {
      final u = buildUser();
      expect(
        () => u.saveCategorySelection('UnsupportedCategory', ['Item 1']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('preserves provenance metadata when selectionSources is omitted for DreamsAndGoals', () async {
      final u = buildUser();
      u.updateDreamsAndGoals(
        ['Write and publish a book', 'Custom Goal B'],
        selectionSources: ['catalogue:write-and-publish-a-book', 'custom'],
      );

      // Save with omitted selectionSources
      await u.saveCategorySelection(
        'PersonalPlan-DreamsAndGoals',
        ['Write and publish a book', 'Custom Goal B'],
      );

      expect(u.dreamsAndGoalsSelectionSources, [
        'catalogue:write-and-publish-a-book',
        'custom',
      ]);
    });

    test('updates provenance metadata when selectionSources is explicitly provided for DreamsAndGoals', () async {
      final u = buildUser();
      u.updateDreamsAndGoals(
        ['Write and publish a book', 'Custom Goal B'],
        selectionSources: ['catalogue:write-and-publish-a-book', 'custom'],
      );

      await u.saveCategorySelection(
        'PersonalPlan-DreamsAndGoals',
        ['Write and publish a book', 'Custom Goal B'],
        selectionSources: ['custom', 'custom'],
      );

      expect(u.dreamsAndGoalsSelectionSources, [
        'custom',
        'custom',
      ]);
    });

    test('persists supported standard categories correctly', () async {
      final u = buildUser();
      await u.saveCategorySelection(
        'PersonalPlan-DifficultEvents',
        ['Event 1', 'Event 2'],
      );

      expect(u.difficultEvents, ['Event 1', 'Event 2']);
      expect(
        fakeService.stored['userSelectionPersonalPlan-DifficultEvents'],
        ['Event 1', 'Event 2'],
      );
    });
  });
}
