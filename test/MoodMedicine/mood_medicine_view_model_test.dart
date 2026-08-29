import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_insights.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_exporter.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_repository.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_store.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_view_model.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_view_state.dart';

import '../../test_support/contract_persistent_memory_service.dart';

final class _Repository implements MoodMedicineRepository {
  _Repository(
    this.result, {
    this.failNextSave = false,
    this.saveGate,
    this.nextMutationResult,
  });

  MoodMedicineLoadResult result;
  bool failNextSave;
  Completer<void>? saveGate;
  MoodMedicineLoadResult? nextMutationResult;
  int loadCount = 0;
  int saveCount = 0;
  final List<MoodMedicineSnapshot> receivedSnapshots = <MoodMedicineSnapshot>[];

  @override
  Future<MoodMedicineLoadResult> loadSnapshot() async {
    loadCount += 1;
    return result;
  }

  @override
  Future<MoodMedicineLoadResult> mutateSnapshot(
    MoodMedicineSnapshotMutation mutation,
  ) async {
    final MoodMedicineLoadResult currentResult = result;
    if (currentResult is MoodMedicineUnreadableSnapshot) {
      return currentResult;
    }
    final MoodMedicineSnapshot currentSnapshot = switch (currentResult) {
      MoodMedicineMissingSnapshot() => const MoodMedicineSnapshot.empty(),
      MoodMedicineLoadedSnapshot(:final MoodMedicineSnapshot snapshot) =>
        snapshot,
      MoodMedicineUnreadableSnapshot() => throw StateError(
        'Unreadable snapshots return before mutation.',
      ),
    };
    final MoodMedicineSnapshot snapshot = mutation(currentSnapshot);
    saveCount += 1;
    receivedSnapshots.add(snapshot);
    final Completer<void>? pendingSave = saveGate;
    if (pendingSave != null) {
      await pendingSave.future;
      saveGate = null;
    }
    if (failNextSave) {
      failNextSave = false;
      throw StateError('storage unavailable');
    }
    final MoodMedicineLoadResult? override = nextMutationResult;
    if (override != null) {
      nextMutationResult = null;
      result = override;
      return override;
    }
    result = MoodMedicineLoadedSnapshot(snapshot);
    return result;
  }

  @override
  Future<MoodMedicineLoadResult> discardUnreadableSnapshot() async {
    if (result is! MoodMedicineUnreadableSnapshot) {
      return result;
    }
    const MoodMedicineSnapshot snapshot = MoodMedicineSnapshot.empty();
    saveCount += 1;
    receivedSnapshots.add(snapshot);
    final Completer<void>? pendingSave = saveGate;
    if (pendingSave != null) {
      await pendingSave.future;
      saveGate = null;
    }
    if (failNextSave) {
      failNextSave = false;
      throw StateError('storage unavailable');
    }
    result = const MoodMedicineLoadedSnapshot(snapshot);
    return result;
  }
}

final class _ReportExporter implements MoodMedicineReportExportService {
  MoodMedicineReportInput? latestInput;
  MoodMedicineBuiltReport? latestReport;

  @override
  Future<MoodMedicineBuiltReport> build(
    MoodMedicineReportInput input,
    MoodMedicineReportFormat format,
  ) async {
    latestInput = input;
    latestReport = MoodMedicineBuiltReport(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      fileName: input.fileNameFor(format),
      mimeType: format.mimeType,
    );
    return latestReport!;
  }

  @override
  Future<MoodMedicineReportDelivery> deliver(
    MoodMedicineBuiltReport report, {
    String? shareText,
  }) async {
    return const MoodMedicineReportDelivery(
      MoodMedicineReportDeliveryStatus.delivered,
    );
  }
}

MoodMedicineReportPresentation _presentation() {
  const MoodMedicineReportLabels labels = MoodMedicineReportLabels(
    moodLabel: 'Mood',
    activitiesLabel: 'Activities',
    associationsLabel: 'Associations',
    notesLabel: 'Notes',
    sourcesLabel: 'Sources',
    noDataLabel: 'No data',
    withActivityLabel: 'With activity',
    withoutActivityLabel: 'Without activity',
    associationDisclaimer: 'Association, not causation.',
  );
  return MoodMedicineReportPresentation(
    title: 'Mood report',
    rangeLabels: const <MoodMedicineInsightRange, String>{
      MoodMedicineInsightRange.day: 'Today',
      MoodMedicineInsightRange.week: 'Week',
      MoodMedicineInsightRange.month: 'Month',
      MoodMedicineInsightRange.year: 'Year',
    },
    labels: labels,
    defaultActivityLabels: const <String, String>{
      'music': 'Music',
      'physical_activity': 'Movement',
    },
    sources: const <MoodMedicineReportSource>[],
    textDirection: TextDirection.ltr,
    dayLabelFor: (String dayKey) => dayKey,
  );
}

