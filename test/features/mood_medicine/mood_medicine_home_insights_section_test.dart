import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_home_insights_section.dart';

void main() {
  group('MoodMedicineHomeInsightsSection', () {
    testWidgets('should render its content and invoke the action', (
      WidgetTester tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoodMedicineHomeInsightsSection(
              title: 'Mood Medicine',
              subtitle: 'Track how you feel',
              actionLabel: 'View insights',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Mood Medicine'), findsOneWidget);
      expect(find.text('Track how you feel'), findsOneWidget);
      expect(find.text('View insights'), findsOneWidget);

      await tester.tap(find.byKey(const Key('moodMedicineHomeInsights')));
      expect(pressed, isTrue);
    });
  });
}
