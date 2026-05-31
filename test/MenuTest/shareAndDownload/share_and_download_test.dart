import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluttericon/elusive_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/MainPageHelpers/personalPlanWidget.dart';
import 'package:mazilon/global_enums.dart';

import 'package:mazilon/util/HomePage/sectionBarHome.dart';
import 'package:mazilon/iFx/service_locator.dart';

import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/home.dart';

import 'package:mazilon/file_service.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mockito/annotations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

import '../TestMenu.dart';
import '../test_data.dart';

import 'share_and_download_test.mocks.dart';

void dummyshare() {
  debugPrint('share');
}

@GenerateNiceMocks([
  MockSpec<FileService>(),
  MockSpec<UserInformation>(),
  MockSpec<AppInformation>(),
  MockSpec<SharedPreferences>(),
  MockSpec<VideoPlayerPageFactory>(),
  MockSpec<ImagePickerService>(),
  MockSpec<AnalyticsService>(),
  MockSpec<PersistentMemoryService>(),
])
void main() {
  var counterShare = 0;
  var counterDownload = 0;
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonalPlanWidget download and share Tests', () {
    late MockSharedPreferences mockSharedPreferences;
    late UserInformation mockUserInformation;
    late AppInformation mockAppInformation;

    late GetIt locator;

    setUp(() async {
      locator = GetIt.instance;

      // Reset getIt before each test
      await locator.reset();
      final mockFileServiceImpl = MockFileService();
      getIt.registerLazySingleton<FileService>(() => mockFileServiceImpl);
      final mockAnalytics = MockAnalyticsService();
      getIt.registerLazySingleton<AnalyticsService>(() => mockAnalytics);
      final mockFactory = MockVideoPlayerPageFactory();
      getIt.registerSingleton<VideoPlayerPageFactory>(mockFactory);
      final imageFactory = MockImagePickerService();
      final mockPersistentMemoryService = MockPersistentMemoryService();
      getIt.registerLazySingleton<PersistentMemoryService>(
        () => mockPersistentMemoryService,
      );
      when(
        mockPersistentMemoryService.getItem(any, PersistentMemoryType.Bool),
      ).thenAnswer((_) async => true);
      getIt.registerLazySingleton<ImagePickerService>(() => imageFactory);
      when(mockFileServiceImpl.share(any, any, any, any, any, any)).thenAnswer(
        ((Invocation invocation) async {
          counterShare = counterShare + 1;
        }),
      );
      when(mockFileServiceImpl.download(any, any, any, any, any)).thenAnswer(((
        Invocation invocation,
      ) async {
        counterDownload = counterDownload + 1;
        return null;
      }));
      mockSharedPreferences = MockSharedPreferences();
      mockUserInformation = UserInformation();
      mockAppInformation = AppInformation();
      mockUserInformation.gender = "male";
      mockUserInformation.localeName = "he";
      getData(mockAppInformation);
      when(mockSharedPreferences.getBool('enteredBefore')).thenReturn(false);
    });
    Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await tester.tap(finder);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    testWidgets('Display exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );
      expect(find.byType(Home), findsOneWidget);
      expect(find.byType(PersonalPlanWidget), findsOneWidget);

      expect(find.byType(SectionBarHome), findsWidgets);
      expect(find.byIcon(Elusive.share), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
    testWidgets('Buttons Clickable', (WidgetTester tester) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );
      expect(find.byType(Home), findsOneWidget);
      expect(find.byType(PersonalPlanWidget), findsOneWidget);

      expect(find.byType(SectionBarHome), findsWidgets);
      expect(find.byIcon(Elusive.share), findsOneWidget);
      expect(counterDownload, 0);
      expect(counterShare, 0);
      await tapAndSettle(tester, find.byIcon(Icons.download));

      expect(counterDownload, 1);
      await tapAndSettle(tester, find.byIcon(Elusive.share));
      expect(find.byType(LPShareAlertDialog), findsWidgets);
      expect(find.byIcon(Icons.insert_drive_file_outlined), findsWidgets);
      await tapAndSettle(tester, find.text("שיתוף קובץ של התוכנית האישית"));
      expect(counterShare, 1);
    });
  });
}
