part of 'suffix_action.dart';

Future<void> _runDictationStart(_SpeechDictationSuffixActionState state) async {
  final service = state._speechRecognitionService;
  final appLocale = AppLocalizations.of(state.context);
  if (service == null || appLocale == null) {
    return;
  }
  if (service.hasActiveSession) {
    state._showMessage(appLocale.speechDictationError);
    return;
  }

  state._set(() {
    state._isStarting = true;
  });
  try {
    await state._prepareAndStart(service, appLocale);
  } on PlatformException {
    await state._cancelPendingStart(service);
    if (state.mounted) {
      state._showMessage(appLocale.speechDictationError);
    }
  } on MissingPluginException {
    await state._cancelPendingStart(service);
    if (state.mounted) {
      state._showMessage(appLocale.speechDictationError);
    }
  } catch (error, stackTrace) {
    await state._cancelPendingStart(service);
    Error.throwWithStackTrace(error, stackTrace);
  } finally {
    if (state.mounted) {
      state._set(() {
        state._isStarting = false;
      });
    }
  }
}

Future<void> _runDictationPrepare(
  _SpeechDictationSuffixActionState state,
  SpeechRecognitionService service,
  AppLocalizations appLocale,
) async {
  if (!await state._ensureDisclosure(appLocale) || !state.mounted) return;
  final availability = await service.initialize();
  if (!state.mounted) return;
  if (availability != SpeechRecognitionAvailability.available) {
    state._showMessage(appLocale.speechDictationUnavailable);
    return;
  }

  final localeResult = await service.locales();
  if (!state.mounted) return;
  if (localeResult is! SpeechRecognitionLocalesAvailable ||
      localeResult.locales.isEmpty) {
    state._showMessage(appLocale.speechDictationUnavailable);
    return;
  }

  final locale = await state._chooseLocale(localeResult.locales, appLocale);
  if (!state.mounted || locale == null) return;
  state._activeLocaleId = locale.localeId;
  state._hasHandledFinalTranscript = false;
  state._awaitingSessionStart = true;
  final startResult = await service.start(
    localeId: locale.localeId,
    onEvent: state._handleSessionEvent,
  );
  state._awaitingSessionStart = false;
  await state._handleStartResult(service, startResult, appLocale);
}

Future<void> _runDictationStartResult(
  _SpeechDictationSuffixActionState state,
  SpeechRecognitionService service,
  SpeechRecognitionSessionStartResult startResult,
  AppLocalizations appLocale,
) async {
  if (!state.mounted) {
    state._pendingSessionEvents.clear();
    if (startResult is SpeechRecognitionSessionStarted) {
      await service.cancel();
    }
    return;
  }
  if (startResult is SpeechRecognitionSessionStarted) {
    state._set(() => state._activeSessionId = startResult.sessionId);
    state._drainPendingSessionEvents(startResult.sessionId);
    return;
  }

  state._pendingSessionEvents.clear();
  state._activeLocaleId = null;
  state._showMessage(
    startResult is SpeechRecognitionSessionStartFailure &&
            startResult.kind ==
                SpeechRecognitionSessionStartFailureKind.unavailable
        ? appLocale.speechDictationUnavailable
        : appLocale.speechDictationError,
  );
}

Future<void> _runDictationCancelPending(
  _SpeechDictationSuffixActionState state,
  SpeechRecognitionService service,
) async {
  if (!state._awaitingSessionStart) {
    return;
  }
  state._awaitingSessionStart = false;
  state._activeLocaleId = null;
  state._pendingSessionEvents.clear();

  // A failed cancellation remains fail-closed in the shared service until a
  // terminal recognizer signal arrives. The transient UI has no session id
  // to keep open after start itself failed.
  await service.cancel();
}

Future<bool> _runDictationDisclosure(
  _SpeechDictationSuffixActionState state,
  AppLocalizations appLocale,
) async {
  final persistentMemory = state._persistentMemoryService;
  if (persistentMemory == null) {
    return false;
  }
  final accepted = await persistentMemory.getItem(
    _SpeechDictationSuffixActionState._disclosureAcceptedKey,
    PersistentMemoryType.Bool,
  );
  if (accepted == true) {
    return true;
  }
  if (!state.mounted) {
    return false;
  }

  final confirmed = await showDialog<bool>(
    context: state.context,
    builder: (dialogContext) => AlertDialog(
      title: Text(appLocale.speechDictationDisclosureTitle),
      content: Text(appLocale.speechDictationDisclosureMessage),
      actions: [
        Button(
          key: const Key('speech-dictation-disclosure-decline'),
          label: appLocale.speechDictationDisclosureDecline,
          variant: ButtonVariant.secondary,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        Button(
          key: const Key('speech-dictation-disclosure-accept'),
          label: appLocale.speechDictationDisclosureAccept,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return false;
  }
  await persistentMemory.setItem(
    _SpeechDictationSuffixActionState._disclosureAcceptedKey,
    PersistentMemoryType.Bool,
    true,
  );
  return true;
}

Future<SpeechRecognitionLocale?> _runDictationChooseLocale(
  _SpeechDictationSuffixActionState state,
  List<SpeechRecognitionLocale> locales,
  AppLocalizations appLocale,
) {
  return showDialog<SpeechRecognitionLocale>(
    context: state.context,
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
