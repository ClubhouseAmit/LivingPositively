import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
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
}
