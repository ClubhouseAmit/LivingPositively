import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/notifications/ui/reminder_settings_panel.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  testWidgets('uncertain custom registration remains removable', (
    tester,
  ) async {
    final memory = FakePersistentMemoryService();
    final repository = NotificationRepository.forService(memory);
    final user = UserInformation(service: memory);
    final cancelled = <String>[];
    var failures = 0;

    await pumpWithProviders(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ReminderSettingsPanel(
            repository: repository,
            onRegister: (_, _, _, _) async => false,
            onCancel: (id) async {
              cancelled.add(id);
              return true;
            },
            onFailure: () => failures++,
            onFormatChanged: () {},
          ),
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(400, 800),
      ignoreOverflow: false,
    );

    await tester.enterText(find.byType(TextField).last, 'Practice');
    await tester.ensureVisible(find.text('Add reminder'));
    await tester.tap(find.text('Add reminder'));
    await tester.pumpAndSettle();

    expect(repository.customReminders, hasLength(1));
    final id = repository.customReminders.single.id;
    expect(repository.getPreference(id), isNull);
    expect(failures, 1);

    await tester.ensureVisible(find.byIcon(Icons.close));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(cancelled, [id]);
    expect(repository.customReminders, isEmpty);
  });

  testWidgets('does not save a new custom reminder when 32 are active', (
    tester,
  ) async {
    final memory = FakePersistentMemoryService();
    final repository = NotificationRepository.forService(memory);
    for (var index = 0; index < maxRemindersPerUser; index++) {
      await repository.setPreference(
        'existing_$index',
        const NotificationPreference(hour: 8, minute: 0),
      );
    }
    var registrations = 0;
    await pumpWithProviders(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ReminderSettingsPanel(
            repository: repository,
            onRegister: (_, _, _, _) async {
              registrations++;
              return true;
            },
            onCancel: (_) async => true,
            onFailure: () {},
            onFormatChanged: () {},
          ),
        ),
      ),
      userInformation: UserInformation(service: memory),
      surfaceSize: const Size(400, 800),
    );

    await tester.enterText(find.byType(TextField).last, 'Practice');
    await tester.ensureVisible(find.text('Add reminder'));
    await tester.tap(find.text('Add reminder'));
    await tester.pump();

    expect(registrations, 0);
    expect(repository.customReminders, isEmpty);
    expect(find.textContaining('up to 32 active reminders'), findsOneWidget);
  });

  testWidgets('server limit keeps the form and removes the unsent card', (
    tester,
  ) async {
    final memory = FakePersistentMemoryService();
    final repository = NotificationRepository.forService(memory);
    var failures = 0;
    await pumpWithProviders(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ReminderSettingsPanel(
            repository: repository,
            onRegister: (_, _, _, _) async =>
                throw const NotificationReminderLimitException(),
            onCancel: (_) async => true,
            onFailure: () => failures++,
            onFormatChanged: () {},
          ),
        ),
      ),
      userInformation: UserInformation(service: memory),
      surfaceSize: const Size(400, 800),
    );

    await tester.enterText(find.byType(TextField).last, 'Practice');
    await tester.ensureVisible(find.text('Add reminder'));
    await tester.tap(find.text('Add reminder'));
    await tester.pump();

    expect(repository.customReminders, isEmpty);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.textContaining('up to 32 active reminders'), findsOneWidget);
    expect(failures, 0);
  });
}
