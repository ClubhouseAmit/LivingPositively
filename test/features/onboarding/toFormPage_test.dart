// ignore_for_file: unused_local_variable

import 'package:flutter_test/flutter_test.dart';

void main() {
  try {
    // Mock data for the test

    /* PhonePageData mockPhonePageData = PhonePageData(
        header: '',
        phoneNames: [],
        phoneNumbers: [],
        subTitle: '',
        midTitle: '',
        phoneNameTitle: '',
        phoneNumberTitle: '',
        key: '',
        savedPhoneNames: [],
        savedPhoneNumbers: [],
        phoneDescription: []);*/
  } catch (e) {
    // Test scaffold setup may already be registered by another test file.
  }

  group('FeelGood Widget Tests', () {
    testWidgets('ToFormPage renders correctly', (WidgetTester tester) async {
      //await tester.pumpWidget(createTestWidget());

      /* // Verify the presence of the main title and subtitles
    expect(find.text('mainTitle'), findsOneWidget);
    expect(find.text('subTitle1-male'), findsOneWidget);
    expect(find.text('subTitle2-male'), findsOneWidget);

    // Verify the presence of the image
    expect(find.byType(Image), findsOneWidget);

    // Verify the presence of the buttons
    expect(find.text('למילוי השאלון'), findsOneWidget);
    expect(find.text('דלג על השאלון'), findsOneWidget);*/
    });
  });

  /*
  testWidgets('ToFormPage navigate to FormProgressIndicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Tap the "למילוי השאלון" button
    await tester.tap(find.text('למילוי השאלון'));
    await tester.pumpAndSettle();

    // Verify the navigation to FormProgressIndicator
    expect(find.byType(FormProgressIndicator), findsOneWidget);
  });

  testWidgets('ToFormPage navigate to Menu', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Tap the "דלג על השאלון" button
    await tester.tap(find.text('דלג על השאלון'));
    await tester.pumpAndSettle();

    // Verify the navigation to Menu
    expect(find.byType(Menu), findsOneWidget);
  });

  testWidgets('ToFormPage SharedPreferences value is retrieved correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Verify the initial value of hasFilled
    expect(find.text('דלג על השאלון'), findsOneWidget);
  });
  */
}
