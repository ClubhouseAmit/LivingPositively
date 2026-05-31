// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'steps_widget.dart'; // Import your widget file
import 'text_widget.dart';
import 'phone_widget.dart';

import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  SharedPreferences.setMockInitialValues({});
  testWidgets('next function increments currentStep without exceeding bounds', (
    WidgetTester tester,
  ) async {
    // Assuming YourWidget is the widget that contains the next function
    await tester.pumpWidget(StepsWidget());
    var nextButton = find.byKey(Key('Next'));
    var prevButton = find.byKey(Key('Prev'));
    var skipButton = find.byKey(Key('Skip'));
    // Initial conditions: assuming currentStep is 0 and steps.length is 3
    expect(
      find.text('Step 0'),
      findsOneWidget,
    ); // Verify initial step is displayed

    // Execute the next function
    await tester.tap(nextButton); // Assuming you have a button that calls next
    await tester.pump(); // Rebuild the widget with the new state

    // Assert the outcome
    expect(
      find.text('Step 1'),
      findsOneWidget,
    ); // Verify currentStep incremented

    // Execute the next function again to test boundary condition
    await tester.tap(nextButton);
    await tester.pump();

    // Since steps.length is 3, currentStep should not exceed 2
    expect(
      find.text('Step 2'),
      findsOneWidget,
    ); // Verify currentStep is at the last step
    // Optionally, verify it doesn't increment beyond the last step
    await tester.tap(nextButton);
    await tester.pump();
    expect(find.text('Step 2'), findsOneWidget); // Still on the last step
    await tester.tap(prevButton);
    await tester.pump();
    expect(find.text('Step 1'), findsOneWidget); // Back to the second step
    await tester.tap(prevButton);
    await tester.pump();
    expect(find.text('Step 0'), findsOneWidget); // Back to the second step
    await tester.tap(skipButton);
    await tester.pump();
    expect(find.text('Step 2'), findsOneWidget); // Back to the second step
  });
  testWidgets('test input received in form', (WidgetTester tester) async {
    await tester.pumpWidget(TextWidget());
    final textFieldFinder = find.byKey(
      Key('TextFieldName'),
    ); // or find.byKey(Key('your-textfield-key'))
    final agedrop = find.byKey(Key('dropdownAge'));
    await tester.enterText(textFieldFinder, 'Test Input');
    await tester.pump();
    expect(find.text('Test Input'), findsOneWidget);
    await tester.pump();
    await tester.tap(agedrop);
    await tester.pumpAndSettle();
    expect(find.text("18-30"), findsWidgets);
    await tester.tap(agedrop);
    await tester.pumpAndSettle();
    await tester.tap(find.text("18-"));
    await tester.pumpAndSettle();
    expect(find.text("18-"), findsWidgets);

    await tester.tap(agedrop);
    await tester.pumpAndSettle();
    await tester.tap(find.text("30-40"));
    await tester.pumpAndSettle();
    expect(find.text("30-40"), findsWidgets);

    await tester.tap(agedrop);
    await tester.pumpAndSettle();
    await tester.tap(find.text("40-55"));
    await tester.pumpAndSettle();
    expect(find.text("40-55"), findsWidgets);

    await tester.tap(agedrop);
    await tester.pumpAndSettle();
    await tester.tap(find.text("55+"));
    await tester.pumpAndSettle();
    expect(find.text("55+"), findsWidgets);
  });

  testWidgets('test Phone Page', (WidgetTester tester) async {
    await tester.pumpWidget(PhoneWidget());
    final textFieldFinder = find.byKey(Key('addPhoneButton'));
    await tester.tap(textFieldFinder);
    await tester.pump(); // Rebuild the widget with the new state
    //phase 1, click and then unclick
    final deletePhoneButton = find.byKey(Key('deletePhoneButton'));
    final addPhoneButton = find.byKey(Key('addPhoneButtonInEdit'));
    final nameField = find.byKey(Key('nameField'));
    final numberField = find.byKey(Key('numberField'));
    expect(nameField, findsWidgets);
    expect(numberField, findsWidgets);
    expect(addPhoneButton, findsWidgets);
    expect(deletePhoneButton, findsWidgets);
    await tester.tap(deletePhoneButton);
    await tester.pump();
    expect(deletePhoneButton, findsNothing);
    expect(addPhoneButton, findsNothing);
    expect(nameField, findsNothing);
    expect(numberField, findsNothing);
    //end of phase one

    //phase 2, click and add
    await tester.tap(textFieldFinder);
    await tester.pump();
    final deletePhoneButton2 = find.byKey(Key('deletePhoneButton'));
    final nameField2 = find.byKey(Key('nameField'));
    final numberField2 = find.byKey(Key('numberField'));
    final addPhoneButton2 = find.byKey(Key('addPhoneButtonInEdit'));

    await tester.enterText(nameField2, 'Test Name');
    await tester.enterText(numberField2, 'Test Number');
    await tester.pump();
    expect(find.text('Test Name'), findsOneWidget);
    expect(find.text('Test Number'), findsOneWidget);
    await tester.tap(addPhoneButton2);
    await tester.pump();
    expect(deletePhoneButton2, findsNothing);
    expect(nameField2, findsNothing);
    expect(numberField2, findsNothing);
    final Text nameFieldNoEdit = tester.widget(
      find.byKey(Key('phoneNameAfterAdd')),
    );

    expect(nameFieldNoEdit.data, 'Test Name');
    expect(find.text('Test Name'), findsOneWidget);

    // end of phase 2
    //phase 3 delete the phone number
    expect(find.byKey(Key('enterEditingMode')), findsWidgets);
    await tester.tap(find.byKey(Key('enterEditingMode')));
    await tester.pump();

    final deletePhoneButton3 = find.byKey(Key('deletePhoneButton'));
    final nameField3 = find.byKey(Key('nameField'));
    final numberField3 = find.byKey(Key('numberField'));
    final addPhoneButton3 = find.byKey(Key('addPhoneButtonInEdit'));
    expect(nameField3, findsWidgets);
    expect(numberField3, findsWidgets);
    expect(addPhoneButton3, findsWidgets);
    expect(deletePhoneButton3, findsWidgets);
  });
}
