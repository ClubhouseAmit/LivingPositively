import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'thanksListWidget.dart'; // Update with the correct path

void main() {
  group('PersonalPlanWidget Tests', () {
    List<String> thanks = ['Item 1', 'Item 2', 'Item 3'];
    int tab = 0;
    void addThanks(thank) {
      thanks.add(thank);
    }

    void edit(thank, index) {
      thanks[index] = thank;
    }

    void delete(index) {
      thanks.removeAt(index);
    }

    void changeTab(index) {
      tab = index;
    }

    testWidgets('display thanks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThanksListWidget(
              thanks: thanks,
              add: addThanks,
              edit: edit,
              remove: delete,
              addSuggested: addThanks,
              thanksListLength: thanks.length,
              onTabTapped: changeTab,
            ),
          ),
        ),
      );
      expect(find.text("Item 1"), findsOne);
      expect(find.text("Item 2"), findsOne);
      expect(find.text("Item 3"), findsOne);
    });
    testWidgets('add thanks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThanksListWidget(
              thanks: thanks,
              add: addThanks,
              edit: edit,
              remove: delete,
              addSuggested: addThanks,
              thanksListLength: thanks.length,
              onTabTapped: changeTab,
            ),
          ),
        ),
      );
      final add = find.byKey(Key("addButton"));
      expect(add, findsWidgets);
      await tester.tap(add);
      await tester.pump();
      final editField = find.byKey(Key("addFormTextField"));
      expect(editField, findsWidgets);
      await tester.enterText(editField, "tested Add Input");
      final saveButton = find.byKey(Key("saveButton"));
      final cancelButton = find.byKey(Key("cancelButton"));
      expect(saveButton, findsWidgets);
      expect(cancelButton, findsWidgets);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(saveButton, findsNothing);
      expect(find.text("Item 1"), findsOne);
      expect(find.text("Item 2"), findsOne);
      expect(find.text("Item 3"), findsOne);
      expect(find.text("tested Add Input"), findsOne);
    });
    testWidgets('edit thanks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThanksListWidget(
              thanks: thanks,
              add: addThanks,
              edit: edit,
              remove: delete,
              addSuggested: addThanks,
              thanksListLength: thanks.length,
              onTabTapped: changeTab,
            ),
          ),
        ),
      );
      final editButton = find.byKey(Key("editButton3"));
      expect(editButton, findsWidgets);
      await tester.tap(editButton);
      await tester.pump();
      final editField = find.byKey(Key("addFormTextField"));
      expect(editField, findsWidgets);
      await tester.enterText(editField, "tested Edit Input");
      final saveButton = find.byKey(Key("saveButton"));
      final cancelButton = find.byKey(Key("cancelButton"));
      expect(saveButton, findsWidgets);
      expect(cancelButton, findsWidgets);
      await tester.tap(saveButton);
      await tester.pump();
      expect(find.text("tested Add Input"), findsNothing);
      expect(find.text("tested Edit Input"), findsWidgets);
    });

    testWidgets('remove thanks', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThanksListWidget(
              thanks: thanks,
              add: addThanks,
              edit: edit,
              remove: delete,
              addSuggested: addThanks,
              thanksListLength: thanks.length,
              onTabTapped: changeTab,
            ),
          ),
        ),
      );
      final removeButton = find.byKey(Key("removeButton3"));
      expect(removeButton, findsWidgets);
      await tester.tap(removeButton);
      await tester.pump();
      expect(find.text("tested Edit Input"), findsNothing);
      expect(thanks.length, 3);
    });
    testWidgets('change Tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThanksListWidget(
              thanks: thanks,
              add: addThanks,
              edit: edit,
              remove: delete,
              addSuggested: addThanks,
              thanksListLength: thanks.length,
              onTabTapped: changeTab,
            ),
          ),
        ),
      );
      expect(find.byKey(Key("tab3")), findsWidgets);
      expect(find.byKey(Key("tab4")), findsWidgets);
      expect(tab, 0);
      await tester.tap(find.byKey(Key("tab4")));
      await tester.pump();
      expect(tab, 4);
      await tester.tap(find.byKey(Key("tab3")));
      await tester.pump();
      expect(tab, 3);
    });
    // Add more tests as needed.
  });
}
