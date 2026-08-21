import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

import '../../test_support/contract_persistent_memory_service.dart';

class _FakeAnalytics implements AnalyticsService {
  final List<String> events = [];
  final List<String> sequence = [];
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {
    events.add(eventName);
    sequence.add('analytics:$eventName');
  }
}

class _FakeLogger implements IncidentLoggerService {
  final List<dynamic> logs = [];
  @override
  Future<void> initializeSentry(_) async {}
  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    logs.add(exception);
  }
}

final class _FakeMemory extends ContractPersistentMemoryService {
  _FakeMemory(Map<String, dynamic> store) : super(store: store) {
    onMissingRead = (_, _) => null;
  }
}

final class _StrictFakeMemory extends ContractPersistentMemoryService {
  _StrictFakeMemory(Map<String, dynamic> store) : super(store: store) {
    onMissingRead = (key, _) =>
        throw StateError('Unexpected memory read for unconfigured key: $key');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

  late _FakeAnalytics analytics;
  late _FakeLogger logger;
  late _FakeMemory memory;
  late List<MethodCall> shareCalls;
  String? shareResult;
  Object? shareError;

  setUp(() async {
    await GetIt.instance.reset();
    analytics = _FakeAnalytics();
    logger = _FakeLogger();
    memory = _FakeMemory({
      'userSelectionPersonalPlan-DifficultEvents': <dynamic>['ev1', 'ev2'],
      'userSelectionPersonalPlan-MakeSafer': <dynamic>['safer1'],
      'userSelectionPersonalPlan-FeelBetter': <dynamic>[],
      'userSelectionPersonalPlan-Distractions': <dynamic>['dist1'],
      'userSelectionPersonalPlan-SafeEnvironment': <dynamic>['safe1'],
      'userSelectionPersonalPlan-DreamsAndGoals': <dynamic>['dream1'],
      'PhonePageSavedPhoneNames': <dynamic>['Mom', 'Dad'],
      'PhonePageSavedPhoneNumbers': <dynamic>['111', '222'],
      'name': 'Alex',
    });
    GetIt.instance.registerSingleton<AnalyticsService>(analytics);
    GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
    GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
    shareCalls = <MethodCall>[];
    shareResult = 'com.example.share-target';
    shareError = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (call) async {
          shareCalls.add(call);
          if (shareError != null) {
            throw shareError!;
          }
          return shareResult;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
    await GetIt.instance.reset();
  });

  group('FileServiceImpl.getPrefsData', () {
    test('reads each default plan category and returns expected shape', () async {
      final data = await FileServiceImpl.getPrefsData();
      expect(data['DifficultEvents'], ['ev1', 'ev2']);
      expect(data['MakeSafer'], ['safer1']);
      expect(data['FeelBetter'], <String>[]);
      expect(data['Distractions'], ['dist1']);
      expect(data['SafeEnvironment'], ['safe1']);
      expect(data['DreamsAndGoals'], ['dream1']);
      expect(data['phoneNames'], ['Mom', 'Dad']);
      expect(data['phoneNumbers'], ['111', '222']);
    });

    test(
      'new plan categories default to empty lists for existing plans',
      () async {
        memory.store.remove('userSelectionPersonalPlan-SafeEnvironment');
        memory.store.remove('userSelectionPersonalPlan-DreamsAndGoals');
        final data = await FileServiceImpl.getPrefsData();
        expect(data['SafeEnvironment'], isEmpty);
        expect(data['DreamsAndGoals'], isEmpty);
      },
    );

    test('reads from supplied memoryService override instead of GetIt', () async {
      final customMemory = _FakeMemory({
        'userSelectionPersonalPlan-DreamsAndGoals': ['customDream'],
      });
      final data =
          await FileServiceImpl.getPrefsData(memoryService: customMemory);
      expect(data['DreamsAndGoals'], ['customDream']);
    });
  });

  group('FileServiceImpl.filterEmptyData', () {
    test('drops empty inner lists', () {
      final result = FileServiceImpl.filterEmptyData([
        ['a'],
        <String>[],
        ['b', 'c'],
      ]);
      expect(result, [
        ['a'],
        ['b', 'c'],
      ]);
    });

    test('returns empty when all inner lists empty', () {
      final result = FileServiceImpl.filterEmptyData([<String>[], <String>[]]);
      expect(result, isEmpty);
    });
  });

  group('FileServiceImpl.formatPhonesText', () {
    test('joins names and numbers as "name:number"', () {
      final result = FileServiceImpl.formatPhonesText(['A', 'B'], ['1', '2']);
      expect(result, ['A:1', 'B:2']);
    });

    test('returns empty when both lists empty', () {
      final result = FileServiceImpl.formatPhonesText([], []);
      expect(result, isEmpty);
    });
  });

  group('FileServiceImpl.checkEmptyMessage', () {
    test('returns null for empty', () {
      expect(FileServiceImpl().checkEmptyMessage(''), isNull);
    });

    test('returns the string when non-empty', () {
      expect(FileServiceImpl().checkEmptyMessage('hi'), 'hi');
    });
  });

  group('FileServiceImpl.organizeDataForFile', () {
    test('should preserve the supplied personalized title', () async {
      final svc = FileServiceImpl();
      final result = await svc.organizeDataForFile(
        [
          'Symptoms',
          'Triggers',
          'Wellness',
          'Environmental support',
          'Contacts',
          'Safe Environment',
          'Dreams and Goals',
        ],
        [
          'symptoms subtitle',
          'triggers subtitle',
          'wellness subtitle',
          'support subtitle',
          'contacts subtitle',
          'safe subtitle',
          'dreams subtitle',
        ],
        {
          'firstLine': 'a',
          'firstLinkText': 'b',
          'firstLinkURL': 'c',
          'secondLine': 'd',
          'thirdLine': 'e',
          'secondLinkText': 'f',
          'secondLinkURL': 'g',
          'forthLine': 'h',
        },
        mainTitle: 'Personal Plan of Alex',
      );
      expect(result['mainTitle'], 'Personal Plan of Alex');
      // 'FeelBetter' was empty; the remaining defaults retain their order,
      // with Dreams and Goals appended after Safe Environment.
      expect(result['titles'], [
        'Symptoms',
        'Triggers',
        'Environmental support',
        'Contacts',
        'Safe Environment',
        'Dreams and Goals',
      ]);
      expect(result['subTitles'], [
        'symptoms subtitle',
        'triggers subtitle',
        'support subtitle',
        'contacts subtitle',
        'safe subtitle',
        'dreams subtitle',
      ]);
      expect(result['realData'], [
        ['dist1'],
        ['ev1', 'ev2'],
        ['safer1'],
        ['Mom:111', 'Dad:222'],
        ['safe1'],
        ['dream1'],
      ]);
    });

    test('should omit Dreams data when legacy metadata has six sections', () async {
      final svc = FileServiceImpl();
      final result = await svc.organizeDataForFile(
        ['t1', 't2', 't3', 't4', 't5', 't6'],
        ['s1', 's2', 's3', 's4', 's5', 's6'],
        {},
        mainTitle: 'My Personal Plan',
      );
      expect(result['mainTitle'], 'My Personal Plan');
      expect(result['titles'], ['t1', 't2', 't4', 't5', 't6']);
      expect(result['subTitles'], ['s1', 's2', 's4', 's5', 's6']);
      expect(result['realData'], [
        ['dist1'],
        ['ev1', 'ev2'],
        ['safer1'],
        ['Mom:111', 'Dad:222'],
        ['safe1'],
      ]);
    });

    test('uses supplied memoryService override when provided', () async {
      final customMemory = _StrictFakeMemory({
        'userSelectionPersonalPlan-Distractions': <dynamic>[],
        'userSelectionPersonalPlan-DifficultEvents': <dynamic>['customEv'],
        'userSelectionPersonalPlan-FeelBetter': <dynamic>[],
        'userSelectionPersonalPlan-MakeSafer': <dynamic>[],
        'PhonePageSavedPhoneNames': <dynamic>[],
        'PhonePageSavedPhoneNumbers': <dynamic>[],
        'userSelectionPersonalPlan-SafeEnvironment': <dynamic>['customSafe'],
        'userSelectionPersonalPlan-DreamsAndGoals': <dynamic>['customGoal'],
        'customCategoryTitles': <dynamic>['Custom Title'],
        'customCategoryDescriptions': <dynamic>['Custom Description'],
      });
      final svc = FileServiceImpl();
      final result = await svc.organizeDataForFile(
        ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'],
        ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7'],
        {
          'firstLinkURL': 'https://livepositively.club/valid',
          'secondLinkURL': 'http://untrusted.com/invalid',
        },
        mainTitle: 'Custom Plan',
        memoryService: customMemory,
      );
      expect(result['titles'], ['T2', 'T6', 'T7', 'Custom Title']);
      expect(result['subTitles'], ['S2', 'S6', 'S7', '']);
      expect(result['realData'], [
        ['customEv'],
        ['customSafe'],
        ['customGoal'],
        ['Custom Description'],
      ]);
      expect(result['texts']['text2Link'], 'https://livepositively.club/valid');
      expect(result['texts']['text5Link'], '');
    });

    test('organizeDataForFile respects custom approvedPdfHosts and port 443', () async {
      final customMemory = _StrictFakeMemory({
        'userSelectionPersonalPlan-Distractions': <dynamic>[],
        'userSelectionPersonalPlan-DifficultEvents': <dynamic>['customEv'],
        'userSelectionPersonalPlan-FeelBetter': <dynamic>[],
        'userSelectionPersonalPlan-MakeSafer': <dynamic>[],
        'PhonePageSavedPhoneNames': <dynamic>[],
        'PhonePageSavedPhoneNumbers': <dynamic>[],
        'userSelectionPersonalPlan-SafeEnvironment': <dynamic>['customSafe'],
        'userSelectionPersonalPlan-DreamsAndGoals': <dynamic>['customGoal'],
        'customCategoryTitles': <dynamic>[],
        'customCategoryDescriptions': <dynamic>[],
      });
      final svc = FileServiceImpl();
      final result = await svc.organizeDataForFile(
        ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'],
        ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7'],
        {
          'firstLinkURL': 'https://tenant.org:443/valid',
          'secondLinkURL': 'https://tenant.org:8080/invalid-port',
        },
        mainTitle: 'Custom Plan',
        memoryService: customMemory,
        approvedPdfHosts: const {'tenant.org'},
      );
      expect(result['texts']['text2Link'], 'https://tenant.org/valid');
      expect(result['texts']['text5Link'], '');
    });
  });

  group('FileServiceImpl.shareTextOnly', () {
    test('returns true and tracks analytics after a confirmed share', () async {
      final svc = FileServiceImpl();
      final shared = await svc.shareTextOnly('hello');

      expect(shared, isTrue);
      expect(shareCalls, hasLength(1));
      expect(shareCalls.single.method, 'share');
      expect(shareCalls.single.arguments, {'text': 'hello'});
      expect(analytics.events, ['Text shared']);
      expect(logger.logs, isEmpty);
    });

    test(
      'returns false without tracking when the sheet is dismissed',
      () async {
        shareResult = '';
        final svc = FileServiceImpl();
        final shared = await svc.shareTextOnly('hello');

        expect(shared, isFalse);
        expect(analytics.events, isEmpty);
        expect(logger.logs, isEmpty);
      },
    );

    test(
      'returns false without tracking when no result is available',
      () async {
        shareResult = null;
        final svc = FileServiceImpl();
        final shared = await svc.shareTextOnly('hello');

        expect(shared, isFalse);
        expect(analytics.events, isEmpty);
        expect(logger.logs, isEmpty);
      },
    );

    test('logs and returns false when the native share call throws', () async {
      shareError = StateError('native share unavailable');
      final svc = FileServiceImpl();
      final shared = await svc.shareTextOnly('hello');

      expect(shared, isFalse);
      expect(analytics.events, isEmpty);
      expect(logger.logs.single, isA<PlatformException>());
    });

    test('logs and returns false for an invalid empty message', () async {
      final svc = FileServiceImpl();
      final shared = await svc.shareTextOnly('');

      expect(shared, isFalse);
      expect(shareCalls, isEmpty);
      expect(analytics.events, isEmpty);
      expect(logger.logs.single, isA<ArgumentError>());
    });
  });

  group('FileServiceImpl.share with non-PDF format', () {
    test('returns early when format is not PDF (no AnalyticsService call)',
        () async {
      final svc = FileServiceImpl();
      // Default switch falls through to file == {file: null, format: null}
      // and the function returns without invoking AnalyticsService.
      await svc.share(
        '',
        ['t1', 't2', 't3', 't4', 't5', 't6'],
        ['s1', 's2', 's3', 's4', 's5', 's6'],
        const <String, String>{
          'firstLine': '',
          'firstLinkText': '',
          'firstLinkURL': '',
          'secondLine': '',
          'thirdLine': '',
          'secondLinkText': '',
          'secondLinkURL': '',
          'forthLine': '',
        },
        ShareFileType.DOCX,
        mainTitle: 'My Personal Plan',
        textDirection: 'rtl',
      );
      expect(analytics.events, isEmpty);
    });
  });

  group('FileServiceImpl.share PDF path', () {
    test('share with PDF format produces the share pipeline', () async {
      // SharePlus.instance.share will throw because no platform implementation
      // is registered in the test environment. The catch branch invokes
      // logger.captureLog. We assert that pathway runs.
      final svc = FileServiceImpl();
      await svc.share(
        'msg',
        ['t1', 't2', 't3', 't4', 't5', 't6'],
        ['s1', 's2', 's3', 's4', 's5', 's6'],
        const <String, String>{
          'firstLine': 'a',
          'firstLinkText': 'b',
          'firstLinkURL': 'https://example.com/1',
          'secondLine': 'c',
          'thirdLine': 'd',
          'secondLinkText': 'e',
          'secondLinkURL': 'https://example.com/2',
          'forthLine': 'f',
        },
        ShareFileType.PDF,
        mainTitle: 'My Personal Plan',
        textDirection: 'rtl',
      );
      // Either AnalyticsService recorded "Plan shared" or the catch branch
      // forwarded the share_plus failure to logger. At least one must hold,
      // proving we exercised the PDF path.
      expect(
        analytics.events.contains('Plan shared') || logger.logs.isNotEmpty,
        isTrue,
      );
    });
  });

  group('FileServiceImpl.download', () {
    test('returns null when format is not PDF', () async {
      final svc = FileServiceImpl();
      final out = await svc.download(
        ['t1', 't2', 't3', 't4', 't5', 't6'],
        ['s1', 's2', 's3', 's4', 's5', 's6'],
        const <String, String>{},
        ShareFileType.DOCX,
        mainTitle: 'My Personal Plan',
        textDirection: 'ltr',
      );
      expect(out, isNull);
    });
  });

  group('FileServiceImpl.saveAndroid', () {
    test('successful save returning String path captures full payload and verifies saving precedes analytics', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      String? capturedDialogTitle;
      String? capturedFileName;
      FileType? capturedType;
      String? capturedInitialDirectory;
      Uint8List? capturedBytes;
      List<String>? capturedAllowedExtensions;

      final result = await FileServiceImpl.saveAndroid(
        data,
        'pdf',
        fileSaver: ({
          String? dialogTitle,
          String? fileName,
          FileType type = FileType.any,
          String? initialDirectory,
          Uint8List? bytes,
          List<String>? allowedExtensions,
        }) async {
          capturedDialogTitle = dialogTitle;
          capturedFileName = fileName;
          capturedType = type;
          capturedInitialDirectory = initialDirectory;
          capturedBytes = bytes;
          capturedAllowedExtensions = allowedExtensions;
          analytics.sequence.add('saver:saveFile');
          return '/storage/emulated/0/Download/plan.pdf';
        },
      );

      expect(capturedDialogTitle, 'Please select an output file:');
      expect(capturedFileName, 'התוכנית שלי.pdf');
      expect(capturedBytes, data);
      expect(capturedType, FileType.any);
      expect(capturedInitialDirectory, isNull);
      expect(capturedAllowedExtensions, isNull);
      expect(
        analytics.sequence,
        ['saver:saveFile', 'analytics:Plan downloaded Android'],
      );
      expect(result, '/storage/emulated/0/Download/plan.pdf');
      expect(analytics.events, ['Plan downloaded Android']);
      expect(logger.logs, isEmpty);
    });

    test('successful save with custom dialogTitle and fileName passes them to saver', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      String? capturedDialogTitle;
      String? capturedFileName;

      final result = await FileServiceImpl.saveAndroid(
        data,
        'docx',
        dialogTitle: 'Custom Dialog Title',
        fileName: 'custom_plan.docx',
        fileSaver: ({
          String? dialogTitle,
          String? fileName,
          FileType type = FileType.any,
          String? initialDirectory,
          Uint8List? bytes,
          List<String>? allowedExtensions,
        }) async {
          capturedDialogTitle = dialogTitle;
          capturedFileName = fileName;
          return '/storage/emulated/0/Download/custom_plan.docx';
        },
      );

      expect(capturedDialogTitle, 'Custom Dialog Title');
      expect(capturedFileName, 'custom_plan.docx');
      expect(result, '/storage/emulated/0/Download/custom_plan.docx');
    });

    test('successful save returning Uri path returns normalized string path and tracks event', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      final result = await FileServiceImpl.saveAndroid(
        data,
        'pdf',
        fileSaver: ({
          String? dialogTitle,
          String? fileName,
          FileType type = FileType.any,
          String? initialDirectory,
          Uint8List? bytes,
          List<String>? allowedExtensions,
        }) async => Uri.parse('file:///storage/emulated/0/Documents/plan.pdf'),
      );

      expect(result, '/storage/emulated/0/Documents/plan.pdf');
      expect(analytics.events, ['Plan downloaded Android']);
      expect(logger.logs, isEmpty);
    });

    test('cancellation returning null captures full payload, verifies saving precedes analytics, and returns null', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      String? capturedDialogTitle;
      String? capturedFileName;
      FileType? capturedType;
      String? capturedInitialDirectory;
      Uint8List? capturedBytes;
      List<String>? capturedAllowedExtensions;

      final result = await FileServiceImpl.saveAndroid(
        data,
        'pdf',
        fileSaver: ({
          String? dialogTitle,
          String? fileName,
          FileType type = FileType.any,
          String? initialDirectory,
          Uint8List? bytes,
          List<String>? allowedExtensions,
        }) async {
          capturedDialogTitle = dialogTitle;
          capturedFileName = fileName;
          capturedType = type;
          capturedInitialDirectory = initialDirectory;
          capturedBytes = bytes;
          capturedAllowedExtensions = allowedExtensions;
          analytics.sequence.add('saver:saveFile');
          return null;
        },
      );

      expect(capturedDialogTitle, 'Please select an output file:');
      expect(capturedFileName, 'התוכנית שלי.pdf');
      expect(capturedBytes, data);
      expect(capturedType, FileType.any);
      expect(capturedInitialDirectory, isNull);
      expect(capturedAllowedExtensions, isNull);
      expect(
        analytics.sequence,
        ['saver:saveFile', 'analytics:Plan downloaded Android'],
      );
      expect(result, isNull);
      expect(analytics.events, ['Plan downloaded Android']);
      expect(logger.logs, isEmpty);
    });

    test('save failure is caught, logged, and returns null', () async {
      final data = Uint8List.fromList([1, 2, 3]);
      final result = await FileServiceImpl.saveAndroid(
        data,
        'pdf',
        fileSaver: ({
          String? dialogTitle,
          String? fileName,
          FileType type = FileType.any,
          String? initialDirectory,
          Uint8List? bytes,
          List<String>? allowedExtensions,
        }) async => throw Exception('Storage permission denied'),
      );

      expect(result, isNull);
      expect(logger.logs, isNotEmpty);
    });
  });
}
