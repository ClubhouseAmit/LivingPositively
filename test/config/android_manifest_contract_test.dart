import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidManifest', () {
    test('should declare SMS composer package visibility', () async {
      final manifest = await File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsString();

      expect(
        manifest,
        contains('<action android:name="android.intent.action.SENDTO" />'),
      );
      expect(manifest, contains('<data android:scheme="smsto" />'));
    });
  });
}
