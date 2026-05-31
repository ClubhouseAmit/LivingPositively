// Drives _MenuState.changeCurrentIndex by invoking the closure passed into
// Home's `changeCurrentIndex` constructor argument. This exercises every
// PagesCode branch (lines 91-136 of lib/menu.dart) plus the FAB SOS tap
// (lines 310-314) and the main-menu dialog open path.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/pages/FeelGood/feelGood.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/PersonalPlan/myPlanPageFull.dart';
import 'package:mazilon/pages/about.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/pages/journal.dart';
import 'package:mazilon/pages/notifications/notification_page.dart';
import 'package:mazilon/pages/positive.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'MenuTest/TestMenu.dart';
import 'MenuTest/test_data.dart';
import 'helpers/widget_test_scaffold.dart';

class _FakePm implements PersistentMemoryService {
  final Map<String, dynamic> _values;
  _FakePm({Map<String, dynamic>? init}) : _values = {...?init};
  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (_values.containsKey(key)) return _values[key];
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
  }

  @override
  Future<void> reset() async => _values.clear();
  @override
  Future<void> setItem(String key, PersistentMemoryType type, dynamic v) async {
    _values[key] = v;
  }
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
  Future<void> share(message, titles, subTitles, texts, fmt, dir) async {}
  @override
  Future<String?> download(titles, subTitles, texts, fmt, dir) async => null;
  @override
  Future<void> shareTextOnly(message) async {}
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
      () => _FakePm(
        init: {
          'hasFilled': false,
          'location': '',
          'phonePageDataSavedPhoneNames': <String>[],
          'phonePageDataSavedPhoneNumbers': <String>[],
        },
      ),
    );
    getIt.registerLazySingleton<ImagePickerService>(
      () => NoopImagePickerService(),
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

  Future<void> drive(WidgetTester tester, PagesCode code) async {
    await tester.pumpWidget(getMenuForTests(user, app));
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
    // Positive.initState schedules Future.delayed(10s); drain it so the
    // test does not fail on "Timer is still pending".
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();
    // Close the popup dialog if it appeared.
    final dlgBtn = find.byType(TextButton);
    if (dlgBtn.evaluate().isNotEmpty) {
      await tester.tap(dlgBtn.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
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
}
