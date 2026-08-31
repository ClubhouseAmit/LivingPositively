import 'package:auto_size_text/auto_size_text.dart';
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
      expect(find.byType(Text), findsNWidgets(3));
      expect(find.byType(AutoSizeText), findsNothing);

      await tester.tap(find.byKey(const Key('moodMedicineHomeInsights')));
      expect(pressed, isTrue);
    });

    testWidgets('should disable the action when Mood Medicine is unavailable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 600,
          title: 'Mood Medicine',
          subtitle: 'Track how you feel',
          actionLabel: 'View insights',
          isAvailable: false,
        ),
      );

      final TextButton action = tester.widget<TextButton>(
        find.byKey(const Key('moodMedicineHomeInsights')),
      );
      expect(action.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should stack the action without overflow in English and Hebrew',
      (WidgetTester tester) async {
        for (final (
              Locale locale,
              TextDirection direction,
              String title,
              String subtitle,
              String actionLabel,
            )
            in <(Locale, TextDirection, String, String, String)>[
              (
                const Locale('en'),
                TextDirection.ltr,
                'Mood Medicine',
                'Track how you feel',
                'View insights',
              ),
              (
                const Locale('he'),
                TextDirection.rtl,
                'מעקב מצב רוח',
                'עקבו אחר מצב הרוח שלכם',
                'הצגת תובנות',
              ),
            ]) {
          await tester.pumpWidget(
            _harness(
              width: 320,
              locale: locale,
              direction: direction,
              title: title,
              subtitle: subtitle,
              actionLabel: actionLabel,
            ),
          );

          final Finder action = find.byKey(
            const Key('moodMedicineHomeInsights'),
          );
          final Finder subtitleText = find.text(subtitle);
          expect(action, findsOneWidget);
          expect(
            tester.getTopLeft(action).dy,
            greaterThanOrEqualTo(tester.getBottomRight(subtitleText).dy),
          );
          expect(tester.getBottomRight(action).dx, lessThanOrEqualTo(320));
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('should stack the action for enlarged text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 600,
          textScaler: TextScaler.linear(2),
          title: 'Mood Medicine',
          subtitle: 'Track how you feel',
          actionLabel: 'View insights',
        ),
      );

      expect(
        tester.getTopLeft(find.byKey(const Key('moodMedicineHomeInsights'))).dy,
        greaterThanOrEqualTo(
          tester.getBottomRight(find.text('Track how you feel')).dy,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should wrap long localized labels without overflow in both layouts',
      (WidgetTester tester) async {
        const String longEnglishLabel =
            'View detailed mood and activity insights for your history';
        const String longHebrewLabel =
            'הצגת תובנות מפורטות על מצב הרוח והפעילויות לאורך ההיסטוריה';

        for (final (
              double width,
              Locale locale,
              TextDirection direction,
              String actionLabel,
            )
            in <(double, Locale, TextDirection, String)>[
              (320, const Locale('en'), TextDirection.ltr, longEnglishLabel),
              (600, const Locale('he'), TextDirection.rtl, longHebrewLabel),
            ]) {
          await tester.pumpWidget(
            _harness(
              width: width,
              locale: locale,
              direction: direction,
              title: 'Mood Medicine',
              subtitle: 'Track how you feel',
              actionLabel: actionLabel,
            ),
          );

          final Finder action = find.byKey(
            const Key('moodMedicineHomeInsights'),
          );
          expect(tester.getBottomRight(action).dx, lessThanOrEqualTo(width));
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}

Widget _harness({
  required double width,
  Locale locale = const Locale('en'),
  TextDirection direction = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  required String title,
  required String subtitle,
  required String actionLabel,
  bool isAvailable = true,
}) {
  return MaterialApp(
    locale: locale,
    home: Scaffold(
      body: Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: SizedBox(
            width: width,
            child: MoodMedicineHomeInsightsSection(
              title: title,
              subtitle: subtitle,
              actionLabel: actionLabel,
              isAvailable: isAvailable,
              onPressed: () {},
            ),
          ),
        ),
      ),
    ),
  );
}
