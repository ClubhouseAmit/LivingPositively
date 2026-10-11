import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/notifications/data/notification_preferences_storage.dart';
import 'package:mazilon/util/async/global_enums.dart';

import '../../../../test_support/contract_persistent_memory_service.dart';

const String _primaryKey = 'notificationPreferences';
const String _copyKey = 'notificationReminderSettings';

final class _Memory extends ContractPersistentMemoryService {
  _Memory({Map<String, Object?>? initialValues, this.failCopyWrite = false})
    : super(initialValues: initialValues) {
    onMissingRead = (_, _) => null;
    onPersist = (key, _, _) {
      if (failCopyWrite && key == _copyKey) {
        throw StateError('copy storage unavailable');
      }
    };
  }

  final bool failCopyWrite;
}

Map<String, dynamic> _decode(String? encoded) =>
    jsonDecode(encoded!) as Map<String, dynamic>;

void main() {
  group('persistNotificationSnapshot', () {
    test('writes the snapshot to the primary key and its copy', () async {
      final memory = _Memory();

      await persistNotificationSnapshot(memory, '{"a":1}');

      expect(memory.durableStore[_primaryKey], '{"a":1}');
      expect(memory.durableStore[_copyKey], '{"a":1}');
    });

    test('restores the previous primary value when the copy fails', () async {
      final memory = _Memory(
        initialValues: <String, Object?>{_primaryKey: '{"old":true}'},
        failCopyWrite: true,
      );

      await expectLater(
        persistNotificationSnapshot(memory, '{"new":true}'),
        throwsStateError,
      );

      expect(memory.durableStore[_primaryKey], '{"old":true}');
      expect(memory.durableStore.containsKey(_copyKey), isFalse);
    });

    test('restores an empty object when no primary value existed', () async {
      final memory = _Memory(failCopyWrite: true);

      await expectLater(
        persistNotificationSnapshot(memory, '{"new":true}'),
        throwsStateError,
      );

      expect(memory.durableStore[_primaryKey], '{}');
    });

    test('reads the primary key as a string', () async {
      final memory = _Memory();
      final requested = <PersistentMemoryType>[];
      memory.onRead = (key, type) {
        if (key == _primaryKey) requested.add(type);
      };

      await persistNotificationSnapshot(memory, '{}');

      expect(requested, <PersistentMemoryType>[PersistentMemoryType.String]);
    });
  });

  group('mergeNotificationSnapshots', () {
    for (final expanded in <String?>[null, '']) {
      test('returns legacy unchanged when expanded is ${expanded ?? 'null'}', () {
        const legacy = '{"default":{"hour":7,"minute":0}}';

        expect(mergeNotificationSnapshots(legacy, expanded), same(legacy));
        expect(mergeNotificationSnapshots(null, expanded), isNull);
      });
    }

    test('returns legacy unchanged when it already has custom reminders', () {
      const legacy = '{"__customReminders":[]}';

      expect(
        mergeNotificationSnapshots(legacy, '{"quick_water":{"hour":9}}'),
        same(legacy),
      );
    });

    test('throws when legacy is valid JSON but not an object', () {
      expect(
        () => mergeNotificationSnapshots('[]', '{}'),
        throwsFormatException,
      );
    });

    for (final corrupt in <String>['{broken', '[]', '"text"']) {
      test('returns legacy when expanded is not an object: $corrupt', () {
        const legacy = '{"default":{"hour":7,"minute":0}}';

        expect(mergeNotificationSnapshots(legacy, corrupt), same(legacy));
      });
    }

    test('returns legacy when expanded has an invalid owner', () {
      const legacy = '{"default":{"hour":7,"minute":0}}';

      expect(
        mergeNotificationSnapshots(legacy, '{"__activeAccountUid":""}'),
        same(legacy),
      );
    });

    for (final owner in <Map<String, Object>>[
      {'__activeAccountUid': 'account-a'},
      {'__pausedAccountOwnerUid': 'account-a'},
      {
        '__accountSnapshots': {'account-a': '{}'},
      },
    ]) {
      test('returns expanded unchanged when owned by another account $owner', () {
        final expanded = jsonEncode(<String, Object>{
          'quick_water': {'hour': 9, 'minute': 0},
          ...owner,
        });

        expect(
          mergeNotificationSnapshots('{"default":{"hour":7}}', expanded),
          same(expanded),
        );
      });
    }

    test('merges same-owner entries field by field, legacy winning', () {
      final merged = _decode(
        mergeNotificationSnapshots(
          '{"__activeAccountUid":"account-a",'
              '"quick_water":{"hour":21,"minute":30}}',
          '{"__activeAccountUid":"account-a",'
              '"quick_water":{"hour":9,"minute":0,"staticTitle":"Water"}}',
        ),
      );

      expect(merged['quick_water'], <String, Object>{
        'hour': 21,
        'minute': 30,
        'staticTitle': 'Water',
      });
      expect(merged['__activeAccountUid'], 'account-a');
    });

    test('keeps expanded-only entries and adds legacy-only entries', () {
      final merged = _decode(
        mergeNotificationSnapshots(
          '{"quick_walk":{"hour":18,"minute":0}}',
          '{"custom_1":{"hour":8,"minute":0}}',
        ),
      );

      expect(merged['custom_1'], <String, Object>{'hour': 8, 'minute': 0});
      expect(merged['quick_walk'], <String, Object>{'hour': 18, 'minute': 0});
    });

    test('ignores legacy metadata keys and non-map entries', () {
      final merged = _decode(
        mergeNotificationSnapshots(
          '{"__use24HourFormat":true,"quick_walk":5}',
          '{"__use24HourFormat":false}',
        ),
      );

      expect(merged['__use24HourFormat'], isFalse);
      expect(merged.containsKey('quick_walk'), isFalse);
    });

    test('takes the default reminder from legacy, not expanded', () {
      final merged = _decode(
        mergeNotificationSnapshots(
          '{"default":{"hour":7,"minute":45}}',
          '{"default":{"hour":8,"minute":0}}',
        ),
      );

      expect(merged['default'], <String, Object>{'hour': 7, 'minute': 45});
      expect(merged['__defaultOptOut'], isFalse);
    });

    test('marks the default opted out when legacy has no default', () {
      final merged = _decode(
        mergeNotificationSnapshots(null, '{"default":{"hour":8,"minute":0}}'),
      );

      expect(merged.containsKey('default'), isFalse);
      expect(merged['__defaultOptOut'], isTrue);
    });

    test('drops a legacy default when legacy explicitly opts out', () {
      final merged = _decode(
        mergeNotificationSnapshots(
          '{"__defaultOptOut":true,"default":{"hour":7,"minute":0}}',
          '{}',
        ),
      );

      expect(merged.containsKey('default'), isFalse);
      expect(merged['__defaultOptOut'], isTrue);
    });
  });
}