MoodMedicineViewModel _viewModel(
  _Repository repository,
  _ReportExporter exporter, {
  required String Function() idGenerator,
}) {
  return MoodMedicineViewModel(
    repository,
    exporter,
    clock: () => DateTime(2026, 8, 29, 9),
    idGenerator: idGenerator,
  );
}

void main() {
  group('MoodMedicineViewModel', () {
    test('should retry loading only while recovery is required', () async {
      final _Repository repository = _Repository(
        const MoodMedicineUnreadableSnapshot(
          MoodMedicineLoadFailure(MoodMedicineLoadFailureKind.malformedRecord),
        ),
      );
      final MoodMedicineViewModel viewModel = _viewModel(
        repository,
        _ReportExporter(),
        idGenerator: () => 'unused',
      );

      await viewModel.load();
      expect(viewModel.state, isA<MoodMedicineRecoveryRequiredState>());
      expect(repository.loadCount, 1);

      repository.result = const MoodMedicineMissingSnapshot();
      await viewModel.retryLoad();
      final MoodMedicineViewState readyState = viewModel.state;
      expect(readyState, isA<MoodMedicineReadyState>());
      expect(repository.loadCount, 2);

      await viewModel.retryLoad();
      expect(identical(viewModel.state, readyState), isTrue);
      expect(repository.loadCount, 2);
      viewModel.dispose();
    });

    test(
      'should block overlapping saves and ready-state retry loads',
      () async {
        final Completer<void> saveGate = Completer<void>();
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
          saveGate: saveGate,
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: () => 'entry-1',
        );
        await viewModel.load();
        viewModel.selectMood(4);

        final Future<bool> firstSave = viewModel.saveCheckIn();
        expect(repository.saveCount, 1);
        expect(viewModel.readyState!.persistence.isSaving, isTrue);

        await viewModel.retryLoad();
        expect(repository.loadCount, 1);
        expect(await viewModel.saveCheckIn(), isFalse);
        expect(repository.saveCount, 1);

        saveGate.complete();
        expect(await firstSave, isTrue);
        expect(viewModel.readyState!.snapshot.entries, hasLength(1));
        viewModel.dispose();
      },
    );

    test(
      'should block prompts and writes until unreadable history is discarded',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineUnreadableSnapshot(
            MoodMedicineLoadFailure(
              MoodMedicineLoadFailureKind.malformedRecord,
            ),
          ),
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: () => 'entry-1',
        );

        await viewModel.load();

        expect(viewModel.state, isA<MoodMedicineRecoveryRequiredState>());
        expect(viewModel.shouldPromptFor(DateTime(2026, 8, 29)), isFalse);
        expect(await viewModel.saveCheckIn(), isFalse);
        expect(repository.receivedSnapshots, isEmpty);

        expect(await viewModel.discardUnreadableSnapshot(), isTrue);

        expect(viewModel.readyState, isNotNull);
        expect(repository.receivedSnapshots.single.entries, isEmpty);
        viewModel.dispose();
      },
    );

    test(
      'should rebase a filtered check-in mutation on newer history during retry',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
          failNextSave: true,
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: () => 'entry-1',
        );
        await viewModel.load();
        viewModel.selectMood(4);
        viewModel.toggleActivity('music');
        viewModel.toggleActivity('deleted-custom');
        viewModel.setJournalNote(' private note ');

        expect(await viewModel.saveCheckIn(), isFalse);
        final MoodMedicineReadyState failed = viewModel.readyState!;
        expect(failed.persistence.hasPendingWrite, isTrue);
        expect(
          repository.receivedSnapshots.single.entries.single.activityIds,
          <String>['music'],
        );
        expect(failed.persistence.pendingCheckInDraft!.note, 'private note');

        repository.result = MoodMedicineLoadedSnapshot(
          MoodMedicineSnapshot(
            hiddenDefaultActivityIds: const <String>['music'],
            entries: <MoodMedicineEntry>[
              MoodMedicineEntry(
                id: 'external-entry',
                occurredAtUtc: DateTime.utc(2026, 8, 29, 8),
                localDayKey: '2026-08-29',
                mood: 2,
              ),
            ],
          ),
        );

        expect(await viewModel.retryLastWrite(), isTrue);
        expect(repository.receivedSnapshots, hasLength(2));
        final MoodMedicineSnapshot rebased = repository.receivedSnapshots.last;
        expect(
          rebased.entries.map((MoodMedicineEntry entry) => entry.id),
          <String>['external-entry', 'entry-1'],
        );
        expect(rebased.entries.last.activityIds, isEmpty);
        expect(viewModel.readyState!.snapshot.entries, hasLength(2));
        expect(viewModel.readyState!.checkInForm.mood, isNull);
        viewModel.dispose();
      },
    );

    test(
      'should treat an exact same-id entry as an idempotent check-in retry',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
          failNextSave: true,
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: () => 'entry-1',
        );
        await viewModel.load();
        viewModel.selectMood(4);
        viewModel.toggleEmotion('calm');
        viewModel.toggleActivity('music');
        viewModel.setJournalNote('private note');

        final Future<MoodMedicineUiEffect> firstFailure =
            viewModel.effects.first;
        expect(await viewModel.saveCheckIn(), isFalse);
        expect(await firstFailure, isA<MoodMedicinePersistenceFailedEffect>());
        final MoodMedicineSnapshot committed =
            repository.receivedSnapshots.single;
        repository.result = MoodMedicineLoadedSnapshot(committed);

        expect(await viewModel.retryLastWrite(), isTrue);
        final MoodMedicineSnapshot retryResult =
            repository.receivedSnapshots.last;
        expect(retryResult.entries, hasLength(1));
        expect(retryResult.entries.single.id, 'entry-1');
        expect(retryResult.entries.single.mood, 4);
        expect(retryResult.entries.single.emotionIds, <String>['calm']);
        expect(retryResult.entries.single.activityIds, <String>['music']);
        expect(retryResult.entries.single.note, 'private note');
        expect(viewModel.readyState!.checkInForm.mood, isNull);
        viewModel.dispose();
      },
    );

    test(
      'should retain a differing same-id check-in collision without retrying it',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
          failNextSave: true,
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: _idSequence(<String>['entry-1', 'entry-2']),
        );
        await viewModel.load();
        viewModel.selectMood(4);

        final Future<MoodMedicineUiEffect> firstFailure =
            viewModel.effects.first;
        expect(await viewModel.saveCheckIn(), isFalse);
        expect(await firstFailure, isA<MoodMedicinePersistenceFailedEffect>());
        final MoodMedicineEntry intended =
            repository.receivedSnapshots.single.entries.single;
        repository.result = MoodMedicineLoadedSnapshot(
          MoodMedicineSnapshot(
            entries: <MoodMedicineEntry>[
              MoodMedicineEntry(
                id: intended.id,
                occurredAtUtc: intended.occurredAtUtc,
                localDayKey: intended.localDayKey,
                mood: 2,
              ),
            ],
          ),
        );

        final Future<MoodMedicineUiEffect> collisionFailure =
            viewModel.effects.first;
        expect(await viewModel.retryLastWrite(), isFalse);
        final MoodMedicinePersistenceFailedEffect failure =
            await collisionFailure as MoodMedicinePersistenceFailedEffect;
        expect(failure.canRetry, isFalse);
        final MoodMedicineReadyState collisionState = viewModel.readyState!;
        expect(collisionState.persistence.hasPendingWrite, isFalse);
        expect(collisionState.persistence.pendingCheckInDraft, isNull);
        expect(collisionState.persistence.error, isNotNull);
        expect(collisionState.checkInForm.mood, 4);
        expect(collisionState.checkInForm.draft, isNotNull);
        expect(await viewModel.retryLastWrite(), isFalse);

        expect(await viewModel.saveCheckIn(), isTrue);
        expect(
          viewModel.readyState!.snapshot.entries.map(
            (MoodMedicineEntry entry) => entry.id,
          ),
          <String>['entry-1', 'entry-2'],
        );
        viewModel.dispose();
      },
    );

    test(
      'should retain the check-in when a loaded mutation result misses it',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
          nextMutationResult: const MoodMedicineLoadedSnapshot(
            MoodMedicineSnapshot.empty(),
          ),
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: () => 'entry-1',
        );
        await viewModel.load();
        viewModel.selectMood(4);

        final Future<MoodMedicineUiEffect> failedEffect =
            viewModel.effects.first;
        expect(await viewModel.saveCheckIn(), isFalse);
        expect(await failedEffect, isA<MoodMedicinePersistenceFailedEffect>());
        final MoodMedicineReadyState failedState = viewModel.readyState!;
        expect(failedState.snapshot.entries, isEmpty);
        expect(failedState.checkInForm.mood, 4);
        expect(failedState.persistence.hasPendingWrite, isTrue);
        expect(failedState.persistence.pendingCheckInDraft, isNotNull);

        expect(await viewModel.retryLastWrite(), isTrue);
        expect(viewModel.readyState!.snapshot.entries.single.id, 'entry-1');
        viewModel.dispose();
      },
    );

    test(
      'should preserve two factory view-model writes through one serialized store',
      () async {
        // Force a normal storage read to keep returning the older committed
        // snapshot until the held write completes.
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(exposePendingWrites: false);
        final MoodMedicineStore store = MoodMedicineStore(memory);
        final MoodMedicineViewModel first = MoodMedicineViewModel(
          store,
          _ReportExporter(),
          clock: () => DateTime(2026, 8, 29, 9),
          idGenerator: () => 'entry-first',
        );
        final MoodMedicineViewModel second = MoodMedicineViewModel(
          store,
          _ReportExporter(),
          clock: () => DateTime(2026, 8, 29, 10),
          idGenerator: () => 'entry-second',
        );
        await Future.wait<void>(<Future<void>>[first.load(), second.load()]);
        first.selectMood(2);
        second.selectMood(5);

        final Completer<void> firstWriteStarted = Completer<void>();
        final Completer<void> allowFirstWrite = Completer<void>();
        var snapshotWriteCount = 0;
        memory.onPersist = (String key, _, Object _) async {
          if (key != MoodMedicineStore.snapshotKey ||
              snapshotWriteCount++ > 0) {
            return;
          }
          firstWriteStarted.complete();
          await allowFirstWrite.future;
        };

        final Future<bool> firstSave = first.saveCheckIn();
        await firstWriteStarted.future;
        first.dispose();

        final Future<bool> secondSave = second.saveCheckIn();
        expect(second.readyState!.persistence.isSaving, isTrue);

        allowFirstWrite.complete();
        expect(await firstSave, isTrue);
        expect(await secondSave, isTrue);

        final MoodMedicineLoadResult result = await store.loadSnapshot();
        final MoodMedicineSnapshot snapshot =
            (result as MoodMedicineLoadedSnapshot).snapshot;
        expect(
          snapshot.entries.map((MoodMedicineEntry entry) => entry.id),
          <String>['entry-first', 'entry-second'],
        );
        expect(memory.completedWrites, hasLength(2));
        second.dispose();
      },
    );

    test(
      'should not discard a now-valid snapshot after a confirmed recovery',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineUnreadableSnapshot(
            MoodMedicineLoadFailure(
              MoodMedicineLoadFailureKind.malformedRecord,
            ),
          ),
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: () => 'unused',
        );
        await viewModel.load();
        repository.result = MoodMedicineLoadedSnapshot(
          MoodMedicineSnapshot(
            entries: <MoodMedicineEntry>[
              MoodMedicineEntry(
                id: 'recovered-entry',
                occurredAtUtc: DateTime.utc(2026, 8, 29, 8),
                localDayKey: '2026-08-29',
                mood: 4,
              ),
            ],
          ),
        );

        expect(await viewModel.discardUnreadableSnapshot(), isTrue);
        expect(repository.saveCount, 0);
        expect(
          viewModel.readyState!.snapshot.entries.single.id,
          'recovered-entry',
        );
        viewModel.dispose();
      },
    );

    test(
      'should use the latest historical label before an active or deleted custom label',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: _idSequence(<String>['custom-1', 'entry-1', 'entry-2']),
        );
        await viewModel.load();

        final MoodMedicineCustomActivity custom = (await viewModel
            .addCustomActivity('Evening walk'))!;
        viewModel.selectMood(4);
        viewModel.toggleActivity(custom.id);
        await viewModel.saveCheckIn();
        await viewModel.editCustomActivity(custom.id, 'Morning walk');
        viewModel.setReportPresentation(_presentation());

        expect(
          viewModel.readyState!.dashboard.activityLabelForRange(custom.id),
          'Evening walk',
        );

        await viewModel.deleteCustomActivity(custom.id);
        viewModel.selectMood(3);
        viewModel.toggleActivity(custom.id);
        await viewModel.saveCheckIn();

        expect(
          viewModel.readyState!.snapshot.entries.last.activityIds,
          isEmpty,
        );
        expect(
          viewModel.readyState!.dashboard.activityLabelForRange(custom.id),
          'Evening walk',
        );
        viewModel.dispose();
      },
    );

    test(
      'should build deterministic privacy-preserving report input',
      () async {
        final MoodMedicineEntry entry = MoodMedicineEntry(
          id: 'entry-1',
          occurredAtUtc: DateTime.utc(2026, 8, 29, 8),
          localDayKey: '2026-08-29',
          mood: 5,
          activityIds: const <String>['music'],
          note: 'Private journal detail',
        );
        final _Repository repository = _Repository(
          MoodMedicineLoadedSnapshot(
            MoodMedicineSnapshot(entries: <MoodMedicineEntry>[entry]),
          ),
        );
        final _ReportExporter exporter = _ReportExporter();
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          exporter,
          idGenerator: () => 'unused',
        );
        await viewModel.load();
        viewModel.setReportPresentation(_presentation());
        viewModel.selectRange(MoodMedicineInsightRange.week);

        await viewModel.buildReport();
        expect(exporter.latestInput!.dateRangeLabel, 'Week');
        expect(
          exporter.latestInput!.buildTextContent(),
          isNot(contains('Private journal detail')),
        );

        viewModel.setReportOptions(includeNotes: true);
        await viewModel.buildReport();
        expect(
          exporter.latestInput!.buildTextContent(),
          contains('Private journal detail'),
        );
        viewModel.dispose();
      },
    );

    test(
      'should invalidate a built report when range presentation or history changes',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
        );
        final _ReportExporter exporter = _ReportExporter();
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          exporter,
          idGenerator: () => 'entry-1',
        );
        await viewModel.load();
        viewModel.setReportPresentation(_presentation());

        expect(await viewModel.buildReport(), isNotNull);
        expect(viewModel.readyState!.export.report, isNotNull);

        viewModel.selectRange(MoodMedicineInsightRange.day);
        expect(viewModel.readyState!.export.report, isNull);
        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.idle,
        );
        await viewModel.buildReport();
        expect(exporter.latestInput!.dateRangeLabel, 'Today');

        viewModel.setReportPresentation(_presentation());
        expect(viewModel.readyState!.export.report, isNull);
        await viewModel.buildReport();
        viewModel.selectMood(4);
        expect(await viewModel.saveCheckIn(), isTrue);
        expect(viewModel.readyState!.export.report, isNull);
        viewModel.dispose();
      },
    );

    test(
      'should not deliver a report that finished after its input became stale',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
        );
        final _DelayedReportExporter exporter = _DelayedReportExporter();
        final MoodMedicineViewModel viewModel = MoodMedicineViewModel(
          repository,
          exporter,
          clock: () => DateTime(2026, 8, 29, 9),
          idGenerator: () => 'entry-1',
        );
        await viewModel.load();
        viewModel.setReportPresentation(_presentation());

        final Future<MoodMedicineBuiltReport?> pending = viewModel
            .buildReport();
        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.building,
        );
        viewModel.selectRange(MoodMedicineInsightRange.day);
        exporter.completeBuild();

        expect(await pending, isNull);
        expect(viewModel.readyState!.export.report, isNull);
        expect(await viewModel.shareBuiltReport(), isFalse);
        expect(exporter.deliveryCount, 0);
        viewModel.dispose();
      },
    );
  });
}

