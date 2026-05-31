// Shared test scaffold for widget tests that exercise REAL production widgets.
//
// Resets GetIt and registers lightweight in-memory fakes for the services the
// production code reaches for via service location. Provides a
// [pumpWithProviders] helper that wraps a widget in MultiProvider +
// MaterialApp + ScreenUtilInit with localization wired up, so widgets that
// depend on AppLocalizations / Provider.of<UserInformation>() / etc. build
// the same way they do at runtime.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory implementation of [PersistentMemoryService] backed by a [Map].
///
/// Avoids reaching for shared_preferences platform channels in widget tests
/// while still exercising the real [setItem]/[getItem]/[reset] code paths in
/// the widgets under test.
class FakePersistentMemoryService implements PersistentMemoryService {
  final Map<String, dynamic> store = <String, dynamic>{};

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    final value = store[key];
    if (value != null) return value;
    switch (type) {
      case PersistentMemoryType.String:
        return '';
      case PersistentMemoryType.Int:
        return 0;
      case PersistentMemoryType.Double:
        return 0.0;
      case PersistentMemoryType.Bool:
        return false;
      case PersistentMemoryType.StringList:
        return <String>[];
    }
  }

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (key.isEmpty || value == null) return;
    if (type == PersistentMemoryType.StringList) {
      store[key] = List<String>.from(value as Iterable);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<void> reset() async {
    store.clear();
  }
}

/// No-op logger that records exceptions for assertions if needed.
class NoopIncidentLoggerService implements IncidentLoggerService {
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

/// Records analytics events without hitting Mixpanel.
class NoopAnalyticsService implements AnalyticsService {
  final List<MapEntry<String, Map<String, dynamic>?>> events = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {
    events.add(MapEntry(eventName, properties));
  }
}

/// No-op file service for share/download flows.
class NoopFileService implements FileService {
  int shareCalls = 0;
  int downloadCalls = 0;
  int shareTextCalls = 0;

  @override
  Future<String?> download(
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat,
    String textDirection,
  ) async {
    downloadCalls++;
    return null;
  }

  @override
  Future<void> share(
    String message,
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat,
    String textDirection,
  ) async {
    shareCalls++;
  }

  @override
  Future<void> shareTextOnly(String message) async {
    shareTextCalls++;
  }
}

/// Image picker that returns null/empty results so widgets can build without
/// touching real files.
class NoopImagePickerService implements ImagePickerService {
  @override
  Future<XFile?> pickImage({required ImageSource source}) async => null;

  @override
  Future<File> saveImagePaths(List<String> imagePaths) async {
    // Do not touch the filesystem in tests.
    return File('${Directory.systemTemp.path}/aqe-image-paths.txt');
  }

  @override
  Future<void> getImage(String source, List<String> imagePaths) async {}

  @override
  void deleteImage(int index, List<String> imagePaths) {
    if (index >= 0 && index < imagePaths.length) {
      imagePaths.removeAt(index);
    }
  }

  @override
  Future<void> loadImagePaths(List<String> imagePaths) async {}

  @override
  displayImage(String path, {BoxFit fit = BoxFit.none}) {
    return Image.memory(
      Uint8List(0),
      fit: fit,
      errorBuilder: (_, _, _) {
        return SizedBox.shrink(key: Key('test-image-$path'));
      },
    );
  }

  @override
  Widget getOnlineImage(String url) =>
      SizedBox.shrink(key: Key('test-online-$url'));

  @override
  Future<void> deleteImages() async {}
}

/// Simple [LocaleService] that returns the locale provided at construction.
class FakeLocaleService implements LocaleService {
  String _locale;
  FakeLocaleService([this._locale = 'en']);

  @override
  String getLocale() => _locale;

