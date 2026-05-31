// Widget tests for the REAL ThanksItemSuggested in
// lib/util/Thanks/thanksItemSug.dart.
//
// The widget renders a single suggested thank-you with a dotted-border add
// button (GestureDetector). The on-tap path invokes the [add] callback, then
// reshuffles its internal `thanksSuggestionList` to pull a new random
// suggestion. We exercise:
//   - normal render when `stopShowing` is not blocking
//   - the `show == false` branch when stopShowing > remaining suggestions
//   - the tap-add path: callback fires, suggestion list is rebuilt without
//     crashing
//   - `inputText` override: when non-empty, the widget always uses widget
//     `.inputText` (covers the ternary branch at lines 113/119)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

const _suggestions = <String>[
  'Sun',
  'Rain',
  'Friends',
  'Family',
  'Food',
  'Books',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('renders suggestion row with add button when show is true', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      const ThanksItemSuggested(
        add: _noopAdd,
        inputText: '',
        stopShowing: 1,
        fullSuggestionList: _suggestions,
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 800),
    );

    expect(find.byType(ThanksItemSuggested), findsOneWidget);
    expect(find.byType(GestureDetector), findsWidgets);
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets('renders empty container when show=false branch', (tester) async {
    // stopShowing larger than the suggestion list AFTER removing entries
    // already-thanked today forces _show = false (lines 75-77 + 99).
    user.updateThanks({
      'thanks': [..._suggestions],
      'dates': List<String>.generate(_suggestions.length, (_) => _todayDate()),
    });

    await pumpWithProviders(
      tester,
      const ThanksItemSuggested(
        add: _noopAdd,
        inputText: '',
        stopShowing: 10,
        fullSuggestionList: _suggestions,
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 800),
    );

    // When show=false the build returns an empty Container() — no
    // GestureDetector / AutoSizeText is rendered for the add button row.
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets(
    'tap on add button invokes add() and rebuilds the suggestion text',
    (tester) async {
      final captured = <String>[];

      await pumpWithProviders(
        tester,
        ThanksItemSuggested(
          add: (String suggestion, UserInformation u) {
            captured.add(suggestion);
          },
          inputText: '',
          stopShowing: 1,
          fullSuggestionList: _suggestions,
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 800),
      );

      // Two GestureDetectors render — the outer one for the dotted-border
      // add button is the first GestureDetector child of the ThanksItemSuggested.
      final gestureDetector = find
          .descendant(
            of: find.byType(ThanksItemSuggested),
            matching: find.byType(GestureDetector),
          )
          .first;
      await tester.tap(gestureDetector, warnIfMissed: false);
      await tester.pump();

      expect(captured, isNotEmpty);
      // After tap the widget rebuilds; the GestureDetector still exists.
      expect(find.byType(GestureDetector), findsWidgets);
    },
  );

  testWidgets(
    'tap with inputText override passes the override into add() callback',
    (tester) async {
      final captured = <String>[];

      await pumpWithProviders(
        tester,
        ThanksItemSuggested(
          add: (String suggestion, UserInformation u) {
            captured.add(suggestion);
          },
          inputText: 'override-text',
          stopShowing: 1,
          fullSuggestionList: _suggestions,
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 800),
      );

      final gestureDetector = find
          .descendant(
            of: find.byType(ThanksItemSuggested),
            matching: find.byType(GestureDetector),
          )
          .first;
      await tester.tap(gestureDetector, warnIfMissed: false);
      await tester.pump();

      expect(captured.last, 'override-text');
    },
  );
}

void _noopAdd(String _, UserInformation _) {}

String _todayDate() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d – 09:00';
}
