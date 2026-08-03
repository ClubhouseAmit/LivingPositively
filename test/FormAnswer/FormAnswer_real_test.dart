// Widget tests for the REAL FormAnswer in lib/pages/FormAnswer.dart.
//
// FormAnswer is a single-row template used by the personal-plan questionnaire
// to display, edit, or remove a user-prompt answer. It owns:
//   - the row layout (bullet icon + auto-sized text + edit/delete buttons)
//   - an `editAnswer` closure that pushes an `AddFormAnswer` dialog
//   - a `remove` callback that invokes the supplied remove function
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
    registerTestServices();
    userInformation = UserInformation();
    userInformation.gender = 'other';
    userInformation.localeName = 'en';
  });

  tearDown(resetTestServices);

  testWidgets('renders bullet icon, edit + delete buttons, and label text', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      FormAnswer(
        text: 'Take a walk',
        edit: (_, _, _) {},
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

  testWidgets('tap delete button confirms before remove(num - 1)', (
    tester,
  ) async {
    int? removedIndex;
    await pumpWithProviders(
      tester,
      FormAnswer(
        text: 'Cleaning',
        edit: (_, _, _) {},
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
    await tester.pumpAndSettle();

    expect(find.text('Delete this answer?'), findsOneWidget);
    expect(removedIndex, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(removedIndex, isNull);

    await tester.tap(deleteButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(removedIndex, 2, reason: 'remove must be called with num - 1');
  });

  testWidgets('delete confirmation removes the originally tapped answer', (
    tester,
  ) async {
    final rowNumber = ValueNotifier<int>(3);
    addTearDown(rowNumber.dispose);
    int? removedIndex;

    await pumpWithProviders(
      tester,
      _MutableFormAnswerHost(
        rowNumber: rowNumber,
        remove: (index) => removedIndex = index,
      ),
      userInformation: userInformation,
      surfaceSize: const Size(1200, 1800),
    );

    final deleteButton = find.ancestor(
      of: find.byIcon(Icons.delete),
      matching: find.byType(TextButton),
    );
    await tester.tap(deleteButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    rowNumber.value = 9;
    await tester.pump();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(removedIndex, 2);
  });

  testWidgets('tap edit button opens AddFormAnswer dialog', (tester) async {
    await pumpWithProviders(
      tester,
      FormAnswer(text: 'Cleaning', edit: (_, _, _) {}, remove: (_) {}, num: 2),
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

class _MutableFormAnswerHost extends StatefulWidget {

  const _MutableFormAnswerHost({required this.rowNumber, required this.remove});
  final ValueNotifier<int> rowNumber;
  final void Function(int index) remove;

  @override
  State<_MutableFormAnswerHost> createState() => _MutableFormAnswerHostState();
}

class _MutableFormAnswerHostState extends State<_MutableFormAnswerHost> {
  @override
  void initState() {
    super.initState();
    widget.rowNumber.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(_MutableFormAnswerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rowNumber != widget.rowNumber) {
      oldWidget.rowNumber.removeListener(_rebuild);
      widget.rowNumber.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.rowNumber.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FormAnswer(
      text: 'Cleaning',
      edit: (_, _, _) {},
      remove: widget.remove,
      num: widget.rowNumber.value,
    );
  }
}
