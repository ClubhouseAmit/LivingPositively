// MixPanelService coverage for the token-present branches.
//
// The init() body and the post-init trackEvent() branches in
// lib/AnalyticsService.dart are gated on a non-empty
// `String.fromEnvironment('MIXPANEL_PROJECT_TOKEN')`. Under a plain
// `flutter test` run that constant is the empty string so those branches
// are unreachable.
//
// This file is intended to be run with:
//   flutter test --coverage \
//     --dart-define=MIXPANEL_PROJECT_TOKEN=test-token \
//     test/AnalyticsService/MixPanelService_token_test.dart
//
// CI also runs the file as part of the standard `flutter test --coverage`
// invocation — when the env-var is empty the tests gracefully short-circuit
// (we detect the empty-token state and skip the token-present assertions),
// so the file is safe to include in the default test discovery glob.
//
// Mixpanel.init(...) reaches out to the platform via MethodChannel
// `mixpanel_flutter` with a custom MixpanelMessageCodec; we stub the channel
// with `setMockMethodCallHandler` so the call is fully in-process and never
// hits real native code.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mixpanel_flutter/codec/mixpanel_message_codec.dart';

const _kToken = String.fromEnvironment('MIXPANEL_PROJECT_TOKEN');

void main() {
  const channel = MethodChannel(
    'mixpanel_flutter',
    StandardMethodCodec(MixpanelMessageCodec()),
  );
  final List<MethodCall> calls = <MethodCall>[];

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall m) async {
      calls.add(m);
      // Mixpanel's track / initialize calls all return void on the platform
      // side; null is the right shape for invokeMethod<void>.
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MixPanelService — token present', () {
    test('init() runs the full body when token is non-empty', () async {
      if (_kToken.isEmpty) {
        // Default `flutter test` run with no --dart-define: the post-empty
        // short-circuit is already exercised by AnalyticsService_test.dart;
        // we cannot exercise the init-body path here without the env var.
        // Returning early keeps the file safe to include in the default
        // discovery glob.
        return;
      }

      final svc = MixPanelService();
      await svc.init();

      // The init body assigned `key` and invoked Mixpanel.init via the
      // mocked platform channel.
      expect(svc.key, _kToken);
      expect(calls, isNotEmpty);
      expect(calls.first.method, 'initialize');
      final args = calls.first.arguments as Map<dynamic, dynamic>;
      expect(args['token'], _kToken);
      expect(args['trackAutomaticEvents'], isFalse);
    });

    test('trackEvent() forwards to Mixpanel.track when initialized', () async {
      if (_kToken.isEmpty) return;

      final svc = MixPanelService();
      await svc.init();
      calls.clear();

      await svc.trackEvent('my-event');
      await svc.trackEvent('event-with-props', {'a': 1, 'b': 'two'});

      // Two `track` invocations should now have hit the channel.
      final tracks = calls.where((c) => c.method == 'track').toList();
      expect(tracks, hasLength(2));
      final args0 = tracks[0].arguments as Map<dynamic, dynamic>;
      expect(args0['eventName'], 'my-event');
      final args1 = tracks[1].arguments as Map<dynamic, dynamic>;
      expect(args1['eventName'], 'event-with-props');
      // The properties map is forwarded through Mixpanel's serialization
      // helper; assert both keys round-trip.
      final props1 = args1['properties'] as Map<dynamic, dynamic>;
      expect(props1['a'], 1);
      expect(props1['b'], 'two');
    });

    test('mixpanel getter exposes the underlying instance', () async {
      if (_kToken.isEmpty) return;

      final svc = MixPanelService();
      await svc.init();

      // The getter just exposes the late field assigned in init(). It must
      // not throw post-init.
      expect(() => svc.mixpanel, returnsNormally);
    });

    test('AnalyticsService is implemented by MixPanelService', () {
      // This holds regardless of the token state and gives the file a
      // sanity assertion when the dart-define is missing.
      expect(MixPanelService(), isA<AnalyticsService>());
    });
  });

  group('MixPanelService — empty-token short circuit', () {
    // These short-circuit branches are covered by the existing
    // AnalyticsService_test.dart suite, but we re-assert them here so the
    // file stays useful when run on its own (no --dart-define) and so any
    // regression to the gating logic is caught by both suites.
    test('init() short-circuits when token empty', () async {
      if (_kToken.isNotEmpty) return;
      final svc = MixPanelService();
      await svc.init();
      expect(svc.key, '');
    });

    test('trackEvent() short-circuits when token empty', () async {
      if (_kToken.isNotEmpty) return;
      final svc = MixPanelService();
      await svc.init();
      await svc.trackEvent('noop');
    });
  });
}
