import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_repository.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_store.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_insights.dart';

import '../../../test_support/contract_persistent_memory_service.dart';

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
      'should reject an entire snapshot containing a malformed record',
      () async {
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: jsonEncode(<String, Object>{
                  'version': moodMedicineSnapshotVersion,
                  'hiddenDefaultActivityIds': <String>['physical_activity'],
                  'customActivities': <Object>[
                    <String, Object>{'id': 'walk', 'label': 'Walk'},
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
                      'emotionIds': <String>[],
                      'activityIds': <String>[],
                    },
                  ],
                }),
              },
            );

        final MoodMedicineLoadResult result = await MoodMedicineStore(
          memory,
        ).loadSnapshot();

        expect(result, isA<MoodMedicineUnreadableSnapshot>());
        expect(
          (result as MoodMedicineUnreadableSnapshot).failure.kind,
          MoodMedicineLoadFailureKind.malformedRecord,
        );
        expect(memory.attemptedWrites, isEmpty);
      },
    );

    test(
      'should reject forged default activity label snapshots without writing',
      () async {
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: jsonEncode(<String, Object>{
                  'version': moodMedicineSnapshotVersion,
                  'hiddenDefaultActivityIds': <String>[],
                  'customActivities': <Object>[],
                  'entries': <Object>[
                    <String, Object>{
                      'id': 'entry-1',
                      'occurredAtUtc': '2026-08-29T08:00:00Z',
                      'localDayKey': '2026-08-29',
                      'mood': 4,
                      'emotionIds': <String>[],
                      'activityIds': <String>['physical_activity'],
                      'customActivityLabelSnapshots': <String, String>{
                        'physical_activity': 'Forged label',
                      },
                    },
                  ],
                }),
              },
            );

        final MoodMedicineLoadResult result = await MoodMedicineStore(
          memory,
        ).loadSnapshot();

        expect(result, isA<MoodMedicineUnreadableSnapshot>());
        expect(
          (result as MoodMedicineUnreadableSnapshot).failure.kind,
          MoodMedicineLoadFailureKind.malformedRecord,
        );
        expect(memory.attemptedWrites, isEmpty);
      },
    );

    test(
      'should reject default activity labels during snapshot construction',
      () {
        expect(
          () => MoodMedicineSnapshot(
            entries: <MoodMedicineEntry>[
              MoodMedicineEntry(
                id: 'entry-1',
                occurredAtUtc: DateTime.utc(2026, 8, 29, 8),
                localDayKey: '2026-08-29',
                mood: 4,
                activityIds: const <String>['physical_activity'],
                customActivityLabelSnapshots: const <String, String>{
                  'physical_activity': 'Forged label',
                },
              ),
            ],
          ),
          throwsArgumentError,
        );
      },
    );

    test('should distinguish malformed and unsupported snapshots', () async {
      final ContractPersistentMemoryService malformed =
          ContractPersistentMemoryService(
            initialValues: <String, Object?>{
              MoodMedicineStore.snapshotKey: '{not-json',
            },
          );
      final ContractPersistentMemoryService unsupported =
          ContractPersistentMemoryService(
            initialValues: <String, Object?>{
              MoodMedicineStore.snapshotKey: jsonEncode(<String, Object>{
                'version': moodMedicineSnapshotVersion + 1,
              }),
            },
          );

      final MoodMedicineLoadResult malformedResult = await MoodMedicineStore(
        malformed,
      ).loadSnapshot();
      final MoodMedicineLoadResult unsupportedResult = await MoodMedicineStore(
        unsupported,
      ).loadSnapshot();

      expect(
        (malformedResult as MoodMedicineUnreadableSnapshot).failure.kind,
        MoodMedicineLoadFailureKind.malformedEnvelope,
      );
      expect(
        (unsupportedResult as MoodMedicineUnreadableSnapshot).failure.kind,
        MoodMedicineLoadFailureKind.unsupportedVersion,
      );
    });

    test('should decode a complete version-one snapshot', () async {
      final ContractPersistentMemoryService memory =
          ContractPersistentMemoryService(
            initialValues: <String, Object?>{
              MoodMedicineStore.snapshotKey: MoodMedicineSnapshot(
                hiddenDefaultActivityIds: const <String>['physical_activity'],
              ).encode(),
            },
          );

      final MoodMedicineLoadResult result = await MoodMedicineStore(
        memory,
      ).loadSnapshot();

      expect(result, isA<MoodMedicineLoadedSnapshot>());
      expect(
        (result as MoodMedicineLoadedSnapshot)
            .snapshot
            .hiddenDefaultActivityIds,
        <String>{'physical_activity'},
      );
    });
  });

  group('MoodMedicineInsights', () {
    test(
      'should aggregate multiple check-ins into one daily mean and union',
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

    test('should report associations only after three days on both sides', () {
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
      expect(associations.single.averageMoodDifference, closeTo(7 / 3, 0.0001));
    });
  });
}
