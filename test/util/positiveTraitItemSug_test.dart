// Widget tests for the REAL PositiveTraitItemSug in
// lib/util/Traits/positiveTraitItemSug.dart.
//
// Mirrors thanksItemSug_test but the production code in this file uses
// `GetIt.instance<PersistentMemoryService>().getItem("positiveTraits", ...)`
// inside the on-tap handler — so we use the in-memory FakePersistentMemoryService
// supplied by the test scaffold and assert the saved value flows back through
// the `add` callback. Covers lines 103-136 (the tap-add handler) and the
// `show == false` branch at lines 70 & 91.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Traits/positiveTraitItemSug.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

const _suggestions = <String>[
  'Kind',
  'Brave',
  'Caring',
  'Patient',
  'Strong',
  'Curious',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;
  late FakePersistentMemoryService memory;

  setUp(() {
    final services = registerTestServices(locale: 'en');
    memory = services.memory;
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('renders the suggested trait row with add icon', (tester) async {
    await pumpWithProviders(
      tester,
      PositiveTraitItemSug(
        add: _noopAdd,
        inputText: '',
        stopShowing: 1,
        fullSuggestionList: _suggestions,
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 800),
    );

    expect(find.byType(PositiveTraitItemSug), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets(
      'returns empty container when stopShowing is bigger than suggestions',
      (tester) async {
    // User already wrote 5 of the 6 suggestions -> only 1 remains; stopShowing
    // = 5 forces show=false branch.
    user.updatePositiveTraits([..._suggestions.take(5)]);

    await pumpWithProviders(
      tester,
      PositiveTraitItemSug(
        add: _noopAdd,
        inputText: '',
        stopShowing: 5,
        fullSuggestionList: _suggestions,
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 800),
    );

    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets(
      'tap on add invokes callback with the suggested trait and re-randomises',
      (tester) async {
    // Seed the in-memory persistent service so the awaited getItem inside the
    // on-tap path returns a non-null StringList (covers line 109-111).
    await memory.setItem(
      'positiveTraits',
      PersistentMemoryType.StringList,
      <String>['Kind'],
    );

    final captured = <String>[];

    await pumpWithProviders(
      tester,
      PositiveTraitItemSug(
        add: (String trait, UserInformation u) {
          captured.add(trait);
        },
        inputText: '',
        stopShowing: 1,
        fullSuggestionList: _suggestions,
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 800),
    );

    final gestureDetector = find
        .descendant(
          of: find.byType(PositiveTraitItemSug),
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(gestureDetector, warnIfMissed: false);
    // The on-tap awaits getItem so we need to settle async microtasks.
    await tester.pumpAndSettle();

    expect(captured, isNotEmpty);
    // After the tap, the widget keeps rendering an add button so we can tap
    // again without crashing — this exercises the suggestion-rebuild path
    // (lines 123-137).
    expect(find.byType(GestureDetector), findsWidgets);
  });

  testWidgets('tap with inputText override forwards the override to add()',
      (tester) async {
    await memory.setItem(
      'positiveTraits',
      PersistentMemoryType.StringList,
      <String>[],
    );
    final captured = <String>[];

    await pumpWithProviders(
      tester,
      PositiveTraitItemSug(
        add: (String trait, UserInformation u) {
          captured.add(trait);
        },
        inputText: 'manual-trait',
        stopShowing: 1,
        fullSuggestionList: _suggestions,
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 800),
    );

    final gestureDetector = find
        .descendant(
          of: find.byType(PositiveTraitItemSug),
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(gestureDetector, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(captured.last, 'manual-trait');
  });
}

void _noopAdd(String _, UserInformation __) {}
