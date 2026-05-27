// Phase B (ADR-005) — accessibility regression tests.
//
// These cover the icon-only / tab-state semantics gaps catalogued in
// `docs/UX_GAPS.md` §1.3, §1.6, and §3.11. They are intentionally small,
// real-widget tests in the project's house style — no mocks, no goldens.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PipelineOwner;
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:mazilon/util/HomePage/inspirationalQuote.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:mazilon/AnalyticsService.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../MenuTest/TestMenu.dart';
import '../MenuTest/test_data.dart';

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
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
  }) async => true;
}

class _NoopAnalytics implements AnalyticsService {
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(String name, [Map<String, dynamic>? props]) async {}
}

class _StubPersistentMemoryService implements PersistentMemoryService {
  final Map<String, dynamic> _values = {'hasFilled': false, 'location': ''};

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (_values.containsKey(key)) return _values[key];
    switch (type) {
      case PersistentMemoryType.String:
        return '';
      case PersistentMemoryType.Bool:
        return false;
      case PersistentMemoryType.Int:
        return 0;
      case PersistentMemoryType.Double:
        return 0.0;
      case PersistentMemoryType.StringList:
        return <String>[];
    }
  }

  @override
  Future<void> reset() async => _values.clear();

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    _values[key] = value;
  }
}

class _StubFileService implements FileService {
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
  ) async => null;
  @override
  Future<void> shareTextOnly(String message) async {}
}

Widget _wrap(
  Widget Function(BuildContext) builder, {
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, _) => Scaffold(body: Builder(builder: builder)),
    ),
  );
}

/// Walks the rendered semantics tree from [tester]'s root and collects every
/// SemanticsNode tooltip, label, and merged-descendant tooltip/label. Used to
/// assert that a Tooltip/Semantics annotation actually reaches the platform
/// accessibility tree — not just that the widget constructor received the
/// string.
Set<String> _semanticsStrings(WidgetTester tester) {
  final result = <String>{};
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.tooltip.isNotEmpty) result.add(data.tooltip);
    if (data.label.isNotEmpty) result.add(data.label);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  // rootPipelineOwner is the non-deprecated entry point as of Flutter 3.10+.
  // The semantics tree may live on a child pipeline owner (one per View), so
  // walk every pipeline owner and any node it carries.
  void visitOwner(PipelineOwner owner) {
    final root = owner.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
    owner.visitChildren(visitOwner);
  }

  visitOwner(tester.binding.rootPipelineOwner);
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('phoneContact has accessible tooltip (UX_GAPS §1.3, §1.6)', () {
    testWidgets('Semantics tree exposes the localized "Call <contact>" tooltip', (
      tester,
    ) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = _FakeUrlLauncherPlatform();
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_wrap((_) => phoneContact('555-1234', 'Mom')));
        await tester.pumpAndSettle();

        // Reading the rendered semantics tree (not just Tooltip.message)
        // proves the string actually reaches TalkBack/VoiceOver. Tooltip
        // surfaces its message via SemanticsProperties.tooltip — so we
        // search the live SemanticsNode tooltips.
        expect(
          _semanticsStrings(tester),
          contains('Call Mom'),
          reason:
              'phoneContact must expose "Call <contact>" in the semantics tree.',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('dialer tap target meets the 48dp minimum (UX_GAPS §1.6)', (
      tester,
    ) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = _FakeUrlLauncherPlatform();
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await tester.pumpWidget(_wrap((_) => phoneContact('555-1234', 'Mom')));
      await tester.pumpAndSettle();

      final inkWell = find.byType(InkWell);
      expect(inkWell, findsOneWidget);

      final size = tester.getSize(inkWell);
      expect(
        size.width,
        greaterThanOrEqualTo(48.0),
        reason: 'Phone tap target must be at least 48dp wide.',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(48.0),
        reason: 'Phone tap target must be at least 48dp tall.',
      );
    });

    testWidgets('Hebrew locale exposes the localized tooltip to semantics', (
      tester,
    ) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = _FakeUrlLauncherPlatform();
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            (_) => phoneContact('555-1234', 'אמא'),
            locale: const Locale('he'),
          ),
        );
        await tester.pumpAndSettle();

        // Substring match — assert the contact name reaches the semantics
        // tree under a Hebrew locale, without pinning the exact bidi
        // formatting of the surrounding ARB string.
        expect(
          _semanticsStrings(tester).any((s) => s.contains('אמא')),
          isTrue,
          reason: 'Hebrew dialer must expose the contact name in semantics.',
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('inspirationalQuote close+refresh are labelled (UX_GAPS §1.3)', () {
    setUp(() async {
      // Inspirational quote uses GetIt to read AnalyticsService inside its
      // refresh handler. Register a no-op so the widget initialises cleanly.
      await GetIt.instance.reset();
      getIt.registerLazySingleton<AnalyticsService>(() => _NoopAnalytics());
    });

    testWidgets('refresh button exposes its tooltip to the semantics tree', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            (_) => InspirationalQuote(quotes: const ['quote-1', 'quote-2']),
          ),
        );
        await tester.pumpAndSettle();

        // IconButton routes `tooltip:` into a Tooltip whose message is
        // exposed via SemanticsProperties.tooltip — assert against the
        // live semantics tree so a future regression that strips the
        // tooltip is caught.
        expect(
          _semanticsStrings(tester),
          contains('New quote'),
          reason: 'Refresh button must expose "New quote" to semantics.',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('close (X) button exposes its tooltip to the semantics tree', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap((_) => InspirationalQuote(quotes: const ['quote-1'])),
        );
        await tester.pumpAndSettle();

        expect(
          _semanticsStrings(tester),
          contains('Dismiss quote'),
          reason: 'Close button must expose "Dismiss quote" to semantics.',
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('Bottom nav exposes selected: semantics (UX_GAPS §3.11)', () {
    setUp(() async {
      await GetIt.instance.reset();
      getIt.registerLazySingleton<AnalyticsService>(() => _NoopAnalytics());
      getIt.registerLazySingleton<FileService>(() => _StubFileService());
      getIt.registerLazySingleton<PersistentMemoryService>(
        () => _StubPersistentMemoryService(),
      );
      PackageInfo.setMockInitialValues(
        appName: 'Mazilon',
        packageName: 'mazilon',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    testWidgets('Home tab is announced as selected by default', (tester) async {
      final user = UserInformation()
        ..gender = 'male'
        ..localeName = 'he';
      final app = AppInformation();
      getData(app);

      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(getMenuForTests(user, app));
        await tester.pumpAndSettle();

        final homeBtn = find.byKey(const Key('bottomNavHome'));
        expect(homeBtn, findsOneWidget);

        final semantics = tester.getSemantics(homeBtn);
        expect(
          semantics.flagsCollection.isSelected,
          Tristate.isTrue,
          reason: 'Home tab must announce `selected` when active.',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Other tabs are announced as NOT selected', (tester) async {
      final user = UserInformation()
        ..gender = 'male'
        ..localeName = 'he';
      final app = AppInformation();
      getData(app);

      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(getMenuForTests(user, app));
        await tester.pumpAndSettle();

        final planBtn = find.byKey(const Key('bottomNavMyPlan'));
        expect(planBtn, findsOneWidget);

        final semantics = tester.getSemantics(planBtn);
        expect(
          semantics.flagsCollection.isSelected,
          isNot(Tristate.isTrue),
          reason: 'Inactive tabs must NOT announce `selected`.',
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
