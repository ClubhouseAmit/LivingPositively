import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';

import '../../../Firebase/firebase_auth_service_test.mocks.dart';

final class _Memory implements PersistentMemoryService {
  final writes = <String>[];
  String? expanded;
  Completer<void>? gate;
  bool failNextWrite = false;
  bool failNextExpandedWrite = false;

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (key == 'fcmDefaultReminderMigrated') {
      expect(type, PersistentMemoryType.Bool);
      expect(value, isTrue);
      return;
    }
    if (key == 'notificationReminderSettings') {
      if (failNextExpandedWrite) {
        failNextExpandedWrite = false;
        throw StateError('expanded storage unavailable');
      }
      expanded = value as String;
      return;
    }
    expect(key, 'notificationPreferences');
    expect(type, PersistentMemoryType.String);
    if (gate case final pending?) await pending.future;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('disk unavailable');
    }
    writes.add(value as String);
  }

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async =>
      key == 'notificationPreferences' ? writes.lastOrNull : null;

  @override
  Future<Map<String, Object?>> readSnapshot(
    Map<String, PersistentMemoryType> keys,
  ) async => {'notificationPreferences': writes.lastOrNull};

  @override
  Future<void> reset() async {}
}

void main() {
  group('NotificationRepository', () {
    late _Memory memory;
    late NotificationRepository repository;

    setUp(() {
      memory = _Memory();
      repository = NotificationRepository.forService(memory);
    });

    test(
      'should retain unowned expanded choices after an older client writes',
      () async {
        await repository.setCustomReminder(
          const CustomReminder(
            id: 'custom_1',
            emoji: 'x',
            label: 'Practice',
            hour: 8,
            minute: 0,
          ),
        );
        await repository.setPreference(
          'custom_1',
          const NotificationPreference.withContent(
            hour: 8,
            minute: 0,
            staticTitle: 'Title',
            staticBody: 'Practice',
          ),
        );
        await repository.setUse24HourFormat(false);
        await repository.setSavedTime(
          'quick_water',
          const NotificationPreference(hour: 9, minute: 15),
        );
        final expanded = memory.expanded;
        repository.restorePersistedJson(
          '{"default":{"hour":7,"minute":45},"custom_1":{"hour":8,"minute":0}}',
          expanded,
        );
        expect(repository.customReminders.single.label, 'Practice');
        expect(repository.use24HourFormat, isFalse);
        expect(repository.isActiveAccount('account-a'), isFalse);
        expect(repository.getSavedTime('quick_water')?.minute, 15);
        expect(repository.getPreference('custom_1')?.staticBody, 'Practice');
        expect(repository.getPreference('default')?.minute, 45);
        repository.restorePersistedJson('{}', expanded);
        expect(repository.getPreference('default'), isNull);
        expect(repository.defaultOptOut, isTrue);
        expect(repository.getPreference('custom_1'), isNotNull);
      },
    );

    for (final corrupt in ['{broken', '[]', 'null', '42', '"settings"']) {
      test('should retain valid primary state with corrupt copy $corrupt', () {
        repository.restorePersistedJson(
          '{"quick_water":{"hour":9,"minute":15},"__defaultOptOut":true}',
          corrupt,
        );
        expect(repository.getPreference('quick_water')?.minute, 15);
        expect(repository.getPreference('default'), isNull);
        expect(repository.defaultOptOut, isTrue);
      });
    }

    for (final invalid in ['{broken', '[]', 'null', '42']) {
      test(
        'should reject invalid primary state $invalid despite valid copy',
        () {
          expect(
            () => repository.restorePersistedJson(invalid, '{}'),
            throwsFormatException,
          );
        },
      );
    }

    test(
      'should preserve account A after an unowned account B rewrite',
      () async {
        await repository.activateAccount('account-b');
        await repository.setPreference(
          'default',
          const NotificationPreference(hour: 6, minute: 0),
        );
        await repository.activateAccount('account-a');
        await repository.setCustomReminder(
          const CustomReminder(
            id: 'custom_1',
            emoji: 'x',
            label: 'Account A practice',
            hour: 8,
            minute: 0,
          ),
        );
        await repository.setPreference(
          'quick_water',
          const NotificationPreference(hour: 9, minute: 15),
        );
        await repository.clearPreferenceForAccountTransition('quick_water');
        await repository.clearPreference('default');
        await repository.setUse24HourFormat(false);
        final expanded = memory.expanded;
        repository.restorePersistedJson(
          '{"default":{"hour":22,"minute":45},'
          '"quick_water":{"hour":21,"minute":30}}',
          expanded,
        );
        expect(repository.isActiveAccount('account-a'), isTrue);
        expect(repository.getPreference('default'), isNull);
        expect(repository.defaultOptOut, isTrue);
        expect(repository.getPreference('quick_water'), isNull);
        expect(
          repository
              .pausedAccountRemindersFor('account-a')['quick_water']
              ?.hour,
          9,
        );
        expect(repository.customReminders.single.label, 'Account A practice');
        expect(repository.use24HourFormat, isFalse);

        await repository.activateAccount('account-b');
        expect(repository.getPreference('default')?.hour, 6);
        expect(repository.getPreference('quick_water'), isNull);
        expect(repository.customReminders, isEmpty);
        final restored = NotificationRepository.forService(_Memory())
          ..restoreJson(memory.writes.last);
        await restored.activateAccount('account-a');
        expect(restored.getPreference('default'), isNull);
        expect(restored.defaultOptOut, isTrue);
        expect(restored.getSavedTime('quick_water')?.hour, 9);
        expect(
          restored
              .pausedAccountRemindersFor('account-a')['quick_water']
              ?.minute,
          15,
        );
        expect(restored.customReminders.single.label, 'Account A practice');
        expect(restored.use24HourFormat, isFalse);
      },
    );

    for (final metadata in [
      {'__activeAccountUid': 42},
      {'__activeAccountUid': ''},
      {'__pausedAccountOwnerUid': false},
      {'__pausedAccountOwnerUid': ' '},
      {'__accountSnapshots': []},
      {
        '__accountSnapshots': {'account-a': 42},
      },
      {
        '__accountSnapshots': {'account-a': '{broken'},
      },
      {
        '__accountSnapshots': {'account-a': '[]'},
      },
      {
        '__accountSnapshots': {'': '{}'},
      },
      {
        '__accountSnapshots': {
          'account-a': '{"__activeAccountUid":"account-b"}',
        },
      },
    ]) {
      test('should recover primary state for invalid ownership $metadata', () {
        repository.restorePersistedJson(
          '{"quick_water":{"hour":21,"minute":30},"__defaultOptOut":true}',
          jsonEncode({
            'default': {'hour': 8, 'minute': 0},
            ...metadata,
          }),
        );
        expect(repository.getPreference('quick_water')?.hour, 21);
        expect(repository.getPreference('default'), isNull);
        expect(repository.defaultOptOut, isTrue);
        expect(repository.isActiveAccount('account-a'), isFalse);
      });
    }

    for (final owner in [
      {'__activeAccountUid': 'account-a'},
      {'__pausedAccountOwnerUid': 'account-a'},
      {
        '__accountSnapshots': {'account-a': '{}'},
      },
    ]) {
      test('should preserve each valid ownership marker $owner', () {
        repository.restorePersistedJson(
          '{"default":{"hour":21,"minute":30}}',
          jsonEncode({
            'default': {'hour': 8, 'minute': 0},
            '__defaultOptOut': false,
            ...owner,
          }),
        );
        expect(repository.getPreference('default')?.hour, 8);
        expect(repository.defaultOptOut, isFalse);
      });
    }

    test(
      'should import identified same-account edits and default removal',
      () async {
        await repository.activateAccount('account-a');
        await repository.setPreference(
          'default',
          const NotificationPreference(hour: 8, minute: 0),
        );
        await repository.setUse24HourFormat(false);
        final expanded = memory.expanded;
        repository.restorePersistedJson(
          '{"__activeAccountUid":"account-a",'
          '"default":{"hour":21,"minute":30}}',
          expanded,
        );
        expect(repository.getPreference('default')?.hour, 21);
        expect(repository.defaultOptOut, isFalse);
        expect(repository.use24HourFormat, isFalse);
        repository.restorePersistedJson(
          '{"__activeAccountUid":"account-a"}',
          expanded,
        );
        expect(repository.getPreference('default'), isNull);
        expect(repository.defaultOptOut, isTrue);
        expect(repository.isActiveAccount('account-a'), isTrue);
      },
    );

    for (final optOut in [true, false]) {
      test('should preserve explicit legacy default opt-out $optOut', () {
        repository.restorePersistedJson(
          jsonEncode({'__defaultOptOut': optOut}),
          '{"__use24HourFormat":false}',
        );
        expect(repository.defaultOptOut, optOut);
        expect(repository.use24HourFormat, isFalse);
        expect(repository.getPreference('default'), isNull);
      });
    }

    for (final expandedFailure in [false, true]) {
      test(
        'should roll back custom time on failure (expanded: $expandedFailure)',
        () async {
          const previous = CustomReminder(
            id: 'custom_1',
            emoji: 'x',
            label: 'Practice',
            hour: 8,
            minute: 0,
          );
          await repository.setCustomReminderTime(previous);
          memory.failNextWrite = !expandedFailure;
          memory.failNextExpandedWrite = expandedFailure;
          await expectLater(
            repository.setCustomReminderTime(
              const CustomReminder(
                id: 'custom_1',
                emoji: 'x',
                label: 'Practice',
                hour: 9,
                minute: 30,
              ),
            ),
            throwsStateError,
          );
          expect(repository.customReminders.single.hour, 8);
          expect(repository.getSavedTime('custom_1')?.hour, 8);
          final restored = NotificationRepository.forService(_Memory())
            ..restoreJson(memory.writes.last);
          expect(restored.customReminders.single.hour, 8);
          expect(restored.getSavedTime('custom_1')?.hour, 8);
        },
      );
    }

    test('should preserve concurrent edits when custom time fails', () async {
      await repository.setCustomReminderTime(
        const CustomReminder(
          id: 'custom_1',
          emoji: 'x',
          label: 'Practice',
          hour: 8,
          minute: 0,
        ),
      );
      memory.gate = Completer<void>();
      memory.failNextWrite = true;
      final edit = repository.setCustomReminderTime(
        const CustomReminder(
          id: 'custom_1',
          emoji: 'x',
          label: 'Practice',
          hour: 9,
          minute: 30,
        ),
      );
      final format = repository.setUse24HourFormat(false);
      final quick = repository.setPreference(
        'quick_water',
        const NotificationPreference(hour: 10, minute: 15),
      );
      final failed = expectLater(edit, throwsStateError);
      memory.gate!.complete();
      await Future.wait([failed, format, quick]);
      expect(repository.customReminders.single.hour, 8);
      expect(repository.use24HourFormat, isFalse);
      expect(repository.getPreference('quick_water')?.hour, 10);
      final restored = NotificationRepository.forService(_Memory())
        ..restoreJson(memory.writes.last);
      expect(restored.customReminders.single.hour, 8);
      expect(restored.use24HourFormat, isFalse);
      expect(restored.getPreference('quick_water')?.hour, 10);
    });

    group('locale rescheduling', () {
      late UserInformation user;
      late Completer<http.Response> pendingResponse;
      late Completer<void> requestStarted;
      late List<Map<String, dynamic>> registrations;

      setUp(() {
        final auth = MockFirebaseAuth();
        final firebaseUser = MockUser();
        when(auth.currentUser).thenReturn(firebaseUser);
        when(firebaseUser.isAnonymous).thenReturn(false);
        when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token');
        GetIt.instance.registerSingleton<FirebaseAuth>(auth);
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        user = UserInformation(
          service: memory,
          loggedIn: true,
          userId: 'account-a',
          localeName: 'en',
        );
        pendingResponse = Completer<http.Response>();
        requestStarted = Completer<void>();
        registrations = [];
      });

      tearDown(() async {
        FcmScheduledNotificationService.resetForTesting();
        debugDefaultTargetPlatformOverride = null;
        await GetIt.instance.reset();
      });

      for (final id in ['default', 'quick_water']) {
        test('should keep $id disabled after a queued cancellation', () async {
          await repository.setPreference(
            id,
            const NotificationPreference(hour: 8, minute: 0),
          );
          FcmScheduledNotificationService.debugPostOverride =
              (url, {headers, body, encoding}) async {
                if (url.path.endsWith('/getNotificationMutationVersion')) {
                  return http.Response('{"mutationVersion":0}', 200);
                }
                if (url.path.endsWith('/cancelNotification')) {
                  requestStarted.complete();
                  return pendingResponse.future;
                }
                registrations.add(
                  jsonDecode(body! as String) as Map<String, dynamic>,
                );
                return http.Response('{"success":true}', 200);
              };
          final cancellation =
              FcmScheduledNotificationService.cancelNotification(
                userInformation: user,
                typeId: id,
              );
          await requestStarted.future;
          expect(repository.getPreference(id), isNotNull);
          final refresh = id == 'default'
              ? repository.rescheduleDefaultReminder(user)
              : repository.rescheduleTextReminder(user, id, 'Drink water');
          pendingResponse.complete(http.Response('{"success":true}', 200));
          expect(await cancellation, isTrue);
          expect(await refresh, isTrue);
          expect(registrations, isEmpty);
          expect(repository.getPreference(id), isNull);
        });

        test('should refresh $id using its latest enabled time', () async {
          await repository.setPreference(
            id,
            const NotificationPreference(hour: 8, minute: 0),
          );
          FcmScheduledNotificationService.debugPostOverride =
              (url, {headers, body, encoding}) async {
                if (url.path.endsWith('/getNotificationMutationVersion')) {
                  if (!requestStarted.isCompleted) {
                    requestStarted.complete();
                    return pendingResponse.future;
                  }
                  return http.Response('{"mutationVersion":0}', 200);
                }
                registrations.add(
                  jsonDecode(body! as String) as Map<String, dynamic>,
                );
                return http.Response('{"success":true}', 200);
              };
          final blocker = readDefaultReminderSchedule(userInformation: user);
          await requestStarted.future;
          final refresh = id == 'default'
              ? repository.rescheduleDefaultReminder(user)
              : repository.rescheduleTextReminder(user, id, 'Drink water');
          await repository.setPreference(
            id,
            const NotificationPreference(hour: 21, minute: 15),
          );
          pendingResponse.complete(
            http.Response('{"mutationVersion":0,"schedule":null}', 200),
          );
          await blocker;
          expect(await refresh, isTrue);
          final request = registrations.single;
          expect(request['hour'], 21);
          expect(request['minute'], 15);
          expect(request['locale'], 'en');
          if (id == 'default') {
            expect(request, isNot(contains('staticBody')));
            expect(request, isNot(contains('staticTitle')));
          } else {
            expect(request['staticBody'], 'Drink water');
          }
        });
      }
    });

    group('cancelOtherReminders', () {
      late UserInformation userInformation;
      late List<({String path, Map<String, dynamic> body})> requests;

      setUp(() {
        final auth = MockFirebaseAuth();
        final firebaseUser = MockUser();
        when(auth.currentUser).thenReturn(firebaseUser);
        when(firebaseUser.isAnonymous).thenReturn(false);
        when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token-123');
        GetIt.instance.registerSingleton<FirebaseAuth>(auth);
        userInformation = UserInformation(
          service: memory,
          localeName: 'en',
          loggedIn: true,
          userId: 'account-a',
        );
        requests = [];
        FcmScheduledNotificationService.debugPostOverride =
            (url, {headers, body, encoding}) async {
              requests.add((
                path: url.path,
                body: jsonDecode(body! as String) as Map<String, dynamic>,
              ));
              return http.Response(
                url.path.endsWith('/getNotificationMutationVersion')
                    ? '{"mutationVersion":0}'
                    : '{"success":true,"mutationVersion":1}',
                200,
              );
            };
      });

      tearDown(() async {
        FcmScheduledNotificationService.resetForTesting();
        await GetIt.instance.reset();
      });

      test(
        'should fence every fixed quick ID for a default-only account',
        () async {
          await repository.setPreference(
            'default',
            const NotificationPreference(hour: 8, minute: 0),
          );
          expect(
            await repository.cancelOtherReminders(
              userInformation,
              repository.preferences,
            ),
            isTrue,
          );
          expect(requests, hasLength(2 * QuickReminderType.values.length));
          expect(
            requests
                .where(
                  (request) => request.path.endsWith('/cancelNotification'),
                )
                .map((request) => request.body['typeId']),
            QuickReminderType.values.map((type) => type.id),
          );
        },
      );

      test(
        'should cancel enabled, paused and unacknowledged custom IDs',
        () async {
          await repository.activateAccount('account-a');
          for (final id in ['default', 'quick_exercise', 'quick_water']) {
            await repository.setPreference(
              id,
              const NotificationPreference(hour: 8, minute: 0),
            );
          }
          await repository.clearPreferenceForAccountTransition('quick_water');
          for (final id in ['custom_enabled', 'custom_unacknowledged']) {
            await repository.setCustomReminder(
              CustomReminder(
                id: id,
                emoji: 'x',
                label: 'Practice',
                hour: 18,
                minute: 30,
              ),
            );
          }
          await repository.setPreference(
            'custom_enabled',
            const NotificationPreference(hour: 18, minute: 30),
          );

          expect(
            await repository.cancelOtherReminders(
              userInformation,
              repository.preferences,
            ),
            isTrue,
          );
          final cancellations = requests.where(
            (request) => request.path.endsWith('/cancelNotification'),
          );
          expect(cancellations.map((request) => request.body['typeId']), [
            ...QuickReminderType.values.map((type) => type.id),
            'custom_enabled',
            'custom_unacknowledged',
          ]);
          expect(
            requests,
            hasLength(2 * (QuickReminderType.values.length + 2)),
          );
          expect(
            cancellations.map((request) => request.body['resetFence']),
            everyElement(isTrue),
          );
        },
      );

      test(
        'should fence fixed IDs without cancelling another account custom paused ID',
        () async {
          await repository.activateAccount('account-b');
          await repository.setPreference(
            'custom_other_account',
            const NotificationPreference(hour: 8, minute: 0),
          );
          await repository.clearPreferenceForAccountTransition(
            'custom_other_account',
          );
          await repository.setSavedTime(
            'quick_exercise',
            const NotificationPreference(hour: 9, minute: 0),
          );
          expect(repository.pausedAccountRemindersFor('account-b'), isNotEmpty);

          expect(
            await repository.cancelOtherReminders(userInformation, const {}),
            isTrue,
          );
          expect(requests, hasLength(2 * QuickReminderType.values.length));
          expect(
            requests
                .where(
                  (request) => request.path.endsWith('/cancelNotification'),
                )
                .map((request) => request.body['typeId']),
            QuickReminderType.values.map((type) => type.id),
          );
        },
      );

      test('should cancel a quick registration committed before its response timed out', () async {
        final remoteSchedules = <String>{};
        final versions = <String, int>{};
        final cancelled = <String>[];
        FcmScheduledNotificationService
            .debugPostOverride = (url, {headers, body, encoding}) async {
          final request = jsonDecode(body! as String) as Map<String, dynamic>;
          final id = request['typeId'] as String;
          final version = versions[id] ?? 0;
          if (url.path.endsWith('/getNotificationMutationVersion')) {
            return http.Response(jsonEncode({'mutationVersion': version}), 200);
          }
          expect(request['expectedMutationVersion'], version);
          versions[id] = version + 1;
          if (url.path.endsWith('/registerNotification')) {
            remoteSchedules.add(id);
            throw TimeoutException('Registration response lost after commit');
          }
          expect(request['resetFence'], isTrue);
          remoteSchedules.remove(id);
          cancelled.add(id);
          return http.Response(
            jsonEncode({'success': true, 'mutationVersion': version + 1}),
            200,
          );
        };
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          expect(
            await registerTextReminder(
              userInformation: userInformation,
              typeId: 'quick_water',
              hour: 8,
              minute: 0,
              title: 'Living Positively',
              body: 'Drink water',
            ),
            isFalse,
          );
          expect(remoteSchedules, contains('quick_water'));
          expect(repository.preferences, isEmpty);
          expect(repository.pausedAccountRemindersFor('account-a'), isEmpty);
          expect(repository.customReminders, isEmpty);

          expect(
            await repository.cancelOtherReminders(
              userInformation,
              repository.preferences,
            ),
            isTrue,
          );
          expect(cancelled, contains('quick_water'));
          expect(remoteSchedules, isEmpty);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    });

    test('should retain valid saved entries and skip malformed entries', () {
      repository.restoreJson(
        '{"morning":{"hour":"7","minute":45},'
        '"invalid":{"hour":44,"minute":0}}',
      );
      expect(repository.preferences.keys, ['morning']);
      expect(repository.getPreference('morning')?.hour, 7);
      expect(repository.getPreference('invalid'), isNull);
    });

    test(
      'should keep legacy local time disabled without an FCM preference',
      () {
        repository.restoreJson(null);
        expect(repository.preferences, isEmpty);
      },
    );

    test('should serialize updates to the existing storage key', () async {
      memory.gate = Completer<void>();
      final first = repository.setPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      final second = repository.setPreference(
        'default',
        const NotificationPreference(hour: 9, minute: 30),
      );
      expect(memory.writes, isEmpty);
      memory.gate!.complete();
      await Future.wait([first, second]);
      expect(
        memory.writes.map(
          (value) =>
              (jsonDecode(value) as Map<String, dynamic>)['default']['hour'],
        ),
        [8, 9],
      );
    });

    test('should let a later write persist after an earlier failure', () async {
      memory.failNextWrite = true;
      await expectLater(
        repository.setPreference(
          'default',
          const NotificationPreference(hour: 8, minute: 15),
        ),
        throwsStateError,
      );
      await repository.clearPreference('default');
      expect(repository.getPreference('default'), isNull);
      final persisted =
          jsonDecode(memory.writes.single) as Map<String, dynamic>;
      expect(persisted.containsKey('default'), isFalse);
      expect(persisted['__defaultOptOut'], isTrue);
      expect(repository.getSavedTime('default')?.hour, 8);
    });

    test('keeps custom reminders and the explicit app opt-out', () async {
      await repository.setCustomReminder(
        const CustomReminder(
          id: 'custom_1',
          emoji: '🎵',
          label: 'Practice',
          hour: 18,
          minute: 30,
        ),
      );
      await repository.setUse24HourFormat(false);
      await repository.clearPreference('default');

      final restored = NotificationRepository.forService(_Memory())
        ..restoreJson(memory.writes.last);
      expect(restored.customReminders.single.label, 'Practice');
      expect(restored.use24HourFormat, isFalse);
      expect(restored.defaultOptOut, isTrue);
    });

    test('migrates a legacy disabled default without enabling it', () {
      repository.restoreJson('{}');
      expect(repository.defaultOptOut, isTrue);
      repository.restoreJson('{"default":{"hour":7,"minute":30}}');
      expect(repository.defaultOptOut, isFalse);
      repository.restoreJson(null);
      expect(repository.defaultOptOut, isFalse);
    });

    test(
      'sign-out cancellation preserves default choice but clears its time',
      () async {
        await repository.setPreference(
          'default',
          const NotificationPreference(hour: 9, minute: 15),
        );
        await repository.clearPreferenceForAccountTransition('default');
        expect(repository.defaultOptOut, isFalse);
        expect(repository.getPreference('default'), isNull);
        expect(repository.getSavedTime('default'), isNull);
        final restored = NotificationRepository.forService(_Memory())
          ..restoreJson(memory.writes.last);
        expect(restored.defaultOptOut, isFalse);
      },
    );

    test(
      'account transition retains quick and custom choices for sign-in',
      () async {
        const quick = NotificationPreference.withContent(
          hour: 9,
          minute: 25,
          staticTitle: 'Living Positively',
          staticBody: 'Exercise',
        );
        const custom = NotificationPreference.withContent(
          hour: 18,
          minute: 40,
          staticTitle: 'Living Positively',
          staticBody: 'Practice',
        );
        await repository.setPreference('quick_exercise', quick);
        await repository.setPreference('custom_1', custom);
        await repository.setCustomReminder(
          const CustomReminder(
            id: 'custom_1',
            emoji: '🎵',
            label: 'Practice',
            hour: 18,
            minute: 40,
          ),
        );
        await repository.activateAccount('account-a');
        await repository.clearPreferenceForAccountTransition('quick_exercise');
        await repository.clearPreferenceForAccountTransition('custom_1');

        final accountMemory = _Memory();
        final restored = NotificationRepository.forService(accountMemory)
          ..restoreJson(memory.writes.last);
        expect(restored.getPreference('quick_exercise'), isNull);
        expect(restored.getPreference('custom_1'), isNull);
        expect(restored.getSavedTime('quick_exercise')?.hour, 9);
        expect(restored.getSavedTime('custom_1')?.minute, 40);
        expect(restored.pausedAccountRemindersFor('account-b'), isEmpty);
        expect(
          restored.pausedAccountRemindersFor('account-a').keys,
          containsAll([
            'quick_exercise',
            'custom_1',
          ]),
        );

        await restored.activateAccount('account-b');
        expect(restored.preferences, isEmpty);
        expect(restored.customReminders, isEmpty);
        expect(restored.getSavedTime('quick_exercise'), isNull);
        expect(restored.pausedAccountRemindersFor('account-b'), isEmpty);
        final reloaded = NotificationRepository.forService(_Memory())
          ..restoreJson(accountMemory.writes.last);
        await reloaded.activateAccount('account-a');
        expect(reloaded.customReminders.single.label, 'Practice');
        expect(reloaded.pausedAccountRemindersFor('account-a').length, 2);

        await reloaded.clearPausedAccountReminder('quick_exercise');
        expect(reloaded.pausedAccountRemindersFor('account-a').keys, [
          'custom_1',
        ]);
        await reloaded.clearPreference('custom_1');
        expect(reloaded.pausedAccountRemindersFor('account-a'), isEmpty);
      },
    );

    test('a new enabled choice replaces its paused time and text', () async {
      await repository.activateAccount('account-a');
      await repository.setPreference(
        'quick_exercise',
        const NotificationPreference.withContent(
          hour: 8,
          minute: 0,
          staticTitle: 'Living Positively',
          staticBody: 'Exercise',
        ),
      );
      await repository.clearPreferenceForAccountTransition('quick_exercise');
      expect(repository.pausedAccountRemindersFor('account-a'), isNotEmpty);

      await repository.setPreference(
        'quick_exercise',
        const NotificationPreference.withContent(
          hour: 21,
          minute: 15,
          staticTitle: 'Living Positively',
          staticBody: 'New choice',
        ),
      );

      expect(repository.pausedAccountRemindersFor('account-a'), isEmpty);
      expect(repository.getSavedTime('quick_exercise')?.hour, 21);
      final saved = jsonDecode(memory.writes.last) as Map<String, dynamic>;
      expect(saved['__savedTimes'], isNot(contains('quick_exercise')));
      expect(saved['__pausedAccountReminders'], isEmpty);
    });

    test(
      'restores quick text in the current language and custom text as saved',
      () async {
        final auth = MockFirebaseAuth();
        final firebaseUser = MockUser();
        when(auth.currentUser).thenReturn(firebaseUser);
        when(firebaseUser.isAnonymous).thenReturn(false);
        when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token-123');
        GetIt.instance.registerSingleton<FirebaseAuth>(auth);
        final registrations = <Map<String, dynamic>>[];
        FcmScheduledNotificationService.debugPostOverride =
            (url, {headers, body, encoding}) async {
              if (url.path.endsWith('/getNotificationMutationVersion')) {
                return http.Response('{"mutationVersion":0}', 200);
              }
              registrations.add(
                jsonDecode(body! as String) as Map<String, dynamic>,
              );
              return http.Response('{"success":true,"mutationVersion":1}', 200);
            };
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final restored = await repository.restoreSchedules(
            UserInformation(
              service: memory,
              localeName: 'he',
              loggedIn: true,
              userId: 'account-a',
            ),
            {
              'quick_exercise': const NotificationPreference.withContent(
                hour: 9,
                minute: 0,
                staticTitle: 'Living Positively',
                staticBody: 'Exercise',
              ),
              'custom_1': const NotificationPreference.withContent(
                hour: 20,
                minute: 0,
                staticTitle: 'Living Positively',
                staticBody: 'My custom text',
              ),
            },
          );
          expect(restored, isTrue);
          expect(registrations[0]['staticBody'], 'פעילות גופנית');
          expect(registrations[1]['staticBody'], 'My custom text');
        } finally {
          debugDefaultTargetPlatformOverride = null;
          FcmScheduledNotificationService.resetForTesting();
          await GetIt.instance.reset();
        }
      },
    );

    test(
      'continues restoring after a reminder reaches the server limit',
      () async {
        final auth = MockFirebaseAuth();
        final firebaseUser = MockUser();
        when(auth.currentUser).thenReturn(firebaseUser);
        when(firebaseUser.isAnonymous).thenReturn(false);
        when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token-123');
        GetIt.instance.registerSingleton<FirebaseAuth>(auth);
        final registrations = <String>[];
        FcmScheduledNotificationService
            .debugPostOverride = (url, {headers, body, encoding}) async {
          final request = jsonDecode(body! as String) as Map<String, dynamic>;
          if (url.path.endsWith('/getNotificationMutationVersion')) {
            return http.Response('{"mutationVersion":0}', 200);
          }
          final id = request['typeId'] as String;
          registrations.add(id);
          return http.Response(
            id == 'quick_exercise'
                ? '{"error":"REMINDER_LIMIT_REACHED"}'
                : '{"success":true,"mutationVersion":1}',
            id == 'quick_exercise' ? 429 : 200,
          );
        };
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final restored = await repository.restoreSchedules(
            UserInformation(
              service: memory,
              localeName: 'en',
              loggedIn: true,
              userId: 'account-a',
            ),
            {
              for (final id in ['quick_exercise', 'quick_water'])
                id: const NotificationPreference.withContent(
                  hour: 9,
                  minute: 0,
                  staticTitle: 'Living Positively',
                  staticBody: 'Reminder',
                ),
            },
          );
          expect(restored, isFalse);
          expect(registrations, ['quick_exercise', 'quick_water']);
        } finally {
          debugDefaultTargetPlatformOverride = null;
          FcmScheduledNotificationService.resetForTesting();
          await GetIt.instance.reset();
        }
      },
    );

    test(
      'skips a paused entry replaced while another reminder restores',
      () async {
        await repository.activateAccount('account-a');
        for (final id in ['quick_exercise', 'quick_water', 'quick_pills']) {
          await repository.setPreference(
            id,
            const NotificationPreference.withContent(
              hour: 8,
              minute: 0,
              staticTitle: 'Living Positively',
              staticBody: 'Old text',
            ),
          );
          await repository.clearPreferenceForAccountTransition(id);
        }
        final auth = MockFirebaseAuth();
        final firebaseUser = MockUser();
        when(auth.currentUser).thenReturn(firebaseUser);
        when(firebaseUser.isAnonymous).thenReturn(false);
        when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token-123');
        GetIt.instance.registerSingleton<FirebaseAuth>(auth);
        final firstStarted = Completer<void>();
        final firstResponse = Completer<http.Response>();
        final registrations = <({String id, int hour})>[];
        FcmScheduledNotificationService
            .debugPostOverride = (url, {headers, body, encoding}) async {
          if (url.path.endsWith('/getNotificationMutationVersion')) {
            return http.Response('{"mutationVersion":0}', 200);
          }
          final request = jsonDecode(body! as String) as Map<String, dynamic>;
          final id = request['typeId'] as String;
          registrations.add((id: id, hour: request['hour'] as int));
          if (id == 'quick_exercise') {
            firstStarted.complete();
            return firstResponse.future;
          }
          return http.Response('{"success":true,"mutationVersion":1}', 200);
        };
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final pending = repository.resumePausedReminders(
            UserInformation(
              service: memory,
              localeName: 'en',
              loggedIn: true,
              userId: 'account-a',
            ),
          );
          await firstStarted.future;
          await repository.setPreference(
            'quick_water',
            const NotificationPreference.withContent(
              hour: 21,
              minute: 15,
              staticTitle: 'Living Positively',
              staticBody: 'New text',
            ),
          );
          await repository.setSavedTime(
            'quick_pills',
            const NotificationPreference.withContent(
              hour: 21,
              minute: 30,
              staticTitle: 'Living Positively',
              staticBody: 'Old text',
            ),
          );
          firstResponse.complete(
            http.Response('{"success":true,"mutationVersion":1}', 200),
          );
          expect(await pending, isTrue);
          expect(registrations, [
            (id: 'quick_exercise', hour: 8),
            (id: 'quick_pills', hour: 21),
          ]);
          expect(repository.getPreference('quick_water')?.hour, 21);
        } finally {
          debugDefaultTargetPlatformOverride = null;
          FcmScheduledNotificationService.resetForTesting();
          await GetIt.instance.reset();
        }
      },
    );

    test('restores an existing emoji label accepted by the server', () async {
      final label = List.filled(60, '🙂').join();
      expect(label.length, 120);
      await repository.setCustomReminder(
        CustomReminder(
          id: 'custom_emoji',
          emoji: '🎵',
          label: label,
          hour: 8,
          minute: 0,
        ),
      );
      final restored = NotificationRepository.forService(_Memory())
        ..restoreJson(memory.writes.last);
      expect(restored.customReminders.single.label, label);
    });

    test(
      'registration rollback preserves default consent and chosen time',
      () async {
        await repository.setSavedTime(
          'default',
          const NotificationPreference(hour: 10, minute: 20),
        );
        memory.failNextWrite = true;
        await expectLater(
          repository.setPreference(
            'default',
            const NotificationPreference(hour: 8, minute: 0),
          ),
          throwsStateError,
        );
        await repository.clearPreferenceAfterFailedRegistration(
          'default',
          previousDefaultOptOut: false,
        );
        expect(repository.defaultOptOut, isFalse);
        expect(repository.getPreference('default'), isNull);
        expect(repository.getSavedTime('default')?.hour, 10);
        final restored = NotificationRepository.forService(_Memory())
          ..restoreJson(memory.writes.last);
        expect(restored.defaultOptOut, isFalse);
        expect(restored.getSavedTime('default')?.minute, 20);
      },
    );

    test(
      'registration rollback preserves an existing default opt-out',
      () async {
        await repository.clearPreference('default');
        expect(repository.defaultOptOut, isTrue);
        memory.failNextWrite = true;
        await expectLater(
          repository.setPreference(
            'default',
            const NotificationPreference(hour: 8, minute: 0),
          ),
          throwsStateError,
        );
        await repository.clearPreferenceAfterFailedRegistration(
          'default',
          previousDefaultOptOut: true,
        );
        expect(repository.defaultOptOut, isTrue);
        expect(repository.getPreference('default'), isNull);
        final restored = NotificationRepository.forService(_Memory())
          ..restoreJson(memory.writes.last);
        expect(restored.defaultOptOut, isTrue);
      },
    );

    test('editing a custom reminder keeps its saved list position', () async {
      for (final id in ['a', 'b', 'c']) {
        await repository.setCustomReminder(
          CustomReminder(
            id: 'custom_$id',
            emoji: '🎵',
            label: id,
            hour: 8,
            minute: 0,
          ),
        );
      }
      await repository.setCustomReminder(
        const CustomReminder(
          id: 'custom_a',
          emoji: '🎵',
          label: 'a',
          hour: 9,
          minute: 30,
        ),
      );
      final restored = NotificationRepository.forService(_Memory())
        ..restoreJson(memory.writes.last);
      expect(restored.customReminders.map((item) => item.id), [
        'custom_a',
        'custom_b',
        'custom_c',
      ]);
      expect(restored.customReminders.first.hour, 9);
    });
  });
}
