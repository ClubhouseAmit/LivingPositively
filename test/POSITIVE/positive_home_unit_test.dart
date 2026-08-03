import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'TraitListWidgetTest.dart';

void main() {
  testWidgets('test the positive trait list', (tester) async {
    final positiveTraits = <String>['smart', 'beautifull', 'kind'];
    void add(String text) {
      positiveTraits.add(text);
    }

    void edit(String text, int index) { positiveTraits[index] = text; }
    void remove(int index) { positiveTraits.removeAt(index); }
    void addSuggested() => positiveTraits.add('Suggested');
    void onTabTapped(int index) => debugPrint(index.toString());

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
    final addButton = find.byKey(const Key('addButton'));
    expect(addButton, findsWidgets);
    await tester.tap(addButton);
    await tester.pump();
    expect(find.text('Test Text'), findsOneWidget);
    final editButton = find.byKey(const Key('editButton_3'));
    expect(editButton, findsWidgets);
    await tester.tap(editButton);
    await tester.pump();
    expect(find.text('Edit Text'), findsOneWidget);
    final removeButton = find.byKey(const Key('deleteButton_3'));
    expect(removeButton, findsWidgets);
    await tester.tap(removeButton);
    await tester.pump();
    expect(find.text('Edit Text'), findsNothing);
    final addSuggestedButton = find.byKey(const Key('addPositiveSuggesstion'));
    expect(addSuggestedButton, findsWidgets);
    await tester.tap(addSuggestedButton);
    await tester.pump();
    //expect(find.text("Suggested"), findsOneWidget);
  });
}
