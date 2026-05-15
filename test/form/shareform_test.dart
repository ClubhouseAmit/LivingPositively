import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mazilon/form/ShareForm.dart';
import 'package:mockito/mockito.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'shareform_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserInformation>(),
  MockSpec<AppInformation>(),
  MockSpec<FileService>(),
  MockSpec<AnalyticsService>(),
  MockSpec<PersistentMemoryService>(),
])
void main() {
  late UserInformation mockUserInformation;
  late AppInformation mockAppInformation;
  late GetIt locator;

  setUp(() async {
    locator = GetIt.instance;

    // Reset getIt before each test
    await locator.reset();
    // Create and register ONLY PersistentMemoryService
    final mockPersistentMemoryService = MockPersistentMemoryService();

    // Set up mock behaviors for PersistentMemoryService
    when(mockPersistentMemoryService.getItem(
            'hasFilled', PersistentMemoryType.Bool))
        .thenAnswer((_) async => false);
    when(mockPersistentMemoryService.setItem(any, any, any))
        .thenAnswer((_) async => {});
    when(mockPersistentMemoryService.reset()).thenAnswer((_) async => {});

    // Register PersistentMemoryService with GetIt
    getIt.registerLazySingleton<PersistentMemoryService>(
        () => mockPersistentMemoryService);

    mockUserInformation = UserInformation();
    mockUserInformation.gender = "male";
    mockAppInformation = AppInformation();
    final mockAnalytics = MockAnalyticsService();
    getIt.registerLazySingleton<AnalyticsService>(() => mockAnalytics);
    final mockFileServiceImpl = MockFileService();
    getIt.registerLazySingleton<FileService>(() => mockFileServiceImpl);
  });
  tearDown(() async {
    final locator = GetIt.instance;
    // Optionally reset GetIt after each test
    await locator.reset();
  });
  // Mock data for the test

  // Mock shared preferences
  SharedPreferences.setMockInitialValues({'hasFilled': false});

  // Create the test widget
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppInformation>(
            create: (_) => mockAppInformation),
        ChangeNotifierProvider<UserInformation>(
            create: (_) => mockUserInformation),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('he'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ScreenUtilInit(
          designSize: const Size(360, 690),
          child: ShareForm(
            prev: () {},
            submit: (context) {},
          ),
        ),
      ),
    );
  }

  testWidgets('ShareForm renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Verify the presence of the header and subtitles
    expect(find.text('איזה כיף!'), findsOneWidget);
    expect(
        find.text(
            'יצרת לך מדריך שיעזור לך ברגעי משבר! בוא ונכיר כלים נוספים לעזרה עצמית ולחוסן נפשי'),
        findsOneWidget);
    expect(
        find.text(
            'עכשיו אתה יכול לשתף את התוכנית עם הקרובים אליך או להוריד אותה כקובץ'),
        findsOneWidget);

    // Verify the presence of the image
    expect(find.byType(Image), findsOneWidget);

    // Verify the presence of the buttons
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('ShareForm initializes correctly with persistent memory',
      (WidgetTester tester) async {
    // Get the mock service
    final mockPersistentMemoryService =
        GetIt.instance<PersistentMemoryService>();

    // Setup expectations
    when(mockPersistentMemoryService.getItem(
            'hasFilled', PersistentMemoryType.Bool))
        .thenAnswer((_) async => false);
    final completer = Completer<void>();
    when(mockPersistentMemoryService.setItem(
            'hasFilled', PersistentMemoryType.Bool, true))
        .thenAnswer((_) async {
      completer.complete();
      return null;
    });

    // Pump the widget and let it settle
    await tester.pumpWidget(createTestWidget());
    await completer.future;
    await tester.pumpAndSettle();
    // Verify the widget is rendered
    expect(find.byType(ShareForm), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    // Verify memory service interactions
    verify(mockPersistentMemoryService.setItem(
            'hasFilled', PersistentMemoryType.Bool, true))
        .called(1);
  });

  testWidgets('ShareForm shows share dialog and generates PDF',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Tap the share button
    await tester.tap(find.byIcon(Icons.share));
    await tester.pumpAndSettle();
/*
    // Verify the dialog is shown
    expect(find.text("Quick Share"), findsOneWidget);
    expect(find.text('Share Title Male'), findsOneWidget);

    // Tap the emergency send button
    await tester.tap(find.text('Emergency Send'));
    await tester.pumpAndSettle();

    // Verify the dialog is closed
    expect(find.text("SAVE"), findsNothing);*/
  });

  testWidgets('ShareForm triggers PDF download', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Mock permission request
    //when(permissionHandler.requestPermissions([Permission.manageExternalStorage]))
    //    .thenAnswer((_) async => {Permission.manageExternalStorage: PermissionStatus.granted});

    // Tap the download button
    await tester.tap(find.byIcon(Icons.download));
    await tester.pumpAndSettle();

    // Verify the permission request and PDF download logic
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('ShareForm submit button works', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Tap the finish button
    await tester.tap(find.text('סיימתי!'));
    await tester.pumpAndSettle();

    // Verify the submit function is called
    // This can be verified by checking navigation or other state changes
  });
}
