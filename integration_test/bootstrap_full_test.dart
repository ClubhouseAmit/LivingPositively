// Phase 10B (ADR-005 § B): integration test that exercises the full
// foreground bootstrap of `lib/main.dart` by calling the extracted
// `bootstrapApp(...)` directly.
//
// The Phase-7 sibling (`bootstrap_smoke_test.dart`) hand-built the same
// MultiProvider tree that `main()` builds and pumped MyApp from it — this
// covered the bulk of MyApp's lifecycle (initState / build / changeLocale /
// didChangeAppLifecycleState) but left lines 104-156 of main.dart
// (`initializeApp` body + `main` body + the MultiProvider construction)
// outside the test's reach. ADR-005 § B sanctioned the
// `bootstrapApp(...)` extraction specifically to make those lines
// testable; this file exercises them.
//
// Injection seams used (none of these change production behavior because
// they all default to the previous in-`main()` calls):
//   * `firebaseInitializer: () async {}` — skips the real
//     `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
//     call which would require either the secret-injected
//     `firebase_options.dart` to be valid for this test or a network round-
//     trip the integration_test binding does not provide. The downstream
//     `loadAppInformation` / `loadUserInformation` calls in MyApp.build
//     still hit `FirebaseFirestore.instance` and fail, which routes through
//     MyApp's `.catchError` into the Introduction fallback — identical
//     behavior to `bootstrap_smoke_test.dart`.
//   * `locatorSetup` — pass `registerTestServices` directly so the same
//     in-memory fakes the rest of the unit/integration suites use are
//     registered, and the production `setupLocator` (which would
//     `registerLazySingleton` concrete impls and throw on duplicate
//     registration after our fakes are in place) is bypassed.
//   * `workmanagerInitializer: () {}` — no-op; the underlying
//     `WorkmanagerPlatform.instance` is replaced with the
//     `_SilentWorkmanager` recorder so any downstream `Workmanager()` calls
//     in MyApp's lifecycle complete cleanly.
//
// Production `main()` calls `bootstrapApp()` with no args. Its defaults
// match the previous in-`main()` body line-for-line. The CI `build-android`
// + `build-web` jobs build the app starting from `main()` and surface any
// regression.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/main.dart' show MyApp, bootstrapApp, initializeApp;
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/pages/SignIn_Pages/introduction.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import '../test/helpers/widget_test_scaffold.dart';

class _SilentWorkmanager extends WorkmanagerPlatform {
  _SilentWorkmanager._() : super();
  static final _SilentWorkmanager _shared = _SilentWorkmanager._();
  final List<String> calls = [];

  static _SilentWorkmanager register() {
    // Workmanager() lazily constructs a singleton whose constructor installs
    // the real Android/iOS platform if the current platform is only a test
    // fake. Prime that singleton first, then replace the platform with this
    // recorder so the default fallback remains observable.
    Workmanager();
    WorkmanagerPlatform.instance = _shared;
    _shared.calls.clear();
    return _shared;
  }

