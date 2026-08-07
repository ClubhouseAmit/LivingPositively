// Widget tests for the REAL Journal page in lib/pages/journal.dart.
//
// Replaces the previous test which loaded a sibling stub `journal.dart`
// that fabricated its own widget tree, ignored the production AddForm /
// ThankYou widgets, and bypassed Provider entirely.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/journal.dart';
import 'package:mazilon/pages/thankYou.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

const _suggestions = [
  'Be grateful for sunshine',
  'Be grateful for friends',
  'Be grateful for food',
  'Be grateful for health',
  'Be grateful for family',
];

const _scrollToBottomKey = Key('journal-scroll-to-bottom');
const _journalScrollViewKey = Key('journal-scroll-view');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServiceLocators services;
  late UserInformation userInformation;

  setUp(() {
    services = registerTestServices(locale: 'en');
    userInformation = UserInformation();
    userInformation.gender = 'other';
    userInformation.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  group('Journal (real production widget)', () {
    testWidgets('renders empty journal with suggestions and add icon', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );

      expect(find.byType(Journal), findsOneWidget);
      expect(find.byType(ThankYou), findsNothing);
      // Production journal renders three ThanksItemSuggested widgets.
      expect(find.byType(ThanksItemSuggested), findsNWidgets(3));
      // The add icon (IconButton with Icons.add) should be visible.
      expect(find.byIcon(Icons.add), findsWidgets);
      expect(find.byKey(_scrollToBottomKey), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_double_arrow_down), findsOneWidget);
      expect(find.byTooltip('Scroll to bottom'), findsOneWidget);
    });

    testWidgets('quick scroll moves the journal to the bottom', (tester) async {
      final longThanks = List<String>.generate(
        20,
        (index) => 'Gratitude entry ${index + 1}',
      );
      userInformation.updateThanks({
        'thanks': longThanks,
        'dates': List<String>.generate(
          longThanks.length,
          (index) => '2024-01-01 – ${index.toString().padLeft(2, '0')}:00',
        ),
      });

      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        designSize: const Size(1024, 700),
        surfaceSize: const Size(1024, 700),
      );

      final journalScrollable = find.ancestor(
        of: find.byKey(_scrollToBottomKey),
        matching: find.byType(Scrollable),
      );
      expect(journalScrollable, findsOneWidget);
      final position = tester
          .state<ScrollableState>(journalScrollable)
          .position;
      expect(position.pixels, 0);
      expect(position.maxScrollExtent, greaterThan(0));

      await tester.tap(find.byKey(_scrollToBottomKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(position.extentAfter, closeTo(0, 0.1));
    });

    testWidgets('rapid quick-scroll taps keep the newest scroll active', (
      tester,
    ) async {
      final longThanks = List<String>.generate(
        20,
        (index) => 'Gratitude entry ${index + 1}',
      );
      userInformation.updateThanks({
        'thanks': longThanks,
        'dates': List<String>.generate(
          longThanks.length,
          (index) => '2024-01-01 – ${index.toString().padLeft(2, '0')}:00',
        ),
      });

      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        designSize: const Size(1024, 700),
        surfaceSize: const Size(1024, 700),
      );

      final journalScrollable = find.ancestor(
        of: find.byKey(_scrollToBottomKey),
        matching: find.byType(Scrollable),
      );
      final position = tester
          .state<ScrollableState>(journalScrollable)
          .position;

      // The header leaves the hit-test area as soon as the first activation
      // starts scrolling. Invoke the callback captured from the real button
      // twice at the same fake timestamp to model rapid activations without a
      // missed second tap.
      final onPressed = tester
          .widget<IconButton>(find.byKey(_scrollToBottomKey))
          .onPressed!;
      onPressed();
      onPressed();
      await tester.pump();
      // Give a cancelled first request a frame to reach its continuation.
      await tester.pump();

      expect(position.isScrollingNotifier.value, isTrue);
      expect(position.pixels, lessThan(position.maxScrollExtent));

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(position.pixels, closeTo(position.maxScrollExtent, 0.1));
      expect(position.extentAfter, closeTo(0, 0.1));
      expect(position.isScrollingNotifier.value, isFalse);
      expect(position.outOfRange, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('manual scrolling interrupts quick-scroll reconciliation', (
      tester,
    ) async {
      final longThanks = List<String>.generate(
        20,
        (index) => 'Gratitude entry ${index + 1}',
      );
      userInformation.updateThanks({
        'thanks': longThanks,
        'dates': List<String>.generate(
          longThanks.length,
          (index) => '2024-01-01 – ${index.toString().padLeft(2, '0')}:00',
        ),
      });

      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        designSize: const Size(1024, 700),
        surfaceSize: const Size(1024, 700),
      );

      final journalScrollable = find.ancestor(
        of: find.byKey(_scrollToBottomKey),
        matching: find.byType(Scrollable),
      );
      final position = tester
          .state<ScrollableState>(journalScrollable)
          .position;

      await tester.tap(find.byKey(_scrollToBottomKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Keep the drag in the post-animation reconciliation window while
      // avoiding stale shrink-wrap geometry from a previous frame.
      position.jumpTo(position.maxScrollExtent);
      await tester.timedDrag(
        find.byKey(_journalScrollViewKey),
        const Offset(0, 200),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      final manualPixels = position.pixels;
      expect(manualPixels, greaterThan(0));
      expect(manualPixels, lessThan(position.maxScrollExtent));

      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(position.pixels, closeTo(manualPixels, 0.1));
      expect(position.pixels, lessThan(position.maxScrollExtent));
      expect(tester.takeException(), isNull);
    });

    testWidgets('quick scroll catches up after journal content grows', (
      tester,
    ) async {
      final initialThanks = List<String>.generate(
        20,
        (index) =>
            'Gratitude entry ${index + 1}\nSecond line\nThird line\nFourth line',
      );

      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        designSize: const Size(1024, 700),
        surfaceSize: const Size(1024, 700),
      );

      userInformation.updateThanks({
        'thanks': initialThanks,
        'dates': List<String>.generate(
          initialThanks.length,
          (index) => '2024-01-01 – ${index.toString().padLeft(2, '0')}:00',
        ),
      });
      await tester.pump();
      await tester.pump();

      final journalScrollable = find.ancestor(
        of: find.byKey(_scrollToBottomKey),
        matching: find.byType(Scrollable),
      );
      final position = tester
          .state<ScrollableState>(journalScrollable)
          .position;
      final journalScrollableBox = tester.renderObject<RenderBox>(
        journalScrollable,
      );

      await tester.tap(find.byKey(_scrollToBottomKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(position.isScrollingNotifier.value, isTrue);

      final updatedThanks = [
        ...initialThanks,
        ...List<String>.generate(
          20,
          (index) =>
              'New gratitude row ${index + 1}\nSecond line\nThird line\nFourth line',
        ),
      ];
      userInformation.updateThanks({
        'thanks': updatedThanks,
        'dates': List<String>.generate(
          updatedThanks.length,
          (index) => '2024-01-01 – ${index.toString().padLeft(2, '0')}:00',
        ),
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(userInformation.thanks['thanks'], hasLength(40));
      expect(
        userInformation.thanks['thanks'],
        contains('New gratitude row 20\nSecond line\nThird line\nFourth line'),
      );

      expect(position.pixels, closeTo(position.maxScrollExtent, 0.1));
      expect(position.extentAfter, closeTo(0, 0.1));
      expect(position.outOfRange, isFalse);
      final journalViewport =
          journalScrollableBox.localToGlobal(Offset.zero) &
          journalScrollableBox.size;
      final refreshIcon = find.byIcon(Icons.refresh);
      expect(refreshIcon, findsOneWidget);
      expect(journalViewport.contains(tester.getCenter(refreshIcon)), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('quick scroll is a no-op when already at the bottom', (
      tester,
    ) async {
      final longThanks = List<String>.generate(
        20,
        (index) => 'Gratitude entry ${index + 1}',
      );
      userInformation.updateThanks({
        'thanks': longThanks,
        'dates': List<String>.generate(
          longThanks.length,
          (index) => '2024-01-01 – ${index.toString().padLeft(2, '0')}:00',
        ),
      });

      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        designSize: const Size(1024, 700),
        surfaceSize: const Size(1024, 700),
      );

      final journalScrollable = find.ancestor(
        of: find.byKey(_scrollToBottomKey),
        matching: find.byType(Scrollable),
      );
      final position = tester
          .state<ScrollableState>(journalScrollable)
          .position;
      final scrollButton = tester.widget<IconButton>(
        find.byKey(_scrollToBottomKey),
      );

      await tester.tap(find.byKey(_scrollToBottomKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      final bottomPixels = position.pixels;
      final bottomMaxScrollExtent = position.maxScrollExtent;

      // The header is evicted once the outer list reaches the bottom, so this
      // invokes the same button callback captured before the first user tap.
      scrollButton.onPressed!();
      await tester.pump();

      expect(position.pixels, closeTo(bottomPixels, 0.1));
      expect(position.pixels, closeTo(bottomMaxScrollExtent, 0.1));
      expect(position.extentAfter, closeTo(0, 0.1));
      expect(position.isScrollingNotifier.value, isFalse);
      expect(position.outOfRange, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('quick scroll is safe when the journal does not overflow', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        designSize: const Size(1024, 1800),
        surfaceSize: const Size(1024, 1800),
      );

      final journalScrollable = find.ancestor(
        of: find.byKey(_scrollToBottomKey),
        matching: find.byType(Scrollable),
      );
      expect(journalScrollable, findsOneWidget);
      final position = tester
          .state<ScrollableState>(journalScrollable)
          .position;
      expect(position.maxScrollExtent, 0);

      await tester.tap(find.byKey(_scrollToBottomKey));
      await tester.pump();

      expect(position.pixels, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('quick scroll remains usable in the Hebrew journal layout', (
      tester,
    ) async {
      userInformation.localeName = 'he';
      services.localeService.setLocale('he');
      final longThanks = List<String>.generate(
        20,
        (index) => 'רשומת תודה ${index + 1}',
      );
      userInformation.updateThanks({
        'thanks': longThanks,
        'dates': List<String>.generate(
          longThanks.length,
          (index) => '2024-01-01 – ${index.toString().padLeft(2, '0')}:00',
        ),
      });

      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        locale: const Locale('he'),
        designSize: const Size(1024, 700),
        surfaceSize: const Size(1024, 700),
      );

      final scrollButton = find.byKey(_scrollToBottomKey);
      final addButton = find
          .ancestor(
            of: find.byIcon(Icons.add),
            matching: find.byType(IconButton),
          )
          .first;

      expect(find.byTooltip('גלילה לסוף הרשימה'), findsOneWidget);
      expect(
        Directionality.of(tester.element(scrollButton)),
        TextDirection.rtl,
      );
      expect(
        tester.getCenter(scrollButton).dx,
        closeTo(tester.getCenter(addButton).dx, 0.1),
      );
      expect(
        tester.getCenter(scrollButton).dy,
        greaterThan(tester.getCenter(addButton).dy),
      );

      final journalScrollable = find.ancestor(
        of: scrollButton,
        matching: find.byType(Scrollable),
      );
      final position = tester
          .state<ScrollableState>(journalScrollable)
          .position;
      expect(position.maxScrollExtent, greaterThan(0));

      await tester.tap(scrollButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(position.extentAfter, closeTo(0, 0.1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('refresh button rebuilds suggestion text', (tester) async {
      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );

      // The refresh button is the row containing the refresh icon.
      final refreshIcon = find.byIcon(Icons.refresh);
      expect(refreshIcon, findsOneWidget);
      await tester.ensureVisible(refreshIcon);
      final refreshButton = find.ancestor(
        of: refreshIcon,
        matching: find.byType(TextButton),
      );
      await tester.tap(refreshButton, warnIfMissed: false);
      await tester.pump();
      // After tapping, the journal should still have its three suggestion
      // widgets (no crash, sug1/sug2/sug3 reshuffled).
      expect(find.byType(ThanksItemSuggested), findsNWidgets(3));
    });

    testWidgets(skip: true, 'add button opens AddForm dialog', (tester) async {
      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );

      // Tap the page-level add icon (the IconButton wrapping Icons.add).
      final addIcon = find.descendant(
        of: find.byType(Journal),
        matching: find.byIcon(Icons.add),
      );
      // Multiple add icons exist (page + suggestion add buttons). The
      // page-level one is inside an IconButton; tap that.
      final pageAddButton = find
          .ancestor(of: addIcon, matching: find.byType(IconButton))
          .first;
      await tester.ensureVisible(pageAddButton);
      await tester.tap(pageAddButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // AddForm appears as a dialog.
      expect(find.byType(AddForm), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('typing in AddForm + Save adds an entry to the journal', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        designSize: const Size(1024, 1800),
        surfaceSize: const Size(1024, 1800),
      );

      // Open the dialog.
      final addIcon = find.descendant(
        of: find.byType(Journal),
        matching: find.byIcon(Icons.add),
      );
      final pageAddButton = find
          .ancestor(of: addIcon, matching: find.byType(IconButton))
          .first;
      await tester.ensureVisible(pageAddButton);
      await tester.tap(pageAddButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Enter text and tap Save.
      await tester.enterText(find.byType(TextFormField), 'Tested entry');
      await tester.pump();
      // The save button is rendered with localized "Save" text.
      final saveButton = find.ancestor(
        of: find.text('Save'),
        matching: find.byType(TextButton),
      );
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // The dialog should have been dismissed and the new entry appended.
      expect(find.byType(AddForm), findsNothing);
      expect(userInformation.thanks['thanks'], contains('Tested entry'));
      // The popup AlertDialog is shown for the first entry of the day.
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('AddForm Cancel closes the dialog without persisting', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        designSize: const Size(1024, 1800),
        surfaceSize: const Size(1024, 1800),
      );

      final addIcon = find.descendant(
        of: find.byType(Journal),
        matching: find.byIcon(Icons.add),
      );
      final pageAddButton = find
          .ancestor(of: addIcon, matching: find.byType(IconButton))
          .first;
      await tester.tap(pageAddButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Should not save');
      // Tap the Cancel button (localized "Cancel").
      final closeButton = find.ancestor(
        of: find.text('Cancel'),
        matching: find.byType(TextButton),
      );
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(AddForm), findsNothing);
      expect(
        userInformation.thanks['thanks'],
        isNot(contains('Should not save')),
      );
    });

    testWidgets('existing thanks render as ThankYou rows', (tester) async {
      userInformation.updateThanks({
        'thanks': ['Thank A', 'Thank B'],
        'dates': ['2024-01-01 – 09:00', '2024-01-01 – 10:00'],
      });

      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );

      expect(find.byType(ThankYou), findsNWidgets(2));
      expect(find.text('Thank A'), findsOneWidget);
      expect(find.text('Thank B'), findsOneWidget);
    });

    testWidgets(skip: true, 'AddForm validator blocks empty text', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );

      // Open AddForm.
      final addIcon = find.descendant(
        of: find.byType(Journal),
        matching: find.byIcon(Icons.add),
      );
      final pageAddButton = find
          .ancestor(of: addIcon, matching: find.byType(IconButton))
          .first;
      await tester.tap(pageAddButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap Save without typing — validator should fail and dialog stays.
      final saveButton = find.ancestor(
        of: find.text('Save'),
        matching: find.byType(TextButton),
      );
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pump();

      expect(find.byType(AddForm), findsOneWidget);
    });

    testWidgets(skip: true, 'analytics event fires when entry added', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const Journal(fullSuggestionList: _suggestions),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );

      // Open dialog and submit.
      final addIcon = find.descendant(
        of: find.byType(Journal),
        matching: find.byIcon(Icons.add),
      );
      final pageAddButton = find
          .ancestor(of: addIcon, matching: find.byType(IconButton))
          .first;
      await tester.tap(pageAddButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'analytics test');
      await tester.tap(
        find.ancestor(of: find.text('Save'), matching: find.byType(TextButton)),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(
        services.analytics.events
            .map((e) => e.key)
            .contains('Item added to Gratitude Journal'),
        isTrue,
      );
    });
  });
}