final class _DelayedReportExporter implements MoodMedicineReportExportService {
  final Completer<MoodMedicineBuiltReport> _buildCompleter =
      Completer<MoodMedicineBuiltReport>();
  MoodMedicineReportInput? _input;
  MoodMedicineReportFormat? _format;
  int deliveryCount = 0;

  @override
  Future<MoodMedicineBuiltReport> build(
    MoodMedicineReportInput input,
    MoodMedicineReportFormat format,
  ) {
    _input = input;
    _format = format;
    return _buildCompleter.future;
  }

  void completeBuild() {
    final MoodMedicineReportInput input = _input!;
    final MoodMedicineReportFormat format = _format!;
    _buildCompleter.complete(
      MoodMedicineBuiltReport(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        fileName: input.fileNameFor(format),
        mimeType: format.mimeType,
      ),
    );
  }

  @override
  Future<MoodMedicineReportDelivery> deliver(
    MoodMedicineBuiltReport report, {
    String? shareText,
  }) async {
    deliveryCount += 1;
    return const MoodMedicineReportDelivery(
      MoodMedicineReportDeliveryStatus.delivered,
    );
  }
}

String Function() _idSequence(List<String> ids) {
  return () {
    if (ids.isEmpty) {
      throw StateError('No ids remain.');
    }
    return ids.removeAt(0);
  };
}
