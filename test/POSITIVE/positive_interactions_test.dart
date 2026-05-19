// Interaction tests for the REAL Positive page that drive the
// add/remove/edit code paths (lines 89-123 + 160-173 of lib/pages/positive.dart).
//
// addPositiveTrait is invoked via tapping the embedded PositiveTraitItemSug
// add button (the production widget composes it with the page's own
// `addPositiveTrait` closure). removePositiveTrait is invoked via the trash
// IconButton on a rendered ThankYou row. editNotification is invoked via the
// page-level add IconButton in the header.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/positive.dart';
import 'package:mazilon/pages/thankYou.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/Traits/positiveTraitItemSug.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

Future<void> _advancePastInitDelayAndDismiss(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 11));
  await tester.pump();
  final dialogButton = find.byType(TextButton);
  if (dialogButton.evaluate().isNotEmpty) {
    for (final element in dialogButton.evaluate()) {
      final ancestor = element.findAncestorWidgetOfExactType<AlertDialog>();
      if (ancestor != null) {
        await tester.tap(find.byWidget(element.widget), warnIfMissed: false);
        await tester.pumpAndSettle();
        break;
      }
    }
  }
  drainOverflowExceptions(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;
  late FakePersistentMemoryService memory;

  setUp(() {
    final s = registerTestServices(locale: 'en');
    memory = s.memory;
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets(
      'tapping a PositiveTraitItemSug add button appends to userInformation.positiveTraits',
      (tester) async {
    await memory.setItem(
      'positiveTraits',
      PersistentMemoryType.StringList,
      <String>[],
    );
    // userInformation.positiveTraits defaults to a const [] (unmodifiable);
    // initialise to a mutable list so the production addPositiveTrait can
    // append to it.
    user.updatePositiveTraits(<String>[]);

    await pumpWithProviders(
      tester,
      const Positive(),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );

    final firstSug = find.byType(PositiveTraitItemSug).first;
    final addGesture = find
        .descendant(of: firstSug, matching: find.byType(GestureDetector))
        .first;
    await tester.ensureVisible(addGesture);
    await tester.tap(addGesture, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(user.positiveTraits.length, greaterThanOrEqualTo(1));

    await _advancePastInitDelayAndDismiss(tester);
  });

  testWidgets(
      'tapping the delete icon on an existing ThankYou row removes a trait',
      (tester) async {
    user.updatePositiveTraits(['Kind', 'Brave']);
    await memory.setItem(
      'positiveTraits',
      PersistentMemoryType.StringList,
      <String>['Kind', 'Brave'],
    );

    await pumpWithProviders(
      tester,
      const Positive(),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );

    expect(find.byType(ThankYou), findsNWidgets(2));
    final trashIcon = find.byIcon(Icons.delete).first;
    final trashButton = find
        .ancestor(of: trashIcon, matching: find.byType(MaterialButton))
        .first;
    await tester.tap(trashButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(user.positiveTraits.length, 1);

    await _advancePastInitDelayAndDismiss(tester);
  });

  testWidgets(
      'tapping the page-level add icon opens an AddForm dialog (editNotification)',
      (tester) async {
    await pumpWithProviders(
      tester,
      const Positive(),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );

    // The header IconButton's Icons.add — first add icon found in the Positive
    // page subtree (suggestion add buttons are inside GestureDetectors, not
    // IconButtons, so this finds the page-level one).
    final pageAdd = find
        .descendant(
          of: find.byType(Positive),
          matching: find.byType(IconButton),
        )
        .first;
    await tester.ensureVisible(pageAdd);
    await tester.tap(pageAdd, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(AddForm), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);

    // The dialog routes via Provider, so the inner save handler captures
    // the UserInformation from the dialog's Provider context. We tap the
    // page-level IconButton to open the dialog — the dialog widget is now
    // mounted; mostly what matters is that we reached the editNotification
    // branch covering lines 160-173. The form save behaviour is already
    // covered exhaustively by test/Thanks/AddForm_real_test.dart, so this
    // test stops here: pressing Close pops the dialog and verifies the
    // editNotification path executed cleanly.
    final dialogButtons = find.descendant(
      of: find.byType(AddForm),
      matching: find.byType(TextButton),
    );
    // First TextButton is "Close".
    await tester.tap(dialogButtons.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(AddForm), findsNothing);

    await _advancePastInitDelayAndDismiss(tester);
  });

  testWidgets(
      'tapping the edit icon on an existing row opens a seeded AddForm',
      (tester) async {
    user.updatePositiveTraits(['Patient']);
    await memory.setItem(
      'positiveTraits',
      PersistentMemoryType.StringList,
      <String>['Patient'],
    );

    await pumpWithProviders(
      tester,
      const Positive(),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );

    final editIcon = find.byIcon(Icons.edit).first;
    final editButton = find
        .ancestor(of: editIcon, matching: find.byType(MaterialButton))
        .first;
    await tester.tap(editButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(AddForm), findsOneWidget);
    // The seeded text matches the existing trait — the form's edit path
    // (`AddForm._onSubmitForm` widget.text != '') is exhaustively covered in
    // test/Thanks/AddForm_real_test.dart. Here we just verify the dialog was
    // opened with the seeded text, exercising the editNotification path for
    // the row's edit icon.
    final tf = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(tf.controller?.text, 'Patient');
    final dialogButtons = find.descendant(
      of: find.byType(AddForm),
      matching: find.byType(TextButton),
    );
    await tester.tap(dialogButtons.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(AddForm), findsNothing);

    await _advancePastInitDelayAndDismiss(tester);
  });
}
