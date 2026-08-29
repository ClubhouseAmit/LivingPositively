import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_controller.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_insights.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_store.dart';

import '../../test_support/contract_persistent_memory_service.dart';

MoodMedicineEntry _entry({
  required String id,
  required String dayKey,
  required int mood,
  Iterable<String> activityIds = const <String>[],
}) => MoodMedicineEntry(
  id: id,
  occurredAtUtc: DateTime.parse('${dayKey}T12:00:00Z'),
  localDayKey: dayKey,
  mood: mood,
  activityIds: activityIds,
);

void main() {
  group('MoodMedicineStore', () {
    test(
      'decodes a versioned snapshot and drops malformed nested records',
      () async {
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: jsonEncode(<String, Object>{
                  'version': moodMedicineSnapshotVersion,
                  'hiddenDefaultActivityIds': <Object>[
                    'physical_activity',
                    'not-a-default',
                  ],
                  'customActivities': <Object>[
                    <String, Object>{'id': 'walk', 'label': 'Walk'},
                    <String, Object>{'id': '', 'label': 'Ignored'},
                  ],
                  'entries': <Object>[
                    <String, Object>{
                      'id': 'entry-1',
                      'occurredAtUtc': '2026-08-29T08:00:00Z',
                      'localDayKey': '2026-08-29',
                      'mood': 4,
                      'emotionIds': <String>['calm'],
                      'activityIds': <String>['walk'],
                      'customActivityLabelSnapshots': <String, String>{
                        'walk': 'Walk',
                      },
                    },
                    <String, Object>{
                      'id': 'broken',
                      'occurredAtUtc': 'not-a-date',
                      'localDayKey': '2026-08-29',
                      'mood': 3,
                    },
                  ],
                }),
              },
            );

        final MoodMedicineSnapshot snapshot = await MoodMedicineStore(
          memory,
        ).load();

        expect(snapshot.version, moodMedicineSnapshotVersion);
        expect(snapshot.hiddenDefaultActivityIds, <String>{
          'physical_activity',
        });
        expect(snapshot.customActivities.single.label, 'Walk');
        expect(snapshot.entries, hasLength(1));
        expect(
          snapshot.entries.single.customActivityLabelSnapshots,
          <String, String>{'walk': 'Walk'},
        );
      },
    );

    test('treats malformed or unsupported snapshots as empty', () async {
      final ContractPersistentMemoryService malformed =
          ContractPersistentMemoryService(
            initialValues: <String, Object?>{
              MoodMedicineStore.snapshotKey: '{not-json',
            },
          );
      final ContractPersistentMemoryService unsupported =
          ContractPersistentMemoryService(
            initialValues: <String, Object?>{
              MoodMedicineStore.snapshotKey: jsonEncode(<String, int>{
                'version': moodMedicineSnapshotVersion + 1,
              }),
            },
          );

      expect((await MoodMedicineStore(malformed).load()).entries, isEmpty);
      expect((await MoodMedicineStore(unsupported).load()).entries, isEmpty);
    });
  });

  group('MoodMedicineController', () {
    test(
      'persists one atomic versioned snapshot after an awaited check-in',
      () async {
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService();
        final MoodMedicineController controller = MoodMedicineController(
          MoodMedicineStore(memory),
          idGenerator: () => 'entry-1',
        );
        await controller.load();

        final bool saved = await controller.saveCheckIn(
          MoodMedicineCheckInDraft(
            mood: 5,
            emotionIds: <String>['joy'],
            activityIds: <String>['physical_activity'],
            note: '  A good walk.  ',
          ),
          occurredAt: DateTime(2026, 8, 29, 9),
        );

        final String stored =
            memory.durableStore[MoodMedicineStore.snapshotKey]! as String;
        final Map<String, dynamic> payload =
            jsonDecode(stored) as Map<String, dynamic>;
        final Map<String, dynamic> entry =
            (payload['entries'] as List<dynamic>).single
                as Map<String, dynamic>;
        expect(saved, isTrue);
        expect(payload['version'], moodMedicineSnapshotVersion);
        expect(entry['id'], 'entry-1');
        expect(entry['localDayKey'], '2026-08-29');
        expect(entry['note'], 'A good walk.');
        expect(entry['occurredAtUtc'], endsWith('Z'));
        expect(memory.completedWrites, hasLength(1));
      },
    );

    test(
      'keeps the check-in draft and exact snapshot for retry after a save failure',
      () async {
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService();
        bool failNextWrite = true;
        memory.onPersist = (_, _, _) {
          if (failNextWrite) {
            failNextWrite = false;
            throw StateError('disk unavailable');
          }
        };
        final MoodMedicineController controller = MoodMedicineController(
          MoodMedicineStore(memory),
          idGenerator: () => 'entry-1',
        );
        await controller.load();
        final MoodMedicineCheckInDraft draft = MoodMedicineCheckInDraft(
          mood: 3,
          activityIds: <String>['music'],
        );

        expect(
          await controller.saveCheckIn(
            draft,
            occurredAt: DateTime(2026, 8, 29, 10),
          ),
          isFalse,
        );
        expect(controller.entries, isEmpty);
        expect(controller.pendingCheckInDraft, same(draft));
        expect(controller.persistenceError, isA<StateError>());
        expect(controller.hasPendingWrite, isTrue);

        expect(await controller.retryLastWrite(), isTrue);
        expect(controller.entries, hasLength(1));
        expect(controller.pendingCheckInDraft, isNull);
        expect(controller.persistenceError, isNull);
        expect(memory.completedWrites, hasLength(1));
      },
    );

    test(
      'prompts only until a check-in is saved for the current local day',
      () async {
        final MoodMedicineController controller = MoodMedicineController(
          MoodMedicineStore(ContractPersistentMemoryService()),
          idGenerator: () => 'entry-1',
        );
        final DateTime today = DateTime(2026, 8, 29, 9);
        await controller.load();

        expect(controller.shouldPromptFor(today), isTrue);
        await controller.saveCheckIn(
          MoodMedicineCheckInDraft(mood: 4),
          occurredAt: today,
        );
        expect(controller.shouldPromptFor(today), isFalse);
        expect(controller.shouldPromptFor(DateTime(2026, 8, 30, 9)), isTrue);
      },
    );

    test(
      'retains a custom activity label in historical entries after edit and delete',
      () async {
        final List<String> ids = <String>['custom-1', 'entry-1'];
        final MoodMedicineController controller = MoodMedicineController(
          MoodMedicineStore(ContractPersistentMemoryService()),
          idGenerator: () => ids.removeAt(0),
        );
        await controller.load();

        final MoodMedicineCustomActivity custom = (await controller
            .addCustomActivity('  Evening walk  '))!;
        await controller.saveCheckIn(
          MoodMedicineCheckInDraft(mood: 4, activityIds: <String>[custom.id]),
          occurredAt: DateTime(2026, 8, 29, 20),
        );
        await controller.editCustomActivity(custom.id, 'Morning walk');
        await controller.deleteCustomActivity(custom.id);

        expect(controller.customActivities, isEmpty);
        expect(
          controller.entries.single.customActivityLabelSnapshots[custom.id],
          'Evening walk',
        );
        expect(controller.entries.single.activityIds, contains(custom.id));
      },
    );
  });

  group('MoodMedicineInsights', () {
    test(
      'aggregates multiple check-ins into one daily mean and activity union',
      () {
        final List<MoodMedicineDailySummary> summaries =
            MoodMedicineInsights.dailySummaries(<MoodMedicineEntry>[
              _entry(
                id: 'one',
                dayKey: '2026-08-28',
                mood: 1,
                activityIds: <String>['music'],
              ),
              _entry(
                id: 'two',
                dayKey: '2026-08-28',
                mood: 5,
                activityIds: <String>['social_connection'],
              ),
            ]);

        expect(summaries, hasLength(1));
        expect(summaries.single.averageMood, 3);
        expect(summaries.single.checkInCount, 2);
        expect(summaries.single.activityIds, <String>{
          'music',
          'social_connection',
        });
      },
    );

    test(
      'reports only associations with three days both with and without an activity',
      () {
        final List<MoodMedicineEntry> entries = <MoodMedicineEntry>[
          _entry(
            id: '1',
            dayKey: '2026-08-01',
            mood: 5,
            activityIds: <String>['physical_activity', 'too_sparse'],
          ),
          _entry(
            id: '2',
            dayKey: '2026-08-02',
            mood: 4,
            activityIds: <String>['physical_activity', 'too_sparse'],
          ),
          _entry(
            id: '3',
            dayKey: '2026-08-03',
            mood: 3,
            activityIds: <String>['physical_activity'],
          ),
          _entry(id: '4', dayKey: '2026-08-04', mood: 1),
          _entry(id: '5', dayKey: '2026-08-05', mood: 2),
          _entry(id: '6', dayKey: '2026-08-06', mood: 2),
        ];

        final List<MoodMedicineAssociation> associations =
            MoodMedicineInsights.associations(
              MoodMedicineInsights.dailySummaries(entries),
            );

        expect(associations, hasLength(1));
        expect(associations.single.activityId, 'physical_activity');
        expect(associations.single.withActivityDays, 3);
        expect(associations.single.withoutActivityDays, 3);
        expect(associations.single.withActivityAverageMood, 4);
        expect(
          associations.single.averageMoodDifference,
          closeTo(7 / 3, 0.0001),
        );
      },
    );
  });
}
