import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_exporter.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_renderer.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_store.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_page.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_model.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_state.dart';
import 'package:mazilon/util/theme/app_theme.dart';

import '../../../test_support/contract_persistent_memory_service.dart';

final class _TestReportExportService
    implements MoodMedicineReportExportService {
  _TestReportExportService({
    this.deliveryStatus = MoodMedicineReportDeliveryStatus.delivered,
    this.buildError,
  });

  final MoodMedicineReportDeliveryStatus deliveryStatus;
  final Object? buildError;

  @override
  Future<MoodMedicineBuiltReport> build(
    MoodMedicineReportInput input,
    MoodMedicineReportFormat format,
  ) async {
    if (buildError != null) {
      throw buildError!;
    }
    return MoodMedicineBuiltReport(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      fileName: input.fileNameFor(format),
      mimeType: format.mimeType,
    );
  }

  @override
  Future<MoodMedicineReportDelivery> deliver(
    MoodMedicineBuiltReport report, {
    String? shareText,
  }) async {
    return MoodMedicineReportDelivery(deliveryStatus);
  }
}

MoodMedicineViewModel _viewModel(
  ContractPersistentMemoryService memory, {
  DateTime? clock,
  MoodMedicineReportExportService? reportExportService,
  List<String> ids = const <String>[
    'entry-1',
    'custom-1',
    'entry-2',
    'custom-2',
  ],
}) {
  final List<String> generatedIds = List<String>.from(ids);
  return MoodMedicineViewModel(
    MoodMedicineStore(memory),
    reportExportService ?? _TestReportExportService(),
    clock: () => clock ?? DateTime(2026, 8, 29, 12),
    idGenerator: () => generatedIds.removeAt(0),
  );
}

