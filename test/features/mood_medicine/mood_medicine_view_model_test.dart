import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_exporter.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_renderer.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_repository.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_source_link_service.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_store.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_insights.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_model.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_state.dart';
import 'package:mazilon/util/logger_service.dart';

import '../../../test_support/contract_persistent_memory_service.dart';

final class _MockMoodMedicineRepository extends Mock
    implements MoodMedicineRepository {}

final class _MockMoodMedicineReportExportService extends Mock
    implements MoodMedicineReportExportService {}

final class _MockMoodMedicineSourceLinkService extends Mock
    implements MoodMedicineSourceLinkService {}

final class _MockIncidentLoggerService extends Mock
    implements IncidentLoggerService {}

final class _FakeMoodMedicineReportInput extends Fake
    implements MoodMedicineReportInput {}

final class _FakeMoodMedicineBuiltReport extends Fake
    implements MoodMedicineBuiltReport {}

MoodMedicineSnapshot _fallbackSnapshotMutation(MoodMedicineSnapshot snapshot) {
  return snapshot;
}

/// Mutable test state for the source-link boundary mock.
final class _SourceLinkService {
  _SourceLinkService({this.opens = true, this.error}) {
    when(() => mock.openExternal(any())).thenAnswer((_) async {
      if (error != null) {
        throw error!;
      }
      return opens;
    });
  }

  final _MockMoodMedicineSourceLinkService mock =
      _MockMoodMedicineSourceLinkService();
  final bool opens;
  final Object? error;
}

