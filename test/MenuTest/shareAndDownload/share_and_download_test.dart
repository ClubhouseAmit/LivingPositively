import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttericon/elusive_icons.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/MainPageHelpers/personalPlanWidget.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/util/HomePage/sectionBarHome.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    late MockFileService mockFileServiceImpl;
    late UserInformation mockUserInformation;
    late AppInformation mockAppInformation;

    late GetIt locator;

    setUp(() async {
      locator = GetIt.instance;

      // Reset getIt before each test
      await locator.reset();
      mockFileServiceImpl = MockFileService();
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
        (invocation) async {
          counterShare = counterShare + 1;
        },
      );
      when(mockFileServiceImpl.download(any, any, any, any, any)).thenAnswer((
        invocation,
      ) async {
        counterDownload = counterDownload + 1;
        return null;
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
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    Future<void> tapPopupMenuItem(WidgetTester tester, Key itemKey) async {
      final actionsButton = find.byKey(const Key('personalPlanHeaderActionsButton'));
      await tapAndSettle(tester, actionsButton);
      await tapAndSettle(tester, find.byKey(itemKey));
    }

    testWidgets('Display exists', (tester) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );
      expect(find.byType(Home), findsOneWidget);
      expect(find.byType(PersonalPlanWidget), findsOneWidget);

      expect(find.byType(SectionBarHome), findsWidgets);
      expect(find.byKey(const Key('personalPlanHeaderActions')), findsOneWidget);
    });
    testWidgets('Buttons Clickable', (tester) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );
      expect(find.byType(Home), findsOneWidget);
      expect(find.byType(PersonalPlanWidget), findsOneWidget);

      expect(find.byType(SectionBarHome), findsWidgets);
      expect(find.byKey(const Key('personalPlanHeaderActions')), findsOneWidget);
      expect(counterDownload, 0);
      expect(counterShare, 0);
      
      await tapPopupMenuItem(tester, const Key('personalPlanHeaderDownload'));
      expect(counterDownload, 1);
      
      await tapPopupMenuItem(tester, const Key('personalPlanHeaderShare'));
      expect(find.byType(LPShareAlertDialog), findsWidgets);
      expect(find.byIcon(Icons.insert_drive_file_outlined), findsWidgets);
      await tapAndSettle(tester, find.text('שיתוף קובץ של התוכנית האישית'));
      expect(counterShare, 1);
    });

    testWidgets('download uses the localized plan headers and subtitles', (
      tester,
    ) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapPopupMenuItem(tester, const Key('personalPlanHeaderDownload'));

      final localizations = AppLocalizations.of(
        tester.element(find.byType(PersonalPlanWidget)),
      )!;
      final captured = verify(
        mockFileServiceImpl.download(captureAny, captureAny, any, any, any),
      ).captured;

      expect(captured, hasLength(2));
      expect(captured[0], <String>[
        localizations.difficultEventsHeader('male'),
        localizations.makeSaferHeader('male'),
        localizations.feelBetterHeader('male'),
        localizations.distractionsHeader('male'),
        localizations.phonesPageHeader('male'),
      ]);
      expect(captured[1], <String>[
        localizations.difficultEventsSubTitle('male'),
        localizations.makeSaferSubTitle('male'),
        localizations.feelBetterSubTitle('male'),
        localizations.distractionsSubTitle('male'),
        localizations.phonesPageSubTitle('male'),
      ]);
    });
  });
}
