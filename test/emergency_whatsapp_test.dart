import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/phone.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Phone/EmergencyPhones.dart';
import 'package:mazilon/util/Phone/emergencyDialogBox.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const _smsComposeChannel = MethodChannel('com.matzilon.mezilon/sms_compose');

class FakePersistentMemoryService implements PersistentMemoryService {
  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    return null;
  }

  @override
  Future<void> reset() async {}

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {}
}

class FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  FakeUrlLauncherPlatform({this.shouldSucceed = true, this.launchError});

  final List<String> launchedUrls = [];
  final bool shouldSucceed;
  final Object? launchError;

  String? get lastLaunchedUrl =>
      launchedUrls.isEmpty ? null : launchedUrls.last;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    return true;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    if (launchError != null) {
      throw launchError!;
    }
    return shouldSucceed;
  }
}

class RecordingFileService implements FileService {
  RecordingFileService({
    List<String>? callLog,
    this.failedResultsRemaining = 0,
    this.exceptionsRemaining = 0,
  }) : callLog = callLog ?? [];

  final List<String> callLog;
  final List<String> sharedMessages = [];
  int failedResultsRemaining;
  int exceptionsRemaining;

  @override
  Future<String?> download(
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat,
    String textDirection,
  ) async => null;

  @override
  Future<void> share(
    String message,
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat,
    String textDirection,
  ) async {}

  @override
  Future<bool> shareTextOnly(String message) async {
    callLog.add('shareTextOnly');
    if (exceptionsRemaining > 0) {
      exceptionsRemaining--;
      throw StateError('shareTextOnly failed');
    }
    if (failedResultsRemaining > 0) {
      failedResultsRemaining--;
      return false;
    }
    sharedMessages.add(message);
    return true;
  }
}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  FakeGeolocatorPlatform({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.requestedPermission,
    this.position,
    this.positionError,
    this.positionCompleter,
    this.serviceEnabledResults,
    List<String>? callLog,
  }) : callLog = callLog ?? [];

  final List<String> callLog;
  final bool serviceEnabled;
  final LocationPermission permission;
  final LocationPermission? requestedPermission;
  final Position? position;
  final Object? positionError;
  final Completer<Position>? positionCompleter;
  final List<bool>? serviceEnabledResults;
  int checkPermissionCalls = 0;
  int requestPermissionCalls = 0;
  int currentPositionCalls = 0;
  int locationServiceEnabledCalls = 0;
  LocationSettings? lastLocationSettings;

  @override
  Future<LocationPermission> checkPermission() async {
    callLog.add('checkPermission');
    checkPermissionCalls++;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    callLog.add('requestPermission');
    requestPermissionCalls++;
    return requestedPermission ?? permission;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    callLog.add('isLocationServiceEnabled');
    locationServiceEnabledCalls++;
    if (serviceEnabledResults != null && serviceEnabledResults!.isNotEmpty) {
      final resultIndex = locationServiceEnabledCalls - 1;
      return serviceEnabledResults![resultIndex < serviceEnabledResults!.length
          ? resultIndex
          : serviceEnabledResults!.length - 1];
    }
    return serviceEnabled;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    callLog.add('getCurrentPosition');
    currentPositionCalls++;
    lastLocationSettings = locationSettings;
    if (positionCompleter != null) {
      return positionCompleter!.future;
    }
    if (positionError != null) {
      return Future<Position>.error(positionError!);
    }
    return Future<Position>.value(position ?? _testPosition());
  }
}

