import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InspirationalQuote uses a minimum height instead of fixed height', () {
    final source = File(
      'lib/util/HomePage/inspirationalQuote.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('height: 120')));
    expect(source, contains('BoxConstraints(minHeight: 120)'));
  });
}
