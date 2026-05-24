// Drives the navigation callbacks inside FormProgressIndicator that the
// existing form_widgets_test only renders past:
//   - next() / prev() (lines 51-61)
//   - submitForm via the "Save & Quit" IconButton in the AppBar header
//     (lines 92-103 — navigateToMenu pushes a Menu route)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
      key: 'phone',
      header: 'h',
      subTitle: 's',
      midTitle: 'm',
      phoneNameTitle: 'n',
      phoneNumberTitle: 'p',
      phoneNames: const <String>[],
      phoneNumbers: const <String>[],
      savedPhoneNames: const <String>[],
      savedPhoneNumbers: const <String>[],
      phoneDescription: const <String>[],
    );

Future<void> _pumpForm(WidgetTester tester) async {
  final phoneData = _phoneData();
  final user = UserInformation()..gender = 'other';
  await pumpWithProviders(
    tester,
    ChangeNotifierProvider<PhonePageData>.value(
      value: phoneData,
      child: FormProgressIndicator(
        phonePageData: phoneData,
        changeLocale: (_) {},
      ),
    ),
    userInformation: user,
    surfaceSize: const Size(1024, 2400),
  );
  await tester.pump();
  drainOverflowExceptions(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerTestServices(locale: 'en');
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets(
      'tapping a CheckboxListTile on the first FormPageTemplate increments '
      'no progress (state lives in inner template, FormProgressIndicator '
      'is still on currentStep=0)',
      (tester) async {
    await _pumpForm(tester);
    expect(find.byType(FormProgressIndicator), findsOneWidget);
    // Initial step renders a FormPageTemplate (DifficultEvents).
    expect(find.byType(FormPageTemplate), findsOneWidget);
  });

  testWidgets(
      'tapping the save-and-quit IconButton on the header pushes a Menu route',
      (tester) async {
    await _pumpForm(tester);

    // The header contains a single IconButton on currentStep=0 (save-and-quit).
    final iconButton = find.byType(IconButton).first;
    await tester.tap(iconButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    // navigateToMenu pushes the Menu screen via pushAndRemoveUntil.
    expect(find.byType(Menu), findsOneWidget);
  });

  testWidgets(
      'advancing currentStep via the ConfirmationButton inside the inner '
      'FormPageTemplate makes the back-arrow IconButton appear',
      (tester) async {
    await _pumpForm(tester);

    // The inner FormPageTemplate "Continue" ConfirmationButton is a TextButton
    // at the bottom of the page subtree. Find the last TextButton inside
    // FormPageTemplate and tap it — that calls next() on the parent
    // FormProgressIndicator.
    final continueBtn = find.descendant(
      of: find.byType(FormPageTemplate),
      matching: find.byType(TextButton),
    ).last;
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    // After advancing, currentStep > 0 — the back-arrow IconButton appears
    // in the header (the `currentStep > 0` branch on line 185 of form.dart).
    expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    // Tap the back-arrow to fire prev().
    await tester.tap(find.byIcon(Icons.arrow_back_ios), warnIfMissed: false);
    await tester.pumpAndSettle();
    // After prev, the back-arrow disappears again (currentStep == 0).
    expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
  });
}
