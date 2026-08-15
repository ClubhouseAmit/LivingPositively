import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/speech_recognition_service.dart';

/// Converts a final transcript before it replaces an input value.
typedef SpeechTranscriptTransformer =
    String? Function(String transcript, String localeId);

/// Validates a transformed transcript before it replaces an input value.
typedef SpeechTranscriptValidator = bool Function(String transcript);

/// A text-field suffix action that provides short, explicit dictation.
///
/// The action owns only the transient recognition UI. Existing forms retain
/// ownership of their controllers, validation, and persistence callbacks.
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

  /// Whether the current platform has an exposed dictation control.
  static bool get isSupportedPlatform => isSupportedPlatformFor(
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
        width: 48,
        height: 48,
        child: Padding(
          padding: EdgeInsets.all(12),
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
      onPressed: _start,
    );
  }

  Future<void> _start() async {
    final service = _speechRecognitionService;
    final appLocale = AppLocalizations.of(context);
    if (service == null || appLocale == null) {
      return;
    }
    if (service.hasActiveSession) {
      _showMessage(appLocale.speechDictationError);
      return;
    }

    setState(() {
      _isStarting = true;
    });
    try {
      if (!await _ensureDisclosure(appLocale)) {
        return;
      }
      if (!mounted) {
        return;
      }
      final availability = await service.initialize();
      if (!mounted) {
        return;
      }
      if (availability != SpeechRecognitionAvailability.available) {
        _showMessage(appLocale.speechDictationUnavailable);
        return;
      }

      final localeResult = await service.locales();
      if (!mounted) {
        return;
      }
      if (localeResult is! SpeechRecognitionLocalesAvailable ||
          localeResult.locales.isEmpty) {
        _showMessage(appLocale.speechDictationUnavailable);
        return;
      }

      final locale = await _chooseLocale(localeResult.locales, appLocale);
      if (!mounted || locale == null) {
        return;
      }
      _activeLocaleId = locale.localeId;
      _hasHandledFinalTranscript = false;
      _awaitingSessionStart = true;
      final startResult = await service.start(
        localeId: locale.localeId,
        onEvent: _handleSessionEvent,
      );
      _awaitingSessionStart = false;
      if (!mounted) {
        _pendingSessionEvents.clear();
        if (startResult is SpeechRecognitionSessionStarted) {
          await service.cancel();
        }
        return;
      }
      if (startResult is SpeechRecognitionSessionStarted) {
        setState(() {
          _activeSessionId = startResult.sessionId;
        });
        _drainPendingSessionEvents(startResult.sessionId);
        return;
      }

      _pendingSessionEvents.clear();
      _activeLocaleId = null;
      _showMessage(
        startResult is SpeechRecognitionSessionStartFailure &&
                startResult.kind ==
                    SpeechRecognitionSessionStartFailureKind.unavailable
            ? appLocale.speechDictationUnavailable
            : appLocale.speechDictationError,
      );
    } on PlatformException {
      await _cancelPendingStart(service);
      if (mounted) {
        _showMessage(appLocale.speechDictationError);
      }
    } on MissingPluginException {
      await _cancelPendingStart(service);
      if (mounted) {
        _showMessage(appLocale.speechDictationError);
      }
    } catch (error, stackTrace) {
      await _cancelPendingStart(service);
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _cancelPendingStart(SpeechRecognitionService service) async {
    if (!_awaitingSessionStart) {
      return;
    }
    _awaitingSessionStart = false;
    _activeLocaleId = null;
    _pendingSessionEvents.clear();

    // A failed cancellation remains fail-closed in the shared service until a
    // terminal recognizer signal arrives. The transient UI has no session id
    // to keep open after start itself failed.
    await service.cancel();
  }

  Future<bool> _ensureDisclosure(AppLocalizations appLocale) async {
    final persistentMemory = _persistentMemoryService;
    if (persistentMemory == null) {
      return false;
    }
    final accepted = await persistentMemory.getItem(
      _disclosureAcceptedKey,
      PersistentMemoryType.Bool,
    );
    if (accepted == true) {
      return true;
    }
    if (!mounted) {
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appLocale.speechDictationDisclosureTitle),
        content: Text(appLocale.speechDictationDisclosureMessage),
        actions: [
          TextButton(
            key: const Key('speech-dictation-disclosure-decline'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(appLocale.speechDictationDisclosureDecline),
          ),
          TextButton(
            key: const Key('speech-dictation-disclosure-accept'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(appLocale.speechDictationDisclosureAccept),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return false;
    }
    await persistentMemory.setItem(
      _disclosureAcceptedKey,
      PersistentMemoryType.Bool,
      true,
    );
    return true;
  }

  Future<SpeechRecognitionLocale?> _chooseLocale(
    List<SpeechRecognitionLocale> locales,
    AppLocalizations appLocale,
  ) {
    return showDialog<SpeechRecognitionLocale>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(appLocale.speechDictationLanguagePickerTitle),
        children: [
          for (final locale in locales)
            SimpleDialogOption(
              key: Key('speech-dictation-locale-${locale.localeId}'),
              onPressed: () => Navigator.of(dialogContext).pop(locale),
              child: Text(locale.name),
            ),
        ],
      ),
    );
  }

  void _handleSessionEvent(SpeechRecognitionSessionEvent event) {
    if (!mounted) {
      return;
    }
    final activeSessionId = _activeSessionId;
    if (activeSessionId == null) {
      if (_awaitingSessionStart) {
        _pendingSessionEvents.add(event);
      }
      return;
    }
    if (event.sessionId != activeSessionId) {
      return;
    }
    if (event is SpeechRecognitionTranscriptEvent && event.isFinal) {
      _applyFinalTranscript(event.text);
      return;
    }
    if (event is SpeechRecognitionErrorEvent) {
      _showMessage(AppLocalizations.of(context)!.speechDictationError);
      _finishSession();
      return;
    }
    if (event is SpeechRecognitionStatusEvent &&
        event.status == SpeechRecognitionSessionStatus.completed) {
      _finishSession();
    }
  }

  void _applyFinalTranscript(String transcript) {
    if (_hasHandledFinalTranscript) {
      return;
    }
    _hasHandledFinalTranscript = true;
    final appLocale = AppLocalizations.of(context)!;
    final localeId = _activeLocaleId;
    final transformed = localeId == null
        ? null
        : widget.transcriptTransformer == null
        ? transcript
        : widget.transcriptTransformer!(transcript, localeId);
    if (transformed == null) {
      _showMessage(
        widget.isPhoneNumber
            ? appLocale.speechDictationPhoneInvalid
            : appLocale.speechDictationError,
      );
      return;
    }
    if (transformed.trim().isEmpty) {
      _showMessage(appLocale.speechDictationError);
      return;
    }
    if (widget.maxLength != null &&
        transformed.characters.length > widget.maxLength!) {
      _showMessage(appLocale.speechDictationTooLong);
      return;
    }
    if (widget.replacementValidator?.call(transformed) == false) {
      _showMessage(
        widget.isPhoneNumber
            ? appLocale.speechDictationPhoneInvalid
            : appLocale.speechDictationError,
      );
      return;
    }

    widget.controller.value = TextEditingValue(
      text: transformed,
      selection: TextSelection.collapsed(offset: transformed.length),
    );
    widget.onTextApplied?.call(transformed);
  }

  Future<void> _stopAndApply() async {
    final service = _speechRecognitionService;
    if (service == null) {
      return;
    }
    var shouldFinish = false;
    try {
      final result = await service.stop();
      shouldFinish = result != SpeechRecognitionSessionControlResult.stopped;
      if (result == SpeechRecognitionSessionControlResult.failed && mounted) {
        _showMessage(AppLocalizations.of(context)!.speechDictationError);
      }
    } catch (_) {
      shouldFinish = true;
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.speechDictationError);
      }
    }
    if (!mounted || !shouldFinish) {
      return;
    }
    await _cancelAndFinish();
  }

  Future<void> _discard() async {
    await _cancelAndFinish();
  }

  Future<void> _cancelAndFinish() async {
    final service = _speechRecognitionService;
    try {
      final result = service == null
          ? SpeechRecognitionSessionControlResult.noActiveSession
          : await service.cancel();
      if (!mounted) {
        return;
      }
      if (result == SpeechRecognitionSessionControlResult.failed) {
        _showMessage(AppLocalizations.of(context)!.speechDictationError);
        return;
      }
    } catch (_) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context)!.speechDictationError);
      }
      return;
    }
    if (mounted) {
      _finishSession();
    }
  }

  void _finishSession() {
    if (!mounted) {
      return;
    }
    _pendingSessionEvents.clear();
    setState(() {
      _activeSessionId = null;
      _activeLocaleId = null;
      _isStarting = false;
      _awaitingSessionStart = false;
    });
  }

  void _drainPendingSessionEvents(int sessionId) {
    final pendingEvents = List<SpeechRecognitionSessionEvent>.of(
      _pendingSessionEvents,
    );
    _pendingSessionEvents.clear();
    for (final event in pendingEvents) {
      if (event.sessionId == sessionId) {
        _handleSessionEvent(event);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }
}