/// Mutable test state for the incident-logger boundary mock.
final class _IncidentLogger {
  _IncidentLogger({this.error}) {
    when(
      () => mock.captureLog(any(), stackTrace: any(named: 'stackTrace')),
    ).thenAnswer((Invocation invocation) async {
      captured.add(invocation.positionalArguments.single);
      stackTraces.add(invocation.namedArguments[#stackTrace] as StackTrace?);
      if (error != null) {
        throw error!;
      }
    });
  }

  final _MockIncidentLoggerService mock = _MockIncidentLoggerService();
  final Object? error;
  final List<Object> captured = <Object>[];
  final List<StackTrace?> stackTraces = <StackTrace?>[];
}

/// Mutable test state for a repository-boundary mock.
///
/// The controller deliberately owns the scenario state while [mock] remains a
/// Mocktail boundary mock. This lets each test exercise the view-model's
/// behavior without hand-writing a repository implementation.
final class _Repository {
  _Repository(
    this.result, {
    this.failNextSave = false,
    this.saveGate,
    this.nextMutationResult,
  }) {
    when(() => mock.loadSnapshot()).thenAnswer((_) async {
      loadCount += 1;
      return result;
    });
    when(() => mock.mutateSnapshot(any())).thenAnswer((
      Invocation invocation,
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
      final MoodMedicineSnapshotMutation mutation =
          invocation.positionalArguments.single as MoodMedicineSnapshotMutation;
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
    });
    when(() => mock.discardUnreadableSnapshot()).thenAnswer((_) async {
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
      final MoodMedicineLoadResult? override = nextDiscardResult;
      if (override != null) {
        nextDiscardResult = null;
        result = override;
        return override;
      }
      result = const MoodMedicineLoadedSnapshot(snapshot);
      return result;
    });
  }

  final _MockMoodMedicineRepository mock = _MockMoodMedicineRepository();

  MoodMedicineLoadResult result;
  bool failNextSave;
  Completer<void>? saveGate;
  MoodMedicineLoadResult? nextMutationResult;
  MoodMedicineLoadResult? nextDiscardResult;
  int loadCount = 0;
  int saveCount = 0;
  final List<MoodMedicineSnapshot> receivedSnapshots = <MoodMedicineSnapshot>[];
}

/// Mutable test state for a report-exporter boundary mock.
final class _ReportExporter {
  _ReportExporter() {
    when(() => mock.build(any(), any())).thenAnswer((
      Invocation invocation,
    ) async {
      final MoodMedicineReportInput input =
          invocation.positionalArguments[0] as MoodMedicineReportInput;
      final MoodMedicineReportFormat format =
          invocation.positionalArguments[1] as MoodMedicineReportFormat;
      latestInput = input;
      latestReport = MoodMedicineBuiltReport(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        fileName: input.fileNameFor(format),
        format: format,
      );
      return latestReport!;
    });
    when(
      () => mock.deliver(any(), shareText: any(named: 'shareText')),
    ).thenAnswer(
      (_) async => const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.delivered,
      ),
    );
  }

  final _MockMoodMedicineReportExportService mock =
      _MockMoodMedicineReportExportService();
  MoodMedicineReportInput? latestInput;
  MoodMedicineBuiltReport? latestReport;
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
  _SourceLinkService? sourceLinkService,
  _IncidentLogger? incidentLogger,
}) {
  return MoodMedicineViewModel(
    repository.mock,
    exporter.mock,
    sourceLinkService: (sourceLinkService ?? _SourceLinkService()).mock,
    incidentLoggerService: (incidentLogger ?? _IncidentLogger()).mock,
    clock: () => DateTime(2026, 8, 29, 9),
    idGenerator: idGenerator,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_fallbackSnapshotMutation);
    registerFallbackValue(_FakeMoodMedicineReportInput());
    registerFallbackValue(_FakeMoodMedicineBuiltReport());
    registerFallbackValue(MoodMedicineReportFormat.pdf);
    registerFallbackValue(Uri.parse('https://example.test'));
  });

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
      'should open an education source without emitting a failure effect',
      () async {
        final _SourceLinkService sourceLinkService = _SourceLinkService();
        final _IncidentLogger incidentLogger = _IncidentLogger();
        final MoodMedicineViewModel viewModel = _viewModel(
          _Repository(const MoodMedicineMissingSnapshot()),
          _ReportExporter(),
          idGenerator: () => 'unused',
          sourceLinkService: sourceLinkService,
          incidentLogger: incidentLogger,
        );
        final List<MoodMedicineUiEffect> effects = <MoodMedicineUiEffect>[];
        final StreamSubscription<MoodMedicineUiEffect> subscription = viewModel
            .effects
            .listen(effects.add);
        final Uri source = Uri.parse('https://example.test/source');

        await viewModel.openEducationSource(source);
        await Future<void>.delayed(Duration.zero);

        verify(() => sourceLinkService.mock.openExternal(source)).called(1);
        expect(effects, isEmpty);
        expect(incidentLogger.captured, isEmpty);
        await subscription.cancel();
        viewModel.dispose();
      },
    );

    test(
      'should emit a source-open failure effect when the launcher declines',
      () async {
        final _IncidentLogger incidentLogger = _IncidentLogger();
        final MoodMedicineViewModel viewModel = _viewModel(
          _Repository(const MoodMedicineMissingSnapshot()),
          _ReportExporter(),
          idGenerator: () => 'unused',
          sourceLinkService: _SourceLinkService(opens: false),
          incidentLogger: incidentLogger,
        );
        final Future<MoodMedicineUiEffect> effect = viewModel.effects.first;

        await viewModel.openEducationSource(
          Uri.parse('https://example.test/source'),
        );

        expect(await effect, isA<MoodMedicineSourceOpenFailedEffect>());
        expect(incidentLogger.captured, isEmpty);
        viewModel.dispose();
      },
    );

    test(
      'should emit a source-open failure effect when the launcher throws',
      () async {
        final _IncidentLogger incidentLogger = _IncidentLogger();
        final MoodMedicineViewModel viewModel = _viewModel(
          _Repository(const MoodMedicineMissingSnapshot()),
          _ReportExporter(),
          idGenerator: () => 'unused',
          sourceLinkService: _SourceLinkService(
            error: StateError('unavailable'),
          ),
          incidentLogger: incidentLogger,
        );
        final Future<MoodMedicineUiEffect> effect = viewModel.effects.first;

        await viewModel.openEducationSource(
          Uri.parse('https://example.test/source'),
        );

        expect(await effect, isA<MoodMedicineSourceOpenFailedEffect>());
        expect(incidentLogger.captured, hasLength(1));
        final String payload = incidentLogger.captured.single.toString();
        expect(payload, contains('stage: sourceOpen'));
        expect(payload, contains('errorType: StateError'));
        expect(payload, isNot(contains('unavailable')));
        expect(payload, isNot(contains('example.test')));
        expect(incidentLogger.stackTraces.single, isNotNull);
        viewModel.dispose();
      },
    );

    test(
      'should emit a source-open failure effect when incident logging throws',
      () async {
        final _IncidentLogger incidentLogger = _IncidentLogger(
          error: StateError('telemetry unavailable'),
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          _Repository(const MoodMedicineMissingSnapshot()),
          _ReportExporter(),
          idGenerator: () => 'unused',
          sourceLinkService: _SourceLinkService(
            error: ArgumentError('launcher unavailable'),
          ),
          incidentLogger: incidentLogger,
        );
        final Future<MoodMedicineUiEffect> effect = viewModel.effects.first;

        await viewModel.openEducationSource(
          Uri.parse('https://example.test/private-source'),
        );

        expect(await effect, isA<MoodMedicineSourceOpenFailedEffect>());
        expect(incidentLogger.captured, hasLength(1));
        viewModel.dispose();
      },
    );

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
      'should retain a full check-in form through unreadable recovery retries and discard failures',
      () async {
        const MoodMedicineLoadFailure failure = MoodMedicineLoadFailure(
          MoodMedicineLoadFailureKind.malformedRecord,
        );
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: () => 'entry-1',
        );
        await viewModel.load();
        viewModel.selectMood(4);
        viewModel.setCheckInDetailsExpanded(true);
        viewModel.toggleEmotion('calm');
        viewModel.toggleActivity('music');
        viewModel.setJournalNote('Draft note');
        repository.nextMutationResult = const MoodMedicineUnreadableSnapshot(
          failure,
        );

        expect(await viewModel.saveCheckIn(), isFalse);
        MoodMedicineRecoveryRequiredState recovery =
            viewModel.state as MoodMedicineRecoveryRequiredState;
        expect(recovery.checkInForm.mood, 4);
        expect(recovery.checkInForm.emotionIds, <String>{'calm'});
        expect(recovery.checkInForm.activityIds, <String>{'music'});
        expect(recovery.checkInForm.journalNote, 'Draft note');
        expect(recovery.isCheckInDetailsExpanded, isTrue);

        await viewModel.retryLoad();
        recovery = viewModel.state as MoodMedicineRecoveryRequiredState;
        expect(recovery.checkInForm.mood, 4);
        expect(recovery.checkInForm.emotionIds, <String>{'calm'});
        expect(recovery.checkInForm.activityIds, <String>{'music'});
        expect(recovery.checkInForm.journalNote, 'Draft note');
        expect(recovery.isCheckInDetailsExpanded, isTrue);

        final Completer<void> discardGate = Completer<void>();
        repository.nextDiscardResult = const MoodMedicineUnreadableSnapshot(
          failure,
        );
        repository.saveGate = discardGate;
        final Future<bool> stillUnreadableDiscard = viewModel
            .discardUnreadableSnapshot();
        recovery = viewModel.state as MoodMedicineRecoveryRequiredState;
        expect(recovery.isDiscarding, isTrue);
        expect(recovery.checkInForm.mood, 4);
        expect(recovery.checkInForm.emotionIds, <String>{'calm'});
        expect(recovery.checkInForm.activityIds, <String>{'music'});
        expect(recovery.checkInForm.journalNote, 'Draft note');
        expect(recovery.isCheckInDetailsExpanded, isTrue);

        discardGate.complete();
        expect(await stillUnreadableDiscard, isFalse);
        recovery = viewModel.state as MoodMedicineRecoveryRequiredState;
        expect(recovery.isDiscarding, isFalse);
        expect(recovery.checkInForm.mood, 4);
        expect(recovery.checkInForm.emotionIds, <String>{'calm'});
        expect(recovery.checkInForm.activityIds, <String>{'music'});
        expect(recovery.checkInForm.journalNote, 'Draft note');
        expect(recovery.isCheckInDetailsExpanded, isTrue);

        repository.failNextSave = true;
        expect(await viewModel.discardUnreadableSnapshot(), isFalse);
        recovery = viewModel.state as MoodMedicineRecoveryRequiredState;
        expect(recovery.discardError, isNotNull);
        expect(recovery.checkInForm.mood, 4);
        expect(recovery.checkInForm.emotionIds, <String>{'calm'});
        expect(recovery.checkInForm.activityIds, <String>{'music'});
        expect(recovery.checkInForm.journalNote, 'Draft note');
        expect(recovery.isCheckInDetailsExpanded, isTrue);

        expect(await viewModel.discardUnreadableSnapshot(), isTrue);
        final MoodMedicineReadyState ready = viewModel.readyState!;
        expect(ready.snapshot.entries, isEmpty);
        expect(ready.checkInForm.mood, 4);
        expect(ready.checkInForm.emotionIds, <String>{'calm'});
        expect(ready.checkInForm.activityIds, <String>{'music'});
        expect(ready.checkInForm.journalNote, 'Draft note');
        expect(ready.isCheckInDetailsExpanded, isTrue);
        viewModel.dispose();
      },
    );

    test(
      'should restore a recovered form for a fresh explicitly saved rebased check-in',
      () async {
        const MoodMedicineLoadFailure failure = MoodMedicineLoadFailure(
          MoodMedicineLoadFailureKind.malformedRecord,
        );
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: _idSequence(<String>['entry-1', 'entry-2']),
        );
        await viewModel.load();
        viewModel.selectMood(4);
        viewModel.setCheckInDetailsExpanded(true);
        viewModel.toggleActivity('music');
        repository.nextMutationResult = const MoodMedicineUnreadableSnapshot(
          failure,
        );

        expect(await viewModel.saveCheckIn(), isFalse);
        expect(repository.saveCount, 1);
        repository.result = MoodMedicineLoadedSnapshot(
          MoodMedicineSnapshot(
            hiddenDefaultActivityIds: const <String>{'music'},
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

        await viewModel.retryLoad();
        final MoodMedicineReadyState recovered = viewModel.readyState!;
        expect(repository.saveCount, 1);
        expect(recovered.checkInForm.mood, 4);
        expect(recovered.checkInForm.activityIds, <String>{'music'});
        expect(recovered.isCheckInDetailsExpanded, isTrue);

        expect(await viewModel.saveCheckIn(), isTrue);
        final MoodMedicineSnapshot saved = repository.receivedSnapshots.last;
        expect(repository.saveCount, 2);
        expect(
          saved.entries.map((MoodMedicineEntry entry) => entry.id),
          <String>['external-entry', 'entry-2'],
        );
        expect(saved.entries.last.activityIds, isEmpty);
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
      'should remove a hidden default activity from the form after a retried write',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: () => 'unused',
        );
        await viewModel.load();
        viewModel.toggleActivity('music');
        repository.failNextSave = true;

        expect(await viewModel.hideDefaultActivity('music'), isFalse);
        expect(
          viewModel.readyState!.checkInForm.activityIds,
          contains('music'),
        );

        expect(await viewModel.retryLastWrite(), isTrue);
        expect(
          viewModel.readyState!.checkInForm.activityIds,
          isNot(contains('music')),
        );
        viewModel.dispose();
      },
    );

    test(
      'should remove a deleted custom activity from the form after a retried write',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
        );
        final MoodMedicineViewModel viewModel = _viewModel(
          repository,
          _ReportExporter(),
          idGenerator: _idSequence(<String>['custom-1']),
        );
        await viewModel.load();
        final MoodMedicineCustomActivity custom = (await viewModel
            .addCustomActivity('Evening walk'))!;
        viewModel.toggleActivity(custom.id);
        repository.failNextSave = true;

        expect(await viewModel.deleteCustomActivity(custom.id), isFalse);
        expect(
          viewModel.readyState!.checkInForm.activityIds,
          contains(custom.id),
        );

        expect(await viewModel.retryLastWrite(), isTrue);
        expect(
          viewModel.readyState!.checkInForm.activityIds,
          isNot(contains(custom.id)),
        );
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
        final _ReportExporter firstExporter = _ReportExporter();
        final _ReportExporter secondExporter = _ReportExporter();
        final MoodMedicineViewModel first = MoodMedicineViewModel(
          store,
          firstExporter.mock,
          sourceLinkService: _SourceLinkService().mock,
          incidentLoggerService: _IncidentLogger().mock,
          clock: () => DateTime(2026, 8, 29, 9),
          idGenerator: () => 'entry-first',
        );
        final MoodMedicineViewModel second = MoodMedicineViewModel(
          store,
          secondExporter.mock,
          sourceLinkService: _SourceLinkService().mock,
          incidentLoggerService: _IncidentLogger().mock,
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
      'should mark a report build stale when its presentation changes',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
        );
        final _DelayedReportExporter exporter = _DelayedReportExporter();
        final MoodMedicineViewModel viewModel = MoodMedicineViewModel(
          repository.mock,
          exporter.mock,
          sourceLinkService: _SourceLinkService().mock,
          incidentLoggerService: _IncidentLogger().mock,
          clock: () => DateTime(2026, 8, 29, 9),
          idGenerator: () => 'entry-1',
        );
        await viewModel.load();
        viewModel.setReportPresentation(_presentation());

        final Future<MoodMedicineReportBuildOutcome> pending = viewModel
            .buildReport();
        viewModel.setReportPresentation(_presentation());
        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.building,
        );
        expect(
          await viewModel.buildReport(),
          isA<MoodMedicineReportBuildCancelledOutcome>(),
        );
        expect(exporter.buildCount, 1);
        exporter.completeBuild();

        expect(
          await pending,
          isA<MoodMedicineReportBuildStalePresentationOutcome>(),
        );
        expect(viewModel.readyState!.export.report, isNull);
        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.idle,
        );

        final Future<MoodMedicineReportBuildOutcome> retry = viewModel
            .buildReport();
        expect(exporter.buildCount, 2);
        exporter.completeBuild();
        expect(await retry, isA<MoodMedicineReportBuiltOutcome>());
        viewModel.dispose();
      },
    );

    test('should cancel a report build when its input becomes stale', () async {
      final _Repository repository = _Repository(
        const MoodMedicineMissingSnapshot(),
      );
      final _DelayedReportExporter exporter = _DelayedReportExporter();
      final MoodMedicineViewModel viewModel = MoodMedicineViewModel(
        repository.mock,
        exporter.mock,
        sourceLinkService: _SourceLinkService().mock,
        incidentLoggerService: _IncidentLogger().mock,
        clock: () => DateTime(2026, 8, 29, 9),
        idGenerator: () => 'entry-1',
      );
      await viewModel.load();
      viewModel.setReportPresentation(_presentation());

      final Future<MoodMedicineReportBuildOutcome> pending = viewModel
          .buildReport();
      expect(
        viewModel.readyState!.export.phase,
        MoodMedicineExportPhase.building,
      );
      viewModel.selectRange(MoodMedicineInsightRange.day);
      expect(
        viewModel.readyState!.export.phase,
        MoodMedicineExportPhase.building,
      );
      expect(
        await viewModel.buildReport(),
        isA<MoodMedicineReportBuildCancelledOutcome>(),
      );
      expect(exporter.buildCount, 1);
      exporter.completeBuild();

      expect(await pending, isA<MoodMedicineReportBuildCancelledOutcome>());
      expect(viewModel.readyState!.export.report, isNull);
      expect(viewModel.readyState!.export.phase, MoodMedicineExportPhase.idle);
      expect(await viewModel.shareBuiltReport(), isFalse);
      expect(exporter.deliveryCount, 0);

      final Future<MoodMedicineReportBuildOutcome> currentBuild = viewModel
          .buildReport();
      exporter.completeBuild();
      expect(await currentBuild, isA<MoodMedicineReportBuiltOutcome>());
      viewModel.dispose();
    });

    test(
      'should preserve distinct PNG and renderer report failure kinds',
      () async {
        final _ReportExporter exporter = _ReportExporter();
        when(
          () => exporter.mock.build(any(), any()),
        ).thenThrow(const MoodMedicinePngReportTooLargeException(12000));
        final MoodMedicineViewModel viewModel = _viewModel(
          _Repository(const MoodMedicineMissingSnapshot()),
          exporter,
          idGenerator: () => 'unused',
        );
        await viewModel.load();
        viewModel.setReportPresentation(_presentation());

        expect(
          await viewModel.buildReport(),
          isA<MoodMedicineReportBuildFailedOutcome>(),
        );
        expect(
          viewModel.readyState!.export.buildFailureKind,
          MoodMedicineReportBuildFailureKind.pngTooLarge,
        );
        expect(viewModel.readyState!.export.error, isNull);

        viewModel.setReportOptions();
        final StateError rendererError = StateError('renderer failed');
        when(() => exporter.mock.build(any(), any())).thenThrow(rendererError);

        expect(
          await viewModel.buildReport(),
          isA<MoodMedicineReportBuildFailedOutcome>(),
        );
        expect(
          viewModel.readyState!.export.buildFailureKind,
          MoodMedicineReportBuildFailureKind.renderer,
        );
        expect(viewModel.readyState!.export.error, same(rendererError));
        viewModel.dispose();
      },
    );

    test(
      'should cancel an invalidated renderer failure without exposing stale error state',
      () async {
        final _DelayedReportExporter exporter = _DelayedReportExporter();
        final MoodMedicineViewModel delayedViewModel = MoodMedicineViewModel(
          _Repository(const MoodMedicineMissingSnapshot()).mock,
          exporter.mock,
          sourceLinkService: _SourceLinkService().mock,
          incidentLoggerService: _IncidentLogger().mock,
          clock: () => DateTime(2026, 8, 29, 9),
          idGenerator: () => 'unused',
        );
        await delayedViewModel.load();
        delayedViewModel.setReportPresentation(_presentation());

        final Future<MoodMedicineReportBuildOutcome> pending = delayedViewModel
            .buildReport();
        delayedViewModel.selectRange(MoodMedicineInsightRange.day);
        exporter.failBuild(StateError('stale renderer failure'));

        expect(await pending, isA<MoodMedicineReportBuildCancelledOutcome>());
        expect(
          delayedViewModel.readyState!.export.phase,
          MoodMedicineExportPhase.idle,
        );
        expect(delayedViewModel.readyState!.export.error, isNull);
        expect(delayedViewModel.readyState!.export.buildFailureKind, isNull);
        delayedViewModel.dispose();
      },
    );

    test(
      'should keep one build active until history invalidation completes',
      () async {
        final _Repository repository = _Repository(
          const MoodMedicineMissingSnapshot(),
        );
        final _DelayedReportExporter exporter = _DelayedReportExporter();
        final MoodMedicineViewModel viewModel = MoodMedicineViewModel(
          repository.mock,
          exporter.mock,
          sourceLinkService: _SourceLinkService().mock,
          incidentLoggerService: _IncidentLogger().mock,
          clock: () => DateTime(2026, 8, 29, 9),
          idGenerator: () => 'entry-1',
        );
        await viewModel.load();
        viewModel.setReportPresentation(_presentation());
        final Future<MoodMedicineReportBuildOutcome> pending = viewModel
            .buildReport();

        viewModel.selectMood(4);
        expect(await viewModel.saveCheckIn(), isTrue);
        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.building,
        );
        expect(
          await viewModel.buildReport(),
          isA<MoodMedicineReportBuildCancelledOutcome>(),
        );
        expect(exporter.buildCount, 1);

        exporter.completeBuild();
        expect(await pending, isA<MoodMedicineReportBuildCancelledOutcome>());
        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.idle,
        );
        viewModel.dispose();
      },
    );

    test(
      'should reset note consent per export session while retaining format',
      () async {
        final _ReportExporter exporter = _ReportExporter();
        final MoodMedicineViewModel viewModel = _viewModel(
          _Repository(const MoodMedicineMissingSnapshot()),
          exporter,
          idGenerator: () => 'unused',
        );
        await viewModel.load();
        viewModel.setReportPresentation(_presentation());
        viewModel.setReportOptions(
          format: MoodMedicineReportFormat.png,
          includeNotes: true,
        );

        expect(
          await viewModel.buildReport(),
          isA<MoodMedicineReportBuiltOutcome>(),
        );
        expect(viewModel.readyState!.export.includeNotes, isTrue);
        expect(exporter.latestInput!.includeNotes, isTrue);

        viewModel.endReportExportSession();

        expect(
          viewModel.readyState!.export.format,
          MoodMedicineReportFormat.png,
        );
        expect(viewModel.readyState!.export.includeNotes, isFalse);
        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.idle,
        );
        expect(viewModel.readyState!.export.input, isNull);
        expect(viewModel.readyState!.export.report, isNull);

        await viewModel.buildReport();
        expect(exporter.latestInput!.includeNotes, isFalse);
        viewModel.dispose();
      },
    );

    test(
      'should retain the build fence when an export session closes in flight',
      () async {
        final _DelayedReportExporter exporter = _DelayedReportExporter();
        final MoodMedicineViewModel viewModel = MoodMedicineViewModel(
          _Repository(const MoodMedicineMissingSnapshot()).mock,
          exporter.mock,
          sourceLinkService: _SourceLinkService().mock,
          incidentLoggerService: _IncidentLogger().mock,
          clock: () => DateTime(2026, 8, 29, 9),
          idGenerator: () => 'unused',
        );
        await viewModel.load();
        viewModel.setReportPresentation(_presentation());
        viewModel.setReportOptions(includeNotes: true);
        final Future<MoodMedicineReportBuildOutcome> pending = viewModel
            .buildReport();

        viewModel.endReportExportSession();

        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.building,
        );
        expect(viewModel.readyState!.export.includeNotes, isFalse);
        expect(viewModel.readyState!.export.input, isNull);
        expect(
          await viewModel.buildReport(),
          isA<MoodMedicineReportBuildCancelledOutcome>(),
        );
        expect(exporter.buildCount, 1);

        exporter.completeBuild();
        expect(await pending, isA<MoodMedicineReportBuildCancelledOutcome>());
        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.idle,
        );
        expect(viewModel.readyState!.export.report, isNull);
        viewModel.dispose();
      },
    );

    test(
      'should retain the delivery fence when an export session closes in flight',
      () async {
        final _ReportExporter exporter = _ReportExporter();
        final Completer<MoodMedicineReportDelivery> delivery =
            Completer<MoodMedicineReportDelivery>();
        when(
          () =>
              exporter.mock.deliver(any(), shareText: any(named: 'shareText')),
        ).thenAnswer((_) => delivery.future);
        final MoodMedicineViewModel viewModel = _viewModel(
          _Repository(const MoodMedicineMissingSnapshot()),
          exporter,
          idGenerator: () => 'unused',
        );
        await viewModel.load();
        viewModel.setReportPresentation(_presentation());
        viewModel.setReportOptions(includeNotes: true);
        await viewModel.buildReport();
        final Future<bool> pending = viewModel.shareBuiltReport();

        viewModel.endReportExportSession();

        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.delivering,
        );
        expect(viewModel.readyState!.export.includeNotes, isFalse);
        expect(viewModel.readyState!.export.report, isNull);
        expect(await viewModel.shareBuiltReport(), isFalse);

        delivery.complete(
          const MoodMedicineReportDelivery(
            MoodMedicineReportDeliveryStatus.delivered,
          ),
        );
        expect(await pending, isTrue);
        expect(
          viewModel.readyState!.export.phase,
          MoodMedicineExportPhase.idle,
        );
        expect(viewModel.readyState!.export.report, isNull);
        viewModel.dispose();
      },
    );
  });
}

