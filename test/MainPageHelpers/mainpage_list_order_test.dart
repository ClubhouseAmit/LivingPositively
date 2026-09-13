import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_body_widget.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_item_number_widget.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_item_widget.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_widget.dart';
import 'package:mazilon/MainPageHelpers/show_all_button.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/Traits/positiveTraitItemSug.dart';
import 'package:mazilon/util/suggestion_add_button.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

String _date(DateTime date, String time) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day – $time';
}

Future<void> _pumpListWidget(
  WidgetTester tester, {
  required UserInformation user,
  required PagesCode pageCode,
}) {
  return pumpWithProviders(
    tester,
    Scaffold(
      body: ListWidget(onTabTapped: (_, _) {}, pageCode: pageCode),
    ),
    userInformation: user,
    surfaceSize: const Size(800, 2400),
  );
}

List<String> _traitSuggestions(WidgetTester tester) {
  return tester
      .widgetList<PositiveTraitItemSug>(find.byType(PositiveTraitItemSug))
      .map((widget) => widget.inputText)
      .toList();
}

List<String> _thanksSuggestions(WidgetTester tester) {
  return tester
      .widgetList<ThanksItemSuggested>(find.byType(ThanksItemSuggested))
      .map((widget) => widget.inputText)
      .toList();
}

