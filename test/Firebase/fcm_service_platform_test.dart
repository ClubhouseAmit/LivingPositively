import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reminder initialization is a no-op on unsupported native platforms',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await expectLater(FcmService.initialize(), completes);
      await expectLater(FcmService.onUserSignedIn(), completes);
    },
  );

  test('reminder support matrix includes only Android and iOS', () {
    for (final platform in TargetPlatform.values) {
      expect(
        FcmService.supportsReminderSettings(
          isWebOverride: false,
          platformOverride: platform,
        ),
        platform == TargetPlatform.android || platform == TargetPlatform.iOS,
        reason: 'unexpected support result for $platform',
      );
    }
    expect(
      FcmService.supportsReminderSettings(
        isWebOverride: true,
        platformOverride: TargetPlatform.android,
      ),
      isFalse,
    );
  });
}
