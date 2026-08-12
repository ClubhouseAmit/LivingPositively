import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/MainPageHelpers/components/reminders_section.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

import '../helpers/widget_test_scaffold.dart';

class _DelayedMemoryService implements PersistentMemoryService {
  final Completer<dynamic> completer;
  final FakePersistentMemoryService fallback;
  _DelayedMemoryService(this.completer, this.fallback);

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (key == 'customReminder') {
      return completer.future;
    }
    return fallback.getItem(key, type);
  }

  @override
  Future<void> setItem(String key, PersistentMemoryType type, dynamic value) async {
    return fallback.setItem(key, type, value);
  }

  @override
  Future<void> reset() async {
    return fallback.reset();
  }
}

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

Future<T> _onPlatform<T>(
  TargetPlatform platform,
  Future<T> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets(
    'RemindersSectionWidget is shown on Android (supported) with actual data and active edit',
    (WidgetTester tester) async {
      await _onPlatform(TargetPlatform.android, () async {
        final genders = ['male', 'female', 'other'];

        for (final gender in genders) {
          user.gender = gender;
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

          await tester.pumpAndSettle();

          // Verify widget exists
          expect(find.byType(RemindersSectionWidget), findsOneWidget);

          // Verify the expected gender-specific reminder text is displayed
          final remindersWidget = tester.widget<RemindersSectionWidget>(
            find.byType(RemindersSectionWidget),
          );
          final displayedTitle = remindersWidget.reminders.first.title;
          final appLocale = AppLocalizations.of(
            tester.element(find.byType(Home)),
          )!;
          final expectedTexts = [
            appLocale.deepBreathSuggestion(gender),
            appLocale.stretchBodySuggestion(gender),
            appLocale.drinkWaterSuggestion(gender),
            appLocale.shortBreakSuggestion(gender),
            appLocale.lookForwardSuggestion(gender),
          ];

          expect(
            expectedTexts.contains(displayedTitle),
            isTrue,
            reason:
                'Displayed title "$displayedTitle" should be one of the expected motivational texts for gender "$gender": $expectedTexts',
          );

          // Verify the edit button (IconButton) exists and is clickable by tooltip
          final editButtonFinder = find.descendant(
            of: find.byType(RemindersSectionWidget),
            matching: find.byTooltip('Edit entry'),
          );
          expect(editButtonFinder, findsOneWidget);

          await tester.tap(editButtonFinder);
          await tester.pumpAndSettle();

          expect(find.byType(AddForm), findsOneWidget);

          // Pop the dialog to leave a clean state for subsequent iterations
          Navigator.of(tester.element(find.byType(AddForm))).pop();
          await tester.pumpAndSettle();
        }
      });
    },
  );

  testWidgets(
    'Regression test: AddForm does not overwrite loaded customReminder with stale build-time suggestion',
    (WidgetTester tester) async {
      await _onPlatform(TargetPlatform.android, () async {
        user.gender = 'female';

        final completer = Completer<dynamic>();
        final memory = FakePersistentMemoryService();
        final getIt = GetIt.instance;

        if (getIt.isRegistered<PersistentMemoryService>()) {
          await getIt.unregister<PersistentMemoryService>();
        }

        final customMemory = _DelayedMemoryService(completer, memory);
        getIt.registerSingleton<PersistentMemoryService>(customMemory);

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

        await tester.pump(); // Start loadData but don't finish yet

        final editButtonFinder = find.descendant(
          of: find.byType(RemindersSectionWidget),
          matching: find.byTooltip('Edit entry'),
        );
        expect(editButtonFinder, findsOneWidget);

        await tester.tap(editButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(AddForm), findsOneWidget);

        // Complete loading
        completer.complete('Loaded My Custom Reminder');
        await tester.pumpAndSettle();

        // Tap Save
        final saveButtonFinder = find.widgetWithText(TextButton, 'Save');
        expect(saveButtonFinder, findsOneWidget);
        await tester.tap(saveButtonFinder);
        await tester.pumpAndSettle();

        // Dialog should be gone
        expect(find.byType(AddForm), findsNothing);

        // Value must be loaded custom reminder
        final remindersWidget = tester.widget<RemindersSectionWidget>(
          find.byType(RemindersSectionWidget),
        );
        expect(remindersWidget.reminders.first.title, equals('Loaded My Custom Reminder'));
      });
    },
  );
}
