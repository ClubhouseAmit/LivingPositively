import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as speech_to_text;

/// Receives lifecycle, transcript, and error events for one recognition
/// session.
typedef SpeechRecognitionEventCallback =
    void Function(SpeechRecognitionSessionEvent event);

/// Provides short, user-initiated speech-recognition sessions for text input.
///
/// Implementations must keep one recognizer instance for the application
/// session. Recognized text is delivered only to the callback supplied to
/// [start]; this service does not persist or log transcripts.
abstract interface class SpeechRecognitionService {
  /// Initializes the recognizer once for the application session.
  Future<SpeechRecognitionAvailability> initialize();

  /// Returns the recognition locales installed on the current device.
  Future<SpeechRecognitionLocalesResult> locales();

  /// Starts one short recognition session in [localeId].
  ///
  /// Only one session can be active across all text fields. The session emits
  /// results through [onEvent].
  Future<SpeechRecognitionSessionStartResult> start({
    required String localeId,
    required SpeechRecognitionEventCallback onEvent,
  });

  /// Requests completion of the active session while retaining its final
  /// result callback.
  Future<SpeechRecognitionSessionControlResult> stop();

  /// Discards the active session and suppresses ordinary later recognizer
  /// callbacks.
  ///
  /// If cancellation completes with
  /// [SpeechRecognitionSessionControlResult.failed], a later terminal signal
  /// for the same still-active discarded session may deliver one synthetic
  /// [SpeechRecognitionStatusEvent] with
  /// [SpeechRecognitionSessionStatus.completed] through the original [start]
  /// callback. Callbacks for nonmatching session IDs remain ignored.
  Future<SpeechRecognitionSessionControlResult> cancel();

  /// Whether a recognition session is currently active.
  bool get hasActiveSession;
}

/// Whether speech recognition can be used on the current device or browser.
enum SpeechRecognitionAvailability {
  /// The recognizer initialized successfully.
  available,

  /// The recognizer is unavailable, unsupported, or permission was denied.
  unavailable,
}

/// The result of loading installed recognition locales.
sealed class SpeechRecognitionLocalesResult {
  const SpeechRecognitionLocalesResult();
}

/// Installed locales returned by an available recognizer.
final class SpeechRecognitionLocalesAvailable
    extends SpeechRecognitionLocalesResult {
  /// Creates a successful locale lookup.
  const SpeechRecognitionLocalesAvailable(this.locales);

  /// The installed locales that can be selected for the next session.
  final List<SpeechRecognitionLocale> locales;
}

/// A locale lookup when the recognizer is unavailable or cannot list locales.
final class SpeechRecognitionLocalesUnavailable
    extends SpeechRecognitionLocalesResult {
  /// Creates an unavailable locale lookup result.
  const SpeechRecognitionLocalesUnavailable();
}

/// An installed device or browser recognition locale.
final class SpeechRecognitionLocale {
  /// Creates a recognition locale.
  const SpeechRecognitionLocale({required this.localeId, required this.name});

  /// The recognizer locale identifier passed to [SpeechRecognitionService.start].
  final String localeId;

  /// The recognizer-provided display name for the locale.
  final String name;
}

/// The result of attempting to start a recognition session.
sealed class SpeechRecognitionSessionStartResult {
  const SpeechRecognitionSessionStartResult();
}

/// A recognition session that successfully started.
final class SpeechRecognitionSessionStarted
    extends SpeechRecognitionSessionStartResult {
  /// Creates a started recognition session.
  const SpeechRecognitionSessionStarted(this.sessionId);

  /// Identifies events emitted by this session.
  final int sessionId;
}

/// A recognition session that could not start.
final class SpeechRecognitionSessionStartFailure
    extends SpeechRecognitionSessionStartResult {
  /// Creates a failed session-start result.
  const SpeechRecognitionSessionStartFailure(this.kind);

  /// The classified reason the session did not start.
  final SpeechRecognitionSessionStartFailureKind kind;
}

