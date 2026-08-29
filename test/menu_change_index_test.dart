// Drives _MenuState.changeCurrentIndex by invoking the closure passed into
// Home's `changeCurrentIndex` constructor argument. This exercises every
// PagesCode branch (lines 91-136 of lib/menu.dart) plus the FAB SOS tap
// (lines 310-314) and the main-menu dialog open path.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/pages/FeelGood/feelGood.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/PersonalPlan/myPlanPageFull.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_page.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_exporter.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_repository.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_store.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_view_model.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_view_state.dart';
import 'package:mazilon/pages/about.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/pages/journal.dart';
import 'package:mazilon/pages/notifications/notification_page.dart';
import 'package:mazilon/pages/positive.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'MenuTest/TestMenu.dart';
import 'MenuTest/test_data.dart';
import '../test_support/contract_persistent_memory_service.dart';
import 'helpers/widget_test_scaffold.dart';

final class _FakePersistentMemoryService
    extends ContractPersistentMemoryService {
  _FakePersistentMemoryService({Map<String, dynamic>? init})
    : super(initialValues: init) {
    onMissingRead = (String _, PersistentMemoryType type) {
      switch (type) {
        case PersistentMemoryType.String:
          return '';
        case PersistentMemoryType.Bool:
          return false;
        case PersistentMemoryType.Int:
          return 0;
        case PersistentMemoryType.Double:
          return 0.0;
        case PersistentMemoryType.StringList:
          return <String>[];
      }
    };
  }
}

String _completedMoodMedicineSnapshot() {
  final DateTime now = DateTime.now();
  return MoodMedicineSnapshot(
    entries: <MoodMedicineEntry>[
      MoodMedicineEntry(
        id: 'existing-mood-entry',
        occurredAtUtc: now.toUtc(),
        localDayKey: moodMedicineLocalDayKey(now),
        mood: 3,
      ),
    ],
  ).encode();
}

class _FakeAnalytics implements AnalyticsService {
  final List<String> events = [];
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(String name, [Map<String, dynamic>? props]) async =>
      events.add(name);
}

class _FakeFiles implements FileService {
  @override
  Future<ShareResult?> share(
    message,
    titles,
    subTitles,
    texts,
    fmt, {
    required mainTitle,
    required textDirection,
    memoryService,
    approvedPdfHosts,
  }) async => const ShareResult('fake', ShareResultStatus.success);
  @override
  Future<String?> download(
    titles,
    subTitles,
    texts,
    fmt, {
    required mainTitle,
    required textDirection,
    memoryService,
    approvedPdfHosts,
  }) async => null;
  @override
  Future<bool> shareTextOnly(message) async => true;
}

