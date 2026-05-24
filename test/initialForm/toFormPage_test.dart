// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/menu.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mazilon/initialForm/toFormPage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mockito/mockito.dart';

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
  } catch (e) {}

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
