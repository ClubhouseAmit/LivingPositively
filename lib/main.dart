import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/l10n/app_localizations.dart';
//testing:
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/pages/SignIn_Pages/introduction.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';
import 'package:mazilon/util/Firebase/firebase_options.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/async/async_state_view.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sentry/sentry.dart';
import 'package:upgrader/upgrader.dart';
import 'package:workmanager/workmanager.dart';

const _backgroundWorkerSentryDsn = String.fromEnvironment('SENTRY_DSN');

List<String> checkboxCollectionNames = [
  'PersonalPlan-DifficultEvents',
  'PersonalPlan-MakeSafer',
  'PersonalPlan-FeelBetter',
  'PersonalPlan-Distractions',
  // Add the new table name
];

@pragma(
  'vm:entry-point',
) // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (_backgroundWorkerSentryDsn.isNotEmpty && !Sentry.isEnabled) {
        await Sentry.init(
          (options) => options.dsn = _backgroundWorkerSentryDsn,
        );
      }
      if (inputData == null ||
          !inputData.containsKey('text') ||
          !inputData.containsKey('timeHour') ||
          !inputData.containsKey('timeMinute') ||
          !inputData.containsKey('id')) {
        throw ArgumentError('Invalid input data for notification');
      }
      final number = Random().nextInt(inputData['text'].length);
      await NotificationsService.init();
      await NotificationsService.cancelNotifications(null);
      final calculatedTime = NotificationsService.calculateTime(
        inputData['timeHour'],
        inputData['timeMinute'],
      ); // Calculate the time for the notification
      await NotificationsService.scheduleNotification(
        calculatedTime,
        inputData['id'],
        inputData['text'][number],
      );
      await recordReminderDebugEvent(
        status: reminderDebugStatusSuccess,
        task: task,
      );
      return true;
    } catch (error, stackTrace) {
      try {
        await Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) => scope.setContexts('inputData', inputData),
        );
      } catch (_) {}
      await recordReminderDebugEvent(
        status: reminderDebugStatusFailure,
        task: task,
        error: error.toString(),
      );
      return false;
    }
  });
}

Future<void> refreshReminderForLocaleChange({
  required bool remindersSupported,
  required Future<void> Function() initializeNotifications,
  required Future<void> Function() updateNotifications,
}) async {
  if (!remindersSupported) {
    return;
  }

  await initializeNotifications();
  await updateNotifications();
}

// Phase 10B (ADR-005 § B): `firebaseInitializer` is a dependency-injection
// seam used only by tests (`integration_test/bootstrap_full_test.dart`).
// Production callers (`bootstrapApp` below) omit it and accept the default
// `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
// — behavior-preserving by construction.
Future<void> initializeApp({
  Future<void> Function()? firebaseInitializer,
  void Function()? locatorSetup,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await (firebaseInitializer ??
      () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ))();

  (locatorSetup ?? setupLocator)();
}

