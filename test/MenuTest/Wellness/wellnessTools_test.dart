import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/file_service.dart';

import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/WellnessTools/more_videos_item.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/pages/WellnessTools/wellnessTools.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/styles.dart';

import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mockito/annotations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

import '../TestMenu.dart';
import '../test_data.dart';
import 'FakeVideoPlayerPage.dart';
import 'wellnessTools_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FileService>(),
  MockSpec<VideoPlayerPageFactory>(),
  MockSpec<ImagePickerService>(),
  MockSpec<SharedPreferences>(),
  MockSpec<UserInformation>(),
  MockSpec<AppInformation>(),
  MockSpec<AnalyticsService>(),
  MockSpec<PersistentMemoryService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WellnessTools Widget Tests', () {
    late MockSharedPreferences mockSharedPreferences;
    late UserInformation mockUserInformation;
    late AppInformation mockAppInformation;
    late GetIt locator;

    setUp(() async {
      locator = GetIt.instance;

      // Reset getIt before each test
      await locator.reset();
      final mockAnalytics = MockAnalyticsService();
      getIt.registerLazySingleton<AnalyticsService>(() => mockAnalytics);
      final mockFileServiceImpl = MockFileService();
      getIt.registerLazySingleton<FileService>(() => mockFileServiceImpl);
      final mockFactory = MockVideoPlayerPageFactory();
      final mockPersistentMemoryService = MockPersistentMemoryService();
      getIt.registerLazySingleton<PersistentMemoryService>(
          () => mockPersistentMemoryService);
      when(mockPersistentMemoryService.getItem(any, PersistentMemoryType.Bool))
          .thenAnswer((_) async => true);
      when(mockFactory.create(
        onFullScreenChanged: anyNamed('onFullScreenChanged'),
        videoData: anyNamed('videoData'),
      )).thenAnswer((Invocation invocation) {
        final onFullScreenChanged =
            invocation.namedArguments[const Symbol('onFullScreenChanged')]
                as Function(bool);
        final videoData = invocation.namedArguments[const Symbol('videoData')]
            as Map<String, List<String>>;
        return FakeVideoPlayerPage(
          onFullScreenChanged: onFullScreenChanged,
          videoData: videoData,
        );
      });

      getIt.registerSingleton<VideoPlayerPageFactory>(mockFactory);
      final imageFactory = MockImagePickerService();
      when(imageFactory.getOnlineImage(any))
          .thenAnswer((Invocation invocation) {
        return Container(key: const Key("Image"), child: const Text("Image"));
      });

      getIt.registerLazySingleton<ImagePickerService>(() => imageFactory);
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

    testWidgets('Navigate to WellnessTools screen',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(getMenuForTests(mockUserInformation, mockAppInformation));
      await tapAndSettle(tester, find.text('כלי תמיכה'));
      expect(find.byType(WellnessTools), findsOneWidget);
    });
    testWidgets('Header menu opens from hamburger icon',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(getMenuForTests(mockUserInformation, mockAppInformation));
      final menuButton = find.byIcon(Icons.menu);
      final menuIcon = tester.widget<Icon>(menuButton);
      final menuButtonBottom = tester.getBottomLeft(menuButton).dy;

      expect(menuIcon.color, primaryPurple);

      await tapAndSettle(tester, menuButton);

      final menuDialog = find.byKey(const Key('mainMenuDialog'));
      final closeButton = find.byKey(const Key('mainMenuCloseButton'));
      final menuDialogTop = tester.getTopLeft(menuDialog).dy;
      final menuDialogLeft = tester.getTopLeft(menuDialog).dx;
      final menuDialogWidth = tester.getSize(menuDialog).width;
      final closeButtonLeft = tester.getTopLeft(closeButton).dx;
      final closeButtonCenterY = tester.getCenter(closeButton).dy;
      final aboutIconCenterY = tester.getCenter(find.byIcon(Icons.people)).dy;

      expect(find.byKey(const Key('mainMenuDialog')), findsOneWidget);
      expect(menuDialogTop, greaterThanOrEqualTo(menuButtonBottom));
      expect(menuDialogTop - menuButtonBottom, lessThan(20));
      expect(menuDialogWidth, lessThanOrEqualTo(260));
      expect(closeButtonLeft, lessThan(menuDialogLeft + menuDialogWidth / 2));
      expect((closeButtonCenterY - aboutIconCenterY).abs(), lessThan(8));
    });
    testWidgets('Header menu puts close button on the right in English',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(getMenuForTests(
          mockUserInformation, mockAppInformation,
          locale: const Locale('en')));
      final menuButton = find.byIcon(Icons.menu);
      final menuButtonBottom = tester.getBottomLeft(menuButton).dy;

      await tapAndSettle(tester, menuButton);

      final menuDialog = find.byKey(const Key('mainMenuDialog'));
      final closeButton = find.byKey(const Key('mainMenuCloseButton'));
      final menuDialogTop = tester.getTopLeft(menuDialog).dy;
      final menuDialogLeft = tester.getTopLeft(menuDialog).dx;
      final menuDialogWidth = tester.getSize(menuDialog).width;
      final closeButtonLeft = tester.getTopLeft(closeButton).dx;

      expect(menuDialogTop, greaterThanOrEqualTo(menuButtonBottom));
      expect(menuDialogTop - menuButtonBottom, lessThan(20));
      expect(
          closeButtonLeft, greaterThan(menuDialogLeft + menuDialogWidth / 2));
    });
    testWidgets('Navigate from WellnessTools screen',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(getMenuForTests(mockUserInformation, mockAppInformation));

      await tapAndSettle(tester, find.text('כלי תמיכה'));
      await tapAndSettle(tester, find.text('בית'));
      expect(find.byType(Home), findsOneWidget);
    });
    testWidgets('Test Repeated Navigation to and from WellnessTools screen',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(getMenuForTests(mockUserInformation, mockAppInformation));

      await tapAndSettle(tester, find.text('כלי תמיכה'));
      expect(find.byType(WellnessTools), findsOneWidget);
      await tapAndSettle(tester, find.text('בית'));
      expect(find.byType(WellnessTools), findsNothing);
      expect(find.byType(Home), findsOneWidget);
      await tapAndSettle(tester, find.text('כלי תמיכה'));
      expect(find.byType(Home), findsNothing);
      expect(find.byType(WellnessTools), findsOneWidget);
      await tapAndSettle(tester, find.text('בית'));
      expect(find.byType(Home), findsOneWidget);
      expect(find.byType(WellnessTools), findsNothing);
    });
    testWidgets('Test Structure of WellnessTools screen',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(getMenuForTests(mockUserInformation, mockAppInformation));

      await tapAndSettle(tester, find.text('כלי תמיכה'));
      expect(find.byType(FakeVideoPlayerPage), findsOneWidget);
      expect(find.byType(MoreVideosItem), findsWidgets);
      expect(find.byKey(const Key("Image")), findsOneWidget);
    });
    testWidgets('Test Texts inside WellnessTools screen',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(getMenuForTests(mockUserInformation, mockAppInformation));

      await tapAndSettle(tester, find.text('כלי תמיכה'));
      expect(find.text("Image"), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);
      expect(find.text('v2'), findsOneWidget);
      expect(find.text('v1d'), findsOneWidget);
      expect(find.text('v2d'), findsNothing);
    });
    testWidgets('Test change video', (WidgetTester tester) async {
      await tester
          .pumpWidget(getMenuForTests(mockUserInformation, mockAppInformation));

      await tapAndSettle(tester, find.text('כלי תמיכה'));
      await tapAndSettle(tester, find.text('v2'));
      expect(find.text("Image"), findsOneWidget);
      expect(find.text('v1'), findsOneWidget);
      expect(find.text('v2'), findsOneWidget);
      expect(find.text('v1d'), findsNothing);
      expect(find.text('v2d'), findsOneWidget);
    });
  });
}
