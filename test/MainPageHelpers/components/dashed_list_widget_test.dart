import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/home/ui/dashed_list_widget.dart';

import '../../helpers/widget_test_scaffold.dart';

void main() {
  group('DashedListWidget', () {
    setUp(registerTestServices);
    tearDown(resetTestServices);

    testWidgets('should open the section when the title or icon is tapped', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      try {
        var openCount = 0;

        await pumpWithProviders(
          tester,
          _subject(onOpenSection: () => openCount++),
          surfaceSize: const Size(400, 800),
        );

        await tester.tap(find.text('Gratitude Journal'));
        await tester.pump();
        await tester.tap(find.byType(SvgPicture));
        await tester.pump();

        expect(openCount, 2);
        expect(
          tester
              .getSemantics(find.byKey(const Key('dashedListTitleTapTarget')))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('should use onAddNew when the add button is tapped', (
      tester,
    ) async {
      var openCount = 0;
      var addCount = 0;

      await pumpWithProviders(
        tester,
        _subject(onOpenSection: () => openCount++, onAddNew: () => addCount++),
        surfaceSize: const Size(400, 800),
      );

      await tester.tap(_addButton());
      await tester.pump();

      expect(addCount, 1);
      expect(openCount, 0);
    });

    testWidgets(
      'should open the section when the add button has no add callback',
      (tester) async {
        var openCount = 0;

        await pumpWithProviders(
          tester,
          _subject(onOpenSection: () => openCount++),
          surfaceSize: const Size(400, 800),
        );

        await tester.tap(_addButton());
        await tester.pump();

        expect(openCount, 1);
      },
    );

    testWidgets('should render only the first three items by default', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        _subject(
          onOpenSection: () {},
          items: const ['One', 'Two', 'Three', 'Four'],
        ),
        surfaceSize: const Size(400, 800),
      );

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
      expect(find.text('Four'), findsNothing);
    });

    testWidgets(
      'should render and wire all items when showAllItems is enabled',
      (tester) async {
        const items = ['One', 'Two', 'Three', 'Four', 'Five'];
        int? editedIndex;
        int? removedIndex;

        await pumpWithProviders(
          tester,
          _subject(
            onOpenSection: () {},
            items: items,
            showAllItems: true,
            onEditItem: (index) => editedIndex = index,
            onRemoveItem: (index) => removedIndex = index,
          ),
          surfaceSize: const Size(400, 1000),
        );

        for (final item in items) {
          expect(find.text(item), findsOneWidget);
        }

        await tester.tap(find.byIcon(Icons.edit).at(3));
        await tester.tap(find.byIcon(Icons.close).at(4));

        expect(editedIndex, 3);
        expect(removedIndex, 4);
      },
    );
  });
}

Widget _subject({
  required VoidCallback onOpenSection,
  VoidCallback? onAddNew,
  List<String> items = const ['A kind conversation'],
  bool showAllItems = false,
  void Function(int index)? onEditItem,
  void Function(int index)? onRemoveItem,
}) => Scaffold(
  body: DashedListWidget(
    title: 'Gratitude Journal',
    subtitle: 'Notice what went well',
    iconAsset: 'assets/images/thanks_icon.svg',
    items: items,
    suggestions: const [],
    totalCount: items.length,
    showAllItems: showAllItems,
    onOpenSection: onOpenSection,
    onAddNew: onAddNew,
    onEditItem: onEditItem,
    onRemoveItem: onRemoveItem,
  ),
);

Finder _addButton() => find.ancestor(
  of: find.byIcon(Icons.add),
  matching: find.byType(IconButton),
);
