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
import 'package:mazilon/util/personal_plan_export_snapshot.dart';

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

const _snapshotKeyTypes = <String, PersistentMemoryType>{
  'userSelectionPersonalPlan-DifficultEvents': PersistentMemoryType.StringList,
  'userSelectionPersonalPlan-MakeSafer': PersistentMemoryType.StringList,
  'userSelectionPersonalPlan-FeelBetter': PersistentMemoryType.StringList,
  'userSelectionPersonalPlan-Distractions': PersistentMemoryType.StringList,
  'userSelectionPersonalPlan-SafeEnvironment': PersistentMemoryType.StringList,
  'userSelectionPersonalPlan-DreamsAndGoals': PersistentMemoryType.StringList,
  'PhonePageSavedPhoneNames': PersistentMemoryType.StringList,
  'PhonePageSavedPhoneNumbers': PersistentMemoryType.StringList,
  'customCategories': PersistentMemoryType.String,
  'customCategoryTitles': PersistentMemoryType.StringList,
  'customCategoryDescriptions': PersistentMemoryType.StringList,
};

const _snapshotValues = <String, Object?>{
  'userSelectionPersonalPlan-DifficultEvents': ['Recognize warning signs'],
  'userSelectionPersonalPlan-MakeSafer': ['Ask for support'],
  'userSelectionPersonalPlan-FeelBetter': ['Listen to music'],
  'userSelectionPersonalPlan-Distractions': ['Take a walk', 'Read a book'],
  'userSelectionPersonalPlan-SafeEnvironment': ['Visit a friend'],
  'userSelectionPersonalPlan-DreamsAndGoals': ['Learn to paint'],
  'PhonePageSavedPhoneNames': ['Support person'],
  'PhonePageSavedPhoneNumbers': ['+972501234567'],
  'customCategories':
      '[{"title":"My resources","description":"A trusted place"}]',
  'customCategoryTitles': ['Outdated title'],
  'customCategoryDescriptions': ['Outdated description'],
};