/// Classifies why a recognition session could not start.
enum SpeechRecognitionSessionStartFailureKind {
  /// Recognition is unavailable on the device, browser, or permissions state.
  unavailable,

  /// Another text field currently owns the recognizer.
  alreadyActive,

  /// The recognizer rejected or failed to start the requested session.
  startFailed,
}

/// The result of controlling an active recognition session.
enum SpeechRecognitionSessionControlResult {
  /// The recognizer received a request to finish the active session.
  stopped,

  /// The active session was discarded.
  cancelled,

  /// There was no active session to control.
  noActiveSession,

  /// The recognizer could not perform the requested control action.
  failed,
}

/// A typed event produced during one recognition session.
sealed class SpeechRecognitionSessionEvent {
  const SpeechRecognitionSessionEvent(this.sessionId);

  /// Identifies the session that produced this event.
  final int sessionId;
}

/// A partial or final transcript from one recognition session.
final class SpeechRecognitionTranscriptEvent
    extends SpeechRecognitionSessionEvent {
  /// Creates a transcript event.
  const SpeechRecognitionTranscriptEvent({
    required int sessionId,
    required this.text,
    required this.isFinal,
  }) : super(sessionId);

  /// The transcript for the active session.
  final String text;

  /// Whether [text] is the final recognition result.
  final bool isFinal;
}

/// A lifecycle change for one recognition session.
final class SpeechRecognitionStatusEvent extends SpeechRecognitionSessionEvent {
  /// Creates a status event.
  const SpeechRecognitionStatusEvent({
    required int sessionId,
    required this.status,
  }) : super(sessionId);

  /// The new recognition session status.
  final SpeechRecognitionSessionStatus status;
}

/// The lifecycle states surfaced to text input controls.
enum SpeechRecognitionSessionStatus {
  /// The recognizer is accepting speech.
  listening,

  /// The recognizer ended the session.
  completed,
}

/// A recognition failure for one active session.
final class SpeechRecognitionErrorEvent extends SpeechRecognitionSessionEvent {
  /// Creates a recognition error event.
  const SpeechRecognitionErrorEvent({
    required int sessionId,
    required this.isPermanent,
  }) : super(sessionId);

  /// Whether the platform classifies the failure as permanent.
  final bool isPermanent;
}

/// A narrow recognizer seam used by [SpeechRecognitionServiceImpl].
///
/// Keeping the plugin behind this interface permits lifecycle tests without a
/// platform channel and preserves one plugin instance in production.
abstract interface class SpeechRecognitionEngine {
  /// Initializes the recognizer and installs its global status callbacks.
  Future<bool> initialize({
    required SpeechRecognitionEngineStatusCallback onStatus,
    required SpeechRecognitionEngineErrorCallback onError,
  });

  /// Returns the locales currently installed by the recognizer.
  Future<List<SpeechRecognitionLocale>> locales();

  /// Starts a short recognizer session for [localeId].
  Future<void> listen({
    required String localeId,
    required SpeechRecognitionEngineResultCallback onResult,
  });

  /// Requests completion of the active recognizer session.
  Future<void> stop();

  /// Cancels the active recognizer session and discards its result.
  Future<void> cancel();
}

/// Receives a lifecycle update from the underlying recognizer.
typedef SpeechRecognitionEngineStatusCallback =
    void Function(SpeechRecognitionEngineStatus status);

/// Receives an error from the underlying recognizer.
typedef SpeechRecognitionEngineErrorCallback =
    void Function(SpeechRecognitionEngineError error);

/// Receives a transcript result from the underlying recognizer.
typedef SpeechRecognitionEngineResultCallback =
    void Function(SpeechRecognitionEngineResult result);

/// Lifecycle states emitted by the underlying recognizer.
enum SpeechRecognitionEngineStatus {
  /// The recognizer is accepting speech.
  listening,

  /// The recognizer stopped listening but may still deliver a final result.
  notListening,

  /// The recognizer finished a session.
  completed,

  /// A status the service does not need to expose to input controls.
  unknown,
}

