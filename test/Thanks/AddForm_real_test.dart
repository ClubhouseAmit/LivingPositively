// Widget tests for the REAL AddForm in lib/util/Thanks/AddForm.dart.
//
// The dialog widget owns a TextFormField + form validation, and routes
// submission through one of two callbacks (`add` for new entries when
// `widget.text` is empty, `edit` when seeded with existing text). It pops
// the surrounding Navigator on a successful submit. We exercise:
//   - render in an empty/new state (no seeded text) and a seeded/edit state
//   - validator branch: empty submit blocks and does not call add/edit/pop
//   - happy path: non-empty submit fires `add` (new) and `edit` (seeded)
//     and pops the dialog
//   - close button pops the dialog without firing either callback
//
// The widget itself is meant to be shown via `showDialog`; we pump a
// MaterialApp + Scaffold with a "open" button that calls showDialog so we
// have a real Navigator/dialog context for `Navigator.of(context).pop()`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Thanks/AddForm.dart' as real;
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

Future<void> _openDialog(WidgetTester tester, Widget dialog) async {
  await pumpWithProviders(
    tester,
    Builder(
      builder: (ctx) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDialog(context: ctx, builder: (_) => dialog),
              child: const Text('open'),
            ),
          ),
        );
      },
    ),
    surfaceSize: const Size(1200, 1800),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerTestServices(locale: 'en');
  });

  tearDown(() {
    resetTestServices();
  });

  group('AddForm (real production widget)', () {
    testWidgets('renders Dialog with TextFormField + close/save buttons', (
      tester,
    ) async {
      await _openDialog(
        tester,
        real.AddForm(
          add: (_, _) {},
          edit: (_, _, _) {},
          index: 0,
          text: '',
          formTitle: 'Trait',
        ),
      );

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      // Two TextButtons: close + save.
      expect(find.byType(TextButton), findsNWidgets(2));
    });

    testWidgets('seeds TextFormField controller with widget.text', (
      tester,
    ) async {
      await _openDialog(
        tester,
        real.AddForm(
          add: (_, _) {},
          edit: (_, _, _) {},
          index: 2,
          text: 'Existing trait',
          formTitle: 'Trait',
        ),
      );

      final tf = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(tf.controller?.text, 'Existing trait');
    });

    testWidgets('empty submit triggers validator and does not pop', (
      tester,
    ) async {
      var addCalls = 0;
      var editCalls = 0;
      await _openDialog(
        tester,
        real.AddForm(
          add: (_, _) => addCalls++,
          edit: (_, _, _) => editCalls++,
          index: 0,
          text: '',
          formTitle: 'Trait',
        ),
      );

      // Submit empty text via onFieldSubmitted (Enter).
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Validator must have blocked submission and the dialog stays open.
      expect(find.byType(Dialog), findsOneWidget);
      expect(addCalls, 0);
      expect(editCalls, 0);
    });

    testWidgets('non-empty submit on a NEW entry fires add() and pops', (
      tester,
    ) async {
      var addCalls = 0;
      var editCalls = 0;
      UserInformation? capturedUser;
      String? capturedText;

      await _openDialog(
        tester,
        real.AddForm(
          add: (String t, UserInformation u) {
            addCalls++;
            capturedText = t;
            capturedUser = u;
          },
          edit: (_, _, _) => editCalls++,
          index: 0,
          text: '',
          formTitle: 'Trait',
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Brave');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Dialog should have popped.
      expect(find.byType(Dialog), findsNothing);
      expect(addCalls, 1);
      expect(editCalls, 0);
      expect(capturedText, 'Brave');
      expect(capturedUser, isNotNull);
    });

    testWidgets('non-empty submit on a SEEDED entry fires edit() and pops', (
      tester,
    ) async {
      var addCalls = 0;
      var editCalls = 0;
      int? capturedIndex;
      String? capturedText;

      await _openDialog(
        tester,
        real.AddForm(
          add: (_, _) => addCalls++,
          edit: (String t, int i, UserInformation u) {
            editCalls++;
            capturedText = t;
            capturedIndex = i;
          },
          index: 4,
          text: 'Existing',
          formTitle: 'Trait',
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Updated');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(editCalls, 1);
      expect(addCalls, 0);
      expect(capturedText, 'Updated');
      expect(capturedIndex, 4);
    });

    testWidgets(
      'tap save button (not Enter) routes through onPressed → submit',
      (tester) async {
        var addCalls = 0;
        await _openDialog(
          tester,
          real.AddForm(
            add: (_, _) => addCalls++,
            edit: (_, _, _) {},
            index: 0,
            text: '',
            formTitle: 'Trait',
          ),
        );
        await tester.enterText(find.byType(TextFormField), 'Calm');
        // The "save" button is the second TextButton — first is close.
        final buttons = find.byType(TextButton);
        await tester.tap(buttons.last, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(addCalls, 1);
        expect(find.byType(Dialog), findsNothing);
      },
    );

    testWidgets('tap close button pops without firing add/edit', (
      tester,
    ) async {
      var addCalls = 0;
      var editCalls = 0;
      await _openDialog(
        tester,
        real.AddForm(
          add: (_, _) => addCalls++,
          edit: (_, _, _) => editCalls++,
          index: 0,
          text: 'Something',
          formTitle: 'Trait',
        ),
      );
      // First TextButton == close.
      final buttons = find.byType(TextButton);
      await tester.tap(buttons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(addCalls, 0);
      expect(editCalls, 0);
    });
  });
}
