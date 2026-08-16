// Layout guard for the settings screen.
//
// The screen's spacing was tightened specifically so the whole form fits a
// standard phone screen without scrolling. That is a property of the sum of
// a dozen gaps and heights, so any one of them creeping back up breaks it
// silently — this test fails loudly instead.
//
// Note the window is sized via `tester.view` rather than `setSurfaceSize`:
// ScreenUtil reads the raw view metrics, and `setSurfaceSize` leaves it
// measuring the default 800px test window, which doubles every `.sp` and
// makes the measurements meaningless.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/UserSettings.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/speech_recognition_service.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart';

/// iPhone 14/15 logical size — the "standard iPhone screen" the spacing
/// budget targets.
const Size _kPhone = Size(393, 852);

PhonePageData _phone() => PhonePageData(
  key: 'phonePageData',
  header: 'header',
  subTitle: 'subTitle',
  midTitle: 'midTitle',
  phoneNameTitle: 'phoneNameTitle',
  phoneNumberTitle: 'phoneNumberTitle',
  phoneNames: const [],
  phoneNumbers: const [],
  savedPhoneNames: const [],
  savedPhoneNumbers: const [],
  phoneDescription: const [],
);

void main() {
  late TestServiceLocators services;

  setUpAll(loadTestFonts);

  setUp(() {
    services = registerTestServices();
  });

  tearDown(resetTestServices);

  Future<void> pumpSettings(WidgetTester tester, String locale) async {
    services.memory.store.clear();
    final user = UserInformation()
      ..localeName = locale
      ..gender = 'female'
      ..location = 'IL';

    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = _kPhone;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserInformation>.value(value: user),
          ChangeNotifierProvider<AppInformation>.value(value: AppInformation()),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ScreenUtilInit(
            designSize: _kPhone,
            child: Builder(
              builder: (context) => UserSettings(
                username: 'Ariel',
                age: '18-30',
                gender: 'female',
                phonePageData: _phone(),
                changeLocale: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in ['en', 'he']) {
    testWidgets('every field fits on one phone screen ($locale)', (
      tester,
    ) async {
      await pumpSettings(tester, locale);

      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(
        position.maxScrollExtent,
        0,
        reason:
            'The settings form is meant to fit a $_kPhone screen without '
            'scrolling; it overflows by ${position.maxScrollExtent}px.',
      );
    });

    testWidgets(
      'layout fits without scrolling when scheduled dark mode is active ($locale)',
      (tester) async {
        await pumpSettings(tester, locale);

        await tester.tap(find.byKey(const Key('darkModeScheduledOption')));
        await tester.pumpAndSettle();

        final scrollable = find.byType(Scrollable).first;
        final position = tester.state<ScrollableState>(scrollable).position;
        expect(
          position.maxScrollExtent,
          0,
          reason:
              'The settings form with scheduled dark mode is meant to fit a '
              '$_kPhone screen without scrolling; it overflows by '
              '${position.maxScrollExtent}px.',
        );
      },
    );
  }

  testWidgets('field, button and app-bar heights match the spacing budget', (
    tester,
  ) async {
    await pumpSettings(tester, 'en');

    expect(tester.getSize(find.byType(TextField).first).height, 42);
    expect(
      tester.getSize(find.byKey(const Key('darkModeScheduledOption'))).height,
      56,
    );
    expect(tester.getSize(find.byType(AppBar)).height, 40);
    for (final label in ['Confirm', 'Reset Data']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(TextButton),
      );
      expect(button, findsOneWidget, reason: 'no "$label" button');
      expect(tester.getSize(button).height, 44, reason: '"$label" height');
    }
  });

  testWidgets(
    'name field stays within the 42px budget during active dictation',
    (tester) async {
      final originalPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final getIt = GetIt.instance;
        getIt.unregister<SpeechRecognitionService>();
        getIt.registerSingleton<SpeechRecognitionService>(
          _ActiveSpeechRecognitionService(),
        );

        await pumpSettings(tester, 'en');
        services.memory.store['speechDictationDisclosureAccepted'] = true;

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
          find.byKey(const Key('speech-dictation-stop')),
        );

        expect(find.byKey(const Key('speech-dictation-stop')), findsOneWidget);
        expect(
          find.byKey(const Key('speech-dictation-discard')),
          findsOneWidget,
        );
        expect(tester.getSize(find.byType(TextField).first).height, 42);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = originalPlatform;
      }
    },
  );
}

Future<void> _pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsOneWidget);
}

final class _ActiveSpeechRecognitionService
    implements SpeechRecognitionService {
  int? _activeSessionId;

  @override
  bool get hasActiveSession => _activeSessionId != null;

  @override
  Future<SpeechRecognitionAvailability> initialize() async {
    return SpeechRecognitionAvailability.available;
  }

  @override
  Future<SpeechRecognitionLocalesResult> locales() async {
    return const SpeechRecognitionLocalesAvailable([
      SpeechRecognitionLocale(
        localeId: 'en-US',
        name: 'English (United States)',
      ),
    ]);
  }

  @override
  Future<SpeechRecognitionSessionStartResult> start({
    required String localeId,
    required SpeechRecognitionEventCallback onEvent,
  }) async {
    _activeSessionId = 1;
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
    _activeSessionId = null;
    return SpeechRecognitionSessionControlResult.cancelled;
  }
}