/// A transcript result emitted by the underlying recognizer.
final class SpeechRecognitionEngineResult {
  /// Creates an engine transcript result.
  const SpeechRecognitionEngineResult({
    required this.text,
    required this.isFinal,
  });

  /// The recognized text.
  final String text;

  /// Whether [text] is the final recognition result.
  final bool isFinal;
}

/// An error emitted by the underlying recognizer.
final class SpeechRecognitionEngineError {
  /// Creates an engine recognition error.
  const SpeechRecognitionEngineError({required this.isPermanent});

  /// Whether the recognizer classifies the error as permanent.
  final bool isPermanent;
}

/// A [SpeechRecognitionService] backed by one [SpeechRecognitionEngine].
final class SpeechRecognitionServiceImpl implements SpeechRecognitionService {
  /// Creates the production service with one speech-to-text engine instance.
  SpeechRecognitionServiceImpl({SpeechRecognitionEngine? engine})
    : _engine = engine ?? SpeechToTextRecognitionEngine();

  final SpeechRecognitionEngine _engine;
  Future<SpeechRecognitionAvailability>? _initialization;
  _ActiveSpeechRecognitionSession? _activeSession;
  Future<SpeechRecognitionSessionControlResult>? _cancellation;
  Completer<SpeechRecognitionSessionControlResult>? _cancellationCompleter;
  Timer? _cancellationTimeout;
  int _nextSessionId = 0;

  static const _cancellationSettleTimeout = Duration(seconds: 2);

  @override
  bool get hasActiveSession => _activeSession != null || _cancellation != null;

  @override
  Future<SpeechRecognitionAvailability> initialize() {
    return _initialization ??= _initialize();
  }

  @override
  Future<SpeechRecognitionLocalesResult> locales() async {
    if (await initialize() != SpeechRecognitionAvailability.available) {
      return const SpeechRecognitionLocalesUnavailable();
    }

    try {
      final locales = await _engine.locales();
      return SpeechRecognitionLocalesAvailable(
        List<SpeechRecognitionLocale>.unmodifiable(locales),
      );
    } catch (_) {
      return const SpeechRecognitionLocalesUnavailable();
    }
  }

  @override
  Future<SpeechRecognitionSessionStartResult> start({
    required String localeId,
    required SpeechRecognitionEventCallback onEvent,
  }) async {
    if (await initialize() != SpeechRecognitionAvailability.available) {
      return const SpeechRecognitionSessionStartFailure(
        SpeechRecognitionSessionStartFailureKind.unavailable,
      );
    }
    if (_activeSession != null || _cancellation != null) {
      return const SpeechRecognitionSessionStartFailure(
        SpeechRecognitionSessionStartFailureKind.alreadyActive,
      );
    }

    final session = _ActiveSpeechRecognitionSession(
      id: ++_nextSessionId,
      onEvent: onEvent,
    );
    _activeSession = session;
    try {
      await _engine.listen(
        localeId: localeId,
        onResult: (result) => _onEngineResult(session.id, result),
      );
      if (session.isDiscarded) {
        return const SpeechRecognitionSessionStartFailure(
          SpeechRecognitionSessionStartFailureKind.startFailed,
        );
      }
      return SpeechRecognitionSessionStarted(session.id);
    } catch (_) {
      if (_activeSession?.id == session.id && !session.isDiscarded) {
        _activeSession = null;
      }
      return const SpeechRecognitionSessionStartFailure(
        SpeechRecognitionSessionStartFailureKind.startFailed,
      );
    }
  }

  @override
  Future<SpeechRecognitionSessionControlResult> stop() async {
    final session = _activeSession;
    if (session == null) {
      return SpeechRecognitionSessionControlResult.noActiveSession;
    }
    if (session.isDiscarded) {
      return SpeechRecognitionSessionControlResult.failed;
    }

    try {
      await _engine.stop();
      return SpeechRecognitionSessionControlResult.stopped;
    } catch (_) {
      return SpeechRecognitionSessionControlResult.failed;
    }
  }

