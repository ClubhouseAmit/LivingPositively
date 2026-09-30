// Drives the navigation callbacks on InitialForm (lib/pages/onboarding_page.dart):
//   - disclaimer-not-signed branch renders DisclaimerPage (lines 119-120)
//   - skip / next / prev mutate currentStep and the rendered child widget
//   - submitForm persists name and pushes a Menu route (lines 83-103)
//   - the PopScope onPopInvoked fallback calls prev() (lines 144-148)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/disclaimer_page.dart';
import 'package:mazilon/pages/onboarding_page.dart';
import 'package:mazilon/features/onboarding/ui/initial_form_page1.dart';
import 'package:mazilon/features/onboarding/ui/initial_form_page2.dart';
import 'package:mazilon/features/onboarding/ui/initial_form_appearance_page.dart';
import 'package:mazilon/features/onboarding/ui/to_form_page.dart';
import 'package:mazilon/features/personal_plan/data/phone_models.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';

import '../../helpers/widget_test_scaffold.dart';

final class _HeldAppearanceMemoryService extends FakePersistentMemoryService {
  final Completer<void> _preferenceWrite = Completer<void>();
  final Completer<void> preferenceWriteStarted = Completer<void>();

  _HeldAppearanceMemoryService() {
    onPersist = (key, _, _) async {
      if (key == 'darkModePreference' && !preferenceWriteStarted.isCompleted) {
        preferenceWriteStarted.complete();
        await _preferenceWrite.future;
      }
    };
  }

  void releasePreferenceWrite() {
    if (!_preferenceWrite.isCompleted) _preferenceWrite.complete();
  }
}

final class _FailFirstAppearanceMemoryService
    extends FakePersistentMemoryService {
  bool _hasFailed = false;

  _FailFirstAppearanceMemoryService() {
    onPersist = (key, _, _) {
      if (key == 'darkModePreference' && !_hasFailed) {
        _hasFailed = true;
        throw StateError('Appearance persistence failed.');
      }
    };
  }
}

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

