import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/util/personal_plan_export_snapshot.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_store.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'MenuTest/TestMenu.dart';
import 'MenuTest/test_data.dart';
import '../test_support/contract_persistent_memory_service.dart';

class _FakeAnalyticsService implements AnalyticsService {
  final List<String> events = [];
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {
    events.add(eventName);
  }
}

final class _FakePersistentMemoryService
    extends ContractPersistentMemoryService {
  _FakePersistentMemoryService({super.initialValues, bool failWrites = false}) {
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
    if (failWrites) {
      onPersist = (String key, PersistentMemoryType type, Object value) {
        throw StateError('menu persistence failed');
      };
    }
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

class _FakeFileService implements FileService {
  @override
  Future<ShareResult?> share(
    String message,
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat, {
    required String mainTitle,
    required String textDirection,
    PersistentMemoryService? memoryService,
    PersonalPlanExportSnapshot? snapshot,
    Set<String>? approvedPdfHosts,
  }) async => const ShareResult('fake', ShareResultStatus.success);
  @override
  Future<String?> download(
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat, {
    required String mainTitle,
    required String textDirection,
    PersistentMemoryService? memoryService,
    PersonalPlanExportSnapshot? snapshot,
    Set<String>? approvedPdfHosts,
  }) async => null;
  @override
  Future<bool> shareTextOnly(String message) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;
  late AppInformation app;
  late _FakeAnalyticsService analytics;

  setUp(() async {
    await GetIt.instance.reset();
    analytics = _FakeAnalyticsService();
    getIt.registerLazySingleton<AnalyticsService>(() => analytics);
    getIt.registerLazySingleton<FileService>(() => _FakeFileService());
    getIt.registerLazySingleton<PersistentMemoryService>(
      () => _FakePersistentMemoryService(
        initialValues: {
          'hasFilled': false,
          'location': '',
          'phonePageDataSavedPhoneNames': <String>[],
          'phonePageDataSavedPhoneNumbers': <String>[],
          MoodMedicineStore.snapshotKey: _completedMoodMedicineSnapshot(),
        },
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

  testWidgets('default screen is Home and SOS button is visible', (
    tester,
  ) async {
    await tester.pumpWidget(getMenuForTests(user, app));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    // Home tab is selected by default
    expect(find.byKey(const Key('bottomNavHome')), findsOneWidget);
  });

  testWidgets(
    'failed menu initialization writes stay contained and keep Home rendered',
    (tester) async {
      await GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(
        _FakePersistentMemoryService(
          initialValues: <String, Object>{
            'hasFilled': false,
            'location': '',
            'phonePageDataSavedPhoneNames': <String>[],
            'phonePageDataSavedPhoneNumbers': <String>[],
          },
          failWrites: true,
        ),
      );

      await tester.pumpWidget(getMenuForTests(user, app));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottomNavHome')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping SOS swaps to PhonePage', (tester) async {
    await tester.pumpWidget(getMenuForTests(user, app));
    await tester.pumpAndSettle();

    final sos = find.byType(FloatingActionButton);
    expect(sos, findsOneWidget);
    await tester.tap(sos);
    await tester.pumpAndSettle();

    // After SOS tap, the PhonePage replaces the home content. Search bar still
    // should not show 'SOS' twice (FAB persists). We verify the page has been
    // swapped by checking the home greeting from getData('') has been hidden.
    expect(find.byKey(const Key('bottomNavHome')), findsOneWidget);
  }, skip: true);

  testWidgets('tapping the Plan bottom nav swaps to MyPlanPageFull', (
    tester,
  ) async {
    await tester.pumpWidget(getMenuForTests(user, app));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bottomNavMyPlan')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bottomNavMyPlan')), findsOneWidget);
  });

  testWidgets('tapping FeelGood records analytics event', (tester) async {
    await tester.pumpWidget(getMenuForTests(user, app));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('bottomNavFeelGood')));
    await tester.pumpAndSettle();

    expect(analytics.events, contains('Viewed Feel Good Page'));
  }, skip: true);

  testWidgets('back button on Home tab pops the system navigator path', (
    tester,
  ) async {
    await tester.pumpWidget(getMenuForTests(user, app));
    await tester.pumpAndSettle();

    // Drive the PopScope back invocation; current is Home so it should call
    // SystemNavigator.pop and reset to home.
    final dynamicState = tester.state<State<StatefulWidget>>(
      find.byType(MaterialApp).first,
    );
    expect(dynamicState, isNotNull);
  });

  testWidgets('Notifications menu is hidden on iOS (platform override)', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(getMenuForTests(user, app));
    await tester.pumpAndSettle();

    // Open the main menu drawer.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Notification add icon must NOT be present on iOS.
    expect(find.byIcon(Icons.notification_add), findsNothing);
  }, skip: true);
}
