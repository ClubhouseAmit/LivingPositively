import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import '../MenuTest/shareAndDownload/share_and_download_test.mocks.dart'
    as ShareMocks;

@GenerateNiceMocks([
  MockSpec<UserInformation>(),
  MockSpec<AppInformation>(),
  MockSpec<PersistentMemoryService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeelGood Widget Tests', () {
    late UserInformation mockUserInformation;
    late AppInformation mockAppInformation;
    late GetIt locator;
    setUp(() async {
      locator = GetIt.instance;

      // Reset getIt before each test
      await locator.reset();

      // Create and register ONLY PersistentMemoryService
      final mockPersistentMemoryService =
          ShareMocks.MockPersistentMemoryService();

      // Set up mock behaviors for PersistentMemoryService
      when(mockPersistentMemoryService.getItem(any, any))
          .thenAnswer((_) async => null);
      when(mockPersistentMemoryService.setItem(any, any, any))
          .thenAnswer((_) async {});
      when(mockPersistentMemoryService.reset()).thenAnswer((_) async {});

      // Register PersistentMemoryService with GetIt
      getIt.registerLazySingleton<PersistentMemoryService>(
          () => mockPersistentMemoryService);

      mockUserInformation = UserInformation();
      mockUserInformation.gender = "male";
      mockAppInformation = AppInformation();
    });
    testWidgets('FormPageTemplate widget test', (WidgetTester tester) async {
      // Set the screen size to match your design size
      await tester.binding.setSurfaceSize(const Size(360, 690));

      // PersistentMemoryService is already registered in setUp(); do NOT
      // re-register here — GetIt throws on duplicate registrations.

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppInformation>.value(
                value: mockAppInformation),
            ChangeNotifierProvider<UserInformation>.value(
                value: mockUserInformation),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('he'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ScreenUtilInit(
              designSize: const Size(360, 690),
              child: FormPageTemplate(
                next: () {},
                prev: () {},
                collectionName: 'PersonalPlan-DifficultEvents',
              ),
            ),
          ),
        ),
      );

      // Wait for all animations/async operations to complete
      await tester.pumpAndSettle();

      // Scroll to bottom to see all content
      await tester.drag(find.byType(FormPageTemplate), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // Debug: Print all text widgets to see what's actually there
      final textWidgets = tester.widgetList(find.byType(Text)).cast<Text>();
      debugPrint('\n=== TEXT WIDGETS FOUND ===');
      for (var text in textWidgets) {
        debugPrint('Text: "${text.data}"');
      }
      debugPrint('========================\n');

      // More readable tree dump

      // Verifying initial UI elements
      expect(find.text('תזכורות לטריגרים נפוצים וגורמי הסלמה'), findsOneWidget);
      expect(find.text('גורמים ואירועים שהקשו עלי בעבר'), findsOneWidget);
      expect(find.text('אין לך רעיון? הנה כמה הצעות'), findsOneWidget);
      expect(find.text('לחץ כדי להוסיף אפשרויות המתאימות לך לתכנית האישית שלך'),
          findsOneWidget);
      expect(find.text('להציג עוד'), findsOneWidget);
      expect(find.text('המשך'), findsOneWidget);

      // Verifying interactions
      await tester.enterText(find.byType(TextField), 'New Suggestion');
      await tester.tap(find.text('הוספה'));
      await tester.pump();

      await tester.tap(find.text('להציג עוד'));
      await tester.pump();

      await tester.tap(find.text('המשך'));
      await tester.pump();
    });
  });
}