  @override
  Future<SpeechRecognitionSessionControlResult> cancel() {
    final pendingCancellation = _cancellation;
    if (pendingCancellation != null) {
      return pendingCancellation;
    }

    final session = _activeSession;
    if (session == null) {
      return Future<SpeechRecognitionSessionControlResult>.value(
        SpeechRecognitionSessionControlResult.noActiveSession,
      );
    }

    session.isDiscarded = true;
    session.cancelRequestSettled = false;
    session.terminalSignalReceived = false;
    final completer = Completer<SpeechRecognitionSessionControlResult>();
    _cancellationCompleter = completer;
    _cancellation = completer.future;
    _cancellationTimeout = Timer(_cancellationSettleTimeout, () {
      _completeCancellation(
        session,
        session.terminalSignalReceived
            ? SpeechRecognitionSessionControlResult.cancelled
            : SpeechRecognitionSessionControlResult.failed,
      );
    });
    unawaited(_requestCancellation(session));
    return completer.future;
  }

  Future<void> _requestCancellation(
    _ActiveSpeechRecognitionSession session,
  ) async {
    try {
      await _engine.cancel();
      session.cancelRequestSettled = true;
      _completeCancellationWhenQuiescent(session);
    } catch (_) {
      _completeCancellation(
        session,
        session.terminalSignalReceived
            ? SpeechRecognitionSessionControlResult.cancelled
            : SpeechRecognitionSessionControlResult.failed,
      );
    }
  }

  void _completeCancellationWhenQuiescent(
    _ActiveSpeechRecognitionSession session,
  ) {
    if (!session.cancelRequestSettled || !session.terminalSignalReceived) {
      return;
    }
    _completeCancellation(
      session,
      SpeechRecognitionSessionControlResult.cancelled,
    );
  }

  void _completeCancellation(
    _ActiveSpeechRecognitionSession session,
    SpeechRecognitionSessionControlResult result,
  ) {
    if (_activeSession?.id != session.id) {
      return;
    }
    _cancellationTimeout?.cancel();
    _cancellationTimeout = null;
    if (result == SpeechRecognitionSessionControlResult.cancelled) {
      _activeSession = null;
    }
    final completer = _cancellationCompleter;
    _cancellationCompleter = null;
    _cancellation = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  void _recordDiscardedSessionTerminalSignal(
    _ActiveSpeechRecognitionSession session,
  ) {
    session.terminalSignalReceived = true;
    if (_cancellation != null) {
      _completeCancellationWhenQuiescent(session);
      return;
    }
    // A previous cancellation failed, but a later terminal lifecycle signal
    // conclusively releases the recognizer and lets its UI clear controls.
    if (_activeSession?.id != session.id) {
      return;
    }
    _activeSession = null;
    session.onEvent(
      SpeechRecognitionStatusEvent(
        sessionId: session.id,
        status: SpeechRecognitionSessionStatus.completed,
      ),
    );
  }

  Future<SpeechRecognitionAvailability> _initialize() async {
    try {
      final available = await _engine.initialize(
        onStatus: _onEngineStatus,
        onError: _onEngineError,
      );
      return available
          ? SpeechRecognitionAvailability.available
          : SpeechRecognitionAvailability.unavailable;
    } catch (_) {
      return SpeechRecognitionAvailability.unavailable;
    }
  }

  void _onEngineResult(int sessionId, SpeechRecognitionEngineResult result) {
    final session = _activeSession;
    if (session == null || session.id != sessionId || session.isDiscarded) {
      return;
    }
    session.onEvent(
      SpeechRecognitionTranscriptEvent(
        sessionId: session.id,
        text: result.text,
        isFinal: result.isFinal,
      ),
    );
  }

  void _onEngineStatus(SpeechRecognitionEngineStatus status) {
    final session = _activeSession;
    if (session == null) {
      return;
    }
    if (session.isDiscarded) {
      if (status == SpeechRecognitionEngineStatus.completed) {
        _recordDiscardedSessionTerminalSignal(session);
      }
      return;
    }
    if (status == SpeechRecognitionEngineStatus.unknown ||
        status == SpeechRecognitionEngineStatus.notListening) {
      return;
    }

    final sessionStatus = switch (status) {
      SpeechRecognitionEngineStatus.listening =>
        SpeechRecognitionSessionStatus.listening,
      SpeechRecognitionEngineStatus.notListening => throw StateError(
        'The intermediate not-listening status is ignored above.',
      ),
      SpeechRecognitionEngineStatus.completed =>
        SpeechRecognitionSessionStatus.completed,
      SpeechRecognitionEngineStatus.unknown => throw StateError(
        'Unknown engine status is ignored above.',
      ),
    };
    if (sessionStatus == SpeechRecognitionSessionStatus.completed) {
      _activeSession = null;
    }
    session.onEvent(
      SpeechRecognitionStatusEvent(
        sessionId: session.id,
        status: sessionStatus,
      ),
    );
  }

  void _onEngineError(SpeechRecognitionEngineError error) {
    final session = _activeSession;
    if (session == null) {
      return;
    }
    if (session.isDiscarded) {
      return;
    }
    final cancellation = cancel();
    session.onEvent(
      SpeechRecognitionErrorEvent(
        sessionId: session.id,
        isPermanent: error.isPermanent,
      ),
    );
    unawaited(cancellation);
  }
}

/// Adapts the speech_to_text plugin to the narrow [SpeechRecognitionEngine].
final class SpeechToTextRecognitionEngine implements SpeechRecognitionEngine {
  /// Creates an engine with one plugin instance.
  SpeechToTextRecognitionEngine({speech_to_text.SpeechToText? speechToText})
    : _speechToText = speechToText ?? speech_to_text.SpeechToText();

