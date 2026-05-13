import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'TestMenu.dart';
import 'test_data.dart';

class _FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> init() async {}

  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {}
}

class _FakePersistentMemoryService implements PersistentMemoryService {
  _FakePersistentMemoryService({
    Map<String, dynamic>? initialValues,
  }) : _values = {...?initialValues};

  final Map<String, dynamic> _values;

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (_values.containsKey(key)) {
      return _values[key];
    }

    throw StateError(
      'Unexpected persistent memory read for key "$key" with type $type',
    );
  }

  @override
  Future<void> reset() async {}

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    _values[key] = value;
  }
}

class _FakeFileService implements FileService {
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
  Future<String?> download(
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat,
    String textDirection,
  ) async {
    return null;
  }

  @override
  Future<void> shareTextOnly(String message) async {}
}

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  String? lastLaunchedUrl;
  LaunchOptions? lastLaunchOptions;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

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
    lastLaunchedUrl = url;
    return true;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    lastLaunchOptions = options;
    return true;
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hebrewHome = String.fromCharCodes([0x05D1, 0x05D9, 0x05EA]);

  test('fake persistent memory requires explicit values for reads', () async {
    final service = _FakePersistentMemoryService();

    expect(
      service.getItem('unexpectedKey', PersistentMemoryType.Bool),
      throwsA(isA<StateError>()),
    );
  });

  late UserInformation mockUserInformation;
  late AppInformation mockAppInformation;

  setUp(() async {
    await GetIt.instance.reset();
    getIt
        .registerLazySingleton<AnalyticsService>(() => _FakeAnalyticsService());
    getIt.registerLazySingleton<FileService>(() => _FakeFileService());
    getIt.registerLazySingleton<PersistentMemoryService>(
      () => _FakePersistentMemoryService(
        initialValues: {
          'hasFilled': false,
          'location': '',
          'phonePageDataSavedPhoneNames': <String>[],
          'phonePageDataSavedPhoneNumbers': <String>[],
        },
      ),
    );
    PackageInfo.setMockInitialValues(
      appName: 'Mazilon',
      packageName: 'mazilon',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    mockUserInformation = UserInformation()
      ..gender = 'male'
      ..localeName = 'he';
    mockAppInformation = AppInformation();
    getData(mockAppInformation);
  });

  Future<void> openMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      getMenuForTests(mockUserInformation, mockAppInformation),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
  }

  Future<_FakeUrlLauncherPlatform> openMenuWithFakeUrlLauncher(
    WidgetTester tester, {
    Locale locale = const Locale('he'),
  }) async {
    final originalPlatform = UrlLauncherPlatform.instance;
    final fakePlatform = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
    addTearDown(() {
      UrlLauncherPlatform.instance = originalPlatform;
    });

    await tester.pumpWidget(
      getMenuForTests(
        mockUserInformation,
        mockAppInformation,
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    return fakePlatform;
  }

  Future<void> pumpMenu(
    WidgetTester tester, {
    Locale locale = const Locale('he'),
    Size? physicalSize,
  }) async {
    if (physicalSize != null) {
      tester.view.physicalSize = physicalSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    await tester.pumpWidget(
      getMenuForTests(
        mockUserInformation,
        mockAppInformation,
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  List<Finder> bottomNavButtons() {
    return [
      find.byKey(const Key('bottomNavHome')),
      find.byKey(const Key('bottomNavMyPlan')),
      find.byKey(const Key('bottomNavFeelGood')),
      find.byKey(const Key('bottomNavSupportTools')),
    ];
  }

  void expectSymmetricBottomNav(WidgetTester tester) {
    final buttons = bottomNavButtons();
    for (final button in buttons) {
      expect(button, findsOneWidget);
    }

    final widths = buttons.map((button) => tester.getSize(button).width);
    for (final width in widths.skip(1)) {
      expect(width, closeTo(widths.first, 0.1));
    }

    final homeCenter = tester.getCenter(buttons[0]).dx;
    final planCenter = tester.getCenter(buttons[1]).dx;
    final feelGoodCenter = tester.getCenter(buttons[2]).dx;
    final supportToolsCenter = tester.getCenter(buttons[3]).dx;

    final outerLeftGap = (homeCenter - planCenter).abs();
    final outerRightGap = (supportToolsCenter - feelGoodCenter).abs();
    final centerGap = (planCenter - feelGoodCenter).abs();

    expect(outerRightGap, closeTo(outerLeftGap, 0.1));
    expect(centerGap - outerLeftGap, closeTo(72, 0.1));
  }

  testWidgets('hides the reminders menu entry on iOS', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await openMenu(tester);

      expect(find.byIcon(Icons.notification_add), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('shows the reminders menu entry on Android', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await openMenu(tester);

      expect(find.byIcon(Icons.notification_add), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('pins Hebrew contact us entry to the bottom of the menu', (
    WidgetTester tester,
  ) async {
    await openMenuWithFakeUrlLauncher(tester);

    final menuDialog = find.byKey(const Key('mainMenuDialog'));
    final contactButton = find.byKey(const Key('mainMenuContactUsButton'));
    final shareIcon = find.byIcon(Icons.share);

    expect(find.text('יצירת קשר'), findsOneWidget);
    expect(contactButton, findsOneWidget);
    expect(shareIcon, findsOneWidget);

    final contactTop = tester.getTopLeft(contactButton).dy;
    final shareCenter = tester.getCenter(shareIcon).dy;
    final contactBottom = tester.getBottomLeft(contactButton).dy;
    final menuBottom = tester.getBottomLeft(menuDialog).dy;

    expect(contactTop, greaterThan(shareCenter));
    expect(contactBottom, closeTo(menuBottom, 1));
  });

  testWidgets('launches Hebrew contact us URL externally', (
    WidgetTester tester,
  ) async {
    final fakePlatform = await openMenuWithFakeUrlLauncher(tester);

    await tester.tap(find.byKey(const Key('mainMenuContactUsButton')));
    await tester.pumpAndSettle();

    expect(
      fakePlatform.lastLaunchedUrl,
      'https://sites.google.com/mishol.org/matzilon/%D7%AA%D7%9E%D7%99%D7%9B%D7%94',
    );
    expect(
      fakePlatform.lastLaunchOptions?.mode,
      PreferredLaunchMode.externalApplication,
    );
    expect(fakePlatform.lastLaunchOptions?.webOnlyWindowName, '_blank');
  });

  testWidgets('launches English contact us URL externally', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakePlatform = await openMenuWithFakeUrlLauncher(
      tester,
      locale: const Locale('en'),
    );

    expect(find.text('Contact Us'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mainMenuContactUsButton')));
    await tester.pumpAndSettle();

    expect(
      fakePlatform.lastLaunchedUrl,
      'https://sites.google.com/mishol.org/living-positively/support',
    );
    expect(
      fakePlatform.lastLaunchOptions?.mode,
      PreferredLaunchMode.externalApplication,
    );
    expect(fakePlatform.lastLaunchOptions?.webOnlyWindowName, '_blank');
  });

  testWidgets('keeps Hebrew bottom navigation labels visible and symmetric', (
    WidgetTester tester,
  ) async {
    await pumpMenu(tester);

    expect(find.text(hebrewHome), findsOneWidget);
    expectSymmetricBottomNav(tester);
  });

  testWidgets('keeps Hebrew bottom navigation labels in one sizing group', (
    WidgetTester tester,
  ) async {
    await pumpMenu(tester);

    final groups = <AutoSizeGroup?>[];
    for (final button in bottomNavButtons()) {
      final label = find.descendant(
        of: button,
        matching: find.byType(AutoSizeText),
      );
      expect(label, findsOneWidget);
      groups.add(tester.widget<AutoSizeText>(label).group);
    }

    expect(groups.first, isNotNull);
    for (final group in groups.skip(1)) {
      expect(group, same(groups.first));
    }
  });

  testWidgets('keeps English bottom navigation slots symmetric', (
    WidgetTester tester,
  ) async {
    await pumpMenu(
      tester,
      locale: const Locale('en'),
      physicalSize: const Size(1200, 1000),
    );

    expect(find.text('Home'), findsOneWidget);
    expectSymmetricBottomNav(tester);
  });
}
