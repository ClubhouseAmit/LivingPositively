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
//   - `loadImagePaths` error path captures via the registered
//     IncidentLoggerService when the persisted file is absent
//
// The actual ImagePicker.pickImage path requires native code so we don't
// drive it.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/logger_service.dart';

class _CapturingLogger implements IncidentLoggerService {
  final List<dynamic> captured = [];
  @override
  Future<void> initializeSentry(Widget myApp) async {}
  @override
  Future<void> captureLog(dynamic exception,
      {StackTrace? stackTrace, dynamic exceptionData}) async {
    captured.add(exception);
  }
}

class _NoopAnalytics implements AnalyticsService {
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(String eventName,
      [Map<String, dynamic>? properties]) async {}
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

  tearDown(() {
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
    expect((img as Image).fit, BoxFit.cover);
  });

  test('getOnlineImage returns Image.network for url', () {
    final svc = ImagePickerServiceImpl();
    final img = svc.getOnlineImage('https://example.com/x.png');
    expect(img, isA<Image>());
  });

  test('saveImagePaths persists list, loadImagePaths reads it back',
      () async {
    final svc = ImagePickerServiceImpl();
    final paths = ['/a/b.png', '/c/d.png'];
    final file = await svc.saveImagePaths(paths);
    expect(file.existsSync(), isTrue);

    final loaded = <String>[];
    await svc.loadImagePaths(loaded);
    expect(loaded, equals(paths));
  });

  test('loadImagePaths on missing file captures error via logger', () async {
    final svc = ImagePickerServiceImpl();
    final loaded = <String>[];
    // No file written yet; readAsString will throw.
    await svc.loadImagePaths(loaded);
    expect(logger.captured, isNotEmpty);
  });

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
}
