import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/widget_test_scaffold.dart';

/// Mounts the production page with its normal localization and theme while
/// keeping Firebase bootstrap outside this device-local persistence scenario.
Widget _breathingHarness(BreathingViewModel model) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: buildLightTheme(),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: BreathingPage(key: ObjectKey(model), viewModel: model),
    ),
  ),
);

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String reason,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final elapsed = Stopwatch()..start();
  while (!condition() && elapsed.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(condition(), isTrue, reason: reason);
  // Native futures may complete between live frames. Render the state whose
  // condition just became true before attempting to locate its controls.
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await _waitUntil(
    tester,
    () => target.evaluate().isNotEmpty,
    reason: 'The production control $key should be rendered before tapping.',
  );
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
}

/// Restores only the feature key, including an originally malformed primitive.
Future<void> _restoreSnapshot(
  SharedPreferences preferences,
  Object? original,
) async {
  final restored = await switch (original) {
    null => preferences.remove(BreathingStore.snapshotKey),
    String value => preferences.setString(BreathingStore.snapshotKey, value),
    bool value => preferences.setBool(BreathingStore.snapshotKey, value),
    int value => preferences.setInt(BreathingStore.snapshotKey, value),
    double value => preferences.setDouble(BreathingStore.snapshotKey, value),
    List<String> value => preferences.setStringList(
      BreathingStore.snapshotKey,
      value,
    ),
    _ => throw StateError('Unsupported existing preference type.'),
  };
  expect(
    restored,
    isTrue,
    reason: 'The original native value must be restored.',
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Remember to Breathe native persistence', () {
    late SharedPreferences preferences;
    late BreathingStore store;
    Object? originalSnapshot;

    setUp(() async {
      await GetIt.instance.reset();
      GetIt.instance.registerSingleton<IncidentLoggerService>(
        NoopIncidentLoggerService(),
      );
      preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      originalSnapshot = preferences.get(BreathingStore.snapshotKey);
      store = BreathingStore(SharedPreferencesService());
      await preferences.remove(BreathingStore.snapshotKey);
    });

    tearDown(() async {
      // A queued native write must finish before restoring the original value.
      try {
        await store.load();
      } finally {
        await _restoreSnapshot(preferences, originalSnapshot);
        await GetIt.instance.reset();
      }
    });

    testWidgets(
      'should pause, complete eight real-time cycles and reload both ratings',
      (tester) async {
        final model = BreathingViewModel(
          store,
          photoImporter: BreathingPhotoImporter(ImagePickerServiceImpl()),
        );
        try {
          await tester.pumpWidget(_breathingHarness(model));
          await _waitUntil(
            tester,
            () => model.isReady,
            reason: 'The native snapshot should load.',
          );
          await _tap(tester, 'breathingQuickStart');
          expect(model.screen, BreathingScreen.preRating);
          await _tap(tester, 'breathingBefore8');
          await _tap(tester, 'breathingStartRated');
          expect(model.screen, BreathingScreen.practice);
          expect(model.selectedPattern, BreathingPattern.basic);

          await _waitUntil(
            tester,
            () => model.phaseProgress > 0.2,
            reason: 'The production monotonic practice clock should advance.',
          );
          await _tap(tester, 'breathingPause');
          expect(model.isPaused, isTrue);
          final pausedPhase = model.phase;
          final pausedProgress = model.phaseProgress;
          final pausedCycles = model.completedCycles;
          await tester.pump(const Duration(seconds: 1));
          expect(model.phase, pausedPhase);
          expect(model.phaseProgress, pausedProgress);
          expect(model.completedCycles, pausedCycles);
          await _tap(tester, 'breathingContinue');
          expect(model.isPaused, isFalse);

          await _waitUntil(
            tester,
            () => model.screen == BreathingScreen.result,
            reason: 'Basic practice should finish exactly eight 3/3 cycles.',
            timeout: const Duration(seconds: 60),
          );
          expect(model.result!.completedCycles, 8);
          expect(model.result!.isComplete, isTrue);
          expect(model.result!.stressBefore, 8);
          expect(model.result!.stressAfter, isNull);
          await _tap(tester, 'breathingAfter4');
          await _waitUntil(
            tester,
            () => !model.isSaving && !model.hasUnsavedResult,
            reason: 'The completed session and post-rating should save.',
          );
          expect(model.error, isNull);
          final attemptId = model.result!.id;
          await _tap(tester, 'breathingDone');
          expect(model.screen, BreathingScreen.landing);

          // Reload the Android preference channel, then create new persistence
          // and page instances so this cannot pass from the view-model cache.
          await tester.pumpWidget(const SizedBox.shrink());
          await preferences.reload();
          final saved = BreathingSnapshot.decode(
            preferences.getString(BreathingStore.snapshotKey)!,
          );
          expect(saved.sessions, hasLength(1));
          expect(saved.sessions.single.id, attemptId);
          store = BreathingStore(SharedPreferencesService());
          final reloaded = await store.load();
          expect(reloaded.sessions.single.completedCycles, 8);
          expect(reloaded.sessions.single.stressBefore, 8);
          expect(reloaded.sessions.single.stressAfter, 4);

          final reopened = BreathingViewModel(
            store,
            photoImporter: BreathingPhotoImporter(ImagePickerServiceImpl()),
          );
          await tester.pumpWidget(_breathingHarness(reopened));
          await _waitUntil(
            tester,
            () => reopened.isReady,
            reason: 'A fresh page should read the native persisted record.',
          );
          await _tap(tester, 'breathingHistory');
          expect(reopened.screen, BreathingScreen.history);
          expect(reopened.history.single.id, attemptId);
          expect(reopened.history.single.stressBefore, 8);
          expect(reopened.history.single.stressAfter, 4);
          expect(tester.takeException(), isNull);
        } finally {
          // Dispose the page-owned timers before restoring real device data.
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
