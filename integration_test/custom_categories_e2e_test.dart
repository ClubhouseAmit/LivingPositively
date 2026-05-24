import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopFileService implements FileService {
  @override
  Future<String?> download(
      List titles,
      List subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      String textDirection) async {
    return 'noop.pdf';
  }

  @override
  Future<void> share(
      String message,
      List titles,
      List subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      String textDirection) async {}

  @override
  Future<void> shareTextOnly(String message) async {}
}

class _NoopLogger implements IncidentLoggerService {
  @override
  Future<void> captureLog(dynamic exception,
      {StackTrace? stackTrace, dynamic exceptionData}) async {}

  @override
  Future<void> initializeSentry(Widget app) async {}
}

class _NoopAnalytics implements AnalyticsService {
  @override
  Future<void> init() async {}

  @override
  Future<void> trackEvent(String eventName,
      [Map<String, dynamic>? properties]) async {}
}

Widget _shareFormHarness({
  required PersistentMemoryService memoryService,
  required Locale locale,
}) {
  final userInformation = UserInformation(service: memoryService)
    ..gender = 'male'
    ..localeName = locale.languageCode;

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInformation),
      ChangeNotifierProvider<AppInformation>.value(value: AppInformation()),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        child: ShareForm(
          prev: () {},
          submit: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUp(() async {
    await GetIt.instance.reset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    getIt.registerLazySingleton<IncidentLoggerService>(() => _NoopLogger());
    getIt.registerLazySingleton<FileService>(() => _NoopFileService());
    getIt.registerLazySingleton<AnalyticsService>(() => _NoopAnalytics());
    getIt.registerLazySingleton<PersistentMemoryService>(
        () => SharedPreferencesService());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets(
      'user can add repeated custom categories on Android and reload them unchanged',
      (WidgetTester tester) async {
    final memoryService = GetIt.instance<PersistentMemoryService>();

    await tester.pumpWidget(
      _shareFormHarness(
        memoryService: memoryService,
        locale: const Locale('he'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('+ הוספת קטגוריה'));
    await tester.tap(find.text('+ הוספת קטגוריה'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('custom-category-title-field')),
      'כותרת מהאינטגרציה',
    );
    await tester.enterText(
      find.byKey(const Key('custom-category-description-field')),
      'טקסט עברי חופשי שנשאר כמו שהוקלד',
    );
    await tester.ensureVisible(find.text('הוספת קטגוריה'));
    await tester.tap(find.text('הוספת קטגוריה'));
    await tester.pumpAndSettle();

    expect(find.text('כותרת מהאינטגרציה'), findsOneWidget);
    expect(find.text('טקסט עברי חופשי שנשאר כמו שהוקלד'), findsOneWidget);

    await tester.tap(find.text('+ הוספת קטגוריה'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('custom-category-title-field')),
      'Integration English title',
    );
    await tester.enterText(
      find.byKey(const Key('custom-category-description-field')),
      'English notes stay English',
    );
    await tester.ensureVisible(find.text('הוספת קטגוריה'));
    await tester.tap(find.text('הוספת קטגוריה'));
    await tester.pumpAndSettle();

    expect(
      await memoryService.getItem(
          'customCategoryTitles', PersistentMemoryType.StringList),
      ['כותרת מהאינטגרציה', 'Integration English title'],
    );
    expect(
      await memoryService.getItem(
          'customCategoryDescriptions', PersistentMemoryType.StringList),
      ['טקסט עברי חופשי שנשאר כמו שהוקלד', 'English notes stay English'],
    );

    await tester.pumpWidget(
      _shareFormHarness(
        memoryService: memoryService,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('כותרת מהאינטגרציה'));
    expect(find.text('כותרת מהאינטגרציה'), findsOneWidget);
    expect(find.text('טקסט עברי חופשי שנשאר כמו שהוקלד'), findsOneWidget);
    expect(find.text('Integration English title'), findsOneWidget);
    expect(find.text('English notes stay English'), findsOneWidget);
    expect(find.text('+ Add a custom category'), findsOneWidget);
  });
}
