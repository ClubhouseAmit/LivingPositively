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
  testWidgets('shows the FCM schedule time from the parent state', (
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
              initialEnabled: true,
              onToggle: (value) async {
                values.add(value);
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('9:30 AM'), findsOneWidget);
    await tester.tap(find.byType(AnimatedContainer));
    await tester.pumpAndSettle();

    expect(values, [isFalse]);
    expect(find.text('9:30 AM'), findsOneWidget);
  });

  testWidgets('uses updated parent state instead of retaining toggle state', (
    tester,
  ) async {
    Widget buildCard(bool enabled) => MaterialApp(
      home: Scaffold(
        body: NotificationToggleCard(
          emoji: '✨',
          badgeText: 'LP',
          title: 'Daily reminder',
          subtitle: 'A supportive message',
          initialEnabled: enabled,
          initialTime: const TimeOfDay(hour: 7, minute: 45),
          onToggle: (_) async {},
        ),
      ),
    );

    await tester.pumpWidget(buildCard(false));
    expect(find.text('7:45 AM'), findsNothing);

    await tester.pumpWidget(buildCard(true));
    expect(find.text('7:45 AM'), findsOneWidget);
  });
}
