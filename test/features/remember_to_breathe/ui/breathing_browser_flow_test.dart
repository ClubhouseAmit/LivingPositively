// Keep this harness self-contained: Flutter's Chrome test compiler cannot
// resolve the repository's test_support imports outside the test directory.
// Exercise the production persistence adapter and localized page together.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_photo_importer.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_store.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_page.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_model.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_state.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/app_theme.dart';

class _Picker extends Mock implements ImagePickerService {}

class _Logger implements IncidentLoggerService {
  final List<Object> errors = [];

  @override
  Future<void> initializeSentry(Widget app) async {}

  @override
  Future<void> captureLog(
    dynamic error, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    errors.add(error as Object);
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(BreathingPage),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 30,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('BreathingPage browser flow', () {
    setUp(() async {
      await GetIt.instance.reset();
      SharedPreferences.setMockInitialValues({});
      GetIt.instance.registerSingleton<IncidentLoggerService>(_Logger());
    });
    tearDown(() async => GetIt.instance.reset());

    for (final locale in ['en', 'he', 'ar']) {
      testWidgets(
        'should complete $locale customization, practice and history',
        (tester) async {
          final memory = SharedPreferencesService();
          final store = BreathingStore(memory);
          final picker = _Picker();
          when(
            () => picker.pickImage(source: ImageSource.gallery),
          ).thenAnswer((_) async => null);
          var elapsed = Duration.zero;
          final model = BreathingViewModel(
            store,
            photoImporter: BreathingPhotoImporter(picker),
            monotonicElapsed: () => elapsed,
            now: () => DateTime.utc(2026, 9, 13, 12).add(elapsed),
            sessionId: () => 'browser-flow-$locale',
          );
          await tester.binding.setSurfaceSize(const Size(360, 780));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: buildLightTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.2)),
                child: child!,
              ),
              home: Scaffold(body: BreathingPage(viewModel: model)),
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(BreathingPage));
          final strings = AppLocalizations.of(context)!;
          expect(
            Directionality.of(context),
            locale == 'en' ? TextDirection.ltr : TextDirection.rtl,
          );
          expect(find.text(strings.breathingTitle), findsOneWidget);

          await _tap(tester, 'breathingCustomize');
          await _tap(tester, 'breathingBackgroundbeach');
          await _tap(tester, 'breathingChoosePhoto');
          expect(model.draftSettings.background, BreathingBackground.beach);
          await _tap(tester, 'breathingNextStep');
          await _tap(tester, 'breathingInhaleIncrease');
          await _tap(tester, 'breathingNextStep');
          await _tap(tester, 'breathingExhaleIncrease');
          await _tap(tester, 'breathingNextStep');
          expect(
            (await store.load()).settings.inhaleDuration,
            const Duration(seconds: 4),
          );
          expect(
            (await store.load()).settings.exhaleDuration,
            const Duration(seconds: 4),
          );

          await _tap(tester, 'breathingPatterncustom');
          await _tap(tester, 'breathingStartSelected');
          await _tap(tester, 'breathingBefore8');
          await _tap(tester, 'breathingStartRated');
          expect(find.text(strings.breathingCycle(1)), findsOneWidget);
          await _tap(tester, 'breathingToggleCircle');
          expect(find.byKey(const Key('breathingCircle')), findsNothing);
          await _tap(tester, 'breathingToggleText');
          expect(find.byKey(const Key('breathingPhase')), findsNothing);
          await _tap(tester, 'breathingPause');
          elapsed += const Duration(seconds: 20);
          model.refresh();
          await tester.pump();
          expect(model.completedCycles, 0);
          await _tap(tester, 'breathingContinue');
          elapsed += const Duration(seconds: 64);
          model.refresh();
          await tester.pump();
          await tester.pump();
          expect(model.screen, BreathingScreen.result);
          expect(find.text(strings.breathingCompleteMessage), findsOneWidget);
          await _tap(tester, 'breathingAfter3');
          await _tap(tester, 'breathingDone');
          await _tap(tester, 'breathingHistory');
          expect(
            find.text(strings.breathingCompletedCycles(8)),
            findsOneWidget,
          );
          expect(
            find.text('${strings.breathingBefore}: 8 / 10'),
            findsOneWidget,
          );
          expect(
            find.text('${strings.breathingAfter}: 3 / 10'),
            findsOneWidget,
          );

          final reloaded = await BreathingStore(memory).load();
          expect(reloaded.sessions, hasLength(1));
          expect(reloaded.sessions.single.pattern, BreathingPattern.custom);
          expect(reloaded.sessions.single.stressBefore, 8);
          expect(reloaded.sessions.single.stressAfter, 3);
          expect(reloaded.settings.background, BreathingBackground.beach);
          expect(
            (GetIt.instance<IncidentLoggerService>() as _Logger).errors,
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
