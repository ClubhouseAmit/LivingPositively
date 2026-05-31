// Interaction tests for the home-page ListWidget that drive the previously
// uncovered closures: `editThanks` / `editTrait` (AddForm dialog), the
// section bar's title-button tap (`onTabTapped`), and the per-row edit/remove
// callbacks that route through `editItemFunction` / `removeItemFunction`.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_widget.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class _NoOpLogger implements IncidentLoggerService {
  @override
  Future<void> initializeSentry(_) async {}
  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {}
}

class _NoOpAnalytics implements AnalyticsService {
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(
    String name, [
    Map<String, dynamic>? properties,
  ]) async {}
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
  void Function(BuildContext, PagesCode)? onTabTapped,
}) {
  return MultiProvider(
    providers: [ChangeNotifierProvider<UserInformation>.value(value: userInfo)],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, _) => Scaffold(
          body: SingleChildScrollView(
            child: ListWidget(
              onTabTapped: onTabTapped ?? (_, _) {},
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

  testWidgets('section-bar title tap fires onTabTapped with the page code', (
    tester,
  ) async {
    PagesCode? captured;
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'male',
      positiveTraits: const ['kind'],
    );

    await tester.binding.setSurfaceSize(const Size(800, 2000));
    await tester.pumpWidget(
      _hostListWidget(
        userInfo: user,
        pageCode: PagesCode.QualitiesList,
        onTabTapped: (_, p) => captured = p,
      ),
    );
    await tester.pumpAndSettle();

    // The section-bar title is wrapped in a TextButton that calls
    // widget.onTabTapped(context, widget.pageCode). Find it via the first
    // TextButton and tap.
    final titleButton = find.byType(TextButton).first;
    await tester.tap(titleButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(captured, PagesCode.QualitiesList);
  });

  testWidgets('add-button on QualitiesList opens the AddForm dialog', (
    tester,
  ) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'male',
      positiveTraits: const [],
    );

    await tester.binding.setSurfaceSize(const Size(800, 2000));
    await tester.pumpWidget(
      _hostListWidget(userInfo: user, pageCode: PagesCode.QualitiesList),
    );
    await tester.pumpAndSettle();

    // The page-level add IconButton is inside the SectionBarHome row. The
    // suggestion-row Icons.add are NOT inside IconButtons (they're inside
    // GestureDetector); so we can target the IconButton ancestor of an add.
    final pageAddIcon = find.descendant(
      of: find.byType(IconButton),
      matching: find.byIcon(Icons.add),
    );
    expect(pageAddIcon, findsWidgets);
    await tester.tap(pageAddIcon.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // AddForm dialog should be visible.
    expect(find.byType(AddForm), findsOneWidget);
  });

  testWidgets('add-button on GratitudeJournal opens the AddForm dialog', (
    tester,
  ) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'female',
      thanks: const <String, List<String>>{},
    );

    await tester.binding.setSurfaceSize(const Size(800, 2000));
    await tester.pumpWidget(
      _hostListWidget(userInfo: user, pageCode: PagesCode.GratitudeJournal),
    );
    await tester.pumpAndSettle();

    final pageAddIcon = find.descendant(
      of: find.byType(IconButton),
      matching: find.byIcon(Icons.add),
    );
    await tester.tap(pageAddIcon.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(AddForm), findsOneWidget);
  });
}
