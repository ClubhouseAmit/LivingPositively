import 'dart:async';

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
              setTimeLabel: 'Set time',
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
              setTimeLabel: 'Set time',
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

  testWidgets(
    'shows the localized fallback when an enabled reminder lacks a time',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationToggleCard(
              emoji: '✨',
              badgeText: 'LP',
              title: 'Daily reminder',
              subtitle: 'A supportive message',
              setTimeLabel: 'Choose a time',
              initialEnabled: true,
            ),
          ),
        ),
      );

      expect(find.text('Choose a time'), findsOneWidget);
    },
  );

  testWidgets(
    'applies a parent reminder update received during a toggle mutation',
    (tester) async {
      final mutation = Completer<bool>();

      Widget buildCard({required bool initialEnabled, TimeOfDay? initialTime}) {
        return MaterialApp(
          home: Scaffold(
            body: NotificationToggleCard(
              emoji: '✨',
              badgeText: 'LP',
              title: 'Daily reminder',
              subtitle: 'A supportive message',
              setTimeLabel: 'Set time',
              initialEnabled: initialEnabled,
              initialTime: initialTime,
              onToggle: (_) => mutation.future,
            ),
          ),
        );
      }

      await tester.pumpWidget(buildCard(initialEnabled: false));
      await tester.tap(find.byType(AnimatedContainer));
      await tester.pump();

      await tester.pumpWidget(
        buildCard(
          initialEnabled: true,
          initialTime: const TimeOfDay(hour: 10, minute: 15),
        ),
      );
      mutation.complete(false);
      await tester.pumpAndSettle();

      expect(find.text('10:15 AM'), findsOneWidget);
    },
  );

  testWidgets('shows progress while a reminder mutation is pending', (
    tester,
  ) async {
    final mutation = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationToggleCard(
            emoji: '✨',
            badgeText: 'LP',
            title: 'Daily reminder',
            subtitle: 'A supportive message',
            setTimeLabel: 'Set time',
            onToggle: (_) => mutation.future,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AnimatedContainer));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    mutation.complete(false);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
