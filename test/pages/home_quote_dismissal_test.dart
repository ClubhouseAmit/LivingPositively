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

  testWidgets('quote dismissed snackbar disappears on its own', (
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

    await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
    await tester.pump();

    expect(find.text('Quote dismissed.'), findsOneWidget);

    // A SnackBarAction ("Undo") makes SnackBar.persist default to true,
    // which keeps the message on screen forever unless it's explicitly
    // set back to false. Advance well past the default 4s duration plus
    // the hide animation to make sure it's gone on its own.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Quote dismissed.'), findsNothing);
  });
}