Position _testPosition({
  double latitude = 31.7683,
  double longitude = 35.2137,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

PhonePageData _phonePageDataForLocationShare() {
  return PhonePageData(
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
}

Future<void> _runLocationShareTest(
  FakeGeolocatorPlatform geolocator,
  RecordingFileService fileService, {
  required Future<void> Function() body,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  final originalGeolocator = GeolocatorPlatform.instance;
  try {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      FakePersistentMemoryService(),
    );
    GetIt.instance.registerSingleton<FileService>(fileService);

    GeolocatorPlatform.instance = geolocator;
    debugDefaultTargetPlatformOverride = platform;
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
    GeolocatorPlatform.instance = originalGeolocator;
    await GetIt.instance.reset();
  }
}

Future<void> _tapLocationShare(WidgetTester tester) async {
  await _tapSosAction(tester, const Key('phonePageShareLocationButton'));
}

Future<void> _tapMessageShare(WidgetTester tester) async {
  await _tapSosAction(tester, const Key('phonePageShareMessageButton'));
}

Future<void> _tapSosAction(WidgetTester tester, Key key) async {
  final action = find.byKey(key);
  await tester.ensureVisible(action);
  await tester.tap(action, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _chooseDeliveryOption(WidgetTester tester, String option) async {
  await tester.tap(find.text(option), warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _expectLocationUnavailable(
  WidgetTester tester,
  FakeGeolocatorPlatform geolocator, {
  TargetPlatform platform = TargetPlatform.android,
  Locale locale = const Locale('en', 'US'),
  bool servicesDisabled = false,
  String? expectedNotice,
}) async {
  final fileService = RecordingFileService();
  await _runLocationShareTest(
    geolocator,
    fileService,
    platform: platform,
    body: () async {
      final userInfo = UserInformation(
        gender: 'male',
        location: 'US',
        service: FakePersistentMemoryService(),
      );
      final phonePageData = _phonePageDataForLocationShare();

      await tester.pumpWidget(
        buildPhonePageTestApp(
          userInformation: userInfo,
          appInformation: AppInformation(),
          phonePageData: phonePageData,
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      await _tapLocationShare(tester);

      final localizations = AppLocalizations.of(
        tester.element(find.byType(PhonePage)),
      )!;
      final locationUnavailableDialog = find.byType(AlertDialog);
      expect(fileService.sharedMessages, isEmpty);
      expect(
        find.text(
          expectedNotice ??
              (servicesDisabled
                  ? localizations.sosShareLocationServicesDisabled
                  : localizations.sosShareLocationUnavailable),
        ),
        findsOneWidget,
      );
      expect(locationUnavailableDialog, findsOneWidget);
      for (final deliveryAction in [
        localizations.sosShareMessage,
        localizations.sosDeliveryChooseApp,
        localizations.sosDeliverySendToContact,
        localizations.sosDeliveryOpenMapApp,
        localizations.sosDeliverySms,
        localizations.whatsApp,
      ]) {
        expect(
          find.descendant(
            of: locationUnavailableDialog,
            matching: find.text(deliveryAction),
          ),
          findsNothing,
        );
      }
      expect(
        find.descendant(
          of: locationUnavailableDialog,
          matching: find.text(localizations.asyncRetryButton),
        ),
        findsOneWidget,
      );
    },
  );
}

Widget buildEmergencyDialogTestApp({
  required EmergencyDialogBox dialog,
  required UserInformation userInformation,
  required AppInformation appInformation,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInformation),
      ChangeNotifierProvider<AppInformation>.value(value: appInformation),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      home: ScreenUtilInit(designSize: const Size(360, 690), child: dialog),
    ),
  );
}

Widget buildEmergencyGridTestApp({
  required UserInformation userInformation,
  Locale locale = const Locale('en', 'US'),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInformation),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: locale,
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        child: Scaffold(body: EmergencyPhonesGrid()),
      ),
    ),
  );
}

Widget buildPhonePageTestApp({
  required UserInformation userInformation,
  required AppInformation appInformation,
  required PhonePageData phonePageData,
  Locale locale = const Locale('en', 'US'),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInformation),
      ChangeNotifierProvider<AppInformation>.value(value: appInformation),
      ChangeNotifierProvider<PhonePageData>.value(value: phonePageData),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: locale,
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        child: PhonePage(phonePageData: phonePageData),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hebrewEran = String.fromCharCodes([0x05E2, 0x05E8, 0x0022, 0x05DF]);
  final hebrewSahar = String.fromCharCodes([0x05E1, 0x05D4, 0x0022, 0x05E8]);

  test('Israel emergency numbers include correct Eran phone + WhatsApp', () {
    final israel = countries['israel'];
    expect(israel, isNotNull);

    final eran = israel!.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'ער"ן',
    );

    expect(eran['number'], '1201');
    expect(eran['whatsapp'], true);
    expect(eran['whatsappNumber'], '972528451201');
    expect(eran['description'], 'עזרה ראשונה נפשית');
  });

  test('Israel emergency numbers include Sahar description and website', () {
    final israel = countries['israel'];
    expect(israel, isNotNull);

    final sahar = israel!.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'סה"ר',
    );

    expect(sahar['number'], '0559571399');
    expect(sahar['whatsapp'], true);
    expect(sahar['whatsappNumber'], '972559571399');
    expect(sahar['description'], 'סיוע והקשבה ברשת');
    expect(sahar['link'], 'https://sahar.org.il/');
  });

  test('105 entry uses WhatsApp chat number 972521210105', () {
    final israel = countries['israel'];
    expect(israel, isNotNull);

    final entry105 = israel!.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == '105',
    );

    expect(entry105['number'], '105');
    expect(entry105['whatsapp'], true);
    expect(entry105['whatsappNumber'], '972521210105');
  });

  test('Elem support uses the requested WhatsApp number and website', () {
    expect(elemSupportOption['name'], 'Elem עלם');
    expect(elemSupportOption['number'], '0546786776');
    expect(elemSupportOption['whatsappNumber'], '972546786776');
    expect(
      elemSupportOption['number'],
      isNot(elemSupportOption['whatsappNumber']),
    );
    expect(elemSupportOption['link'], 'https://yelem.org.il/');
    expect(elemSupportOption['whatsapp'], true);
    expect(elemSupportOption['canCall'], false);
  });

  testWidgets('Elem support is shown only to under-18 users', (tester) async {
    await tester.pumpWidget(
      buildEmergencyGridTestApp(
        userInformation: UserInformation(
          age: '18-',
          location: 'US',
          service: FakePersistentMemoryService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const expectedNames = [
      'Emergency',
      'Veterans Crisis Line',
      'The Trevor Project (for LGBTQ+ youth)',
      '988 Suicide & Crisis Lifeline',
      'Crisis Text Line',
      'Elem עלם',
    ];
    for (final name in expectedNames) {
      expect(find.text(name), findsOneWidget);
    }

    final renderedNames = tester
        .widgetList<EmergencyPhoneItem>(find.byType(EmergencyPhoneItem))
        .map((item) => item.number['name'] as String)
        .toList();
    expect(renderedNames, expectedNames);

    await tester.pumpWidget(
      buildEmergencyGridTestApp(
        userInformation: UserInformation(
          age: '18-30',
          location: 'US',
          service: FakePersistentMemoryService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elem עלם'), findsNothing);
  });

  testWidgets('Elem support opens WhatsApp and website actions', (
    tester,
  ) async {
    final originalPlatform = UrlLauncherPlatform.instance;
    final fakePlatform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
    addTearDown(() {
      UrlLauncherPlatform.instance = originalPlatform;
    });

    await tester.pumpWidget(
      buildEmergencyGridTestApp(
        userInformation: UserInformation(
          age: '18-',
          location: 'US',
          service: FakePersistentMemoryService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elem עלם'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chat).last);
    await tester.pumpAndSettle();
    expect(fakePlatform.launchedUrls, ['https://wa.me/972546786776']);

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    expect(fakePlatform.launchedUrls, [
      'https://wa.me/972546786776',
      'https://yelem.org.il/',
    ]);
  });

  test('Emergency numbers match SOS reference data for AU/US/UK/EU', () {
    final usa = countries['usa'];
    final uk = countries['uk'];
    final eu = countries['eu'];
    final australia = countries['australia'];

    expect(usa, isNotNull);
    expect(uk, isNotNull);
    expect(eu, isNotNull);
    expect(australia, isNotNull);

    final usaEmergency = usa!.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Emergency',
    );
    expect(usaEmergency['number'], '911');

    final veterans = usa.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Veterans Crisis Line',
    );
    expect(veterans['number'], '988');
    expect(veterans['textNumber'], '838255');
    expect(
      veterans['link'],
      'https://www.veteranscrisisline.net/get-help-now/chat/',
    );

    final trevor = usa.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'The Trevor Project (for LGBTQ+ youth)',
    );
    expect(trevor['number'], '18664887386');
    expect(trevor['textNumber'], '678678');
    expect(trevor['textMessage'], 'START');

    final lifeline = usa.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == '988 Suicide & Crisis Lifeline',
    );
    expect(lifeline['number'], '988');
    expect(lifeline['textNumber'], '988');
    expect(lifeline['link'], 'https://988lifeline.org/chat/');

    final crisisTextLine = usa.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Crisis Text Line',
    );
    expect(crisisTextLine['textNumber'], '741741');
    expect(crisisTextLine['textMessage'], 'HOME');

    final ukEmergency = uk!.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Emergency',
    );
    expect(ukEmergency['number'], '999');

    final samaritans = uk.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Samaritans',
    );
    expect(samaritans['number'], '116123');

    final shout = uk.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Shout',
    );
    expect(shout['textNumber'], '85258');
    expect(shout['textMessage'], 'SHOUT');

    final calm = uk.emergencyNumbers.firstWhere(
      (entry) =>
          entry['name'] == 'CALM (Campaign Against Living Miserably, for men)',
    );
    expect(calm['number'], '0800585858');

    final papyrus = uk.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Papyrus (for people under 35)',
    );
    expect(papyrus['number'], '08000684141');
    expect(papyrus['textNumber'], '88247');
    expect(papyrus['link'], '');

    final euEmergency = eu!.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'European Emergency Number',
    );
    expect(euEmergency['number'], '112');
    expect(euEmergency['canCall'], true);

    final mentalHealthEurope = eu.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Mental Health Europe',
    );
    expect(mentalHealthEurope['link'], 'https://mhe-sme.org/');

    final auEmergency = australia!.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Emergency',
    );
    expect(auEmergency['number'], '000');

    final lifelineAu = australia.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Lifeline Australia',
    );
    expect(lifelineAu['number'], '131114');
    expect(lifelineAu['textNumber'], '0477131114');
    expect(lifelineAu['linkType'], 'chat');

    final beyondBlue = australia.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Beyond Blue',
    );
    expect(beyondBlue['number'], '1300224636');
    expect(
      beyondBlue['link'],
      'https://www.beyondblue.org.au/get-support/talk-to-a-counsellor',
    );

    final kidsHelpline = australia.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'Kids Helpline (for people aged 5-25)',
    );
    expect(kidsHelpline['number'], '1800551800');
    expect(kidsHelpline['link'], 'https://kidshelpline.com.au/');

    final mensLine = australia.emergencyNumbers.firstWhere(
      (entry) => entry['name'] == 'MensLine Australia',
    );
    expect(mensLine['number'], '1300789978');
    expect(mensLine['link'], 'https://mensline.org.au/');
  });

  testWidgets('EmergencyDialogBox uses whatsappNumber for WhatsApp action', (
    tester,
  ) async {
    final originalPlatform = UrlLauncherPlatform.instance;
    final fakePlatform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
    addTearDown(() {
      UrlLauncherPlatform.instance = originalPlatform;
    });

    final userInfo = UserInformation(
      gender: 'male',
      service: FakePersistentMemoryService(),
    );
    final appInfo = AppInformation();

    await tester.pumpWidget(
      buildEmergencyDialogTestApp(
        dialog: const EmergencyDialogBox(
          number: '105',
          whatsappNumber: '972521210105',
          link: '',
          hasWhatsApp: true,
          hasLink: false,
          canCall: false,
        ),
        userInformation: userInfo,
        appInformation: appInfo,
      ),
    );

    await tester.tap(find.byIcon(Icons.chat));
    await tester.pumpAndSettle();

    expect(fakePlatform.lastLaunchedUrl, 'https://wa.me/972521210105');
  });

  testWidgets('EmergencyDialogBox uses sms number and body for text action', (
    tester,
  ) async {
    MethodCall? smsCall;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_smsComposeChannel, (call) async {
      smsCall = call;
      return true;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(_smsComposeChannel, null);
    });

    final userInfo = UserInformation(
      gender: 'male',
      service: FakePersistentMemoryService(),
    );
    final appInfo = AppInformation();

    await tester.pumpWidget(
      buildEmergencyDialogTestApp(
        dialog: const EmergencyDialogBox(
          number: '741741',
          whatsappNumber: '',
          link: '',
          textNumber: '741741',
          textMessage: 'HOME',
          hasWhatsApp: false,
          hasLink: false,
          canCall: false,
        ),
        userInformation: userInfo,
        appInformation: appInfo,
      ),
    );

    await tester.tap(find.byIcon(Icons.sms));
    await tester.pumpAndSettle();

    expect(smsCall?.method, 'composeSms');
    expect(smsCall?.arguments, <String, String>{
      'number': '741741',
      'body': 'HOME',
    });
  });

  test('dialPhone uses url_launcher for Android phone links', () async {
    final originalPlatform = UrlLauncherPlatform.instance;
    final fakePlatform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      UrlLauncherPlatform.instance = originalPlatform;
    });

    await dialPhone('1201');

    expect(fakePlatform.lastLaunchedUrl, 'tel:1201%20');
  });

  test(
    'dialPhone does not add Android display hints to regular numbers',
    () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fakePlatform = FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        UrlLauncherPlatform.instance = originalPlatform;
      });

      await dialPhone('+9721201');

      expect(fakePlatform.lastLaunchedUrl, 'tel:+9721201');
    },
  );

  testWidgets('EmergencyDialogBox labels chat links as Chat', (tester) async {
    final userInfo = UserInformation(
      gender: 'male',
      service: FakePersistentMemoryService(),
    );
    final appInfo = AppInformation();

    await tester.pumpWidget(
      buildEmergencyDialogTestApp(
        dialog: const EmergencyDialogBox(
          number: '988',
          whatsappNumber: '',
          link: 'https://988lifeline.org/chat/',
          linkType: 'chat',
          hasWhatsApp: false,
          hasLink: true,
          canCall: true,
        ),
        userInformation: userInfo,
        appInformation: appInfo,
      ),
    );

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Website'), findsNothing);
  });

  testWidgets(
    'EmergencyPhonesGrid uses saved country over locale fallback for SOS data',
    (tester) async {
      final userInfo = UserInformation(
        gender: 'male',
        location: 'GB',
        service: FakePersistentMemoryService(),
      );

      await tester.pumpWidget(
        buildEmergencyGridTestApp(
          userInformation: userInfo,
          locale: const Locale('en', 'US'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Samaritans'), findsOneWidget);
      expect(find.text('Shout'), findsOneWidget);
      expect(find.text('Veterans Crisis Line'), findsNothing);
    },
  );

  testWidgets('EmergencyPhonesGrid uses two columns on phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final userInfo = UserInformation(
      gender: 'male',
      location: 'US',
      service: FakePersistentMemoryService(),
    );

    await tester.pumpWidget(
      buildEmergencyGridTestApp(userInformation: userInfo),
    );

    await tester.pumpAndSettle();

    final emergency = find.text('Emergency');
    final veterans = find.text('Veterans Crisis Line');
    expect(emergency, findsOneWidget);
    expect(veterans, findsOneWidget);

    final emergencyTop = tester.getTopLeft(emergency).dy;
    final veteransTop = tester.getTopLeft(veterans).dy;
    final emergencyLeft = tester.getTopLeft(emergency).dx;
    final veteransLeft = tester.getTopLeft(veterans).dx;

    expect(veteransTop, closeTo(emergencyTop, 1));
    expect(veteransLeft, greaterThan(emergencyLeft));
  });

  testWidgets(
    'PhonePage keeps emergency numbers in two columns at 360dp width',
    (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await GetIt.instance.reset();
      GetIt.instance.registerSingleton<PersistentMemoryService>(
        FakePersistentMemoryService(),
      );
      addTearDown(() async {
        await GetIt.instance.reset();
      });

      final userInfo = UserInformation(
        gender: 'male',
        location: 'US',
        service: FakePersistentMemoryService(),
      );
      final appInfo = AppInformation();
      final phonePageData = PhonePageData(
        key: 'phonePageData',
        header: 'header',
        subTitle: 'subTitle',
        midTitle: 'midTitle',
        phoneNameTitle: 'phoneNameTitle',
        phoneNumberTitle: 'phoneNumberTitle',
        phoneNames: [],
        phoneNumbers: [],
        savedPhoneNames: [],
        savedPhoneNumbers: [],
        phoneDescription: [],
      );

      await tester.pumpWidget(
        buildPhonePageTestApp(
          userInformation: userInfo,
          appInformation: appInfo,
          phonePageData: phonePageData,
        ),
      );

      await tester.pumpAndSettle();

      final emergency = find.text('Emergency');
      final veterans = find.text('Veterans Crisis Line');
      expect(emergency, findsOneWidget);
      expect(veterans, findsOneWidget);

      final emergencyTop = tester.getTopLeft(emergency).dy;
      final veteransTop = tester.getTopLeft(veterans).dy;
      final emergencyLeft = tester.getTopLeft(emergency).dx;
      final veteransLeft = tester.getTopLeft(veterans).dx;

      expect(veteransTop, closeTo(emergencyTop, 1));
      expect(veteransLeft, greaterThan(emergencyLeft));
    },
  );

  testWidgets('PhonePage contact disclaimer info icon is labelled', (
    tester,
  ) async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      FakePersistentMemoryService(),
    );
    addTearDown(() async {
      await GetIt.instance.reset();
    });

    final userInfo = UserInformation(
      gender: 'male',
      location: 'US',
      service: FakePersistentMemoryService(),
    );
    final phonePageData = PhonePageData(
      key: 'phonePageData',
      header: 'header',
      subTitle: 'subTitle',
      midTitle: 'midTitle',
      phoneNameTitle: 'phoneNameTitle',
      phoneNumberTitle: 'phoneNumberTitle',
      phoneNames: [],
      phoneNumbers: [],
      savedPhoneNames: [],
      savedPhoneNumbers: [],
      phoneDescription: [],
    );

    await tester.pumpWidget(
      buildPhonePageTestApp(
        userInformation: userInfo,
        appInformation: AppInformation(),
        phonePageData: phonePageData,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Contact storage information'), findsOneWidget);
    final infoIcon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
    expect(infoIcon.semanticLabel, 'Contact storage information');
  });

  testWidgets('PhonePage opens the existing contact editor from contacts', (
    tester,
  ) async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      FakePersistentMemoryService(),
    );
    addTearDown(() async {
      await GetIt.instance.reset();
    });

    final userInfo = UserInformation(
      gender: 'male',
      location: 'US',
      service: FakePersistentMemoryService(),
    );
    final appInfo = AppInformation();
    final phonePageData = PhonePageData(
      key: 'phonePageData',
      header: 'header',
      subTitle: 'subTitle',
      midTitle: 'midTitle',
      phoneNameTitle: 'phoneNameTitle',
      phoneNumberTitle: 'phoneNumberTitle',
      phoneNames: [],
      phoneNumbers: [],
      savedPhoneNames: [],
      savedPhoneNumbers: [],
      phoneDescription: [],
    );

    await tester.pumpWidget(
      buildPhonePageTestApp(
        userInformation: userInfo,
        appInformation: appInfo,
        phonePageData: phonePageData,
      ),
    );
    await tester.pumpAndSettle();

    final manageButton = find.byKey(const Key('phonePageManageContactsButton'));
    expect(manageButton, findsOneWidget);

    await tester.ensureVisible(manageButton);
    await tester.tap(manageButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(PhonePageForm), findsOneWidget);
  });

  testWidgets('PhonePage reflects PhonePageData contact changes', (
    tester,
  ) async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      FakePersistentMemoryService(),
    );
    addTearDown(() async {
      await GetIt.instance.reset();
    });

    final userInfo = UserInformation(
      gender: 'male',
      location: 'US',
      service: FakePersistentMemoryService(),
    );
    final appInfo = AppInformation();
    final phonePageData = PhonePageData(
      key: 'phonePageData',
      header: 'header',
      subTitle: 'subTitle',
      midTitle: 'midTitle',
      phoneNameTitle: 'phoneNameTitle',
      phoneNumberTitle: 'phoneNumberTitle',
      phoneNames: [],
      phoneNumbers: [],
      savedPhoneNames: [],
      savedPhoneNumbers: [],
      phoneDescription: [],
    );

    await tester.pumpWidget(
      buildPhonePageTestApp(
        userInformation: userInfo,
        appInformation: appInfo,
        phonePageData: phonePageData,
      ),
    );
    await tester.pumpAndSettle();

    phonePageData.addItem('Alex', '123456');
    await tester.pump();

    expect(find.text('Alex'), findsOneWidget);
  });

  testWidgets('PhonePage guards invalid legacy personal-contact calls', (
    tester,
  ) async {
    final originalPlatform = UrlLauncherPlatform.instance;
    final fakePlatform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
    addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      FakePersistentMemoryService(),
    );
    addTearDown(() async {
      await GetIt.instance.reset();
    });

    final phonePageData = _phonePageDataForLocationShare();
    await tester.pumpWidget(
      buildPhonePageTestApp(
        userInformation: UserInformation(
          gender: 'male',
          location: 'IL',
          service: FakePersistentMemoryService(),
        ),
        appInformation: AppInformation(),
        phonePageData: phonePageData,
      ),
    );
    await tester.pumpAndSettle();

    phonePageData.savedPhoneNames = <String>['Local legacy', 'Invalid legacy'];
    phonePageData.savedPhoneNumbers = <String>['0501234567', '*123#'];
    phonePageData.update();
    await tester.pumpAndSettle();

    final localCall = find.byTooltip('Call Local legacy');
    await tester.ensureVisible(localCall);
    await tester.tap(localCall, warnIfMissed: false);
    await tester.pump();
    expect(fakePlatform.launchedUrls, <String>['tel:+972501234567']);

    final invalidCall = find.byTooltip('Call Invalid legacy');
    await tester.ensureVisible(invalidCall);
    await tester.tap(invalidCall, warnIfMissed: false);
    await tester.pump();

    final localizations = AppLocalizations.of(
      tester.element(find.byType(PhonePage)),
    )!;
    expect(fakePlatform.launchedUrls, <String>['tel:+972501234567']);
    expect(find.text(localizations.callFailedMessage('*123#')), findsOneWidget);
  });

  testWidgets('Hebrew Israel emergency grid puts Sahar beside Eran', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final userInfo = UserInformation(
      gender: 'male',
      location: 'IL',
      service: FakePersistentMemoryService(),
    );

    await tester.pumpWidget(
      buildEmergencyGridTestApp(
        userInformation: userInfo,
        locale: const Locale('he'),
      ),
    );

    await tester.pumpAndSettle();

    final eran = find.text(hebrewEran);
    final sahar = find.text(hebrewSahar);
    final number105 = find.text('105');
    final eranDescription = find.text('עזרה ראשונה נפשית');
    final saharDescription = find.text('סיוע והקשבה ברשת');
    expect(eran, findsOneWidget);
    expect(sahar, findsOneWidget);
    expect(number105, findsOneWidget);
    expect(eranDescription, findsOneWidget);
    expect(saharDescription, findsOneWidget);

    final eranTop = tester.getTopLeft(eran).dy;
    final saharTop = tester.getTopLeft(sahar).dy;
    final number105Top = tester.getTopLeft(number105).dy;

    expect(saharTop, closeTo(eranTop, 1));
    expect(number105Top, greaterThan(eranTop + 20));
  });

  testWidgets(
    'Sahar website action appears below WhatsApp and opens the site',
    (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fakePlatform = FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() {
        UrlLauncherPlatform.instance = originalPlatform;
      });

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final userInfo = UserInformation(
        gender: 'male',
        location: 'IL',
        service: FakePersistentMemoryService(),
      );

      await tester.pumpWidget(
        buildEmergencyGridTestApp(
          userInformation: userInfo,
          locale: const Locale('he'),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text(hebrewSahar));
      await tester.pumpAndSettle();

      final whatsAppAction = find.text('ווצאפ');
      final websiteAction = find.text('קישור לאתר');
      expect(whatsAppAction, findsOneWidget);
      expect(websiteAction, findsOneWidget);

      expect(
        tester.getTopLeft(websiteAction).dy,
        greaterThan(tester.getTopLeft(whatsAppAction).dy),
      );

      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      expect(fakePlatform.lastLaunchedUrl, 'https://sahar.org.il/');
    },
  );

  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets(
      'PhonePage offers a high-accuracy current location delivery after personal contacts on $platform',
      (tester) async {
        final callLog = <String>[];
        final geolocator = FakeGeolocatorPlatform(
          permission: LocationPermission.denied,
          requestedPermission: LocationPermission.whileInUse,
          position: _testPosition(latitude: 31.7683, longitude: 35.2137),
          callLog: callLog,
        );
        final fileService = RecordingFileService(callLog: callLog);
        await _runLocationShareTest(
          geolocator,
          fileService,
          platform: platform,
          body: () async {
            final phonePageData = _phonePageDataForLocationShare();

            await tester.pumpWidget(
              buildPhonePageTestApp(
                userInformation: UserInformation(
                  gender: 'male',
                  location: 'US',
                  service: FakePersistentMemoryService(),
                ),
                appInformation: AppInformation(),
                phonePageData: phonePageData,
              ),
            );
            await tester.pumpAndSettle();

            final contactSection = find.text('Your contacts');
            final shareLocation = find.text('Share Location');
            final shareMessage = find.text('Share SOS Message');
            final emergencyNumbers = find.text('Emergency Numbers');
            expect(contactSection, findsOneWidget);
            expect(shareLocation, findsOneWidget);
            expect(shareMessage, findsOneWidget);
            expect(emergencyNumbers, findsOneWidget);
            expect(
              tester.getTopLeft(shareLocation).dy,
              greaterThan(tester.getTopLeft(contactSection).dy),
            );
            expect(
              tester.getTopLeft(emergencyNumbers).dy,
              greaterThan(tester.getTopLeft(shareLocation).dy),
            );
            expect(
              find.byTooltip('Share your current location'),
              findsOneWidget,
            );
            expect(
              find.byTooltip('Share your SOS help message'),
              findsOneWidget,
            );

            await _tapLocationShare(tester);
            expect(fileService.sharedMessages, isEmpty);
            expect(find.text('Choose an app'), findsOneWidget);
            await _chooseDeliveryOption(tester, 'Choose an app');

            expect(callLog, [
              'isLocationServiceEnabled',
              'checkPermission',
              'requestPermission',
              'getCurrentPosition',
              'shareTextOnly',
            ]);
            expect(fileService.sharedMessages, [
              'I am here and I need your help.\n'
                  'https://www.google.com/maps/search/?api=1&query=31.7683,35.2137',
            ]);
            expect(geolocator.locationServiceEnabledCalls, 1);
            expect(geolocator.checkPermissionCalls, 1);
            expect(geolocator.requestPermissionCalls, 1);
            expect(geolocator.currentPositionCalls, 1);
            expect(
              geolocator.lastLocationSettings?.accuracy,
              LocationAccuracy.high,
            );
            expect(
              geolocator.lastLocationSettings?.timeLimit,
              const Duration(seconds: 15),
            );
          },
        );
      },
    );
  }

  testWidgets('PhonePage localizes SOS location sharing in Hebrew', (
    tester,
  ) async {
    final geolocator = FakeGeolocatorPlatform();
    final fileService = RecordingFileService();
    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'IL',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: _phonePageDataForLocationShare(),
            locale: const Locale('he'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('שיתוף מיקום'), findsOneWidget);
        expect(find.byTooltip('שיתוף המיקום הנוכחי שלך'), findsOneWidget);
        expect(find.text('שיתוף הודעת SOS'), findsOneWidget);

        await _tapLocationShare(tester);
        await _chooseDeliveryOption(tester, 'בחירת אפליקציה');

        expect(fileService.sharedMessages, [
          'אני כאן ויש לי צורך בעזרתך\n'
              'https://www.google.com/maps/search/?api=1&query=31.7683,35.2137',
        ]);
      },
    );
  });

  for (final disabledServicesCase in <({Locale locale, String notice})>[
    (
      locale: const Locale('en'),
      notice:
          'Your current location could not be obtained. Please enable location services.',
    ),
    (
      locale: const Locale('he'),
      notice: 'לא ניתן לקבל את מיקומך הנוכחי, נא להפעיל את שירותי המיקום',
    ),
    (
      locale: const Locale('ar'),
      notice: 'تعذّر الحصول على موقعك الحالي. يُرجى تفعيل خدمات الموقع.',
    ),
  ]) {
    testWidgets(
      'PhonePage stops SOS delivery and shows disabled-services feedback in ${disabledServicesCase.locale.languageCode}',
      (tester) async {
        final geolocator = FakeGeolocatorPlatform(serviceEnabled: false);

        await _expectLocationUnavailable(
          tester,
          geolocator,
          locale: disabledServicesCase.locale,
          servicesDisabled: true,
          expectedNotice: disabledServicesCase.notice,
        );

        expect(geolocator.checkPermissionCalls, 0);
        expect(geolocator.currentPositionCalls, 0);
      },
    );
  }

  testWidgets(
    'PhonePage stops SOS delivery when location permission is denied',
    (tester) async {
      final geolocator = FakeGeolocatorPlatform(
        permission: LocationPermission.denied,
        requestedPermission: LocationPermission.denied,
      );

      await _expectLocationUnavailable(tester, geolocator);

      expect(geolocator.requestPermissionCalls, 1);
      expect(geolocator.currentPositionCalls, 0);
    },
  );

  testWidgets(
    'PhonePage stops SOS delivery when location permission is permanently denied',
    (tester) async {
      final geolocator = FakeGeolocatorPlatform(
        permission: LocationPermission.deniedForever,
      );

      await _expectLocationUnavailable(tester, geolocator);

      expect(geolocator.requestPermissionCalls, 0);
      expect(geolocator.currentPositionCalls, 0);
    },
  );

  testWidgets('PhonePage accepts an existing always location permission', (
    tester,
  ) async {
    final geolocator = FakeGeolocatorPlatform(
      permission: LocationPermission.always,
    );
    final fileService = RecordingFileService();

    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'US',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: _phonePageDataForLocationShare(),
          ),
        );
        await tester.pumpAndSettle();

        await _tapLocationShare(tester);
        await _chooseDeliveryOption(tester, 'Choose an app');

        expect(geolocator.requestPermissionCalls, 0);
        expect(geolocator.currentPositionCalls, 1);
        expect(fileService.sharedMessages, [
          'I am here and I need your help.\n'
              'https://www.google.com/maps/search/?api=1&query=31.7683,35.2137',
        ]);
      },
    );
  });

  testWidgets(
    'PhonePage stops SOS delivery when location availability cannot be determined',
    (tester) async {
      final geolocator = FakeGeolocatorPlatform(
        permission: LocationPermission.unableToDetermine,
      );

      await _expectLocationUnavailable(tester, geolocator);

      expect(geolocator.currentPositionCalls, 0);
    },
  );

  testWidgets('PhonePage stops SOS delivery when location lookup times out', (
    tester,
  ) async {
    final geolocator = FakeGeolocatorPlatform(
      positionError: TimeoutException('location lookup timed out'),
    );

    await _expectLocationUnavailable(tester, geolocator);

    expect(geolocator.currentPositionCalls, 1);
  });

  testWidgets('PhonePage stops SOS delivery when location lookup throws', (
    tester,
  ) async {
    final geolocator = FakeGeolocatorPlatform(
      positionError: StateError('location lookup failed'),
    );

    await _expectLocationUnavailable(tester, geolocator);

    expect(geolocator.currentPositionCalls, 1);
  });

  testWidgets('PhonePage stops SOS delivery without GPS on desktop', (
    tester,
  ) async {
    final geolocator = FakeGeolocatorPlatform();

    await _expectLocationUnavailable(
      tester,
      geolocator,
      platform: TargetPlatform.windows,
    );

    expect(geolocator.locationServiceEnabledCalls, 0);
    expect(geolocator.checkPermissionCalls, 0);
    expect(geolocator.requestPermissionCalls, 0);
    expect(geolocator.currentPositionCalls, 0);
    expect(geolocator.callLog, isEmpty);
  });

  testWidgets('PhonePage stops SOS delivery without GPS on web', (
    tester,
  ) async {
    final geolocator = FakeGeolocatorPlatform();

    await _expectLocationUnavailable(tester, geolocator);

    expect(geolocator.locationServiceEnabledCalls, 0);
    expect(geolocator.checkPermissionCalls, 0);
    expect(geolocator.requestPermissionCalls, 0);
    expect(geolocator.currentPositionCalls, 0);
    expect(geolocator.callLog, isEmpty);
  }, skip: !kIsWeb);

  testWidgets(
    'PhonePage shows localized Arabic SOS feedback and allows retry when sharing is not confirmed',
    (tester) async {
      final geolocator = FakeGeolocatorPlatform();
      final fileService = RecordingFileService(failedResultsRemaining: 1);
      await _runLocationShareTest(
        geolocator,
        fileService,
        body: () async {
          await tester.pumpWidget(
            buildPhonePageTestApp(
              userInformation: UserInformation(
                gender: 'male',
                location: 'IL',
                service: FakePersistentMemoryService(),
              ),
              appInformation: AppInformation(),
              phonePageData: _phonePageDataForLocationShare(),
              locale: const Locale('ar'),
            ),
          );
          await tester.pumpAndSettle();

          final localizations = AppLocalizations.of(
            tester.element(find.byType(PhonePage)),
          )!;
          await _tapLocationShare(tester);
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliveryChooseApp,
          );

          expect(tester.takeException(), isNull);
          expect(
            find.text(localizations.sosShareLocationShareFailed),
            findsOneWidget,
          );
          expect(fileService.sharedMessages, isEmpty);

          await _tapLocationShare(tester);
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliveryChooseApp,
          );

          expect(tester.takeException(), isNull);
          expect(fileService.sharedMessages, hasLength(1));
          expect(geolocator.currentPositionCalls, 2);
        },
      );
    },
  );

  testWidgets('PhonePage localizes SOS location sharing in Arabic', (
    tester,
  ) async {
    final geolocator = FakeGeolocatorPlatform();
    final fileService = RecordingFileService();
    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'IL',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: _phonePageDataForLocationShare(),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          Directionality.of(tester.element(find.byType(PhonePage))),
          TextDirection.rtl,
        );
        expect(find.text('مشاركة الموقع'), findsOneWidget);
        expect(find.byTooltip('مشاركة موقعك الحالي'), findsOneWidget);
        expect(find.text('مشاركة رسالة الاستغاثة'), findsOneWidget);

        await _tapLocationShare(tester);
        await _chooseDeliveryOption(tester, 'اختيار تطبيق');

        expect(fileService.sharedMessages, [
          'أنا هنا وأحتاج إلى مساعدتك.\n'
              'https://www.google.com/maps/search/?api=1&query=31.7683,35.2137',
        ]);
      },
    );
  });

  testWidgets(
    'PhonePage shows localized SOS feedback and allows retry when sharing throws',
    (tester) async {
      final geolocator = FakeGeolocatorPlatform();
      final fileService = RecordingFileService(exceptionsRemaining: 1);
      await _runLocationShareTest(
        geolocator,
        fileService,
        body: () async {
          await tester.pumpWidget(
            buildPhonePageTestApp(
              userInformation: UserInformation(
                gender: 'male',
                location: 'IL',
                service: FakePersistentMemoryService(),
              ),
              appInformation: AppInformation(),
              phonePageData: _phonePageDataForLocationShare(),
              locale: const Locale('he'),
            ),
          );
          await tester.pumpAndSettle();

          final localizations = AppLocalizations.of(
            tester.element(find.byType(PhonePage)),
          )!;
          await _tapLocationShare(tester);
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliveryChooseApp,
          );

          expect(tester.takeException(), isNull);
          expect(
            find.text(localizations.sosShareLocationShareFailed),
            findsOneWidget,
          );
          expect(fileService.sharedMessages, isEmpty);

          await _tapLocationShare(tester);
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliveryChooseApp,
          );

          expect(tester.takeException(), isNull);
          expect(fileService.sharedMessages, hasLength(1));
          expect(geolocator.currentPositionCalls, 2);
        },
      );
    },
  );

  testWidgets('PhonePage shares only the SOS message without requesting GPS', (
    tester,
  ) async {
    final geolocator = FakeGeolocatorPlatform();
    final fileService = RecordingFileService();
    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'IL',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: _phonePageDataForLocationShare(),
          ),
        );
        await tester.pumpAndSettle();
        final localizations = AppLocalizations.of(
          tester.element(find.byType(PhonePage)),
        )!;

        await _tapMessageShare(tester);
        expect(
          find.text(localizations.sosDeliveryOptionsTitle),
          findsOneWidget,
        );
        await _chooseDeliveryOption(tester, localizations.sosDeliveryChooseApp);

        expect(fileService.sharedMessages, [
          localizations.sosShareLocationMessage,
        ]);
        expect(geolocator.callLog, isEmpty);
      },
    );
  });

  for (final mapHandoff in <TargetPlatform, String>{
    TargetPlatform.android: 'geo:0,0?q=31.7683,35.2137',
    TargetPlatform.iOS: 'https://maps.apple.com/?ll=31.7683,35.2137',
  }.entries) {
    testWidgets(
      'PhonePage opens a compatible ${mapHandoff.key} map app without sharing text',
      (tester) async {
        final originalPlatform = UrlLauncherPlatform.instance;
        final fakePlatform = FakeUrlLauncherPlatform();
        UrlLauncherPlatform.instance = fakePlatform;
        addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

        final geolocator = FakeGeolocatorPlatform();
        final fileService = RecordingFileService();
        await _runLocationShareTest(
          geolocator,
          fileService,
          platform: mapHandoff.key,
          body: () async {
            await tester.pumpWidget(
              buildPhonePageTestApp(
                userInformation: UserInformation(
                  gender: 'male',
                  location: 'IL',
                  service: FakePersistentMemoryService(),
                ),
                appInformation: AppInformation(),
                phonePageData: _phonePageDataForLocationShare(),
              ),
            );
            await tester.pumpAndSettle();
            final localizations = AppLocalizations.of(
              tester.element(find.byType(PhonePage)),
            )!;

            await _tapLocationShare(tester);
            await _chooseDeliveryOption(
              tester,
              localizations.sosDeliveryOpenMapApp,
            );

            expect(fakePlatform.lastLaunchedUrl, mapHandoff.value);
            expect(fileService.sharedMessages, isEmpty);
          },
        );
      },
    );
  }

  testWidgets('PhonePage shows launch feedback when the map app cannot open', (
    tester,
  ) async {
    final originalPlatform = UrlLauncherPlatform.instance;
    final fakePlatform = FakeUrlLauncherPlatform(shouldSucceed: false);
    UrlLauncherPlatform.instance = fakePlatform;
    addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

    final geolocator = FakeGeolocatorPlatform();
    final fileService = RecordingFileService();
    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'IL',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: _phonePageDataForLocationShare(),
          ),
        );
        await tester.pumpAndSettle();
        final localizations = AppLocalizations.of(
          tester.element(find.byType(PhonePage)),
        )!;

        await _tapLocationShare(tester);
        await _chooseDeliveryOption(
          tester,
          localizations.sosDeliveryOpenMapApp,
        );

        expect(find.text(localizations.couldNotOpenApp), findsOneWidget);
        expect(fileService.sharedMessages, isEmpty);
      },
    );
  });

  testWidgets('PhonePage sends location SOS content to a saved SMS contact', (
    tester,
  ) async {
    MethodCall? smsCall;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_smsComposeChannel, (call) async {
      smsCall = call;
      return true;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(_smsComposeChannel, null),
    );

    final geolocator = FakeGeolocatorPlatform();
    final fileService = RecordingFileService();
    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        final phonePageData = _phonePageDataForLocationShare();
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'IL',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: phonePageData,
          ),
        );
        await tester.pumpAndSettle();
        expect(phonePageData.addItem('SOS SMS', '+972 50 123 4567'), isTrue);
        await tester.pumpAndSettle();
        final localizations = AppLocalizations.of(
          tester.element(find.byType(PhonePage)),
        )!;

        await _tapLocationShare(tester);
        await _chooseDeliveryOption(
          tester,
          localizations.sosDeliverySendToContact,
        );
        await tester.tap(find.text('SOS SMS').last);
        await tester.pumpAndSettle();
        await _chooseDeliveryOption(tester, localizations.sosDeliverySms);

        expect(smsCall?.method, 'composeSms');
        expect(smsCall?.arguments, <String, String>{
          'number': '+972501234567',
          'body':
              '${localizations.sosShareLocationMessage}\n'
              'https://www.google.com/maps/search/?api=1&query=31.7683,35.2137',
        });
        expect(fileService.sharedMessages, isEmpty);
      },
    );
  });

  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets(
      'PhonePage canonicalizes a legacy 00 SOS SMS contact for $platform',
      (tester) async {
        final smsCalls = <MethodCall>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(_smsComposeChannel, (call) async {
          smsCalls.add(call);
          return true;
        });
        addTearDown(
          () => messenger.setMockMethodCallHandler(_smsComposeChannel, null),
        );

        final geolocator = FakeGeolocatorPlatform();
        final fileService = RecordingFileService();
        await _runLocationShareTest(
          geolocator,
          fileService,
          platform: platform,
          body: () async {
            final phonePageData = _phonePageDataForLocationShare();
            await tester.pumpWidget(
              buildPhonePageTestApp(
                userInformation: UserInformation(
                  gender: 'male',
                  location: 'US',
                  service: FakePersistentMemoryService(),
                ),
                appInformation: AppInformation(),
                phonePageData: phonePageData,
              ),
            );
            await tester.pumpAndSettle();
            phonePageData.savedPhoneNames = ['Legacy SMS'];
            phonePageData.savedPhoneNumbers = ['00972501234567'];
            phonePageData.update();
            await tester.pumpAndSettle();
            final localizations = AppLocalizations.of(
              tester.element(find.byType(PhonePage)),
            )!;

            await _tapMessageShare(tester);
            await _chooseDeliveryOption(
              tester,
              localizations.sosDeliverySendToContact,
            );
            await tester.tap(find.text('Legacy SMS').last);
            await tester.pumpAndSettle();
            await _chooseDeliveryOption(tester, localizations.sosDeliverySms);

            expect(smsCalls, hasLength(1));
            final smsCall = smsCalls.single;
            expect(smsCall.method, 'composeSms');
            expect(smsCall.arguments, <String, String>{
              'number': '+972501234567',
              'body': localizations.sosShareLocationMessage,
            });
            expect(geolocator.callLog, isEmpty);
            expect(fileService.sharedMessages, isEmpty);
          },
        );
      },
    );
  }

  testWidgets('PhonePage keeps an international WhatsApp contact unchanged', (
    tester,
  ) async {
    final originalPlatform = UrlLauncherPlatform.instance;
    final fakePlatform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
    addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

    final geolocator = FakeGeolocatorPlatform();
    final fileService = RecordingFileService();
    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        final phonePageData = _phonePageDataForLocationShare();
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'US',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: phonePageData,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          phonePageData.addItem('SOS WhatsApp', '+972 50 123 4567'),
          isTrue,
        );
        await tester.pumpAndSettle();
        final localizations = AppLocalizations.of(
          tester.element(find.byType(PhonePage)),
        )!;

        await _tapMessageShare(tester);
        await _chooseDeliveryOption(
          tester,
          localizations.sosDeliverySendToContact,
        );
        await tester.tap(find.text('SOS WhatsApp').last);
        await tester.pumpAndSettle();
        await _chooseDeliveryOption(tester, localizations.whatsApp);

        final whatsAppUri = Uri.parse(fakePlatform.lastLaunchedUrl!);
        expect(whatsAppUri.host, 'wa.me');
        expect(whatsAppUri.path, '/972501234567');
        expect(
          whatsAppUri.queryParameters['text'],
          localizations.sosShareLocationMessage,
        );
        expect(geolocator.callLog, isEmpty);
        expect(fileService.sharedMessages, isEmpty);
      },
    );
  });

  testWidgets('PhonePage converts a legacy Israeli local WhatsApp contact', (
    tester,
  ) async {
    final originalPlatform = UrlLauncherPlatform.instance;
    final fakePlatform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
    addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

    final geolocator = FakeGeolocatorPlatform();
    final fileService = RecordingFileService();
    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        final phonePageData = _phonePageDataForLocationShare();
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'IL',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: phonePageData,
          ),
        );
        await tester.pumpAndSettle();
        expect(phonePageData.addItem('Local WhatsApp', '0501234567'), isTrue);
        await tester.pumpAndSettle();
        final localizations = AppLocalizations.of(
          tester.element(find.byType(PhonePage)),
        )!;

        await _tapMessageShare(tester);
        await _chooseDeliveryOption(
          tester,
          localizations.sosDeliverySendToContact,
        );
        await tester.tap(find.text('Local WhatsApp').last);
        await tester.pumpAndSettle();
        await _chooseDeliveryOption(tester, localizations.whatsApp);

        final whatsAppUri = Uri.parse(fakePlatform.lastLaunchedUrl!);
        expect(whatsAppUri.host, 'wa.me');
        expect(whatsAppUri.path, '/972501234567');
        expect(
          whatsAppUri.queryParameters['text'],
          localizations.sosShareLocationMessage,
        );
      },
    );
  });

  testWidgets(
    'PhonePage converts a legacy 00-prefixed WhatsApp contact to its international number',
    (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fakePlatform = FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final geolocator = FakeGeolocatorPlatform();
      final fileService = RecordingFileService();
      await _runLocationShareTest(
        geolocator,
        fileService,
        body: () async {
          final phonePageData = _phonePageDataForLocationShare();
          await tester.pumpWidget(
            buildPhonePageTestApp(
              userInformation: UserInformation(
                gender: 'male',
                location: 'US',
                service: FakePersistentMemoryService(),
              ),
              appInformation: AppInformation(),
              phonePageData: phonePageData,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            phonePageData.addItem('00 WhatsApp', '00972501234567'),
            isTrue,
          );
          await tester.pumpAndSettle();
          final localizations = AppLocalizations.of(
            tester.element(find.byType(PhonePage)),
          )!;

          await _tapMessageShare(tester);
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliverySendToContact,
          );
          await tester.tap(find.text('00 WhatsApp').last);
          await tester.pumpAndSettle();
          await _chooseDeliveryOption(tester, localizations.whatsApp);

          final whatsAppUri = Uri.parse(fakePlatform.lastLaunchedUrl!);
          expect(whatsAppUri.host, 'wa.me');
          expect(whatsAppUri.path, '/972501234567');
          expect(
            whatsAppUri.queryParameters['text'],
            localizations.sosShareLocationMessage,
          );
        },
      );
    },
  );

  testWidgets(
    'PhonePage converts a legacy local WhatsApp contact using profile country',
    (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fakePlatform = FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final geolocator = FakeGeolocatorPlatform();
      final fileService = RecordingFileService();
      await _runLocationShareTest(
        geolocator,
        fileService,
        body: () async {
          final phonePageData = _phonePageDataForLocationShare();
          await tester.pumpWidget(
            buildPhonePageTestApp(
              userInformation: UserInformation(
                gender: 'male',
                location: 'US',
                service: FakePersistentMemoryService(),
              ),
              appInformation: AppInformation(),
              phonePageData: phonePageData,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            phonePageData.addItem('US local WhatsApp', '(555) 123-4567'),
            isTrue,
          );
          await tester.pumpAndSettle();
          final localizations = AppLocalizations.of(
            tester.element(find.byType(PhonePage)),
          )!;

          await _tapMessageShare(tester);
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliverySendToContact,
          );
          await tester.tap(find.text('US local WhatsApp').last);
          await tester.pumpAndSettle();
          await _chooseDeliveryOption(tester, localizations.whatsApp);

          final whatsAppUri = Uri.parse(fakePlatform.lastLaunchedUrl!);
          expect(whatsAppUri.host, 'wa.me');
          expect(whatsAppUri.path, '/15551234567');
        },
      );
    },
  );

  for (final profileCountry in <String>['', 'XX', 'CA']) {
    testWidgets(
      'PhonePage does not launch a legacy local WhatsApp contact without a supported profile country ($profileCountry)',
      (tester) async {
        final originalPlatform = UrlLauncherPlatform.instance;
        final fakePlatform = FakeUrlLauncherPlatform();
        UrlLauncherPlatform.instance = fakePlatform;
        addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

        final geolocator = FakeGeolocatorPlatform();
        final fileService = RecordingFileService();
        await _runLocationShareTest(
          geolocator,
          fileService,
          body: () async {
            final phonePageData = _phonePageDataForLocationShare();
            await tester.pumpWidget(
              buildPhonePageTestApp(
                userInformation: UserInformation(
                  gender: 'male',
                  location: profileCountry,
                  service: FakePersistentMemoryService(),
                ),
                appInformation: AppInformation(),
                phonePageData: phonePageData,
              ),
            );
            await tester.pumpAndSettle();
            expect(
              phonePageData.addItem('Unmapped WhatsApp', '0501234567'),
              isTrue,
            );
            await tester.pumpAndSettle();
            final localizations = AppLocalizations.of(
              tester.element(find.byType(PhonePage)),
            )!;

            await _tapMessageShare(tester);
            await _chooseDeliveryOption(
              tester,
              localizations.sosDeliverySendToContact,
            );
            await tester.tap(find.text('Unmapped WhatsApp').last);
            await tester.pumpAndSettle();
            await _chooseDeliveryOption(tester, localizations.whatsApp);

            expect(
              find.text(localizations.sosDeliveryWhatsAppInternationalNumber),
              findsOneWidget,
            );
            expect(
              find.text(localizations.sosDeliveryEditContacts),
              findsOneWidget,
            );
            expect(fakePlatform.launchedUrls, isEmpty);
          },
        );
      },
    );
  }

  testWidgets(
    'PhonePage does not launch an invalid legacy local WhatsApp contact',
    (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fakePlatform = FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final geolocator = FakeGeolocatorPlatform();
      final fileService = RecordingFileService();
      await _runLocationShareTest(
        geolocator,
        fileService,
        body: () async {
          final phonePageData = _phonePageDataForLocationShare();
          await tester.pumpWidget(
            buildPhonePageTestApp(
              userInformation: UserInformation(
                gender: 'male',
                location: 'IL',
                service: FakePersistentMemoryService(),
              ),
              appInformation: AppInformation(),
              phonePageData: phonePageData,
            ),
          );
          await tester.pumpAndSettle();
          expect(phonePageData.addItem('Invalid WhatsApp', '11'), isTrue);
          await tester.pumpAndSettle();
          final localizations = AppLocalizations.of(
            tester.element(find.byType(PhonePage)),
          )!;

          await _tapMessageShare(tester);
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliverySendToContact,
          );
          await tester.tap(find.text('Invalid WhatsApp').last);
          await tester.pumpAndSettle();
          await _chooseDeliveryOption(tester, localizations.whatsApp);

          expect(
            find.text(localizations.sosDeliveryWhatsAppInternationalNumber),
            findsOneWidget,
          );
          expect(fakePlatform.launchedUrls, isEmpty);
        },
      );
    },
  );

  testWidgets('PhonePage explains when no saved SOS contact is available', (
    tester,
  ) async {
    final geolocator = FakeGeolocatorPlatform();
    final fileService = RecordingFileService();
    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'IL',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: _phonePageDataForLocationShare(),
          ),
        );
        await tester.pumpAndSettle();
        final localizations = AppLocalizations.of(
          tester.element(find.byType(PhonePage)),
        )!;

        await _tapMessageShare(tester);
        await _chooseDeliveryOption(
          tester,
          localizations.sosDeliverySendToContact,
        );

        expect(
          find.text(localizations.sosDeliveryNoContactsMessage),
          findsOneWidget,
        );
        expect(fileService.sharedMessages, isEmpty);
        expect(geolocator.callLog, isEmpty);
      },
    );
  });

  testWidgets(
    'PhonePage requires mismatched saved contacts to be edited before delivery',
    (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fakePlatform = FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final geolocator = FakeGeolocatorPlatform();
      final fileService = RecordingFileService();
      await _runLocationShareTest(
        geolocator,
        fileService,
        body: () async {
          final phonePageData = _phonePageDataForLocationShare();
          await tester.pumpWidget(
            buildPhonePageTestApp(
              userInformation: UserInformation(
                gender: 'male',
                location: 'IL',
                service: FakePersistentMemoryService(),
              ),
              appInformation: AppInformation(),
              phonePageData: phonePageData,
            ),
          );
          await tester.pumpAndSettle();
          phonePageData.savedPhoneNames = ['Paired contact', 'Unpaired name'];
          phonePageData.savedPhoneNumbers = ['+972501234567'];
          phonePageData.update();
          await tester.pumpAndSettle();
          final localizations = AppLocalizations.of(
            tester.element(find.byType(PhonePage)),
          )!;

          await _tapMessageShare(tester);
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliverySendToContact,
          );

          expect(
            find.text(localizations.sosDeliveryContactsNeedAttention),
            findsOneWidget,
          );
          expect(fakePlatform.launchedUrls, isEmpty);
          expect(phonePageData.savedPhoneNames, [
            'Paired contact',
            'Unpaired name',
          ]);
          expect(phonePageData.savedPhoneNumbers, ['+972501234567']);

          await tester.tap(find.text(localizations.sosDeliveryEditContacts));
          await tester.pumpAndSettle();

          expect(find.byType(PhonePageForm), findsOneWidget);
          expect(find.byType(TextFormField), findsNWidgets(2));
          await tester.enterText(
            find.byType(TextFormField).at(1),
            '+972502222222',
          );
          final saveButton = find.byIcon(Icons.check);
          await tester.ensureVisible(saveButton);
          await tester.tap(saveButton);
          await tester.pumpAndSettle();

          expect(phonePageData.savedPhoneNames, [
            'Paired contact',
            'Unpaired name',
          ]);
          expect(phonePageData.savedPhoneNumbers, [
            '+972501234567',
            '+972502222222',
          ]);
        },
      );
    },
  );

  testWidgets(
    'PhonePage blocks malformed legacy SMS contacts before launching',
    (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fakePlatform = FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      MethodCall? smsCall;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_smsComposeChannel, (call) async {
        smsCall = call;
        return true;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(_smsComposeChannel, null),
      );

      final geolocator = FakeGeolocatorPlatform();
      final fileService = RecordingFileService();
      await _runLocationShareTest(
        geolocator,
        fileService,
        body: () async {
          final phonePageData = _phonePageDataForLocationShare();
          await tester.pumpWidget(
            buildPhonePageTestApp(
              userInformation: UserInformation(
                gender: 'male',
                location: 'IL',
                service: FakePersistentMemoryService(),
              ),
              appInformation: AppInformation(),
              phonePageData: phonePageData,
            ),
          );
          await tester.pumpAndSettle();
          phonePageData.savedPhoneNames = ['Legacy SMS'];
          phonePageData.savedPhoneNumbers = ['*123#'];
          phonePageData.update();
          await tester.pumpAndSettle();
          final localizations = AppLocalizations.of(
            tester.element(find.byType(PhonePage)),
          )!;

          await _tapMessageShare(tester);
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliverySendToContact,
          );
          await tester.tap(find.text('Legacy SMS').last);
          await tester.pumpAndSettle();
          await _chooseDeliveryOption(tester, localizations.sosDeliverySms);

          expect(
            find.text(localizations.sosDeliveryContactsNeedAttention),
            findsOneWidget,
          );
          expect(fakePlatform.launchedUrls, isEmpty);
          expect(smsCall, isNull);
        },
      );
    },
  );

  testWidgets(
    'PhonePage retries disabled location services before offering delivery',
    (tester) async {
      final geolocator = FakeGeolocatorPlatform(
        serviceEnabledResults: [false, true],
      );
      final fileService = RecordingFileService();
      await _runLocationShareTest(
        geolocator,
        fileService,
        body: () async {
          await tester.pumpWidget(
            buildPhonePageTestApp(
              userInformation: UserInformation(
                gender: 'male',
                location: 'IL',
                service: FakePersistentMemoryService(),
              ),
              appInformation: AppInformation(),
              phonePageData: _phonePageDataForLocationShare(),
            ),
          );
          await tester.pumpAndSettle();
          final localizations = AppLocalizations.of(
            tester.element(find.byType(PhonePage)),
          )!;

          await _tapLocationShare(tester);
          expect(fileService.sharedMessages, isEmpty);
          expect(
            find.text(localizations.sosShareLocationServicesDisabled),
            findsOneWidget,
          );
          await tester.tap(find.text(localizations.asyncRetryButton));
          await tester.pumpAndSettle();
          await _chooseDeliveryOption(
            tester,
            localizations.sosDeliveryChooseApp,
          );

          expect(geolocator.locationServiceEnabledCalls, 2);
          expect(fileService.sharedMessages, hasLength(1));
          expect(
            fileService.sharedMessages.single,
            '${localizations.sosShareLocationMessage}\n'
            'https://www.google.com/maps/search/?api=1&query=31.7683,35.2137',
          );
        },
      );
    },
  );

  testWidgets('PhonePage serializes SOS actions while location is loading', (
    tester,
  ) async {
    final positionCompleter = Completer<Position>();
    final geolocator = FakeGeolocatorPlatform(
      positionCompleter: positionCompleter,
    );
    final fileService = RecordingFileService();
    await _runLocationShareTest(
      geolocator,
      fileService,
      body: () async {
        await tester.pumpWidget(
          buildPhonePageTestApp(
            userInformation: UserInformation(
              gender: 'male',
              location: 'US',
              service: FakePersistentMemoryService(),
            ),
            appInformation: AppInformation(),
            phonePageData: _phonePageDataForLocationShare(),
          ),
        );
        await tester.pumpAndSettle();

        final locationAction = find.byKey(
          const Key('phonePageShareLocationButton'),
        );
        await tester.ensureVisible(locationAction);
        await tester.tap(locationAction, warnIfMissed: false);
        await tester.pump();
        await tester.tap(locationAction, warnIfMissed: false);
        await tester.pump();

        final messageAction = find.byKey(
          const Key('phonePageShareMessageButton'),
        );
        await tester.ensureVisible(messageAction);
        await tester.tap(messageAction, warnIfMissed: false);
        await tester.pump();

        expect(geolocator.currentPositionCalls, 1);
        expect(find.text('Choose a delivery option'), findsNothing);
        expect(fileService.sharedMessages, isEmpty);

        positionCompleter.complete(_testPosition());
        await tester.pumpAndSettle();

        await _chooseDeliveryOption(tester, 'Choose an app');

        expect(fileService.sharedMessages, hasLength(1));
      },
    );
  });
}