/// Test seam for `main()`. Performs platform binding + Firebase init +
/// service-locator setup + (on non-web) Workmanager init, then returns the
/// root widget tree. `main()` only adds the `IncidentLoggerService.
/// initializeSentry(...)` call (which itself calls `runApp`); a test that
/// calls `bootstrapApp()` directly can pump the returned widget through the
/// test binding without going through `runApp`.
///
/// Named parameters are dependency-injection seams used by
/// `integration_test/bootstrap_full_test.dart`. Production callers (`main()`
/// below) omit them and accept defaults that exactly match the previous
/// pre-extraction body — behavior-preserving by construction.
///
/// Per ADR-005 § B, this extraction is the **fourth sanctioned production-
/// code exception** to the no-production-changes guard rail of the coverage
/// initiative, alongside:
///   1. ADR-001 Round 1 — `firestore` named-param injection on 14 helpers
///      in `firebase_functions.dart`.
///   2. ADR-002 PR #266 — `@visibleForTesting
///      NotificationsService.resetForTest()`.
///   3. ADR-004 Round 9 — `firestore` injection extended to 29 more helpers.
/// All four share the same shape: narrow, mechanical, behaviour-preserving
/// for production paths.
Future<Widget> bootstrapApp({
  Future<void> Function()? firebaseInitializer,
  void Function()? locatorSetup,
  void Function()? workmanagerInitializer,
}) async {
  await initializeApp(
    firebaseInitializer: firebaseInitializer,
    locatorSetup: locatorSetup,
  );

  // Initialize Workmanager only on mobile platforms (not web). Preserves the
  // fire-and-forget shape of the original `main()` — `Workmanager().initialize`
  // returns `Future<void>` but is intentionally not awaited so the rest of
  // bootstrap can proceed in parallel.
  if (!kIsWeb) {
    (workmanagerInitializer ??
        () {
          Workmanager().initialize(callbackDispatcher);
        })();
  }

  return MultiProvider(
    providers: [
      for (int i = 0; i < checkboxCollectionNames.length; i++)
        // Initialize the checkbox models
        // Initialize the phonePageData provider
        ChangeNotifierProvider(
          create: (context) => PhonePageData(
            key: 'PhonePage',
            phoneNames: [],
            phoneNumbers: [],
            header: '', // Blank for unknown field
            subTitle: '', // Blank for unknown field
            midTitle: '', // Blank for unknown field
            phoneNameTitle: '', // Blank for unknown field
            phoneNumberTitle: '', // Blank for unknown field
            savedPhoneNames: [], // Assuming empty list for unknown
            savedPhoneNumbers: [], // Assuming empty list for unknown
            phoneDescription: [], // Assuming empty list for unknown
          )..loadItemsFromPrefs(), // Initialize phonePageData
        ),

      // Initialize the APP information provider
      ChangeNotifierProvider(create: (context) => AppInformation()),
      // Initialize the User information provider
      ChangeNotifierProvider(create: (context) => UserInformation()),
    ],
    child: const MyApp(),
  );
}

