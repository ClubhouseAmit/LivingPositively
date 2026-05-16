// Widget tests for the REAL FormAnswer in lib/pages/FormAnswer.dart.
//
// FormAnswer is a single-row template used by the personal-plan questionnaire
// to display, edit, or remove a user-prompt answer. It owns:
//   - the row layout (bullet icon + auto-sized text + edit/delete buttons)
//   - an `editAnswer` closure that pushes an `AddFormAnswer` dialog
//   - a `remove` callback that invokes the supplied `widget.remove(num - 1)`
//
// We assert structural render, tap routing, and that the edit button opens
// the dialog (we don't drive the dialog itself — covered separately).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/FormAnswer.dart';
import 'package:mazilon/util/FormAnswer/addFormAnswer.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation userInformation;

  setUp(() {
    registerTestServices(locale: 'en');
    userInformation = UserInformation();
    userInformation.gender = 'other';
    userInformation.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('renders bullet icon, edit + delete buttons, and label text',
      (tester) async {
    await pumpWithProviders(
      tester,
      FormAnswer(
        text: 'Take a walk',
        edit: (_, __, ___) {},
        remove: (_) {},
        num: 1,
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1200, 1800),
    );

    expect(find.byType(FormAnswer), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    // Two TextButtons: edit + delete.
    expect(find.byType(TextButton), findsNWidgets(2));
    expect(find.text('Take a walk'), findsOneWidget);
  });

  testWidgets('tap delete button calls widget.remove(num - 1)', (tester) async {
    int? removedIndex;
    await pumpWithProviders(
      tester,
      FormAnswer(
        text: 'Cleaning',
        edit: (_, __, ___) {},
        remove: (int i) => removedIndex = i,
        num: 3,
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1200, 1800),
    );

    final deleteButton = find.ancestor(
      of: find.byIcon(Icons.delete),
      matching: find.byType(TextButton),
    );
    await tester.tap(deleteButton, warnIfMissed: false);
    await tester.pump();

    expect(removedIndex, 2, reason: 'remove must be called with num - 1');
  });

  testWidgets('tap edit button opens AddFormAnswer dialog', (tester) async {
    await pumpWithProviders(
      tester,
      FormAnswer(
        text: 'Cleaning',
        edit: (_, __, ___) {},
        remove: (_) {},
        num: 2,
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1200, 1800),
    );

    expect(find.byType(AddFormAnswer), findsNothing);
    final editButton = find.ancestor(
      of: find.byIcon(Icons.edit),
      matching: find.byType(TextButton),
    );
    await tester.tap(editButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    // The edit closure does showDialog of AddFormAnswer.
    expect(find.byType(AddFormAnswer), findsOneWidget);
  });
}
