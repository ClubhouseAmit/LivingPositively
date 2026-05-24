import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/AnalyticsService.dart';

import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
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

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  setupLocator();
  await FcmService.initialize();
}

void main() async {
  await initializeApp();

  IncidentLoggerService sentryService = GetIt.instance<IncidentLoggerService>();

  await sentryService.initializeSentry(
    MultiProvider(
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
    ),
  );
}

class MyApp extends StatefulWidget {
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
  @override
  void dispose() {
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

  void _pauseSession() {
    if (_startTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime
        .difference(_startTime!)
        .inSeconds; // Calculate session length

    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent("Session Paused", {
      "duration_seconds": duration,
    });

    _startTime = null; // Reset for next session
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSession(); // App is active
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
    if (!_isInitialized) {
      phonePageData = Provider.of<PhonePageData>(context);
      _isInitialized = true;
    }
    super.didChangeDependencies();
  }

  void changeLocale(String locale) {
    LocaleService localeService = GetIt.instance<LocaleService>();
    PersistentMemoryService service = GetIt.instance<PersistentMemoryService>();

    setState(() {
      localeService.setLocale(locale);
      localeName = localeService.getLocale();
    });
    service.setItem("localeName", PersistentMemoryType.String, locale);
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
      userInfo.updateLocaleName(locale);

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

            IncidentLoggerService loggerService =
                GetIt.instance<IncidentLoggerService>();
            loggerService.captureLog(error, stackTrace: stackTrace);

            // Fallback to Introduction page on error
            widgetNotifier.value = const Center(child: Introduction());
          });
    }

    if (localeName == '') {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
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
