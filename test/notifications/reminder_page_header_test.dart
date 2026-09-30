import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/notifications/ui/reminder_page_header.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  testWidgets('wide header changes the persisted clock format', (tester) async {
    final memory = FakePersistentMemoryService();
    final user = UserInformation(service: memory);
    final repository = NotificationRepository.forService(memory);
    var changed = 0;

    await pumpWithProviders(
      tester,
      ReminderPageHeader(
        onFormatChanged: () => changed++,
        onFailure: () => fail('format save failed'),
      ),
      userInformation: user,
      surfaceSize: const Size(900, 600),
      ignoreOverflow: false,
    );

    expect(find.text('24h'), findsOneWidget);
    await tester.tap(find.text('24h'));
    await tester.pumpAndSettle();

    expect(repository.use24HourFormat, isFalse);
    expect(find.text('AM/PM'), findsOneWidget);
    expect(changed, 1);
  });
}
