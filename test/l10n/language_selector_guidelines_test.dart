import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/disclaimerLanguageSelect.dart';

void main() {
  testWidgets('Language selector follows the language guidelines', (
    WidgetTester tester,
  ) async {
    String? selectedLocale;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguageDropDown(
            changeLocale: (String locale) {
              selectedLocale = locale;
            },
          ),
        ),
      ),
    );

    final selector = find.byType(LanguageDropDown);
    final labelStrip = find.descendant(
      of: selector,
      matching: find.byType(Wrap),
    );

    expect(
      find.descendant(of: labelStrip, matching: find.text('English')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: labelStrip, matching: find.text('עברית')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: labelStrip, matching: find.text('العربية')),
      findsOneWidget,
    );

    final option = find.text('العربية');
    expect(option, findsOneWidget);

    await tester.tap(option);
    await tester.pumpAndSettle();

    expect(selectedLocale, 'ar');
  });
}
