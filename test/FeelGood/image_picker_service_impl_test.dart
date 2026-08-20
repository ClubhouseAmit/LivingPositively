// Unit tests for ImagePickerServiceImpl - the production implementation
// behind the abstract ImagePickerService interface.
//
// The class wraps `image_picker`, `path_provider`, and direct File I/O. We
// focus on the pure-Dart paths that do not depend on the platform image
// picker dialog:
//   - `displayImage(path)` returns a configured Image.file
//   - `getOnlineImage(url)` returns Image.network
//   - `deleteImage(index, paths)` deletes the file + removes from the list
//   - `loadImagePaths` reads back what `saveImagePaths` wrote (using a
//     `path_provider` mock that returns a real OS temp dir)
//   - `loadImagePaths` treats a missing manifest as the empty first-run
//     state: returns normally, leaves the list empty, logs nothing
//     (genuine read failures are covered by the widget test in
//     test/pages/FeelGood/feel_good_async_error_test.dart)
//
// The actual ImagePicker.pickImage path requires native code so we don't
// drive it.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/logger_service.dart';

import '../../test_support/contract_persistent_memory_service.dart';

class _CapturingLogger implements IncidentLoggerService {
  final List<dynamic> captured = [];
  @override
  Future<void> initializeSentry(Widget myApp) async {}
  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    captured.add(exception);
  }
}

