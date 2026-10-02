import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/main.dart' show MyApp;
import 'package:mazilon/features/personal_plan/data/phone_models.dart';
import 'package:mazilon/util/async/analytics_service.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mixpanel_flutter/codec/mixpanel_message_codec.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart';

const _kToken = 'test-token';

void main() {
  const channel = MethodChannel(
    'mixpanel_flutter',
    StandardMethodCodec(MixpanelMessageCodec()),
  );
  final List<MethodCall> calls = <MethodCall>[];

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    calls.clear();
    MixPanelService.debugProjectTokenOverride = _kToken;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall m) async {
          calls.add(m);
          // Mixpanel's track / initialize calls all return void on the platform
          // side; null is the right shape for invokeMethod<void>.
          return null;
        });
  });

  tearDown(() async {
    await GetIt.instance.reset();
    MixPanelService.debugClock = DateTime.now;
    MixPanelService.debugProjectTokenOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('MixPanelService — token present', () {
    testWidgets('should deliver MyApp cold-start Session started', (
      tester,
    ) async {
      await GetIt.instance.reset();
      registerTestServices();
      final sdkReady = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') await sdkReady.future;
            return null;
          });
      await GetIt.instance.unregister<AnalyticsService>();
      GetIt.instance.registerSingleton<AnalyticsService>(MixPanelService());
      await GetIt.instance.unregister<PersistentMemoryService>();
      final memory = GatedLocalePersistentMemoryService();
      GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
      final phones = PhonePageData(
        key: 'PhonePage',
        phoneNames: [],
        phoneNumbers: [],
        header: '',
        subTitle: '',
        midTitle: '',
        phoneNameTitle: '',
        phoneNumberTitle: '',
        savedPhoneNames: [],
        savedPhoneNumbers: [],
        phoneDescription: [],
      );
      await pumpWithProviders(
        tester,
        ChangeNotifierProvider<PhonePageData>.value(
          value: phones,
          child: MyApp(),
        ),
      );
      expect(calls.where((call) => call.method == 'track'), isEmpty);
      sdkReady.complete();
      await tester.pump();
      expect(
        calls
            .where((call) => call.method == 'track')
            .map(
              (call) => (call.arguments as Map)['eventName'],
            ),
        contains('Session started'),
      );
      memory.localeGate.complete();
      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      phones.dispose();
      await GetIt.instance.reset();
    });

    test(
      'should preserve cold-start events until initialization completes',
      () async {
        final ready = Completer<void>();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              if (call.method == 'initialize') await ready.future;
              return null;
            });
        final svc = MixPanelService();
        final init = svc.init();
        final started = svc.trackEvent('Session started');
        final home = svc.trackEvent('Home opened');
        await Future<void>.delayed(Duration.zero);
        expect(calls.where((call) => call.method == 'track'), isEmpty);
        ready.complete();
        await Future.wait([init, started, home]);
        final events = calls
            .where((call) => call.method == 'track')
            .map(
              (call) => (call.arguments as Map)['eventName'],
            );
        expect(events, ['Session started', 'Home opened']);
      },
    );

    test(
      'should report failed initialization and drop events during backoff',
      () async {
        final logger = _RecordingIncidentLogger();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              throw PlatformException(code: 'initialization-failed');
            });
        final svc = MixPanelService();
        final init = svc.init();
        final started = svc.trackEvent('Session started');
        await Future.wait([init, started]);
        await svc.trackEvent('after-failure');
        expect(calls.map((call) => call.method), ['initialize']);
        expect(logger.messages.single, contains('Mixpanel initialization'));
        var now = DateTime.now();
        MixPanelService.debugClock = () => now;
        for (var attempt = 0; attempt < 4; attempt++) {
          now = now.add(const Duration(days: 1));
          await svc.trackEvent('retry-$attempt');
        }
        expect(logger.messages, hasLength(1));
        expect(
          calls.where((call) => call.method == 'initialize'),
          hasLength(5),
        );
      },
    );

    test('should bound waiting and deliver startup events after late initialization', () async {
      final logger = _RecordingIncidentLogger();
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
      final ready = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') await ready.future;
            return null;
          });
      final svc = MixPanelService();
      final init = svc.init();
      await svc
          .trackEvent('Session started')
          .timeout(const Duration(seconds: 7));
      await init;
      expect(logger.messages.single, contains('startup timed out'));
      ready.complete();
      await Future<void>.delayed(Duration.zero);
      await svc.trackEvent('late-event');
      expect(calls.map((call) => call.method), [
        'initialize',
        'track',
        'track',
      ]);
      expect(
        calls
            .where((call) => call.method == 'track')
            .map((call) => (call.arguments as Map)['eventName']),
        ['Session started', 'late-event'],
      );
    });

    test('should report overflow separately after a startup timeout', () async {
      final logger = _RecordingIncidentLogger();
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
      final ready = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') await ready.future;
            return null;
          });
      final svc = MixPanelService();
      await svc
          .trackEvent('Session started')
          .timeout(const Duration(seconds: 7));
      for (var i = 0; i < 80; i++) {
        await svc.trackEvent('event-$i');
      }
      await svc.init();
      expect(calls.map((call) => call.method), ['initialize']);
      expect(logger.messages, [
        contains('startup timed out'),
        contains('buffer exceeded'),
      ]);
      ready.complete();
      await Future<void>.delayed(Duration.zero);
      final events = calls.where((call) => call.method == 'track').toList();
      expect(events, hasLength(64));
      expect((events.first.arguments as Map)['eventName'], 'event-16');
      expect(logger.messages, hasLength(2));
    });

    test(
      'should retry initialization on an event after failure backoff',
      () async {
        var now = DateTime(2026);
        MixPanelService.debugClock = () => now;
        var fail = true;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              if (fail) throw PlatformException(code: 'init-failed');
              return null;
            });
        final svc = MixPanelService();
        await svc.init();
        await svc.init(); // A backoff call must not cache a completed no-op.
        fail = false;
        now = now.add(const Duration(minutes: 1));
        await svc.trackEvent('recovered');
        expect(calls.map((call) => call.method), [
          'initialize',
          'initialize',
          'track',
        ]);
      },
    );

    test('should bound retained startup events and report overflow', () async {
      final logger = _RecordingIncidentLogger();
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
      final ready = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') await ready.future;
            return null;
          });
      final svc = MixPanelService();
      final pending = [for (var i = 0; i < 65; i++) svc.trackEvent('event-$i')];
      ready.complete();
      await Future.wait(pending);
      final events = calls.where((call) => call.method == 'track').toList();
      expect(events, hasLength(64));
      expect((events.first.arguments as Map)['eventName'], 'event-1');
      expect(logger.messages.single, contains('buffer exceeded'));
    });

    test(
      'should preserve occurrence timestamps through delayed startup',
      () async {
        final ready = Completer<void>();
        var now = DateTime.utc(2026, 10, 2);
        MixPanelService.debugClock = () => now;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              if (call.method == 'initialize') await ready.future;
              return null;
            });
        final svc = MixPanelService();
        final firstTime = now.millisecondsSinceEpoch;
        final original = <String, dynamic>{'page': 'Home'};
        final first = svc.trackEvent('Session started', original);
        original['page'] = 'changed';
        now = now.add(const Duration(seconds: 2));
        final secondTime = now.millisecondsSinceEpoch;
        final second = svc.trackEvent('Home opened');
        final explicit = svc.trackEvent('explicit', {'time': 1234567890});
        now = now.add(const Duration(minutes: 1));
        ready.complete();
        await Future.wait([first, second, explicit]);
        final properties = calls
            .where((call) => call.method == 'track')
            .map((call) => (call.arguments as Map)['properties'] as Map)
            .toList();
        expect(properties[0]['time'], firstTime);
        expect(properties[0]['page'], 'Home');
        expect(properties[1]['time'], secondTime);
        expect(properties[2]['time'], 1234567890);
      },
    );

    test(
      'should keep new events behind buffered events during flushing',
      () async {
        final ready = Completer<void>();
        final tracked = Completer<void>();
        final releaseFirst = Completer<void>();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              if (call.method == 'initialize') await ready.future;
              if (call.method == 'track' &&
                  (call.arguments as Map)['eventName'] == 'first') {
                tracked.complete();
                await releaseFirst.future;
              }
              return null;
            });
        final svc = MixPanelService();
        final first = svc.trackEvent('first');
        final second = svc.trackEvent('second');
        ready.complete();
        await tracked.future;
        final third = svc.trackEvent('third');
        await Future<void>.delayed(Duration.zero);
        expect(calls.where((call) => call.method == 'track'), hasLength(1));
        releaseFirst.complete();
        await Future.wait([first, second, third]);
        expect(
          calls
              .where((call) => call.method == 'track')
              .map((call) => (call.arguments as Map)['eventName']),
          ['first', 'second', 'third'],
        );
      },
    );

    test(
      'should isolate a flush error and retain the initialized SDK',
      () async {
        final ready = Completer<void>();
        final logger = _RecordingIncidentLogger();
        GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              calls.add(call);
              if (call.method == 'initialize') await ready.future;
              if (call.method == 'track' &&
                  (call.arguments as Map)['eventName'] == 'bad') {
                throw PlatformException(code: 'track-failed');
              }
              return null;
            });
        final svc = MixPanelService();
        final bad = svc.trackEvent('bad');
        final good = svc.trackEvent('good');
        ready.complete();
        await Future.wait([bad, good]);
        await svc.init();
        await svc.trackEvent('after');
        expect(
          calls.where((call) => call.method == 'initialize'),
          hasLength(1),
        );
        expect(
          calls
              .where((call) => call.method == 'track')
              .map((call) => (call.arguments as Map)['eventName']),
          ['bad', 'good', 'after'],
        );
        expect(
          logger.messages.single,
          contains('startup event delivery failed'),
        );
      },
    );

    test('init() runs the full body when token is non-empty', () async {
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
      MixPanelService.debugProjectTokenOverride = '';
      final svc = MixPanelService();
      await svc.init();
      expect(svc.key, '');
    });

    test('trackEvent() short-circuits when token empty', () async {
      MixPanelService.debugProjectTokenOverride = '';
      final svc = MixPanelService();
      await svc.init();
      await svc.trackEvent('noop');
    });
  });
}

class _RecordingIncidentLogger extends NoopIncidentLoggerService {
  final messages = <String>[];
  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    messages.add(exception.toString());
  }
}
