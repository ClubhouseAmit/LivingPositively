import 'dart:async';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/async/async_state_view.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'util/Firebase/firebase_options.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import '/pages/SignIn_Pages/introduction.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/Firebase/firebase_functions.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:upgrader/upgrader.dart';
//testing:
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';

List<String> checkboxCollectionNames = [
  'PersonalPlan-DifficultEvents',
  'PersonalPlan-MakeSafer',
  'PersonalPlan-FeelBetter',
  'PersonalPlan-Distractions',
  // Add the new table name
];

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

/// Defers best-effort FCM startup until the first frame is visible.
void _scheduleFcmInitialization(Future<void> Function()? fcmInitializer) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      _initializeFcmBestEffort(fcmInitializer ?? FcmService.initialize),
    );
  });
}

Future<void> _initializeFcmBestEffort(
  Future<void> Function() initializer,
) async {
  try {
    await Future<void>.sync(initializer);
  } catch (error, stackTrace) {
    debugPrint('[Bootstrap] FCM initialization failed: $error');
    if (!GetIt.instance.isRegistered<IncidentLoggerService>()) return;
    try {
      await GetIt.instance<IncidentLoggerService>().captureLog(
        error,
        stackTrace: stackTrace,
      );
    } catch (loggerError) {
      debugPrint('[Bootstrap] FCM failure reporting failed: $loggerError');
    }
  }
}

/// Test seam for `main()`. Performs platform binding + Firebase init +
/// service-locator setup, then returns the
/// root widget tree. `main()` only adds the `IncidentLoggerService.
/// initializeSentry(...)` call (which itself calls `runApp`); a test that
/// calls `bootstrapApp()` directly can pump the returned widget through the
/// test binding without going through `runApp`.
///
/// Named parameters are dependency-injection seams used by
/// `integration_test/bootstrap_full_test.dart`. Production callers (`main()`
/// below) omit them and accept defaults that exactly match the production
/// collaborators. FCM initialization starts after the first rendered frame.
///
/// Per ADR-005 § B, this extraction is the **fourth sanctioned production-
/// code exception** to the no-production-changes guard rail of the coverage
/// initiative, alongside:
///   1. ADR-001 Round 1 — `firestore` named-param injection on 14 helpers
///      in `firebase_functions.dart`.
///   2. ADR-002 PR #266 — notification-service testability seam.
///   3. ADR-004 Round 9 — `firestore` injection extended to 29 more helpers.
/// All four share the same shape: narrow, mechanical, behaviour-preserving
/// for production paths.
Future<Widget> bootstrapApp({
  Future<void> Function()? firebaseInitializer,
  void Function()? locatorSetup,
  Future<void> Function()? fcmInitializer,
}) async {
  await initializeApp(
    firebaseInitializer: firebaseInitializer,
    locatorSetup: locatorSetup,
  );

  final app = MultiProvider(
    providers: [
      for (int i = 0; i < checkboxCollectionNames.length; i++)
        // Initialize the checkbox models
        // Initialize the phonePageData provider
        ChangeNotifierProvider(
          create: (context) => PhonePageData(
            key: "PhonePage",
            phoneNames: [],
            phoneNumbers: [],
            header: "", // Blank for unknown field
            subTitle: "", // Blank for unknown field
            midTitle: "", // Blank for unknown field
            phoneNameTitle: "", // Blank for unknown field
            phoneNumberTitle: "", // Blank for unknown field
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
    child: MyApp(),
  );
  _scheduleFcmInitialization(fcmInitializer);
  return app;
}

void main() async {
  final app = await bootstrapApp();
  final IncidentLoggerService sentryService =
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
  final GlobalKey<NavigatorState> _navigatorKey =
      GetIt.instance<GlobalKey<NavigatorState>>();
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
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent("Session started");
    _startTime = DateTime.now(); // Store session start time
  }

  void _endSession() {
    if (_startTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime
        .difference(_startTime!)
        .inSeconds; // Calculate session length

    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent("Session Ended", {"duration_seconds": duration});

    _startTime = null; // Reset for next session
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSession(); // App is active
      _refreshThemeSchedule(force: true);
      FcmService.onAppResumed();
      if (mounted) {
        setState(() {});
      }
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _endSession(); // App is inactive or closed
    }
  }

  void getHasFilled() async {
    try {
      PersistentMemoryService service =
          GetIt.instance<
            PersistentMemoryService
          >(); // Get the persistent memory service instance

      var hasFilledValue =
          await service.getItem("hasFilled", PersistentMemoryType.Bool) ??
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
      LocaleService localeService = GetIt.instance<LocaleService>();

      PersistentMemoryService service =
          GetIt.instance<
            PersistentMemoryService
          >(); // Get the persistent memory service instance

      String? prefsLocale = await service.getItem(
        'localeName',
        PersistentMemoryType.String,
      );

      setState(() {
        localeService.setLocale(prefsLocale != "" ? prefsLocale! : 'en');
        localeName = localeService.getLocale();
      });
    } catch (e) {
      // Set default locale on error
      LocaleService localeService = GetIt.instance<LocaleService>();
      setState(() {
        localeService.setLocale('en');
        localeName = 'en';
      });
    }
  }

  void loadFirstTime() async {
    try {
      PersistentMemoryService service =
          GetIt.instance<
            PersistentMemoryService
          >(); // Get the persistent memory service instance

      var enteredBeforeValue =
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
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
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
      "e38d39b73bc076129d0a5390af41fc24",
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
    LocaleService localeService = GetIt.instance<LocaleService>();
    PersistentMemoryService service = GetIt.instance<PersistentMemoryService>();

    setState(() {
      localeService.setLocale(locale);
      localeName = localeService.getLocale();
    });
    unawaited(_saveLocaleInBackground(service, locale));

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    userInfoProvider.updateLocaleName(locale);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentContext = _navigatorKey.currentContext;
      if (currentContext == null) return;
      final userInfo = Provider.of<UserInformation>(
        currentContext,
        listen: false,
      );
      final pref = userInfo.getNotificationPreference('default');
      if (pref != null) {
        await FcmScheduledNotificationService.registerNotification(
          context: currentContext,
          typeId: 'default',
          hour: pref.hour,
          minute: pref.minute,
        );
      }
    });
  }

  Future<void> _saveLocaleInBackground(
    PersistentMemoryService service,
    String locale,
  ) async {
    try {
      await service.setItem("localeName", PersistentMemoryType.String, locale);
    } catch (error, stackTrace) {
      try {
        await GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      } catch (_) {
        // Logging is best effort for this background preference write.
      }
    }
  }

  ValueNotifier<Widget?> widgetNotifier = ValueNotifier<Widget?>(null);

  //app start this runs:
  @override
  Widget build(BuildContext context) {
    LocaleService localeService = GetIt.instance<LocaleService>();
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
            if (!mounted) return;
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

            IncidentLoggerService loggerService =
                GetIt.instance<IncidentLoggerService>();
            loggerService.captureLog(error, stackTrace: stackTrace);

            // Fallback to Introduction page on error
            widgetNotifier.value = Introduction(
              child: Builder(
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'An error occurred during startup.\nPlease try restarting the app.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            );
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
      designSize: Size(360, 690),
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