const _expectedSnapshotData = <String, List<String>>{
  'DifficultEvents': ['Recognize warning signs'],
  'MakeSafer': ['Ask for support'],
  'FeelBetter': ['Listen to music'],
  'Distractions': ['Take a walk', 'Read a book'],
  'SafeEnvironment': ['Visit a friend'],
  'DreamsAndGoals': ['Learn to paint'],
  'phoneNames': ['Support person'],
  'phoneNumbers': ['+972501234567'],
  'customCategoryTitles': ['My resources'],
  'customCategoryDescriptions': ['A trusted place'],
};

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

  group('PersonalPlanSectionWidget', () {
    late MockSharedPreferences mockSharedPreferences;
    late MockFileService mockFileServiceImpl;
    late UserInformation mockUserInformation;
    late AppInformation mockAppInformation;
    late List<Map<String, PersistentMemoryType>> snapshotRequests;

    late GetIt locator;

    setUp(() async {
      locator = GetIt.instance;
      counterShare = 0;
      counterDownload = 0;
      snapshotRequests = [];

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
      when(mockPersistentMemoryService.readSnapshot(any)).thenAnswer((
        invocation,
      ) async {
        final keys =
            invocation.positionalArguments.single
                as Map<String, PersistentMemoryType>;
        snapshotRequests.add(Map.unmodifiable(keys));
        for (final entry in keys.entries) {
          if (_snapshotKeyTypes[entry.key] != entry.value) {
            throw StateError('Unexpected snapshot key/type: $entry');
          }
        }
        expect(keys, equals(_snapshotKeyTypes));
        return <String, Object?>{
          for (final key in keys.keys) key: _snapshotValues[key],
        };
      });
      getIt.registerLazySingleton<PersistentMemoryService>(
        () => mockPersistentMemoryService,
      );
      when(
        mockPersistentMemoryService.getItem(any, any),
      ).thenAnswer((_) async => null);
      when(
        mockPersistentMemoryService.setItem(any, any, any),
      ).thenAnswer((_) async {});
      when(
        mockPersistentMemoryService.getItem(any, PersistentMemoryType.Bool),
      ).thenAnswer((_) async => true);
      getIt.registerLazySingleton<ImagePickerService>(() => imageFactory);
      when(
        mockFileServiceImpl.share(
          any,
          any,
          any,
          any,
          any,
          mainTitle: anyNamed('mainTitle'),
          textDirection: anyNamed('textDirection'),
          memoryService: anyNamed('memoryService'),
          snapshot: anyNamed('snapshot'),
          approvedPdfHosts: anyNamed('approvedPdfHosts'),
        ),
      ).thenAnswer(((Invocation invocation) async {
        counterShare = counterShare + 1;
        return const ShareResult('test-success', ShareResultStatus.success);
      }));
      when(
        mockFileServiceImpl.download(
          any,
          any,
          any,
          any,
          mainTitle: anyNamed('mainTitle'),
          textDirection: anyNamed('textDirection'),
          memoryService: anyNamed('memoryService'),
          snapshot: anyNamed('snapshot'),
          approvedPdfHosts: anyNamed('approvedPdfHosts'),
        ),
      ).thenAnswer(((Invocation invocation) async {
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
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
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

    testWidgets('should display the personal plan menu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(getPersonalPlanWidgetForTests());
      expect(find.byType(PersonalPlanSectionWidget), findsOneWidget);
      expect(find.byKey(const Key('personalPlanHeaderMenu')), findsOneWidget);
    });
    testWidgets('should download the complete stored plan snapshot', (
      WidgetTester tester,
    ) async {
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
      expect(counterShare, 0);
      expect(snapshotRequests, equals([_snapshotKeyTypes]));
      final snapshot =
          verify(
                mockFileServiceImpl.download(
                  any,
                  any,
                  any,
                  any,
                  mainTitle: anyNamed('mainTitle'),
                  textDirection: anyNamed('textDirection'),
                  memoryService: anyNamed('memoryService'),
                  snapshot: captureAnyNamed('snapshot'),
                  approvedPdfHosts: anyNamed('approvedPdfHosts'),
                ),
              ).captured.single
              as PersonalPlanExportSnapshot;
      expect(snapshot.data, equals(_expectedSnapshotData));
      expect(tester.takeException(), isNull);
    });

    testWidgets('should share the complete stored plan snapshot', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(getPersonalPlanWidgetForTests());
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
      expect(counterDownload, 0);
      expect(snapshotRequests, equals([_snapshotKeyTypes]));
      final snapshot =
          verify(
                mockFileServiceImpl.share(
                  any,
                  any,
                  any,
                  any,
                  any,
                  mainTitle: anyNamed('mainTitle'),
                  textDirection: anyNamed('textDirection'),
                  memoryService: anyNamed('memoryService'),
                  snapshot: captureAnyNamed('snapshot'),
                  approvedPdfHosts: anyNamed('approvedPdfHosts'),
                ),
              ).captured.single
              as PersonalPlanExportSnapshot;
      expect(snapshot.data, equals(_expectedSnapshotData));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should show Personal Plan feedback when file sharing is unavailable',
      (WidgetTester tester) async {
        when(
          mockFileServiceImpl.share(
            any,
            any,
            any,
            any,
            any,
            mainTitle: anyNamed('mainTitle'),
            textDirection: anyNamed('textDirection'),
            memoryService: anyNamed('memoryService'),
            snapshot: anyNamed('snapshot'),
            approvedPdfHosts: anyNamed('approvedPdfHosts'),
          ),
        ).thenAnswer((_) async => ShareResult.unavailable);
        await tester.pumpWidget(getPersonalPlanWidgetForTests());

        await tapAndSettle(
          tester,
          find.byKey(const Key('personalPlanHeaderMenu')),
        );
        await tapAndSettle(
          tester,
          find.byKey(const Key('personalPlanHeaderShare')),
        );
        await tapAndSettle(tester, find.text('שיתוף קובץ של התוכנית האישית'));

        expect(
          find.text('לא ניתן היה לשתף את התוכנית האישית שלך. נסו שוב.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('should download with localized plan headers and subtitles', (
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
        mockFileServiceImpl.download(
          captureAny,
          captureAny,
          any,
          any,
          mainTitle: anyNamed('mainTitle'),
          textDirection: anyNamed('textDirection'),
          memoryService: anyNamed('memoryService'),
          snapshot: anyNamed('snapshot'),
          approvedPdfHosts: anyNamed('approvedPdfHosts'),
        ),
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
