import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/phone.dart';
import 'package:mazilon/pages/sos_location_service.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../helpers/phone_delivery_test_fakes.dart';

const _smsComposeChannel = MethodChannel('com.matzilon.mezilon/sms_compose');

class RecordedShareCall {
  const RecordedShareCall({
    required this.message,
    required this.titles,
    required this.subTitles,
    required this.texts,
    required this.mainTitle,
    required this.saveFormat,
    required this.textDirection,
  });

  final String message;
  final List<dynamic> titles;
  final List<dynamic> subTitles;
  final Map<String, String> texts;
  final String mainTitle;
  final ShareFileType saveFormat;
  final String textDirection;
}

class RecordingFileService implements FileService {
  RecordingFileService({
    List<String>? callLog,
    this.failedResultsRemaining = 0,
    this.exceptionsRemaining = 0,
    this.shareCompleter,
  }) : callLog = callLog ?? [];

  final List<String> callLog;
  final List<String> sharedMessages = [];
  final List<RecordedShareCall> shareCalls = [];
  final Completer<void>? shareCompleter;
  int failedResultsRemaining;
  int exceptionsRemaining;

  @override
  Future<String?> download(
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat,
    {required String mainTitle,
    required String textDirection,
  }) async => null;

  @override
  Future<void> share(
    String message,
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat,
    {required String mainTitle,
    required String textDirection,
  }) async {
    shareCalls.add(
      RecordedShareCall(
        message: message,
        titles: titles,
        subTitles: subTitles,
        texts: texts,
        mainTitle: mainTitle,
        saveFormat: saveFormat,
        textDirection: textDirection,
      ),
    );
    await shareCompleter?.future;
  }

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

class FakeSosLocationService implements SosLocationService {
  FakeSosLocationService({
    List<SosLocationLookupResult>? results,
    this.lookupCompleter,
    List<String>? callLog,
  }) : _results =
           results ??
           const [
             SosLocationSuccess(
               SosLocationSnapshot(latitude: 31.7683, longitude: 35.2137),
             ),
           ],
       callLog = callLog ?? [];

  final List<SosLocationLookupResult> _results;
  final Completer<SosLocationLookupResult>? lookupCompleter;
  final List<String> callLog;
  int lookupCalls = 0;

