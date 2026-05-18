// Drives the ConfirmationButton onPressed inside PhonePageForm
// (lines 181-185 of lib/form/phonePageform.dart) — saves prefs and
// invokes widget.next.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _data() => PhonePageData(
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
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets(
      'tapping the bottom Continue button (ConfirmationButton) fires '
      'widget.next after saving prefs',
      (tester) async {
    final phone = _data();
    var nextCalls = 0;

    await pumpWithProviders(
      tester,
      ChangeNotifierProvider<PhonePageData>.value(
        value: phone,
        child: PhonePageForm(
          phonePageData: phone,
          next: () => nextCalls++,
          prev: () {},
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 2400),
    );
    await tester.pump();
    drainOverflowExceptions(tester);

    // The page renders one outer TextButton (the ConfirmationButton). Its
    // onPressed is async and routes through phonePageData.loadItemsFromPrefs
    // → saveItemsToPrefs → update() → widget.next.
    final buttons = find.byType(TextButton);
    expect(buttons, findsWidgets);
    await tester.ensureVisible(buttons.last);
    await tester.tap(buttons.last, warnIfMissed: false);
    await tester.pump();
    // Drain microtasks for the chained async helpers.
    await tester.pump(const Duration(milliseconds: 50));

    expect(nextCalls, 1);
  });
}