  @override
  Future<void> initialize(Function callbackDispatcher,
      {bool isInDebugMode = false}) async {
    calls.add('initialize');
  }

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
  }

  @override
  Future<void> registerOneOffTask(String uniqueName, String taskName,
      {Map<String, dynamic>? inputData,
      Duration? initialDelay,
      Constraints? constraints,
      ExistingWorkPolicy? existingWorkPolicy,
      BackoffPolicy? backoffPolicy,
      Duration? backoffPolicyDelay,
      String? tag,
      OutOfQuotaPolicy? outOfQuotaPolicy}) async {}

  @override
  Future<void> registerPeriodicTask(String uniqueName, String taskName,
      {Duration? frequency,
      Duration? flexInterval,
      Map<String, dynamic>? inputData,
      Duration? initialDelay,
      Constraints? constraints,
      ExistingPeriodicWorkPolicy? existingWorkPolicy,
      BackoffPolicy? backoffPolicy,
      Duration? backoffPolicyDelay,
      String? tag}) async {}

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {}

  @override
  Future<void> cancelByTag(String tag) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const sharedPrefsChannel =
      MethodChannel('plugins.flutter.io/shared_preferences');

  late _SilentWorkmanager fakeWm;

  setUp(() async {
    await GetIt.instance.reset();
    fakeWm = _SilentWorkmanager.register();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(pathProviderChannel, (call) async {
        switch (call.method) {
          case 'getApplicationDocumentsDirectory':
          case 'getApplicationSupportDirectory':
          case 'getTemporaryDirectory':
            return '/tmp/aqe-bootstrap-full';
          default:
            return null;
        }
      })
      // PhonePageData.loadItemsFromPrefs reads via shared_preferences; return
      // an empty store so the cascade completes without touching real prefs.
      ..setMockMethodCallHandler(sharedPrefsChannel, (call) async {
        if (call.method == 'getAll') return <String, Object>{};
        return null;
      });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(pathProviderChannel, null)
      ..setMockMethodCallHandler(sharedPrefsChannel, null);
    await GetIt.instance.reset();
  });

  group('bootstrapApp() return shape', () {
    testWidgets(
        'returns the same MultiProvider tree shape that pre-extraction main() built',
        (tester) async {
      var firebaseCalled = false;
      var locatorCalled = false;
      var workmanagerCalled = false;

      final widget = await bootstrapApp(
        firebaseInitializer: () async {
          firebaseCalled = true;
        },
        locatorSetup: () {
          locatorCalled = true;
          registerTestServices(locale: 'en');
        },
        workmanagerInitializer: () {
          workmanagerCalled = true;
        },
      );

      expect(firebaseCalled, isTrue,
          reason: 'bootstrapApp must call firebaseInitializer');
      expect(locatorCalled, isTrue,
          reason: 'bootstrapApp must call locatorSetup');
      // workmanagerInitializer only runs on non-web; integration_test binding
      // on Android emulator => kIsWeb is false, so it must have run.
      expect(workmanagerCalled, isTrue,
          reason:
              'bootstrapApp must call workmanagerInitializer on non-web platforms');

      // Top-level shape: MultiProvider wrapping MyApp. The provider package
      // does not expose providers/child as public getters, so we verify the
      // shape by pumping the widget and asserting the resulting tree
      // contains the MultiProvider + MyApp pair the pre-extraction main()
      // produced.
      expect(widget, isA<MultiProvider>(),
          reason:
              'bootstrapApp must return a MultiProvider as its root widget');

      await tester.pumpWidget(widget);
      await tester.pump();

      expect(find.byType(MultiProvider), findsOneWidget,
          reason: 'pumped tree must contain the bootstrap MultiProvider');
      expect(find.byType(MyApp), findsOneWidget,
          reason: 'pumped tree must contain MyApp under the MultiProvider');
    });
  });

  group('bootstrapApp() pumps a working MyApp tree', () {
    testWidgets(
        'first frame after bootstrapApp shows the CircularProgressIndicator placeholder',
        (tester) async {
      final widget = await bootstrapApp(
        firebaseInitializer: () async {},
        locatorSetup: () => registerTestServices(locale: 'en'),
        workmanagerInitializer: () {},
      );

      await tester.pumpWidget(widget);
      // First frame: localeName is still '' so MyApp renders the bootstrap
      // MaterialApp + CircularProgressIndicator placeholder (lines 399-406
      // of main.dart, the pre-`ScreenUtilInit` branch).
      await tester.pump();

      expect(find.byType(MaterialApp), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets(
        'MyApp settles to FirstPage or Introduction after async bootstrap (spinner is gone)',
        (tester) async {
      final widget = await bootstrapApp(
        firebaseInitializer: () async {},
        locatorSetup: () => registerTestServices(locale: 'en'),
        workmanagerInitializer: () {},
      );

      await tester.pumpWidget(widget);

      // Drive the async build cycle. MyApp.build kicks off a Future.wait of
      // loadAppInformation / loadUserInformation / setLocale. The first two
      // hit FirebaseFirestore.instance (no Firebase initialised) and fail,
      // routing through MyApp's .catchError → Introduction. setLocale
      // completes via the in-memory PersistentMemoryService fake.
      //
      // Pump generously (2s total) so a slow CI agent still settles; we then
      // assert the STRONGER condition that the spinner is gone and the
      // bootstrap reached a terminal widget. A bootstrap that hangs on the
      // CircularProgressIndicator placeholder forever (e.g. setLocale future
      // never completes, or the localeName='' branch never flips) is a real
      // regression — it should fail this test, not slip through.
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final hasFirstPage = find.byType(FirstPage).evaluate().isNotEmpty;
      final hasIntroduction = find.byType(Introduction).evaluate().isNotEmpty;
      // STRONGER than the Phase-7 smoke test: we no longer accept a
      // CircularProgressIndicator as a "settled" state. A bootstrap that
      // never leaves the placeholder (e.g. setLocale future never
      // completes, or the localeName='' → ScreenUtilInit transition is
      // broken) is the exact regression Phase 10B is meant to catch — the
      // raised main.dart per-file floor (50% → 65%) is meaningless if the
      // test passes on a bootstrap that hung.
      expect(
        hasFirstPage || hasIntroduction,
        isTrue,
        reason: 'After 2s of async pumps MyApp must have left the loading '
            'placeholder and rendered FirstPage (success path) or '
            'Introduction (catchError fallback path). If neither is found, '
            'the bootstrap is stuck on the CircularProgressIndicator '
            'placeholder from main.dart lines 399-406 — that is a real '
            'regression in the localeName=""→ScreenUtilInit transition, '
            'not a flake.',
      );
    });
  });

  group('bootstrapApp() default branches (workmanagerInitializer absent)', () {
    testWidgets(
        'when workmanagerInitializer is omitted, falls back to Workmanager().initialize',
        (tester) async {
      fakeWm.calls.clear();

      final widget = await bootstrapApp(
        firebaseInitializer: () async {},
        locatorSetup: () => registerTestServices(locale: 'en'),
        // workmanagerInitializer omitted → exercises the default-fallback
        // closure that calls `Workmanager().initialize(callbackDispatcher,
        // isInDebugMode: false)`. _SilentWorkmanager records the call.
      );

      // The default fallback fires Workmanager().initialize, which routes
      // through WorkmanagerPlatform.instance (our _SilentWorkmanager).
      expect(
        fakeWm.calls,
        contains('initialize'),
        reason:
            'default workmanagerInitializer must call Workmanager().initialize',
      );

      // Returned widget is still the expected MultiProvider shape — proves
      // the workmanager branch did not derail the bootstrap.
      expect(widget, isA<MultiProvider>());
    });
  });

  group('initializeApp() default branches', () {
    testWidgets(
        'initializeApp() with firebaseInitializer override + locatorSetup override completes',
        (tester) async {
      var firebaseCalled = false;
      var locatorCalled = false;

      await initializeApp(
        firebaseInitializer: () async {
          firebaseCalled = true;
        },
        locatorSetup: () {
          locatorCalled = true;
          registerTestServices(locale: 'en');
        },
      );

      expect(firebaseCalled, isTrue);
      expect(locatorCalled, isTrue);
      // After locator setup our fake should be registered.
      expect(GetIt.instance.isRegistered<AnalyticsService>(), isTrue);
      expect(GetIt.instance.isRegistered<LocaleService>(), isTrue);
    });
  });
}
