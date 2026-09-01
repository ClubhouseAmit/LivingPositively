import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_exporter.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_repository.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_source_link_service.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_store.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_page.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_model.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_state.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../MenuTest/TestMenu.dart';
import '../../MenuTest/test_data.dart';
import '../../helpers/widget_test_scaffold.dart';
import '../../../test_support/contract_persistent_memory_service.dart';

final class _PromptAnalyticsService implements AnalyticsService {
  @override
  Future<void> init() async {}

  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {}
}

final class _MockMoodMedicineRepository extends Mock
    implements MoodMedicineRepository {}

final class _MockMoodMedicineSourceLinkService extends Mock
    implements MoodMedicineSourceLinkService {}

MoodMedicineSnapshot _fallbackSnapshotMutation(MoodMedicineSnapshot snapshot) {
  return snapshot;
}

MoodMedicineSourceLinkService _sourceLinkService() {
  final _MockMoodMedicineSourceLinkService mock =
      _MockMoodMedicineSourceLinkService();
  when(() => mock.openExternal(any())).thenAnswer((_) async => true);
  return mock;
}

/// Holds the state for a Mocktail repository boundary mock. Returning a
/// captured missing outcome lets the tests prove Menu rejects the stale prompt
/// by Home-session identity, rather than accidentally passing because a later
/// read sees the new snapshot.
final class _PromptRaceRepository {
  _PromptRaceRepository() {
    when(() => mock.loadSnapshot()).thenAnswer((_) {
      loadCount++;
      if (loadCount == 1) {
        return _firstLoad.future;
      }
      return Future<MoodMedicineLoadResult>.value(
        MoodMedicineLoadedSnapshot(_snapshot),
      );
    });
    when(() => mock.mutateSnapshot(any())).thenAnswer((
      Invocation invocation,
    ) async {
      final MoodMedicineSnapshotMutation mutation =
          invocation.positionalArguments.single as MoodMedicineSnapshotMutation;
      _snapshot = mutation(_snapshot);
      return MoodMedicineLoadedSnapshot(_snapshot);
    });
    when(() => mock.discardUnreadableSnapshot()).thenAnswer((_) {
      return Future<MoodMedicineLoadResult>.value(
        MoodMedicineLoadedSnapshot(_snapshot),
      );
    });
  }

  final _MockMoodMedicineRepository mock = _MockMoodMedicineRepository();
  final Completer<MoodMedicineLoadResult> _firstLoad =
      Completer<MoodMedicineLoadResult>();
  MoodMedicineSnapshot _snapshot = const MoodMedicineSnapshot.empty();
  int loadCount = 0;

  MoodMedicineSnapshot get snapshot => _snapshot;

  void completeStalePromptLoad() {
    _firstLoad.complete(const MoodMedicineMissingSnapshot());
  }
}

