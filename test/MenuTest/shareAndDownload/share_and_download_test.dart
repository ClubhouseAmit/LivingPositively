import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/MainPageHelpers/components/personal_plan_section.dart';
import 'package:mazilon/global_enums.dart';

import 'package:mazilon/iFx/service_locator.dart';

import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';

import 'package:mazilon/file_service.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

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

  group('PersonalPlanSectionWidget download and share Tests', () {
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
      when(mockFileServiceImpl.share(any, any, any, any, any,
              mainTitle: anyNamed('mainTitle'), textDirection: anyNamed('textDirection'))).thenAnswer(
        ((Invocation invocation) async {
          counterShare = counterShare + 1;
          return const ShareResult('test-success', ShareResultStatus.success);
        }),
      );
      when(mockFileServiceImpl.download(any, any, any, any,
              mainTitle: anyNamed('mainTitle'), textDirection: anyNamed('textDirection'))).thenAnswer(((
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

    Widget getPersonalPlanWidgetForTests({Locale locale = const Locale('he')}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserInformation>.value(
            value: mockUserInformation,
          ),
          ChangeNotifierProvider<AppInformation>.value(
            value: mockAppInformation,
          ),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ScreenUtilInit(
            designSize: const Size(360, 690),
            child: Scaffold(
              body: PersonalPlanSectionWidget(
                items: const ['Item 1', 'Item 2'],
                onSeeAll: () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Display exists', (WidgetTester tester) async {
      await tester.pumpWidget(getPersonalPlanWidgetForTests());
      expect(find.byType(PersonalPlanSectionWidget), findsOneWidget);
      expect(find.byKey(const Key('personalPlanHeaderMenu')), findsOneWidget);
    });
    testWidgets('Buttons Clickable', (WidgetTester tester) async {
      await tester.pumpWidget(getPersonalPlanWidgetForTests());
      expect(find.byType(PersonalPlanSectionWidget), findsOneWidget);

      expect(counterDownload, 0);
      expect(counterShare, 0);

      // Open the popover menu
      await tapAndSettle(
        tester,
        find.byKey(const Key('personalPlanHeaderMenu')),
      );

      // Tap download option
      await tapAndSettle(
        tester,
        find.byKey(const Key('personalPlanHeaderDownload')),
      );
      expect(counterDownload, 1);

      // Open the popover menu again for share
      await tapAndSettle(
        tester,
        find.byKey(const Key('personalPlanHeaderMenu')),
      );

      // Tap share option
      await tapAndSettle(
        tester,
        find.byKey(const Key('personalPlanHeaderShare')),
      );
      expect(find.byType(LPShareAlertDialog), findsWidgets);
      expect(find.byIcon(Icons.insert_drive_file_outlined), findsWidgets);
      await tapAndSettle(tester, find.text("שיתוף קובץ של התוכנית האישית"));
      expect(counterShare, 1);
    });

    testWidgets('shows Personal Plan feedback when file sharing is unavailable',
        (WidgetTester tester) async {
      when(mockFileServiceImpl.share(any, any, any, any, any,
              mainTitle: anyNamed('mainTitle'), textDirection: anyNamed('textDirection')))
          .thenAnswer((_) async => ShareResult.unavailable);
      await tester.pumpWidget(getPersonalPlanWidgetForTests());

      await tapAndSettle(tester, find.byKey(const Key('personalPlanHeaderMenu')));
      await tapAndSettle(tester, find.byKey(const Key('personalPlanHeaderShare')));
      await tapAndSettle(tester, find.text('שיתוף קובץ של התוכנית האישית'));

      expect(
        find.text('לא ניתן היה לשתף את התוכנית האישית שלך. נסו שוב.'),
        findsOneWidget,
      );
    });

    testWidgets('download uses the localized plan headers and subtitles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(getPersonalPlanWidgetForTests());

      // Open the popover menu
      await tapAndSettle(
        tester,
        find.byKey(const Key('personalPlanHeaderMenu')),
      );

      await tapAndSettle(
        tester,
        find.byKey(const Key('personalPlanHeaderDownload')),
      );

      final localizations = AppLocalizations.of(
        tester.element(find.byType(PersonalPlanSectionWidget)),
      )!;
      final captured = verify(
        mockFileServiceImpl.download(captureAny, captureAny, any, any,
            mainTitle: anyNamed('mainTitle'), textDirection: anyNamed('textDirection')),
      ).captured;

      expect(captured, hasLength(2));
      expect(captured[0], <String>[
        localizations.distractionsHeader('male'),
        localizations.difficultEventsHeader('male'),
        localizations.feelBetterHeader('male'),
        localizations.makeSaferHeader('male'),
        localizations.phonesPageHeader('male'),
        localizations.safeEnvironmentHeader('male'),
        localizations.dreamsAndGoalsHeader('male'),
      ]);
      expect(captured[1], <String>[
        localizations.distractionsSubTitle('male'),
        localizations.difficultEventsSubTitle('male'),
        localizations.feelBetterSubTitle('male'),
        localizations.makeSaferSubTitle('male'),
        localizations.phonesPageSubTitle('male'),
        localizations.safeEnvironmentSubTitle('male'),
        localizations.dreamsAndGoalsSubTitle('male'),
      ]);
    });
  });
}
