import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/notifications/notification_toggle_card.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class _Memory implements PersistentMemoryService {
  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async => null;

  @override
  Future<void> reset() async {}

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {}
}

void main() {
  testWidgets('toggle exposes the FCM schedule time when enabled', (
    tester,
  ) async {
    final values = <bool>[];
    final user = UserInformation(service: _Memory());

    await tester.pumpWidget(
      ChangeNotifierProvider<UserInformation>.value(
        value: user,
        child: MaterialApp(
          home: Scaffold(
            body: NotificationToggleCard(
              emoji: '✨',
              badgeText: 'LP',
              title: 'Daily reminder',
              subtitle: 'A supportive message',
              initialTime: const TimeOfDay(hour: 9, minute: 30),
              onToggle: (value) async {
                values.add(value);
                return true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('9:30 AM'), findsNothing);
    await tester.tap(find.byType(AnimatedContainer));
    await tester.pumpAndSettle();

    expect(values, [isTrue]);
    expect(find.text('9:30 AM'), findsOneWidget);
  });

  testWidgets('toggle remains unchanged when the remote mutation fails', (
    tester,
  ) async {
    final user = UserInformation(service: _Memory());

    await tester.pumpWidget(
      ChangeNotifierProvider<UserInformation>.value(
        value: user,
        child: MaterialApp(
          home: Scaffold(
            body: NotificationToggleCard(
              emoji: 'âœ¨',
              badgeText: 'LP',
              title: 'Daily reminder',
              subtitle: 'A supportive message',
              initialTime: const TimeOfDay(hour: 9, minute: 30),
              onToggle: (_) async => false,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AnimatedContainer));
    await tester.pumpAndSettle();

    expect(find.text('9:30 AM'), findsNothing);
  });
}
