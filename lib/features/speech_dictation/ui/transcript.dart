part of 'suffix_action.dart';

void _runDictationSessionEvent(
  _SpeechDictationSuffixActionState state,
  SpeechRecognitionSessionEvent event,
) {
  if (!state.mounted) {
    return;
  }
  final activeSessionId = state._activeSessionId;
  if (activeSessionId == null) {
    if (state._awaitingSessionStart) {
      state._pendingSessionEvents.add(event);
    }
    return;
  }
  if (event.sessionId != activeSessionId) {
    return;
  }
  if (event is SpeechRecognitionTranscriptEvent && event.isFinal) {
    state._applyFinalTranscript(event.text);
    return;
  }
  if (event is SpeechRecognitionErrorEvent) {
    state._showMessage(
      AppLocalizations.of(state.context)!.speechDictationError,
    );
    state._finishSession();
    return;
  }
  if (event is SpeechRecognitionStatusEvent &&
      event.status == SpeechRecognitionSessionStatus.completed) {
    state._finishSession();
  }
}

void _runDictationApplyTranscript(
  _SpeechDictationSuffixActionState state,
  String transcript,
) {
  if (state._hasHandledFinalTranscript) {
    return;
  }
  state._hasHandledFinalTranscript = true;
  final appLocale = AppLocalizations.of(state.context)!;
  final localeId = state._activeLocaleId;
  final transformed = localeId == null
      ? null
      : state.widget.transcriptTransformer == null
      ? transcript
      : state.widget.transcriptTransformer!(transcript, localeId);
  if (transformed == null) {
    state._showMessage(
      state.widget.isPhoneNumber
          ? appLocale.speechDictationPhoneInvalid
          : appLocale.speechDictationError,
    );
    return;
  }
  if (transformed.trim().isEmpty) {
    state._showMessage(appLocale.speechDictationError);
    return;
  }
  if (state.widget.maxLength != null &&
      transformed.characters.length > state.widget.maxLength!) {
    state._showMessage(appLocale.speechDictationTooLong);
    return;
  }
  if (state.widget.replacementValidator?.call(transformed) == false) {
    state._showMessage(
      state.widget.isPhoneNumber
          ? appLocale.speechDictationPhoneInvalid
          : appLocale.speechDictationError,
    );
    return;
  }

  state.widget.controller.value = TextEditingValue(
    text: transformed,
    selection: TextSelection.collapsed(offset: transformed.length),
  );
  state.widget.onTextApplied?.call(transformed);
}

Future<void> _runDictationStopAndApply(
  _SpeechDictationSuffixActionState state,
) async {
  final service = state._speechRecognitionService;
  if (service == null) {
    return;
  }
  var shouldFinish = false;
  try {
    final result = await service.stop();
    shouldFinish = result != SpeechRecognitionSessionControlResult.stopped;
    if (result == SpeechRecognitionSessionControlResult.failed &&
        state.mounted) {
      state._showMessage(
        AppLocalizations.of(state.context)!.speechDictationError,
      );
    }
  } catch (_) {
    shouldFinish = true;
    if (state.mounted) {
      state._showMessage(
        AppLocalizations.of(state.context)!.speechDictationError,
      );
    }
  }
  if (!state.mounted || !shouldFinish) {
    return;
  }
  await state._cancelAndFinish();
}

Future<void> _runDictationDiscard(_SpeechDictationSuffixActionState state) {
  return state._cancelAndFinish();
}

Future<void> _runDictationCancelAndFinish(
  _SpeechDictationSuffixActionState state,
) async {
  final service = state._speechRecognitionService;
  final sessionId = state._activeSessionId;
  try {
    final result = service == null
        ? SpeechRecognitionSessionControlResult.noActiveSession
        : await service.cancel();
    if (!state.mounted || state._activeSessionId != sessionId) {
      return;
    }
    if (result == SpeechRecognitionSessionControlResult.failed) {
      state._showMessage(
        AppLocalizations.of(state.context)!.speechDictationError,
      );
      return;
    }
  } catch (_) {
    if (state.mounted && state._activeSessionId == sessionId) {
      state._showMessage(
        AppLocalizations.of(state.context)!.speechDictationError,
      );
    }
    return;
  }
  if (state.mounted && state._activeSessionId == sessionId) {
    state._finishSession();
  }
}

void _runDictationFinish(_SpeechDictationSuffixActionState state) {
  if (!state.mounted) {
    return;
  }
  state._pendingSessionEvents.clear();
  state._set(() {
    state._activeSessionId = null;
    state._activeLocaleId = null;
    state._isStarting = false;
    state._awaitingSessionStart = false;
  });
}

void _runDictationDrainPending(
  _SpeechDictationSuffixActionState state,
  int sessionId,
) {
  final pendingEvents = List<SpeechRecognitionSessionEvent>.of(
    state._pendingSessionEvents,
  );
  state._pendingSessionEvents.clear();
  for (final event in pendingEvents) {
    if (event.sessionId == sessionId) {
      state._handleSessionEvent(event);
    }
  }
}
