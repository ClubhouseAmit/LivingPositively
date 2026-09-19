import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/home/ui/dashed_list_widget.dart';
import 'package:mazilon/features/journal/ui/gratitude_section.dart';
import 'package:mazilon/features/journal/ui/AddForm.dart';
import 'package:mazilon/util/userInformation.dart';

import '../../helpers/widget_test_scaffold.dart';

void main() {
  group('GratitudeSectionWidget', () {
    setUp(registerTestServices);
    tearDown(resetTestServices);

    testWidgets('should reject stale edits and removals for expanded rows', (
      tester,
    ) async {
      final today = DateTime.now().toIso8601String();
      const initialItems = ['One', 'Two', 'Three', 'Four', 'Five'];
      final dates = List<String>.filled(initialItems.length, today);
      final user = UserInformation(
        gender: 'other',
        localeName: 'en',
        thanks: {'thanks': initialItems, 'dates': dates},
      );

      await pumpWithProviders(
        tester,
        Scaffold(body: GratitudeSectionWidget(onOpenSection: () {})),
        userInformation: user,
        surfaceSize: const Size(1024, 1200),
      );

      for (final item in initialItems) {
        expect(find.text(item), findsOneWidget);
      }

      final section = tester.widget<DashedListWidget>(
        find.byType(DashedListWidget),
      );
      section.onEditItem!(3);
      await tester.pumpAndSettle();
      expect(find.byType(AddForm), findsOneWidget);

      const reorderedItems = ['One', 'Three', 'Two', 'Four', 'Five'];
      user.updateThanks({'thanks': reorderedItems, 'dates': dates});
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'Changed');
      await tester.tap(
        find
            .descendant(
              of: find.byType(AddForm),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();

      expect(user.thanks['thanks'], reorderedItems);

      final staleSection = tester.widget<DashedListWidget>(
        find.byType(DashedListWidget),
      );
      const changedItems = ['One', 'Two', 'Four', 'Three', 'Five'];
      user.updateThanks({'thanks': changedItems, 'dates': dates});
      await tester.pump();
      staleSection.onRemoveItem!(3);
      await tester.pump();

      expect(user.thanks['thanks'], changedItems);
    });
  });
}
