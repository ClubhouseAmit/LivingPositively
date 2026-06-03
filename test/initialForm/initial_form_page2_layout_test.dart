import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/initialForm/form.dart';
import 'package:mazilon/initialForm/initialFormPage1.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
    user.disclaimerSigned = true;
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('personal-info onboarding keeps controls above progress dots', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      InitialFormProgressIndicator(
        phonePageData: _phoneData(),
        changeLocale: (_) {},
      ),
      userInformation: user,
      surfaceSize: const Size(390, 844),
      ignoreOverflow: false,
    );

    tester.widget<InitialFormPage1>(find.byType(InitialFormPage1)).next();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(InitialFormPage2), findsOneWidget);

    final continueButton = find.ancestor(
      of: find.text('Continue'),
      matching: find.byType(TextButton),
    );
    expect(continueButton, findsOneWidget);

    final progressDots = find.byType(AnimatedContainer);
    expect(progressDots, findsNWidgets(3));

    final continueBottom = tester.getBottomLeft(continueButton).dy;
    final firstDotTop = tester.getTopLeft(progressDots.first).dy;
    expect(continueBottom, lessThan(firstDotTop - 8));

    final titleHeight = tester
        .getSize(find.text("Let's get to know you!"))
        .height;
    expect(titleHeight, lessThanOrEqualTo(72));

    final nameField = find.byType(TextField).first;
    final nameFieldHeight = tester.getSize(nameField).height;
    expect(nameFieldHeight, greaterThanOrEqualTo(48));

    final nameFieldWidth = tester.getSize(nameField).width;
    final continueButtonWidth = tester.getSize(continueButton).width;
    expect(continueButtonWidth, moreOrLessEquals(nameFieldWidth, epsilon: 1));

    final nicknameHintBottom = tester
        .getBottomLeft(find.text('(feel free to use a nickname)'))
        .dy;
    final nameFieldTop = tester.getTopLeft(nameField).dy;
    expect(nameFieldTop - nicknameHintBottom, greaterThanOrEqualTo(6));
  });
}
