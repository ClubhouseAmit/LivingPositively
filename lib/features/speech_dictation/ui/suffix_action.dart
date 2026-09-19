import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/util/async/speech_recognition_service.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

part 'session.dart';
part 'transcript.dart';

/// Converts a final transcript before it replaces an input value.
typedef SpeechTranscriptTransformer =
    String? Function(String transcript, String localeId);

/// Validates a transformed transcript before it replaces an input value.
typedef SpeechTranscriptValidator = bool Function(String transcript);

const double _micHitSize = 48;

/// A text-field suffix action that provides short, explicit dictation.
/// Existing forms retain ownership of controllers, validation, and storage.
class SpeechDictationSuffixAction extends StatefulWidget {
  /// Creates a suffix action for [controller].
  const SpeechDictationSuffixAction({
    required this.controller,
    super.key,
    this.maxLength,
    this.onTextApplied,
    this.transcriptTransformer,
    this.replacementValidator,
    this.isPhoneNumber = false,
    this.speechRecognitionService,
    this.persistentMemoryService,
  });

  /// The controller whose complete value is replaced after a final result.
  final TextEditingController controller;

  /// The existing field limit that a final result must not exceed.
  final int? maxLength;

  /// Preserves any existing state updates normally triggered by typing.
  final ValueChanged<String>? onTextApplied;

  /// Optionally transforms a final transcript for a field-specific format.
  final SpeechTranscriptTransformer? transcriptTransformer;

  /// Optionally validates a transformed transcript before it is applied.
  final SpeechTranscriptValidator? replacementValidator;

  /// Selects the localized validation message for phone-number failures.
  final bool isPhoneNumber;

  /// Overrides the registered service in focused widget tests.
  final SpeechRecognitionService? speechRecognitionService;

  /// Overrides local persistence in focused widget tests.
  final PersistentMemoryService? persistentMemoryService;

  /// Feature flag controlling whether speech dictation UI is enabled.
  /// Set to `true` to show the action across its explicit form field callers.
  static bool isFeatureEnabled = true;

  /// Whether the current platform has an exposed dictation control.
  static bool get isSupportedPlatform =>
      isFeatureEnabled &&
      isSupportedPlatformFor(
        isWeb: kIsWeb,
        targetPlatform: defaultTargetPlatform,
      );

  /// Determines platform support from the supplied runtime characteristics.
  @visibleForTesting
  static bool isSupportedPlatformFor({
    required bool isWeb,
    required TargetPlatform targetPlatform,
  }) {
    if (isWeb) {
      return true;
    }
    return switch (targetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
  }

  @override
  State<SpeechDictationSuffixAction> createState() =>
      _SpeechDictationSuffixActionState();
}

class _SpeechDictationSuffixActionState
    extends State<SpeechDictationSuffixAction> {
  static const _disclosureAcceptedKey = 'speechDictationDisclosureAccepted';

  SpeechRecognitionService? _speechRecognitionService;
  PersistentMemoryService? _persistentMemoryService;
  int? _activeSessionId;
  String? _activeLocaleId;
  bool _isStarting = false;
  bool _awaitingSessionStart = false;
  bool _hasHandledFinalTranscript = false;
  final List<SpeechRecognitionSessionEvent> _pendingSessionEvents = [];

  @override
  void initState() {
    super.initState();
    final getIt = GetIt.instance;
    _speechRecognitionService =
        widget.speechRecognitionService ??
        (getIt.isRegistered<SpeechRecognitionService>()
            ? getIt<SpeechRecognitionService>()
            : null);
    _persistentMemoryService =
        widget.persistentMemoryService ??
        (getIt.isRegistered<PersistentMemoryService>()
            ? getIt<PersistentMemoryService>()
            : null);
  }

  @override
  void dispose() {
    if (_activeSessionId != null || _awaitingSessionStart) {
      final service = _speechRecognitionService;
      if (service != null) {
        unawaited(service.cancel());
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SpeechDictationSuffixAction.isSupportedPlatform ||
        _speechRecognitionService == null) {
      return const SizedBox.shrink();
    }

    final appLocale = AppLocalizations.of(context)!;
    if (_isStarting) {
      return const SizedBox(
        width: _micHitSize,
        height: _micHitSize,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_activeSessionId != null) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: appLocale.speechDictationListeningLabel,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('speech-dictation-stop'),
              tooltip: appLocale.speechDictationStopAndApplyAction,
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: _stopAndApply,
            ),
            IconButton(
              key: const Key('speech-dictation-discard'),
              tooltip: appLocale.speechDictationDiscardAction,
              icon: const Icon(Icons.cancel_outlined),
              onPressed: _discard,
            ),
          ],
        ),
      );
    }

    return IconButton(
      key: const Key('speech-dictation-start'),
      tooltip: appLocale.speechDictationAction,
      icon: const Icon(Icons.mic_none),
      onPressed: _startFromButton,
    );
  }

  void _startFromButton() {
    unawaited(_startAndHandleError());
  }

  Future<void> _startAndHandleError() async {
    try {
      await _start();
    } catch (error, stackTrace) {
      debugPrint('Unable to start speech dictation: $error\n$stackTrace');
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.speechDictationError);
      }
    }
  }

  Future<void> _start() => _runDictationStart(this);

  Future<void> _prepareAndStart(
    SpeechRecognitionService service,
    AppLocalizations appLocale,
  ) => _runDictationPrepare(this, service, appLocale);

  Future<void> _handleStartResult(
    SpeechRecognitionService service,
    SpeechRecognitionSessionStartResult startResult,
    AppLocalizations appLocale,
  ) => _runDictationStartResult(this, service, startResult, appLocale);

  Future<void> _cancelPendingStart(SpeechRecognitionService service) =>
      _runDictationCancelPending(this, service);

  Future<bool> _ensureDisclosure(AppLocalizations appLocale) =>
      _runDictationDisclosure(this, appLocale);

  Future<SpeechRecognitionLocale?> _chooseLocale(
    List<SpeechRecognitionLocale> locales,
    AppLocalizations appLocale,
  ) => _runDictationChooseLocale(this, locales, appLocale);

  void _handleSessionEvent(SpeechRecognitionSessionEvent event) =>
      _runDictationSessionEvent(this, event);

  void _applyFinalTranscript(String transcript) =>
      _runDictationApplyTranscript(this, transcript);

  Future<void> _stopAndApply() => _runDictationStopAndApply(this);

  Future<void> _discard() => _runDictationDiscard(this);

  Future<void> _cancelAndFinish() => _runDictationCancelAndFinish(this);

  void _finishSession() => _runDictationFinish(this);

  void _drainPendingSessionEvents(int sessionId) =>
      _runDictationDrainPending(this, sessionId);

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _set(VoidCallback fn) => setState(fn);
}
