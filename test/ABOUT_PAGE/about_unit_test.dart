import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'aboutTest.dart';

void main() {
  testWidgets('Test Matzilon logo widget exists', (tester) async {
    await tester.pumpWidget(const About());
    expect(find.byKey(const Key('MatzilonLogo')), findsOneWidget);
  });

  testWidgets('Test social Hub logo widget exists', (
    tester,
  ) async {
    await tester.pumpWidget(const About());
    expect(find.byKey(const Key('aboutPageSocialHubLogo')), findsOneWidget);
  });
}