class _NoopAnalytics implements AnalyticsService {
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDir;
  late _CapturingLogger logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('image_picker_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tempDir.path);
    logger = _CapturingLogger();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<IncidentLoggerService>()) {
      getIt.unregister<IncidentLoggerService>();
    }
    if (getIt.isRegistered<AnalyticsService>()) {
      getIt.unregister<AnalyticsService>();
    }
    getIt.registerSingleton<IncidentLoggerService>(logger);
    getIt.registerSingleton<AnalyticsService>(_NoopAnalytics());
  });

  tearDown(() async {
    // Drain any unawaited `saveImagePaths` futures spawned by deleteImage /
    // deleteImages / getImage. The production code fires those without
    // `await` (see lib/pages/FeelGood/image_picker_service_impl.dart lines
    // 38, 61, 80), so they race against the tempDir cleanup below. Without
    // this delay the post-test write would land in a now-deleted directory
    // and the test framework reports it as an "after-test" failure on CI
    // (where I/O timing is tighter than on the dev machine).
    await Future<void>.delayed(const Duration(milliseconds: 50));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    // Best-effort cleanup. Windows may still hold a handle on freshly-written
    // files; the OS will reap the temp dir on its own.
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
    GetIt.instance.reset();
  });

  test('displayImage returns Image.file with provided path + BoxFit', () {
    final svc = ImagePickerServiceImpl();
    final img = svc.displayImage('/some/where.png', fit: BoxFit.cover);
    expect(img, isA<Image>());
    expect((img).fit, BoxFit.cover);
  });

  test('getOnlineImage returns Image.network for url', () {
    final svc = ImagePickerServiceImpl();
    final img = svc.getOnlineImage('https://example.com/x.png');
    expect(img, isA<Image>());
  });

  test('saveImagePaths persists list, loadImagePaths reads it back', () async {
    final svc = ImagePickerServiceImpl();
    final paths = ['/a/b.png', '/c/d.png'];
    final file = await svc.saveImagePaths(paths);
    expect(file.existsSync(), isTrue);

    final loaded = <String>[];
    await svc.loadImagePaths(loaded);
    expect(loaded, equals(paths));
  });

  test(
    'loadImagePaths on missing file returns empty without logging an error',
    () async {
      final svc = ImagePickerServiceImpl();
      final loaded = <String>[];
      // No file written yet. Phase E (ADR-005 §Decision step 5): a missing
      // manifest is the empty first-run state, NOT an error — loadImagePaths
      // must return normally, leave the list empty, and log nothing, so
      // AsyncStateView stays out of its error branch and the Feel Good grid
      // shows its add affordance. Genuine read failures (manifest present but
      // unreadable) are logged + rethrown and covered by the widget test.
      await svc.loadImagePaths(loaded);
      expect(loaded, isEmpty);
      expect(logger.captured, isEmpty);
    },
  );

  test('deleteImage removes entry at index and the file on disk', () async {
    final svc = ImagePickerServiceImpl();
    // Create two real temporary files so deleteSync succeeds.
    final f1 = File('${tempDir.path}/i1.png')..writeAsStringSync('x');
    final f2 = File('${tempDir.path}/i2.png')..writeAsStringSync('y');
    final paths = [f1.path, f2.path];
    svc.deleteImage(0, paths);
    expect(paths.length, 1);
    expect(paths.first, f2.path);
    expect(f1.existsSync(), isFalse);
  });

  test('deleteImages drains saved-path list, deleting each file', () async {
    final svc = ImagePickerServiceImpl();
    final f1 = File('${tempDir.path}/d1.png')..writeAsStringSync('x');
    final f2 = File('${tempDir.path}/d2.png')..writeAsStringSync('y');
    await svc.saveImagePaths([f1.path, f2.path]);

    await svc.deleteImages();
    expect(f1.existsSync(), isFalse);
    expect(f2.existsSync(), isFalse);
  });

  test('downloadImage returns null when source image file does not exist', () async {
    final svc = ImagePickerServiceImpl();
    final result = await svc.downloadImage('${tempDir.path}/nonexistent.png');
    expect(result, isNull);
  });

  test('downloadImage returns destination path on success and preserves source extension', () async {
    final sourceFile = File('${tempDir.path}/picture.png')
      ..writeAsBytesSync([1, 2, 3, 4]);

    String? capturedDialogTitle;
    String? capturedFileName;
    Uint8List? capturedBytes;
    int saveFileCalls = 0;

    final svc = ImagePickerServiceImpl(
      fileSaver: ({
        String? dialogTitle,
        String? fileName,
        FileType type = FileType.any,
        String? initialDirectory,
        Uint8List? bytes,
        List<String>? allowedExtensions,
      }) async {
        saveFileCalls++;
        capturedDialogTitle = dialogTitle;
        capturedFileName = fileName;
        capturedBytes = bytes;
        return '${tempDir.path}/saved_$fileName';
      },
    );

    final result = await svc.downloadImage(
      sourceFile.path,
      dialogTitle: 'Download photo',
    );

    expect(saveFileCalls, 1);
    expect(capturedDialogTitle, 'Download photo');
    expect(capturedFileName, startsWith('feel_good_'));
    expect(capturedFileName, endsWith('.png'));
    expect(capturedBytes, [1, 2, 3, 4]);
    expect(result, '${tempDir.path}/saved_$capturedFileName');
  });

  test('saveImageRotations verifies contract and persists serialized list', () async {
    final memory = _FakePersistentMemory();
    final svc = ImagePickerServiceImpl(
      persistentMemoryService: memory,
      loggerService: logger,
    );
    await svc.saveImageRotations({'/path/1.jpg': 1, '/path/2.png': 3});

    expect(memory.lastSetKey, 'feelGoodImageRotations');
    expect(memory.lastSetType, PersistentMemoryType.StringList);
    expect(memory.lastSetValue, containsAll(['/path/1.jpg:1', '/path/2.png:3']));
  });

  test('loadImageRotations normalizes out-of-range legacy entries', () async {
    final memory = _FakePersistentMemory();
    await memory.setItem(
      'feelGoodImageRotations',
      PersistentMemoryType.StringList,
      ['/path/legacy.jpg:7', '/path/normal.png:2'],
    );

    final svc = ImagePickerServiceImpl(
      persistentMemoryService: memory,
      loggerService: logger,
    );
    final loaded = await svc.loadImageRotations();
    expect(loaded['/path/legacy.jpg'], 3); // 7 % 4 = 3
    expect(loaded['/path/normal.png'], 2);
  });

  test('loadImageRotations returns empty map when nothing is saved', () async {
    final memory = _FakePersistentMemory();
    final svc = ImagePickerServiceImpl(
      persistentMemoryService: memory,
      loggerService: logger,
    );
    final loaded = await svc.loadImageRotations();
    expect(loaded, isEmpty);
  });

  test('ImagePickerServiceImpl works with injected analytics, logger, and memory without GetIt', () async {
    final memory = _FakePersistentMemory();
    final noopAnalytics = _NoopAnalytics();
    final svc = ImagePickerServiceImpl(
      persistentMemoryService: memory,
      analyticsService: noopAnalytics,
      loggerService: logger,
    );

    await svc.saveImageRotations({'/path/test.jpg': 2});
    final loaded = await svc.loadImageRotations();
    expect(loaded, {'/path/test.jpg': 2});
  });

  test('downloadImage returns destination path even if analytics tracking throws', () async {
    final sourceFile = File('${tempDir.path}/picture.png')
      ..writeAsBytesSync([1, 2, 3, 4]);

    final svc = ImagePickerServiceImpl(
      analyticsService: _FailingAnalytics(),
      loggerService: logger,
      fileSaver: ({
        String? dialogTitle,
        String? fileName,
        FileType type = FileType.any,
        String? initialDirectory,
        Uint8List? bytes,
        List<String>? allowedExtensions,
      }) async {
        return '${tempDir.path}/saved_$fileName';
      },
    );

    final result = await svc.downloadImage(sourceFile.path);
    expect(result, isNotNull);
    expect(result, contains('saved_feel_good_'));
    expect(result, endsWith('.png'));
    expect(logger.captured, isNotEmpty);
    expect(logger.captured.first.toString(), contains('Analytics uninitialized'));
  });

  test('downloadImage correctly derives extension when path contains dotted directory names', () async {
    final subDir = Directory('${tempDir.path}/folder.2024')..createSync();
    final sourceFile = File('${subDir.path}/photo.webp')
      ..writeAsBytesSync([1, 2, 3]);

    String? capturedFileName;
    final svc = ImagePickerServiceImpl(
      fileSaver: ({
        String? dialogTitle,
        String? fileName,
        FileType type = FileType.any,
        String? initialDirectory,
        Uint8List? bytes,
        List<String>? allowedExtensions,
      }) async {
        capturedFileName = fileName;
        return '${tempDir.path}/saved';
      },
    );

    await svc.downloadImage(sourceFile.path);
    expect(capturedFileName, endsWith('.webp'));
    expect(capturedFileName, isNot(contains('folder')));
  });

  test('downloadImage returns destination path even if both analytics and logger throw', () async {
    final sourceFile = File('${tempDir.path}/picture.png')
      ..writeAsBytesSync([1, 2, 3, 4]);

    final svc = ImagePickerServiceImpl(
      analyticsService: _FailingAnalytics(),
      loggerService: _ThrowingLogger(),
      fileSaver: ({
        String? dialogTitle,
        String? fileName,
        FileType type = FileType.any,
        String? initialDirectory,
        Uint8List? bytes,
        List<String>? allowedExtensions,
      }) async {
        return '${tempDir.path}/saved_$fileName';
      },
    );

    final result = await svc.downloadImage(sourceFile.path);
    expect(result, isNotNull);
    expect(result, contains('saved_feel_good_'));
    expect(result, endsWith('.png'));
  });
}

class _ThrowingLogger implements IncidentLoggerService {
  @override
  Future<void> initializeSentry(Widget myApp) async {}

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    throw Exception('Logger exception');
  }
}

class _FailingAnalytics implements AnalyticsService {
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) async {
    throw Exception('Analytics uninitialized');
  }
}

final class _FakePersistentMemory extends ContractPersistentMemoryService {
  _FakePersistentMemory() {
    onMissingRead = (_, _) => null;
    onSetItemCompleted = (key, type, value) {
      lastSetKey = key;
      lastSetType = type;
      lastSetValue = value;
    };
  }

  String? lastSetKey;
  PersistentMemoryType? lastSetType;
  dynamic lastSetValue;
}
