import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/main_menu_dialog.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/WellnessTools/more_videos_item.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/pages/WellnessTools/wellnessTools.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mockito/annotations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

import '../TestMenu.dart';
import '../test_data.dart';
import '../../helpers/widget_test_scaffold.dart';
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
        () => mockPersistentMemoryService,
      );
      when(
        mockPersistentMemoryService.getItem(any, PersistentMemoryType.Bool),
      ).thenAnswer((_) async => true);
      when(
        mockFactory.create(
          onFullScreenChanged: anyNamed('onFullScreenChanged'),
          videoData: anyNamed('videoData'),
        ),
      ).thenAnswer((Invocation invocation) {
        final onFullScreenChanged =
            invocation.namedArguments[const Symbol('onFullScreenChanged')]
                as Function(bool);
        final videoData =
            invocation.namedArguments[const Symbol('videoData')]
                as Map<String, List<String>>;
        return FakeVideoPlayerPage(
          onFullScreenChanged: onFullScreenChanged,
          videoData: videoData,
        );
      });

      getIt.registerSingleton<VideoPlayerPageFactory>(mockFactory);
      final imageFactory = MockImagePickerService();
      when(imageFactory.getOnlineImage(any)).thenAnswer((
        Invocation invocation,
      ) {
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

    testWidgets('Navigate to WellnessTools screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );
      await tapAndSettle(tester, find.text('כלי תמיכה'));
      expect(find.byType(WellnessTools), findsOneWidget);
    });
    Future<void> openDialogMenu(
      WidgetTester tester, {
      Locale locale = const Locale('he'),
    }) async {
      final user = UserInformation()
        ..gender = 'other'
        ..localeName = locale.languageCode;
      final phonePageData = PhonePageData(
        key: 'phonePageData',
        header: 'header',
        subTitle: 'subTitle',
        midTitle: 'midTitle',
        phoneNameTitle: 'phoneNameTitle',
        phoneNumberTitle: 'phoneNumberTitle',
        phoneNames: [],
        phoneNumbers: [],
        savedPhoneNames: [],
        savedPhoneNumbers: [],
        phoneDescription: [],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserInformation>.value(value: user),
            ChangeNotifierProvider<AppInformation>.value(
              value: mockAppInformation,
            ),
            ChangeNotifierProvider<PhonePageData>.value(value: phonePageData),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ScreenUtilInit(
              designSize: const Size(360, 690),
              child: Builder(
                builder: (ctx) {
                  return Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        key: const Key('openMenu'),
                        onPressed: () {
                          showMainMenuDialog(
                            context: ctx,
                            anchorContext: ctx,
                            appLocale: AppLocalizations.of(ctx)!,
                            userInformation: user,
                            phonePageData: phonePageData,
                            changeLocale: (_) {},
                            isWeb: false,
                            onAboutPressed: () {},
                            onNotificationsPressed: () {},
                          );
                        },
                        child: const Text('open'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tapAndSettle(tester, find.byKey(const Key('openMenu')));
    }

    testWidgets('Header menu opens from hamburger icon', (
      WidgetTester tester,
    ) async {
      await openDialogMenu(tester, locale: const Locale('he'));

      final menuDialog = find.byKey(const Key('mainMenuDialog'));
      final closeButton = find.byKey(const Key('mainMenuCloseButton'));
      final menuDialogLeft = tester.getTopLeft(menuDialog).dx;
      final menuDialogWidth = tester.getSize(menuDialog).width;
      final closeButtonLeft = tester.getTopLeft(closeButton).dx;

      expect(find.byKey(const Key('mainMenuDialog')), findsOneWidget);
      expect(
        closeButtonLeft,
        lessThan(menuDialogLeft + menuDialogWidth / 2),
        reason: 'RTL close button should land on the left edge.',
      );
    });
    testWidgets('Header menu puts close button on the right in English', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await openDialogMenu(tester, locale: const Locale('en'));

      final menuDialog = find.byKey(const Key('mainMenuDialog'));
      final closeButton = find.byKey(const Key('mainMenuCloseButton'));
      final menuDialogLeft = tester.getTopLeft(menuDialog).dx;
      final menuDialogWidth = tester.getSize(menuDialog).width;
      final closeButtonLeft = tester.getTopLeft(closeButton).dx;

      expect(
        closeButtonLeft,
        greaterThan(menuDialogLeft + menuDialogWidth / 2),
        reason: 'LTR close button should land on the right edge.',
      );
    });
    testWidgets('Navigate from WellnessTools screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapAndSettle(tester, find.text('כלי תמיכה'));
      await tapAndSettle(tester, find.text('בית'));
      expect(find.byType(Home), findsOneWidget);
    });
    testWidgets('Test Repeated Navigation to and from WellnessTools screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

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
    testWidgets('Test Structure of WellnessTools screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapAndSettle(tester, find.text('כלי תמיכה'));
      expect(find.byType(FakeVideoPlayerPage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('v2'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.byType(MoreVideosItem), findsWidgets);
      expect(find.byKey(const Key("Image")), findsOneWidget);
    });
    testWidgets('Test Texts inside WellnessTools screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapAndSettle(tester, find.text('כלי תמיכה'));
      expect(find.text('v1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('v1d'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('v1d'), findsOneWidget);
      expect(find.text('v2d'), findsNothing);
      expect(find.byType(ExpansionTile), findsOneWidget);

      await tapAndSettle(tester, find.byType(ExpansionTile));
      expect(find.text('v1 transcript'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('v2'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('v2'), findsOneWidget);
      expect(find.text("Image"), findsOneWidget);
    });
    testWidgets('Test change video', (WidgetTester tester) async {
      await tester.pumpWidget(
        getMenuForTests(mockUserInformation, mockAppInformation),
      );

      await tapAndSettle(tester, find.text('כלי תמיכה'));
      await tester.scrollUntilVisible(
        find.text('v2'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tapAndSettle(tester, find.text('v2'));
      await tester.scrollUntilVisible(
        find.text('v2d'),
        -300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('v2d'), findsOneWidget);
      expect(find.text('v1d'), findsNothing);
    });

    testWidgets('shows fallback for malformed or short-id video data', (
      WidgetTester tester,
    ) async {
      await pumpWithProviders(
        tester,
        WellnessTools(
          isFullScreen: false,
          setBool: (_) {},
          videoData: const {
            'videoId': ['short'],
            'videoHeadline': ['Title'],
            'videoDescription': ['Description'],
          },
        ),
      );
      expect(find.text('Videos cannot be shown right now.'), findsOneWidget);

      await pumpWithProviders(
        tester,
        WellnessTools(
          isFullScreen: false,
          setBool: (_) {},
          videoData: const {
            'videoId': ['abcdefghijk'],
            'videoHeadline': ['Title', 'Extra title'],
            'videoDescription': ['Description'],
          },
        ),
      );
      expect(find.text('Videos cannot be shown right now.'), findsOneWidget);
    });

    testWidgets('renders transcript as unbounded long-form text', (
      WidgetTester tester,
    ) async {
      const transcript =
          'Transcript line one. Transcript line two. Transcript line three. '
          'Transcript line four. Transcript line five. Transcript line six. '
          'Transcript line seven.';
      await pumpWithProviders(
        tester,
        WellnessTools(
          isFullScreen: false,
          setBool: (_) {},
          videoData: const {
            'videoId': ['abcdefghijk', 'lmnopqrstuv'],
            'videoHeadline': ['Title one', 'Title two'],
            'videoDescription': ['Description one', 'Description two'],
            'videoTranscript': [transcript, ''],
          },
        ),
        surfaceSize: const Size(900, 1600),
      );

      await tapAndSettle(tester, find.byType(ExpansionTile));

      final transcriptWidget = tester.widget<Text>(find.text(transcript));
      expect(transcriptWidget.maxLines, isNull);
      expect(transcriptWidget.overflow, isNull);
    });

    testWidgets(
      'should keep Wellness Tools content reachable when text is enlarged',
      (tester) async {
        const transcript =
            'Transcript line one. Transcript line two. Transcript line three. '
            'Transcript line four. Transcript line five. Transcript line six. '
            'Transcript line seven. Transcript line eight.';
        final fullscreenChanges = <bool>[];

        await pumpWithProviders(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2.5)),
              child: WellnessTools(
                isFullScreen: false,
                setBool: fullscreenChanges.add,
                videoData: const {
                  'videoId': ['abcdefghijk', 'lmnopqrstuv', 'mnopqrstuvw'],
                  'videoHeadline': [
                    'A long wellness video title for enlarged text',
                    'Another video title',
                    'A third video title',
                  ],
                  'videoDescription': [
                    'A long wellness video description that must remain '
                        'reachable while the page is enlarged.',
                    'Another description',
                    'A third description',
                  ],
                  'videoTranscript': [transcript, '', ''],
                },
              ),
            ),
          ),
          locale: const Locale('he'),
          surfaceSize: const Size(360, 690),
          ignoreOverflow: false,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
        final scrollView = tester.widget<CustomScrollView>(
          find.byType(CustomScrollView),
        );
        expect(scrollbar.controller, same(scrollView.controller));
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(ListView), findsNothing);

        final player = find.byKey(const Key('fake-video-player'));
        final playerSize = tester.getSize(player);
        expect(playerSize.height, closeTo(playerSize.width * 9 / 16, 0.1));

        final pageScrollableFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.physics is! NeverScrollableScrollPhysics,
        );
        expect(pageScrollableFinder, findsOneWidget);
        final pageScrollable = tester.state<ScrollableState>(
          pageScrollableFinder,
        );
        expect(pageScrollable.position.maxScrollExtent, greaterThan(0));

        await tester.ensureVisible(
          find.byKey(const Key('fake-video-player-enter-fullscreen')),
        );
        await tester.tap(
          find.byKey(const Key('fake-video-player-enter-fullscreen')),
        );
        await tester.pumpAndSettle();
        expect(fullscreenChanges, [true]);
        expect(find.byType(MoreVideosItem), findsNothing);

        await tester.tap(
          find.byKey(const Key('fake-video-player-exit-fullscreen')),
        );
        await tester.pumpAndSettle();
        expect(fullscreenChanges, [true, false]);
        await tester.scrollUntilVisible(
          find.text('A third video title'),
          300,
          scrollable: find.byType(Scrollable),
        );
        expect(find.byType(MoreVideosItem), findsWidgets);
        const expectedVideoIds = ['abcdefghijk', 'lmnopqrstuv', 'mnopqrstuvw'];
        for (final item in tester.widgetList<MoreVideosItem>(
          find.byType(MoreVideosItem),
        )) {
          expect(item.key, ValueKey<String>(expectedVideoIds[item.index]));
        }

        final expansionTile = find.byType(ExpansionTile);
        await tester.ensureVisible(expansionTile);
        await tester.tap(expansionTile);
        await tester.pumpAndSettle();
        expect(find.text(transcript), findsOneWidget);

        await tester.ensureVisible(find.text(transcript));
        await tester.scrollUntilVisible(
          find.text('A third video title'),
          300,
          scrollable: find.byType(Scrollable),
        );
        await tester.pumpAndSettle();

        expect(pageScrollable.position.pixels, greaterThan(0));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
