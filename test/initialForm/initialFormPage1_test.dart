import 'package:flutter/material.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/initialForm/initialFormPage1.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/widget_test_scaffold.dart'
    show pumpWithProviders, wizardStepHarness;
import 'initialFormPage1_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserInformation>(),
  MockSpec<AppInformation>(),
  MockSpec<PersistentMemoryService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockPersistentMemoryService mockPersistentMemoryService;
  late MockUserInformation mockUserInformation;
  late MockAppInformation mockAppInformation;

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
    // Default behavior for other keys
    when(
      mockPersistentMemoryService.getItem(
        argThat(isNot(equals('hasFilled'))),
        any,
      ),
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

  testWidgets('test the positive trait list', (WidgetTester tester) async {
    bool tapnext = false;
    bool tapskip = false;
    bool tapprev = false;
    //List<int> index = 0;
    // Mock functions
    mockNext() => {tapnext = !tapnext};
    mockSkip() => {tapskip = !tapskip};
    mockPrev() => {tapprev = !tapprev};
    mockUpdateName(String n) {}

    await pumpWithProviders(
      tester,
      wizardStepHarness(
        InitialFormPage1(
          key: GlobalKey<WizardStepState>(),
          next: mockNext,
          skip: mockSkip,
          prev: mockPrev,
          updateName: mockUpdateName,
        ),
      ),
      userInformation: mockUserInformation,
      appInformation: mockAppInformation,
      locale: const Locale('he'),
    );

    final nextButton = find.byKey(const Key('wizard-primary-action'));
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pump();
    expect(tapnext, isTrue);

    final skipButton = find.byKey(const Key('wizard-secondary-action'));
    expect(skipButton, findsNothing);
  });
}
