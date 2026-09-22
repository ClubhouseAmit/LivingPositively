import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';

final class _Memory implements PersistentMemoryService {
  final writes = <String>[];
  Completer<void>? gate;
  bool failNextWrite = false;

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
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
  Future<dynamic> getItem(String key, PersistentMemoryType type) async => null;

  @override
  Future<Map<String, Object?>> readSnapshot(
    Map<String, PersistentMemoryType> keys,
  ) async => const {};

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
      expect(memory.writes, [
        '{"default":{"hour":8,"minute":15}}',
        '{"default":{"hour":9,"minute":30}}',
      ]);
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
      expect(memory.writes, ['{}']);
    });
  });
}
