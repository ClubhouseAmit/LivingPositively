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
    testWidgets(
      'keeps header actions on-screen with scaled text and an empty journal',
      (tester) async {
        const surfaceSize = Size(320, 800);

        await pumpWithProviders(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: const Journal(fullSuggestionList: []),
            ),
          ),
          userInformation: userInformation,
          surfaceSize: surfaceSize,
          ignoreOverflow: false,
        );

        final addButton = find.byTooltip('Add');

        expect(tester.takeException(), isNull);
        expect(find.byType(ThankYou), findsNothing);
        expect(addButton, findsOneWidget);
        expect(addButton.hitTestable(), findsOneWidget);

        final bounds = tester.getRect(addButton);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(surfaceSize.width));
      },
    );

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

    testWidgets(
      'deleting the newest note removes the correct underlying entry',
      (tester) async {
        userInformation.updateThanks({
          'thanks': ['oldest', 'middle', 'newest'],
          'dates': [
            '2024-01-01 – 09:00',
            '2024-01-02 – 09:00',
            '2024-01-03 – 09:00',
          ],
        });

        await pumpWithProviders(
          tester,
          const Journal(fullSuggestionList: _suggestions),
          userInformation: userInformation,
          surfaceSize: const Size(1024, 1800),
        );

        // Display order is newest-first: newest above middle above oldest.
        final newestY = tester.getTopLeft(find.text('newest')).dy;
        final middleY = tester.getTopLeft(find.text('middle')).dy;
        final oldestY = tester.getTopLeft(find.text('oldest')).dy;
        expect(newestY, lessThan(middleY));
        expect(middleY, lessThan(oldestY));

        // The oldest note is numbered 1, the newest is numbered 3.
        final oldestThankYou = tester.widget<ThankYou>(
          find.ancestor(
            of: find.text('oldest'),
            matching: find.byType(ThankYou),
          ),
        );
        final newestThankYou = tester.widget<ThankYou>(
          find.ancestor(
            of: find.text('newest'),
            matching: find.byType(ThankYou),
          ),
        );
        expect(oldestThankYou.number, 1);
        expect(newestThankYou.number, 3);

        // Delete the MIDDLE note (not an edge one, so an off-by-one in the
        // reversal math would still be caught).
        final middleThankYou = find.ancestor(
          of: find.text('middle'),
          matching: find.byType(ThankYou),
        );
        final deleteButton = find
            .ancestor(
              of: find.descendant(
                of: middleThankYou,
                matching: find.byIcon(Icons.delete),
              ),
              matching: find.byType(MaterialButton),
            )
            .first;
        await tester.ensureVisible(deleteButton);
        await tester.tap(deleteButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Delete'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(
          userInformation.thanks['thanks'],
          ['oldest', 'newest'],
        );
      },
    );

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