String _snapshotWithTodayCheckIn() {
  final DateTime now = DateTime.now();
  return MoodMedicineSnapshot(
    entries: <MoodMedicineEntry>[
      MoodMedicineEntry(
        id: 'today-check-in',
        occurredAtUtc: now.toUtc(),
        localDayKey: moodMedicineLocalDayKey(now),
        mood: 3,
      ),
    ],
  ).encode();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(_fallbackSnapshotMutation);
    registerFallbackValue(Uri.parse('https://example.test'));
  });

  late UserInformation user;
  late AppInformation app;
  late ContractPersistentMemoryService memory;

  setUp(() async {
    await GetIt.instance.reset();
    memory = ContractPersistentMemoryService(
      initialValues: <String, Object?>{'hasFilled': false, 'location': ''},
    );
    getIt.registerLazySingleton<PersistentMemoryService>(() => memory);
    getIt.registerLazySingleton<AnalyticsService>(
      () => _PromptAnalyticsService(),
    );
    getIt.registerLazySingleton<IncidentLoggerService>(
      () => NoopIncidentLoggerService(),
    );
    getIt.registerLazySingleton<MoodMedicineStore>(
      () => MoodMedicineStore(memory),
    );
    getIt.registerLazySingleton<MoodMedicineRepository>(
      () => getIt<MoodMedicineStore>(),
    );
    getIt.registerLazySingleton<MoodMedicineReportExportService>(
      () => MoodMedicineReportExporter(
        incidentLoggerService: getIt<IncidentLoggerService>(),
      ),
    );
    getIt.registerLazySingleton<MoodMedicineSourceLinkService>(
      _sourceLinkService,
    );
    getIt.registerFactory<MoodMedicineViewModel>(
      () => MoodMedicineViewModel(
        getIt<MoodMedicineRepository>(),
        getIt<MoodMedicineReportExportService>(),
        sourceLinkService: getIt<MoodMedicineSourceLinkService>(),
        incidentLoggerService: getIt<IncidentLoggerService>(),
      ),
    );
    PackageInfo.setMockInitialValues(
      appName: 'Mazilon',
      packageName: 'mazilon',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    user = UserInformation()
      ..gender = 'male'
      ..localeName = 'en';
    app = AppInformation();
    getData(app);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<void> pumpMenu(
    WidgetTester tester, {
    String? snapshot,
    MoodMedicineViewModel Function()? moodMedicineViewModelFactory,
  }) async {
    if (snapshot != null) {
      memory.store[MoodMedicineStore.snapshotKey] = snapshot;
    } else {
      memory.store.remove(MoodMedicineStore.snapshotKey);
    }
    await tester.pumpWidget(
      getMenuForTests(
        user,
        app,
        locale: const Locale('en'),
        moodMedicineViewModelFactory: moodMedicineViewModelFactory,
      ),
    );
  }

  group('MoodMedicineMenu', () {
    testWidgets(
      'should keep an uncomposed Menu stable when Mood Medicine is unavailable',
      (WidgetTester tester) async {
        getIt.unregister<MoodMedicineViewModel>();

        await pumpMenu(tester);
        await tester.pumpAndSettle();

        expect(find.byType(Home), findsOneWidget);
        expect(find.byType(MoodMedicinePage), findsNothing);
        final TextButton action = tester.widget<TextButton>(
          find.byKey(const Key('moodMedicineHomeInsights')),
        );
        expect(action.onPressed, isNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should open the check-in after its first frame when today has no snapshot entry',
      (WidgetTester tester) async {
        await pumpMenu(tester);

        expect(find.byType(Home), findsOneWidget);

        await tester.pumpAndSettle();

        final MoodMedicinePage page = tester.widget<MoodMedicinePage>(
          find.byType(MoodMedicinePage),
        );
        expect(page.initialView, MoodMedicineInitialView.checkIn);
      },
    );

    testWidgets(
      'should use an injected factory for the first-frame check-in prompt',
      (WidgetTester tester) async {
        getIt.unregister<MoodMedicineViewModel>();
        final List<MoodMedicineViewModel> created = <MoodMedicineViewModel>[];

        await pumpMenu(
          tester,
          moodMedicineViewModelFactory: () {
            final MoodMedicineViewModel viewModel = MoodMedicineViewModel(
              getIt<MoodMedicineRepository>(),
              getIt<MoodMedicineReportExportService>(),
              sourceLinkService: getIt<MoodMedicineSourceLinkService>(),
              incidentLoggerService: getIt<IncidentLoggerService>(),
            );
            created.add(viewModel);
            return viewModel;
          },
        );
        await tester.pumpAndSettle();

        final MoodMedicinePage page = tester.widget<MoodMedicinePage>(
          find.byType(MoodMedicinePage),
        );
        expect(created, hasLength(1));
        expect(page.viewModel, same(created.single));
        expect(page.initialView, MoodMedicineInitialView.checkIn);
      },
    );

    testWidgets(
      'should keep a returned Home session visible when a stale prompt load completes',
      (WidgetTester tester) async {
        final _PromptRaceRepository repository = _PromptRaceRepository();

        await pumpMenu(
          tester,
          moodMedicineViewModelFactory: () => MoodMedicineViewModel(
            repository.mock,
            getIt<MoodMedicineReportExportService>(),
            sourceLinkService: getIt<MoodMedicineSourceLinkService>(),
            incidentLoggerService: getIt<IncidentLoggerService>(),
          ),
        );
        await tester.pump();
        expect(repository.loadCount, 1);

        await tester.tap(find.byKey(const Key('moodMedicineHomeInsights')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('bottomNavHome')));
        await tester.pumpAndSettle();
        expect(find.byType(Home), findsOneWidget);

        repository.completeStalePromptLoad();
        await tester.pumpAndSettle();

        expect(find.byType(Home), findsOneWidget);
        expect(find.byType(MoodMedicinePage), findsNothing);
      },
    );

    testWidgets(
      'should suppress a stale prompt after a concurrent manual same-day check-in',
      (WidgetTester tester) async {
        final _PromptRaceRepository repository = _PromptRaceRepository();

        await pumpMenu(
          tester,
          moodMedicineViewModelFactory: () => MoodMedicineViewModel(
            repository.mock,
            getIt<MoodMedicineReportExportService>(),
            sourceLinkService: getIt<MoodMedicineSourceLinkService>(),
            incidentLoggerService: getIt<IncidentLoggerService>(),
          ),
        );
        await tester.pump();
        expect(repository.loadCount, 1);

        await tester.tap(find.byKey(const Key('mainMenuButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('moodMedicineQuickCheckIn')));
        await tester.pumpAndSettle();
        expect(find.byType(MoodMedicinePage), findsOneWidget);

        await tester.tap(find.byKey(const Key('moodMedicineMood4')));
        await tester.pumpAndSettle();
        final Finder checkInScrollable = find.descendant(
          of: find.byKey(const Key('moodMedicineCheckIn')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('moodMedicineSaveCheckIn')),
          300,
          scrollable: checkInScrollable.first,
        );
        await tester.drag(checkInScrollable.first, const Offset(0, -240));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('moodMedicineSaveCheckIn')));
        await tester.pumpAndSettle();
        expect(repository.snapshot.entries, hasLength(1));

        await tester.tap(find.byKey(const Key('bottomNavHome')));
        await tester.pumpAndSettle();
        expect(find.byType(Home), findsOneWidget);

        repository.completeStalePromptLoad();
        await tester.pumpAndSettle();

        expect(find.byType(Home), findsOneWidget);
        expect(find.byType(MoodMedicinePage), findsNothing);
      },
    );

    testWidgets(
      'should keep Home visible after its first frame when today already has a check-in',
      (WidgetTester tester) async {
        await pumpMenu(tester, snapshot: _snapshotWithTodayCheckIn());

        await tester.pumpAndSettle();

        expect(find.byType(Home), findsOneWidget);
        expect(find.byType(MoodMedicinePage), findsNothing);
      },
    );

    testWidgets(
      'should prompt again after a dismissed check-in is reopened with no saved entry',
      (WidgetTester tester) async {
        await pumpMenu(tester);
        await tester.pumpAndSettle();
        expect(find.byType(MoodMedicinePage), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(Home), findsOneWidget);
        expect(
          memory.store.containsKey(MoodMedicineStore.snapshotKey),
          isFalse,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await pumpMenu(tester);
        await tester.pumpAndSettle();

        final MoodMedicinePage page = tester.widget<MoodMedicinePage>(
          find.byType(MoodMedicinePage),
        );
        expect(page.initialView, MoodMedicineInitialView.checkIn);
      },
    );

    testWidgets(
      'should leave Home visible and preserve corrupt history after its first frame',
      (WidgetTester tester) async {
        await pumpMenu(tester, snapshot: '{unreadable');

        await tester.pumpAndSettle();

        expect(find.byType(Home), findsOneWidget);
        expect(find.byType(MoodMedicinePage), findsNothing);
        expect(
          memory.completedWrites.where(
            (write) => write.key == MoodMedicineStore.snapshotKey,
          ),
          isEmpty,
        );
        expect(memory.store[MoodMedicineStore.snapshotKey], '{unreadable');
      },
    );
  });
}
