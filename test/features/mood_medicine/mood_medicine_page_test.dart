import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mocktail/mocktail.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_exporter.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_renderer.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_source_link_service.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_store.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_content.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_insights.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_page.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_trend_chart.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_model.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_state.dart';
import 'package:mazilon/util/theme/app_theme.dart';

import '../../helpers/widget_test_scaffold.dart';
import '../../../test_support/contract_persistent_memory_service.dart';

final class _MockMoodMedicineReportExportService extends Mock
    implements MoodMedicineReportExportService {}

final class _MockMoodMedicineSourceLinkService extends Mock
    implements MoodMedicineSourceLinkService {}

final class _FakeMoodMedicineReportInput extends Fake
    implements MoodMedicineReportInput {}

final class _FakeMoodMedicineBuiltReport extends Fake
    implements MoodMedicineBuiltReport {}

MoodMedicineReportExportService _reportExportService({
  MoodMedicineReportDeliveryStatus deliveryStatus =
      MoodMedicineReportDeliveryStatus.delivered,
  Object? buildError,
  Object? deliveryError,
}) {
  final _MockMoodMedicineReportExportService mock =
      _MockMoodMedicineReportExportService();

  when(() => mock.build(any(), any())).thenAnswer((
    Invocation invocation,
  ) async {
    if (buildError != null) {
      throw buildError;
    }
    final MoodMedicineReportInput input =
        invocation.positionalArguments[0] as MoodMedicineReportInput;
    final MoodMedicineReportFormat format =
        invocation.positionalArguments[1] as MoodMedicineReportFormat;
    return MoodMedicineBuiltReport(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      fileName: input.fileNameFor(format),
      format: format,
    );
  });

  when(
    () => mock.deliver(any(), shareText: any(named: 'shareText')),
  ).thenAnswer((_) async {
    if (deliveryError != null) {
      throw deliveryError;
    }
    return MoodMedicineReportDelivery(deliveryStatus);
  });
  return mock;
}