Finder _refreshButton() {
  return find.ancestor(
    of: find.text('other suggestions'),
    matching: find.byType(TextButton),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServiceLocators services;

  setUp(() {
    services = registerTestServices(locale: 'en');
  });

  tearDown(resetTestServices);

  UserInformation user({
    List<String> traits = const [],
    Map<String, List<String>> thanks = const {},
  }) {
    return UserInformation(
      service: services.memory,
      gender: 'other',
      positiveTraits: List<String>.from(traits),
      thanks: {
        'thanks': List<String>.from(thanks['thanks'] ?? const []),
        'dates': List<String>.from(thanks['dates'] ?? const []),
      },
    );
  }

  testWidgets('places saved traits before show all and refreshed suggestions', (
    tester,
  ) async {
    final testUser = user(traits: ['older', 'newer']);

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.QualitiesList,
    );

    final rows = tester
        .widgetList<MainpageListItemWidget>(find.byType(MainpageListItemWidget))
        .toList();
    expect(rows.map((row) => row.item), ['newer', 'older']);
    expect(
      tester
          .widget<ListItemNumberWidget>(find.byType(ListItemNumberWidget).first)
          .index,
      0,
    );

    final listBodyY = tester.getTopLeft(find.byType(ListBodyWidget)).dy;
    final showAllY = tester.getTopLeft(find.byType(ShowAllButton)).dy;
    final suggestionY = tester
        .getTopLeft(find.byType(PositiveTraitItemSug).first)
        .dy;
    final refreshY = tester.getTopLeft(_refreshButton()).dy;

    expect(listBodyY, lessThan(showAllY));
    expect(showAllY, lessThan(suggestionY));
    expect(suggestionY, lessThan(refreshY));
  });

  testWidgets('renders today gratitude entries newest first', (tester) async {
    final now = DateTime.now();
    final testUser = user(
      thanks: {
        'thanks': ['older today', 'newer today'],
        'dates': [_date(now, '09:00'), _date(now, '10:00')],
      },
    );

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.GratitudeJournal,
    );

    final rows = tester
        .widgetList<MainpageListItemWidget>(find.byType(MainpageListItemWidget))
        .toList();
    expect(rows.map((row) => row.item), ['newer today', 'older today']);
    expect(_thanksSuggestions(tester), hasLength(3));
    expect(_refreshButton(), findsOneWidget);
  });

  testWidgets('should label the gratitude journal with its full entry count', (
    tester,
  ) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final testUser = user(
      thanks: {
        'thanks': ['historic', 'today'],
        'dates': [_date(yesterday, '09:00'), _date(now, '10:00')],
      },
    );

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.GratitudeJournal,
    );

    expect(tester.widget<ShowAllButton>(find.byType(ShowAllButton)).count, 2);
  });

  testWidgets(
    'maps reversed qualities edits and deletes to their source rows',
    (tester) async {
      final testUser = user(traits: ['oldest', 'middle', 'newest']);

      await _pumpListWidget(
        tester,
        user: testUser,
        pageCode: PagesCode.QualitiesList,
      );

      tester
          .widget<MainpageListItemWidget>(
            find.byType(MainpageListItemWidget).at(2),
          )
          .onEdit();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller
            ?.text,
        'oldest',
      );

      await tester.enterText(find.byType(TextFormField), 'renamed oldest');
      await tester.tap(
        find
            .descendant(
              of: find.byType(AddForm),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(testUser.positiveTraits, ['renamed oldest', 'middle', 'newest']);

      tester
          .widget<MainpageListItemWidget>(
            find.byType(MainpageListItemWidget).first,
          )
          .onDelete();
      await tester.pumpAndSettle();
      expect(testUser.positiveTraits, ['renamed oldest', 'middle']);
    },
  );

  testWidgets(
    'maps filtered gratitude edits and deletes to their source rows',
    (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final testUser = user(
        thanks: {
          'thanks': [
            'duplicate',
            'historic',
            'middle today',
            'duplicate',
            'older historic',
          ],
          'dates': [
            _date(now, '08:00'),
            _date(yesterday, '11:00'),
            _date(now, '09:00'),
            _date(now, '10:00'),
            _date(yesterday, '12:00'),
          ],
        },
      );

      await _pumpListWidget(
        tester,
        user: testUser,
        pageCode: PagesCode.GratitudeJournal,
      );

      tester
          .widget<MainpageListItemWidget>(
            find.byType(MainpageListItemWidget).at(2),
          )
          .onEdit();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'edited source zero');
      await tester.tap(
        find
            .descendant(
              of: find.byType(AddForm),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(testUser.thanks['thanks']?[0], 'edited source zero');
      expect(testUser.thanks['dates']?[0], _date(now, '08:00'));

      tester
          .widget<MainpageListItemWidget>(
            find.byType(MainpageListItemWidget).first,
          )
          .onDelete();
      await tester.pumpAndSettle();
      expect(testUser.thanks['thanks'], [
        'edited source zero',
        'historic',
        'middle today',
        'older historic',
      ]);
      expect(testUser.thanks['dates'], [
        _date(now, '08:00'),
        _date(yesterday, '11:00'),
        _date(now, '09:00'),
        _date(yesterday, '12:00'),
      ]);
    },
  );

  testWidgets('ignores stale reversed qualities callbacks', (tester) async {
    final testUser = user(traits: ['older', 'newer']);

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.QualitiesList,
    );

    final staleCallbacks = tester.widget<ListBodyWidget>(
      find.byType(ListBodyWidget),
    );

    testUser.updatePositiveTraits(['older']);
    await tester.pump();
    staleCallbacks.editItems(0);
    await tester.pumpAndSettle();

    expect(find.byType(AddForm), findsNothing);
    expect(testUser.positiveTraits, ['older']);

    staleCallbacks.removeItems(0);
    await tester.pumpAndSettle();

    expect(testUser.positiveTraits, ['older']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ignores stale filtered gratitude callbacks when storage shrinks',
    (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final historicalDate = _date(yesterday, '08:00');
      final olderTodayDate = _date(now, '09:00');
      final newerTodayDate = _date(now, '10:00');
      final testUser = user(
        thanks: {
          'thanks': ['historic', 'older today', 'newer today'],
          'dates': [historicalDate, olderTodayDate, newerTodayDate],
        },
      );

      await _pumpListWidget(
        tester,
        user: testUser,
        pageCode: PagesCode.GratitudeJournal,
      );

      final staleCallbacks = tester.widget<ListBodyWidget>(
        find.byType(ListBodyWidget),
      );

      testUser.updateThanks({
        'thanks': ['historic', 'older today'],
        'dates': [historicalDate, olderTodayDate],
      });
      await tester.pump();
      staleCallbacks.editItems(0);
      await tester.pumpAndSettle();

      expect(find.byType(AddForm), findsNothing);
      expect(testUser.thanks['thanks'], ['historic', 'older today']);

      testUser.updateThanks({
        'thanks': ['historic', 'older today', 'newer today'],
        'dates': [historicalDate, olderTodayDate],
      });
      await tester.pump();
      staleCallbacks.removeItems(0);
      await tester.pumpAndSettle();

      expect(testUser.thanks['thanks'], [
        'historic',
        'older today',
        'newer today',
      ]);
      expect(testUser.thanks['dates'], [historicalDate, olderTodayDate]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ignores stale in-range qualities callbacks after reordering', (
    tester,
  ) async {
    final testUser = user(traits: ['duplicate', 'middle', 'duplicate']);

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.QualitiesList,
    );

    final staleCallbacks = tester.widget<ListBodyWidget>(
      find.byType(ListBodyWidget),
    );
    testUser.updatePositiveTraits(['middle', 'duplicate', 'duplicate']);
    await tester.pump();

    staleCallbacks.editItems(0);
    await tester.pumpAndSettle();
    expect(find.byType(AddForm), findsNothing);
    expect(testUser.positiveTraits, ['middle', 'duplicate', 'duplicate']);

    staleCallbacks.removeItems(0);
    await tester.pumpAndSettle();
    expect(testUser.positiveTraits, ['middle', 'duplicate', 'duplicate']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores stale in-range gratitude callbacks after reordering', (
    tester,
  ) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final historicalDate = _date(yesterday, '08:00');
    final olderTodayDate = _date(now, '09:00');
    final newerTodayDate = _date(now, '10:00');
    final testUser = user(
      thanks: {
        'thanks': ['historic', 'older today', 'newer today'],
        'dates': [historicalDate, olderTodayDate, newerTodayDate],
      },
    );

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.GratitudeJournal,
    );

    final staleCallbacks = tester.widget<ListBodyWidget>(
      find.byType(ListBodyWidget),
    );
    testUser.updateThanks({
      'thanks': ['historic', 'newer today', 'older today'],
      'dates': [historicalDate, newerTodayDate, olderTodayDate],
    });
    await tester.pump();

    staleCallbacks.editItems(0);
    await tester.pumpAndSettle();
    expect(find.byType(AddForm), findsNothing);
    expect(testUser.thanks['thanks'], [
      'historic',
      'newer today',
      'older today',
    ]);

    staleCallbacks.removeItems(0);
    await tester.pumpAndSettle();
    expect(testUser.thanks['thanks'], [
      'historic',
      'newer today',
      'older today',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'refreshes qualities suggestions and excludes a newly added one',
    (tester) async {
      final testUser = user(traits: <String>[]);

      await _pumpListWidget(
        tester,
        user: testUser,
        pageCode: PagesCode.QualitiesList,
      );

      final initialSuggestions = _traitSuggestions(tester);
      expect(initialSuggestions, hasLength(3));
      expect(initialSuggestions.toSet(), hasLength(3));

      await tester.tap(_refreshButton());
      await tester.pumpAndSettle();
      final refreshedSuggestions = _traitSuggestions(tester);
      expect(refreshedSuggestions, isNot(equals(initialSuggestions)));
      expect(refreshedSuggestions.toSet(), hasLength(3));

      final selectedSuggestion = refreshedSuggestions.first;
      final selectedRow = find.byWidgetPredicate(
        (widget) =>
            widget is PositiveTraitItemSug &&
            widget.inputText == selectedSuggestion,
      );
      await tester.tap(
        find.descendant(
          of: selectedRow,
          matching: find.byType(SuggestionAddButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(testUser.positiveTraits, contains(selectedSuggestion));
      expect(_traitSuggestions(tester), isNot(contains(selectedSuggestion)));
    },
  );

  testWidgets('refreshes qualities suggestions after an external update', (
    tester,
  ) async {
    final testUser = user(traits: <String>[]);

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.QualitiesList,
    );

    final offeredSuggestion = _traitSuggestions(tester).first;
    testUser.updatePositiveTraits([offeredSuggestion]);
    await tester.pump();

    expect(_traitSuggestions(tester), isNot(contains(offeredSuggestion)));
  });

  testWidgets('refreshes gratitude suggestions with unique eligible values', (
    tester,
  ) async {
    final now = DateTime.now();
    final testUser = user(
      thanks: {
        'thanks': ['already saved'],
        'dates': [_date(now, '09:00')],
      },
    );

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.GratitudeJournal,
    );

    final initialSuggestions = _thanksSuggestions(tester);
    expect(initialSuggestions, hasLength(3));
    expect(initialSuggestions.toSet(), hasLength(3));

    await tester.tap(_refreshButton());
    await tester.pumpAndSettle();
    final refreshedSuggestions = _thanksSuggestions(tester);
    expect(refreshedSuggestions, isNot(equals(initialSuggestions)));
    expect(refreshedSuggestions.toSet(), hasLength(3));

    final selectedSuggestion = refreshedSuggestions.first;
    final selectedRow = find.byWidgetPredicate(
      (widget) =>
          widget is ThanksItemSuggested &&
          widget.inputText == selectedSuggestion,
    );
    await tester.tap(
      find.descendant(
        of: selectedRow,
        matching: find.byType(SuggestionAddButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(testUser.thanks['thanks'], contains(selectedSuggestion));
    expect(_thanksSuggestions(tester), isNot(contains(selectedSuggestion)));
  });

  testWidgets('refreshes gratitude suggestions after an external update', (
    tester,
  ) async {
    final now = DateTime.now();
    final testUser = user();

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.GratitudeJournal,
    );

    final offeredSuggestion = _thanksSuggestions(tester).first;
    testUser.updateThanks({
      'thanks': [offeredSuggestion],
      'dates': [_date(now, '09:00')],
    });
    await tester.pump();

    expect(_thanksSuggestions(tester), isNot(contains(offeredSuggestion)));
  });

  testWidgets('handles gratitude dates that outnumber saved entries', (
    tester,
  ) async {
    final now = DateTime.now();
    final testUser = user(
      thanks: {
        'thanks': ['today'],
        'dates': [_date(now, '09:00'), _date(now, '10:00')],
      },
    );

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.GratitudeJournal,
    );

    final rows = tester
        .widgetList<MainpageListItemWidget>(find.byType(MainpageListItemWidget))
        .toList();
    expect(rows.map((row) => row.item), ['today']);
    expect(_thanksSuggestions(tester), hasLength(3));
    final selectedSuggestion = _thanksSuggestions(tester).first;
    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is ThanksItemSuggested &&
              widget.inputText == selectedSuggestion,
        ),
        matching: find.byType(SuggestionAddButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(testUser.thanks['thanks'], contains(selectedSuggestion));
    expect(tester.takeException(), isNull);
  });

  testWidgets('skips malformed gratitude dates without failing Home', (
    tester,
  ) async {
    final now = DateTime.now();
    final testUser = user(
      thanks: {
        'thanks': ['today', 'corrupt'],
        'dates': [_date(now, '09:00'), 'bad'],
      },
    );

    await _pumpListWidget(
      tester,
      user: testUser,
      pageCode: PagesCode.GratitudeJournal,
    );

    final rows = tester
        .widgetList<MainpageListItemWidget>(find.byType(MainpageListItemWidget))
        .toList();
    expect(rows.map((row) => row.item), ['today']);
    expect(_thanksSuggestions(tester), hasLength(3));
    final selectedSuggestion = _thanksSuggestions(tester).first;
    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is ThanksItemSuggested &&
              widget.inputText == selectedSuggestion,
        ),
        matching: find.byType(SuggestionAddButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(testUser.thanks['thanks'], contains(selectedSuggestion));
    expect(tester.takeException(), isNull);
  });
}