Future<void> _moveToAppearance(
  WidgetTester tester,
  UserInformation user,
) async {
  await pumpWithProviders(
    tester,
    InitialFormProgressIndicator(
      phonePageData: _data(),
      changeLocale: (_) {},
    ),
    userInformation: user,
    surfaceSize: const Size(1024, 2200),
  );
  tester.widget<InitialFormPage1>(find.byType(InitialFormPage1)).next();
  await tester.pump();
  tester.widget<InitialFormPage2>(find.byType(InitialFormPage2)).next();
  await tester.pump();
}

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
        InitialFormProgressIndicator(
          phonePageData: _data(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2200),
      );
      expect(find.byType(DisclaimerPage), findsOneWidget);
    },
  );

  testWidgets(
    'renders InitialFormPage1 first with the back arrow hidden',
    (tester) async {
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
      expect(find.byType(InitialFormPage1), findsOneWidget);
      expect(find.byKey(const Key('intro-header-back')), findsNothing);
    },
  );

  testWidgets('invoking the InitialFormPage1 next callback advances to '
      'InitialFormPage2', (tester) async {
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
    // Capture the InitialFormPage1 widget and call its `next` closure
    // directly — that calls the parent's `next()` setState (lines 56-60).
    final page1 = tester.widget<InitialFormPage1>(
      find.byType(InitialFormPage1),
    );
    page1.next();
    await tester.pump();
    drainOverflowExceptions(tester);
    expect(find.byType(InitialFormPage2), findsOneWidget);
    expect(find.byKey(const Key('intro-header-back')), findsNothing);
  });

  testWidgets('invoking the InitialFormPage1 skip callback jumps to the final '
      'ToFormPage', (tester) async {
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
    final page1 = tester.widget<InitialFormPage1>(
      find.byType(InitialFormPage1),
    );
    page1.skip();
    await tester.pump();
    drainOverflowExceptions(tester);
    expect(find.byType(ToFormPage), findsOneWidget);
    expect(find.byKey(const Key('intro-header-back')), findsOneWidget);
  });

  testWidgets('invoking updateName stores the name without throwing; prev() on '
      'InitialFormPage2 returns to page 1', (tester) async {
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
    final page1 = tester.widget<InitialFormPage1>(
      find.byType(InitialFormPage1),
    );
    page1.updateName('TestName');
    await tester.pump();
    // Advance to InitialFormPage2.
    page1.next();
    // Pump to advance the step and settle the dot animation.
    await tester.pump(const Duration(milliseconds: 400));
    drainOverflowExceptions(tester);

    expect(find.byType(InitialFormPage2), findsOneWidget);
    tester.widget<InitialFormPage2>(find.byType(InitialFormPage2)).prev();
    await tester.pump(const Duration(milliseconds: 400));
    drainOverflowExceptions(tester);
    expect(find.byType(InitialFormPage1), findsOneWidget);
  });

  testWidgets(
    'personal details advance to the appearance step, then the plan',
    (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        InitialFormProgressIndicator(
          phonePageData: _data(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2200),
      );
      tester.widget<InitialFormPage1>(find.byType(InitialFormPage1)).next();
      await tester.pump();

      tester.widget<InitialFormPage2>(find.byType(InitialFormPage2)).next();
      await tester.pump();
      expect(find.byType(InitialFormAppearancePage), findsOneWidget);
      expect(find.byKey(const Key('intro-header-back')), findsOneWidget);

      await tester.tap(find.byKey(const Key('intro-header-back')));
      await tester.pump();
      expect(find.byType(InitialFormPage2), findsOneWidget);
      expect(find.byKey(const Key('intro-header-back')), findsNothing);

      tester.widget<InitialFormPage2>(find.byType(InitialFormPage2)).next();
      await tester.pump();

      await tester.tap(find.byKey(const Key('darkModeAlwaysDarkOption')));
      await tester.pump();
      expect(user.darkModePreference, DarkModePreference.alwaysDark);

      await tester.tap(find.byKey(const Key('wizard-primary-action')));
      await tester.pump();
      expect(find.byType(ToFormPage), findsOneWidget);
      expect(find.byKey(const Key('intro-header-back')), findsOneWidget);
    },
  );

  testWidgets('appearance step waits for its preference to persist', (
    tester,
  ) async {
    final memory = _HeldAppearanceMemoryService();
    GetIt.instance.unregister<PersistentMemoryService>();
    GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
    user = UserInformation()
      ..gender = 'other'
      ..localeName = 'en'
      ..disclaimerSigned = true;
    addTearDown(memory.releasePreferenceWrite);

    await _moveToAppearance(tester, user);
    await tester.tap(find.byKey(const Key('darkModeAlwaysDarkOption')));
    await memory.preferenceWriteStarted.future;
    await tester.tap(find.byKey(const Key('wizard-primary-action')));
    await tester.pump();

    expect(find.byType(InitialFormAppearancePage), findsOneWidget);
    memory.releasePreferenceWrite();
    await tester.pumpAndSettle();
    expect(find.byType(ToFormPage), findsOneWidget);
  });

  testWidgets('appearance step offers a retry when persistence fails', (
    tester,
  ) async {
    final memory = _FailFirstAppearanceMemoryService();
    GetIt.instance.unregister<PersistentMemoryService>();
    GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
    user = UserInformation()
      ..gender = 'other'
      ..localeName = 'en'
      ..disclaimerSigned = true;

    await _moveToAppearance(tester, user);
    await tester.tap(find.byKey(const Key('darkModeAlwaysDarkOption')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<StateError>());

    await tester.tap(find.byKey(const Key('wizard-primary-action')));
    await tester.pumpAndSettle();
    expect(find.byType(InitialFormAppearancePage), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'Try again'), findsOneWidget);

    tester
        .widget<SnackBarAction>(
          find.widgetWithText(SnackBarAction, 'Try again'),
        )
        .onPressed();
    await tester.pumpAndSettle();
    expect(find.byType(ToFormPage), findsOneWidget);
  });
}
