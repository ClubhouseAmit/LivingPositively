import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';

void main() {
  group('NotificationsService.supportsReminderSettings', () {
    test('returns false on web', () {
      expect(
        NotificationsService.supportsReminderSettings(isWebOverride: true),
        isFalse,
      );
    });

    test('returns true on iOS', () {
      expect(
        NotificationsService.supportsReminderSettings(
          isWebOverride: false,
          platformOverride: TargetPlatform.iOS,
        ),
        isTrue,
      );
    });

    test('returns false on macOS', () {
      expect(
        NotificationsService.supportsReminderSettings(
          isWebOverride: false,
          platformOverride: TargetPlatform.macOS,
        ),
        isFalse,
      );
    });

    test('returns true on Android', () {
      expect(
        NotificationsService.supportsReminderSettings(
          isWebOverride: false,
          platformOverride: TargetPlatform.android,
        ),
        isTrue,
      );
    });
  });
}
