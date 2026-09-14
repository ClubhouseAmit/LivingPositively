import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Firebase/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test(
      'should select the Firebase apps registered for production stores',
      () {
        expect(
          DefaultFirebaseOptions.android.appId,
          '1:37967917693:android:e4e96bf355e8cff9faf714',
        );
        expect(
          DefaultFirebaseOptions.ios.appId,
          '1:37967917693:ios:88e13cae59c4020cfaf714',
        );
        expect(
          DefaultFirebaseOptions.ios.iosBundleId,
          'com.clubhouse.livingpositively',
        );
      },
    );
  });
}
