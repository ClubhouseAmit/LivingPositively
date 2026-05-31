import 'package:flutter_test/flutter_test.dart';
import 'aboutTest.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Test Matzilon logo widget exists', (WidgetTester tester) async {
    await tester.pumpWidget(About());
    expect(find.byKey(Key('MatzilonLogo')), findsOneWidget);
  });

  testWidgets('Test social Hub logo widget exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(About());
    expect(find.byKey(Key('aboutPageSocialHubLogo')), findsOneWidget);
  });
}
