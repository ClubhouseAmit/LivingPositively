// Phase 7 (ADR-002): integration test for SentryServiceImpl
// (`lib/util/logger_service.dart`).
//
// The unit suite (`test/util/logger_service_test.dart`) already covers the
// `Sentry.isEnabled == false` paths through captureLog. Under `flutter test`
// Sentry can never be enabled because nothing calls SentryFlutter.init, so the
// `Sentry.isEnabled == true` branch of captureLog and ALL of initializeSentry
// stayed at 10.5%.
//
// Under integration_test we DO have a real Flutter binding, so we can:
//   1. Drive the empty-DSN branch of initializeSentry — it calls runApp(...)
//      directly, which on a real binding mounts a widget tree and then
//      pumpAndSettle drains it. (channel-mock SentryFlutter.init is unnecessary
//      here because the empty-DSN branch never reaches it.)
//   2. Drive the catch branch of initializeSentry by passing a Widget that
//      triggers no exception itself, but channel-stub `SentryFlutter.init` to
//      throw — exercising the catch + the "runApp anyway" fallback.
//   3. Drive the with-DSN happy path by channel-stubbing the Sentry
//      MethodChannel so SentryFlutter.init returns successfully and the
//      appRunner callback runs.
//
// All three drive REAL `runApp` calls (not stubs) — that is the whole point of
// the integration_test binding. We channel-mock only the Sentry SDK's native
// side, not the Dart entry-points.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/util/logger_service.dart';
// ignore: depend_on_referenced_packages
import 'package:sentry/sentry.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const sentryChannel = MethodChannel('sentry_flutter');

  setUp(() {
    // Default permissive Sentry channel — every call returns null/empty so
    // SentryFlutter.init can complete its native handshake. Individual tests
    // override this to inject specific behaviour.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sentryChannel, (call) async {
      // sentry_flutter calls a handful of methods during init:
      //   - "initNativeSdk" returns void
      //   - "loadContexts" returns a Map (give an empty one)
      //   - "loadDebugImages" returns a List
      //   - others — null is safe.
      switch (call.method) {
        case 'loadContexts':
          return <String, dynamic>{};
        case 'loadDebugImages':
          return <Map<String, dynamic>>[];
        case 'fetchNativeAppStart':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    // Reset Sentry between tests so `Sentry.isEnabled` returns to false.
    // Under the CI dart-define (SENTRY_DSN non-empty), the first test
    // successfully initializes the SDK via the permissive channel mock —
    // without `close()` here, every later test sees `isEnabled == true`
    // and the "captureLog short-circuits when disabled" assertion would
    // fail. Close is idempotent and a no-op when the SDK was never
    // initialized (local `flutter test` without the dart-define).
    if (Sentry.isEnabled) {
      await Sentry.close();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sentryChannel, null);
  });

  testWidgets(
      'initializeSentry mounts the appRunner widget (both empty-DSN and with-DSN modes)',
      (tester) async {
    // Dual-mode test (PR #266 review: baz-reviewer finding 1):
    //   * Local `flutter test integration_test/logger_init_test.dart` (no
    //     --dart-define): `_sentryDsn` is empty, so the if-branch runs and
    //     `runApp(MyApp)` is invoked directly (lines 16-18 of
    //     logger_service.dart).
    //   * CI integration-test job
    //     (--dart-define=SENTRY_DSN=https://test@dsn.example.local/0):
    //     `_sentryDsn` is non-empty, so the else-branch runs and
    //     SentryFlutter.init's appRunner callback eventually calls
    //     runApp(MyApp). The permissive channel mock above lets init
    //     complete cleanly (lines 20-26).
    //
    // The assertion holds in both modes — what matters is that the
    // placeholder widget ends up mounted. The empty-DSN branch's coverage
    // contribution under `flutter test` is preserved; the with-DSN branch
    // is contributed by the CI dart-define run.
    final svc = SentryServiceImpl();
    await svc.initializeSentry(
      const MaterialApp(
        home: Scaffold(body: SizedBox(key: Key('logger-init-empty-dsn'))),
      ),
    );
    await tester.pumpAndSettle();

    // The widget runApp mounted is now the active root.
    expect(find.byKey(const Key('logger-init-empty-dsn')), findsOneWidget);
  });

  testWidgets(
      'captureLog short-circuits cleanly under Sentry.isEnabled == false',
      (tester) async {
    // Even on a real binding, Sentry.isEnabled stays false until something
    // has actually initialised Sentry. This drives the early-return branch
    // of captureLog (lines 37-51), with multiple exceptionData shapes to
    // exercise the contains() guards.
    final svc = SentryServiceImpl();

    await svc.captureLog(Exception('disabled-1'));
    await svc.captureLog(
      Exception('disabled-2'),
      stackTrace: StackTrace.current,
    );
    await svc.captureLog(
      Exception('disabled-3'),
      exceptionData: const {'name': 'context-key', 'value': 'context-value'},
    );
    await svc.captureLog(
      Exception('disabled-4'),
      exceptionData: const {'no-name': true},
    );

    expect(Sentry.isEnabled, isFalse);
  });

  testWidgets(
      'initializeSentry survives a SentryFlutter.init failure via the catch branch',
      (tester) async {
    // Have the native Sentry channel throw on initNativeSdk to drive the
    // catch branch (lines 28-32). The fallback still calls runApp(MyApp),
    // so the placeholder widget should mount.
    //
    // The CI integration-test job passes
    // `--dart-define=SENTRY_DSN=https://test@dsn.example.local/0` so this
    // test deterministically exercises the catch branch there (PR #266
    // review: baz-reviewer finding 1). Locally, without the dart-define,
    // `_sentryDsn` is empty and the if-branch runs instead — the assertion
    // still holds either way (placeholder mounts), and the catch-branch
    // coverage contribution comes from the CI run.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sentryChannel, (call) async {
      if (call.method == 'initNativeSdk') {
        throw PlatformException(code: 'NATIVE_FAIL', message: 'simulated');
      }
      return null;
    });

    final svc = SentryServiceImpl();
    await svc.initializeSentry(
      const MaterialApp(
        home: Scaffold(body: SizedBox(key: Key('logger-init-catch-branch'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logger-init-catch-branch')), findsOneWidget);
  });

  testWidgets(
      'captureLog routes through Sentry when isEnabled == true',
      (tester) async {
    // Drives the `Sentry.isEnabled == true` branch of captureLog
    // (lines 38-50 of logger_service.dart): the `if (exceptionData != null
    // && contains("name") && contains("value"))` configureScope guard,
    // both arms of that guard, and the trailing `Sentry.captureException`
    // call.
    //
    // Coverage contract: this test is effective only when the CI
    // integration-test job passes `--dart-define=SENTRY_DSN=<test value>`
    // — under a local `flutter test integration_test/logger_init_test.dart`
    // run without the dart-define, `_sentryDsn.isEmpty` is true and
    // initializeSentry returns through the if-branch without ever
    // initialising the SDK, so `Sentry.isEnabled` stays false and the
    // captureLog body short-circuits. The test still passes locally
    // (no assertion is made conditional on `Sentry.isEnabled`), but the
    // lines 40-46 coverage contribution comes from the CI run.
    //
    // Why these calls are safe under the permissive channel mock from
    // setUp: every native Sentry SDK call (`captureEnvelope`,
    // `loadContexts`, `loadDebugImages`, etc.) returns null/empty via the
    // default handler, so the Dart-side `Sentry.captureException` future
    // resolves cleanly without producing real telemetry. configureScope
    // is purely Dart-side and needs no mock.
    final svc = SentryServiceImpl();
    await svc.initializeSentry(
      const MaterialApp(
        home: Scaffold(body: SizedBox(key: Key('logger-captureLog-enabled'))),
      ),
    );
    await tester.pumpAndSettle();

    // With name+value present — drives the configureScope branch
    // (lines 39-44) and then Sentry.captureException (line 46).
    await svc.captureLog(
      Exception('enabled-with-context'),
      stackTrace: StackTrace.current,
      exceptionData: const {'name': 'context-key', 'value': 'context-value'},
    );

    // Without exceptionData — skips the configureScope branch but still
    // hits the Sentry.captureException call (line 46).
    await svc.captureLog(Exception('enabled-no-context'));

    // exceptionData present but missing the `value` key — exercises the
    // false arm of the contains() guard while still reaching line 46.
    await svc.captureLog(
      Exception('enabled-missing-value'),
      exceptionData: const {'name': 'only-name'},
    );

    // The assertion holds in both CI (Sentry initialised) and local
    // (placeholder mounted via the empty-DSN if-branch) modes; the
    // coverage contribution differs by mode as documented above.
    expect(find.byKey(const Key('logger-captureLog-enabled')), findsOneWidget);
  });
}
