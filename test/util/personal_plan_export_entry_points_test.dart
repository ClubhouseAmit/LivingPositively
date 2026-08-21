import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/MainPageHelpers/components/personal_plan_section.dart';
import 'package:mazilon/MainPageHelpers/personalPlanWidget.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/phone.dart';
import 'package:mazilon/pages/sos_location_service.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/Share/personal_plan_download.dart';
import 'package:mazilon/util/Share/personal_plan_share.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../test_support/contract_persistent_memory_service.dart';
import '../helpers/widget_test_scaffold.dart';

class _RecordingIncidentLogger implements IncidentLoggerService {
  final List<dynamic> capturedLogs = <dynamic>[];

  @override
  Future<void> initializeSentry(Widget myApp) async {}

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    capturedLogs.add(exception);
  }
}

class _TestFileService implements FileService {
  final List<String> callLog = <String>[];
  String? downloadResult = '/path/to/downloaded/file.pdf';

  @override
  Future<ShareResult?> share(
    String message,
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType shareFileType, {
    required String mainTitle,
    required String textDirection,
  }) async {
    callLog.add('share');
    return const ShareResult('success', ShareResultStatus.success);
  }

  @override
  Future<String?> download(
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType shareFileType, {
    required String mainTitle,
    required String textDirection,
  }) async {
    callLog.add('download');
    return downloadResult;
  }

  @override
  Future<bool> shareTextOnly(String message) async {
    callLog.add('shareTextOnly');
    return true;
  }
}

