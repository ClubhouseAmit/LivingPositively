import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/speech_dictation_suffix_action.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/speech_recognition_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpeechDictationSuffixAction', () {
    testWidgets('should omit the dictation control on Linux', (tester) async {
      final originalPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await _pumpAction(
          tester,
          controller: _controllerWithText('Existing value'),
          service: _FakeSpeechRecognitionService(),
          memory: _FakePersistentMemoryService(),
        );

        expect(find.byKey(const Key('speech-dictation-start')), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = originalPlatform;
      }
    });

    testWidgets(
      'should leave the field unchanged when disclosure is declined',
      (tester) async {
        final controller = _controllerWithText('Existing value');
        final service = _FakeSpeechRecognitionService();
        final memory = _FakePersistentMemoryService();

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
        );

        await tester.tap(find.byKey(const Key('speech-dictation-start')));
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-disclosure-decline')),
        );

        expect(
          find.byKey(const Key('speech-dictation-disclosure-decline')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('speech-dictation-disclosure-decline')),
        );
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-start')),
        );

        expect(controller.text, 'Existing value');
        expect(memory.disclosureAccepted, isFalse);
        expect(service.initializeCalls, 0);
        expect(service.startCalls, 0);
        expect(find.byKey(const Key('speech-dictation-start')), findsOneWidget);
      },
    );

    testWidgets(
      'should preserve the field and show feedback when recognition is unavailable',
      (tester) async {
        final controller = _controllerWithText('Existing value');
        final service = _FakeSpeechRecognitionService(
          availability: SpeechRecognitionAvailability.unavailable,
        );
        final memory = _FakePersistentMemoryService(
          initialDisclosureAccepted: true,
        );

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
        );

        await tester.tap(find.byKey(const Key('speech-dictation-start')));
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-start')),
        );

        expect(controller.text, 'Existing value');
        expect(service.initializeCalls, 1);
        expect(service.localeCalls, 0);
        expect(service.startCalls, 0);
        expect(
          find.text('Voice dictation is unavailable on this device.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should apply a final transcript emitted synchronously as a session starts',
      (tester) async {
        final controller = _controllerWithText('Existing value');
        final service = _FakeSpeechRecognitionService(
          synchronousFinalTranscript: 'Final before start completes',
        );
        final memory = _FakePersistentMemoryService(
          initialDisclosureAccepted: true,
        );
        final appliedText = <String>[];

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
          onTextApplied: appliedText.add,
        );

        await tester.tap(find.byKey(const Key('speech-dictation-start')));
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-locale-en-US')),
        );
        await tester.tap(
          find.byKey(const Key('speech-dictation-locale-en-US')),
        );
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-start')),
        );

        expect(controller.text, 'Final before start completes');
        expect(appliedText, <String>['Final before start completes']);
        expect(find.byKey(const Key('speech-dictation-start')), findsOneWidget);
      },
    );

    testWidgets(
      'should persist disclosure acceptance and show installed languages',
      (tester) async {
        final controller = _controllerWithText('Existing value');
        final service = _FakeSpeechRecognitionService();
        final memory = _FakePersistentMemoryService();

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
        );

        await tester.tap(find.byKey(const Key('speech-dictation-start')));
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-disclosure-accept')),
        );
        await tester.tap(
          find.byKey(const Key('speech-dictation-disclosure-accept')),
        );
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-locale-he-IL')),
        );

        expect(memory.disclosureAccepted, isTrue);
        expect(service.initializeCalls, 1);
        expect(service.localeCalls, 1);
        expect(find.text('English (United States)'), findsOneWidget);
        expect(find.text('Hebrew (Israel)'), findsOneWidget);
        expect(
          find.byKey(const Key('speech-dictation-locale-he-IL')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('speech-dictation-locale-he-IL')),
        );
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-stop')),
        );

        expect(service.startedLocaleId, 'he-IL');
        expect(find.byKey(const Key('speech-dictation-stop')), findsOneWidget);
        expect(
          find.byKey(const Key('speech-dictation-discard')),
          findsOneWidget,
        );
      },
    );

    testWidgets('should expose an active dictation accessibility label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final controller = _controllerWithText('Existing value');
        final service = _FakeSpeechRecognitionService();
        final memory = _FakePersistentMemoryService(
          initialDisclosureAccepted: true,
        );

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
        );
        await _startSession(tester, localeId: 'en-US');

        expect(find.bySemanticsLabel('Listening…'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'should replace the whole field with a final transcript and invoke the callback',
      (tester) async {
        final controller = TextEditingController.fromValue(
          const TextEditingValue(
            text: 'Existing value',
            selection: TextSelection(baseOffset: 2, extentOffset: 7),
          ),
        );
        addTearDown(controller.dispose);
        final service = _FakeSpeechRecognitionService();
        final memory = _FakePersistentMemoryService(
          initialDisclosureAccepted: true,
        );
        final appliedText = <String>[];

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
          onTextApplied: appliedText.add,
        );
        await _startSession(tester, localeId: 'en-US');

        service.emitTranscript('A complete replacement', isFinal: true);
        await tester.pump();

        expect(controller.text, 'A complete replacement');
        expect(
          controller.selection,
          const TextSelection.collapsed(
            offset: 'A complete replacement'.length,
          ),
        );
        expect(appliedText, <String>['A complete replacement']);
      },
    );

    testWidgets('should preserve the existing field value when discarded', (
      tester,
    ) async {
      final controller = _controllerWithText('Keep this value');
      final service = _FakeSpeechRecognitionService();
      final memory = _FakePersistentMemoryService(
        initialDisclosureAccepted: true,
      );
      final appliedText = <String>[];

      await _pumpAction(
        tester,
        controller: controller,
        service: service,
        memory: memory,
        onTextApplied: appliedText.add,
      );
      await _startSession(tester, localeId: 'en-US');

      service.emitTranscript('Partial text', isFinal: false);
      await tester.pump();
      await tester.tap(find.byKey(const Key('speech-dictation-discard')));
      await _pumpUntilVisible(
        tester,
        find.byKey(const Key('speech-dictation-start')),
      );

      expect(controller.text, 'Keep this value');
      expect(appliedText, isEmpty);
      expect(service.cancelCalls, 1);
      expect(find.byKey(const Key('speech-dictation-start')), findsOneWidget);
    });

    testWidgets(
      'should preserve the existing field value when a final transcript is too long',
      (tester) async {
        final controller = _controllerWithText('Short');
        final service = _FakeSpeechRecognitionService();
        final memory = _FakePersistentMemoryService(
          initialDisclosureAccepted: true,
        );
        final appliedText = <String>[];

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
          maxLength: 5,
          onTextApplied: appliedText.add,
        );
        await _startSession(tester, localeId: 'en-US');

        service.emitTranscript('Too long', isFinal: true);
        await tester.pump();

        expect(controller.text, 'Short');
        expect(appliedText, isEmpty);
        expect(
          find.text('The dictated text is too long for this field.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should accept one composed emoji when the maximum length is one grapheme',
      (tester) async {
        const emoji = '👩‍💻';
        final controller = _controllerWithText('Previous value');
        final service = _FakeSpeechRecognitionService();
        final memory = _FakePersistentMemoryService(
          initialDisclosureAccepted: true,
        );
        final appliedText = <String>[];

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
          maxLength: 1,
          onTextApplied: appliedText.add,
        );
        await _startSession(tester, localeId: 'en-US');

        service.emitTranscript(emoji, isFinal: true);
        await tester.pump();

        expect(controller.text, emoji);
        expect(appliedText, <String>[emoji]);
      },
    );

    testWidgets(
      'should preserve the existing field value when a replacement is invalid',
      (tester) async {
        final controller = _controllerWithText('Previous number');
        final service = _FakeSpeechRecognitionService();
        final memory = _FakePersistentMemoryService(
          initialDisclosureAccepted: true,
        );
        final appliedText = <String>[];

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
          isPhoneNumber: true,
          replacementValidator: (_) => false,
          onTextApplied: appliedText.add,
        );
        await _startSession(tester, localeId: 'en-US');

        service.emitTranscript('+1 555 0100', isFinal: true);
        await tester.pump();

        expect(controller.text, 'Previous number');
        expect(appliedText, isEmpty);
        expect(
          find.text(
            'The dictated phone number is not valid for the selected country.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}

TextEditingController _controllerWithText(String text) {
  final controller = TextEditingController(text: text);
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _pumpAction(
  WidgetTester tester, {
  required TextEditingController controller,
  required SpeechRecognitionService service,
  required PersistentMemoryService memory,
  int? maxLength,
  ValueChanged<String>? onTextApplied,
  SpeechTranscriptValidator? replacementValidator,
  bool isPhoneNumber = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SpeechDictationSuffixAction(
            controller: controller,
            maxLength: maxLength,
            onTextApplied: onTextApplied,
            replacementValidator: replacementValidator,
            isPhoneNumber: isPhoneNumber,
            speechRecognitionService: service,
            persistentMemoryService: memory,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _startSession(
  WidgetTester tester, {
  required String localeId,
}) async {
  await tester.tap(find.byKey(const Key('speech-dictation-start')));
  await _pumpUntilVisible(
    tester,
    find.byKey(Key('speech-dictation-locale-$localeId')),
  );
  await tester.tap(find.byKey(Key('speech-dictation-locale-$localeId')));
  await _pumpUntilVisible(
    tester,
    find.byKey(const Key('speech-dictation-stop')),
  );
}

Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

final class _FakePersistentMemoryService implements PersistentMemoryService {
  _FakePersistentMemoryService({bool initialDisclosureAccepted = false})
    : _disclosureAccepted = initialDisclosureAccepted;

  bool _disclosureAccepted;

  bool get disclosureAccepted => _disclosureAccepted;

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    return switch (type) {
      PersistentMemoryType.Bool => _disclosureAccepted,
      PersistentMemoryType.String => '',
      PersistentMemoryType.Int => 0,
      PersistentMemoryType.Double => 0.0,
      PersistentMemoryType.StringList => <String>[],
    };
  }

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (type == PersistentMemoryType.Bool && value is bool) {
      _disclosureAccepted = value;
    }
  }

  @override
  Future<void> reset() async {
    _disclosureAccepted = false;
  }
}

final class _FakeSpeechRecognitionService implements SpeechRecognitionService {
  _FakeSpeechRecognitionService({
    this.availability = SpeechRecognitionAvailability.available,
    this.synchronousFinalTranscript,
  });

  final SpeechRecognitionAvailability availability;
  final String? synchronousFinalTranscript;
  List<SpeechRecognitionLocale> availableLocales =
      const <SpeechRecognitionLocale>[
        SpeechRecognitionLocale(
          localeId: 'en-US',
          name: 'English (United States)',
        ),
        SpeechRecognitionLocale(localeId: 'he-IL', name: 'Hebrew (Israel)'),
      ];
  int initializeCalls = 0;
  int localeCalls = 0;
  int startCalls = 0;
  int cancelCalls = 0;
  String? startedLocaleId;
  int? _activeSessionId;
  SpeechRecognitionEventCallback? _onEvent;

  @override
  bool get hasActiveSession => _activeSessionId != null;

  @override
  Future<SpeechRecognitionAvailability> initialize() async {
    initializeCalls++;
    return availability;
  }

  @override
  Future<SpeechRecognitionLocalesResult> locales() async {
    localeCalls++;
    return SpeechRecognitionLocalesAvailable(availableLocales);
  }

  @override
  Future<SpeechRecognitionSessionStartResult> start({
    required String localeId,
    required SpeechRecognitionEventCallback onEvent,
  }) async {
    startCalls++;
    if (hasActiveSession) {
      return const SpeechRecognitionSessionStartFailure(
        SpeechRecognitionSessionStartFailureKind.alreadyActive,
      );
    }

    startedLocaleId = localeId;
    _onEvent = onEvent;
    _activeSessionId = 1;
    final transcript = synchronousFinalTranscript;
    if (transcript != null) {
      onEvent(
        SpeechRecognitionTranscriptEvent(
          sessionId: _activeSessionId!,
          text: transcript,
          isFinal: true,
        ),
      );
      _activeSessionId = null;
      onEvent(
        const SpeechRecognitionStatusEvent(
          sessionId: 1,
          status: SpeechRecognitionSessionStatus.completed,
        ),
      );
    }
    return const SpeechRecognitionSessionStarted(1);
  }

  @override
  Future<SpeechRecognitionSessionControlResult> stop() async {
    return hasActiveSession
        ? SpeechRecognitionSessionControlResult.stopped
        : SpeechRecognitionSessionControlResult.noActiveSession;
  }

  @override
  Future<SpeechRecognitionSessionControlResult> cancel() async {
    if (!hasActiveSession) {
      return SpeechRecognitionSessionControlResult.noActiveSession;
    }
    cancelCalls++;
    _activeSessionId = null;
    _onEvent = null;
    return SpeechRecognitionSessionControlResult.cancelled;
  }

  void emitTranscript(String text, {required bool isFinal}) {
    final sessionId = _activeSessionId;
    final onEvent = _onEvent;
    if (sessionId == null || onEvent == null) {
      return;
    }
    onEvent(
      SpeechRecognitionTranscriptEvent(
        sessionId: sessionId,
        text: text,
        isFinal: isFinal,
      ),
    );
    if (isFinal) {
      _activeSessionId = null;
      onEvent(
        SpeechRecognitionStatusEvent(
          sessionId: sessionId,
          status: SpeechRecognitionSessionStatus.completed,
        ),
      );
    }
  }
}
