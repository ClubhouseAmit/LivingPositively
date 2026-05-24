import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_widget.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class _NoOpLogger implements IncidentLoggerService {
  @override
  Future<void> initializeSentry(_) async {}
  @override
  Future<void> captureLog(dynamic exception,
      {StackTrace? stackTrace, dynamic exceptionData}) async {}
}

class _NoOpAnalytics implements AnalyticsService {
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(String name,
      [Map<String, dynamic>? properties]) async {}
}

class _FakePersistentMemoryService implements PersistentMemoryService {
  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async => null;
  @override
  Future<void> reset() async {}
  @override
  Future<void> setItem(String key, PersistentMemoryType type, value) async {}
}

Widget _hostListWidget({
  required UserInformation userInfo,
  required PagesCode pageCode,
  Locale locale = const Locale('en'),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInfo),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: locale,
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, _) => Scaffold(
          body: SingleChildScrollView(
            child: ListWidget(
              onTabTapped: (_, __) {},
              pageCode: pageCode,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<IncidentLoggerService>(_NoOpLogger());
    GetIt.instance.registerSingleton<AnalyticsService>(_NoOpAnalytics());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets(
      'renders QualitiesList with empty positiveTraits (empty state branch)',
      (tester) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'male',
      positiveTraits: const [],
    );

    await tester.pumpWidget(_hostListWidget(
      userInfo: user,
      pageCode: PagesCode.QualitiesList,
    ));
    await tester.pumpAndSettle();

    // The widget mounts without errors and shows the section bar with the
    // configured icon for the QualitiesList page.
    expect(find.byType(ListWidget), findsOneWidget);
    expect(find.byIcon(Icons.diamond), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets(
      'renders GratitudeJournal with empty thanks (empty state branch)',
      (tester) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'female',
      thanks: const <String, List<String>>{},
    );

    await tester.pumpWidget(_hostListWidget(
      userInfo: user,
      pageCode: PagesCode.GratitudeJournal,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ListWidget), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets(
      'renders QualitiesList with non-empty positiveTraits',
      (tester) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'male',
      positiveTraits: <String>['kind', 'curious'],
    );

    await tester.pumpWidget(_hostListWidget(
      userInfo: user,
      pageCode: PagesCode.QualitiesList,
    ));
    await tester.pumpAndSettle();

    expect(find.text('kind'), findsOneWidget);
    expect(find.text('curious'), findsOneWidget);
  });
}