/// Holds delayed Mocktail exporter calls while a page's locale changes.
final class _DelayedReportExportService {
  _DelayedReportExportService() {
    when(() => mock.build(any(), any())).thenAnswer((Invocation invocation) {
      final _DelayedReportBuild build = _DelayedReportBuild(
        input: invocation.positionalArguments[0] as MoodMedicineReportInput,
        format: invocation.positionalArguments[1] as MoodMedicineReportFormat,
      );
      builds.add(build);
      return build.completer.future;
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
  final List<_DelayedReportBuild> builds = <_DelayedReportBuild>[];
  int deliveryCount = 0;

  void completeBuild(int index) {
    final _DelayedReportBuild build = builds[index];
    build.completer.complete(
      MoodMedicineBuiltReport(
        bytes: Uint8List.fromList(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9WlDqsoAAAAASUVORK5CYII=',
          ),
        ),
        fileName: build.input.fileNameFor(build.format),
        format: build.format,
      ),
    );
  }
}

final class _DelayedReportBuild {
  _DelayedReportBuild({required this.input, required this.format});

  final MoodMedicineReportInput input;
  final MoodMedicineReportFormat format;
  final Completer<MoodMedicineBuiltReport> completer =
      Completer<MoodMedicineBuiltReport>();
}

_MockMoodMedicineSourceLinkService _sourceLinkService({
  bool opened = true,
  Object? error,
}) {
  final _MockMoodMedicineSourceLinkService mock =
      _MockMoodMedicineSourceLinkService();
  when(() => mock.openExternal(any())).thenAnswer((_) async {
    if (error != null) {
      throw error;
    }
    return opened;
  });
  return mock;
}

MoodMedicineViewModel _viewModel(
  ContractPersistentMemoryService memory, {
  DateTime? clock,
  MoodMedicineReportExportService? reportExportService,
  MoodMedicineSourceLinkService? sourceLinkService,
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
    reportExportService ?? _reportExportService(),
    sourceLinkService: sourceLinkService ?? _sourceLinkService(),
    incidentLoggerService: NoopIncidentLoggerService(),
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

enum _SourceEntryPoint { activity, education }

Future<({AppLocalizations l10n, Uri expectedUri})> _openSourceAction(
  WidgetTester tester, {
  required MoodMedicineViewModel viewModel,
  required _SourceEntryPoint entryPoint,
}) async {
  final MoodMedicineInitialView initialView = switch (entryPoint) {
    _SourceEntryPoint.activity => MoodMedicineInitialView.checkIn,
    _SourceEntryPoint.education => MoodMedicineInitialView.education,
  };
  await viewModel.load(initialView: initialView);
  if (entryPoint == _SourceEntryPoint.activity) {
    viewModel.selectMood(3);
  }
  await tester.pumpWidget(
    _app(
      viewModel: viewModel,
      initialView: initialView,
      locale: const Locale('he'),
    ),
  );
  await tester.pumpAndSettle();

  final AppLocalizations l10n = AppLocalizations.of(
    tester.element(find.byType(MoodMedicinePage)),
  )!;
  final MoodMedicineActivityContent activity = MoodMedicineContent.activityFor(
    l10n,
    entryPoint == _SourceEntryPoint.activity
        ? MoodMedicineContent.physicalActivityId
        : MoodMedicineContent.nourishingMealId,
  )!;

  switch (entryPoint) {
    case _SourceEntryPoint.activity:
      final Finder infoButton = find.descendant(
        of: find.byKey(
          const Key(
            'moodMedicineActivity${MoodMedicineContent.physicalActivityId}',
          ),
        ),
        matching: find.byIcon(Icons.info_outline),
      );
      await tester.ensureVisible(infoButton);
      await tester.pumpAndSettle();
      await tester.tap(infoButton);
      await tester.pumpAndSettle();
      final Finder sourceButton = find.byKey(
        const Key(
          'moodMedicineActivitySource${MoodMedicineContent.physicalActivityId}',
        ),
      );
      await tester.ensureVisible(sourceButton);
      await tester.tap(sourceButton);
      break;
    case _SourceEntryPoint.education:
      final Finder sourceButton = find.byKey(
        const Key('moodMedicineEducationSource'),
      );
      await tester.ensureVisible(sourceButton);
      await tester.pumpAndSettle();
      await tester.tap(sourceButton);
      break;
  }
  await tester.pumpAndSettle();
  return (l10n: l10n, expectedUri: activity.sourceUri);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(_FakeMoodMedicineReportInput());
    registerFallbackValue(_FakeMoodMedicineBuiltReport());
    registerFallbackValue(MoodMedicineReportFormat.pdf);
    registerFallbackValue(Uri.parse('https://example.test'));
  });

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

    testWidgets('should plot every same-day check-in as a separate point', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineSnapshot snapshot = MoodMedicineSnapshot(
        entries: <MoodMedicineEntry>[
          MoodMedicineEntry(
            id: 'later',
            occurredAtUtc: DateTime.utc(2026, 8, 29, 18),
            localDayKey: '2026-08-29',
            mood: 5,
            activityIds: const <String>['social_connection'],
          ),
          MoodMedicineEntry(
            id: 'earlier',
            occurredAtUtc: DateTime.utc(2026, 8, 29, 8),
            localDayKey: '2026-08-29',
            mood: 1,
            activityIds: const <String>['music'],
          ),
        ],
      );
      final ContractPersistentMemoryService memory =
          ContractPersistentMemoryService(
            initialValues: <String, Object?>{
              MoodMedicineStore.snapshotKey: snapshot.encode(),
            },
          );
      final MoodMedicineViewModel viewModel = _viewModel(memory);
      await viewModel.load();

      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();

      final MoodMedicineTrendChart chart = tester.widget(
        find.byType(MoodMedicineTrendChart),
      );
      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(MoodMedicinePage)),
      )!;
      expect(chart.points, hasLength(2));
      expect(
        chart.points.map((MoodMedicineTrendPoint point) => point.mood),
        <double>[1, 5],
      );
      expect(chart.points.first.activityIds, <String>{'music'});
      expect(chart.points.last.activityIds, <String>{'social_connection'});
      expect(chart.activityColors, MoodMedicineContent.activityColors);
      expect(chart.semanticSummary, isNot(contains('2026-08-29')));
      expect(
        intl.DateFormat.yMMMMd(
          'en',
        ).format(DateTime(2026, 8, 29)).allMatches(chart.semanticSummary),
        hasLength(2),
      );
      expect(viewModel.readyState!.dashboard.summaries, hasLength(1));
      expect(find.text(l10n.moodMedicineEachCheckIn), findsOneWidget);
      expect(find.text(l10n.moodMedicineOneEntry), findsNothing);
      expect(find.text(l10n.moodMedicineActivitiesOverlay), findsOneWidget);
      expect(
        find.text(
          MoodMedicineContent.activityFor(
            l10n,
            MoodMedicineContent.musicId,
          )!.label,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('moodMedicineOverlay${MoodMedicineContent.musicId}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key(
            'moodMedicineOverlay${MoodMedicineContent.socialConnectionId}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          MoodMedicineContent.activityFor(
            l10n,
            MoodMedicineContent.socialConnectionId,
          )!.label,
        ),
        findsOneWidget,
      );
    });

    testWidgets('should disclose omitted older checks in a large year trend', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineSnapshot snapshot = MoodMedicineSnapshot(
        entries: List<MoodMedicineEntry>.generate(
          MoodMedicineInsights.maxYearTrendPoints + 1,
          (int index) => MoodMedicineEntry(
            id: 'year-$index',
            occurredAtUtc: DateTime.utc(
              2026,
              8,
              29,
            ).add(Duration(minutes: index)),
            localDayKey: '2026-08-29',
            mood: index % 5 + 1,
          ),
        ),
      );
      final ContractPersistentMemoryService memory =
          ContractPersistentMemoryService(
            initialValues: <String, Object?>{
              MoodMedicineStore.snapshotKey: snapshot.encode(),
            },
          );
      final MoodMedicineViewModel viewModel = _viewModel(
        memory,
        clock: DateTime(2026, 8, 29, 12),
      );
      await viewModel.load();

      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();
      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(MoodMedicinePage)),
      )!;
      await tester.tap(find.text(l10n.moodMedicineYear));
      await tester.pumpAndSettle();

      expect(
        find.text(
          l10n.moodMedicineTrendOmitted(
            MoodMedicineInsights.maxYearTrendPoints,
            1,
          ),
        ),
        findsOneWidget,
      );
      final MoodMedicineTrendChart chart = tester.widget(
        find.byType(MoodMedicineTrendChart),
      );
      expect(
        chart.semanticSummary,
        isNot(
          contains(
            l10n.moodMedicineTrendOmitted(
              MoodMedicineInsights.maxYearTrendPoints,
              1,
            ),
          ),
        ),
      );
      expect(
        viewModel.readyState!.dashboard.trendSeries.checkIns,
        hasLength(MoodMedicineInsights.maxYearTrendPoints),
      );
    });

    testWidgets('should format trend dates for each supported locale', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineSnapshot snapshot = MoodMedicineSnapshot(
        entries: <MoodMedicineEntry>[
          MoodMedicineEntry(
            id: 'localized-day',
            occurredAtUtc: DateTime.utc(2026, 8, 29, 8),
            localDayKey: '2026-08-29',
            mood: 4,
          ),
        ],
      );
      for (final Locale locale in const <Locale>[
        Locale('en'),
        Locale('he'),
        Locale('ar'),
      ]) {
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: snapshot.encode(),
              },
            );
        final MoodMedicineViewModel viewModel = _viewModel(memory);
        await viewModel.load();
        await tester.pumpWidget(_app(viewModel: viewModel, locale: locale));
        await tester.pumpAndSettle();

        final MoodMedicineTrendChart chart = tester.widget(
          find.byType(MoodMedicineTrendChart),
        );
        final String localizedDate = intl.DateFormat.yMMMMd(
          locale.languageCode,
        ).format(DateTime(2026, 8, 29));
        expect(chart.semanticSummary, contains(localizedDate));
        expect(chart.semanticSummary, isNot(contains('2026-08-29')));
      }
    });

    test('should pluralize omitted trend checks in every locale', () async {
      for (final Locale locale in const <Locale>[
        Locale('en'),
        Locale('he'),
        Locale('ar'),
      ]) {
        final AppLocalizations l10n = await AppLocalizations.delegate.load(
          locale,
        );
        final String singular = l10n.moodMedicineTrendOmitted(1000, 1);
        final String plural = l10n.moodMedicineTrendOmitted(1000, 2);
        switch (locale.languageCode) {
          case 'en':
            expect(
              singular,
              'Showing the latest 1000 check-ins; '
              '1 older check-in is not shown.',
            );
            expect(
              plural,
              'Showing the latest 1000 check-ins; '
              '2 older check-ins are not shown.',
            );
          case 'he':
            expect(
              singular,
              'מוצגות 1000 הבדיקות האחרונות; '
              'בדיקה ישנה יותר אחת אינה מוצגת.',
            );
            expect(
              plural,
              'מוצגות 1000 הבדיקות האחרונות; '
              '2 בדיקות ישנות יותר אינן מוצגות.',
            );
          case 'ar':
            expect(
              singular,
              'يتم عرض أحدث 1000 تسجيل؛ '
              'لا يتم عرض تسجيل أقدم واحد.',
            );
            expect(
              plural,
              'يتم عرض أحدث 1000 تسجيل؛ '
              'لا يتم عرض تسجيلين أقدمين.',
            );
        }
      }
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

    testWidgets(
      'should keep PDF activity and D.O.S.E. colour cues in both themes',
      (WidgetTester tester) async {
        _setLargeScreen(tester);
        final MoodMedicineViewModel checkInViewModel = _viewModel(
          ContractPersistentMemoryService(),
        );
        await checkInViewModel.load(
          initialView: MoodMedicineInitialView.checkIn,
        );
        await tester.pumpWidget(
          _app(
            viewModel: checkInViewModel,
            initialView: MoodMedicineInitialView.checkIn,
            theme: buildLightTheme(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('moodMedicineMood3')));
        await tester.pumpAndSettle();

        final FilterChip physicalActivityChip = tester.widget<FilterChip>(
          find.byKey(
            const Key(
              'moodMedicineActivity${MoodMedicineContent.physicalActivityId}',
            ),
          ),
        );
        expect(
          (physicalActivityChip.avatar! as Icon).color,
          const Color(0xFF1875D1),
        );

        final MoodMedicineViewModel educationViewModel = _viewModel(
          ContractPersistentMemoryService(),
        );
        await educationViewModel.load(
          initialView: MoodMedicineInitialView.education,
        );
        await tester.pumpWidget(
          _app(
            viewModel: educationViewModel,
            initialView: MoodMedicineInitialView.education,
            locale: const Locale('ar'),
            theme: buildDarkTheme(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          Directionality.of(tester.element(find.byType(MoodMedicinePage))),
          TextDirection.rtl,
        );
        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(MoodMedicinePage)),
        )!;
        for (final MoodMedicineDoseContent item
            in MoodMedicineContent.doseItems(l10n)) {
          final DecoratedBox surface = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byKey(Key('moodMedicineDose${item.kind.name}')),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          final BoxDecoration decoration = surface.decoration as BoxDecoration;
          expect((decoration.border! as Border).top.color, item.color);
        }
        expect(tester.takeException(), isNull);
      },
    );

    for (final _SourceEntryPoint entryPoint in _SourceEntryPoint.values) {
      testWidgets(
        'should open the ${entryPoint.name} source without an error',
        (WidgetTester tester) async {
          _setLargeScreen(tester);
          final _MockMoodMedicineSourceLinkService sourceLinkService =
              _sourceLinkService();
          final MoodMedicineViewModel viewModel = _viewModel(
            ContractPersistentMemoryService(),
            sourceLinkService: sourceLinkService,
          );

          final (:l10n, :expectedUri) = await _openSourceAction(
            tester,
            viewModel: viewModel,
            entryPoint: entryPoint,
          );

          verify(() => sourceLinkService.openExternal(expectedUri)).called(1);
          final MoodMedicineActivityContent sourceActivity =
              MoodMedicineContent.activities(l10n).firstWhere(
                (MoodMedicineActivityContent activity) =>
                    activity.sourceUri == expectedUri,
              );
          expect(
            find.text(
              '${l10n.moodMedicineOpenSource}: ${sourceActivity.sourceLabel}',
            ),
            findsOneWidget,
          );
          expect(find.text(l10n.asyncErrorMessage), findsNothing);
        },
      );

      testWidgets(
        'should show localized error when the ${entryPoint.name} source is unavailable',
        (WidgetTester tester) async {
          _setLargeScreen(tester);
          final _MockMoodMedicineSourceLinkService sourceLinkService =
              _sourceLinkService(opened: false);
          final MoodMedicineViewModel viewModel = _viewModel(
            ContractPersistentMemoryService(),
            sourceLinkService: sourceLinkService,
          );

          final (:l10n, :expectedUri) = await _openSourceAction(
            tester,
            viewModel: viewModel,
            entryPoint: entryPoint,
          );

          verify(() => sourceLinkService.openExternal(expectedUri)).called(1);
          expect(find.text(l10n.asyncErrorMessage), findsOneWidget);
        },
      );

      testWidgets(
        'should show localized error when the ${entryPoint.name} source throws',
        (WidgetTester tester) async {
          _setLargeScreen(tester);
          final _MockMoodMedicineSourceLinkService sourceLinkService =
              _sourceLinkService(error: StateError('launch failed'));
          final MoodMedicineViewModel viewModel = _viewModel(
            ContractPersistentMemoryService(),
            sourceLinkService: sourceLinkService,
          );

          final (:l10n, :expectedUri) = await _openSourceAction(
            tester,
            viewModel: viewModel,
            entryPoint: entryPoint,
          );

          verify(() => sourceLinkService.openExternal(expectedUri)).called(1);
          expect(find.text(l10n.asyncErrorMessage), findsOneWidget);
        },
      );
    }

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

    testWidgets('should update an open export sheet when locale changes', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
      );
      await viewModel.load();
      viewModel.selectRange(MoodMedicineInsightRange.year);
      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();

      final AppLocalizations english = AppLocalizations.of(
        tester.element(find.byType(MoodMedicinePage)),
      )!;
      await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
      await tester.pumpAndSettle();

      final Finder sheet = find.byType(BottomSheet);
      await tester.tap(
        find.descendant(
          of: sheet,
          matching: find.text(english.moodMedicineExportPng),
        ),
      );
      await tester.pumpAndSettle();

      List<String> visibleSheetText(AppLocalizations l10n) => <String>[
        l10n.moodMedicineExport,
        '${l10n.moodMedicineExportRange}: ${l10n.moodMedicineYear}',
        l10n.moodMedicineExportPdf,
        l10n.moodMedicineExportPng,
        l10n.moodMedicinePngPrintGuidance,
        l10n.moodMedicineIncludeNotes,
        l10n.moodMedicineNotesPrivacy,
        l10n.moodMedicineNotesExcluded,
        l10n.moodMedicineView,
        l10n.moodMedicineShare,
      ];
      for (final String text in visibleSheetText(english)) {
        expect(
          find.descendant(of: sheet, matching: find.text(text)),
          findsOneWidget,
        );
      }

      await tester.pumpWidget(
        _app(viewModel: viewModel, locale: const Locale('he')),
      );
      await tester.pumpAndSettle();

      final AppLocalizations hebrew = AppLocalizations.of(
        tester.element(find.byType(MoodMedicinePage)),
      )!;
      for (final String text in visibleSheetText(hebrew)) {
        expect(
          find.descendant(of: sheet, matching: find.text(text)),
          findsOneWidget,
        );
      }
      for (final String text in visibleSheetText(
        english,
      ).where((String text) => !visibleSheetText(hebrew).contains(text))) {
        expect(
          find.descendant(of: sheet, matching: find.text(text)),
          findsNothing,
        );
      }
      expect(
        Directionality.of(
          tester.element(find.byKey(const Key('moodMedicineIncludeNotes'))),
        ),
        TextDirection.rtl,
      );
    });

    testWidgets('should reset note consent when the export sheet closes', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
      );
      await viewModel.load();
      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moodMedicineIncludeNotes')));
      await tester.pumpAndSettle();
      expect(viewModel.readyState!.export.includeNotes, isTrue);

      Navigator.of(
        tester.element(find.byKey(const Key('moodMedicineIncludeNotes'))),
      ).pop();
      await tester.pumpAndSettle();

      expect(viewModel.readyState!.export.includeNotes, isFalse);
      await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('moodMedicineIncludeNotes')),
            )
            .value,
        isFalse,
      );
    });

    testWidgets(
      'should disable the export entry until a dismissed build completes',
      (WidgetTester tester) async {
        _setLargeScreen(tester);
        final _DelayedReportExportService exporter =
            _DelayedReportExportService();
        final MoodMedicineViewModel viewModel = _viewModel(
          ContractPersistentMemoryService(),
          reportExportService: exporter.mock,
        );
        await viewModel.load();
        await tester.pumpWidget(_app(viewModel: viewModel));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('moodMedicineViewExport')));
        await tester.pump();
        expect(exporter.builds, hasLength(1));

        Navigator.of(
          tester.element(find.byKey(const Key('moodMedicineViewExport'))),
        ).pop();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<OutlinedButton>(
                find.byKey(const Key('moodMedicineExportButton')),
              )
              .onPressed,
          isNull,
        );

        exporter.completeBuild(0);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<OutlinedButton>(
                find.byKey(const Key('moodMedicineExportButton')),
              )
              .onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'should retry a locale-stale build before opening a report preview',
      (WidgetTester tester) async {
        _setLargeScreen(tester);
        final _DelayedReportExportService exporter =
            _DelayedReportExportService();
        final MoodMedicineViewModel viewModel = _viewModel(
          ContractPersistentMemoryService(),
          reportExportService: exporter.mock,
        );
        await viewModel.load();
        await tester.pumpWidget(_app(viewModel: viewModel));
        await tester.pumpAndSettle();
        final AppLocalizations english = AppLocalizations.of(
          tester.element(find.byType(MoodMedicinePage)),
        )!;

        await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(english.moodMedicineExportPng));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('moodMedicineViewExport')));
        await tester.pump();
        expect(exporter.builds, hasLength(1));
        final String initialTitle = exporter.builds.single.input.title;

        await tester.pumpWidget(
          _app(viewModel: viewModel, locale: const Locale('he')),
        );
        await tester.pump();
        exporter.completeBuild(0);
        await tester.pump();
        expect(exporter.builds, hasLength(2));
        expect(exporter.builds.last.input.title, isNot(initialTitle));

        exporter.completeBuild(1);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('moodMedicinePngPreview')), findsOneWidget);
      },
    );

    testWidgets('should retry a locale-stale build before sharing a report', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final _DelayedReportExportService exporter =
          _DelayedReportExportService();
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
        reportExportService: exporter.mock,
      );
      await viewModel.load();
      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();
      final AppLocalizations english = AppLocalizations.of(
        tester.element(find.byType(MoodMedicinePage)),
      )!;

      await tester.tap(find.byKey(const Key('moodMedicineExportButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.moodMedicineExportPng));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moodMedicineStartExport')));
      await tester.pump();
      expect(exporter.builds, hasLength(1));
      final String initialTitle = exporter.builds.single.input.title;

      await tester.pumpWidget(
        _app(viewModel: viewModel, locale: const Locale('he')),
      );
      await tester.pump();
      exporter.completeBuild(0);
      await tester.pump();
      expect(exporter.builds, hasLength(2));
      expect(exporter.builds.last.input.title, isNot(initialTitle));

      exporter.completeBuild(1);
      await tester.pumpAndSettle();

      expect(exporter.deliveryCount, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('should guide PDF use when a PNG preview is too large', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
        reportExportService: _reportExportService(
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
        reportExportService: _reportExportService(
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
        final MoodMedicineReportBuildOutcome outcome = await viewModel
            .buildReport();
        expect(outcome, isA<MoodMedicineReportBuiltOutcome>());
        expect(memory.completedWrites, hasLength(1));
      },
    );

    testWidgets(
      'should show the generic async error for a failed history discard',
      (WidgetTester tester) async {
        _setLargeScreen(tester);
        final ContractPersistentMemoryService memory =
            ContractPersistentMemoryService(
              initialValues: <String, Object?>{
                MoodMedicineStore.snapshotKey: '{unreadable',
              },
            );
        memory.onPersist = (_, PersistentMemoryType _, Object _) {
          throw StateError('history storage failed');
        };
        final MoodMedicineViewModel viewModel = _viewModel(memory);
        await tester.pumpWidget(_app(viewModel: viewModel));
        await tester.pumpAndSettle();
        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(MoodMedicinePage)),
        )!;

        await tester.tap(
          find.byKey(const Key('moodMedicineDiscardUnreadable')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.moodMedicineDiscardUnreadable).last);
        await tester.pumpAndSettle();

        expect(find.text(l10n.asyncErrorMessage), findsOneWidget);
        expect(find.text(l10n.moodMedicineExportError), findsNothing);
      },
    );

    for (final bool deliveryThrows in <bool>[false, true]) {
      testWidgets(
        'should show a localized export error and keep the sheet open when '
        'sharing ${deliveryThrows ? 'throws' : 'returns a failed status'}',
        (WidgetTester tester) async {
          _setLargeScreen(tester);
          final MoodMedicineViewModel viewModel = _viewModel(
            ContractPersistentMemoryService(),
            reportExportService: _reportExportService(
              deliveryStatus: MoodMedicineReportDeliveryStatus.failed,
              deliveryError: deliveryThrows
                  ? StateError('handoff failed')
                  : null,
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
          final Finder sheet = find.byType(BottomSheet);

          await tester.tap(
            find.descendant(
              of: sheet,
              matching: find.byKey(const Key('moodMedicineStartExport')),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(l10n.moodMedicineExportError), findsOneWidget);
          expect(sheet, findsOneWidget);
          expect(
            find.descendant(
              of: sheet,
              matching: find.byKey(const Key('moodMedicineStartExport')),
            ),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('should not show an export error when sharing is dismissed', (
      WidgetTester tester,
    ) async {
      _setLargeScreen(tester);
      final MoodMedicineViewModel viewModel = _viewModel(
        ContractPersistentMemoryService(),
        reportExportService: _reportExportService(
          deliveryStatus: MoodMedicineReportDeliveryStatus.dismissed,
        ),
      );
      await viewModel.load();
      await tester.pumpWidget(_app(viewModel: viewModel));
      await tester.pumpAndSettle();

      final MoodMedicineReportBuildOutcome outcome = await viewModel
          .buildReport();
      expect(outcome, isA<MoodMedicineReportBuiltOutcome>());
      expect(await viewModel.shareBuiltReport(), isFalse);
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
