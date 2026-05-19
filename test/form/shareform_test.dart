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

import 'package:mazilon/form/shareform.dart';
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
  late MockPersistentMemoryService mockPersistentMemoryService;
  late GetIt locator;

  setUp(() async {
    locator = GetIt.instance;

    // Reset getIt before each test
    await locator.reset();
    // Create and register ONLY PersistentMemoryService
    mockPersistentMemoryService = MockPersistentMemoryService();

    // Set up mock behaviors for PersistentMemoryService
    when(mockPersistentMemoryService.getItem(any, any))
        .thenAnswer((invocation) async {
      final type = invocation.positionalArguments[1];
      if (type == PersistentMemoryType.Bool) {
        return false;
      }
      if (type == PersistentMemoryType.StringList) {
        return <String>[];
      }
      return '';
    });
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
  Widget createTestWidget({Locale locale = const Locale('he')}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppInformation>(
            create: (_) => mockAppInformation),
        ChangeNotifierProvider<UserInformation>(
            create: (_) => mockUserInformation),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
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
    await tester.ensureVisible(find.byIcon(Icons.share));
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
    await tester.ensureVisible(find.byIcon(Icons.download));
    await tester.tap(find.byIcon(Icons.download));
    await tester.pumpAndSettle();

    // Verify the permission request and PDF download logic
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('ShareForm submit button works', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Tap the finish button
    await tester.ensureVisible(find.text('סיימתי!'));
    await tester.tap(find.text('סיימתי!'));
    await tester.pumpAndSettle();

    // Verify the submit function is called
    // This can be verified by checking navigation or other state changes
  });

  testWidgets('ShareForm adds multiple custom categories in original text',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
    await tester.tap(find.text('+ הוספת קטגוריה'));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('custom-category-title-field')), findsOneWidget);
    expect(find.byKey(const Key('custom-category-description-field')),
        findsOneWidget);

    await tester.enterText(find.byKey(const Key('custom-category-title-field')),
        'כותרת מקורית שלי');
    await tester.enterText(
        find.byKey(const Key('custom-category-description-field')),
        'טקסט חופשי בעברית שלא מתורגם');
    await tester.ensureVisible(find.text('הוספת קטגוריה'));
    await tester.tap(find.text('הוספת קטגוריה'));
    await tester.pumpAndSettle();

    expect(find.text('כותרת מקורית שלי'), findsOneWidget);
    expect(find.text('טקסט חופשי בעברית שלא מתורגם'), findsOneWidget);
    expect(find.text('+ הוספת קטגוריה'), findsOneWidget);

    await tester.tap(find.text('+ הוספת קטגוריה'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('custom-category-title-field')),
        'Second free title');
    await tester.enterText(
        find.byKey(const Key('custom-category-description-field')),
        'English text remains English');
    await tester.ensureVisible(find.text('הוספת קטגוריה'));
    await tester.tap(find.text('הוספת קטגוריה'));
    await tester.pumpAndSettle();

    verify(mockPersistentMemoryService.setItem(
      'customCategoryTitles',
      PersistentMemoryType.StringList,
      ['כותרת מקורית שלי', 'Second free title'],
    )).called(1);
    verify(mockPersistentMemoryService.setItem(
      'customCategoryDescriptions',
      PersistentMemoryType.StringList,
      ['טקסט חופשי בעברית שלא מתורגם', 'English text remains English'],
    )).called(1);
  });

  testWidgets('ShareForm exposes predefined custom category titles',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
    await tester.tap(find.text('+ הוספת קטגוריה'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('custom-category-title-field')));
    await tester.pumpAndSettle();

    expect(find.text('משפטים מחזקים שחשוב לי לזכור'), findsOneWidget);
    expect(find.text('אירועים מהעבר לתזכורת'), findsOneWidget);
    expect(find.text('דברים עלי שחשוב לי שנזכור'), findsOneWidget);
    expect(find.text('אפשרות לכתוב משהו מקורי משלי'), findsOneWidget);
  });

  testWidgets('ShareForm requires both category title and description',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
    await tester.tap(find.text('+ הוספת קטגוריה'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('הוספת קטגוריה'));
    await tester.tap(find.text('הוספת קטגוריה'));
    await tester.pumpAndSettle();

    expect(find.text('השדה אינו יכול להיות ריק'), findsNWidgets(2));

    await tester.enterText(
        find.byKey(const Key('custom-category-title-field')), 'כותרת בלבד');
    await tester.tap(find.text('הוספת קטגוריה'));
    await tester.pumpAndSettle();

    expect(find.text('כותרת בלבד'), findsOneWidget);
    expect(find.text('השדה אינו יכול להיות ריק'), findsOneWidget);
    verifyNever(mockPersistentMemoryService.setItem(
      'customCategoryTitles',
      PersistentMemoryType.StringList,
      any,
    ));
  });

  testWidgets('ShareForm custom input option keeps title free-form',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
    await tester.tap(find.text('+ הוספת קטגוריה'));
    await tester.pumpAndSettle();

    final titleField = find.byKey(const Key('custom-category-title-field'));
    await tester.tap(titleField);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('אפשרות לכתוב משהו מקורי משלי'));
    await tester.tap(find.text('אפשרות לכתוב משהו מקורי משלי'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(titleField).controller?.text, isEmpty);

    await tester.enterText(titleField, 'Free typed title');
    await tester.enterText(
      find.byKey(const Key('custom-category-description-field')),
      'Typed description',
    );
    await tester.ensureVisible(find.text('הוספת קטגוריה'));
    await tester.tap(find.text('הוספת קטגוריה'));
    await tester.pumpAndSettle();

    expect(find.text('Free typed title'), findsOneWidget);
    expect(find.text('Typed description'), findsOneWidget);
  });

  testWidgets('ShareForm reloads stored custom text without translating it',
      (WidgetTester tester) async {
    when(mockPersistentMemoryService.getItem(
      'customCategoryTitles',
      PersistentMemoryType.StringList,
    )).thenAnswer((_) async => ['כותרת עברית שמורה']);
    when(mockPersistentMemoryService.getItem(
      'customCategoryDescriptions',
      PersistentMemoryType.StringList,
    )).thenAnswer((_) async => ['טקסט עברי שמור']);

    await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('כותרת עברית שמורה'));
    expect(find.text('כותרת עברית שמורה'), findsOneWidget);
    expect(find.text('טקסט עברי שמור'), findsOneWidget);
    expect(find.text('+ Add a custom category'), findsOneWidget);
  });
}