/// Mutable test state for a delayed report-exporter boundary mock.
final class _DelayedReportExporter {
  _DelayedReportExporter() {
    when(() => mock.build(any(), any())).thenAnswer((Invocation invocation) {
      final _PendingReportBuild pending = _PendingReportBuild(
        invocation.positionalArguments[0] as MoodMedicineReportInput,
        invocation.positionalArguments[1] as MoodMedicineReportFormat,
      );
      pendingBuilds.add(pending);
      return pending.completer.future;
    });
    when(
      () => mock.deliver(any(), shareText: any(named: 'shareText')),
    ).thenAnswer((_) async {
      deliveryCount += 1;
      return const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.delivered,
      );
    });
  }

  final _MockMoodMedicineReportExportService mock =
      _MockMoodMedicineReportExportService();
  final List<_PendingReportBuild> pendingBuilds = <_PendingReportBuild>[];
  int deliveryCount = 0;

  int get buildCount => pendingBuilds.length;

  void completeBuild() {
    final _PendingReportBuild pending = pendingBuilds.firstWhere(
      (_PendingReportBuild candidate) => !candidate.completer.isCompleted,
    );
    pending.completer.complete(
      MoodMedicineBuiltReport(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        fileName: pending.input.fileNameFor(pending.format),
        format: pending.format,
      ),
    );
  }

  void failBuild(Object error) {
    final _PendingReportBuild pending = pendingBuilds.firstWhere(
      (_PendingReportBuild candidate) => !candidate.completer.isCompleted,
    );
    pending.completer.completeError(error);
  }
}

final class _PendingReportBuild {
  _PendingReportBuild(this.input, this.format);

  final MoodMedicineReportInput input;
  final MoodMedicineReportFormat format;
  final Completer<MoodMedicineBuiltReport> completer =
      Completer<MoodMedicineBuiltReport>();
}

String Function() _idSequence(List<String> ids) {
  return () {
    if (ids.isEmpty) {
      throw StateError('No ids remain.');
    }
    return ids.removeAt(0);
  };
}