// We'll register the test scaffold's NoopImagePickerService below in setUp.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAnalytics analytics;
  late UserInformation user;
  late AppInformation app;

  setUp(() async {
    await GetIt.instance.reset();
    analytics = _FakeAnalytics();
    getIt.registerLazySingleton<AnalyticsService>(() => analytics);
    getIt.registerLazySingleton<FileService>(() => _FakeFiles());
    getIt.registerLazySingleton<PersistentMemoryService>(
      () => _FakePersistentMemoryService(
        init: {
          'hasFilled': false,
          'location': '',
          'phonePageDataSavedPhoneNames': <String>[],
          'phonePageDataSavedPhoneNumbers': <String>[],
          MoodMedicineStore.snapshotKey: _completedMoodMedicineSnapshot(),
        },
      ),
    );
    getIt.registerLazySingleton<ImagePickerService>(
      () => NoopImagePickerService(),
    );
    getIt.registerLazySingleton<MoodMedicineStore>(
      () => MoodMedicineStore(getIt<PersistentMemoryService>()),
    );
    getIt.registerLazySingleton<MoodMedicineRepository>(
      () => getIt<MoodMedicineStore>(),
    );
    getIt.registerLazySingleton<MoodMedicineReportExportService>(
      () => MoodMedicineReportExporter(),
    );
    getIt.registerFactory<MoodMedicineViewModel>(
      () => MoodMedicineViewModel(
        getIt<MoodMedicineRepository>(),
        getIt<MoodMedicineReportExportService>(),
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
      ..localeName = 'he';
    app = AppInformation();
    getData(app);
  });

  Future<void> drive(
    WidgetTester tester,
    PagesCode code, {
    MoodMedicineViewModel Function()? moodMedicineViewModelFactory,
  }) async {
    await tester.pumpWidget(
      getMenuForTests(
        user,
        app,
        moodMedicineViewModelFactory: moodMedicineViewModelFactory,
      ),
    );
    await tester.pumpAndSettle();
    final homeWidget = tester.widget<Home>(find.byType(Home));
    final homeContext = tester.element(find.byType(Home));
    homeWidget.changeCurrentIndex(homeContext, code);
    await tester.pump();
  }

  testWidgets('changeCurrentIndex FullPlan branch swaps to MyPlanPageFull', (
    tester,
  ) async {
    await drive(tester, PagesCode.FullPlan);
    expect(find.byType(MyPlanPageFull), findsOneWidget);
  });

  testWidgets('changeCurrentIndex QualitiesList branch swaps to Positive', (
    tester,
  ) async {
    await drive(tester, PagesCode.QualitiesList);
    expect(find.byType(Positive), findsOneWidget);
  });

  testWidgets('changeCurrentIndex GratitudeJournal branch swaps to Journal', (
    tester,
  ) async {
    await drive(tester, PagesCode.GratitudeJournal);
    expect(find.byType(Journal), findsOneWidget);
  });

  testWidgets('changeCurrentIndex About branch swaps to About', (tester) async {
    await drive(tester, PagesCode.About);
    expect(find.byType(About), findsOneWidget);
  });

  testWidgets('changeCurrentIndex FeelGoodPage branch swaps to FeelGood', (
    tester,
  ) async {
    await drive(tester, PagesCode.FeelGoodPage);
    expect(find.byType(FeelGood), findsOneWidget);
  });

  testWidgets(
    'changeCurrentIndex NotificationPage branch swaps to NotificationPage '
    '(supportsReminderSettings is true on the default test platform)',
    (tester) async {
      await drive(tester, PagesCode.NotificationPage);
      expect(find.byType(NotificationPage), findsOneWidget);
    },
  );

  group('MoodMedicine menu branch', () {
    testWidgets(
      'should compose a fresh insights page and retain analytics tracking',
      (WidgetTester tester) async {
        await drive(tester, PagesCode.MoodMedicinePage);
        await tester.pumpAndSettle();

        expect(find.byType(MoodMedicinePage), findsOneWidget);
        expect(analytics.events, contains('Viewed Mood Medicine Insights'));
      },
    );

    testWidgets(
      'should use the injected factory for direct insights navigation',
      (WidgetTester tester) async {
        final List<MoodMedicineViewModel> created = <MoodMedicineViewModel>[];
        MoodMedicineViewModel createViewModel() {
          final MoodMedicineViewModel viewModel = MoodMedicineViewModel(
            getIt<MoodMedicineRepository>(),
            getIt<MoodMedicineReportExportService>(),
          );
          created.add(viewModel);
          return viewModel;
        }

        await drive(
          tester,
          PagesCode.MoodMedicinePage,
          moodMedicineViewModelFactory: createViewModel,
        );
        await tester.pumpAndSettle();

        final MoodMedicinePage page = tester.widget<MoodMedicinePage>(
          find.byType(MoodMedicinePage),
        );
        expect(created, hasLength(2));
        expect(page.viewModel, same(created.last));
      },
    );

    testWidgets(
      'should open insights from the Home entry point and track the view',
      (WidgetTester tester) async {
        await tester.pumpWidget(getMenuForTests(user, app));
        await tester.pumpAndSettle();

        final Finder insights = find.byKey(
          const Key('moodMedicineHomeInsights'),
        );
        await tester.ensureVisible(insights);
        await tester.tap(insights);
        await tester.pumpAndSettle();

        final MoodMedicinePage page = tester.widget<MoodMedicinePage>(
          find.byType(MoodMedicinePage),
        );
        expect(page.initialView, MoodMedicineInitialView.insights);
        expect(analytics.events, contains('Viewed Mood Medicine Insights'));
      },
    );

    testWidgets('should open check-in from the main-menu quick action', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(getMenuForTests(user, app));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('mainMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moodMedicineQuickCheckIn')));
      await tester.pumpAndSettle();

      final MoodMedicinePage page = tester.widget<MoodMedicinePage>(
        find.byType(MoodMedicinePage),
      );
      expect(page.initialView, MoodMedicineInitialView.checkIn);
    });

    testWidgets('should use the injected factory for quick check-in', (
      WidgetTester tester,
    ) async {
      final List<MoodMedicineViewModel> created = <MoodMedicineViewModel>[];
      MoodMedicineViewModel createViewModel() {
        final MoodMedicineViewModel viewModel = MoodMedicineViewModel(
          getIt<MoodMedicineRepository>(),
          getIt<MoodMedicineReportExportService>(),
        );
        created.add(viewModel);
        return viewModel;
      }

      await tester.pumpWidget(
        getMenuForTests(
          user,
          app,
          moodMedicineViewModelFactory: createViewModel,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mainMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moodMedicineQuickCheckIn')));
      await tester.pumpAndSettle();

      final MoodMedicinePage page = tester.widget<MoodMedicinePage>(
        find.byType(MoodMedicinePage),
      );
      expect(created, hasLength(2));
      expect(page.viewModel, same(created.last));
      expect(page.initialView, MoodMedicineInitialView.checkIn);
    });
  });
}
