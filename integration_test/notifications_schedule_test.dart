import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FcmService', () {
    test('should support reminder settings on Android and iOS', () {
      expect(
        FcmService.supportsReminderSettings(
          platformOverride: TargetPlatform.android,
        ),
        isTrue,
      );
      expect(
        FcmService.supportsReminderSettings(
          platformOverride: TargetPlatform.iOS,
        ),
        isTrue,
      );
    });
  });
}