Widget _app({
  required MoodMedicineViewModel viewModel,
  MoodMedicineInitialView initialView = MoodMedicineInitialView.insights,
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) {
  return MaterialApp(
    locale: locale,
    theme: theme,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: MoodMedicinePage(viewModel: viewModel, initialView: initialView),
  );
}

void _setLargeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MoodMedicinePage', () {
    testWidgets('should use locale directionality in English and Hebrew', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel english = _viewModel(
        ContractPersistentMemoryService(),
      );
      await english.load();
      await tester.pumpWidget(_app(viewModel: english));
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(MoodMedicinePage))),
        TextDirection.ltr,
      );
      expect(find.byKey(const Key('moodMedicineInsights')), findsOneWidget);

      final MoodMedicineViewModel hebrew = _viewModel(
        ContractPersistentMemoryService(),
      );
      await hebrew.load();
      await tester.pumpWidget(
        _app(viewModel: hebrew, locale: const Locale('he')),
      );
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(MoodMedicinePage))),
        TextDirection.rtl,
      );
      expect(find.byKey(const Key('moodMedicineInsights')), findsOneWidget);
    });

    testWidgets('should preserve a failed check-in draft and expose retry', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final ContractPersistentMemoryService memory =
          ContractPersistentMemoryService();
      var failOnce = true;
      memory.onPersist = (_, PersistentMemoryType _, Object _) {
        if (failOnce) {
          failOnce = false;
          throw StateError('offline');
        }
      };
      final MoodMedicineViewModel viewModel = _viewModel(memory);
      await viewModel.load(initialView: MoodMedicineInitialView.checkIn);
      await tester.pumpWidget(
        _app(
          viewModel: viewModel,
          initialView: MoodMedicineInitialView.checkIn,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('moodMedicineMood4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moodMedicineSaveCheckIn')));
      await tester.pumpAndSettle();

      expect(viewModel.readyState!.snapshot.entries, isEmpty);
      expect(viewModel.readyState!.persistence.pendingCheckInDraft, isNotNull);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(viewModel.readyState!.snapshot.entries, hasLength(1));
      expect(viewModel.readyState!.persistence.hasPendingWrite, isFalse);
    });

    testWidgets(
      'should retain a check-in collision without rendering a retry action',
      (WidgetTester tester) async {
        _setLargeScreen(tester);
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService();
        var shouldCreateCollision = true;
        memory.onPersist = (String key, PersistentMemoryType _, Object value) {
          if (!shouldCreateCollision || key != MoodMedicineStore.snapshotKey) {
            return;
          }
          shouldCreateCollision = false;
          final MoodMedicineEntry intended = MoodMedicineSnapshot.decode(
            value as String,
          ).entries.single;
          memory.store[key] = MoodMedicineSnapshot(
            entries: <MoodMedicineEntry>[
              MoodMedicineEntry(
                id: intended.id,
                occurredAtUtc: intended.occurredAtUtc,
                localDayKey: intended.localDayKey,
                mood: 2,
              ),
            ],
          ).encode();
          throw StateError('offline');
        };
        final MoodMedicineViewModel viewModel = _viewModel(
          memory,
          ids: const <String>['entry-1', 'entry-2'],
        );
        await viewModel.load(initialView: MoodMedicineInitialView.checkIn);
        await tester.pumpWidget(
          _app(
            viewModel: viewModel,
            initialView: MoodMedicineInitialView.checkIn,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('moodMedicineMood4')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('moodMedicineSaveCheckIn')));
        await tester.pumpAndSettle();
        expect(find.text('Try again'), findsOneWidget);

        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(viewModel.readyState!.checkInForm.draft, isNotNull);
        expect(viewModel.readyState!.persistence.hasPendingWrite, isFalse);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.byType(SnackBarAction), findsNothing);
        expect(find.text('Try again'), findsNothing);

        await tester.tap(find.byKey(const Key('moodMedicineSaveCheckIn')));
        await tester.pumpAndSettle();
        expect(
          viewModel.readyState!.snapshot.entries.map(
            (MoodMedicineEntry entry) => entry.id,
          ),
          <String>['entry-1', 'entry-2'],
        );
      },
    );

    testWidgets('should use the fixed editor and expanding journal input', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
      );
      await viewModel.load(initialView: MoodMedicineInitialView.checkIn);
      await tester.pumpWidget(
        _app(
          viewModel: viewModel,
          initialView: MoodMedicineInitialView.checkIn,
          theme: buildLightTheme(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('moodMedicineMood3')));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('moodMedicineNoteField'))).height,
        greaterThan(40),
      );

      await tester.tap(find.text('Manage activities'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add personal activity'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(const Key('moodMedicineActivityEditorField')))
            .height,
        40,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render themed cards and inputs in dark RTL layout', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
      );
      await viewModel.load(initialView: MoodMedicineInitialView.checkIn);
      await tester.pumpWidget(
        _app(
          viewModel: viewModel,
          initialView: MoodMedicineInitialView.checkIn,
          locale: const Locale('ar'),
          theme: buildDarkTheme(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moodMedicineMood3')));
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(MoodMedicinePage))),
        TextDirection.rtl,
      );
      expect(find.byKey(const Key('moodMedicineNoteField')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should offer private-by-default report controls', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
      );
      await viewModel.load();
      viewModel.selectMood(4);
      await viewModel.saveCheckIn();
      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
      await tester.pumpAndSettle();

      final SwitchListTile includeNotes = tester.widget<SwitchListTile>(
        find.byKey(const Key('moodMedicineIncludeNotes')),
      );
      expect(includeNotes.value, isFalse);
      expect(find.text('Personal notes are not included.'), findsOneWidget);
      expect(find.byKey(const Key('moodMedicineViewExport')), findsOneWidget);
    });

    testWidgets('should guide PDF use when a PNG preview is too large', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
        reportExportService: _TestReportExportService(
          buildError: const MoodMedicinePngReportTooLargeException(100),
        ),
      );
      await viewModel.load();
      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();
      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(MoodMedicinePage)),
      )!;

      await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.moodMedicineExportPng));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moodMedicineViewExport')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.moodMedicinePngTooLarge), findsOneWidget);
      expect(find.text(l10n.moodMedicinePreviewError), findsNothing);
    });

    testWidgets('should guide PDF use when a PNG share build is too large', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
        reportExportService: _TestReportExportService(
          buildError: const MoodMedicinePngReportTooLargeException(100),
        ),
      );
      await viewModel.load();
      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();
      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(MoodMedicinePage)),
      )!;

      await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.moodMedicineExportPng));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moodMedicineStartExport')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.moodMedicinePngTooLarge), findsOneWidget);
      expect(find.text(l10n.moodMedicineExportError), findsNothing);
    });

    testWidgets(
      'should restore localized report export after confirmed unreadable-history discard',
      (WidgetTester tester) async {
        _setLargeScreen(tester);
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: '{unreadable',
              },
            );
        final MoodMedicineViewModel viewModel = _viewModel(memory);
        await tester.pumpWidget(
          _app(
            viewModel: viewModel,
            initialView: MoodMedicineInitialView.insights,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('moodMedicineDiscardUnreadable')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('moodMedicineCheckIn')), findsNothing);
        await tester.tap(
          find.byKey(const Key('moodMedicineDiscardUnreadable')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Discard unreadable history').last);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('moodMedicineInsights')), findsOneWidget);
        expect(
          find.byKey(const Key('moodMedicineExportButton')),
          findsOneWidget,
        );
        expect(viewModel.readyState!.presentation, isNotNull);
        expect(await viewModel.buildReport(), isNotNull);
        expect(memory.completedWrites, hasLength(1));
      },
    );

    testWidgets('should not show an export error when sharing is dismissed', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
        reportExportService: _TestReportExportService(
          deliveryStatus: MoodMedicineReportDeliveryStatus.dismissed,
        ),
      );
      await viewModel.load();
      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(await viewModel.buildReport(), isNotNull);
      expect(await viewModel.shareBuiltReport(), isFalse);
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
