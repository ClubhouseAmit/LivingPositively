import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/speech_dictation_suffix_action.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/speech_recognition_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('should default isFeatureEnabled to false in production', () {
    expect(SpeechDictationSuffixAction.isFeatureEnabled, isFalse);
    expect(SpeechDictationSuffixAction.isSupportedPlatform, isFalse);
  });

  group('SpeechDictationSuffixAction', () {
    late bool originalFeatureFlag;

    setUp(() {
      originalFeatureFlag = SpeechDictationSuffixAction.isFeatureEnabled;
      SpeechDictationSuffixAction.isFeatureEnabled = true;
    });

    tearDown(() {
      SpeechDictationSuffixAction.isFeatureEnabled = originalFeatureFlag;
    });

    test('should report false when feature flag is disabled', () {
      SpeechDictationSuffixAction.isFeatureEnabled = false;
      expect(SpeechDictationSuffixAction.isSupportedPlatform, isFalse);
    });

    test('should report the supported web and native platform matrix', () {
      expect(
        SpeechDictationSuffixAction.isSupportedPlatformFor(
          isWeb: true,
          targetPlatform: TargetPlatform.linux,
        ),
        isTrue,
      );
      for (final platform in <TargetPlatform>[
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      ]) {
        expect(
          SpeechDictationSuffixAction.isSupportedPlatformFor(
            isWeb: false,
            targetPlatform: platform,
          ),
          isTrue,
          reason: '$platform should support dictation.',
        );
      }
      for (final platform in <TargetPlatform>[
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          SpeechDictationSuffixAction.isSupportedPlatformFor(
            isWeb: false,
            targetPlatform: platform,
          ),
          isFalse,
          reason: '$platform should not support dictation.',
        );
      }
    });

    testWidgets(
      'should render the dictation control only on supported native platforms',
      (tester) async {
        final originalPlatform = debugDefaultTargetPlatformOverride;
        try {
          final expectedSupport = <TargetPlatform, bool>{
            TargetPlatform.android: true,
            TargetPlatform.iOS: true,
            TargetPlatform.macOS: true,
            TargetPlatform.windows: true,
            TargetPlatform.linux: false,
            TargetPlatform.fuchsia: false,
          };
          for (final entry in expectedSupport.entries) {
            debugDefaultTargetPlatformOverride = entry.key;
            await _pumpAction(
              tester,
              controller: _controllerWithText('Existing value'),
              service: _FakeSpeechRecognitionService(),
              memory: _FakePersistentMemoryService(),
            );

            expect(
              find.byKey(const Key('speech-dictation-start')),
              entry.value ? findsOneWidget : findsNothing,
              reason:
                  '${entry.key} should ${entry.value ? '' : 'not '}show dictation.',
            );
          }
        } finally {
          debugDefaultTargetPlatformOverride = originalPlatform;
          await tester.pump();
        }
      },
    );

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
        expect(memory.getItemCalls, 1);
        expect(memory.setItemCalls, 0);
        expect(service.initializeCalls, 0);
        expect(service.startCalls, 0);
        expect(find.byKey(const Key('speech-dictation-start')), findsOneWidget);
      },
    );

    testWidgets(
      'should disclose recognition processing and app privacy boundaries in each language',
      (tester) async {
        final disclosures = <Locale, String>{
          const Locale(
            'en',
          ): 'Your device or browser may send speech to a speech-recognition service for processing. This app does not store audio or send dictated text to analytics. Recognition providers’ policies may apply. You can review and edit the text before saving.',
          const Locale(
            'he',
          ): 'המכשיר או הדפדפן שלך עשויים לשלוח את הדיבור לשירות זיהוי דיבור לצורך עיבוד. אפליקציה זו אינה שומרת אודיו ואינה שולחת טקסט מוכתב לניתוח נתונים. ייתכן שמדיניות ספקי שירותי הזיהוי חלה. אפשר לעבור על הטקסט ולערוך אותו לפני השמירה.',
          const Locale(
            'ar',
          ): 'قد يرسل جهازك أو متصفحك الكلام إلى خدمة للتعرّف على الكلام من أجل معالجته. لا يخزن هذا التطبيق الصوت ولا يرسل النص المملى إلى التحليلات. قد تنطبق سياسات موفري خدمة التعرّف. يمكنك مراجعة النص وتعديله قبل الحفظ.',
        };

        for (final entry in disclosures.entries) {
          await _pumpAction(
            tester,
            controller: _controllerWithText('Existing value'),
            service: _FakeSpeechRecognitionService(),
            memory: _FakePersistentMemoryService(),
            locale: entry.key,
          );

          await tester.tap(find.byKey(const Key('speech-dictation-start')));
          await _pumpUntilVisible(
            tester,
            find.byKey(const Key('speech-dictation-disclosure-decline')),
          );

          expect(find.text(entry.value), findsOneWidget);
          await tester.tap(
            find.byKey(const Key('speech-dictation-disclosure-decline')),
          );
          await _pumpUntilVisible(
            tester,
            find.byKey(const Key('speech-dictation-start')),
          );
        }
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
      'should cancel a pending start after an expected platform failure',
      (tester) async {
        final controller = _controllerWithText('Existing value');
        final cancellation = Completer<void>();
        final service = _FakeSpeechRecognitionService()
          ..startError = PlatformException(code: 'start-failed')
          ..startErrorStartsSession = true
          ..cancelCompleter = cancellation;
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
          find.byKey(const Key('speech-dictation-locale-en-US')),
        );
        await tester.tap(
          find.byKey(const Key('speech-dictation-locale-en-US')),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byKey(const Key('speech-dictation-start')), findsNothing);
        expect(service.cancelCalls, 1);
        expect(service.hasActiveSession, isTrue);
        expect(
          find.text(
            'Voice dictation could not be completed. Please try again.',
          ),
          findsNothing,
        );

        cancellation.complete();
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-start')),
        );

        expect(controller.text, 'Existing value');
        expect(service.cancelCalls, 1);
        expect(service.hasActiveSession, isFalse);
        expect(
          find.text(
            'Voice dictation could not be completed. Please try again.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should surface unexpected start failures after pending cleanup',
      (tester) async {
        final controller = _controllerWithText('Existing value');
        final service = _FakeSpeechRecognitionService()
          ..startError = StateError('unexpected start failure')
          ..startErrorStartsSession = true;
        final memory = _FakePersistentMemoryService(
          initialDisclosureAccepted: true,
        );

        await _pumpAction(
          tester,
          controller: controller,
          service: service,
          memory: memory,
        );

        final dynamic startCallback = tester
            .widget<IconButton>(find.byKey(const Key('speech-dictation-start')))
            .onPressed;
        final operation = startCallback() as Future<void>;
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-locale-en-US')),
        );
        final localeCallback = tester
            .widget<SimpleDialogOption>(
              find.byKey(const Key('speech-dictation-locale-en-US')),
            )
            .onPressed!;
        final expectation = expectLater(operation, throwsA(isA<StateError>()));
        localeCallback();
        await tester.pump();

        await expectation;
        expect(controller.text, 'Existing value');
        expect(service.cancelCalls, 1);
        expect(service.hasActiveSession, isFalse);
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
        expect(memory.getItemCalls, 1);
        expect(memory.setItemCalls, 1);
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
      'should clear dictation controls when a failed cancellation later terminates',
      (tester) async {
        final controller = _controllerWithText('Keep this value');
        final service = _FakeSpeechRecognitionService()
          ..cancelResult = SpeechRecognitionSessionControlResult.failed;
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

        await tester.tap(find.byKey(const Key('speech-dictation-discard')));
        await tester.pump();

        expect(find.byKey(const Key('speech-dictation-stop')), findsOneWidget);
        expect(service.hasActiveSession, isTrue);
        expect(
          find.text(
            'Voice dictation could not be completed. Please try again.',
          ),
          findsOneWidget,
        );

        service.emitCompleted();
        await _pumpUntilVisible(
          tester,
          find.byKey(const Key('speech-dictation-start')),
        );

        expect(controller.text, 'Keep this value');
        expect(service.hasActiveSession, isFalse);
        await _startSession(tester, localeId: 'en-US');
        expect(find.byKey(const Key('speech-dictation-stop')), findsOneWidget);
      },
    );

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
      'should preserve the existing field value when a final transcript is blank',
      (tester) async {
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

        service.emitTranscript('   ', isFinal: true);
        await tester.pump();

        expect(controller.text, 'Keep this value');
        expect(appliedText, isEmpty);
        expect(
          find.text(
            'Voice dictation could not be completed. Please try again.',
          ),
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
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
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
  static const _disclosureAcceptedKey = 'speechDictationDisclosureAccepted';

  _FakePersistentMemoryService({bool initialDisclosureAccepted = false})
    : _disclosureAccepted = initialDisclosureAccepted;

  bool _disclosureAccepted;
  int getItemCalls = 0;
  int setItemCalls = 0;

  bool get disclosureAccepted => _disclosureAccepted;

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    _verifyDisclosureEntry(key, type);
    getItemCalls++;
    return _disclosureAccepted;
  }

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    _verifyDisclosureEntry(key, type);
    if (value is! bool) {
      throw StateError('The disclosure acknowledgement must be a bool.');
    }
    setItemCalls++;
    _disclosureAccepted = value;
  }

  @override
  Future<void> reset() async {
    _disclosureAccepted = false;
  }

  void _verifyDisclosureEntry(String key, PersistentMemoryType type) {
    if (key != _disclosureAcceptedKey || type != PersistentMemoryType.Bool) {
      throw StateError('Unexpected persistent-memory disclosure entry.');
    }
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
  Object? startError;
  bool startErrorStartsSession = false;
  Completer<void>? cancelCompleter;
  SpeechRecognitionSessionControlResult cancelResult =
      SpeechRecognitionSessionControlResult.cancelled;
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

    final error = startError;
    if (error != null) {
      if (startErrorStartsSession) {
        startedLocaleId = localeId;
        _onEvent = onEvent;
        _activeSessionId = 1;
      }
      throw error;
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
    final completer = cancelCompleter;
    if (completer != null) {
      await completer.future;
    }
    if (cancelResult == SpeechRecognitionSessionControlResult.failed) {
      return cancelResult;
    }
    _activeSessionId = null;
    _onEvent = null;
    return cancelResult;
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
      emitCompleted();
    }
  }

  void emitCompleted() {
    final sessionId = _activeSessionId;
    final onEvent = _onEvent;
    if (sessionId == null || onEvent == null) {
      return;
    }
    _activeSessionId = null;
    onEvent(
      SpeechRecognitionStatusEvent(
        sessionId: sessionId,
        status: SpeechRecognitionSessionStatus.completed,
      ),
    );
  }
}
