import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_insights.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_exporter.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_repository.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_view_model.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_view_state.dart';

final class _Repository implements MoodMedicineRepository {
  _Repository(this.result, {this.failNextSave = false, this.saveGate});

  MoodMedicineLoadResult result;
  bool failNextSave;
  Completer<void>? saveGate;
  int loadCount = 0;
  int saveCount = 0;
  final List<MoodMedicineSnapshot> receivedSnapshots = <MoodMedicineSnapshot>[];

  @override
  Future<MoodMedicineLoadResult> loadSnapshot() async {
    loadCount += 1;
    return result;
  }

  @override
  Future<void> saveSnapshot(MoodMedicineSnapshot snapshot) async {
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
    result = MoodMedicineLoadedSnapshot(snapshot);
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
      'should retain the exact filtered check-in snapshot for retry',
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
        final MoodMedicineSnapshot pending = failed.persistence.failedSnapshot!;
        expect(pending.entries.single.activityIds, <String>['music']);
        expect(failed.persistence.pendingCheckInDraft!.note, 'private note');

        expect(await viewModel.retryLastWrite(), isTrue);
        expect(repository.receivedSnapshots, hasLength(2));
        expect(
          repository.receivedSnapshots.first.encode(),
          repository.receivedSnapshots.last.encode(),
        );
        expect(viewModel.readyState!.snapshot.entries, hasLength(1));
        expect(viewModel.readyState!.checkInForm.mood, isNull);
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
