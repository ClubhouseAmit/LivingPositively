// Widget tests for the REAL FormAnswer in lib/pages/FormAnswer.dart.
//
// FormAnswer is a single-row template used by the personal-plan questionnaire
// to display, edit, or remove a user-prompt answer, matching the shared
// Figma onboarding template: a plain numbered row (no border/icons). It owns:
//   - the row layout (number label + auto-sized text, tap-to-edit)
//   - an `editAnswer` closure that pushes an `AddFormAnswer` dialog
//   - a swipe-to-delete `Dismissible` that confirms before invoking `remove`
//
// We assert structural render, tap routing, and that tapping the row opens
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

  testWidgets('renders the numbered row and label text, no icons', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      Scaffold(
        body: FormAnswer(
          text: 'Take a walk',
          edit: (_, _, _) {},
          remove: (_) {},
          num: 1,
        ),
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1200, 1800),
    );

    expect(find.byType(FormAnswer), findsOneWidget);
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Take a walk'), findsOneWidget);
    // The design has no persistent edit/delete icons on the row.
    expect(find.byIcon(Icons.circle), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
  });

  testWidgets('tapping the row opens the AddFormAnswer edit dialog', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      Scaffold(
        body: FormAnswer(
          text: 'Cleaning',
          edit: (_, _, _) {},
          remove: (_) {},
          num: 2,
        ),
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1200, 1800),
    );

    expect(find.byType(AddFormAnswer), findsNothing);
    await tester.tap(find.text('Cleaning'));
    await tester.pumpAndSettle();

    expect(find.byType(AddFormAnswer), findsOneWidget);
  });

  testWidgets('swipe to delete confirms before remove(num - 1)', (
    tester,
  ) async {
    int? removedIndex;
    await pumpWithProviders(
      tester,
      Scaffold(
        body: FormAnswer(
          text: 'Cleaning',
          edit: (_, _, _) {},
          remove: (int i) => removedIndex = i,
          num: 3,
        ),
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1200, 1800),
    );

    await tester.drag(find.byType(Dismissible), const Offset(-1100, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete this answer?'), findsOneWidget);
    expect(removedIndex, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(removedIndex, isNull);

    await tester.drag(find.byType(Dismissible), const Offset(-1100, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(removedIndex, 2, reason: 'remove must be called with num - 1');
  });
}