  static const Duration _shortListenDuration = Duration(seconds: 30);
  static const Duration _shortPauseDuration = Duration(seconds: 3);

  final speech_to_text.SpeechToText _speechToText;

  @override
  Future<bool> initialize({
    required SpeechRecognitionEngineStatusCallback onStatus,
    required SpeechRecognitionEngineErrorCallback onError,
  }) {
    return _speechToText.initialize(
      onStatus: (status) => onStatus(_statusFor(status)),
      onError: (error) =>
          onError(SpeechRecognitionEngineError(isPermanent: error.permanent)),
    );
  }

  @override
  Future<List<SpeechRecognitionLocale>> locales() async {
    final locales = await _speechToText.locales();
    return List<SpeechRecognitionLocale>.unmodifiable(
      locales.map(
        (locale) => SpeechRecognitionLocale(
          localeId: locale.localeId,
          name: locale.name,
        ),
      ),
    );
  }

  @override
  Future<void> listen({
    required String localeId,
    required SpeechRecognitionEngineResultCallback onResult,
  }) {
    return _speechToText.listen(
      listenOptions: speech_to_text.SpeechListenOptions(
        localeId: localeId,
        listenFor: _shortListenDuration,
        pauseFor: _shortPauseDuration,
        partialResults: false,
        cancelOnError: false,
        listenMode: speech_to_text.ListenMode.dictation,
      ),
      onResult: (result) => onResult(
        SpeechRecognitionEngineResult(
          text: result.recognizedWords,
          isFinal: result.finalResult,
        ),
      ),
    );
  }

  @override
  Future<void> stop() => _speechToText.stop();

  @override
  Future<void> cancel() => _speechToText.cancel();

  SpeechRecognitionEngineStatus _statusFor(String status) {
    return switch (status) {
      'listening' => SpeechRecognitionEngineStatus.listening,
      'notListening' => SpeechRecognitionEngineStatus.notListening,
      'done' => SpeechRecognitionEngineStatus.completed,
      _ => SpeechRecognitionEngineStatus.unknown,
    };
  }
}

final class _ActiveSpeechRecognitionSession {
  _ActiveSpeechRecognitionSession({required this.id, required this.onEvent});

  final int id;
  final SpeechRecognitionEventCallback onEvent;
  bool isDiscarded = false;
  bool cancelRequestSettled = false;
  bool terminalSignalReceived = false;
}