  @override
  Future<SosLocationLookupResult> lookupCurrentPosition() {
    callLog.add('lookupCurrentPosition');
    lookupCalls++;
    if (lookupCompleter != null) {
      return lookupCompleter!.future;
    }
    final index = lookupCalls - 1;
    return Future<SosLocationLookupResult>.value(
      _results[index < _results.length ? index : _results.length - 1],
    );
  }
}

const _successfulLocation = SosLocationSuccess(
  SosLocationSnapshot(latitude: 31.7683, longitude: 35.2137),
);

const _servicesDisabled = SosLocationFailureResult(
  SosLocationFailureKind.servicesDisabled,
);

const _locationUnavailable = SosLocationFailureResult(
  SosLocationFailureKind.unavailable,
);

SosLocationService? _activeSosLocationService;

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

Future<void> _runPhonePageTest(
  FakeSosLocationService locationService,
  RecordingFileService fileService, {
  required Future<void> Function() body,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  try {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      FakePersistentMemoryService(),
    );
    GetIt.instance.registerSingleton<FileService>(fileService);
    _activeSosLocationService = locationService;
    debugDefaultTargetPlatformOverride = platform;
    await body();
  } finally {
    _activeSosLocationService = null;
    debugDefaultTargetPlatformOverride = null;
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

Future<void> _expectLocationFailure(
  WidgetTester tester,
  FakeSosLocationService locationService, {
  required String expectedNotice,
  Locale locale = const Locale('en', 'US'),
  bool canRetry = false,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  final fileService = RecordingFileService();
  final userInformation = UserInformation(
    gender: 'male',
    location: 'US',
    service: FakePersistentMemoryService(),
  );
  await _runPhonePageTest(
    locationService,
    fileService,
    platform: platform,
    body: () async {
      await tester.pumpWidget(
        buildPhonePageTestApp(
          userInformation: userInformation,
          appInformation: AppInformation(),
          phonePageData: _phonePageDataForLocationShare(),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      await _tapLocationShare(tester);

      final dialog = find.byType(AlertDialog);
      final localizations = AppLocalizations.of(
        tester.element(find.byType(PhonePage)),
      )!;
      expect(dialog, findsOneWidget);
      expect(find.text(expectedNotice), findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(localizations.asyncRetryButton),
        ),
        canRetry ? findsOneWidget : findsNothing,
      );
      for (final deliveryAction in [
        localizations.sosDeliveryChooseApp,
        localizations.sosDeliverySendToContact,
        localizations.sosDeliveryOpenMapApp,
        localizations.sosDeliverySms,
        localizations.whatsApp,
      ]) {
        expect(
          find.descendant(of: dialog, matching: find.text(deliveryAction)),
          findsNothing,
        );
      }

      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.text(
            localizations.closeButton(userInformation.gender),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(fileService.sharedMessages, isEmpty);
    },
  );
}

Widget buildPhonePageTestApp({
  required UserInformation userInformation,
  required AppInformation appInformation,
  required PhonePageData phonePageData,
  SosLocationService? sosLocationService,
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
        child: PhonePage(
          phonePageData: phonePageData,
          sosLocationService:
              sosLocationService ??
              _activeSosLocationService ??
              FakeSosLocationService(),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets(
      'PhonePage offers a high-accuracy current location delivery after personal contacts on $platform',
      (tester) async {
        final callLog = <String>[];
        final locationService = FakeSosLocationService(
          results: const [_successfulLocation],
          callLog: callLog,
        );
        final fileService = RecordingFileService(callLog: callLog);
        await _runPhonePageTest(
          locationService,
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

            expect(callLog, ['lookupCurrentPosition', 'shareTextOnly']);
            expect(fileService.sharedMessages, [
              'I am here and I need your help.\n'
                  'https://www.google.com/maps/search/?api=1&query=31.7683,35.2137',
            ]);
            expect(locationService.lookupCalls, 1);
          },
        );
      },
    );
  }

  testWidgets('PhonePage localizes SOS location sharing in Hebrew', (
    tester,
  ) async {
    final locationService = FakeSosLocationService();
    final fileService = RecordingFileService();
    await _runPhonePageTest(
      locationService,
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

  group('PhonePage SOS location availability', () {
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
        'should show the disabled-services notice and close without delivery in ${disabledServicesCase.locale.languageCode}',
        (tester) async {
          final locationService = FakeSosLocationService(
            results: const [_servicesDisabled],
          );

          await _expectLocationFailure(
            tester,
            locationService,
            locale: disabledServicesCase.locale,
            expectedNotice: disabledServicesCase.notice,
            canRetry: true,
          );

          expect(locationService.lookupCalls, 1);
          expect(locationService.callLog, ['lookupCurrentPosition']);
        },
      );
    }

    for (final unavailableCase in <String>[
      'permission is denied',
      'permission is permanently denied',
      'location availability cannot be determined',
      'location lookup times out',
      'location lookup throws',
    ]) {
      testWidgets(
        'should show close-only generic feedback when $unavailableCase',
        (tester) async {
          final locationService = FakeSosLocationService(
            results: const [_locationUnavailable],
          );

          await _expectLocationFailure(
            tester,
            locationService,
            expectedNotice: 'Your current location could not be obtained.',
          );

          expect(locationService.lookupCalls, 1);
          expect(locationService.callLog, ['lookupCurrentPosition']);
        },
      );
    }

    testWidgets(
      'should wait before retrying disabled services and offer delivery after success',
      (tester) async {
        final locationService = FakeSosLocationService(
          results: const [_servicesDisabled, _successfulLocation],
        );
        final fileService = RecordingFileService();
        await _runPhonePageTest(
          locationService,
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
            await tester.tap(find.text(localizations.asyncRetryButton));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 499));
            expect(locationService.lookupCalls, 1);
            await tester.pump(const Duration(milliseconds: 1));
            await tester.pumpAndSettle();

            expect(locationService.callLog, [
              'lookupCurrentPosition',
              'lookupCurrentPosition',
            ]);
            expect(
              find.text(localizations.sosDeliveryOptionsTitle),
              findsOneWidget,
            );
            await _chooseDeliveryOption(
              tester,
              localizations.sosDeliveryChooseApp,
            );
            expect(fileService.sharedMessages, [
              '${localizations.sosShareLocationMessage}\n'
                  'https://www.google.com/maps/search/?api=1&query=31.7683,35.2137',
            ]);
          },
        );
      },
    );

    testWidgets(
      'should stop retrying after three disabled-services lookup attempts',
      (tester) async {
        final locationService = FakeSosLocationService(
          results: const [
            _servicesDisabled,
            _servicesDisabled,
            _servicesDisabled,
          ],
        );
        final fileService = RecordingFileService();
        await _runPhonePageTest(
          locationService,
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
            for (var retry = 0; retry < 2; retry++) {
              await tester.tap(find.text(localizations.asyncRetryButton));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 500));
              await tester.pumpAndSettle();
            }

            final dialog = find.byType(AlertDialog);
            expect(locationService.lookupCalls, 3);
            expect(
              find.descendant(
                of: dialog,
                matching: find.text(localizations.asyncRetryButton),
              ),
              findsNothing,
            );
            await tester.tap(
              find.descendant(
                of: dialog,
                matching: find.text(localizations.closeButton('male')),
              ),
            );
            await tester.pumpAndSettle();
            expect(fileService.sharedMessages, isEmpty);
          },
        );
      },
    );

    testWidgets('should not look up again when disposed during retry backoff', (
      tester,
    ) async {
      final locationService = FakeSosLocationService(
        results: const [_servicesDisabled, _successfulLocation],
      );
      final fileService = RecordingFileService();
      await _runPhonePageTest(
        locationService,
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
          await tester.tap(find.text(localizations.asyncRetryButton));
          await tester.pump();
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));

          expect(locationService.lookupCalls, 1);
          expect(fileService.sharedMessages, isEmpty);
        },
      );
    });
  });
  testWidgets(
    'PhonePage shows localized Arabic SOS feedback and allows retry when sharing is not confirmed',
    (tester) async {
      final locationService = FakeSosLocationService();
      final fileService = RecordingFileService(failedResultsRemaining: 1);
      await _runPhonePageTest(
        locationService,
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
          expect(locationService.lookupCalls, 2);
        },
      );
    },
  );

  testWidgets('PhonePage localizes SOS location sharing in Arabic', (
    tester,
  ) async {
    final locationService = FakeSosLocationService();
    final fileService = RecordingFileService();
    await _runPhonePageTest(
      locationService,
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
      final locationService = FakeSosLocationService();
      final fileService = RecordingFileService(exceptionsRemaining: 1);
      await _runPhonePageTest(
        locationService,
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
          expect(locationService.lookupCalls, 2);
        },
      );
    },
  );

  testWidgets('PhonePage shares only the SOS message without requesting GPS', (
    tester,
  ) async {
    final locationService = FakeSosLocationService();
    final fileService = RecordingFileService();
    await _runPhonePageTest(
      locationService,
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
        expect(locationService.callLog, isEmpty);
      },
    );
  });

  group('PhonePage personal plan crisis sharing', () {
    for (final localeCase
        in <
          ({Locale locale, String label, String message, String textDirection})
        >[
          (
            locale: const Locale('en'),
            label: 'Share Personal Plan during a crisis',
            message:
                'I’m not doing well and I need help. I would appreciate your support in activating my personal plan. Thank you in advance.',
            textDirection: 'ltr',
          ),
          (
            locale: const Locale('he'),
            label: 'שיתוף התוכנית האישית בעת משבר',
            message:
                'אני במצב לא טוב ויש לי צורך בעזרה. אשמח לעזרתך בהפעלת התוכנית האישית שלי. בתודה מראש.',
            textDirection: 'rtl',
          ),
          (
            locale: const Locale('ar'),
            label: 'مشاركة الخطة الشخصية أثناء الأزمة',
            message:
                'أنا لست بخير وأحتاج إلى المساعدة. سأقدّر دعمك في تفعيل خطتي الشخصية. شكرًا لك مقدمًا.',
            textDirection: 'rtl',
          ),
        ]) {
      testWidgets(
        'should share the localized Personal Plan PDF and crisis message in ${localeCase.locale.languageCode}',
        (tester) async {
          final locationService = FakeSosLocationService();
          final fileService = RecordingFileService();
          final appInformation = AppInformation()
            ..updateSharePDFtexts({'customCategory': 'Custom content'});
          await _runPhonePageTest(
            locationService,
            fileService,
            body: () async {
              await tester.pumpWidget(
                buildPhonePageTestApp(
                  userInformation: UserInformation(
                    gender: 'male',
                    location: 'IL',
                    service: FakePersistentMemoryService(),
                  ),
                  appInformation: appInformation,
                  phonePageData: _phonePageDataForLocationShare(),
                  locale: localeCase.locale,
                ),
              );
              await tester.pumpAndSettle();
              final localizations = AppLocalizations.of(
                tester.element(find.byType(PhonePage)),
              )!;

              expect(find.text(localeCase.label), findsOneWidget);
              await _tapSosAction(
                tester,
                const Key('phonePageSharePersonalPlanButton'),
              );

              final shareCall = fileService.shareCalls.single;
              final exportMetadata = buildPersonalPlanExportMetadata(
                localizations,
                'male',
                '',
              );
              expect(shareCall.message, localeCase.message);
              expect(shareCall.titles, exportMetadata.titles);
              expect(shareCall.subTitles, exportMetadata.subTitles);
              expect(shareCall.texts, appInformation.sharePDFtexts);
              expect(shareCall.mainTitle, exportMetadata.mainTitle);
              expect(shareCall.saveFormat, ShareFileType.PDF);
              expect(shareCall.textDirection, localeCase.textDirection);
              expect(fileService.sharedMessages, isEmpty);
              expect(locationService.callLog, isEmpty);
            },
          );
        },
      );
    }

    testWidgets('should serialize repeated Personal Plan crisis shares', (
      tester,
    ) async {
      final shareCompleter = Completer<void>();
      final locationService = FakeSosLocationService();
      final fileService = RecordingFileService(shareCompleter: shareCompleter);
      await _runPhonePageTest(
        locationService,
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
          final action = find.byKey(
            const Key('phonePageSharePersonalPlanButton'),
          );

          await tester.ensureVisible(action);
          await tester.tap(action, warnIfMissed: false);
          await tester.pump();
          await tester.tap(action, warnIfMissed: false);
          await tester.pump();

          expect(fileService.shareCalls, hasLength(1));
          shareCompleter.complete();
          await tester.pumpAndSettle();
        },
      );
    });
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

        final locationService = FakeSosLocationService();
        final fileService = RecordingFileService();
        await _runPhonePageTest(
          locationService,
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

    final locationService = FakeSosLocationService();
    final fileService = RecordingFileService();
    await _runPhonePageTest(
      locationService,
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

    final locationService = FakeSosLocationService();
    final fileService = RecordingFileService();
    await _runPhonePageTest(
      locationService,
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

        final locationService = FakeSosLocationService();
        final fileService = RecordingFileService();
        await _runPhonePageTest(
          locationService,
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
            expect(locationService.callLog, isEmpty);
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

    final locationService = FakeSosLocationService();
    final fileService = RecordingFileService();
    await _runPhonePageTest(
      locationService,
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
        expect(locationService.callLog, isEmpty);
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

    final locationService = FakeSosLocationService();
    final fileService = RecordingFileService();
    await _runPhonePageTest(
      locationService,
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

      final locationService = FakeSosLocationService();
      final fileService = RecordingFileService();
      await _runPhonePageTest(
        locationService,
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

      final locationService = FakeSosLocationService();
      final fileService = RecordingFileService();
      await _runPhonePageTest(
        locationService,
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

        final locationService = FakeSosLocationService();
        final fileService = RecordingFileService();
        await _runPhonePageTest(
          locationService,
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

      final locationService = FakeSosLocationService();
      final fileService = RecordingFileService();
      await _runPhonePageTest(
        locationService,
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
    final locationService = FakeSosLocationService();
    final fileService = RecordingFileService();
    await _runPhonePageTest(
      locationService,
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
        expect(locationService.callLog, isEmpty);
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

      final locationService = FakeSosLocationService();
      final fileService = RecordingFileService();
      await _runPhonePageTest(
        locationService,
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

      final locationService = FakeSosLocationService();
      final fileService = RecordingFileService();
      await _runPhonePageTest(
        locationService,
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

  testWidgets('PhonePage serializes SOS actions while location is loading', (
    tester,
  ) async {
    final lookupCompleter = Completer<SosLocationLookupResult>();
    final locationService = FakeSosLocationService(
      lookupCompleter: lookupCompleter,
    );
    final fileService = RecordingFileService();
    await _runPhonePageTest(
      locationService,
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

        expect(locationService.lookupCalls, 1);
        expect(find.text('Choose a delivery option'), findsNothing);
        expect(fileService.sharedMessages, isEmpty);

        lookupCompleter.complete(_successfulLocation);
        await tester.pumpAndSettle();

        await _chooseDeliveryOption(tester, 'Choose an app');

        expect(fileService.sharedMessages, hasLength(1));
      },
    );
  });
}
