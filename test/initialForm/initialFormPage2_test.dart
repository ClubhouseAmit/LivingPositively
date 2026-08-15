import 'package:flutter/material.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/widget_test_scaffold.dart' show wizardStepHarness;

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
  var nextTapped = false;
  var updatedName = '';

  void mockPrev() {}

  void mockUpdateName(String name) {
    updatedName = name;
  }

  setUp(() async {
    nextTapped = false;
    updatedName = '';
    mockUserInformation = MockUserInformation();
    mockAppInformation = MockAppInformation();
    when(mockUserInformation.gender).thenReturn('male');
    when(mockUserInformation.binary).thenReturn(false);
    when(mockUserInformation.age).thenReturn('18-30');
    when(mockUserInformation.disclaimerSigned).thenReturn(true);

    SharedPreferences.setMockInitialValues({'hasFilled': false});
    await GetIt.instance.reset();
    mockPersistentMemoryService = MockPersistentMemoryService();
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
        locale: const Locale('he'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ScreenUtilInit(
          designSize: const Size(360, 690),
          child: wizardStepHarness(
            InitialFormPage2(
              key: GlobalKey<WizardStepState>(),
              next: mockNext,
              prev: mockPrev,
              updateName: mockUpdateName,
            ),
          ),
        ),
      ),
    );
  }

  Finder nextButtonFinder() {
    final loc = lookupAppLocalizations(const Locale('he'));
    return find.ancestor(
      of: find.text(loc.nextButton('male')),
      matching: find.byType(TextButton),
    );
  }

  testWidgets('InitialFormPage2 renders form controls', (tester) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.byType(InitialFormPage2), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(DropdownMenu<String>), findsNWidgets(2));
  });

  testWidgets('InitialFormPage2 text field input', (tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.enterText(find.byType(TextFormField), 'Test Name');
    await tester.pump();

    expect(find.text('Test Name'), findsOneWidget);
  });

  testWidgets('InitialFormPage2 dropdown menu selection', (tester) async {
    await tester.pumpWidget(createTestWidget());

    final firstDropdown = find.byType(DropdownMenu<String>).first;
    await tester.ensureVisible(firstDropdown);
    await tester.tap(firstDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('30-40').last);
    await tester.pumpAndSettle();

    expect(find.text('30-40'), findsWidgets);

    final loc = lookupAppLocalizations(const Locale('he'));
    final lastDropdown = find.byType(DropdownMenu<String>).last;
    await tester.ensureVisible(lastDropdown);
    await tester.tap(lastDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(loc.female).last);
    await tester.pumpAndSettle();

    expect(find.text(loc.female), findsWidgets);
  });

  testWidgets('InitialFormPage2 button tap saves name and advances', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    await tester.enterText(find.byType(TextFormField), 'Test Name');
    await tester.pump();

    final nextButton = nextButtonFinder();
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(nextTapped, isTrue);
    expect(updatedName, 'Test Name');
  });

  testWidgets('InitialFormPage2 whitespace-only name blocks next', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pump();

    final nextButton = nextButtonFinder();
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(nextTapped, isFalse);
    expect(updatedName, isEmpty);
    expect(
      find.text(lookupAppLocalizations(const Locale('he')).nameRequiredError),
      findsOneWidget,
    );
  });
}
