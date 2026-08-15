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
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:mazilon/AnalyticsService.dart';

import '../MenuTest/shareAndDownload/share_and_download_test.mocks.dart'
    as ShareMocks;
import '../helpers/widget_test_scaffold.dart' show NoopAnalyticsService;

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
          child: Scaffold(
            body: WizardStepPage.forStep(
              step: FormPageTemplate(
                key: GlobalKey<WizardStepState>(),
                next: () {},
                prev: () {},
                collectionName: collectionName,
              ),
            ),
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
    // The continue button tracks an analytics event on tap. Previously the
    // button sat below the fold here so the tap silently missed and this was
    // never needed; now that it is pinned to the bottom the tap lands.
    locator.registerSingleton<AnalyticsService>(NoopAnalyticsService());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('MakeSafer collection loads + addItem + continue', (
    tester,
  ) async {
    await _pumpFormPage(tester, 'PersonalPlan-MakeSafer');
    // The 'addItem' path: tap the inline "add your own" link, which opens
    // the AddFormAnswer dialog, then save.
    await tester.ensureVisible(find.text('הוסף עוד משלך'));
    await tester.tap(find.text('הוסף עוד משלך'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'New safer step');
    await tester.tap(find.text('שמור'));
    await tester.pumpAndSettle();
    // Continue button → createSelection → MakeSafer switch arm.
    await tester.tap(find.text('המשך'), warnIfMissed: false);
    await tester.pump();
  });

  testWidgets('FeelBetter collection loads + show-more + continue', (
    tester,
  ) async {
    await _pumpFormPage(tester, 'PersonalPlan-FeelBetter');
    // more-suggestions link: exercises the `length > displayedLength + 3`
    // branch (returns early if list shorter than 3; either way, no crash).
    await tester.tap(find.text('הצעות אחרות'));
    await tester.pump();
    await tester.tap(find.text('המשך'), warnIfMissed: false);
    await tester.pump();
  });

  testWidgets('Distractions collection loads + addItem + continue', (
    tester,
  ) async {
    await _pumpFormPage(tester, 'PersonalPlan-Distractions');
    await tester.ensureVisible(find.text('הוסף עוד משלך'));
    await tester.tap(find.text('הוסף עוד משלך'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Music');
    await tester.tap(find.text('שמור'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('המשך'), warnIfMissed: false);
    await tester.pump();
  });
}
