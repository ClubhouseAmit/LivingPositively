import 'package:flutter_test/flutter_test.dart';
import 'TraitListWidgetTest.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('test the positive trait list', (WidgetTester tester) async {
    List<String> positiveTraits = ["smart", "beautifull", "kind"];
    add(text) {
      positiveTraits.add(text);
    }

    edit(text, index) => {positiveTraits[index] = text};
    remove(index) => {positiveTraits.removeAt(index)};
    addSuggested() => positiveTraits.add("Suggested");
    onTabTapped(index) => debugPrint(index);

    await tester.pumpWidget(
      TraitListWidget(
        traits: positiveTraits,
        add: add,
        edit: edit,
        remove: remove,
        traitListLength: positiveTraits.length,
        addSuggested: addSuggested,
        onTabTapped: onTabTapped,
      ),
    );
    final addButton = find.byKey(Key('addButton'));
    expect(addButton, findsWidgets);
    await tester.tap(addButton);
    await tester.pump();
    expect(find.text("Test Text"), findsOneWidget);
    final editButton = find.byKey(Key('editButton_3'));
    expect(editButton, findsWidgets);
    await tester.tap(editButton);
    await tester.pump();
    expect(find.text("Edit Text"), findsOneWidget);
    final removeButton = find.byKey(Key('deleteButton_3'));
    expect(removeButton, findsWidgets);
    await tester.tap(removeButton);
    await tester.pump();
    expect(find.text("Edit Text"), findsNothing);
    final addSuggestedButton = find.byKey(Key('addPositiveSuggesstion'));
    expect(addSuggestedButton, findsWidgets);
    await tester.tap(addSuggestedButton);
    await tester.pump();
    //expect(find.text("Suggested"), findsOneWidget);
  });
}
