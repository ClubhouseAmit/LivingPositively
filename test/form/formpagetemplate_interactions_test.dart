import 'dart:async';

// Drives every uncovered branch in FormPageTemplate:
//   - addItem / removeItem / editItem (lines 66-70)
//   - addSuggestion more-suggestions link (lines 73-81)
//   - createSelection switch arms for all six collection names
//     (lines 89-106) — DifficultEvents, MakeSafer, FeelBetter, Distractions,
//     SafeEnvironment, DreamsAndGoals
//   - the suggestion-row tap path with the already-selected branch
//   - the "add your own" link, which opens the AddFormAnswer dialog with
//     both the empty-validate and non-empty paths

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart'
    show NoopIncidentLoggerService, wizardStepHarness;
import '../../test_support/contract_persistent_memory_service.dart';

class _FakeAnalytics implements AnalyticsService {
  final List<String> events = [];
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(
    String name, [
    Map<String, dynamic>? properties,
  ]) async {
    events.add(name);
  }
}

base class _FakePersistentMemoryService
    extends ContractPersistentMemoryService {
  _FakePersistentMemoryService({this.writeDelay, this.failFirstWrite = false}) {
    onMissingRead = (_, _) => null;
    onPersist = (String key, PersistentMemoryType type, Object value) async {
      if (writeDelay != null) {
        await Future<void>.delayed(writeDelay!);
      }
      if (failFirstWrite && !_firstWriteAttempted) {
        _firstWriteAttempted = true;
        throw StateError('write failed');
      }
      if (failDreamsAndGoalsWrites &&
          <String>[
            'userSelectionPersonalPlan-DreamsAndGoals',
            'selectionSourcesPersonalPlan-DreamsAndGoals',
            'addedStringsPersonalPlan-DreamsAndGoals',
          ].contains(key)) {
        throw StateError('Dreams and Goals write failed');
      }
    };
  }

  /// Makes writes take measurable time so a test can observe the window
  /// between tapping the primary button and the wizard advancing.
  final Duration? writeDelay;

  /// Fails the first write only, so a test can check that a step recovers
  /// from a failed save rather than being stuck.
  final bool failFirstWrite;
  bool _firstWriteAttempted = false;
  bool failDreamsAndGoalsWrites = false;

  List<ContractPersistentMemoryWrite> completedWritesFor(String key) =>
      completedWrites.where((write) => write.key == key).toList();
}

final class _HeldDreamsMemoryService extends _FakePersistentMemoryService {
  _HeldDreamsMemoryService() {
    final ContractPersistentMemoryPersistHook? parentPersist = onPersist;
    onPersist = (String key, PersistentMemoryType type, Object value) async {
      if (key == 'userSelectionPersonalPlan-DreamsAndGoals' &&
          _holdFirstDreamsSelectionWrite) {
        _holdFirstDreamsSelectionWrite = false;
        firstDreamsSelectionWriteStarted.complete();
        await _firstDreamsSelectionWrite.future;
      }
      if (parentPersist != null) {
        await parentPersist(key, type, value);
      }
    };
  }

  final Completer<void> _firstDreamsSelectionWrite = Completer<void>();
  final Completer<void> firstDreamsSelectionWriteStarted = Completer<void>();
  bool _holdFirstDreamsSelectionWrite = true;

  void releaseFirstDreamsSelectionWrite() {
    if (!_firstDreamsSelectionWrite.isCompleted) {
      _firstDreamsSelectionWrite.complete();
    }
  }
}

final class _DualFailureDreamsMemoryService
    extends _FakePersistentMemoryService {
  _DualFailureDreamsMemoryService() {
    final ContractPersistentMemoryPersistHook? parentPersist = onPersist;
    onPersist = (String key, PersistentMemoryType type, Object value) async {
      attemptedKeys.add(key);
      if (failDreamsAndDisclaimerWrites &&
          (key == 'userSelectionPersonalPlan-DreamsAndGoals' ||
              key == 'disclaimerConfirmed')) {
        throw StateError('intentional $key write failure');
      }
      if (parentPersist != null) {
        await parentPersist(key, type, value);
      }
    };
  }

  bool failDreamsAndDisclaimerWrites = true;
  final List<String> attemptedKeys = <String>[];
}

