import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazilon/initialForm/initialFormPage1.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/initialForm/toFormPage.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';

import 'package:mazilon/initialForm/form.dart';

import '../helpers/widget_test_scaffold.dart'
    show drainOverflowExceptions, pumpWithProviders;

import 'form_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserInformation>(),
  MockSpec<AppInformation>(),
  MockSpec<SharedPreferences>(),
  MockSpec<PersistentMemoryService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeelGood Widget Tests', () {
    late MockPersistentMemoryService mockPersistentMemoryService;

    late MockSharedPreferences mockSharedPreferences;
    late MockUserInformation mockUserInformation;
    late MockAppInformation mockAppInformation;
    late PhonePageData phonePageData;

    setUp(() async {
      // Setup GetIt before each test
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

      // Setup other mocks
      mockUserInformation = MockUserInformation();
      when(mockUserInformation.gender).thenReturn("male");
      when(mockUserInformation.disclaimerSigned).thenReturn(true);

      // Setup mock AppInformation
      mockAppInformation = MockAppInformation();
      SharedPreferences.setMockInitialValues({'hasFilled': false});

      phonePageData = PhonePageData(
        header: '',
        phoneNames: [],
        phoneNumbers: [],
        subTitle: '',
        midTitle: '',
        phoneNameTitle: '',
        phoneNumberTitle: '',
        key: '',
        savedPhoneNames: [],
        savedPhoneNumbers: [],
        phoneDescription: [],
      );

      mockSharedPreferences = MockSharedPreferences();
      when(
        mockSharedPreferences.getStringList('SavedPhoneNames'),
      ).thenReturn([]);
      when(
        mockSharedPreferences.getStringList('SavedPhoneNumbers'),
      ).thenReturn([]);
    });
    tearDown(() {
      GetIt.I.reset();
    });
    // Setup the test environment
    // SharedPreferences.setMockInitialValues({'hasFilled': false});

    testWidgets('FormPageTemplate widget test', (WidgetTester tester) async {
      await pumpWithProviders(
        tester,
        InitialFormProgressIndicator(
          phonePageData: phonePageData,
          changeLocale: (String locale) {},
        ),
        userInformation: mockUserInformation,
        appInformation: mockAppInformation,
        locale: const Locale('he'),
      );
      await tester.pumpAndSettle();

      // Verify the initial state
      expect(find.byType(InitialFormPage1), findsOneWidget);
      expect(find.byType(InitialFormPage2), findsNothing);
      expect(find.byType(ToFormPage), findsNothing);

      // Tap the next button
      await tester.tap(find.byKey(const Key('wizard-primary-action')));
      await tester.pumpAndSettle();
      drainOverflowExceptions(tester);

      // Verify the state after tapping next
      expect(find.byType(InitialFormPage1), findsNothing);
      expect(find.byType(InitialFormPage2), findsOneWidget);
      expect(find.byType(ToFormPage), findsNothing);

      await tester.enterText(find.byType(TextFormField), 'Tester');
      await tester.pumpAndSettle();

      // Tap the next button again
      await tester.tap(find.byKey(const Key('wizard-primary-action')));
      await tester.pumpAndSettle();
      drainOverflowExceptions(tester);

      // Verify the state after tapping next
      expect(find.byType(InitialFormPage1), findsNothing);
      expect(find.byType(InitialFormPage2), findsNothing);
      expect(find.byType(ToFormPage), findsOneWidget);
    });
  });
}
