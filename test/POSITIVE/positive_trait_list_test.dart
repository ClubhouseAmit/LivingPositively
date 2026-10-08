// Widget tests for PositiveTraitList in
// lib/features/positive/ui/positive_trait_list.dart.
//
// Issue #358: when a trait is added on the positive traits page, the new
// (last) row fades in, like the home page. Nothing animates on first load
// or on remove.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/positive/ui/positive_trait_list.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

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

  Future<void> pumpList(WidgetTester tester, List<String> traits) {
    return pumpWithProviders(
      tester,
      Scaffold(
        body: PositiveTraitList(
          traits: traits,
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

  testWidgets('does not animate on first load', (tester) async {
    await pumpList(tester, ['Kind', 'Brave']);

    expect(opacityOf(tester, 'Brave'), 1.0);
  });

  testWidgets('fades in the new last row when a trait is added', (
    tester,
  ) async {
    await pumpList(tester, ['Kind']);
    await pumpList(tester, ['Kind', 'Brave']);
    await tester.pump(const Duration(milliseconds: 100));

    expect(opacityOf(tester, 'Brave'), lessThan(1.0));

    await tester.pumpAndSettle();

    expect(opacityOf(tester, 'Brave'), 1.0);
  });

  testWidgets('does not animate when a trait is removed', (tester) async {
    await pumpList(tester, ['Kind', 'Brave', 'Caring']);
    await pumpList(tester, ['Kind', 'Brave']);
    await tester.pump(const Duration(milliseconds: 100));

    expect(opacityOf(tester, 'Brave'), 1.0);
  });
}
