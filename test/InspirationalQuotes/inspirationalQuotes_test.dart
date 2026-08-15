import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'InspirationalQuotestest.dart';

import 'package:flutter/material.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  final List<String> mockQuotes = ["Quote 1", "Quote 2", "Quote 3"];
  group('Journal Component Test', () {
    testWidgets('test Inspirational Quotes closing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: InspirationalQuote(quotes: mockQuotes)),
      );
      expect(find.byKey(Key('InspirationalQuote')), findsWidgets);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Verify that the widget is no longer visible
      expect(find.byKey(Key('InspirationalQuote')), findsNothing);
    });
  });
}
