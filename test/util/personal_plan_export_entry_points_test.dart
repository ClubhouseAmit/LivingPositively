import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/MainPageHelpers/components/personal_plan_section.dart';
import 'package:mazilon/MainPageHelpers/personalPlanWidget.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/util/personal_plan_export_snapshot.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/phone.dart';
import 'package:mazilon/pages/sos_location_service.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/Share/personal_plan_download.dart';
import 'package:mazilon/util/Share/personal_plan_share.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../test_support/contract_persistent_memory_service.dart';
import '../helpers/widget_test_scaffold.dart';

class _RecordingIncidentLogger implements IncidentLoggerService {
  final List<dynamic> capturedLogs = <dynamic>[];
  final List<StackTrace?> capturedStacks = <StackTrace?>[];
  final List<String> eventOrder = <String>[];
  bool throwOnCapture = false;

  @override
  Future<void> initializeSentry(Widget myApp) async {}

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    eventOrder.add('captureLog');
    capturedLogs.add(exception);
    capturedStacks.add(stackTrace);
    if (throwOnCapture) {
      throw StateError('Telemetry failure');
    }
  }
}

class _TestFileService implements FileService {
  final List<String> callLog = <String>[];
  String? downloadResult = '/path/to/downloaded/file.pdf';
  bool throwOnAction = false;
  Completer<void>? pendingDownloadCompleter;
  Future<void> Function(PersonalPlanExportSnapshot)? onDownload;
  Future<void> Function(PersonalPlanExportSnapshot)? onShare;
  PersistentMemoryService? lastMemoryService;
  PersonalPlanExportSnapshot? lastSnapshot;
  Map<String, String>? lastTexts;
  Set<String>? lastApprovedHosts;

  @override
  Future<ShareResult?> share(
    String message,
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType shareFileType, {
    required String mainTitle,
    required String textDirection,
    PersistentMemoryService? memoryService,
    PersonalPlanExportSnapshot? snapshot,
    Set<String>? approvedPdfHosts,
  }) async {
    lastMemoryService = memoryService;
    lastSnapshot = snapshot;
    lastTexts = texts;
    lastApprovedHosts = approvedPdfHosts;
    if (throwOnAction) {
      throw StateError('Share failed');
    }
    await onShare?.call(snapshot!);
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
    PersistentMemoryService? memoryService,
    PersonalPlanExportSnapshot? snapshot,
    Set<String>? approvedPdfHosts,
  }) async {
    lastMemoryService = memoryService;
    lastSnapshot = snapshot;
    lastTexts = texts;
    lastApprovedHosts = approvedPdfHosts;
    if (throwOnAction) {
      throw StateError('Download failed');
    }
    await onDownload?.call(snapshot!);
    if (pendingDownloadCompleter != null) {
      await pendingDownloadCompleter!.future;
    }
    callLog.add('download');
    return downloadResult;
  }

  @override
  Future<bool> shareTextOnly(String message) async {
    if (throwOnAction) {
      throw StateError('ShareTextOnly failed');
    }
    callLog.add('shareTextOnly');
    return true;
  }
}

