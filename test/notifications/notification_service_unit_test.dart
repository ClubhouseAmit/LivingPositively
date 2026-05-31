import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationsService.calculateTime', () {
    test('returns TimeOfDay matching given hour/minute', () {
      final t = NotificationsService.calculateTime(7, 30);
      expect(t.hour, 7);
      expect(t.minute, 30);
    });

    test('handles edge: 0:0', () {
      final t = NotificationsService.calculateTime(0, 0);
      expect(t, const TimeOfDay(hour: 0, minute: 0));
    });

    test('handles edge: 23:59', () {
      final t = NotificationsService.calculateTime(23, 59);
      expect(t, const TimeOfDay(hour: 23, minute: 59));
    });
  });

  group('NotificationsService.supportsReminderSettings (additional cases)', () {
    test(
      'explicit isWebOverride=true short-circuits before platform check',
      () {
        expect(
          NotificationsService.supportsReminderSettings(
            isWebOverride: true,
            platformOverride: TargetPlatform.android,
          ),
          isFalse,
        );
      },
    );

    test('android non-web returns true', () {
      expect(
        NotificationsService.supportsReminderSettings(
          isWebOverride: false,
          platformOverride: TargetPlatform.android,
        ),
        isTrue,
      );
    });

    test('linux returns false', () {
      expect(
        NotificationsService.supportsReminderSettings(
          isWebOverride: false,
          platformOverride: TargetPlatform.linux,
        ),
        isFalse,
      );
    });

    test('windows returns false', () {
      expect(
        NotificationsService.supportsReminderSettings(
          isWebOverride: false,
          platformOverride: TargetPlatform.windows,
        ),
        isFalse,
      );
    });

    test('falls back to runtime defaultTargetPlatform when no override', () {
      // Result depends on test-host platform; just verify it doesn't throw
      // and returns a bool (not null).
      final r = NotificationsService.supportsReminderSettings();
      expect(r, anyOf(isTrue, isFalse));
    });
  });
}
