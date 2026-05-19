// Drives Journal.addThankYou + showThankYouPopup by tapping the embedded
// ThanksItemSuggested add button (the production widget composed inside
// Journal). Covers the addThankYou path (lines 116-147 of
// lib/pages/journal.dart) and the showThankYouPopup AlertDialog branch
// (lines 150-170).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/journal.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

const _suggestions = <String>[
  'Be grateful for sunshine',
  'Be grateful for friends',
  'Be grateful for food',
  'Be grateful for health',
  'Be grateful for family',
];

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

  testWidgets(
      'tapping the add button on a ThanksItemSuggested invokes addThankYou',
      (tester) async {
    await pumpWithProviders(
      tester,
      const Journal(fullSuggestionList: _suggestions),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );

    // Find the first GestureDetector inside the first ThanksItemSuggested —
    // that is the add-button row.
    final firstSuggestion = find.byType(ThanksItemSuggested).first;
    final addGesture = find
        .descendant(of: firstSuggestion, matching: find.byType(GestureDetector))
        .first;

    await tester.ensureVisible(addGesture);
    await tester.tap(addGesture, warnIfMissed: false);
    await tester.pump();
    // Drive the post-tap Future.delayed(0) that schedules the popup.
    await tester.pump(const Duration(milliseconds: 50));

    // After the tap, addThankYou should have appended to userInformation.thanks
    // and the AlertDialog popup should have been scheduled for the first
    // entry-of-the-day.
    expect(user.thanks['thanks']?.length, 1);
    // The popup dialog is shown via showDialog when count == 1.
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets(
      'second tap does NOT show the AlertDialog (popup only on first entry)',
      (tester) async {
    // Seed a prior thank-you for today so the count-after-tap will be > 1,
    // exercising the `else` branch (line 137 NOT taken).
    final today = _todayString();
    user.updateThanks({
      'thanks': ['existing-entry'],
      'dates': [today],
    });

    await pumpWithProviders(
      tester,
      const Journal(fullSuggestionList: _suggestions),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );

    final firstSuggestion = find.byType(ThanksItemSuggested).first;
    final addGesture = find
        .descendant(of: firstSuggestion, matching: find.byType(GestureDetector))
        .first;
    await tester.ensureVisible(addGesture);
    await tester.tap(addGesture, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Should now have 2 entries and NO popup.
    expect(user.thanks['thanks']?.length, 2);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

String _todayString() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  // Match the production format 'yyyy-MM-dd – kk:mm' on the first 10 chars.
  return '$y-$m-$d – 09:00';
}
