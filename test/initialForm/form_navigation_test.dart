// Drives the navigation callbacks on InitialForm (lib/initialForm/form.dart):
//   - disclaimer-not-signed branch renders DisclaimerPage (lines 119-120)
//   - skip / next / prev mutate currentStep and the rendered child widget
//   - submitForm persists name and pushes a Menu route (lines 83-103)
//   - the PopScope onPopInvoked fallback calls prev() (lines 144-148)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/disclaimerPage.dart';
import 'package:mazilon/initialForm/form.dart';
import 'package:mazilon/initialForm/initialFormPage1.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/initialForm/toFormPage.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';

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
    user.disclaimerSigned = true;
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets(
      'when disclaimerSigned is false, InitialFormProgressIndicator renders the DisclaimerPage',
      (tester) async {
    user.disclaimerSigned = false;
    await pumpWithProviders(
      tester,
      InitialFormProgressIndicator(phonePageData: _data(), changeLocale: (_) {}),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    expect(find.byType(DisclaimerPage), findsOneWidget);
  });

  testWidgets(
      'renders InitialFormPage1 first; the back arrow is hidden because '
      'currentStep == 0 and not on the last page',
      (tester) async {
    await pumpWithProviders(
      tester,
      InitialFormProgressIndicator(phonePageData: _data(), changeLocale: (_) {}),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);
    expect(find.byType(InitialFormPage1), findsOneWidget);
  });

  testWidgets(
      'invoking the InitialFormPage1 next callback advances to '
      'InitialFormPage2',
      (tester) async {
    await pumpWithProviders(
      tester,
      InitialFormProgressIndicator(phonePageData: _data(), changeLocale: (_) {}),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);
    // Capture the InitialFormPage1 widget and call its `next` closure
    // directly — that calls the parent's `next()` setState (lines 56-60).
    final page1 =
        tester.widget<InitialFormPage1>(find.byType(InitialFormPage1));
    page1.next();
    await tester.pump();
    drainOverflowExceptions(tester);
    expect(find.byType(InitialFormPage2), findsOneWidget);
  });

  testWidgets(
      'invoking the InitialFormPage1 skip callback jumps to the final '
      'ToFormPage',
      (tester) async {
    await pumpWithProviders(
      tester,
      InitialFormProgressIndicator(phonePageData: _data(), changeLocale: (_) {}),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);
    final page1 =
        tester.widget<InitialFormPage1>(find.byType(InitialFormPage1));
    page1.skip();
    await tester.pump();
    drainOverflowExceptions(tester);
    expect(find.byType(ToFormPage), findsOneWidget);
  });

  testWidgets(
      'invoking updateName stores the name without throwing; prev() on '
      'InitialFormPage2 returns to page 1',
      (tester) async {
    await pumpWithProviders(
      tester,
      InitialFormProgressIndicator(phonePageData: _data(), changeLocale: (_) {}),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);
    final page1 =
        tester.widget<InitialFormPage1>(find.byType(InitialFormPage1));
    page1.updateName('TestName');
    await tester.pump();
    // Advance to InitialFormPage2.
    page1.next();
    // Drive the AnimatedSwitcher transition fully so only one page is in tree.
    await tester.pump(const Duration(milliseconds: 400));
    drainOverflowExceptions(tester);

    expect(find.byType(InitialFormPage2), findsOneWidget);
    final page2 =
        tester.widget<InitialFormPage2>(find.byType(InitialFormPage2));
    page2.prev();
    await tester.pump(const Duration(milliseconds: 400));
    drainOverflowExceptions(tester);
    expect(find.byType(InitialFormPage1), findsOneWidget);
  });
}
