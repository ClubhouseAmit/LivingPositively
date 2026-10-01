import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/notifications/ui/custom_reminder_form.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  testWidgets('custom label uses the server UTF-16 limit', (tester) async {
    String? submitted;
    await pumpWithProviders(
      tester,
      Scaffold(
        body: CustomReminderForm(
          use24HourFormat: true,
          onAdd: (_, label, _) async {
            submitted = label;
            return true;
          },
        ),
      ),
      userInformation: UserInformation(service: FakePersistentMemoryService()),
      surfaceSize: const Size(400, 700),
      ignoreOverflow: false,
    );

    final labelField = find.byType(TextField).last;
    await tester.enterText(labelField, List.filled(100, '👍🏽').join());
    expect(tester.widget<TextField>(labelField).controller!.text, isEmpty);

    final accepted = List.filled(60, '🙂').join();
    await tester.enterText(labelField, accepted);
    await tester.tap(find.text('Add reminder'));
    await tester.pumpAndSettle();
    expect(submitted, accepted);
  });
}
