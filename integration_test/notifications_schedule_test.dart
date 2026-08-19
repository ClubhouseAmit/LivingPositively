import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('FCM reminder settings are available on supported mobile platforms', () {
    expect(
      FcmService.supportsReminderSettings(
        platformOverride: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      FcmService.supportsReminderSettings(platformOverride: TargetPlatform.iOS),
      isTrue,
    );
  });
}
