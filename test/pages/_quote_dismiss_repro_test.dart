import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
  key: 'phonePageData',
  header: 'header',
  subTitle: 'subTitle',
  midTitle: 'midTitle',
  phoneNameTitle: 'phoneNameTitle',
  phoneNumberTitle: 'phoneNumberTitle',
  phoneNames: const [],
  phoneNumbers: const [],
  savedPhoneNames: const [],
  savedPhoneNumbers: const [],
  phoneDescription: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
    user.makeSafer = ['Call Alex'];
    user.difficultEvents = ['Argument'];
    user.feelBetter = ['Music'];
    user.distractions = ['Puzzle'];
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('quote dismissed snackbar disappears after its duration', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      Home(
        phonePageData: _phoneData(),
        changeCurrentIndex: (BuildContext context, PagesCode code) {},
        changeLocale: (_) {},
        openMainMenu: (_) {},
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );

    final closeButton = find.widgetWithIcon(IconButton, Icons.close);
    expect(closeButton, findsOneWidget);

    await tester.tap(closeButton);
    await tester.pump();

    expect(find.text('Quote dismissed.'), findsOneWidget);

    // Advance well past the default SnackBar duration (4s) plus the
    // hide animation.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 1));
      // ignore: avoid_print
      print('t+${i + 1}s snackbars: ${find.text('Quote dismissed.').evaluate().length}');
    }

    expect(find.text('Quote dismissed.'), findsNothing);
  });
}
