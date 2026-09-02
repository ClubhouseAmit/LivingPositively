import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/MainPageHelpers/components/dashed_list_widget.dart';

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
  });
}

Widget _subject({
  required VoidCallback onOpenSection,
  VoidCallback? onAddNew,
}) => Scaffold(
  body: DashedListWidget(
    title: 'Gratitude Journal',
    subtitle: 'Notice what went well',
    iconAsset: 'assets/images/thanks_icon.svg',
    items: const ['A kind conversation'],
    suggestions: const [],
    totalCount: 1,
    onOpenSection: onOpenSection,
    onAddNew: onAddNew,
  ),
);

Finder _addButton() => find.ancestor(
  of: find.byIcon(Icons.add),
  matching: find.byType(IconButton),
);
