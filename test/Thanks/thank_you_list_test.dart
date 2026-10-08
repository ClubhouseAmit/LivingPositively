// Widget tests for ThankYouList in
// lib/features/journal/ui/thank_you_list.dart.
//
// Issue #358: when a note is added on the journal page, the new (first,
// newest-first) row fades in, like the home page. Nothing animates on first
// load or on remove.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/journal/ui/thank_you_list.dart';
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

  Future<void> pumpList(WidgetTester tester, List<String> thankYous) {
    return pumpWithProviders(
      tester,
      Scaffold(
        body: ThankYouList(
          thankYous: thankYous,
          dates: List<String>.filled(thankYous.length, _date),
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
    await pumpList(tester, ['Sun', 'Rain']);

    expect(opacityOf(tester, 'Rain'), 1.0);
  });

  testWidgets('fades in the new first row when a note is added', (
    tester,
  ) async {
    await pumpList(tester, ['Sun']);
    await pumpList(tester, ['Sun', 'Rain']);
    await tester.pump(const Duration(milliseconds: 100));

    expect(opacityOf(tester, 'Rain'), lessThan(1.0));

    await tester.pumpAndSettle();

    expect(opacityOf(tester, 'Rain'), 1.0);
  });

  testWidgets('does not animate when a note is removed', (tester) async {
    await pumpList(tester, ['Sun', 'Rain', 'Friends']);
    await pumpList(tester, ['Sun', 'Rain']);
    await tester.pump(const Duration(milliseconds: 100));

    expect(opacityOf(tester, 'Rain'), 1.0);
  });
}
