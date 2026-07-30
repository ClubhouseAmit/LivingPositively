import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/UserSettings.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/widget_test_scaffold.dart';

PhonePageData _phonePageData() => PhonePageData(
  key: 'phonePageData',
  header: '',
  subTitle: '',
  midTitle: '',
  phoneNameTitle: '',
  phoneNumberTitle: '',
  phoneNames: const [],
  phoneNumbers: const [],
  savedPhoneNames: const [],
  savedPhoneNumbers: const [],
  phoneDescription: const [],
);

/// Runs the production settings page inside the same theme contract used by
/// MyApp. The app bootstrap itself needs Firebase and Workmanager, which are
/// outside this local preference flow and already covered by bootstrap tests.
Widget _darkModeSettingsHarness(UserInformation userInformation) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInformation),
      ChangeNotifierProvider(create: (_) => AppInformation()),
    ],
    child: Consumer<UserInformation>(
      builder: (context, userInfo, child) {
        return MaterialApp(
          key: const Key('darkModeSettingsTestApp'),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: userInfo.usesDarkModeAt(DateTime.now())
              ? ThemeMode.dark
              : ThemeMode.light,
          home: ScreenUtilInit(
            designSize: const Size(360, 690),
            child: UserSettings(
              username: 'Integration User',
              age: '18-30',
              gender: 'male',
              phonePageData: _phonePageData(),
              changeLocale: (_) {},
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  late SharedPreferences preferences;
  late UserInformation userInformation;

  setUp(() async {
    await GetIt.instance.reset();
    registerTestServices(locale: 'en');
    GetIt.instance.unregister<PersistentMemoryService>();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      SharedPreferencesService(),
    );

    preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    userInformation = UserInformation()..localeName = 'en';
  });

  tearDown(() async {
    await preferences.clear();
    await GetIt.instance.reset();
  });

  testWidgets('smoke: settings starts in light mode and switches to dark', (
    tester,
  ) async {
    await tester.pumpWidget(_darkModeSettingsHarness(userInformation));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('darkModeAlwaysLightOption')), findsOneWidget);
    expect(find.byKey(const Key('darkModeAlwaysDarkOption')), findsOneWidget);
    expect(
      tester
          .widget<MaterialApp>(find.byKey(const Key('darkModeSettingsTestApp')))
          .themeMode,
      ThemeMode.light,
    );
    expect(
      Theme.of(tester.element(find.byType(UserSettings))).brightness,
      Brightness.light,
    );

    final alwaysDarkOption = find.byKey(const Key('darkModeAlwaysDarkOption'));
    await tester.ensureVisible(alwaysDarkOption);
    await tester.tap(alwaysDarkOption, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(userInformation.darkModePreference, DarkModePreference.alwaysDark);
    expect(preferences.getString('darkModePreference'), 'alwaysDark');
    expect(
      tester
          .widget<MaterialApp>(find.byKey(const Key('darkModeSettingsTestApp')))
          .themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.byType(UserSettings))).brightness,
      Brightness.dark,
    );
  });

  testWidgets(
    'end-to-end: sleep schedule persists defaults and exposes time selection',
    (tester) async {
      await tester.pumpWidget(_darkModeSettingsHarness(userInformation));
      await tester.pumpAndSettle();

      final scheduledOption = find.byKey(const Key('darkModeScheduledOption'));
      await tester.ensureVisible(scheduledOption);
      await tester.tap(scheduledOption, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(userInformation.darkModePreference, DarkModePreference.scheduled);
      expect(userInformation.darkModeStartHour, 22);
      expect(userInformation.darkModeStartMinute, 0);
      expect(userInformation.darkModeEndHour, 6);
      expect(userInformation.darkModeEndMinute, 0);
      expect(preferences.getString('darkModePreference'), 'scheduled');
      expect(preferences.getInt('darkModeStartHour'), 22);
      expect(preferences.getInt('darkModeStartMinute'), 0);
      expect(preferences.getInt('darkModeEndHour'), 6);
      expect(preferences.getInt('darkModeEndMinute'), 0);

      final startTimeButton = find.byKey(const Key('darkModeStartTimeButton'));
      await tester.ensureVisible(startTimeButton);
      await tester.tap(startTimeButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);
      final timePickerActions = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextButton),
      );
      expect(timePickerActions, findsNWidgets(2));
      await tester.tap(timePickerActions.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsNothing);
      expect(userInformation.darkModePreference, DarkModePreference.scheduled);
    },
  );
}
