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
    // The view is driven directly as well as via surfaceSize: ScreenUtil reads
    // the window, which setSurfaceSize does not change, so without this `.sp`
    // sizes scale against the default 800px test window instead of 390 and the
    // page lays out more than twice as tall as it does on the device.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

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

    // Ceiling is two lines at the Figma title spec (26px, line-height 1.3,
    // node 1660:2281) scaled to this 390-wide view: 2 x 26 x 1.3 x 390/360 =
    // 73.2. The English string wraps to two lines where the Hebrew fits on
    // one. The previous ceiling of 72 was derived from the old 30px
    // AutoSizeText, which shrank to fit rather than honouring a design size.
    final titleHeight = tester
        .getSize(find.text("Let's get to know you!"))
        .height;
    expect(titleHeight, lessThanOrEqualTo(76));

    final nameField = find.byType(TextField).first;
    final nameFieldHeight = tester.getSize(nameField).height;
    expect(nameFieldHeight, greaterThanOrEqualTo(48));

    final nameFieldWidth = tester.getSize(nameField).width;
    final continueButtonWidth = tester.getSize(continueButton).width;
    expect(continueButtonWidth, moreOrLessEquals(nameFieldWidth, epsilon: 1));

    // The name label is one Text at a single size (Figma node 1660:2294). It
    // used to be split on "(" and rendered at 20px and 18px, so this assertion
    // used to target the "(feel free to use a nickname)" fragment on its own.
    final nameLabelBottom = tester
        .getBottomLeft(
          find.text('What should we call you?(feel free to use a nickname)'),
        )
        .dy;
    final nameFieldTop = tester.getTopLeft(nameField).dy;
    expect(nameFieldTop - nameLabelBottom, greaterThanOrEqualTo(6));
  });
}
