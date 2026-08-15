import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/speech_recognition_service.dart';

void main() {
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

        engine.emitStatus(SpeechRecognitionEngineStatus.completed);
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
      engine.cancelError = StateError('cancel failed');

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
      'should release a cancellation when a terminal status precedes its failed reply',
      () async {
        await service.start(localeId: 'en-US', onEvent: (_) {});
        engine.cancelError = StateError('cancel failed');

        final cancellation = service.cancel();
        engine.emitStatus(SpeechRecognitionEngineStatus.completed);

        expect(
          await cancellation,
          SpeechRecognitionSessionControlResult.cancelled,
        );
        expect(service.hasActiveSession, isFalse);
      },
    );
  });
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
