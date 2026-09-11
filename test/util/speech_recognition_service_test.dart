import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/speech_recognition_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpeechRecognitionServiceImpl', () {
    late _FakeSpeechRecognitionEngine engine;
    late SpeechRecognitionServiceImpl service;

    setUp(() {
      engine = _FakeSpeechRecognitionEngine();
      service = SpeechRecognitionServiceImpl(engine: engine);
    });

    test(
      'should initialize the engine once for the application session',
      () async {
        expect(
          await service.initialize(),
          SpeechRecognitionAvailability.available,
        );
        expect(
          await service.initialize(),
          SpeechRecognitionAvailability.available,
        );

        expect(engine.initializeCalls, 1);
      },
    );

    test('should expose the installed locales after initialization', () async {
      engine.availableLocales = const <SpeechRecognitionLocale>[
        SpeechRecognitionLocale(localeId: 'en-US', name: 'English (US)'),
        SpeechRecognitionLocale(localeId: 'he-IL', name: 'Hebrew (Israel)'),
      ];

      final result = await service.locales();

      expect(result, isA<SpeechRecognitionLocalesAvailable>());
      final available = result as SpeechRecognitionLocalesAvailable;
      expect(available.locales, engine.availableLocales);
      expect(engine.initializeCalls, 1);
      expect(engine.localeCalls, 1);
    });

    test(
      'should return unavailable locales when initialization is unavailable',
      () async {
        engine.isAvailable = false;

        final result = await service.locales();

        expect(result, isA<SpeechRecognitionLocalesUnavailable>());
        expect(engine.localeCalls, 0);
      },
    );

    test('should fail closed when initialization throws', () async {
      engine.initializationError = StateError('initialization failed');

      final result = await service.initialize();

      expect(result, SpeechRecognitionAvailability.unavailable);
      expect(engine.initializeCalls, 1);
    });

    test(
      'should return unavailable locales when locale lookup throws',
      () async {
        engine.localeError = StateError('locale lookup failed');

        final result = await service.locales();

        expect(result, isA<SpeechRecognitionLocalesUnavailable>());
        expect(engine.localeCalls, 1);
      },
    );

    test(
      'should relay partial and final transcript events for a session',
      () async {
        final events = <SpeechRecognitionSessionEvent>[];

        final result = await service.start(
          localeId: 'he-IL',
          onEvent: events.add,
        );

        expect(result, isA<SpeechRecognitionSessionStarted>());
        final started = result as SpeechRecognitionSessionStarted;
        expect(engine.listenCalls, 1);
        expect(engine.localeId, 'he-IL');
        expect(service.hasActiveSession, isTrue);

        engine.emitResult(text: 'shalom', isFinal: false);
        engine.emitResult(text: 'shalom world', isFinal: true);
        engine.emitStatus(SpeechRecognitionEngineStatus.completed);
        await Future<void>.delayed(Duration.zero);

        final transcripts = events
            .whereType<SpeechRecognitionTranscriptEvent>()
            .toList();
        expect(transcripts, hasLength(2));
        expect(transcripts[0].sessionId, started.sessionId);
        expect(transcripts[0].text, 'shalom');
        expect(transcripts[0].isFinal, isFalse);
        expect(transcripts[1].sessionId, started.sessionId);
        expect(transcripts[1].text, 'shalom world');
        expect(transcripts[1].isFinal, isTrue);
        expect(
          events.whereType<SpeechRecognitionStatusEvent>().single.status,
          SpeechRecognitionSessionStatus.completed,
        );
        expect(service.hasActiveSession, isFalse);
      },
    );

    test('should keep one active session across all text fields', () async {
      final first = await service.start(localeId: 'en-US', onEvent: (_) {});
      final second = await service.start(localeId: 'ar-SA', onEvent: (_) {});

      expect(first, isA<SpeechRecognitionSessionStarted>());
      expect(second, isA<SpeechRecognitionSessionStartFailure>());
      expect(
        (second as SpeechRecognitionSessionStartFailure).kind,
        SpeechRecognitionSessionStartFailureKind.alreadyActive,
      );
      expect(engine.listenCalls, 1);
    });

    test(
      'should stop an active session without discarding its final result',
      () async {
        final events = <SpeechRecognitionSessionEvent>[];
        await service.start(localeId: 'en-US', onEvent: events.add);

        expect(
          await service.stop(),
          SpeechRecognitionSessionControlResult.stopped,
        );
        engine.emitResult(text: 'final result', isFinal: true);

        expect(engine.stopCalls, 1);
        expect(
          events.whereType<SpeechRecognitionTranscriptEvent>().single.text,
          'final result',
        );
        expect(service.hasActiveSession, isTrue);
      },
    );

    test(
      'should retain a session through not-listening until final results arrive',
      () async {
        final events = <SpeechRecognitionSessionEvent>[];
        await service.start(localeId: 'en-US', onEvent: events.add);

        engine.emitStatus(SpeechRecognitionEngineStatus.notListening);

        expect(events, isEmpty);
        expect(service.hasActiveSession, isTrue);

        engine.emitResult(text: 'final result', isFinal: true);
        engine.emitStatus(SpeechRecognitionEngineStatus.completed);
        await Future<void>.delayed(Duration.zero);

        expect(
          events.whereType<SpeechRecognitionTranscriptEvent>().single.text,
          'final result',
        );
        expect(
          events.whereType<SpeechRecognitionStatusEvent>().single.status,
          SpeechRecognitionSessionStatus.completed,
        );
        expect(service.hasActiveSession, isFalse);
      },
    );

    test(
      'should discard late transcript callbacks after cancellation',
      () async {
        final events = <SpeechRecognitionSessionEvent>[];
        await service.start(localeId: 'en-US', onEvent: events.add);

        expect(
          await service.cancel(),
          SpeechRecognitionSessionControlResult.cancelled,
        );
        engine.emitResult(text: 'discarded', isFinal: true);
        engine.emitStatus(SpeechRecognitionEngineStatus.completed);

        expect(engine.cancelCalls, 1);
        expect(events, isEmpty);
        expect(service.hasActiveSession, isFalse);
      },
    );

    test(
      'should block a new session until cancellation settles and drop old callbacks',
      () async {
        final firstEvents = <SpeechRecognitionSessionEvent>[];
        await service.start(localeId: 'en-US', onEvent: firstEvents.add);
        engine.cancelCompleter = Completer<void>();

        final cancellation = service.cancel();
        expect(service.hasActiveSession, isTrue);

        final blockedStart = await service.start(
          localeId: 'he-IL',
          onEvent: (_) {},
        );
        expect(
          blockedStart,
          isA<SpeechRecognitionSessionStartFailure>().having(
            (failure) => failure.kind,
            'kind',
            SpeechRecognitionSessionStartFailureKind.alreadyActive,
          ),
        );

        engine.emitResultFromListen(0, text: 'discarded text', isFinal: true);
        engine.emitStatus(SpeechRecognitionEngineStatus.notListening);
        engine.emitError(isPermanent: true);
        expect(firstEvents, isEmpty);
        expect(service.hasActiveSession, isTrue);

        engine.cancelCompleter!.complete();
        expect(
          await cancellation,
          SpeechRecognitionSessionControlResult.cancelled,
        );
        expect(service.hasActiveSession, isFalse);

        final secondEvents = <SpeechRecognitionSessionEvent>[];
        await service.start(localeId: 'he-IL', onEvent: secondEvents.add);

        engine.emitResultFromListen(0, text: 'old session text', isFinal: true);
        expect(secondEvents, isEmpty);

        engine.emitResult(text: 'new session text', isFinal: true);
        expect(
          secondEvents
              .whereType<SpeechRecognitionTranscriptEvent>()
              .single
              .text,
          'new session text',
        );
      },
    );

    test(
      'should surface a recognition error and release the active session',
      () async {
        final events = <SpeechRecognitionSessionEvent>[];
        await service.start(localeId: 'en-US', onEvent: events.add);

        engine.emitError(isPermanent: true);
        engine.emitStatus(SpeechRecognitionEngineStatus.completed);
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(
          events.single,
          isA<SpeechRecognitionErrorEvent>().having(
            (event) => event.isPermanent,
            'isPermanent',
            isTrue,
          ),
        );
        expect(service.hasActiveSession, isFalse);
      },
    );

    test(
      'should block a new session while a non-permanent error is settling',
      () async {
        final events = <SpeechRecognitionSessionEvent>[];
        await service.start(localeId: 'en-US', onEvent: events.add);
        engine.cancelCompleter = Completer<void>();

        engine.emitError(isPermanent: false);

        expect(events, hasLength(1));
        expect(events.single, isA<SpeechRecognitionErrorEvent>());
        expect(service.hasActiveSession, isTrue);
        expect(
          await service.start(localeId: 'he-IL', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStartFailure>().having(
            (failure) => failure.kind,
            'kind',
            SpeechRecognitionSessionStartFailureKind.alreadyActive,
          ),
        );

        engine.emitStatus(SpeechRecognitionEngineStatus.notListening);
        expect(service.hasActiveSession, isTrue);
        engine.emitStatus(SpeechRecognitionEngineStatus.completed);
        engine.cancelCompleter!.complete();
        await Future<void>.delayed(Duration.zero);

        expect(service.hasActiveSession, isFalse);
      },
    );

    test('should classify a failed listen request', () async {
      engine.listenError = StateError('listen failed');

      final result = await service.start(localeId: 'en-US', onEvent: (_) {});

      expect(result, isA<SpeechRecognitionSessionStartFailure>());
      expect(
        (result as SpeechRecognitionSessionStartFailure).kind,
        SpeechRecognitionSessionStartFailureKind.startFailed,
      );
      expect(service.hasActiveSession, isFalse);
    });

    test(
      'should report no active session controls without using the engine',
      () async {
        expect(
          await service.stop(),
          SpeechRecognitionSessionControlResult.noActiveSession,
        );
        expect(
          await service.cancel(),
          SpeechRecognitionSessionControlResult.noActiveSession,
        );
        expect(engine.stopCalls, 0);
        expect(engine.cancelCalls, 0);
      },
    );

    test(
      'should classify a failed stop request while preserving the session',
      () async {
        await service.start(localeId: 'en-US', onEvent: (_) {});
        engine.stopError = StateError('stop failed');

        final result = await service.stop();

        expect(result, SpeechRecognitionSessionControlResult.failed);
        expect(service.hasActiveSession, isTrue);
      },
    );

    test('should retain exclusive ownership when cancellation fails', () async {
      await service.start(localeId: 'en-US', onEvent: (_) {});
      engine.cancelError = PlatformException(code: 'cancel_failed');

      final result = await service.cancel();

      expect(result, SpeechRecognitionSessionControlResult.failed);
      expect(service.hasActiveSession, isTrue);
      expect(
        await service.start(localeId: 'he-IL', onEvent: (_) {}),
        isA<SpeechRecognitionSessionStartFailure>().having(
          (failure) => failure.kind,
          'kind',
          SpeechRecognitionSessionStartFailureKind.alreadyActive,
        ),
      );
    });

    test(
      'should notify the discarded session when a failed cancellation later terminates',
      () async {
        final events = <SpeechRecognitionSessionEvent>[];
        await service.start(localeId: 'en-US', onEvent: events.add);
        engine.cancelError = PlatformException(code: 'cancel_failed');

        expect(
          await service.cancel(),
          SpeechRecognitionSessionControlResult.failed,
        );
        expect(events, isEmpty);
        expect(service.hasActiveSession, isTrue);

        engine.emitStatus(SpeechRecognitionEngineStatus.completed);

        expect(events, hasLength(1));
        expect(
          events.single,
          isA<SpeechRecognitionStatusEvent>()
              .having((event) => event.sessionId, 'sessionId', 1)
              .having(
                (event) => event.status,
                'status',
                SpeechRecognitionSessionStatus.completed,
              ),
        );
        expect(service.hasActiveSession, isFalse);
        expect(
          await service.start(localeId: 'he-IL', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStarted>(),
        );
      },
    );

    test(
      'should release a cancellation when a terminal status precedes its failed reply',
      () async {
        await service.start(localeId: 'en-US', onEvent: (_) {});
        engine.cancelError = PlatformException(code: 'cancel_failed');

        final cancellation = service.cancel();
        engine.emitStatus(SpeechRecognitionEngineStatus.completed);

        expect(
          await cancellation,
          SpeechRecognitionSessionControlResult.cancelled,
        );
        expect(service.hasActiveSession, isFalse);
      },
    );

    test(
      'should reject Stop while a final-only session is being discarded',
      () async {
        await service.start(localeId: 'en-US', onEvent: (_) {});
        engine.emitResult(text: 'A final before completion', isFinal: true);
        engine.cancelCompleter = Completer<void>();
        final cancellation = service.cancel();

        expect(
          await service.stop(),
          SpeechRecognitionSessionControlResult.failed,
        );
        expect(engine.stopCalls, 0);
        expect(engine.cancelCalls, 1);

        engine.cancelCompleter!.complete();
        expect(
          await cancellation,
          SpeechRecognitionSessionControlResult.cancelled,
        );
      },
    );

    for (final terminalBeforeFailure in <bool>[false, true]) {
      testWidgets(
        'should report an unexpected cancellation failure with its original '
        'stack ${terminalBeforeFailure ? 'after' : 'before'} a terminal status',
        (tester) async {
          final reports = <FlutterErrorDetails>[];
          final originalOnError = FlutterError.onError;
          FlutterError.onError = reports.add;
          try {
            final events = <SpeechRecognitionSessionEvent>[];
            final error = StateError('Unexpected cancellation defect');
            final stack = StackTrace.fromString('original cancellation stack');
            await service.start(localeId: 'en-US', onEvent: events.add);
            engine.cancelCompleter = Completer<void>();
            final cancellation = service.cancel();
            if (terminalBeforeFailure) {
              engine.emitStatus(SpeechRecognitionEngineStatus.notListening);
            }

            engine.cancelCompleter!.completeError(error, stack);
            await tester.pump();

            expect(
              await cancellation,
              SpeechRecognitionSessionControlResult.failed,
            );
            expect(reports, hasLength(1));
            expect(reports.single.exception, same(error));
            expect(reports.single.stack, same(stack));
            if (!terminalBeforeFailure) {
              expect(service.hasActiveSession, isTrue);
              expect(events, isEmpty);
              expect(
                await service.start(localeId: 'he-IL', onEvent: (_) {}),
                isA<SpeechRecognitionSessionStartFailure>(),
              );
              engine.emitStatus(SpeechRecognitionEngineStatus.notListening);
              await tester.pump();
            }
            expect(service.hasActiveSession, isFalse);
            expect(
              events.whereType<SpeechRecognitionStatusEvent>(),
              hasLength(1),
            );
            await tester.pump(const Duration(seconds: 3));
            expect(reports, hasLength(1));
            expect(events, hasLength(1));
          } finally {
            FlutterError.onError = originalOnError;
          }
        },
      );
    }

    testWidgets(
      'should report a late unexpected cleanup failure once after timeout',
      (tester) async {
        final reports = <FlutterErrorDetails>[];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = reports.add;
        try {
          final events = <SpeechRecognitionSessionEvent>[];
          final error = StateError('Late cancellation defect');
          final stack = StackTrace.fromString('late cancellation stack');
          await service.start(localeId: 'en-US', onEvent: events.add);
          engine.cancelCompleter = Completer<void>();
          engine.emitResult(text: 'Keep this final', isFinal: true);
          engine.emitStatus(SpeechRecognitionEngineStatus.completed);

          await tester.pump(const Duration(seconds: 2));
          expect(events.whereType<SpeechRecognitionErrorEvent>(), hasLength(1));
          expect(service.hasActiveSession, isTrue);
          expect(reports, isEmpty);

          engine.cancelCompleter!.completeError(error, stack);
          await tester.pump();
          expect(service.hasActiveSession, isFalse);
          expect(reports, hasLength(1));
          expect(reports.single.exception, same(error));
          expect(reports.single.stack, same(stack));
          expect(events.whereType<SpeechRecognitionErrorEvent>(), hasLength(1));
          expect(
            events.whereType<SpeechRecognitionStatusEvent>(),
            hasLength(1),
          );
          await tester.pump(const Duration(seconds: 3));
          expect(reports, hasLength(1));
          expect(events, hasLength(3));
        } finally {
          FlutterError.onError = originalOnError;
        }
      },
    );

    testWidgets(
      'should not swallow a callback PlatformException as a native cancel failure',
      (tester) async {
        final callbackError = PlatformException(
          code: 'consumer_callback_failed',
        );
        final callbackStack = StackTrace.fromString('consumer callback stack');
        final uncaughtErrors = <Object>[];
        final uncaughtStacks = <StackTrace>[];
        await service.start(
          localeId: 'en-US',
          onEvent: (event) {
            if (event is SpeechRecognitionStatusEvent) {
              Error.throwWithStackTrace(callbackError, callbackStack);
            }
          },
        );
        engine.cancelCompleter = Completer<void>();
        late Future<SpeechRecognitionSessionControlResult> cancellation;
        runZonedGuarded(
          () {
            cancellation = service.cancel();
          },
          (error, stack) {
            uncaughtErrors.add(error);
            uncaughtStacks.add(stack);
          },
        );
        engine.emitStatus(SpeechRecognitionEngineStatus.notListening);
        await tester.pump(const Duration(seconds: 2));
        expect(
          await cancellation,
          SpeechRecognitionSessionControlResult.failed,
        );

        engine.cancelCompleter!.complete();
        await tester.pump();

        expect(uncaughtErrors, hasLength(1));
        expect(uncaughtErrors.single, same(callbackError));
        expect(uncaughtStacks.single, same(callbackStack));
        expect(service.hasActiveSession, isFalse);
      },
    );

    testWidgets(
      'should not extend the final deadline for repeated completion',
      (tester) async {
        final events = <SpeechRecognitionSessionEvent>[];
        await service.start(localeId: 'en-US', onEvent: events.add);
        engine.emitStatus(SpeechRecognitionEngineStatus.completed);
        await tester.pump(const Duration(seconds: 1));
        engine.emitStatus(SpeechRecognitionEngineStatus.completed);

        await tester.pump(const Duration(seconds: 1));

        expect(events, hasLength(1));
        expect(
          events.single,
          isA<SpeechRecognitionErrorEvent>().having(
            (event) => event.isPermanent,
            'isPermanent',
            isFalse,
          ),
        );
        expect(service.hasActiveSession, isFalse);
        await tester.pump(const Duration(seconds: 1));
        expect(events, hasLength(1));
      },
    );

    testWidgets('should isolate a new session from a previous final deadline', (
      tester,
    ) async {
      final firstEvents = <SpeechRecognitionSessionEvent>[];
      await service.start(localeId: 'en-US', onEvent: firstEvents.add);
      engine.emitStatus(SpeechRecognitionEngineStatus.completed);
      await tester.pump(const Duration(seconds: 1));
      engine.emitResult(text: 'First final', isFinal: true);

      final secondEvents = <SpeechRecognitionSessionEvent>[];
      expect(
        await service.start(localeId: 'he-IL', onEvent: secondEvents.add),
        isA<SpeechRecognitionSessionStarted>(),
      );
      await tester.pump(const Duration(seconds: 2));
      engine.emitResultFromListen(0, text: 'Old callback', isFinal: true);

      expect(firstEvents, hasLength(2));
      expect(secondEvents, isEmpty);
      expect(service.hasActiveSession, isTrue);
      engine.emitResult(text: 'Second final', isFinal: true);
      engine.emitStatus(SpeechRecognitionEngineStatus.completed);
      await tester.pump();
      expect(
        secondEvents.whereType<SpeechRecognitionTranscriptEvent>().single.text,
        'Second final',
      );
      expect(service.hasActiveSession, isFalse);
    });
  });

  // Browser recognition bypasses the native MethodChannel exercised here.
  group('SpeechToTextRecognitionEngine', () {
    late _NativeSpeechChannel native;
    late SpeechToText plugin;
    late SpeechRecognitionServiceImpl service;
    late List<SpeechRecognitionSessionEvent> events;

    setUp(() {
      native = _NativeSpeechChannel();
      native.install();
      plugin = SpeechToText.withMethodChannel();
      service = SpeechRecognitionServiceImpl(
        engine: SpeechToTextRecognitionEngine(speechToText: plugin),
      );
      events = <SpeechRecognitionSessionEvent>[];
    });

    tearDown(() {
      native.cancelReply = null;
      // Cancel plugin timers synchronously, without awaiting a fake-clock
      // platform reply after a failed assertion has ended the test body.
      unawaited(plugin.cancel());
      native.uninstall();
    });

    testWidgets('should retain the existing pause and listen limits on iOS', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await service.start(localeId: 'en-US', onEvent: events.add);

        expect(native.listenArguments['pauseFor'], 3000);
        expect(native.listenArguments['listenFor'], 30000);
      } finally {
        await plugin.cancel();
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets(
      'should accept a final transcript before the listen request returns',
      (tester) async {
        native.beforeListenReply = () async {
          await native.result('An immediate final phrase', isFinal: true);
          await native.status('done');
        };

        final result = await service.start(
          localeId: 'en-US',
          onEvent: events.add,
        );
        expect(result, isA<SpeechRecognitionSessionStarted>());
        await tester.pump();

        expect(events, hasLength(2));
        expect(
          events.first,
          isA<SpeechRecognitionTranscriptEvent>().having(
            (event) => event.text,
            'text',
            'An immediate final phrase',
          ),
        );
        expect(service.hasActiveSession, isFalse);
        await tester.pump(const Duration(seconds: 31));
        expect(native.stopCalls, 0);
      },
    );

    for (final terminalBeforeListenReply in <bool>[true, false]) {
      testWidgets(
        'should clean up a cancelled pending listen when terminal status is '
        '${terminalBeforeListenReply ? 'before' : 'after'} its reply',
        (tester) async {
          final listenReply = Completer<void>();
          native.beforeListenReply = () => listenReply.future;
          native.cancelReply = Completer<void>();
          final starting = service.start(
            localeId: 'en-US',
            onEvent: events.add,
          );
          await tester.pump();

          final cancellation = service.cancel();
          await tester.pump();
          await native.result('Discard this partial', isFinal: false);
          if (terminalBeforeListenReply) {
            await native.status('notListening');
            await native.status('done');
            native.cancelReply!.complete();
            await tester.pump();
          }
          expect(service.hasActiveSession, isTrue);
          expect(events, isEmpty);
          expect(
            await service.start(localeId: 'he-IL', onEvent: (_) {}),
            isA<SpeechRecognitionSessionStartFailure>(),
          );

          listenReply.complete();
          expect(await starting, isA<SpeechRecognitionSessionStartFailure>());
          await tester.pump();
          if (!terminalBeforeListenReply) {
            expect(service.hasActiveSession, isTrue);
            await native.status('notListening');
            await native.status('done');
            native.cancelReply!.complete();
            await tester.pump();
          }
          expect(
            await cancellation,
            SpeechRecognitionSessionControlResult.cancelled,
          );
          expect(service.hasActiveSession, isFalse);
          expect(events, isEmpty);
          expect(native.cancelCalls, 1);

          await tester.pump(const Duration(seconds: 31));
          expect(native.stopCalls, 0);
          native.beforeListenReply = null;
          native.cancelReply = null;
          expect(
            await service.start(localeId: 'en-US', onEvent: events.add),
            isA<SpeechRecognitionSessionStarted>(),
          );
          for (var second = 1; second <= 29; second++) {
            await tester.pump(const Duration(seconds: 1));
            await native.result('New phrase $second', isFinal: false);
            expect(native.stopCalls, 0);
          }
          await tester.pump(const Duration(seconds: 1));
          expect(native.stopCalls, 1);
          await native.result('The new final phrase', isFinal: true);
          await native.status('notListening');
          await native.status('done');
          await tester.pump();
          expect(service.hasActiveSession, isFalse);
        },
      );
    }

    for (final listenFails in <bool>[false, true]) {
      testWidgets('should retain timed-out cancellation until a pending listen '
          '${listenFails ? 'fails' : 'succeeds'} and cleanup settles', (
        tester,
      ) async {
        final listenReply = Completer<void>();
        native.beforeListenReply = () => listenReply.future;
        final starting = service.start(localeId: 'en-US', onEvent: events.add);
        await tester.pump();
        final cancellation = service.cancel();
        await native.status('notListening');

        await tester.pump(const Duration(seconds: 2));
        expect(
          await cancellation,
          SpeechRecognitionSessionControlResult.failed,
        );
        expect(service.hasActiveSession, isTrue);
        expect(events, isEmpty);
        expect(
          await service.cancel(),
          SpeechRecognitionSessionControlResult.failed,
        );
        expect(native.cancelCalls, 0);

        if (listenFails) {
          listenReply.completeError(PlatformException(code: 'listen_failed'));
        } else {
          listenReply.complete();
        }
        expect(await starting, isA<SpeechRecognitionSessionStartFailure>());
        await tester.pump();
        expect(native.cancelCalls, 1);
        expect(service.hasActiveSession, isFalse);
        expect(
          events.single,
          isA<SpeechRecognitionStatusEvent>().having(
            (event) => event.status,
            'status',
            SpeechRecognitionSessionStatus.completed,
          ),
        );
        await tester.pump(const Duration(seconds: 31));
        expect(native.stopCalls, 0);
      });
    }

    testWidgets(
      'should keep ongoing speech active until the thirty-second limit',
      (tester) async {
        await service.start(localeId: 'en-US', onEvent: events.add);
        await native.status('listening');

        for (var second = 1; second <= 29; second++) {
          await tester.pump(const Duration(seconds: 1));
          await native.result(
            'Words spoken for $second seconds',
            isFinal: false,
          );
          expect(
            native.stopCalls,
            0,
            reason: 'Continuous speech stopped after $second seconds.',
          );
        }

        expect(service.hasActiveSession, isTrue);
        expect(
          events.whereType<SpeechRecognitionTranscriptEvent>(),
          hasLength(29),
        );
        expect(native.listenArguments['localeId'], 'en-US');
        expect(
          native.listenArguments['listenMode'],
          ListenMode.dictation.index,
        );

        await tester.pump(const Duration(seconds: 1));
        expect(native.stopCalls, 1);

        await native.result('The complete spoken sentence', isFinal: true);
        await native.status('notListening');
        await native.status('done');
        await plugin.cancel();
        expect(service.hasActiveSession, isFalse);
      },
    );

    testWidgets(
      'should deliver a delayed final after stopping before the first partial',
      (tester) async {
        await service.start(localeId: 'en-US', onEvent: events.add);
        await service.stop();
        await native.status('notListening');
        await native.status('doneNoResult');

        expect(events, isEmpty);
        expect(service.hasActiveSession, isTrue);
        expect(
          await service.start(localeId: 'he-IL', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStartFailure>().having(
            (failure) => failure.kind,
            'kind',
            SpeechRecognitionSessionStartFailureKind.alreadyActive,
          ),
        );

        await tester.pump(const Duration(milliseconds: 1900));
        await native.result('The delayed final words', isFinal: true);
        await tester.pump();

        expect(events, hasLength(2));
        expect(
          events.first,
          isA<SpeechRecognitionTranscriptEvent>()
              .having((event) => event.text, 'text', 'The delayed final words')
              .having((event) => event.isFinal, 'isFinal', isTrue),
        );
        expect(
          events.last,
          isA<SpeechRecognitionStatusEvent>().having(
            (event) => event.status,
            'status',
            SpeechRecognitionSessionStatus.completed,
          ),
        );
        expect(service.hasActiveSession, isFalse);
        await tester.pump(const Duration(seconds: 3));
        expect(events, hasLength(2));
      },
    );

    for (final hasFinal in <bool>[true, false]) {
      testWidgets('should preserve the next session limit after repeated '
          '${hasFinal ? 'successful completions' : 'empty-result retries'}', (
        tester,
      ) async {
        for (var previous = 0; previous < 2; previous++) {
          await service.start(localeId: 'en-US', onEvent: (_) {});
          await tester.pump(const Duration(seconds: 1));
          await native.status('notListening');
          if (hasFinal) {
            await native.result('Previous complete phrase', isFinal: true);
            await native.status('done');
          } else {
            await native.status('doneNoResult');
            await tester.pump(const Duration(seconds: 2));
          }
          expect(service.hasActiveSession, isFalse);
        }

        await service.start(localeId: 'en-US', onEvent: events.add);
        await native.status('listening');
        for (var second = 1; second <= 29; second++) {
          await tester.pump(const Duration(seconds: 1));
          await native.result('Ongoing phrase $second', isFinal: false);
          expect(
            native.stopCalls,
            0,
            reason: 'An old session stopped the new one after $second seconds.',
          );
        }
        await tester.pump(const Duration(seconds: 1));
        expect(native.stopCalls, 1);
        await native.result('The current complete phrase', isFinal: true);
        await native.status('notListening');
        await native.status('done');
        await plugin.cancel();
        expect(service.hasActiveSession, isFalse);
      });
    }

    for (final completionFirst in <bool>[false, true]) {
      testWidgets(
        'should accept Stop during automatic cleanup after '
        '${completionFirst ? 'completion then a late final' : 'a final then completion'}',
        (tester) async {
          await service.start(localeId: 'en-US', onEvent: events.add);
          native.cancelReply = Completer<void>();
          if (completionFirst) {
            await native.status('doneNoResult');
            await tester.pump(const Duration(milliseconds: 500));
          }
          await native.result('The complete final phrase', isFinal: true);
          if (!completionFirst) {
            await native.status('done');
          }
          await tester.pump();

          expect(
            await service.stop(),
            SpeechRecognitionSessionControlResult.stopped,
          );
          expect(native.stopCalls, 0);
          expect(native.cancelCalls, 1);
          expect(service.hasActiveSession, isTrue);
          expect(events.whereType<SpeechRecognitionErrorEvent>(), isEmpty);

          native.cancelReply!.complete();
          await tester.pump();
          expect(service.hasActiveSession, isFalse);
          expect(
            events.whereType<SpeechRecognitionTranscriptEvent>(),
            hasLength(1),
          );
          expect(
            events.whereType<SpeechRecognitionStatusEvent>(),
            hasLength(1),
          );
        },
      );
    }

    testWidgets(
      'should report a cleanup timeout while retaining ownership until its late reply',
      (tester) async {
        await service.start(localeId: 'en-US', onEvent: events.add);
        await native.result('The complete final phrase', isFinal: true);
        await native.status('notListening');
        native.cancelReply = Completer<void>();
        await native.status('done');

        expect(events, hasLength(1));
        expect(events.single, isA<SpeechRecognitionTranscriptEvent>());
        expect(service.hasActiveSession, isTrue);
        expect(native.cancelCalls, 1);
        expect(
          await service.start(localeId: 'he-IL', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStartFailure>(),
        );
        await tester.pump(const Duration(milliseconds: 1999));
        expect(service.hasActiveSession, isTrue);
        expect(events, hasLength(1));

        await tester.pump(const Duration(milliseconds: 1));
        expect(service.hasActiveSession, isTrue);
        expect(events, hasLength(2));
        expect(
          events.whereType<SpeechRecognitionErrorEvent>().single.isPermanent,
          isFalse,
        );
        expect(
          await service.start(localeId: 'he-IL', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStartFailure>(),
        );
        await tester.pump(const Duration(seconds: 1));
        expect(events.whereType<SpeechRecognitionErrorEvent>(), hasLength(1));

        native.cancelReply!.complete();
        await tester.pump();
        expect(service.hasActiveSession, isFalse);
        expect(events, hasLength(3));
        expect(events.whereType<SpeechRecognitionStatusEvent>(), hasLength(1));

        native.cancelReply = null;
        final nextEvents = <SpeechRecognitionSessionEvent>[];
        expect(
          await service.start(localeId: 'en-US', onEvent: nextEvents.add),
          isA<SpeechRecognitionSessionStarted>(),
        );
        for (var second = 1; second <= 29; second++) {
          await tester.pump(const Duration(seconds: 1));
          await native.result('The next phrase $second', isFinal: false);
          expect(native.stopCalls, 0);
        }
        expect(events, hasLength(3));
        expect(nextEvents.whereType<SpeechRecognitionErrorEvent>(), isEmpty);
        await tester.pump(const Duration(seconds: 1));
        expect(native.stopCalls, 1);
        await native.result('The next final', isFinal: true);
        await native.status('notListening');
        await native.status('done');
        await tester.pump();
        expect(service.hasActiveSession, isFalse);
      },
    );

    testWidgets(
      'should report an error after two seconds when completion has no final',
      (tester) async {
        await service.start(localeId: 'en-US', onEvent: events.add);
        await native.status('notListening');
        await native.status('doneNoResult');

        await tester.pump(const Duration(milliseconds: 1999));
        expect(events, isEmpty);
        expect(service.hasActiveSession, isTrue);

        await tester.pump(const Duration(milliseconds: 1));
        expect(events, hasLength(1));
        expect(events.single, isA<SpeechRecognitionErrorEvent>());
        expect(service.hasActiveSession, isFalse);

        await native.result('Too late to apply', isFinal: true);
        await plugin.cancel();
        expect(events, hasLength(1));
        expect(
          await service.start(localeId: 'en-US', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStarted>(),
        );
        await plugin.cancel();
      },
    );

    testWidgets(
      'should surface an error after completion and clear the final wait',
      (tester) async {
        await service.start(localeId: 'en-US', onEvent: events.add);
        await native.status('notListening');
        await native.status('doneNoResult');
        await tester.pump(const Duration(milliseconds: 500));

        await native.error();
        await tester.pump();
        expect(events, hasLength(1));
        expect(events.single, isA<SpeechRecognitionErrorEvent>());
        expect(service.hasActiveSession, isFalse);

        await tester.pump(const Duration(seconds: 3));
        expect(events, hasLength(1));
      },
    );

    testWidgets(
      'should cancel after a partial even when the plugin suppresses done',
      (tester) async {
        await service.start(localeId: 'en-US', onEvent: events.add);
        await native.result('Discard this partial', isFinal: false);
        events.clear();
        native.cancelReply = Completer<void>();
        SpeechRecognitionSessionControlResult? result;
        final cancellation = service.cancel().then((value) => result = value);
        await tester.pump();

        await native.status('notListening');
        await native.status('done');
        expect(service.hasActiveSession, isTrue);
        expect(result, isNull);
        expect(
          await service.start(localeId: 'he-IL', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStartFailure>(),
        );

        native.cancelReply!.complete();
        await tester.pump();
        expect(result, SpeechRecognitionSessionControlResult.cancelled);
        await cancellation;
        expect(service.hasActiveSession, isFalse);
        await native.result('Discard this late final too', isFinal: true);
        expect(events, isEmpty);
        expect(
          await service.start(localeId: 'he-IL', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStarted>(),
        );
        await plugin.cancel();
      },
    );

    testWidgets(
      'should cancel when notListening arrived before the discard request',
      (tester) async {
        await service.start(localeId: 'en-US', onEvent: events.add);
        await native.result('Discard this partial', isFinal: false);
        await native.status('notListening');
        await native.status('done');
        events.clear();

        SpeechRecognitionSessionControlResult? result;
        final cancellation = service.cancel().then((value) => result = value);
        await tester.pump();

        expect(result, SpeechRecognitionSessionControlResult.cancelled);
        await cancellation;
        expect(service.hasActiveSession, isFalse);
        expect(events, isEmpty);
        expect(
          await service.start(localeId: 'en-US', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStarted>(),
        );
        await plugin.cancel();
      },
    );

    testWidgets(
      'should retain ownership when a cancellation reply exceeds two seconds',
      (tester) async {
        await service.start(localeId: 'en-US', onEvent: events.add);
        await native.result('Discard this partial', isFinal: false);
        events.clear();
        native.cancelReply = Completer<void>();
        final cancellation = service.cancel();
        await tester.pump();
        await native.status('notListening');

        await tester.pump(const Duration(seconds: 2));
        expect(
          await cancellation,
          SpeechRecognitionSessionControlResult.failed,
        );
        expect(service.hasActiveSession, isTrue);
        expect(events, isEmpty);
        expect(
          await service.cancel(),
          SpeechRecognitionSessionControlResult.failed,
        );
        expect(native.cancelCalls, 1);
        expect(
          await service.start(localeId: 'he-IL', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStartFailure>(),
        );
        await native.status('doneNoResult');
        expect(service.hasActiveSession, isTrue);

        native.cancelReply!.complete();
        await tester.pump();
        expect(service.hasActiveSession, isFalse);
        expect(
          events.single,
          isA<SpeechRecognitionStatusEvent>().having(
            (event) => event.status,
            'status',
            SpeechRecognitionSessionStatus.completed,
          ),
        );
        await native.result('Discard this late final', isFinal: true);
        expect(events, hasLength(1));
        expect(
          await service.start(localeId: 'en-US', onEvent: (_) {}),
          isA<SpeechRecognitionSessionStarted>(),
        );
        await plugin.cancel();
      },
    );

    testWidgets(
      'should discard a pending final without leaving a settlement error',
      (tester) async {
        await service.start(localeId: 'en-US', onEvent: events.add);
        await native.status('notListening');
        await native.status('doneNoResult');

        SpeechRecognitionSessionControlResult? result;
        final cancellation = service.cancel().then((value) => result = value);
        await tester.pump();
        expect(result, SpeechRecognitionSessionControlResult.cancelled);
        await cancellation;

        await native.result('Discard this delayed final', isFinal: true);
        await tester.pump(const Duration(seconds: 3));
        expect(events, isEmpty);
        expect(service.hasActiveSession, isFalse);
      },
    );
  }, skip: kIsWeb);
}

final class _NativeSpeechChannel {
  static const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Map<Object?, Object?> listenArguments = <Object?, Object?>{};
  Future<void> Function()? beforeListenReply;
  Completer<void>? cancelReply;
  int stopCalls = 0;
  int cancelCalls = 0;

  void install() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'listen':
          listenArguments = call.arguments as Map<Object?, Object?>;
          await beforeListenReply?.call();
          return true;
        case 'stop':
          stopCalls++;
          return null;
        case 'cancel':
          cancelCalls++;
          await cancelReply?.future;
          return null;
        default:
          throw StateError('Unexpected speech method: ${call.method}');
      }
    });
  }

  void uninstall() {
    messenger.setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  }

  Future<void> status(String value) => _send('notifyStatus', value);

  Future<void> result(String text, {required bool isFinal}) async {
    // Android only sends partials when the adapter requests them.
    if (!isFinal && listenArguments['partialResults'] != true) {
      return;
    }
    await _send(
      'textRecognition',
      jsonEncode(<String, Object>{
        'alternates': <Map<String, Object>>[
          <String, Object>{'recognizedWords': text, 'confidence': 1.0},
        ],
        'resultType': isFinal
            ? ResultType.finalResult.value
            : ResultType.partial.value,
      }),
    );
  }

  Future<void> error() => _send(
    'notifyError',
    jsonEncode(<String, Object>{
      'errorMsg': 'error_no_match',
      'permanent': true,
    }),
  );

  Future<void> _send(String method, Object arguments) async {
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall(method, arguments)),
      (_) {},
    );
  }
}

final class _FakeSpeechRecognitionEngine implements SpeechRecognitionEngine {
  bool isAvailable = true;
  List<SpeechRecognitionLocale> availableLocales =
      const <SpeechRecognitionLocale>[];
  Object? initializationError;
  Object? localeError;
  Object? listenError;
  Object? stopError;
  Object? cancelError;
  int initializeCalls = 0;
  int localeCalls = 0;
  int listenCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  String? localeId;
  SpeechRecognitionEngineStatusCallback? _onStatus;
  SpeechRecognitionEngineErrorCallback? _onError;
  SpeechRecognitionEngineResultCallback? _onResult;
  final List<SpeechRecognitionEngineResultCallback> _resultCallbacks = [];
  Completer<void>? cancelCompleter;

  @override
  Future<bool> initialize({
    required SpeechRecognitionEngineStatusCallback onStatus,
    required SpeechRecognitionEngineErrorCallback onError,
  }) async {
    initializeCalls++;
    _onStatus = onStatus;
    _onError = onError;
    final error = initializationError;
    if (error != null) {
      throw error;
    }
    return isAvailable;
  }

  @override
  Future<List<SpeechRecognitionLocale>> locales() async {
    localeCalls++;
    final error = localeError;
    if (error != null) {
      throw error;
    }
    return availableLocales;
  }

  @override
  Future<void> listen({
    required String localeId,
    required SpeechRecognitionEngineResultCallback onResult,
  }) async {
    listenCalls++;
    this.localeId = localeId;
    _onResult = onResult;
    _resultCallbacks.add(onResult);
    final error = listenError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    final error = stopError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
    final completer = cancelCompleter;
    if (completer != null) {
      await completer.future;
    }
    final error = cancelError;
    if (error != null) {
      throw error;
    }
    emitStatus(SpeechRecognitionEngineStatus.completed);
  }

  void emitResult({required String text, required bool isFinal}) {
    _onResult?.call(
      SpeechRecognitionEngineResult(text: text, isFinal: isFinal),
    );
  }

  void emitResultFromListen(
    int listenIndex, {
    required String text,
    required bool isFinal,
  }) {
    _resultCallbacks[listenIndex](
      SpeechRecognitionEngineResult(text: text, isFinal: isFinal),
    );
  }

  void emitStatus(SpeechRecognitionEngineStatus status) {
    _onStatus?.call(status);
  }

  void emitError({required bool isPermanent}) {
    _onError?.call(SpeechRecognitionEngineError(isPermanent: isPermanent));
  }
}
