// Additional branch coverage for FormPageTemplate.
//
// The existing `formpagetemplate_test.dart` exercises the
// `PersonalPlan-DifficultEvents` collectionName. We add render-only smoke
// tests for the other three collection names so the `loadItems` and
// `createSelection` switch arms (`MakeSafer`, `FeelBetter`, `Distractions`)
// are exercised in coverage.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../MenuTest/shareAndDownload/share_and_download_test.mocks.dart'
    as ShareMocks;

Future<void> _pumpFormPage(WidgetTester tester, String collectionName) async {
  await tester.binding.setSurfaceSize(const Size(360, 690));
  final mockUser = UserInformation();
  mockUser.gender = 'male';
  mockUser.difficultEvents = ['de1'];
  mockUser.makeSafer = ['ms1'];
  mockUser.feelBetter = ['fb1'];
  mockUser.distractions = ['d1'];
  final mockApp = AppInformation();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppInformation>.value(value: mockApp),
        ChangeNotifierProvider<UserInformation>.value(value: mockUser),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('he'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ScreenUtilInit(
          designSize: const Size(360, 690),
          child: FormPageTemplate(
            next: () {},
            prev: () {},
            collectionName: collectionName,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt locator;
  setUp(() async {
    locator = GetIt.instance;
    await locator.reset();
    final mockPm = ShareMocks.MockPersistentMemoryService();
    when(mockPm.getItem(any, any)).thenAnswer((_) async => null);
    when(mockPm.setItem(any, any, any)).thenAnswer((_) async {});
    when(mockPm.reset()).thenAnswer((_) async {});
    locator.registerLazySingleton<PersistentMemoryService>(() => mockPm);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('MakeSafer collection loads + addItem + continue', (tester) async {
    await _pumpFormPage(tester, 'PersonalPlan-MakeSafer');
    // The 'addItem' path: enter text and tap the add button.
    await tester.enterText(find.byType(TextField), 'New safer step');
    await tester.tap(find.text('הוספה'));
    await tester.pump();
    // Continue button → createSelection → MakeSafer switch arm.
    await tester.tap(find.text('המשך'));
    await tester.pump();
  });

  testWidgets('FeelBetter collection loads + show-more + continue',
      (tester) async {
    await _pumpFormPage(tester, 'PersonalPlan-FeelBetter');
    // show-more button: exercises the `length > displayedLength + 3` branch
    // (returns early if list shorter than 3; either way, no crash).
    await tester.tap(find.text('להציג עוד'));
    await tester.pump();
    await tester.tap(find.text('המשך'));
    await tester.pump();
  });

  testWidgets('Distractions collection loads + addItem + continue',
      (tester) async {
    await _pumpFormPage(tester, 'PersonalPlan-Distractions');
    await tester.enterText(find.byType(TextField), 'Music');
    await tester.tap(find.text('הוספה'));
    await tester.pump();
    await tester.tap(find.text('המשך'));
    await tester.pump();
  });
}