base class _TestPersistentMemoryService extends ContractPersistentMemoryService {
  _TestPersistentMemoryService() {
    onMissingRead = (_, _) => null;
  }

  final List<String> writeLog = <String>[];
  Completer<void>? pendingWriteCompleter;
  bool throwOnWrite = false;

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (throwOnWrite) {
      throw StateError('Write failed');
    }
    if (pendingWriteCompleter != null) {
      await pendingWriteCompleter!.future;
    }
    writeLog.add(key);
    await super.setItem(key, type, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');
  final List<String> toastCalls = <String>[];
  late GetIt locator;
  late _TestFileService fileService;
  late _TestPersistentMemoryService memoryService;
  late _RecordingIncidentLogger loggerService;
  late AppInformation appInformation;
  late UserInformation userInformation;

  setUp(() async {
    toastCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (call) async {
      if (call.method == 'showToast') {
        toastCalls.add(call.arguments['msg']?.toString() ?? '');
      }
      return true;
    });

    locator = GetIt.instance;
    await locator.reset();

    fileService = _TestFileService();
    memoryService = _TestPersistentMemoryService();
    loggerService = _RecordingIncidentLogger();
    appInformation = AppInformation();

    locator.registerSingleton<FileService>(fileService);
    locator.registerSingleton<PersistentMemoryService>(memoryService);
    locator.registerSingleton<IncidentLoggerService>(loggerService);
    locator.registerSingleton<AnalyticsService>(NoopAnalyticsService());
    locator.registerSingleton<SosLocationService>(NoopSosLocationService());

    userInformation = UserInformation(service: memoryService);
    userInformation.gender = 'male';
    userInformation.name = 'Test User';
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, null);
  });

  group('Personal Plan export entry points preparation and stabilization', () {
    test(
      'preparePersonalPlanExport awaits pending saves and repairs unaligned sources',
      () async {
        // Setup initial unaligned sources (legacy state: 2 selections, 1 source)
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        // Advance revision and start a pending save
        final saveFuture = userInformation.queueDreamsAndGoalsSave();

        // Run preparation helper
        await userInformation.prepareForPersonalPlanExport();
        await saveFuture;

        // Sources must now be aligned
        expect(userInformation.dreamsAndGoalsSelectionSources, [
          'custom',
          'custom',
        ]);
        expect(
          memoryService.writeLog,
          contains('selectionSourcesPersonalPlan-DreamsAndGoals'),
        );
      },
    );

    test(
      'Entry point 1: LPShareAlertDialog shareFile awaits pending saves before sharing',
      () async {
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await shareFile(
          localizations,
          userInformation.gender,
          userInformation.name,
          appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result?.status, ShareResultStatus.success);
        expect(fileService.callLog, contains('share'));
        expect(userInformation.dreamsAndGoalsSelectionSources.length, 2);
      },
    );

    testWidgets(
      'Entry point 2: personalPlanWidget header download awaits pending saves and repairs sources',
      (WidgetTester tester) async {
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        await pumpWithProviders(
          tester,
          PersonalPlanWidget(
            text: const <String, dynamic>{
              'SubTitle': 'Test Subtitle',
              'list': ['Item 1', 'Item 2'],
            },
            changeCurrentIndex: (_, _) {},
          ),
          userInformation: userInformation,
          appInformation: appInformation,
        );
        await tester.pumpAndSettle();

        final downloadIcon = find.byKey(
          const Key('personalPlanHeaderDownload'),
        );
        expect(downloadIcon, findsOneWidget);

        await tester.runAsync(() async {
          final button = tester.widget<IconButton>(downloadIcon);
          button.onPressed!();
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();

        expect(fileService.callLog, contains('download'));
        expect(userInformation.dreamsAndGoalsSelectionSources.length, 2);
      },
    );

    testWidgets(
      'Entry point 3: personal_plan_section menu download awaits pending saves and repairs sources',
      (WidgetTester tester) async {
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        await pumpWithProviders(
          tester,
          Scaffold(
            body: PersonalPlanSectionWidget(
              items: const ['Item 1', 'Item 2'],
              onSeeAll: () {},
            ),
          ),
          userInformation: userInformation,
          appInformation: appInformation,
          surfaceSize: const Size(800, 1600),
        );
        await tester.pumpAndSettle();

        final menuButton = find.byKey(
          const Key('personalPlanHeaderMenu'),
        );
        expect(menuButton, findsOneWidget);

        await tester.runAsync(() async {
          final menu = tester.widget<PopupMenuButton<String>>(menuButton);
          menu.onSelected!('download');
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        expect(fileService.callLog, contains('download'));
        expect(userInformation.dreamsAndGoalsSelectionSources.length, 2);
      },
    );

    testWidgets(
      'Entry point 4: phone.dart SOS personal plan crisis share awaits pending saves and repairs sources',
      (WidgetTester tester) async {
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        final phonePageData = PhonePageData(
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

        await pumpWithProviders(
          tester,
          ChangeNotifierProvider<PhonePageData>.value(
            value: phonePageData,
            child: PhonePage(
              phonePageData: phonePageData,
              sosLocationService: NoopSosLocationService(),
            ),
          ),
          userInformation: userInformation,
          appInformation: appInformation,
          surfaceSize: const Size(800, 1600),
        );
        await tester.pumpAndSettle();

        final personalPlanBtn = find.byKey(
          const Key('phonePageSharePersonalPlanButton'),
        );
        expect(personalPlanBtn, findsOneWidget);
        await tester.ensureVisible(personalPlanBtn);

        await tester.runAsync(() async {
          final button = tester.widget<TextButton>(personalPlanBtn);
          button.onPressed!();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        expect(fileService.callLog, contains('share'));
        expect(userInformation.dreamsAndGoalsSelectionSources.length, 2);
      },
    );

    test(
      'downloadPersonalPlanFile catches preparation persistence failure, logs telemetry, and shows failure toast',
      () async {
        memoryService.throwOnWrite = true;
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );
        userInformation.queueDreamsAndGoalsSave();

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          textDirection: localizations.textDirection,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, isNull);
        expect(fileService.callLog, isNot(contains('download')));
        expect(loggerService.capturedLogs, isNotEmpty);
        expect(toastCalls, contains(localizations.downloadFailed('male')));
      },
    );

    test(
      'downloadPersonalPlanFile returns null without failure toast when user cancels download',
      () async {
        fileService.downloadResult = null;
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          textDirection: localizations.textDirection,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, isNull);
        expect(fileService.callLog, contains('download'));
        expect(loggerService.capturedLogs, isEmpty);
        expect(toastCalls, isEmpty);
      },
    );

    test(
      'downloadPersonalPlanFile returns path and shows finished toast on success',
      () async {
        fileService.downloadResult = '/saved/plan.pdf';
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          textDirection: localizations.textDirection,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, '/saved/plan.pdf');
        expect(fileService.callLog, contains('download'));
        expect(loggerService.capturedLogs, isEmpty);
        expect(toastCalls, contains(localizations.finishedDownloading('male')));
      },
    );

    test(
      'sharePersonalPlanFile catches preparation persistence failure, logs telemetry, and returns null',
      () async {
        memoryService.throwOnWrite = true;
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );
        userInformation.queueDreamsAndGoalsSave();

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await sharePersonalPlanFile(
          message: 'emergency msg',
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, isNull);
        expect(fileService.callLog, isNot(contains('share')));
        expect(loggerService.capturedLogs, isNotEmpty);
      },
    );

    test(
      'LPShareAlertDialog shareFile forwards to sharePersonalPlanFile with empty message',
      () async {
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await shareFile(
          localizations,
          userInformation.gender,
          userInformation.name,
          appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result?.status, ShareResultStatus.success);
        expect(fileService.callLog, contains('share'));
        expect(loggerService.capturedLogs, isEmpty);
      },
    );
  });
}
