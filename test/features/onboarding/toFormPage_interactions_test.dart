// Drives the wizard primary + fill-later handlers of ToFormPage:
//   - primary action pushes a FormProgressIndicator route
//   - fill later reuses the onboarding skip path to push a Menu route

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/onboarding/ui/to_form_page.dart';
import 'package:mazilon/features/personal_plan/data/phone_models.dart';
import 'package:mazilon/features/wizard/ui/wizard_step.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/pages/onboarding_page.dart';
import 'package:mazilon/pages/personal_plan_editor_page.dart';
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
  late TestServiceLocators services;

  setUp(() {
    services = registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
    user.disclaimerSigned = true;
  });

  tearDown(() {
    resetTestServices();
  });

  group('ToFormPage', () {
    testWidgets('should open the questionnaire from the primary action', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        wizardStepHarness(
          ToFormPage(
            key: GlobalKey<WizardStepState>(),
            phonePageData: _data(),
            changeLocale: (_) {},
            fillLater: () {},
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

    testWidgets('should open the menu from the fill later action', (
      tester,
    ) async {
      services.memory.store['hasFilled'] = true;
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

      final state = tester.state<InitialFormProgressIndicatorState>(
        find.byType(InitialFormProgressIndicator),
      );
      state.skip();
      await tester.pump();
      drainOverflowExceptions(tester);

      final fillLaterButton = find.byKey(
        const Key('wizard-secondary-action'),
      );
      expect(fillLaterButton, findsOneWidget);
      expect(find.text('Fill Later'), findsOneWidget);
      await tester.tap(fillLaterButton);
      await tester.pumpAndSettle();

      expect(find.byType(Menu), findsOneWidget);
      expect(tester.widget<Menu>(find.byType(Menu)).hasFilled, isTrue);
    });

    testWidgets('should render every gendered Hebrew and Arabic label', (
      tester,
    ) async {
      const cases =
          <({String locale, String gender, bool binary, String label})>[
            (locale: 'he', gender: 'male', binary: false, label: 'מלא אחר כך'),
            (
              locale: 'he',
              gender: 'female',
              binary: false,
              label: 'מלאי אחר כך',
            ),
            (locale: 'he', gender: '', binary: true, label: 'מלא.י אחר כך'),
            (locale: 'ar', gender: 'male', binary: false, label: 'املأ لاحقًا'),
            (
              locale: 'ar',
              gender: 'female',
              binary: false,
              label: 'املئي لاحقًا',
            ),
            (locale: 'ar', gender: '', binary: true, label: 'املأ/ي لاحقًا'),
          ];

      for (final testCase in cases) {
        user.gender = testCase.gender;
        user.binary = testCase.binary;
        await pumpWithProviders(
          tester,
          wizardStepHarness(
            ToFormPage(
              key: GlobalKey<WizardStepState>(),
              phonePageData: _data(),
              changeLocale: (_) {},
              fillLater: () {},
            ),
          ),
          userInformation: user,
          locale: Locale(testCase.locale),
          surfaceSize: const Size(1024, 2200),
        );

        expect(find.text(testCase.label), findsOneWidget);
      }
    });
  });
}
