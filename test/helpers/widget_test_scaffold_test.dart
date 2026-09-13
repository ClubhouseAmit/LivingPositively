import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'widget_test_scaffold.dart';

void main() {
  tearDown(() => GetIt.instance.reset());

  test('registerTestServices registers the app navigator key', () {
    registerTestServices();

    expect(GetIt.instance.isRegistered<GlobalKey<NavigatorState>>(), isTrue);
  });
}