base class _TestPersistentMemoryService
    extends ContractPersistentMemoryService {
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
  bool throwOnToast = false;
  bool invalidToastResponse = false;
  late GetIt locator;
  late _TestFileService fileService;
  late _TestPersistentMemoryService memoryService;
  late _RecordingIncidentLogger loggerService;
  late AppInformation appInformation;
  late UserInformation userInformation;

  setUp(() async {
    toastCalls.clear();
    throwOnToast = false;
    invalidToastResponse = false;
    locator = GetIt.instance;
    await locator.reset();

    fileService = _TestFileService();
    memoryService = _TestPersistentMemoryService();
    loggerService = _RecordingIncidentLogger();
    appInformation = AppInformation();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (call) async {
          if (call.method == 'showToast') {
            loggerService.eventOrder.add('showToast');
            if (invalidToastResponse) return 'not a boolean';
            if (throwOnToast) {
              throw PlatformException(
                code: 'TOAST_FAILED',
                message: 'Failed to show toast',
              );
            }
            toastCalls.add(call.arguments['msg']?.toString() ?? '');
            return true;
          }
          throw UnsupportedError(
            'Unexpected method on toastChannel: ${call.method}',
          );
        });

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

  group('preparePersonalPlanExport', () {
    test('should await pending saves and repair unaligned sources', () async {
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
    });
  });

  group('Personal Plan UI entry points', () {
    testWidgets(
      'header download button should await pending saves and repair sources',
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
      'section menu download option should await pending saves and repair sources',
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

        final menuButton = find.byKey(const Key('personalPlanHeaderMenu'));
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
      'phone page personal plan button should await pending saves and repair sources',
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

    testWidgets(
      'overlapping header and section menu activations should trigger FileService.download only once',
      (WidgetTester tester) async {
        final completer = Completer<void>();
        fileService.pendingDownloadCompleter = completer;

        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        await pumpWithProviders(
          tester,
          Scaffold(
            body: Column(
              children: [
                PersonalPlanWidget(
                  text: const <String, dynamic>{
                    'SubTitle': 'Test Subtitle',
                    'list': ['Item 1', 'Item 2'],
                  },
                  changeCurrentIndex: (_, _) {},
                ),
                PersonalPlanSectionWidget(
                  items: const ['Item 1', 'Item 2'],
                  onSeeAll: () {},
                ),
              ],
            ),
          ),
          userInformation: userInformation,
          appInformation: appInformation,
          surfaceSize: const Size(800, 1600),
        );
        await tester.pumpAndSettle();

        final downloadIcon = find.byKey(
          const Key('personalPlanHeaderDownload'),
        );
        final menuButton = find.byKey(const Key('personalPlanHeaderMenu'));
        expect(downloadIcon, findsOneWidget);
        expect(menuButton, findsOneWidget);

        await tester.runAsync(() async {
          final button = tester.widget<IconButton>(downloadIcon);
          button.onPressed!();

          final menu = tester.widget<PopupMenuButton<String>>(menuButton);
          menu.onSelected!('download');

          await Future<void>.delayed(const Duration(milliseconds: 50));
          completer.complete();
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();

        expect(
          fileService.callLog.where((call) => call == 'download').length,
          1,
        );
        expect(toastCalls.length, 1);
      },
    );
  });

  group('downloadPersonalPlanFile', () {
    for (final edit in [
      'direct storage write',
      'completed save',
      'pending save',
    ]) {
      test(
        'should not coalesce a category-only $edit with an older download',
        () async {
          final localizations = await AppLocalizations.delegate.load(
            const Locale('en'),
          );
          final downloadGate = Completer<void>();
          final saveGate = Completer<void>();
          final firstRead = Completer<void>();
          final secondRead = Completer<void>();
          final snapshots = <List<dynamic>>[];
          fileService.pendingDownloadCompleter = downloadGate;
          fileService.onDownload = (snapshot) async {
            final data = snapshot.data;
            snapshots.add(
              List<dynamic>.from(data['customCategoryTitles'] as List),
            );
            (snapshots.length == 1 ? firstRead : secondRead).complete();
          };
          Future<String?> download() => downloadPersonalPlanFile(
            appLocale: localizations,
            gender: userInformation.gender,
            username: userInformation.name,
            appInformation: appInformation,
            userInformation: userInformation,
            fileService: fileService,
          );
          await userInformation.saveCustomCategories(
            categories: const [MapEntry('Old', 'Old description')],
          );
          final dreamsRevision = userInformation.dreamsAndGoalsSaveRevision;
          final first = download();
          await firstRead.future;
          Future<void>? save;
          try {
            if (edit == 'direct storage write') {
              await saveCustomCategoriesToStorage(const [
                MapEntry('New', 'New description'),
              ], memoryService: memoryService);
            } else {
              if (edit == 'pending save') {
                memoryService.onPersist = (_, _, _) => saveGate.future;
              }
              save = userInformation.saveCustomCategories(
                categories: const [MapEntry('New', 'New description')],
              );
              if (edit == 'completed save') await save;
            }
            final second = download();
            await Future<void>.delayed(Duration.zero);
            if (edit == 'pending save') {
              expect(snapshots, [
                ['Old'],
              ]);
              saveGate.complete();
              await save;
            }
            await secondRead.future.timeout(const Duration(seconds: 2));
            expect(userInformation.dreamsAndGoalsSaveRevision, dreamsRevision);
            expect(snapshots, [
              ['Old'],
              ['New'],
            ]);
            downloadGate.complete();
            expect(await Future.wait([first, second]), [
              fileService.downloadResult,
              fileService.downloadResult,
            ]);
            expect(fileService.callLog, ['download', 'download']);
          } finally {
            if (!saveGate.isCompleted) saveGate.complete();
            if (!downloadGate.isCompleted) downloadGate.complete();
            await save;
            await first;
          }
        },
      );
    }

    test(
      'should return path, log no errors, and show finished toast on success',
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
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, '/saved/plan.pdf');
        expect(fileService.callLog, contains('download'));
        expect(loggerService.capturedLogs, isEmpty);
        expect(loggerService.eventOrder, equals(['showToast']));
        expect(toastCalls, contains(localizations.finishedDownloading('male')));
      },
    );

    test(
      'should deduplicate concurrent in-flight downloads and call FileService once',
      () async {
        final completer = Completer<void>();
        fileService.pendingDownloadCompleter = completer;
        fileService.downloadResult = '/saved/plan.pdf';

        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final future1 = downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        final future2 = downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        completer.complete();
        final results = await Future.wait([future1, future2]);

        expect(results[0], '/saved/plan.pdf');
        expect(results[1], '/saved/plan.pdf');
        expect(
          fileService.callLog.where((call) => call == 'download').length,
          1,
        );
        expect(loggerService.capturedLogs, isEmpty);
        expect(toastCalls, hasLength(1));
        expect(toastCalls.first, localizations.finishedDownloading('male'));
      },
    );

    test(
      'should return path and suppress toast exception when toast channel throws on success',
      () async {
        throwOnToast = true;
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
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, '/saved/plan.pdf');
        expect(fileService.callLog, contains('download'));
        expect(loggerService.capturedLogs, isEmpty);
        expect(loggerService.eventOrder, equals(['showToast']));
      },
    );

    test(
      'should return null without failure toast when user cancels download',
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
      'should catch preparation persistence failure, log telemetry, and show failure toast',
      () async {
        memoryService.throwOnWrite = true;
        userInformation.dreamsAndGoals = ['Goal 1', 'Goal 2'];
        userInformation.dreamsAndGoalsSelectionSources = ['custom'];

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, isNull);
        expect(fileService.callLog, isNot(contains('download')));
        expect(loggerService.capturedLogs, hasLength(1));
        expect(
          loggerService.capturedLogs.first,
          isA<StateError>().having((e) => e.message, 'message', 'Write failed'),
        );
        expect(loggerService.eventOrder, equals(['captureLog', 'showToast']));
        expect(toastCalls, contains(localizations.downloadFailed('male')));
      },
    );

    test(
      'should return null and retain logged error when toast channel throws on failure',
      () async {
        memoryService.throwOnWrite = true;
        throwOnToast = true;
        userInformation.dreamsAndGoals = ['Goal 1', 'Goal 2'];
        userInformation.dreamsAndGoalsSelectionSources = ['custom'];

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, isNull);
        expect(fileService.callLog, isNot(contains('download')));
        expect(loggerService.capturedLogs, hasLength(1));
        expect(
          loggerService.capturedLogs.first,
          isA<StateError>().having((e) => e.message, 'message', 'Write failed'),
        );
        expect(loggerService.eventOrder, equals(['captureLog', 'showToast']));
      },
    );

    for (final failurePhase in ['capture', 'render']) {
      test(
        'should contain unexpected toast errors after $failurePhase failure',
        () async {
          final originalError = StateError('Original $failurePhase failure');
          final originalStack = StackTrace.current;
          invalidToastResponse = true;
          if (failurePhase == 'capture') {
            memoryService.onRead = (_, _) =>
                Error.throwWithStackTrace(originalError, originalStack);
          } else {
            fileService.onDownload = (_) async =>
                Error.throwWithStackTrace(originalError, originalStack);
          }
          final localizations = await AppLocalizations.delegate.load(
            const Locale('en'),
          );
          final result = await downloadPersonalPlanFile(
            appLocale: localizations,
            gender: userInformation.gender,
            username: userInformation.name,
            appInformation: appInformation,
            userInformation: userInformation,
            fileService: fileService,
          );
          expect(result, isNull);
          expect(loggerService.capturedLogs, [same(originalError)]);
          expect(loggerService.capturedStacks, [same(originalStack)]);
          expect(loggerService.eventOrder, ['captureLog', 'showToast']);

          // Failure reporting must also release the in-flight context for retry.
          memoryService.onRead = null;
          fileService.onDownload = null;
          invalidToastResponse = false;
          expect(
            await downloadPersonalPlanFile(
              appLocale: localizations,
              gender: userInformation.gender,
              username: userInformation.name,
              appInformation: appInformation,
              userInformation: userInformation,
              fileService: fileService,
            ),
            '/path/to/downloaded/file.pdf',
          );
        },
      );
    }

    test(
      'should return null and show failure toast when logger throws',
      () async {
        memoryService.throwOnWrite = true;
        loggerService.throwOnCapture = true;
        userInformation.dreamsAndGoals = ['Goal 1', 'Goal 2'];
        userInformation.dreamsAndGoalsSelectionSources = ['custom'];

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, isNull);
        expect(fileService.callLog, isNot(contains('download')));
        expect(loggerService.capturedLogs, hasLength(1));
        expect(
          loggerService.capturedLogs.first,
          isA<StateError>().having((e) => e.message, 'message', 'Write failed'),
        );
        expect(loggerService.eventOrder, equals(['captureLog', 'showToast']));
        expect(toastCalls, contains(localizations.downloadFailed('male')));
      },
    );

    test(
      'should execute concurrent downloads independently and provide independent feedback when export contexts differ',
      () async {
        final completer1 = Completer<void>();
        final completer2 = Completer<void>();
        final service1 = _TestFileService()
          ..downloadResult = '/saved/male_plan.pdf'
          ..pendingDownloadCompleter = completer1;
        final service2 = _TestFileService()
          ..downloadResult = '/saved/female_plan.pdf'
          ..pendingDownloadCompleter = completer2;

        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final future1 = downloadPersonalPlanFile(
          appLocale: localizations,
          gender: 'male',
          username: 'User Male',
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: service1,
        );

        final future2 = downloadPersonalPlanFile(
          appLocale: localizations,
          gender: 'female',
          username: 'User Female',
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: service2,
        );

        completer1.complete();
        completer2.complete();
        final results = await Future.wait([future1, future2]);

        expect(results[0], '/saved/male_plan.pdf');
        expect(results[1], '/saved/female_plan.pdf');
        expect(service1.callLog, ['download']);
        expect(service2.callLog, ['download']);
        expect(loggerService.capturedLogs, isEmpty);
        expect(
          toastCalls,
          containsAll([
            localizations.finishedDownloading('male'),
            localizations.finishedDownloading('female'),
          ]),
        );
      },
    );

    test(
      'should forward userInformation persistent memory service to FileService download',
      () async {
        final customMemory = _TestPersistentMemoryService();
        final customUser = UserInformation(
          service: customMemory,
          name: 'Custom User',
          gender: 'female',
        );

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: customUser.gender,
          username: customUser.name,
          appInformation: appInformation,
          userInformation: customUser,
          fileService: fileService,
        );

        expect(result, isNotNull);
        expect(fileService.lastMemoryService, same(customMemory));
      },
    );

    test(
      'should coalesce downloads with equivalent sharePDFtexts map in different key order',
      () async {
        final completer = Completer<void>();
        fileService.pendingDownloadCompleter = completer;

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final appInfoOrderA = AppInformation()
          ..sharePDFtexts = {'line1': 'text1', 'line2': 'text2'};
        final appInfoOrderB = AppInformation()
          ..sharePDFtexts = {'line2': 'text2', 'line1': 'text1'};

        final futureA = downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInfoOrderA,
          userInformation: userInformation,
          fileService: fileService,
        );

        final futureB = downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInfoOrderB,
          userInformation: userInformation,
          fileService: fileService,
        );

        completer.complete();
        final results = await Future.wait([futureA, futureB]);
        expect(results[0], results[1]);
        expect(fileService.callLog, ['download']);
      },
    );

    test(
      'should catch FileService download failure, log telemetry, and show failure toast',
      () async {
        fileService.throwOnAction = true;
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
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(result, isNull);
        expect(fileService.callLog, isEmpty);
        expect(loggerService.capturedLogs, hasLength(1));
        expect(
          loggerService.capturedLogs.first,
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Download failed',
          ),
        );
        expect(loggerService.eventOrder, equals(['captureLog', 'showToast']));
        expect(toastCalls, contains(localizations.downloadFailed('male')));
      },
    );
  });

  group('sharePersonalPlanFile', () {
    for (final action in ['share', 'download']) {
      test(
        'should freeze the $action payload before delayed rendering',
        () async {
          await userInformation.saveCustomCategories(
            categories: const [MapEntry('At capture', 'Original notes')],
          );
          final captured = Completer<void>();
          final render = Completer<void>();
          late PersonalPlanExportSnapshot received;
          Future<void> delayedRender(
            PersonalPlanExportSnapshot snapshot,
          ) async {
            received = snapshot;
            captured.complete();
            await render.future;
          }

          fileService.onDownload = delayedRender;
          fileService.onShare = delayedRender;
          final locale = await AppLocalizations.delegate.load(
            const Locale('en'),
          );
          final Future<Object?> export = action == 'share'
              ? sharePersonalPlanFile(
                  message: 'plan',
                  appLocale: locale,
                  gender: 'male',
                  username: 'User',
                  appInformation: appInformation,
                  userInformation: userInformation,
                  fileService: fileService,
                )
              : downloadPersonalPlanFile(
                  appLocale: locale,
                  gender: 'male',
                  username: 'User',
                  appInformation: appInformation,
                  userInformation: userInformation,
                  fileService: fileService,
                );
          await captured.future;
          try {
            await userInformation.saveCustomCategories(
              categories: const [MapEntry('After capture', 'Changed notes')],
            );
            expect(received.data['customCategoryTitles'], ['At capture']);
            expect(received.data['customCategoryDescriptions'], [
              'Original notes',
            ]);
            expect(
              userInformation.customCategories.single.key,
              'After capture',
            );
          } finally {
            render.complete();
          }
          expect(await export, isNotNull);
          expect(fileService.callLog, [action]);
        },
      );
    }

    for (final action in ['share', 'download']) {
      test(
        "should $action an independent source during another store's hydration",
        () async {
          final readStarted = Completer<void>();
          final readGate = Completer<void>();
          memoryService.store[customCategoriesKey] =
              '[{"title":"Saved category","description":"Saved description"}]';
          memoryService.onRead = (key, type) async {
            expect(
              (key, type),
              (customCategoriesKey, PersistentMemoryType.String),
            );
            readStarted.complete();
            await readGate.future;
          };
          final hydration = userInformation.loadCustomCategories();
          await readStarted.future;
          final alternateMemory = _TestPersistentMemoryService();
          alternateMemory.store[customCategoriesKey] =
              '[{"title":"Independent","description":"Independent description"}]';
          final localizations = await AppLocalizations.delegate.load(
            const Locale('en'),
          );
          final Future<Object?> export = action == 'share'
              ? sharePersonalPlanFile(
                  message: 'plan',
                  appLocale: localizations,
                  gender: userInformation.gender,
                  username: userInformation.name,
                  appInformation: appInformation,
                  userInformation: userInformation,
                  fileService: fileService,
                  memoryService: alternateMemory,
                )
              : downloadPersonalPlanFile(
                  appLocale: localizations,
                  gender: userInformation.gender,
                  username: userInformation.name,
                  appInformation: appInformation,
                  userInformation: userInformation,
                  fileService: fileService,
                  memoryService: alternateMemory,
                );
          try {
            await Future<void>.delayed(Duration.zero);
            expect(alternateMemory.writeLog, isEmpty);
            expect(await export, isNotNull);
            expect(fileService.callLog, [action]);
            expect(fileService.lastSnapshot!.data['customCategoryTitles'], [
              'Independent',
            ]);
          } finally {
            readGate.complete();
          }
          await hydration;
          expect(await export, isNotNull);
          final data = await FileServiceImpl.getPrefsData(
            memoryService: alternateMemory,
          );
          expect(data['customCategoryTitles'], ['Independent']);
          expect(data['customCategoryDescriptions'], [
            'Independent description',
          ]);
          expect(alternateMemory.writeLog, isEmpty);
          expect(fileService.callLog, [action]);
        },
      );
    }

    for (final failingKey in [
      'userSelectionPersonalPlan-DreamsAndGoals',
      customCategoriesKey,
    ]) {
      test(
        'should fail without rendering or writing when $failingKey capture fails',
        () async {
          final alternateMemory = _TestPersistentMemoryService();
          final failure = StateError('Snapshot read failed');
          alternateMemory.store[customCategoriesKey] =
              '[{"title":"Independent","description":"Independent description"}]';
          alternateMemory.onRead = (key, _) {
            if (key == failingKey) throw failure;
          };
          final localizations = await AppLocalizations.delegate.load(
            const Locale('en'),
          );
          Future<ShareResult?> share() => sharePersonalPlanFile(
            message: 'plan',
            appLocale: localizations,
            gender: userInformation.gender,
            username: userInformation.name,
            appInformation: appInformation,
            userInformation: userInformation,
            fileService: fileService,
            memoryService: alternateMemory,
          );
          expect(await share(), isNull);
          expect(fileService.callLog, isEmpty);
          expect(loggerService.capturedLogs, [same(failure)]);
          expect(alternateMemory.writeLog, isEmpty);
          alternateMemory.onRead = null;
          expect((await share())?.status, ShareResultStatus.success);
          expect(fileService.lastSnapshot!.data['customCategoryTitles'], [
            'Independent',
          ]);
          expect(alternateMemory.writeLog, isEmpty);
          expect(fileService.callLog, ['share']);
        },
      );
    }

    test(
      'should capture the alternate source without copying the current model',
      () async {
        final alternateMemoryService = _TestPersistentMemoryService();
        alternateMemoryService.store.addAll({
          'userSelectionPersonalPlan-DreamsAndGoals': ['Independent goal'],
          customCategoriesKey:
              '[{"title":"Independent category","description":"Independent description"}]',
        });
        userInformation.updateDreamsAndGoals(
          ['Latest goal'],
          selectionSources: ['custom'],
        );
        userInformation.customCategories = const [
          MapEntry<String, String>('Latest category', 'Latest description'),
        ];
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
          memoryService: alternateMemoryService,
        );
        final exportedData = fileService.lastSnapshot!.data;
        expect(alternateMemoryService.writeLog, isEmpty);

        expect(result?.status, ShareResultStatus.success);
        expect(fileService.lastMemoryService, same(alternateMemoryService));
        expect(exportedData['DreamsAndGoals'], ['Independent goal']);
        expect(exportedData['customCategoryTitles'], ['Independent category']);
        expect(exportedData['customCategoryDescriptions'], [
          'Independent description',
        ]);
      },
    );

    test(
      'should catch preparation persistence failure, log telemetry, and return null',
      () async {
        memoryService.throwOnWrite = true;
        userInformation.dreamsAndGoals = ['Goal 1', 'Goal 2'];
        userInformation.dreamsAndGoalsSelectionSources = ['custom'];

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
        expect(loggerService.capturedLogs, hasLength(1));
        expect(
          loggerService.capturedLogs.first,
          isA<StateError>().having((e) => e.message, 'message', 'Write failed'),
        );
        expect(loggerService.eventOrder, equals(['captureLog']));
      },
    );

    test('should return null when logger throws', () async {
      memoryService.throwOnWrite = true;
      loggerService.throwOnCapture = true;
      userInformation.dreamsAndGoals = ['Goal 1', 'Goal 2'];
      userInformation.dreamsAndGoalsSelectionSources = ['custom'];

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
      expect(loggerService.capturedLogs, hasLength(1));
      expect(
        loggerService.capturedLogs.first,
        isA<StateError>().having((e) => e.message, 'message', 'Write failed'),
      );
      expect(loggerService.eventOrder, equals(['captureLog']));
    });

    test(
      'should return null and log error when FileService is not registered in GetIt and not injected',
      () async {
        await locator.unregister<FileService>();

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
          fileService: null,
        );

        expect(result, isNull);
        expect(loggerService.capturedLogs, hasLength(1));
        expect(loggerService.capturedLogs.first, isA<StateError>());
        expect(loggerService.eventOrder, equals(['captureLog']));
      },
    );

    test(
      'should catch FileService share failure, log telemetry, and return null',
      () async {
        fileService.throwOnAction = true;
        userInformation.updateDreamsAndGoals(
          ['Goal 1', 'Goal 2'],
          selectionSources: ['custom', 'custom'],
        );

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
        expect(fileService.callLog, isEmpty);
        expect(loggerService.capturedLogs, hasLength(1));
        expect(
          loggerService.capturedLogs.first,
          isA<StateError>().having((e) => e.message, 'message', 'Share failed'),
        );
        expect(loggerService.eventOrder, equals(['captureLog']));
      },
    );
  });

  group('LPShareAlertDialog shareFile', () {
    test(
      'should forward to sharePersonalPlanFile with empty message',
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

    test('should await pending saves before sharing', () async {
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
    });

    test(
      'should forward userInformation persistent memory service to FileService share',
      () async {
        final customMemory = _TestPersistentMemoryService();
        final customUser = UserInformation(
          service: customMemory,
          name: 'Custom User',
          gender: 'female',
        );

        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );

        final result = await shareFile(
          localizations,
          customUser.gender,
          customUser.name,
          appInformation,
          userInformation: customUser,
          fileService: fileService,
        );

        expect(result?.status, ShareResultStatus.success);
        expect(fileService.lastMemoryService, same(customMemory));
      },
    );

    test(
      'downloadPersonalPlanFile uses snapshot of sharePDFtexts taken at start of download even if mutated during preparation',
      () async {
        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );
        appInformation.sharePDFtexts = {
          'firstLine': 'Initial First Line',
          'firstLinkURL': 'https://livepositively.club/ok',
        };

        // Hook userInformation preparation to mutate appInformation.sharePDFtexts during await
        userInformation.updateDreamsAndGoals(
          ['Goal 1'],
          selectionSources: ['custom'],
        );
        final downloadFuture = downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        // Mutate live map while download is running
        appInformation.sharePDFtexts = {
          'firstLine': 'Mutated First Line',
          'firstLinkURL': 'https://livepositively.club/mutated',
        };

        final result = await downloadFuture;
        expect(result, isNotNull);
        expect(fileService.lastTexts?['firstLine'], 'Initial First Line');
        expect(
          fileService.lastTexts?['firstLinkURL'],
          'https://livepositively.club/ok',
        );
      },
    );

    test(
      'downloadPersonalPlanFile and sharePersonalPlanFile sanitize untrusted URLs from sharePDFtexts',
      () async {
        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );
        appInformation.sharePDFtexts = {
          'firstLine': 'First Line',
          'firstLinkURL': 'https://livepositively.club/valid',
          'secondLinkURL': 'http://untrusted-http.com',
        };

        await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(
          fileService.lastTexts?['firstLinkURL'],
          'https://livepositively.club/valid',
        );
        expect(fileService.lastTexts?['secondLinkURL'], '');

        appInformation.sharePDFtexts = {
          'firstLine': 'First Line',
          'firstLinkURL': 'javascript:alert(1)',
          'secondLinkURL': 'https://hebsite.livepositively.club/help',
        };

        await sharePersonalPlanFile(
          message: 'msg',
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(fileService.lastTexts?['firstLinkURL'], '');
        expect(
          fileService.lastTexts?['secondLinkURL'],
          'https://hebsite.livepositively.club/help',
        );
      },
    );

    test(
      'PDF link sanitization accepts default port 443 and rejects nonstandard ports',
      () async {
        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );
        appInformation.sharePDFtexts = {
          'firstLinkURL': 'https://livepositively.club:443/secure',
          'secondLinkURL': 'https://livepositively.club:8080/insecure',
        };

        await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
        );

        expect(
          fileService.lastTexts?['firstLinkURL'],
          'https://livepositively.club/secure',
        );
        expect(fileService.lastTexts?['secondLinkURL'], '');
      },
    );

    test(
      'PDF link sanitization supports configurable injected domain allow-list',
      () async {
        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );
        appInformation.sharePDFtexts = {
          'firstLinkURL': 'https://tenant.customdomain.org/resources',
          'secondLinkURL': 'https://livepositively.club/not-allowed-in-custom',
        };

        await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
          approvedPdfHosts: const {'tenant.customdomain.org'},
        );

        expect(
          fileService.lastTexts?['firstLinkURL'],
          'https://tenant.customdomain.org/resources',
        );
        expect(fileService.lastTexts?['secondLinkURL'], '');
      },
    );

    for (final action in ['download', 'share']) {
      test('should use canonical approved hosts throughout $action', () async {
        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );
        appInformation.sharePDFtexts = {
          'firstLinkURL': 'https://tenant.customdomain.org/resources',
          'secondLinkURL':
              'https://tenant.customdomain.org.attacker.example/blocked',
        };
        const hosts = {
          ' TENANT.CustomDomain.org ',
          ' tenant.customdomain.org ',
        };
        if (action == 'download') {
          expect(
            await downloadPersonalPlanFile(
              appLocale: localizations,
              gender: userInformation.gender,
              username: userInformation.name,
              appInformation: appInformation,
              userInformation: userInformation,
              fileService: fileService,
              approvedPdfHosts: hosts,
            ),
            isNotNull,
          );
        } else {
          expect(
            await sharePersonalPlanFile(
              message: 'Plan',
              appLocale: localizations,
              gender: userInformation.gender,
              username: userInformation.name,
              appInformation: appInformation,
              userInformation: userInformation,
              fileService: fileService,
              approvedPdfHosts: hosts,
            ),
            isNotNull,
          );
        }
        expect(fileService.lastTexts, {
          'firstLinkURL': 'https://tenant.customdomain.org/resources',
          'secondLinkURL': '',
        });
        expect(fileService.lastApprovedHosts, {'tenant.customdomain.org'});
        expect(
          () => fileService.lastApprovedHosts!.add('attacker.example'),
          throwsUnsupportedError,
        );
      });
    }

    test(
      'should coalesce equivalent padded and canonical approved hosts',
      () async {
        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );
        appInformation.sharePDFtexts = {
          'firstLinkURL': 'https://tenant.customdomain.org/resources',
        };
        final release = Completer<void>();
        fileService.pendingDownloadCompleter = release;
        final requests = [
          for (final hosts in [
            {' TENANT.CustomDomain.org ', ' tenant.customdomain.org '},
            {'tenant.customdomain.org'},
          ])
            downloadPersonalPlanFile(
              appLocale: localizations,
              gender: userInformation.gender,
              username: userInformation.name,
              appInformation: appInformation,
              userInformation: userInformation,
              fileService: fileService,
              approvedPdfHosts: hosts,
            ),
        ];
        release.complete();
        expect(await Future.wait(requests), [
          '/path/to/downloaded/file.pdf',
          '/path/to/downloaded/file.pdf',
        ]);
        expect(fileService.callLog, ['download']);
        expect(
          fileService.lastTexts!['firstLinkURL'],
          'https://tenant.customdomain.org/resources',
        );
      },
    );

    test(
      'in-flight mutation of caller approvedPdfHosts set does not strand active downloads',
      () async {
        final localizations = await AppLocalizations.delegate.load(
          const Locale('en'),
        );
        appInformation.sharePDFtexts = {
          'firstLinkURL': 'https://tenant.customdomain.org/resources',
        };

        final callerHosts = <String>{'tenant.customdomain.org'};
        final completer = Completer<void>();
        fileService.pendingDownloadCompleter = completer;

        final downloadFuture = downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
          approvedPdfHosts: callerHosts,
        );

        // Mutate caller's set reference during in-flight download
        callerHosts.add('mutated-during-flight.org');
        callerHosts.remove('tenant.customdomain.org');

        completer.complete();
        final firstResult = await downloadFuture;
        expect(firstResult, '/path/to/downloaded/file.pdf');

        // Subsequent download with fresh call completes without interference
        fileService.pendingDownloadCompleter = null;
        final secondResult = await downloadPersonalPlanFile(
          appLocale: localizations,
          gender: userInformation.gender,
          username: userInformation.name,
          appInformation: appInformation,
          userInformation: userInformation,
          fileService: fileService,
          approvedPdfHosts: const {'tenant.customdomain.org'},
        );
        expect(secondResult, '/path/to/downloaded/file.pdf');
      },
    );
  });
}
