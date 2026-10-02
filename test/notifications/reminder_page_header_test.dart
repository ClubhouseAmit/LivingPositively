import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/notifications/ui/reminder_page_header.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  group('ReminderPageHeader', () {
    testWidgets('should omit the wide clock format control', (tester) async {
      final memory = FakePersistentMemoryService();
      final user = UserInformation(service: memory);
      final repository = NotificationRepository.forService(memory);

      await pumpWithProviders(
        tester,
        const ReminderPageHeader(),
        userInformation: user,
        surfaceSize: const Size(900, 600),
        ignoreOverflow: false,
      );

      expect(find.text('24h'), findsNothing);
      expect(find.text('AM/PM'), findsNothing);
      expect(repository.use24HourFormat, isTrue);
    });
  });
}
