import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hebrew ARB keeps reviewed strings readable in source', () {
    final arbSource = File('lib/l10n/app_he.arb').readAsStringSync();

    expect(
      arbSource,
      contains(
        '"noVideosAvailableForLocale": "אין סרטונים זמינים בשפה שבחרת."',
      ),
    );
    expect(arbSource, contains('"confirmResetTitle": "האם את/ה בטוח/ה?"'));
    expect(
      arbSource,
      contains(
        '"aboutVersionLabel": "גרסת האפליקציה Living Positively: {version}"',
      ),
    );
    expect(RegExp(r'\\u05[0-9A-Fa-f]{2}').hasMatch(arbSource), isFalse);
  });
}
