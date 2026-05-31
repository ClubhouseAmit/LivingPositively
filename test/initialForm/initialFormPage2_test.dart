import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'initialFormPage2_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserInformation>(),
  MockSpec<AppInformation>(),
  MockSpec<SharedPreferences>(),
  MockSpec<PersistentMemoryService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockUserInformation mockUserInformation;
  late MockAppInformation mockAppInformation;
  late MockPersistentMemoryService mockPersistentMemoryService;
  bool nextTapped = false;
  void mockPrev() {}
  void mockUpdateName(String name) {}
  setUp(() async {
    mockUserInformation = MockUserInformation();
    mockAppInformation = MockAppInformation();
    when(mockUserInformation.gender).thenReturn("male");
    when(mockUserInformation.disclaimerSigned).thenReturn(true);

    // Setup required AppInformation mocks
    when(mockAppInformation.disclaimerText).thenReturn("Test Disclaimer");
    when(mockAppInformation.disclaimerNext).thenReturn("Next");
    when(mockAppInformation.traitMainTitle).thenReturn({"he": "כותרת ראשית"});
    when(mockAppInformation.traitSubTitle).thenReturn({"he": "כותרת משנה"});
    when(mockAppInformation.positiveTraitsPopUpText).thenReturn({"he": "טקסט"});
    when(
      mockAppInformation.personalPlanMainTitle,
    ).thenReturn({"he": "תוכנית אישית"});
    when(
      mockAppInformation.personalPlanSubTitle,
    ).thenReturn({"he": "כותרת משנה"});
    when(mockAppInformation.popupBack).thenReturn({"he": "חזור"});
    when(mockAppInformation.othersuggestions).thenReturn({"he": "הצעות אחרות"});
    SharedPreferences.setMockInitialValues({'hasFilled': false});
    await GetIt.instance.reset();
    mockPersistentMemoryService = MockPersistentMemoryService();

    // Setup specific mock behavior for hasFilled
    when(
      mockPersistentMemoryService.getItem('hasFilled', any),
    ).thenAnswer((_) async => false);
    when(
      mockPersistentMemoryService.getItem(any, any),
    ).thenAnswer((_) async => null);
    when(
      mockPersistentMemoryService.setItem(any, any, any),
    ).thenAnswer((_) async {});
    when(mockPersistentMemoryService.reset()).thenAnswer((_) async {});

    GetIt.instance.registerSingleton<PersistentMemoryService>(
      mockPersistentMemoryService,
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createTestWidget() {
    void mockNext() {
      nextTapped = true;
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppInformation>.value(value: mockAppInformation),
        ChangeNotifierProvider<UserInformation>.value(
          value: mockUserInformation,
        ),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('he'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ScreenUtilInit(
          designSize: const Size(360, 690),
          child: InitialFormPage2(
            next: mockNext,
            prev: mockPrev,
            updateName: mockUpdateName,
          ),
        ),
      ),
      //),
    );
  }

  testWidgets('InitialFormPage2 renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    // Verify the presence of the main title and subtitle
    expect(find.text('בוא נכיר'), findsOneWidget);
    expect(
      find.text(
        'היי, שמחים שהגעת! נשמח להכיר אותך קצת כדי שנוכל לדעת איך לפנות אליך',
      ),
      findsOneWidget,
    );

    // Verify the presence of the form labels
    expect(find.text('כיצד הייתי רוצה שיפנו אלי?'), findsOneWidget);
    expect(find.text('מהו גילי?'), findsOneWidget);
    expect(find.text('כיצד הייתי רוצה שיפנו אלי?'), findsOneWidget);

    // Verify the presence of the text field and dropdown menus
    expect(find.byType(TextField), findsWidgets);
    expect(find.byType(DropdownMenu<String>), findsNWidgets(2));
  });

  testWidgets('InitialFormPage2 text field input', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Enter text in the name text field
    await tester.enterText(find.byType(TextField).first, 'Test Name');
    await tester.pump();

    // Verify the entered text
    expect(find.text('Test Name'), findsOneWidget);
  });

  testWidgets('InitialFormPage2 dropdown menu selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    // Tap on the age dropdown menu and select an option
    await tester.tap(find.byType(DropdownMenu<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('30-40').last);
    await tester.pumpAndSettle();

    // Verify the selected age
    expect(find.text('30-40'), findsWidgets);

    // Tap on the gender dropdown menu and select an option
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('את').last);
    await tester.pumpAndSettle();

    // Verify the selected gender
    expect(find.text('את'), findsWidgets);
  });

  testWidgets('InitialFormPage2 button tap', (WidgetTester tester) async {
    // Override the mockNext function to set a flag when called

    await tester.pumpWidget(createTestWidget());

    // Enter text in the name text field
    await tester.enterText(find.byType(TextField).first, 'Test Name');
    await tester.pump();

    // Tap the next button
    await tester.scrollUntilVisible(
      find.text('המשך'),
      500.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('המשך'));
    await tester.pumpAndSettle();
    expect(nextTapped, isTrue);
  });
}