void main() async {
  final app = await bootstrapApp();
  final sentryService =
      GetIt.instance<IncidentLoggerService>();
  await sentryService.initializeSentry(app);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Mixpanel mixpanel;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool enteredBefore = true;
  String localeName = '';
  bool _initializationStarted = false; // Add this flag

  bool _isInitialized = false;
  List<String> phonePageCollectionNames = ['PersonalPlan-PhonesPage'];
  List<String> textCollectionNames = [];
  late Map<String, dynamic>
  personalPlanPhonesPageData; // Store the new table data
  late PhonePageData phonePageData;
  late Future<void> loadCollectionsFuture;
  late Future<Widget> futureWidget;
  List<String> homeTitles = [];

  AppInformation appInfo = AppInformation();

  bool hasFilled = false;
  DateTime? _startTime;
  Timer? _themeScheduleTimer;
  UserInformation? _themeUserInformation;
  DarkModePreference? _observedDarkModePreference;
  int? _observedDarkModeStartHour;
  int? _observedDarkModeStartMinute;
  int? _observedDarkModeEndHour;
  int? _observedDarkModeEndMinute;

  @override
  void dispose() {
    _themeScheduleTimer?.cancel();
    _themeUserInformation?.removeListener(_handleThemeSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _endSession(); // Ensure session ends when widget is disposed
    super.dispose();
  }

  void _startSession() {
    final mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent('Session started');
    _startTime = DateTime.now(); // Store session start time
  }

  void _endSession() {
    if (_startTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime
        .difference(_startTime!)
        .inSeconds; // Calculate session length

    final mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent('Session Ended', {'duration_seconds': duration});

    _startTime = null; // Reset for next session
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSession(); // App is active
      _refreshThemeSchedule(force: true);
      if (mounted) {
        setState(() {});
      }
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _endSession(); // App is inactive or closed
    }
  }

  Future<void> getHasFilled() async {
    try {
      final service =
          GetIt.instance<
            PersistentMemoryService
          >(); // Get the persistent memory service instance

      final hasFilledValue =
          await service.getItem('hasFilled', PersistentMemoryType.Bool) ??
          false;
      setState(() {
        hasFilled = hasFilledValue;
      });
    } catch (e) {
      // Set default value on error
      setState(() {
        hasFilled = false;
      });
    }
  }

  Future<void> setLocale() async {
    try {
      final localeService = GetIt.instance<LocaleService>();

      final service =
          GetIt.instance<
            PersistentMemoryService
          >(); // Get the persistent memory service instance

      final String? prefsLocale = await service.getItem(
        'localeName',
        PersistentMemoryType.String,
      );

      setState(() {
        localeService.setLocale(prefsLocale != '' ? prefsLocale! : 'en');
        localeName = localeService.getLocale();
      });
    } catch (e) {
      // Set default locale on error
      final localeService = GetIt.instance<LocaleService>();
      setState(() {
        localeService.setLocale('en');
        localeName = 'en';
      });
    }
  }

  Future<void> loadFirstTime() async {
    try {
      final service =
          GetIt.instance<
            PersistentMemoryService
          >(); // Get the persistent memory service instance

      final enteredBeforeValue =
          await service.getItem('enteredBefore', PersistentMemoryType.Bool) ??
          true;

      setState(() {
        enteredBefore = enteredBeforeValue;
      });
    } catch (e) {
      // Set default value on error
      setState(() {
        enteredBefore = false;
      });
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    final mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.init();
    getHasFilled();
    loadFirstTime();
    super.initState();
    _startSession();
    //initMixpanel();
    personalPlanPhonesPageData = {
      'phoneName': <String>[],
      'emergencyPhones': <String>[],
      'phoneDescription': <String>[],
    }; // Initialize personalPlanPhonesPageData
  }

  Future<void> initMixpanel() async {
    // Once you've called this method once, you can access `mixpanel` throughout the rest of your application.
    mixpanel = await Mixpanel.init(
      'e38d39b73bc076129d0a5390af41fc24',
      trackAutomaticEvents: false,
    );
  }

  @override
  void didChangeDependencies() {
    final themeUserInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    if (!identical(_themeUserInformation, themeUserInformation)) {
      _themeUserInformation?.removeListener(_handleThemeSettingsChanged);
      _themeUserInformation = themeUserInformation;
      _themeUserInformation!.addListener(_handleThemeSettingsChanged);
      _refreshThemeSchedule(force: true);
    }
    if (!_isInitialized) {
      phonePageData = Provider.of<PhonePageData>(context);
      _isInitialized = true;
    }
    super.didChangeDependencies();
  }

  bool _hasThemeSettingsChanged(UserInformation userInfo) {
    return _observedDarkModePreference != userInfo.darkModePreference ||
        _observedDarkModeStartHour != userInfo.darkModeStartHour ||
        _observedDarkModeStartMinute != userInfo.darkModeStartMinute ||
        _observedDarkModeEndHour != userInfo.darkModeEndHour ||
        _observedDarkModeEndMinute != userInfo.darkModeEndMinute;
  }

  void _handleThemeSettingsChanged() {
    final userInfo = _themeUserInformation;
    if (userInfo == null || !_hasThemeSettingsChanged(userInfo)) {
      return;
    }

    _refreshThemeSchedule(force: true);
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshThemeSchedule({bool force = false}) {
    final userInfo = _themeUserInformation;
    if (userInfo == null || (!force && !_hasThemeSettingsChanged(userInfo))) {
      return;
    }

    _observedDarkModePreference = userInfo.darkModePreference;
    _observedDarkModeStartHour = userInfo.darkModeStartHour;
    _observedDarkModeStartMinute = userInfo.darkModeStartMinute;
    _observedDarkModeEndHour = userInfo.darkModeEndHour;
    _observedDarkModeEndMinute = userInfo.darkModeEndMinute;

    _themeScheduleTimer?.cancel();
    _themeScheduleTimer = null;

    final nextBoundary = userInfo.nextDarkModeBoundaryAfter(DateTime.now());
    if (nextBoundary == null) {
      return;
    }

    _themeScheduleTimer = Timer(nextBoundary.difference(DateTime.now()), () {
      if (!mounted) {
        return;
      }
      _refreshThemeSchedule(force: true);
      setState(() {});
    });
  }

  void changeLocale(String locale) {
    final localeService = GetIt.instance<LocaleService>();
    final service = GetIt.instance<PersistentMemoryService>();

    setState(() {
      localeService.setLocale(locale);
      localeName = localeService.getLocale();
    });
    service.setItem('localeName', PersistentMemoryType.String, locale);
    Provider.of<UserInformation>(
      context,
      listen: false,
    ).updateLocaleName(locale);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentContext = _navigatorKey.currentContext;
      if (currentContext == null) return;
      final appLocale = AppLocalizations.of(currentContext);
      if (appLocale == null) return;

      final userInfo = Provider.of<UserInformation>(
        currentContext,
        listen: false,
      );
      await refreshReminderForLocaleChange(
        remindersSupported: NotificationsService.supportsReminderSettings(),
        initializeNotifications: NotificationsService.init,
        updateNotifications: () =>
            NotificationsService.updateNotification(userInfo, appLocale),
      );
    });
  }

  ValueNotifier<Widget?> widgetNotifier = ValueNotifier<Widget?>(null);

  //app start this runs:
  @override
  Widget build(BuildContext context) {
    final localeService = GetIt.instance<LocaleService>();
    final appInfoProvider = Provider.of<AppInformation>(context, listen: false);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final themeMode = userInfoProvider.usesDarkModeAt(DateTime.now())
        ? ThemeMode.dark
        : ThemeMode.light;

    if (widgetNotifier.value == null && !_initializationStarted) {
      _initializationStarted = true; // Prevent multiple initialization attempts

      Future.wait([
            //load from DB or from json:
            loadAppInformation(appInfoProvider),
            loadUserInformation(userInfoProvider, localeService.getLocale()),
            setLocale(),
          ])
          .then((_) {
            //initialize which widget will run first:
            widgetNotifier.value = FirstPage(
              firsttime: !enteredBefore,
              hasFilled: hasFilled,
              changeLocale: changeLocale,
              phonePageData: phonePageData,
            );
          })
          .catchError((error, stackTrace) {
            // Handle errors and provide a fallback widget

            final loggerService =
                GetIt.instance<IncidentLoggerService>();
            loggerService.captureLog(error, stackTrace: stackTrace);

            // Fallback to Introduction page on error
            widgetNotifier.value = const Center(child: Introduction());
          });
    }

    if (localeName == '') {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: themeMode,
        // Phase E (ADR-005 §Decision step 5): this boot spinner renders
        // before the localization delegates are wired, so it passes an
        // explicit English label rather than reading AppLocalizations.
        home: const Scaffold(
          body: AsyncLoadingIndicator(semanticLabel: 'Loading'),
        ),
      );
    }

    return ScreenUtilInit(
      builder: (context, child) => MaterialApp(
        navigatorKey: _navigatorKey,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(localeService.getLocale()),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        debugShowCheckedModeBanner: false,
        // Semantic tokens are layered onto Material 2. The user's dark-mode
        // preference selects the matching accessible palette below.
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: themeMode,
        home: UpgradeAlert(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: ValueListenableBuilder<Widget?>(
              valueListenable: widgetNotifier,
              builder: (context, widget, child) {
                //widget running on success or intro in first login:
                return widget ?? const Center(child: Introduction());
              },
            ),
          ),
        ),
      ),
    );
  }
}