  @override
  void setLocale(String? locale) {
    if (locale != null) _locale = locale;
  }
}

/// VideoPlayer factory that returns a plain [Container] so widgets that embed
/// the wellness video player can build without invoking the real
/// [YoutubePlayerController] (which requires native code).
class FakeVideoPlayerPageFactory implements VideoPlayerPageFactory {
  @override
  Widget create({
    required Function(bool) onFullScreenChanged,
    required Map<String, List<String>> videoData,
  }) {
    return Container(key: const Key('fake-video-player'));
  }
}

/// Resets [GetIt] and registers the lightweight fakes used by widget tests.
///
/// Returns the registered fakes so individual tests can introspect/assert
/// against them (e.g., verify analytics events fired, verify keys persisted).
TestServiceLocators registerTestServices({String locale = 'en'}) {
  final getIt = GetIt.instance;
  if (getIt.isRegistered<PersistentMemoryService>()) {
    getIt.unregister<PersistentMemoryService>();
  }
  if (getIt.isRegistered<IncidentLoggerService>()) {
    getIt.unregister<IncidentLoggerService>();
  }
  if (getIt.isRegistered<AnalyticsService>()) {
    getIt.unregister<AnalyticsService>();
  }
  if (getIt.isRegistered<FileService>()) {
    getIt.unregister<FileService>();
  }
  if (getIt.isRegistered<ImagePickerService>()) {
    getIt.unregister<ImagePickerService>();
  }
  if (getIt.isRegistered<LocaleService>()) {
    getIt.unregister<LocaleService>();
  }
  if (getIt.isRegistered<VideoPlayerPageFactory>()) {
    getIt.unregister<VideoPlayerPageFactory>();
  }

  final memory = FakePersistentMemoryService();
  final logger = NoopIncidentLoggerService();
  final analytics = NoopAnalyticsService();
  final files = NoopFileService();
  final picker = NoopImagePickerService();
  final localeService = FakeLocaleService(locale);
  final videoFactory = FakeVideoPlayerPageFactory();

  getIt.registerSingleton<PersistentMemoryService>(memory);
  getIt.registerSingleton<IncidentLoggerService>(logger);
  getIt.registerSingleton<AnalyticsService>(analytics);
  getIt.registerSingleton<FileService>(files);
  getIt.registerSingleton<ImagePickerService>(picker);
  getIt.registerSingleton<LocaleService>(localeService);
  getIt.registerSingleton<VideoPlayerPageFactory>(videoFactory);

  return TestServiceLocators(
    memory: memory,
    logger: logger,
    analytics: analytics,
    files: files,
    picker: picker,
    localeService: localeService,
    videoFactory: videoFactory,
  );
}

void resetTestServices() {
  GetIt.instance.reset();
}

class TestServiceLocators {
  final FakePersistentMemoryService memory;
  final NoopIncidentLoggerService logger;
  final NoopAnalyticsService analytics;
  final NoopFileService files;
  final NoopImagePickerService picker;
  final FakeLocaleService localeService;
  final FakeVideoPlayerPageFactory videoFactory;
  TestServiceLocators({
    required this.memory,
    required this.logger,
    required this.analytics,
    required this.files,
    required this.picker,
    required this.localeService,
    required this.videoFactory,
  });
}

/// Wraps [child] in MultiProvider + MaterialApp + ScreenUtilInit so it builds
/// with real [UserInformation], [AppInformation], [AppLocalizations] and
/// screen-util sizing the way the production code expects.
///
/// When [ignoreOverflow] is `true` (the default) any RenderFlex overflow
/// exceptions raised during the initial pump are drained so tests can focus
/// on behaviour rather than pixel-perfect layout. Other exceptions are
/// re-thrown so real failures still surface loudly.
Future<void> pumpWithProviders(
  WidgetTester tester,
  Widget child, {
  UserInformation? userInformation,
  AppInformation? appInformation,
  Locale locale = const Locale('en'),
  Size designSize = const Size(360, 690),
  Size? surfaceSize,
  bool ignoreOverflow = true,
}) async {
  final user = userInformation ?? UserInformation();
  final app = appInformation ?? AppInformation();

  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserInformation>.value(value: user),
        ChangeNotifierProvider<AppInformation>.value(value: app),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ScreenUtilInit(
          designSize: designSize,
          child: Builder(builder: (context) => child),
        ),
      ),
    ),
  );
  // Allow ScreenUtilInit to lay itself out before tests exercise the child.
  await tester.pump();
  if (ignoreOverflow) {
    drainOverflowExceptions(tester);
  }
}

/// Drains any layout-overflow exceptions from the binding so a test can
/// continue exercising real production widgets without being failed by
/// (often-cosmetic) RenderFlex overflows. Returns a list of the exceptions
/// drained for diagnostic asserts.
List<dynamic> drainOverflowExceptions(WidgetTester tester) {
  final drained = <dynamic>[];
  while (true) {
    final ex = tester.takeException();
    if (ex == null) break;
    drained.add(ex);
    final asString = ex.toString();
    if (!asString.contains('RenderFlex overflowed') &&
        !asString.contains('A RenderFlex overflowed')) {
      // Surface non-overflow exceptions so tests still fail loudly on real
      // bugs.
      throw ex as Object;
    }
  }
  return drained;
}
