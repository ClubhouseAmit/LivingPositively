import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/pages/FeelGood/add_Image_item.dart';
import 'package:mazilon/pages/FeelGood/feelGood.dart';
import 'package:mazilon/pages/FeelGood/image_display_item.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../TestMenu.dart';
import '../test_data.dart';
import 'feelGood_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<VideoPlayerPageFactory>(),
  MockSpec<FileService>(),
  MockSpec<ImagePickerService>(),
  MockSpec<SharedPreferences>(),
  MockSpec<UserInformation>(),
  MockSpec<AppInformation>(),
  MockSpec<AnalyticsService>(),
  MockSpec<PersistentMemoryService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeelGood Widget Tests', () {
    late MockSharedPreferences mockSharedPreferences;
    late UserInformation mockUserInformation;
    late AppInformation mockAppInformation;

    late GetIt locator;

    setUp(() async {
      locator = GetIt.instance;

      // Reset getIt before each test
      await locator.reset();
      final mockFileServiceImpl = MockFileService();
      final mockAnalytics = MockAnalyticsService();
      getIt.registerLazySingleton<AnalyticsService>(() => mockAnalytics);
      getIt.registerLazySingleton<FileService>(() => mockFileServiceImpl);

      final mockPersistentMemoryService = MockPersistentMemoryService();

      // Set up mock behaviors for PersistentMemoryService
      when(
        mockPersistentMemoryService.getItem(any, any),
      ).thenAnswer((_) async => null);
      when(
        mockPersistentMemoryService.getItem(any, PersistentMemoryType.Bool),
      ).thenAnswer((_) async => true);
      when(
        mockPersistentMemoryService.setItem(any, any, any),
      ).thenAnswer((_) async {});
      when(mockPersistentMemoryService.reset()).thenAnswer((_) async {});

      // Register PersistentMemoryService with GetIt
      getIt.registerLazySingleton<PersistentMemoryService>(
        () => mockPersistentMemoryService,
      );

      final mockFactory = MockVideoPlayerPageFactory();
      getIt.registerSingleton<VideoPlayerPageFactory>(mockFactory);
      final imageFactory = MockImagePickerService();
      getIt.registerLazySingleton<ImagePickerService>(() => imageFactory);
      when(imageFactory.displayImage(any, fit: anyNamed('fit'))).thenAnswer((
        invocation,
      ) {
        final path = invocation.positionalArguments[0] as String;
        return Container(key: Key(path), child: Text(path));
      });
      when(imageFactory.loadImagePaths(any)).thenAnswer((
        invocation,
      ) async {
        final list = invocation.positionalArguments[0] as List<String>;
        list.addAll([]);
      });
      when(imageFactory.deleteImage(any, any)).thenAnswer((
        invocation,
      ) async {
        final index = invocation.positionalArguments[0] as int;
        final list = invocation.positionalArguments[1] as List<String>;
        list.removeAt(index);
        //list.addAll(['test1', 'test2']);
      });
      when(imageFactory.getImage(any, any)).thenAnswer((
        invocation,
      ) async {
        final list = invocation.positionalArguments[1] as List<String>;

        list.addAll(['added']);
      });

      mockSharedPreferences = MockSharedPreferences();
      mockUserInformation = UserInformation();
      mockAppInformation = AppInformation();
      mockUserInformation.gender = 'male';
      mockUserInformation.localeName = 'he';
      getData(mockAppInformation);
      when(mockSharedPreferences.getBool('enteredBefore')).thenReturn(false);
    });

    Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await tester.tap(finder);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    testWidgets('Navigate to FeelGood screen', (tester) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapAndSettle(tester, find.text('להרגיש טוב'));
      expect(find.byType(FeelGood), findsOneWidget);
      expect(find.byType(ImageAddItem), findsWidgets);
      expect(find.byType(ImageDisplay), findsNothing);
    });
    testWidgets('Navigate back from FeelGood screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapAndSettle(tester, find.text('להרגיש טוב'));
      await tapAndSettle(tester, find.text('בית'));
      expect(find.byType(Home), findsOneWidget);
    });
    testWidgets('Test adding photo from Camera', (tester) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapAndSettle(tester, find.text('להרגיש טוב'));
      expect(find.byKey(const Key('addImgButtonText')), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const Key('addImgButtonText')));
      expect(find.byKey(const Key('cameraButtonText')), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const Key('cameraButtonText')));
      expect(find.text('added'), findsWidgets);
      expect(find.byType(ImageDisplay), findsOneWidget);
      expect(find.byType(ImageAddItem), findsOneWidget);
    });
    testWidgets('Test Adding Photo Gallery', (tester) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapAndSettle(tester, find.text('להרגיש טוב'));
      await tapAndSettle(tester, find.byKey(const Key('addImgButtonText')));
      expect(find.byKey(const Key('galleryButtonText')), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const Key('galleryButtonText')));
      expect(find.text('added'), findsWidgets);
      expect(find.byType(ImageDisplay), findsOneWidget);
      expect(find.byType(ImageAddItem), findsOneWidget);
    });
    testWidgets('Delete photos', (tester) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapAndSettle(tester, find.text('להרגיש טוב'));
      await tapAndSettle(tester, find.byKey(const Key('addImgButtonText')));
      await tapAndSettle(tester, find.byKey(const Key('cameraButtonText')));
      await tapAndSettle(tester, find.text('added'));
      expect(find.byKey(const Key('deleteButtonIcon')), findsOneWidget);
      expect(find.byTooltip('חזרה לתמונות'), findsOneWidget);
      expect(find.byTooltip('מחיקת תמונה'), findsOneWidget);
      final backIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('backButtonIcon')),
          matching: find.byIcon(Icons.arrow_back),
        ),
      );
      final deleteIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('deleteButtonIcon')),
          matching: find.byIcon(Icons.delete),
        ),
      );
      expect(backIcon.semanticLabel, isNull);
      expect(deleteIcon.semanticLabel, isNull);

      await tapAndSettle(tester, find.byKey(const Key('deleteButtonIcon')));
      expect(find.text('למחוק את התמונה?'), findsOneWidget);
      expect(find.text('התמונה תוסר מאזור להרגיש טוב.'), findsOneWidget);
      expect(find.byKey(const Key('deleteButtonText')), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const Key('deleteButtonText')));
      expect(find.text('added'), findsNothing);
      expect(find.byType(ImageDisplay), findsNothing);
      expect(find.byType(ImageAddItem), findsWidgets);
    });
  });
}
