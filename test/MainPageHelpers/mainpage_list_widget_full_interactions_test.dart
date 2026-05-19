// Drives the previously-uncovered closures inside ListWidget:
//   - buildThanksItemSug / buildPositiveTraitItemSug (lines 155-176)
//   - showThankYouPopup (lines 41-67)
//   - editThanksState / editTraitsState setState bodies (lines 70-83)
//   - editTrait / editThanks dialog wiring (lines 96-124)
//   - editItemFunction / removeItemFunction across both pageCode branches
//     (lines 127-152)
//
// We pump ListWidget twice — once with PagesCode.GratitudeJournal and once
// with PagesCode.QualitiesList — and exercise the suggestion tap path plus
// the per-row edit/delete buttons.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_widget.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_item_widget.dart'
    show MainpageListItemWidget;
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/Traits/positiveTraitItemSug.dart';
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
  final Map<String, dynamic> _store = {};

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (_store.containsKey(key)) return _store[key];
    switch (type) {
      case PersistentMemoryType.String:
        return '';
      case PersistentMemoryType.Bool:
        return false;
      case PersistentMemoryType.Int:
        return 0;
      case PersistentMemoryType.Double:
        return 0.0;
      case PersistentMemoryType.StringList:
        return <String>[];
    }
  }

  @override
  Future<void> reset() async {
    _store.clear();
  }

  @override
  Future<void> setItem(String key, PersistentMemoryType type, value) async {
    _store[key] = value;
  }
}

Widget _hostListWidget({
  required UserInformation userInfo,
  required PagesCode pageCode,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInfo),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
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

String _todayDate() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d – 09:00';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<IncidentLoggerService>(_NoOpLogger());
    GetIt.instance.registerSingleton<AnalyticsService>(_NoOpAnalytics());
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      _FakePersistentMemoryService(),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets(
      'tapping a ThanksItemSuggested add button inside a GratitudeJournal '
      'ListWidget appends an entry and shows the AlertDialog popup',
      (tester) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'other',
      thanks: const <String, List<String>>{},
    );

    await tester.binding.setSurfaceSize(const Size(800, 2400));
    await tester.pumpWidget(_hostListWidget(
      userInfo: user,
      pageCode: PagesCode.GratitudeJournal,
    ));
    await tester.pumpAndSettle();

    final firstSug = find.byType(ThanksItemSuggested).first;
    final addGesture = find
        .descendant(of: firstSug, matching: find.byType(GestureDetector))
        .first;
    await tester.ensureVisible(addGesture);
    await tester.tap(addGesture, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(user.thanks['thanks']?.length, 1);
    // First-of-day popup branch (showThankYouPopup).
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets(
      'tapping a PositiveTraitItemSug add button inside a QualitiesList '
      'ListWidget appends a trait',
      (tester) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'other',
      positiveTraits: <String>[],
    );

    await tester.binding.setSurfaceSize(const Size(800, 2400));
    await tester.pumpWidget(_hostListWidget(
      userInfo: user,
      pageCode: PagesCode.QualitiesList,
    ));
    await tester.pumpAndSettle();

    final firstSug = find.byType(PositiveTraitItemSug).first;
    final addGesture = find
        .descendant(of: firstSug, matching: find.byType(GestureDetector))
        .first;
    await tester.ensureVisible(addGesture);
    await tester.tap(addGesture, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(user.positiveTraits.length, greaterThanOrEqualTo(1));
  });

  testWidgets(
      'tapping the edit button on a Gratitude row opens an AddForm seeded '
      'with the existing text',
      (tester) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'other',
    );
    user.updateThanks({
      'thanks': ['Existing thank'],
      'dates': [_todayDate()],
    });

    await tester.binding.setSurfaceSize(const Size(800, 2400));
    await tester.pumpWidget(_hostListWidget(
      userInfo: user,
      pageCode: PagesCode.GratitudeJournal,
    ));
    await tester.pumpAndSettle();

    // The row renders an edit icon — find the first MainpageListItemWidget.
    expect(find.byType(MainpageListItemWidget), findsOneWidget);
    final editIcon = find.byIcon(Icons.edit).first;
    await tester.tap(editIcon, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(AddForm), findsOneWidget);
    final tf = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(tf.controller?.text, 'Existing thank');

    // Close the dialog so the test does not leak the open route.
    final closeBtn = find
        .descendant(
          of: find.byType(AddForm),
          matching: find.byType(TextButton),
        )
        .first;
    await tester.tap(closeBtn, warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'tapping the delete button on a Qualities row removes the trait',
      (tester) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'other',
      positiveTraits: <String>['Brave', 'Kind'],
    );

    await tester.binding.setSurfaceSize(const Size(800, 2400));
    await tester.pumpWidget(_hostListWidget(
      userInfo: user,
      pageCode: PagesCode.QualitiesList,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MainpageListItemWidget), findsNWidgets(2));
    final deleteIcon = find.byIcon(Icons.delete).first;
    await tester.tap(deleteIcon, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(user.positiveTraits.length, 1);
  });

  testWidgets(
      'tapping the edit button on a Qualities row opens an AddForm seeded '
      'with the trait text',
      (tester) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'other',
      positiveTraits: <String>['Patient'],
    );

    await tester.binding.setSurfaceSize(const Size(800, 2400));
    await tester.pumpWidget(_hostListWidget(
      userInfo: user,
      pageCode: PagesCode.QualitiesList,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MainpageListItemWidget), findsOneWidget);
    final editIcon = find.byIcon(Icons.edit).first;
    await tester.tap(editIcon, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(AddForm), findsOneWidget);
    final tf = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(tf.controller?.text, 'Patient');

    final closeBtn = find
        .descendant(
          of: find.byType(AddForm),
          matching: find.byType(TextButton),
        )
        .first;
    await tester.tap(closeBtn, warnIfMissed: false);
    await tester.pumpAndSettle();
  });
}
