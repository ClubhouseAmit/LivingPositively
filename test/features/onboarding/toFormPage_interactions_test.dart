// Drives the wizard primary + skip handlers of ToFormPage:
//   - primary action pushes a FormProgressIndicator route
//   - skip pushes a Menu route via pushAndRemoveUntil

import 'package:flutter/material.dart';
import 'package:mazilon/features/wizard/ui/wizard_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/personal_plan_editor_page.dart';
import 'package:mazilon/pages/onboarding_page.dart';
import 'package:mazilon/features/onboarding/ui/to_form_page.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/features/personal_plan/data/phone_models.dart';
import 'package:mazilon/util/userInformation.dart';

import '../../helpers/widget_test_scaffold.dart';

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

  testWidgets('tapping the next button pushes a FormProgressIndicator', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      wizardStepHarness(
        ToFormPage(
          key: GlobalKey<WizardStepState>(),
          phonePageData: _data(),
          changeLocale: (_) {},
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);

    final button = find.byKey(const Key('wizard-primary-action'));
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(FormProgressIndicator), findsOneWidget);
  });

  testWidgets('tapping the skip button pushes a Menu route', (tester) async {
    await pumpWithProviders(
      tester,
      InitialFormProgressIndicator(
        phonePageData: _data(),
        changeLocale: (_) {},
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 2200),
    );
    await tester.pump();
    drainOverflowExceptions(tester);

    // Jump to the last step (ToFormPage) so we are on the page presenting the questionnaire option.
    final state = tester.state<InitialFormProgressIndicatorState>(
      find.byType(InitialFormProgressIndicator),
    );
    state.skip();
    await tester.pump();
    drainOverflowExceptions(tester);

    final skipButton = find.byKey(const Key('intro-header-skip'));
    expect(skipButton, findsOneWidget);
    await tester.tap(skipButton);
    await tester.pumpAndSettle();

    expect(find.byType(Menu), findsOneWidget);
  });
}
