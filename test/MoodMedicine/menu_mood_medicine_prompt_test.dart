import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_page.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_exporter.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_repository.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_store.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_view_model.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_view_state.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../MenuTest/TestMenu.dart';
import '../MenuTest/test_data.dart';
import '../../test_support/contract_persistent_memory_service.dart';

final class _PromptAnalyticsService implements AnalyticsService {
  @override
  Future<void> init() async {}

  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {}
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
    getIt.registerLazySingleton<MoodMedicineStore>(
      () => MoodMedicineStore(memory),
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
      ..localeName = 'en';
    app = AppInformation();
    getData(app);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<void> pumpMenu(WidgetTester tester, {String? snapshot}) async {
    if (snapshot != null) {
      memory.store[MoodMedicineStore.snapshotKey] = snapshot;
    } else {
      memory.store.remove(MoodMedicineStore.snapshotKey);
    }
    await tester.pumpWidget(
      getMenuForTests(user, app, locale: const Locale('en')),
    );
  }

  group('MoodMedicineMenu', () {
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
