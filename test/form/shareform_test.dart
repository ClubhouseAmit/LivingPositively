import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/form/speech_dictation_suffix_action.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/speech_recognition_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mockito/mockito.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/custom_categories_storage.dart';
import '../helpers/widget_test_scaffold.dart'
    show NoopSpeechRecognitionService, wizardStepHarness;
import 'shareform_test.mocks.dart';

const _shareFormStorageKeys = <String>{
  'hasFilled',
  'userSelectionPersonalPlan-DreamsAndGoals',
  'addedStringsPersonalPlan-DreamsAndGoals',
  'selectionSourcesPersonalPlan-DreamsAndGoals',
  customCategoriesKey,
  customCategoryTitlesKey,
  customCategoryDescriptionsKey,
  customCategoriesLegacyCommitKey,
};

bool _isShareFormStorageKey(String key) => _shareFormStorageKeys.contains(key);

dynamic _defaultShareFormStorageValue(PersistentMemoryType type) {
  switch (type) {
    case PersistentMemoryType.Bool:
      return false;
    case PersistentMemoryType.StringList:
      return <String>[];
    case PersistentMemoryType.String:
      return '';
    case PersistentMemoryType.Int:
      return 0;
    case PersistentMemoryType.Double:
      return 0.0;
  }
}

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
    locator.registerSingleton<SpeechRecognitionService>(
      NoopSpeechRecognitionService(),
    );
    // Create and register PersistentMemoryService
    mockPersistentMemoryService = MockPersistentMemoryService();

    // Set up mock behaviors for PersistentMemoryService
    when(mockPersistentMemoryService.getItem(any, any)).thenAnswer((
      invocation,
    ) async {
      final key = invocation.positionalArguments[0] as String;
      final type = invocation.positionalArguments[1] as PersistentMemoryType;
      if (!_isShareFormStorageKey(key)) {
        throw StateError('Unexpected ShareForm persistence key read: $key');
      }
      return _defaultShareFormStorageValue(type);
    });
    when(mockPersistentMemoryService.setItem(any, any, any)).thenAnswer((
      invocation,
    ) {
      final key = invocation.positionalArguments[0] as String;
      if (!_isShareFormStorageKey(key)) {
        throw StateError('Unexpected ShareForm persistence key: $key');
      }
      return SynchronousFuture<void>(null);
    });
    when(mockPersistentMemoryService.reset()).thenAnswer((_) async => {});

    // Register PersistentMemoryService with GetIt
    getIt.registerLazySingleton<PersistentMemoryService>(
      () => mockPersistentMemoryService,
    );

    mockUserInformation = UserInformation(service: mockPersistentMemoryService);
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
          create: (_) => mockAppInformation,
        ),
        ChangeNotifierProvider<UserInformation>(
          create: (_) => mockUserInformation,
        ),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ScreenUtilInit(
          designSize: const Size(360, 690),
          child: wizardStepHarness(
            ShareForm(
              key: GlobalKey<WizardStepState>(),
              prev: () {},
              submit: (context) async {},
              memoryService: mockPersistentMemoryService,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> waitForCustomCategoryPersistence(WidgetTester tester) async {
    // The editor action is intentionally fire-and-forget at the Flutter
    // button boundary. Give its async callback a turn to install the latest
    // pending save before awaiting that future.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.runAsync(
      () => mockUserInformation.pendingCustomCategoriesSave,
    );
    await tester.pump();
  }

  group('ShareForm', () {
    testWidgets('ShareForm renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify the presence of the header and subtitles
      expect(find.text('איזה כיף!'), findsOneWidget);
      expect(
        find.text(
          'יצרת לך מדריך שיעזור לך ברגעי משבר! בוא ונכיר כלים נוספים לעזרה עצמית ולחוסן נפשי',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'עכשיו אתה יכול לשתף את התוכנית עם הקרובים אליך או להוריד אותה כקובץ',
        ),
        findsOneWidget,
      );

      // Verify the presence of the image
      expect(find.byType(Image), findsOneWidget);

      // Verify the presence of the buttons
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('ShareForm initializes correctly with persistent memory', (
      WidgetTester tester,
    ) async {
      // Get the mock service
      final mockPersistentMemoryService =
          GetIt.instance<PersistentMemoryService>();

      // Setup expectations
      when(
        mockPersistentMemoryService.getItem(
          'hasFilled',
          PersistentMemoryType.Bool,
        ),
      ).thenAnswer((_) async => false);
      final completer = Completer<void>();
      when(
        mockPersistentMemoryService.setItem(
          'hasFilled',
          PersistentMemoryType.Bool,
          true,
        ),
      ).thenAnswer((_) async {
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
      verify(
        mockPersistentMemoryService.setItem(
          'hasFilled',
          PersistentMemoryType.Bool,
          true,
        ),
      ).called(1);
    });

    testWidgets(
      'ShareForm edits the shared Dreams and Goals selection without creating a '
      'generic custom category',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(find.byType(FormPageTemplate), findsNothing);
        final dreamsToggle = find.byKey(
          const Key('share-dreams-and-goals-toggle'),
        );
        await tester.ensureVisible(dreamsToggle);
        await tester.tap(dreamsToggle);
        await tester.pumpAndSettle();
        expect(find.byType(FormPageTemplate), findsOneWidget);
        final addOwn = find.text('Add my own personal dream or goal...');
        await tester.ensureVisible(addOwn);
        await tester.tap(addOwn);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'My shared dream');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();

        expect(mockUserInformation.dreamsAndGoals, ['My shared dream']);
        verify(
          mockPersistentMemoryService.setItem(
            'userSelectionPersonalPlan-DreamsAndGoals',
            PersistentMemoryType.StringList,
            ['My shared dream'],
          ),
        ).called(1);
        verify(
          mockPersistentMemoryService.setItem(
            'addedStringsPersonalPlan-DreamsAndGoals',
            PersistentMemoryType.StringList,
            ['My shared dream'],
          ),
        ).called(1);
        verify(
          mockPersistentMemoryService.setItem(
            'selectionSourcesPersonalPlan-DreamsAndGoals',
            PersistentMemoryType.StringList,
            ['custom'],
          ),
        ).called(1);
        verifyNever(
          mockPersistentMemoryService.setItem(
            'customCategoryTitles',
            PersistentMemoryType.StringList,
            any,
          ),
        );
        verifyNever(
          mockPersistentMemoryService.setItem(
            'customCategoryDescriptions',
            PersistentMemoryType.StringList,
            any,
          ),
        );
      },
    );

    testWidgets('ShareForm shows share dialog and generates PDF', (
      WidgetTester tester,
    ) async {
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

    testWidgets('ShareForm places the finish button below custom categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
      await tester.pumpAndSettle();

      final addCategoryTop = tester.getTopLeft(find.text('+ הוספת קטגוריה')).dy;
      final finishTop = tester.getTopLeft(find.text('סיימתי!')).dy;

      expect(finishTop, greaterThan(addCategoryTop));
    });

    testWidgets(
      'should hide dictation on custom category inputs when feature flag is disabled',
      (WidgetTester tester) async {
        final previousFeatureEnabled =
            SpeechDictationSuffixAction.isFeatureEnabled;
        final originalPlatform = debugDefaultTargetPlatformOverride;
        SpeechDictationSuffixAction.isFeatureEnabled = false;
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          await tester.pumpWidget(createTestWidget());
          await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
          await tester.tap(find.text('+ הוספת קטגוריה'));
          await tester.pumpAndSettle();

          final titleField = tester.widget<TextField>(
            find.byKey(const Key('custom-category-title-field')),
          );
          final descriptionField = tester.widget<TextField>(
            find.byKey(const Key('custom-category-description-field')),
          );
          expect(titleField.decoration?.suffixIcon, isNull);
          expect(descriptionField.decoration?.suffixIcon, isNull);
          expect(find.byKey(const Key('speech-dictation-start')), findsNothing);
        } finally {
          SpeechDictationSuffixAction.isFeatureEnabled = previousFeatureEnabled;
          debugDefaultTargetPlatformOverride = originalPlatform;
        }
      },
    );

    testWidgets(
      'should expose dictation on custom category inputs when supported and enabled',
      (WidgetTester tester) async {
        final previousFeatureEnabled =
            SpeechDictationSuffixAction.isFeatureEnabled;
        final originalPlatform = debugDefaultTargetPlatformOverride;
        SpeechDictationSuffixAction.isFeatureEnabled = true;
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          await tester.pumpWidget(createTestWidget());
          await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
          await tester.tap(find.text('+ הוספת קטגוריה'));
          await tester.pumpAndSettle();

          final titleField = tester.widget<TextField>(
            find.byKey(const Key('custom-category-title-field')),
          );
          final descriptionField = tester.widget<TextField>(
            find.byKey(const Key('custom-category-description-field')),
          );
          expect(
            titleField.decoration?.suffixIcon,
            isA<SpeechDictationSuffixAction>(),
          );
          expect(
            descriptionField.decoration?.suffixIcon,
            isA<SpeechDictationSuffixAction>(),
          );
          expect(
            find.byKey(const Key('speech-dictation-start')),
            findsNWidgets(2),
          );
        } finally {
          SpeechDictationSuffixAction.isFeatureEnabled = previousFeatureEnabled;
          debugDefaultTargetPlatformOverride = originalPlatform;
        }
      },
    );

    testWidgets(
      'ShareForm keeps its content clear of the pinned finish button',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final finishTop = tester.getTopLeft(find.text('סיימתי!')).dy;
        final addCategoryBottom = tester
            .getBottomLeft(find.text('+ הוספת קטגוריה'))
            .dy;

        expect(finishTop, lessThanOrEqualTo(844.0));
        expect(addCategoryBottom, lessThanOrEqualTo(finishTop));
      },
    );

    testWidgets('ShareForm adds multiple custom categories in original text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
      await tester.tap(find.text('+ הוספת קטגוריה'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('custom-category-title-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('custom-category-description-field')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('custom-category-title-field')),
        'כותרת מקורית שלי',
      );
      await tester.enterText(
        find.byKey(const Key('custom-category-description-field')),
        'טקסט חופשי בעברית שלא מתורגם',
      );
      await tester.ensureVisible(find.text('הוספת קטגוריה'));
      await tester.tap(find.text('הוספת קטגוריה'));
      await tester.pumpAndSettle();

      expect(find.text('כותרת מקורית שלי'), findsOneWidget);
      expect(find.text('טקסט חופשי בעברית שלא מתורגם'), findsOneWidget);
      expect(find.text('+ הוספת קטגוריה'), findsOneWidget);

      await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
      await tester.tap(find.text('+ הוספת קטגוריה'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('custom-category-title-field')),
        'Second free title',
      );
      await tester.enterText(
        find.byKey(const Key('custom-category-description-field')),
        'English text remains English',
      );
      await tester.ensureVisible(find.text('הוספת קטגוריה'));
      await tester.tap(find.text('הוספת קטגוריה'));
      await tester.pumpAndSettle();

      await waitForCustomCategoryPersistence(tester);
      verify(
        mockPersistentMemoryService.setItem(
          'customCategoryTitles',
          PersistentMemoryType.StringList,
          ['כותרת מקורית שלי', 'Second free title'],
        ),
      ).called(1);
      verify(
        mockPersistentMemoryService.setItem(
          'customCategoryDescriptions',
          PersistentMemoryType.StringList,
          ['טקסט חופשי בעברית שלא מתורגם', 'English text remains English'],
        ),
      ).called(1);
    });

    testWidgets(
      'should surface custom category persistence failure and retry its latest snapshot',
      (WidgetTester tester) async {
        var rejectTitleWrite = true;
        when(mockPersistentMemoryService.setItem(any, any, any)).thenAnswer((
          invocation,
        ) {
          final key = invocation.positionalArguments[0] as String;
          if (!_isShareFormStorageKey(key)) {
            throw StateError('Unexpected ShareForm persistence key: $key');
          }
          if (key == customCategoryTitlesKey && rejectTitleWrite) {
            return Future<void>.sync(
              () => throw StateError(
                'intentional custom category persistence failure',
              ),
            );
          }
          return SynchronousFuture<void>(null);
        });

        await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
        await tester.ensureVisible(find.text('+ Add a custom category'));
        await tester.tap(find.text('+ Add a custom category'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('custom-category-title-field')),
          'My category',
        );
        await tester.enterText(
          find.byKey(const Key('custom-category-description-field')),
          'My description',
        );
        await tester.ensureVisible(find.text('Add category'));
        await tester.tap(find.text('Add category'));
        await tester.pumpAndSettle();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        await tester.runAsync(() async {
          try {
            await mockUserInformation.pendingCustomCategoriesSave;
          } catch (_) {
            // The failure is asserted through the retry snackbar below.
          }
        });
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(SnackBarAction, 'Try again'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        rejectTitleWrite = false;
        tester
            .widget<SnackBarAction>(
              find.widgetWithText(SnackBarAction, 'Try again'),
            )
            .onPressed();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        await tester.runAsync(
          () => mockUserInformation.pendingCustomCategoriesSave,
        );
        await tester.pumpAndSettle();

        verify(
          mockPersistentMemoryService.setItem(
            'customCategoryTitles',
            PersistentMemoryType.StringList,
            ['My category'],
          ),
        ).called(2);
        verify(
          mockPersistentMemoryService.setItem(
            'customCategoryDescriptions',
            PersistentMemoryType.StringList,
            ['My description'],
          ),
        ).called(1);
      },
    );

    testWidgets(
      'ShareForm shows title suggestions when adding another category',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
        await tester.tap(find.text('+ הוספת קטגוריה'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('custom-category-title-field')),
          'קטגוריה ראשונה',
        );
        await tester.enterText(
          find.byKey(const Key('custom-category-description-field')),
          'תיאור ראשון',
        );
        await tester.ensureVisible(find.text('הוספת קטגוריה'));
        await tester.tap(find.text('הוספת קטגוריה'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
        await tester.tap(find.text('+ הוספת קטגוריה'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('custom-category-title-field')));
        await tester.pumpAndSettle();

        expect(find.text('משפטים מחזקים שחשוב לי לזכור'), findsOneWidget);
        expect(find.text('אירועים מהעבר לתזכורת'), findsOneWidget);
        expect(find.text('דברים עלי שחשוב לי שנזכור'), findsOneWidget);
        expect(find.text('אפשרות לכתוב משהו מקורי משלי'), findsOneWidget);
      },
    );

    testWidgets('ShareForm edits and deletes saved custom categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
      await tester.tap(find.text('+ הוספת קטגוריה'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('custom-category-title-field')),
        'כותרת לעריכה',
      );
      await tester.enterText(
        find.byKey(const Key('custom-category-description-field')),
        'תיאור לעריכה',
      );
      await tester.ensureVisible(find.text('הוספת קטגוריה'));
      await tester.tap(find.text('הוספת קטגוריה'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('custom-category-edit-button-0')));
      await tester.pumpAndSettle();

      final titleField = find.byKey(const Key('custom-category-title-field'));
      final descriptionField = find.byKey(
        const Key('custom-category-description-field'),
      );
      expect(
        tester.widget<TextField>(titleField).controller?.text,
        'כותרת לעריכה',
      );
      expect(
        tester.widget<TextField>(descriptionField).controller?.text,
        'תיאור לעריכה',
      );

      await tester.tap(titleField);
      await tester.pumpAndSettle();
      expect(find.text('משפטים מחזקים שחשוב לי לזכור'), findsOneWidget);
      expect(find.text('אירועים מהעבר לתזכורת'), findsOneWidget);
      expect(find.text('דברים עלי שחשוב לי שנזכור'), findsOneWidget);
      expect(find.text('אפשרות לכתוב משהו מקורי משלי'), findsOneWidget);

      await tester.enterText(titleField, 'כותרת אחרי עריכה');
      await tester.enterText(descriptionField, 'תיאור אחרי עריכה');
      await tester.ensureVisible(find.text('הוספת קטגוריה'));
      await tester.tap(find.text('הוספת קטגוריה'));
      await tester.pumpAndSettle();

      expect(find.text('כותרת לעריכה'), findsNothing);
      expect(find.text('תיאור לעריכה'), findsNothing);
      expect(find.text('כותרת אחרי עריכה'), findsOneWidget);
      expect(find.text('תיאור אחרי עריכה'), findsOneWidget);
      await waitForCustomCategoryPersistence(tester);
      verify(
        mockPersistentMemoryService.setItem(
          'customCategoryTitles',
          PersistentMemoryType.StringList,
          ['כותרת אחרי עריכה'],
        ),
      ).called(1);
      verify(
        mockPersistentMemoryService.setItem(
          'customCategoryDescriptions',
          PersistentMemoryType.StringList,
          ['תיאור אחרי עריכה'],
        ),
      ).called(1);

      await tester.tap(
        find.byKey(const Key('custom-category-delete-button-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await waitForCustomCategoryPersistence(tester);

      expect(find.text('כותרת אחרי עריכה'), findsNothing);
      expect(find.text('תיאור אחרי עריכה'), findsNothing);
      expect(find.text('+ הוספת קטגוריה'), findsOneWidget);
      await waitForCustomCategoryPersistence(tester);
      verify(
        mockPersistentMemoryService.setItem(
          'customCategoryTitles',
          PersistentMemoryType.StringList,
          <String>[],
        ),
      ).called(1);
      verify(
        mockPersistentMemoryService.setItem(
          'customCategoryDescriptions',
          PersistentMemoryType.StringList,
          <String>[],
        ),
      ).called(1);
    });

    testWidgets('ShareForm exposes predefined custom category titles', (
      WidgetTester tester,
    ) async {
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

    testWidgets('ShareForm requires both category title and description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
      await tester.tap(find.text('+ הוספת קטגוריה'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('הוספת קטגוריה'));
      await tester.tap(find.text('הוספת קטגוריה'));
      await tester.pumpAndSettle();

      expect(find.text('השדה אינו יכול להיות ריק'), findsNWidgets(2));

      await tester.enterText(
        find.byKey(const Key('custom-category-title-field')),
        'כותרת בלבד',
      );
      await tester.ensureVisible(find.text('הוספת קטגוריה'));
      await tester.tap(find.text('הוספת קטגוריה'));
      await tester.pumpAndSettle();

      expect(find.text('כותרת בלבד'), findsOneWidget);
      expect(find.text('השדה אינו יכול להיות ריק'), findsOneWidget);
      verifyNever(
        mockPersistentMemoryService.setItem(
          'customCategoryTitles',
          PersistentMemoryType.StringList,
          any,
        ),
      );
    });

    testWidgets('ShareForm custom input option keeps title free-form', (
      WidgetTester tester,
    ) async {
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

    testWidgets('ShareForm reloads stored custom text without translating it', (
      WidgetTester tester,
    ) async {
      when(
        mockPersistentMemoryService.getItem(
          'customCategoryTitles',
          PersistentMemoryType.StringList,
        ),
      ).thenAnswer((_) async => ['כותרת עברית שמורה']);
      when(
        mockPersistentMemoryService.getItem(
          'customCategoryDescriptions',
          PersistentMemoryType.StringList,
        ),
      ).thenAnswer((_) async => ['טקסט עברי שמור']);

      await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('כותרת עברית שמורה'));
      expect(find.text('כותרת עברית שמורה'), findsOneWidget);
      expect(find.text('טקסט עברי שמור'), findsOneWidget);
      expect(find.text('+ Add a custom category'), findsOneWidget);
    });
  });
}
