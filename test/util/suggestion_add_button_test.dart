import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/suggestion_add_button.dart';

void main() {
  for (final testCase in <({String? label, String expectedLabel})>[
    (label: null, expectedLabel: 'Add'),
    (label: 'Custom add', expectedLabel: 'Custom add'),
  ]) {
    testWidgets(
      'provides a labelled 48dp add action for ${testCase.expectedLabel}',
      (tester) async {
        var taps = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SuggestionAddButton(
                label: testCase.label,
                onPressed: () => taps++,
              ),
            ),
          ),
        );

        final button = find.byType(SuggestionAddButton);
        final tapTarget = find.descendant(
          of: button,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is SizedBox && widget.width == 48 && widget.height == 48,
          ),
        );
        final handle = tester.ensureSemantics();
        try {
          expect(find.byTooltip(testCase.expectedLabel), findsOneWidget);
          expect(tapTarget, findsOneWidget);
          expect(tester.getSize(tapTarget), const Size(48, 48));
          expect(
            tester.getSemantics(find.byType(InkWell)),
            matchesSemantics(
              label: testCase.expectedLabel,
              tooltip: testCase.expectedLabel,
              isButton: true,
              isFocusable: true,
              hasTapAction: true,
              hasFocusAction: true,
            ),
          );

          await tester.tap(tapTarget);
          expect(taps, 1);
        } finally {
          handle.dispose();
        }
      },
    );
  }
}