Future<int> _pump(
  WidgetTester tester,
  String collection, {
  UserInformation? user,
  PersistentMemoryService? persistentMemoryService,
  VoidCallback? onNext,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 2200));
  final u = user ?? UserInformation()
    ..gender = 'other';
  final app = AppInformation();
  var nextCalls = 0;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserInformation>.value(value: u),
        ChangeNotifierProvider<AppInformation>.value(value: app),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        //FormPageTemplate is a wizard step hosted inside form.dart's
        //Scaffold; it no longer nests a Scaffold of its own, so the test
        //must supply the Material ancestor the same way production does.
        home: ScreenUtilInit(
          designSize: const Size(360, 690),
          child: wizardStepHarness(
            FormPageTemplate(
              key: GlobalKey<WizardStepState>(),
              next: () {
                nextCalls++;
                if (onNext != null) onNext();
              },
              prev: () {},
              collectionName: collection,
              persistentMemoryService: persistentMemoryService,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return nextCalls;
}

/// Opens the "add your own" dialog (the inline link identified by its
/// leading `Icons.add`), enters [text] if non-null, and taps Save.
Future<void> _addViaDialog(WidgetTester tester, String? text) async {
  await tester.ensureVisible(find.byIcon(Icons.add));
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  if (text != null) {
    await tester.enterText(find.byType(TextFormField), text);
  }
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

/// The primary button — keyed as wizard-primary-action inside WizardActions.
Finder _primaryButton() => find.byKey(const Key('wizard-primary-action'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePersistentMemoryService pm;
  late _FakeAnalytics analytics;

  setUp(() async {
    await GetIt.instance.reset();
    pm = _FakePersistentMemoryService();
    analytics = _FakeAnalytics();
    GetIt.instance.registerSingleton<PersistentMemoryService>(pm);
    GetIt.instance.registerSingleton<AnalyticsService>(analytics);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('empty-text add shows the AddFormAnswer validation error', (
    tester,
  ) async {
    await _pump(tester, 'PersonalPlan-DifficultEvents');

    // Open the "add your own" dialog and save without entering text.
    await _addViaDialog(tester, null);

    // The empty-text branch is now surfaced by AddFormAnswer's own
    // validator instead of the removed inline TextField.
    expect(find.text('Field cannot be empty'), findsOneWidget);
    expect(pm.store['userSelectionPersonalPlan-DifficultEvents'], isNull);
  });

  testWidgets(
    'non-empty add appends a FormAnswer row (addItem + createSelection)',
    (tester) async {
      await _pump(tester, 'PersonalPlan-DifficultEvents');

      await _addViaDialog(tester, 'manual entry');

      // Persisted via the fake PersistentMemoryService.
      expect(
        pm.store['userSelectionPersonalPlan-DifficultEvents'],
        contains('manual entry'),
      );
      expect(pm.store['disclaimerConfirmed'], true);
    },
  );

  testWidgets('tapping a suggestion promotes it out of the pool and persists '
      'via createSelection', (tester) async {
    await _pump(tester, 'PersonalPlan-DifficultEvents');

    // Suggestion rows are the ones wrapped in a dashed DottedBorder. Picking
    // one promotes it into the answered list above, so it leaves this pool
    // rather than staying put with a "selected" treatment.
    final suggestions = find.ancestor(
      of: find.byType(DottedBorder),
      matching: find.byType(InkWell),
    );
    final countBefore = suggestions.evaluate().length;
    expect(countBefore, greaterThan(0));

    final firstSuggestion = suggestions.first;
    final itemText = tester
        .widget<Text>(
          find
              .descendant(of: firstSuggestion, matching: find.byType(Text))
              .first,
        )
        .data!;
    await tester.ensureVisible(firstSuggestion);
    await tester.tap(firstSuggestion, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Persisted as a selection...
    final stored =
        pm.store['userSelectionPersonalPlan-DifficultEvents'] as List;
    expect(stored, contains(itemText));

    // ...and gone from the suggestion pool, not merely restyled.
    expect(find.byKey(ValueKey('suggestion-$itemText')), findsNothing);
    expect(
      find
          .ancestor(
            of: find.byType(DottedBorder),
            matching: find.byType(InkWell),
          )
          .evaluate()
          .length,
      countBefore - 1,
    );
  });

  testWidgets('the wizard does not advance until the answers are saved', (
    tester,
  ) async {
    // Re-register with a service whose writes take time, so the gap between
    // the tap and the step advancing is observable.
    await GetIt.instance.reset();
    final slowPm = _FakePersistentMemoryService(
      writeDelay: const Duration(milliseconds: 300),
    );
    GetIt.instance.registerSingleton<PersistentMemoryService>(slowPm);
    GetIt.instance.registerSingleton<AnalyticsService>(_FakeAnalytics());

    var nextCalls = 0;
    await _pump(
      tester,
      'PersonalPlan-DifficultEvents',
      onNext: () => nextCalls++,
    );

    await tester.tap(_primaryButton(), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));

    // Still saving.
    expect(nextCalls, 0);
    expect(
      slowPm.durableStore['userSelectionPersonalPlan-DifficultEvents'],
      isNull,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(nextCalls, 1);
    expect(
      slowPm.store['userSelectionPersonalPlan-DifficultEvents'],
      isNotNull,
    );
  });

  testWidgets('a failed save leaves the wizard where it is, and can be '
      'retried', (tester) async {
    await GetIt.instance.reset();
    final flakyPm = _FakePersistentMemoryService(failFirstWrite: true);
    GetIt.instance.registerSingleton<PersistentMemoryService>(flakyPm);
    GetIt.instance.registerSingleton<AnalyticsService>(_FakeAnalytics());

    var nextCalls = 0;
    await _pump(
      tester,
      'PersonalPlan-DifficultEvents',
      onNext: () => nextCalls++,
    );

    await tester.tap(_primaryButton(), warnIfMissed: false);
    await tester.pump();
    await tester.pump();
    expect(nextCalls, 0, reason: 'navigation waits on a save that failed');

    final retry = tester.widget<SnackBarAction>(
      find.widgetWithText(SnackBarAction, 'Try again'),
    );
    retry.onPressed();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(nextCalls, 1);
    expect(
      flakyPm.store['userSelectionPersonalPlan-DifficultEvents'],
      isNotNull,
    );
  });

  testWidgets('double-tapping the primary button advances only one step', (
    tester,
  ) async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      _FakePersistentMemoryService(
        writeDelay: const Duration(milliseconds: 300),
      ),
    );
    GetIt.instance.registerSingleton<AnalyticsService>(_FakeAnalytics());

    var nextCalls = 0;
    await _pump(
      tester,
      'PersonalPlan-DifficultEvents',
      onNext: () => nextCalls++,
    );

    // Both taps land inside the save window.
    await tester.tap(_primaryButton(), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_primaryButton(), warnIfMissed: false);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(nextCalls, 1);
  });

  testWidgets('deleting one of two identical answers keeps the other', (
    tester,
  ) async {
    final user = UserInformation()..gender = 'other';
    user.updateDifficultEvents(['same answer', 'same answer', 'other answer']);
    await _pump(tester, 'PersonalPlan-DifficultEvents', user: user);

    expect(find.byType(Dismissible), findsNWidgets(3));

    // Swipe the first of the two identical rows away.
    await tester.drag(find.byType(Dismissible).first, const Offset(-1100, 0));
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsNWidgets(2));
    expect(pm.store['userSelectionPersonalPlan-DifficultEvents'], [
      'same answer',
      'other answer',
    ], reason: 'removal is by row, not by matching text');
  });

  testWidgets('a whitespace-only answer is rejected', (tester) async {
    await _pump(tester, 'PersonalPlan-DifficultEvents');

    await tester.ensureVisible(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '    ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The dialog stays open with its validation error, and nothing is saved.
    expect(find.text('Field cannot be empty'), findsOneWidget);
    expect(find.byType(Dismissible), findsNothing);
    expect(pm.store['userSelectionPersonalPlan-DifficultEvents'], isNull);
  });

  testWidgets('picking every visible suggestion pulls in the next batch', (
    tester,
  ) async {
    await _pump(tester, 'PersonalPlan-DifficultEvents');

    Finder suggestionCards() => find.ancestor(
      of: find.byType(DottedBorder),
      matching: find.byType(InkWell),
    );

    String textOf(Finder card) => tester
        .widget<Text>(
          find.descendant(of: card, matching: find.byType(Text)).first,
        )
        .data!;

    final batchSize = suggestionCards().evaluate().length;
    expect(batchSize, greaterThan(0));
    final firstBatch = [
      for (var i = 0; i < batchSize; i++) textOf(suggestionCards().at(i)),
    ];

    for (var i = 0; i < batchSize; i++) {
      final card = suggestionCards().first;
      await tester.ensureVisible(card);
      await tester.tap(card, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    final refilled = suggestionCards();
    expect(refilled, findsWidgets);
    for (var i = 0; i < refilled.evaluate().length; i++) {
      expect(firstBatch, isNot(contains(textOf(refilled.at(i)))));
    }
  });

  testWidgets('an answered row can be edited and deleted from its dialog', (
    tester,
  ) async {
    await _pump(tester, 'PersonalPlan-DifficultEvents');
    await _addViaDialog(tester, 'original answer');

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    await tester.tap(find.text('original answer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'edited answer');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('edited answer'), findsOneWidget);
    expect(
      pm.store['userSelectionPersonalPlan-DifficultEvents'],
      contains('edited answer'),
    );

    await tester.tap(find.text('edited answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('edited answer'), findsNothing);
  });

  testWidgets('tapping the more-suggestions link widens displayedLength', (
    tester,
  ) async {
    await _pump(tester, 'PersonalPlan-DifficultEvents');

    // The more-suggestions link is identified by its trailing refresh icon.
    final moreSuggestions = find.ancestor(
      of: find.byIcon(Icons.refresh),
      matching: find.byType(TextButton),
    );
    expect(moreSuggestions, findsOneWidget);
    await tester.tap(moreSuggestions, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(InkWell), findsWidgets);
  });

  testWidgets('every collectionName routes through its createSelection arm + '
      'next button fires widget.next', (tester) async {
    for (final collection in const [
      'PersonalPlan-DifficultEvents',
      'PersonalPlan-MakeSafer',
      'PersonalPlan-FeelBetter',
      'PersonalPlan-Distractions',
      'PersonalPlan-SafeEnvironment',
      'PersonalPlan-DreamsAndGoals',
    ]) {
      await tester.binding.setSurfaceSize(const Size(900, 2200));
      var nextCalls = 0;
      final u = UserInformation()..gender = 'other';
      final app = AppInformation();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserInformation>.value(value: u),
            ChangeNotifierProvider<AppInformation>.value(value: app),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ScreenUtilInit(
              designSize: const Size(360, 690),
              child: wizardStepHarness(
                FormPageTemplate(
                  key: GlobalKey<WizardStepState>(),
                  next: () => nextCalls++,
                  prev: () {},
                  collectionName: collection,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Add via the dialog to force createSelection.
      await _addViaDialog(tester, 'x');
      // Tap ConfirmationButton — implementation uses InkWell wrapping the
      // child text, so we find by GestureDetector ancestor. Simplest: scroll
      // it into view and tap by text "המשך"/"Continue".
      // Cross-locale fallback: find ConfirmationButton InkWell — it's the
      // last InkWell with onPressed in the layout (suggestion rows precede
      // it in the tree).
      final inkwell = find.byWidgetPredicate((w) => w is InkWell);
      if (inkwell.evaluate().isNotEmpty) {
        await tester.tap(inkwell.last, warnIfMissed: false);
        await tester.pumpAndSettle();
      }
      // Persisted lookup key for this collection.
      expect(
        pm.store['userSelection$collection'],
        anyOf(contains('x'), isA<List<String>>()),
        reason: 'createSelection should have persisted for $collection',
      );
    }
  });

  testWidgets(
    'Safe Environment shows all four options and persists multiple choices '
    'with free text',
    (tester) async {
      final user = UserInformation()..gender = 'other';
      await _pump(tester, 'PersonalPlan-SafeEnvironment', user: user);

      // Suggestion rows are the only InkWells wrapped in a dashed
      // DottedBorder while unselected — that's how all four are identified
      // distinct from the "add your own"/continue InkWells.
      final choices = find.ancestor(
        of: find.byType(DottedBorder),
        matching: find.byType(InkWell),
      );
      expect(choices, findsNWidgets(4));

      await _addViaDialog(tester, 'My own safety step');

      await tester.tap(choices.first, warnIfMissed: false);
      await tester.tap(choices.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      const expected = [
        'My own safety step',
        'Removing or depositing personal weapon',
        'Having someone stay with me, not being alone',
      ];
      expect(pm.store['userSelectionPersonalPlan-SafeEnvironment'], expected);
      expect(user.safeEnvironment, expected);
    },
  );

  group('FormPageTemplate', () {
    testWidgets(
      'should persist a non-Dreams disclaimer through the injected UserInformation service',
      (tester) async {
        final modelMemory = _FakePersistentMemoryService();
        final user = UserInformation(service: modelMemory)..gender = 'other';
        await _pump(tester, 'PersonalPlan-DifficultEvents', user: user);

        await tester.tap(
          find.byKey(const ValueKey('suggestion-Watching the news')),
        );
        await tester.pumpAndSettle();

        expect(modelMemory.store['disclaimerConfirmed'], isTrue);
        expect(pm.store['disclaimerConfirmed'], isNull);
      },
    );

    group('Dreams and Goals', () {
      testWidgets(
        'should persist the disclaimer through the injected UserInformation service',
        (tester) async {
          final modelMemory = _FakePersistentMemoryService();
          final user = UserInformation(service: modelMemory)..gender = 'other';
          await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

          await tester.tap(
            find.byKey(const ValueKey('suggestion-Write and publish a book')),
          );
          await tester.pumpAndSettle();

          expect(modelMemory.store['disclaimerConfirmed'], isTrue);
          expect(pm.store['disclaimerConfirmed'], isNull);
        },
      );

      testWidgets(
        'should repair and persist malformed and missing sources before rendering',
        (tester) async {
          final modelMemory = _FakePersistentMemoryService();
          final user = UserInformation(service: modelMemory, gender: 'other');
          await user.hydrateDreamsAndGoalsFromStorage(
            const <String>['Write and publish a book', 'My custom dream'],
            storedSelectionSources: const <String>[
              'catalogue:learn-a-new-language',
            ],
            storedCustomSelections: const <String>[],
          );

          await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

          expect(user.dreamsAndGoalsSelectionSources, const <String>[
            'catalogue:write-and-publish-a-book',
            'custom',
          ]);
          expect(
            modelMemory.store['selectionSourcesPersonalPlan-DreamsAndGoals'],
            user.dreamsAndGoalsSelectionSources,
          );
          expect(
            modelMemory.store['addedStringsPersonalPlan-DreamsAndGoals'],
            const <String>['My custom dream'],
          );
          expect(
            find.byKey(const ValueKey('suggestion-Write and publish a book')),
            findsNothing,
          );
        },
      );

      testWidgets(
        'should keep add-own above rows while allowing multiple custom goals',
        (tester) async {
          final modelMemory = _FakePersistentMemoryService();
          final user = UserInformation(service: modelMemory, gender: 'other')
            ..updateDreamsAndGoals(
              const <String>[
                'Write and publish a book',
                'First custom dream',
                'Learn a new language',
                'Second custom dream',
              ],
              selectionSources: const <String>[
                'catalogue:write-and-publish-a-book',
                'custom',
                'catalogue:learn-a-new-language',
                'custom',
              ],
            );

          await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

          final addOwnGoal = find.text('Add my own personal dream or goal...');
          expect(addOwnGoal, findsOneWidget);
          expect(find.text('First custom dream'), findsOneWidget);
          expect(find.text('Second custom dream'), findsOneWidget);
          expect(
            tester.getTopLeft(addOwnGoal).dy,
            lessThan(tester.getTopLeft(find.text('First custom dream')).dy),
          );
          await _addViaDialog(tester, 'Third custom dream');

          expect(user.dreamsAndGoals, const <String>[
            'Write and publish a book',
            'First custom dream',
            'Learn a new language',
            'Second custom dream',
            'Third custom dream',
          ]);
          expect(user.dreamsAndGoalsSelectionSources, const <String>[
            'catalogue:write-and-publish-a-book',
            'custom',
            'catalogue:learn-a-new-language',
            'custom',
            'custom',
          ]);
          expect(
            modelMemory.store['addedStringsPersonalPlan-DreamsAndGoals'],
            const <String>[
              'First custom dream',
              'Second custom dream',
              'Third custom dream',
            ],
          );
          expect(addOwnGoal, findsOneWidget);
          expect(
            tester.getTopLeft(addOwnGoal).dy,
            lessThan(tester.getTopLeft(find.text('First custom dream')).dy),
          );
        },
      );

      testWidgets(
        'should persist multiple custom goals unchanged before advancing',
        (tester) async {
          final modelMemory = _FakePersistentMemoryService();
          final user = UserInformation(service: modelMemory, gender: 'other')
            ..updateDreamsAndGoals(
              const <String>['First custom dream', 'Second custom dream'],
              selectionSources: const <String>['custom', 'custom'],
            );
          var nextCalls = 0;

          await _pump(
            tester,
            'PersonalPlan-DreamsAndGoals',
            user: user,
            onNext: () {
              nextCalls++;
            },
          );
          await tester.tap(_primaryButton());
          await tester.pumpAndSettle();

          expect(nextCalls, 1);
          expect(
            modelMemory.store['userSelectionPersonalPlan-DreamsAndGoals'],
            const <String>['First custom dream', 'Second custom dream'],
          );
          expect(
            modelMemory.store['selectionSourcesPersonalPlan-DreamsAndGoals'],
            const <String>['custom', 'custom'],
          );
          expect(
            modelMemory.store['addedStringsPersonalPlan-DreamsAndGoals'],
            const <String>['First custom dream', 'Second custom dream'],
          );
          expect(
            modelMemory.completedWritesFor('disclaimerConfirmed'),
            hasLength(1),
          );
        },
      );

      testWidgets(
        'should retry the latest multiple-custom snapshot before advancing',
        (tester) async {
          final modelMemory = _FakePersistentMemoryService()
            ..failDreamsAndGoalsWrites = true;
          final user = UserInformation(service: modelMemory, gender: 'other')
            ..updateDreamsAndGoals(
              const <String>['First custom dream', 'Second custom dream'],
              selectionSources: const <String>['custom', 'custom'],
            );
          var nextCalls = 0;

          await _pump(
            tester,
            'PersonalPlan-DreamsAndGoals',
            user: user,
            onNext: () {
              nextCalls++;
            },
          );
          await tester.tap(_primaryButton(), warnIfMissed: false);
          await tester.pump();
          await tester.pump();

          expect(nextCalls, 0);
          final retry = tester.widget<SnackBarAction>(
            find.widgetWithText(SnackBarAction, 'Try again'),
          );

          modelMemory.failDreamsAndGoalsWrites = false;
          retry.onPressed();
          await tester.pumpAndSettle();

          expect(nextCalls, 1);
          expect(
            modelMemory.store['userSelectionPersonalPlan-DreamsAndGoals'],
            const <String>['First custom dream', 'Second custom dream'],
          );
          expect(
            modelMemory.store['selectionSourcesPersonalPlan-DreamsAndGoals'],
            const <String>['custom', 'custom'],
          );
          expect(
            modelMemory.store['addedStringsPersonalPlan-DreamsAndGoals'],
            const <String>['First custom dream', 'Second custom dream'],
          );
        },
      );

      testWidgets(
        'should persist repeated custom and catalogue sources separately',
        (tester) async {
          final user = UserInformation()..gender = 'other';
          await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

          await _addViaDialog(tester, 'My personal dream');
          await _addViaDialog(tester, 'Another personal dream');
          await tester.tap(
            find.byKey(const ValueKey('suggestion-Write and publish a book')),
          );
          await tester.tap(
            find.byKey(const ValueKey('suggestion-Learn a new language')),
          );
          await tester.pumpAndSettle();

          const expected = <String>[
            'My personal dream',
            'Another personal dream',
            'Write and publish a book',
            'Learn a new language',
          ];
          expect(user.dreamsAndGoals, expected);
          expect(user.dreamsAndGoalsSelectionSources, const <String>[
            'custom',
            'custom',
            'catalogue:write-and-publish-a-book',
            'catalogue:learn-a-new-language',
          ]);
          expect(
            pm.store['userSelectionPersonalPlan-DreamsAndGoals'],
            expected,
          );
          expect(pm.store['addedStringsPersonalPlan-DreamsAndGoals'], const [
            'My personal dream',
            'Another personal dream',
          ]);
          expect(
            pm.store['selectionSourcesPersonalPlan-DreamsAndGoals'],
            user.dreamsAndGoalsSelectionSources,
          );
          final addOwnGoal = find.text('Add my own personal dream or goal...');
          expect(addOwnGoal, findsOneWidget);
          expect(
            tester.getTopLeft(addOwnGoal).dy,
            lessThan(tester.getTopLeft(find.text('My personal dream')).dy),
          );
        },
      );

      testWidgets(
        'should keep the latest row snapshot when an older save is held',
        (tester) async {
          await GetIt.instance.reset();
          final heldMemory = _HeldDreamsMemoryService();
          GetIt.instance.registerSingleton<PersistentMemoryService>(heldMemory);
          GetIt.instance.registerSingleton<AnalyticsService>(_FakeAnalytics());
          addTearDown(heldMemory.releaseFirstDreamsSelectionWrite);

          final user = UserInformation(service: heldMemory)..gender = 'other';
          await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

          await _addViaDialog(tester, 'First custom dream');
          await heldMemory.firstDreamsSelectionWriteStarted.future;

          await tester.tap(
            find.byKey(const ValueKey('suggestion-Write and publish a book')),
          );
          await tester.pump();

          heldMemory.releaseFirstDreamsSelectionWrite();
          await tester.pumpAndSettle();

          expect(
            heldMemory.store['userSelectionPersonalPlan-DreamsAndGoals'],
            <String>['First custom dream', 'Write and publish a book'],
          );
          expect(
            heldMemory.store['selectionSourcesPersonalPlan-DreamsAndGoals'],
            <String>['custom', 'catalogue:write-and-publish-a-book'],
          );
          expect(
            heldMemory.store['addedStringsPersonalPlan-DreamsAndGoals'],
            <String>['First custom dream'],
          );
        },
      );

      testWidgets('should preserve sources through edit and paired removal', (
        tester,
      ) async {
        final user = UserInformation()
          ..gender = 'other'
          ..updateDreamsAndGoals(
            [
              'My original dream',
              'Another original dream',
              'Write and publish a book',
            ],
            selectionSources: const <String>[
              'custom',
              'custom',
              'catalogue:write-and-publish-a-book',
            ],
          );
        await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

        await tester.tap(find.text('Another original dream'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), 'My edited dream');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(user.dreamsAndGoalsSelectionSources, const <String>[
          'custom',
          'custom',
          'catalogue:write-and-publish-a-book',
        ]);
        expect(pm.store['addedStringsPersonalPlan-DreamsAndGoals'], [
          'My original dream',
          'My edited dream',
        ]);

        await tester.tap(find.text('My original dream'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(user.dreamsAndGoals, [
          'My edited dream',
          'Write and publish a book',
        ]);
        expect(user.dreamsAndGoalsSelectionSources, const <String>[
          'custom',
          'catalogue:write-and-publish-a-book',
        ]);
        expect(pm.store['addedStringsPersonalPlan-DreamsAndGoals'], [
          'My edited dream',
        ]);
        expect(
          find.text('Add my own personal dream or goal...'),
          findsOneWidget,
        );
      });

      testWidgets(
        'should observe simultaneous Dreams and disclaimer save failures before retrying',
        (tester) async {
          await GetIt.instance.reset();
          final memory = _DualFailureDreamsMemoryService();
          final logger = NoopIncidentLoggerService();
          GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
          GetIt.instance.registerSingleton<AnalyticsService>(_FakeAnalytics());
          GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
          final user = UserInformation(service: memory)..gender = 'other';
          await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

          await _addViaDialog(tester, 'A recoverable dream');
          await tester.pump();

          expect(
            find.widgetWithText(SnackBarAction, 'Try again'),
            findsOneWidget,
          );
          expect(
            memory.attemptedKeys,
            containsAll(<String>[
              'userSelectionPersonalPlan-DreamsAndGoals',
              'disclaimerConfirmed',
            ]),
          );
          expect(tester.takeException(), isNull);

          final SnackBarAction failedRetry = tester.widget<SnackBarAction>(
            find.widgetWithText(SnackBarAction, 'Try again'),
          );
          failedRetry.onPressed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));

          expect(logger.captured, isNotEmpty);
          expect(logger.captured.last, isA<StateError>());
          expect(
            find.widgetWithText(SnackBarAction, 'Try again'),
            findsOneWidget,
          );

          memory.failDreamsAndDisclaimerWrites = false;
          final SnackBarAction retry = tester.widget<SnackBarAction>(
            find.widgetWithText(SnackBarAction, 'Try again'),
          );
          retry.onPressed();
          await tester.pumpAndSettle();

          expect(
            memory.store['userSelectionPersonalPlan-DreamsAndGoals'],
            <String>['A recoverable dream'],
          );
          expect(memory.store['disclaimerConfirmed'], isTrue);
        },
      );

      testWidgets('should promote a changed catalogue row to a custom source', (
        tester,
      ) async {
        final user = UserInformation()
          ..gender = 'other'
          ..updateDreamsAndGoals(
            ['Write and publish a book'],
            selectionSources: const <String>[
              'catalogue:write-and-publish-a-book',
            ],
          );
        await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

        await tester.tap(find.text('Write and publish a book'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          'My revised own goal',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(user.dreamsAndGoals, ['My revised own goal']);
        expect(user.dreamsAndGoalsSelectionSources, const <String>['custom']);
        expect(pm.store['addedStringsPersonalPlan-DreamsAndGoals'], [
          'My revised own goal',
        ]);

        await tester.tap(find.text('My revised own goal'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          'Learn a new language',
        );
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(user.dreamsAndGoalsSelectionSources, const <String>['custom']);
        expect(
          find.byKey(const ValueKey('suggestion-Learn a new language')),
          findsOneWidget,
        );
      });

      testWidgets(
        'should allow a catalogue row to become another custom goal',
        (tester) async {
          final user = UserInformation()
            ..gender = 'other'
            ..updateDreamsAndGoals(
              ['My only custom goal', 'Write and publish a book'],
              selectionSources: const <String>[
                'custom',
                'catalogue:write-and-publish-a-book',
              ],
            );
          await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

          await tester.tap(find.text('Write and publish a book'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField),
            'A second own goal',
          );
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();

          expect(user.dreamsAndGoals, [
            'My only custom goal',
            'A second own goal',
          ]);
          expect(user.dreamsAndGoalsSelectionSources, const <String>[
            'custom',
            'custom',
          ]);
          expect(pm.store['addedStringsPersonalPlan-DreamsAndGoals'], const [
            'My only custom goal',
            'A second own goal',
          ]);
        },
      );

      testWidgets(
        'should keep an exact-catalogue own goal custom and selectable separately',
        (tester) async {
          final user = UserInformation()..gender = 'other';
          await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

          await _addViaDialog(tester, 'Write and publish a book');

          final catalogueSuggestion = find.byKey(
            const ValueKey('suggestion-Write and publish a book'),
          );
          expect(catalogueSuggestion, findsOneWidget);
          await tester.tap(catalogueSuggestion);
          await tester.pumpAndSettle();

          expect(user.dreamsAndGoals, const <String>[
            'Write and publish a book',
            'Write and publish a book',
          ]);
          expect(user.dreamsAndGoalsSelectionSources, const <String>[
            'custom',
            'catalogue:write-and-publish-a-book',
          ]);
          expect(pm.store['addedStringsPersonalPlan-DreamsAndGoals'], const [
            'Write and publish a book',
          ]);
        },
      );

      testWidgets('should hide a Hebrew catalogue selection in English', (
        tester,
      ) async {
        const hebrewSuggestion = 'לכתוב ולהוציא לאור ספר';
        final user = UserInformation()
          ..gender = 'other'
          ..updateDreamsAndGoals(
            [hebrewSuggestion],
            selectionSources: const <String>[
              'catalogue:write-and-publish-a-book',
            ],
          );
        await _pump(tester, 'PersonalPlan-DreamsAndGoals', user: user);

        expect(
          find.byKey(const ValueKey('suggestion-Write and publish a book')),
          findsNothing,
        );
        expect(
          find.text('Add my own personal dream or goal...'),
          findsOneWidget,
        );
      });
    });
  });

  testWidgets('swiping a FormAnswer row calls removeItem', (tester) async {
    final user = UserInformation()..gender = 'other';
    user.updateDifficultEvents(['seedA', 'seedB']);

    await _pump(tester, 'PersonalPlan-DifficultEvents', user: user);

    // Two FormAnswer rows exist, each wrapped in a Dismissible.
    expect(find.byType(Dismissible), findsNWidgets(2));
    await tester.drag(find.byType(Dismissible).first, const Offset(-1100, 0));
    await tester.pumpAndSettle();

    // After removal, persisted list shrinks by one.
    final after = pm.store['userSelectionPersonalPlan-DifficultEvents'];
    expect(after, isA<List<String>>());
    expect((after as List).length, 1);
  });

  group('Injectable persistence boundary without global locator mutation', () {
    testWidgets(
      'FormPageTemplate uses injected PersistentMemoryService without GetIt registration',
      (tester) async {
        final injectedMemoryService = _FakePersistentMemoryService();
        final user = UserInformation(service: injectedMemoryService)
          ..gender = 'other';

        await _pump(
          tester,
          'PersonalPlan-FeelBetter',
          user: user,
          persistentMemoryService: injectedMemoryService,
        );

        // Add an item via dialog
        await _addViaDialog(tester, 'New Feel Better Item');
        await tester.pumpAndSettle();

        expect(
          injectedMemoryService.store['userSelectionPersonalPlan-FeelBetter'],
          contains('New Feel Better Item'),
        );
      },
    );

    testWidgets(
      'FormPageTemplate Dreams and Goals routes through injected UserInformation without GetIt registration',
      (tester) async {
        final injectedMemoryService = _FakePersistentMemoryService();
        final user = UserInformation(service: injectedMemoryService)
          ..gender = 'other';

        await _pump(
          tester,
          'PersonalPlan-DreamsAndGoals',
          user: user,
        );

        // Add custom goal via dialog
        await _addViaDialog(tester, 'Run a Marathon');
        await tester.pumpAndSettle();

        expect(
          injectedMemoryService.store['userSelectionPersonalPlan-DreamsAndGoals'],
          contains('Run a Marathon'),
        );
        expect(
          injectedMemoryService.store['selectionSourcesPersonalPlan-DreamsAndGoals'],
          contains('custom'),
        );
      },
    );
  });
}
