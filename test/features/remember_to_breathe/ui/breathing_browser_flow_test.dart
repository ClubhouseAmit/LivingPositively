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
import 'package:mazilon/pages/breathing_page.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_model.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_state.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_widgets.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/feel_good/data/image_picker_repository.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/util/async/app_theme.dart';

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

Future<BreathingViewModel> _pumpProgressPage(
  WidgetTester tester, {
  required Duration Function() elapsed,
  String locale = 'en',
}) async {
  final model = BreathingViewModel(
    BreathingStore(SharedPreferencesService()),
    photoImporter: BreathingPhotoImporter(_Picker()),
    monotonicElapsed: elapsed,
  );
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildLightTheme(),
      home: Scaffold(body: BreathingPage(viewModel: model)),
    ),
  );
  await tester.pumpAndSettle();
  return model;
}

Map<Element, int> _trackRebuilds() {
  final rebuilds = <Element, int>{};
  final previous = debugOnRebuildDirtyWidget;
  debugOnRebuildDirtyWidget = (element, builtOnce) {
    previous?.call(element, builtOnce);
    rebuilds.update(element, (count) => count + 1, ifAbsent: () => 1);
  };
  addTearDown(() => debugOnRebuildDirtyWidget = previous);
  return rebuilds;
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

    testWidgets('should rebuild only the circle for animation samples', (
      tester,
    ) async {
      var elapsed = Duration.zero;
      final model = await _pumpProgressPage(tester, elapsed: () => elapsed);
      await _tap(tester, 'breathingQuickStart');
      await _tap(tester, 'breathingSkipRating');
      await tester.pumpAndSettle();
      final strings = AppLocalizations.of(
        tester.element(find.byType(BreathingPage)),
      )!;
      final pageBuilder = tester.element(
        find.byWidgetPredicate(
          (widget) => widget is AnimatedBuilder && widget.animation == model,
        ),
      );
      final circleBuilder = tester.element(
        find.byWidgetPredicate(
          (widget) =>
              widget is AnimatedBuilder &&
              widget.animation == model.progressChanges,
        ),
      );
      final stableElements = [
        pageBuilder,
        tester.element(find.text(strings.breathingTitle)),
        tester.element(find.byType(BreathingBackgroundImage)),
        for (final key in [
          'breathingBack',
          'breathingPause',
          'breathingToggleCircle',
          'breathingToggleText',
          'breathingCycle',
          'breathingPhase',
        ])
          tester.element(find.byKey(Key(key))),
      ];
      final circle = find.byKey(const Key('breathingCircle'));
      final decoration = tester.widget<Transform>(circle).child;
      final rebuilds = _trackRebuilds();
      for (var tick = 0; tick < 30; tick++) {
        elapsed += const Duration(milliseconds: 33);
        model.refresh();
        await tester.pump();
      }
      expect(rebuilds[circleBuilder], 30);
      for (final element in stableElements) {
        expect(rebuilds[element] ?? 0, 0, reason: '${element.widget} rebuilt');
      }
      expect(
        tester.widget<Transform>(circle).transform.storage[0],
        closeTo(0.45 + 0.55 * 0.33, 0.0001),
      );
      expect(tester.widget<Transform>(circle).child, same(decoration));

      elapsed = const Duration(seconds: 3);
      model.refresh();
      await tester.pump();
      expect(rebuilds[pageBuilder], 1);
      expect(find.text(strings.breathingExhale), findsOneWidget);
      expect(tester.widget<Transform>(circle).transform.storage[0], 1);

      await _tap(tester, 'breathingToggleCircle');
      await _tap(tester, 'breathingToggleText');
      await tester.pumpAndSettle();
      rebuilds.clear();
      elapsed += const Duration(seconds: 1);
      model.refresh();
      await tester.pump();
      expect(rebuilds[pageBuilder] ?? 0, 0);
      expect(circle, findsNothing);
      expect(model.phaseProgress, closeTo(1 / 3, 0.0001));
      await _tap(tester, 'breathingToggleCircle');
      expect(
        tester.widget<Transform>(circle).transform.storage[0],
        closeTo(0.45 + 0.55 * 2 / 3, 0.0001),
      );
      elapsed = const Duration(seconds: 6);
      model.refresh();
      await tester.pump();
      expect(find.text(strings.breathingCycle(2)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should rebuild only the duration display while measuring', (
      tester,
    ) async {
      var elapsed = Duration.zero;
      final model = await _pumpProgressPage(tester, elapsed: () => elapsed);
      await _tap(tester, 'breathingCustomize');
      await _tap(tester, 'breathingNextStep');
      final measure = find.byKey(const Key('breathingMeasure'));
      await tester.ensureVisible(measure);
      final gesture = await tester.startGesture(tester.getCenter(measure));
      await tester.pumpAndSettle();
      final strings = AppLocalizations.of(
        tester.element(find.byType(BreathingPage)),
      )!;
      final pageBuilder = tester.element(
        find.byWidgetPredicate(
          (widget) => widget is AnimatedBuilder && widget.animation == model,
        ),
      );
      final durationBuilder = tester.element(
        find.byWidgetPredicate(
          (widget) =>
              widget is AnimatedBuilder &&
              widget.animation == model.progressChanges,
        ),
      );
      final stableElements = [
        pageBuilder,
        tester.element(find.text(strings.breathingTitle)),
        tester.element(find.byKey(const Key('breathingBack'))),
        tester.element(find.byKey(const Key('breathingNextStep'))),
        tester.element(find.byKey(const Key('breathingSkipStep'))),
      ];
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('breathingNextStep')))
            .onPressed,
        isNull,
      );
      final rebuilds = _trackRebuilds();
      for (var tick = 0; tick < 30; tick++) {
        elapsed += const Duration(milliseconds: 33);
        model.refresh();
        await tester.pump();
      }
      expect(rebuilds[durationBuilder], 30);
      for (final element in stableElements) {
        expect(rebuilds[element] ?? 0, 0, reason: '${element.widget} rebuilt');
      }
      expect(find.text(strings.breathingSeconds(1.0)), findsOneWidget);
      expect(model.isMeasuring, isTrue);
      elapsed = const Duration(seconds: 9);
      model.refresh();
      await tester.pump();
      expect(rebuilds[pageBuilder], 1);
      expect(model.isMeasuring, isFalse);
      expect(model.draftSettings.inhaleDuration, const Duration(seconds: 9));
      expect(find.text(strings.breathingSeconds(9.0)), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('breathingNextStep')))
            .onPressed,
        isNotNull,
      );
      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should select Arabic duration plurals at displayed precision',
      (tester) async {
        var elapsed = Duration.zero;
        final model = await _pumpProgressPage(
          tester,
          elapsed: () => elapsed,
          locale: 'ar',
        );
        await _tap(tester, 'breathingCustomize');
        await _tap(tester, 'breathingNextStep');
        final strings = AppLocalizations.of(
          tester.element(find.byType(BreathingPage)),
        )!;
        final measure = find.byKey(const Key('breathingMeasure'));
        await tester.ensureVisible(measure);
        final gesture = await tester.startGesture(tester.getCenter(measure));
        elapsed = const Duration(milliseconds: 3033);
        model.refresh();
        await tester.pump();
        expect(find.text(strings.breathingSeconds(3)), findsOneWidget);
        expect(strings.breathingSeconds(3), endsWith('ثوانٍ'));
        elapsed = const Duration(milliseconds: 3500);
        model.refresh();
        await tester.pump();
        expect(find.text(strings.breathingSeconds(3.5)), findsOneWidget);
        expect(strings.breathingSeconds(3.5), endsWith('ثانية'));
        await gesture.up();
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('should label Hebrew duration adjustments by one second', (
      tester,
    ) async {
      await _pumpProgressPage(
        tester,
        elapsed: () => Duration.zero,
        locale: 'he',
      );
      await _tap(tester, 'breathingCustomize');
      await _tap(tester, 'breathingNextStep');
      expect(find.byTooltip('קיצור משך הנשימה בשנייה'), findsOneWidget);
      expect(find.byTooltip('הארכת משך הנשימה בשנייה'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should end paused Hebrew practice through the back button', (
      tester,
    ) async {
      var elapsed = Duration.zero;
      final model = await _pumpProgressPage(
        tester,
        elapsed: () => elapsed,
        locale: 'he',
      );
      await _tap(tester, 'breathingQuickStart');
      await _tap(tester, 'breathingBefore8');
      await _tap(tester, 'breathingStartRated');
      elapsed = const Duration(seconds: 7);
      model.refresh();
      await tester.pump();
      await _tap(tester, 'breathingBack');
      expect(model.isPaused, isTrue);
      elapsed += const Duration(minutes: 1);
      model.refresh();
      await _tap(tester, 'breathingBack');
      await tester.pumpAndSettle();
      expect(model.screen, BreathingScreen.result);
      final saved = (await BreathingStore(
        SharedPreferencesService(),
      ).load()).sessions.single;
      expect(saved.completedCycles, 1);
      expect(saved.stressBefore, 8);
      expect(saved.stressAfter, isNull);
      await _tap(tester, 'breathingDone');
      expect(model.screen, BreathingScreen.landing);
      expect(tester.takeException(), isNull);
    });

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

          final quickStartIcon = find.descendant(
            of: find.byKey(const Key('breathingQuickStart')),
            matching: find.byIcon(Icons.play_arrow),
          );
          expect(
            tester.getCenter(quickStartIcon).dx,
            lessThan(
              tester.getTopLeft(find.text(strings.breathingQuickStart)).dx,
            ),
          );
          final iconGlyph = tester.renderObject<RenderBox>(
            find.descendant(
              of: quickStartIcon,
              matching: find.byType(RichText),
            ),
          );
          // Check the painted glyph's direction, not just the widget setting.
          expect(
            iconGlyph.getTransformTo(null).entry(0, 0),
            locale == 'en' ? greaterThan(0) : lessThan(0),
          );

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
