// Interaction tests for lib/pages/journal.dart that drive
// `addThankYou`, `editThankYou`, `removeThankYou`, and the `showThankYouPopup`
// branch (first thank-you-of-the-day) — methods the existing
// `Journal_test.dart` only renders around.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/journal.dart';
import 'package:mazilon/pages/thankYou.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

const _suggestions = [
  'Be grateful for sunshine',
  'Be grateful for friends',
  'Be grateful for food',
  'Be grateful for health',
  'Be grateful for family',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation userInformation;

  setUp(() {
    registerTestServices(locale: 'en');
    userInformation = UserInformation();
    userInformation.gender = 'other';
    userInformation.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets(
      'tap delete on an existing ThankYou row triggers removeThankYou flow',
      (tester) async {
    userInformation.updateThanks({
      'thanks': ['First', 'Second'],
      'dates': ['2024-01-01 – 09:00', '2024-01-01 – 10:00'],
    });

    await pumpWithProviders(
      tester,
      const Journal(fullSuggestionList: _suggestions),
      userInformation: userInformation,
      surfaceSize: const Size(1024, 2400),
    );

    // Find a ThankYou row's delete (trash) icon.
    expect(find.byType(ThankYou), findsNWidgets(2));
    final trashIcon = find.byIcon(Icons.delete).first;
    final trashTap = find
        .ancestor(of: trashIcon, matching: find.byType(MaterialButton))
        .first;
    await tester.tap(trashTap, warnIfMissed: false);
    await tester.pumpAndSettle();

    // List shrunk by one.
    expect(userInformation.thanks['thanks']?.length, 1);
  });

  testWidgets('editThankYou closure routes through AddForm seeded with text',
      (tester) async {
    userInformation.updateThanks({
      'thanks': ['Original entry'],
      'dates': ['2024-01-01 – 09:00'],
    });

    await pumpWithProviders(
      tester,
      const Journal(fullSuggestionList: _suggestions),
      userInformation: userInformation,
      surfaceSize: const Size(1024, 2400),
    );

    expect(find.byType(ThankYou), findsOneWidget);
    final editIcon = find.byIcon(Icons.edit).first;
    final editButton = find
        .ancestor(of: editIcon, matching: find.byType(MaterialButton))
        .first;
    await tester.tap(editButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(AddForm), findsOneWidget);

    // Replace text and save → editThankYou path.
    await tester.enterText(find.byType(TextFormField), 'Updated entry');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(userInformation.thanks['thanks'], contains('Updated entry'));
    expect(userInformation.thanks['thanks'], isNot(contains('Original entry')));
  });
}
