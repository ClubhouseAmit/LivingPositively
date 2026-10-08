// Widget tests for AnimatedItemList in
// lib/features/journal/ui/animated_item_list.dart.
//
// Issue #358: when an item is added on the journal page (newest first) or
// the positive traits page (oldest first), the new row fades in, like the
// home page. Nothing animates on first load or on remove.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/journal/ui/animated_item_list.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

const _date = '2026-01-01 – 09:00';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  Future<void> pumpList(
    WidgetTester tester,
    List<String> items, {
    required bool newestFirst,
  }) {
    return pumpWithProviders(
      tester,
      Scaffold(
        body: AnimatedItemList(
          items: items,
          dates: newestFirst ? List<String>.filled(items.length, _date) : null,
          newestFirst: newestFirst,
          edit: (String text, int index) {},
          remove: (int index) {},
          color: Colors.black,
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 800),
    );
  }

  double opacityOf(WidgetTester tester, String text) {
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(of: find.text(text), matching: find.byType(FadeTransition))
          .first,
    );
    return fade.opacity.value;
  }

  for (final newestFirst in [true, false]) {
    group(newestFirst ? 'newest first (journal)' : 'oldest first (traits)', () {
      testWidgets('does not animate on first load', (tester) async {
        await pumpList(tester, ['Sun', 'Rain'], newestFirst: newestFirst);

        expect(opacityOf(tester, 'Rain'), 1.0);
      });

      testWidgets('fades in the new row when an item is added', (
        tester,
      ) async {
        await pumpList(tester, ['Sun'], newestFirst: newestFirst);
        await pumpList(tester, ['Sun', 'Rain'], newestFirst: newestFirst);
        await tester.pump(const Duration(milliseconds: 100));

        expect(opacityOf(tester, 'Rain'), lessThan(1.0));

        await tester.pumpAndSettle();

        expect(opacityOf(tester, 'Rain'), 1.0);
      });

      testWidgets('does not animate when an item is removed', (tester) async {
        await pumpList(
          tester,
          ['Sun', 'Rain', 'Friends'],
          newestFirst: newestFirst,
        );
        await pumpList(tester, ['Sun', 'Rain'], newestFirst: newestFirst);
        await tester.pump(const Duration(milliseconds: 100));

        expect(opacityOf(tester, 'Rain'), 1.0);
      });
    });
  }

  testWidgets('newest first shows the last item on top', (
    tester,
  ) async {
    await pumpList(tester, ['Sun', 'Rain'], newestFirst: true);

    expect(
      tester.getTopLeft(find.text('Rain')).dy,
      lessThan(tester.getTopLeft(find.text('Sun')).dy),
    );
  });

  testWidgets('oldest first shows items in order', (tester) async {
    await pumpList(tester, ['Sun', 'Rain'], newestFirst: false);

    expect(
      tester.getTopLeft(find.text('Sun')).dy,
      lessThan(tester.getTopLeft(find.text('Rain')).dy),
    );
  });
}
