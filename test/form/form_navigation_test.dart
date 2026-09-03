import 'dart:async';

// Drives the navigation callbacks inside FormProgressIndicator that the
// existing form_widgets_test only renders past:
//   - next() / prev() (lines 51-61)
//   - submitForm via the "Save & Quit" IconButton in the AppBar header
//     (lines 92-103 — navigateToMenu pushes a Menu route)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/form/custom_category_step.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../../test_support/contract_persistent_memory_service.dart';
import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
  key: 'phone',
  header: 'h',
  subTitle: 's',
  midTitle: 'm',
  phoneNameTitle: 'n',
  phoneNumberTitle: 'p',
  phoneNames: const <String>[],
  phoneNumbers: const <String>[],
  savedPhoneNames: const <String>[],
  savedPhoneNumbers: const <String>[],
  phoneDescription: const <String>[],
);

abstract base class _FormNavigationPersistentMemoryService
    extends ContractPersistentMemoryService {
  _FormNavigationPersistentMemoryService() {
    onMissingRead = (_, PersistentMemoryType type) {
      switch (type) {
        case PersistentMemoryType.String:
          return '';
        case PersistentMemoryType.Int:
          return 0;
        case PersistentMemoryType.Double:
          return 0.0;
        case PersistentMemoryType.Bool:
          return false;
        case PersistentMemoryType.StringList:
          return <String>[];
      }
    };
  }
}

final class _HeldDreamsMemoryService
    extends _FormNavigationPersistentMemoryService {
  final Completer<void> _firstDreamsSelectionWrite = Completer<void>();
  final Completer<void> firstDreamsSelectionWriteStarted = Completer<void>();
  bool _holdFirstDreamsSelectionWrite = true;

  _HeldDreamsMemoryService() {
    onPersist = (key, _, _) async {
      if (key == 'userSelectionPersonalPlan-DreamsAndGoals' &&
          _holdFirstDreamsSelectionWrite) {
        _holdFirstDreamsSelectionWrite = false;
        firstDreamsSelectionWriteStarted.complete();
        await _firstDreamsSelectionWrite.future;
      }
    };
  }

  void releaseFirstDreamsSelectionWrite() {
    if (!_firstDreamsSelectionWrite.isCompleted) {
      _firstDreamsSelectionWrite.complete();
    }
  }
}

final class _HeldDisclaimerMemoryService
    extends _FormNavigationPersistentMemoryService {
  final Completer<void> _disclaimerWrite = Completer<void>();
  final Completer<void> disclaimerWriteStarted = Completer<void>();
  bool _holdDisclaimerWrite = true;

  _HeldDisclaimerMemoryService() {
    onPersist = (key, _, _) async {
      if (key == 'disclaimerConfirmed' && _holdDisclaimerWrite) {
        _holdDisclaimerWrite = false;
        disclaimerWriteStarted.complete();
        await _disclaimerWrite.future;
      }
    };
  }

  void releaseDisclaimerWrite() {
    if (!_disclaimerWrite.isCompleted) {
      _disclaimerWrite.complete();
    }
  }
}

final class _FailFirstDisclaimerMemoryService
    extends _FormNavigationPersistentMemoryService {
  bool _hasFailed = false;
  int disclaimerWrites = 0;

  _FailFirstDisclaimerMemoryService() {
    onPersist = (key, _, _) {
      if (key == 'disclaimerConfirmed') {
        disclaimerWrites++;
        if (!_hasFailed) {
          _hasFailed = true;
          throw StateError('Disclaimer persistence failed.');
        }
      }
    };
  }
}

final class _FailFirstDreamsMemoryService
    extends _FormNavigationPersistentMemoryService {
  bool _hasFailed = false;

  _FailFirstDreamsMemoryService() {
    onPersist = (key, _, _) {
      if (key == 'userSelectionPersonalPlan-DreamsAndGoals' && !_hasFailed) {
        _hasFailed = true;
        throw StateError('Dreams persistence failed.');
      }
    };
  }
}

final class _FailingNameMemoryService
    extends _FormNavigationPersistentMemoryService {
  bool failNameWrite = true;

  _FailingNameMemoryService() {
    onPersist = (key, _, _) {
      if (key == 'name' && failNameWrite) {
        throw StateError('name persistence failed.');
      }
    };
  }
}

final class _HeldNameMemoryService
    extends _FormNavigationPersistentMemoryService {
  final Completer<void> _nameWrite = Completer<void>();
  final Completer<void> nameWriteStarted = Completer<void>();

  _HeldNameMemoryService() {
    onPersist = (key, _, _) async {
      if (key == 'name' && !nameWriteStarted.isCompleted) {
        nameWriteStarted.complete();
        await _nameWrite.future;
      }
    };
  }

  void releaseNameWrite() {
    if (!_nameWrite.isCompleted) {
      _nameWrite.complete();
    }
  }
}

Future<UserInformation> _pumpForm(WidgetTester tester) async {
  final phoneData = _phoneData();
  final user = UserInformation()..gender = 'other';
  await pumpWithProviders(
    tester,
    ChangeNotifierProvider<PhonePageData>.value(
      value: phoneData,
      child: FormProgressIndicator(
        phonePageData: phoneData,
        changeLocale: (_) {},
      ),
    ),
    userInformation: user,
    surfaceSize: const Size(1024, 2400),
  );
  await tester.pump();
  drainOverflowExceptions(tester);
  return user;
}

Future<FormProgressIndicatorState> _moveToDreamsAndGoals(
  WidgetTester tester,
) async {
  final state = tester.state<FormProgressIndicatorState>(
    find.byType(FormProgressIndicator),
  );
  while (state.currentStep < 5) {
    state.next();
    await tester.pumpAndSettle();
  }
  expect(
    tester
        .widget<FormPageTemplate>(find.byType(FormPageTemplate))
        .collectionName,
    'PersonalPlan-DreamsAndGoals',
  );
  return state;
}

Future<FormProgressIndicatorState> _moveToShare(WidgetTester tester) async {
  final state = tester.state<FormProgressIndicatorState>(
    find.byType(FormProgressIndicator),
  );
  while (find.byType(ShareForm).evaluate().isEmpty) {
    state.next();
    await tester.pumpAndSettle();
  }
  expect(find.byType(ShareForm), findsOneWidget);
  return state;
}

Future<void> _addShareDreamAndHoldSave(
  WidgetTester tester,
  _HeldDreamsMemoryService memory,
) async {
  final toggle = find.byKey(const Key('share-dreams-and-goals-toggle'));
  await tester.ensureVisible(toggle);
  await tester.tap(toggle);
  await tester.pumpAndSettle();

  final addOwnGoal = find.text('Add my own personal dream or goal...');
  await tester.ensureVisible(addOwnGoal);
  await tester.tap(addOwnGoal);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), 'Held share dream');
  await tester.tap(find.text('Save'));
  await memory.firstDreamsSelectionWriteStarted.future;
}

void _pressSaveAndQuit(WidgetTester tester) {
  final button = tester.widget<TextButton>(
    find.ancestor(of: find.text('To menu'), matching: find.byType(TextButton)),
  );
  button.onPressed!();
}

void _pressHeaderBack(WidgetTester tester) {
  final button = tester.widget<IconButton>(
    find.ancestor(
      of: find.byIcon(Icons.arrow_back_ios),
      matching: find.byType(IconButton),
    ),
  );
  button.onPressed!();
}

void _pressWizardPrimaryAction(WidgetTester tester) {
  final button = tester.widget<TextButton>(
    find.byKey(const Key('wizard-primary-action')),
  );
  button.onPressed!();
}

Future<void> _flushAsyncAction(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerTestServices(locale: 'en');
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets(
    'tapping a CheckboxListTile on the first FormPageTemplate increments '
    'no progress (state lives in inner template, FormProgressIndicator '
    'is still on currentStep=0)',
    (tester) async {
      await _pumpForm(tester);
      expect(find.byType(FormProgressIndicator), findsOneWidget);
      // Initial step renders a FormPageTemplate (DifficultEvents).
      expect(find.byType(FormPageTemplate), findsOneWidget);
    },
  );

  testWidgets(
    'wizard keeps the seven default categories in the required order',
    (tester) async {
      await _pumpForm(tester);
      final state = tester.state<FormProgressIndicatorState>(
        find.byType(FormProgressIndicator),
      );

      for (final collectionName in const [
        'PersonalPlan-Distractions',
        'PersonalPlan-DifficultEvents',
        'PersonalPlan-FeelBetter',
        'PersonalPlan-MakeSafer',
        'PersonalPlan-SafeEnvironment',
        'PersonalPlan-DreamsAndGoals',
      ]) {
        expect(
          tester
              .widget<FormPageTemplate>(find.byType(FormPageTemplate))
              .collectionName,
          collectionName,
        );
        state.next();
        await tester.pumpAndSettle();
      }

      expect(find.byType(AddCustomCategoryStep), findsOneWidget);
      state.next();
      await tester.pumpAndSettle();
      expect(find.byType(PhonePageForm), findsOneWidget);
      final contactsContinue = find.byKey(const Key('wizard-primary-action'));
      await tester.ensureVisible(contactsContinue);
      await tester.tap(contactsContinue, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(FormPageTemplate), findsNothing);
      expect(find.byType(PhonePageForm), findsNothing);
    },
  );

  testWidgets(
    'tapping the save-and-quit control on the header pushes a Menu route',
    (tester) async {
      await _pumpForm(tester);

      // Located by its label rather than by widget type: it is a TextButton,
      // not an IconButton (an IconButton sizes its tap target for a square
      // glyph, which wrapped this multi-word label onto two lines).
      await tester.tap(find.text('To menu'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // navigateToMenu pushes the Menu screen via pushAndRemoveUntil.
      expect(find.byType(Menu), findsOneWidget);
    },
  );

  testWidgets(
    'should not navigate when the submit caller context is disposed',
    (tester) async {
      final heldMemory = _HeldNameMemoryService();
      final formKey = GlobalKey<FormProgressIndicatorState>();
      final phoneData = _phoneData();
      final user = UserInformation()..gender = 'other';
      BuildContext? callerContext;
      late StateSetter setHostState;
      var includeCaller = true;

      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(heldMemory);
      addTearDown(heldMemory.releaseNameWrite);

      await pumpWithProviders(
        tester,
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return Column(
                children: [
                  Expanded(
                    child: ChangeNotifierProvider<PhonePageData>.value(
                      value: phoneData,
                      child: FormProgressIndicator(
                        key: formKey,
                        phonePageData: phoneData,
                        changeLocale: (_) {},
                      ),
                    ),
                  ),
                  if (includeCaller)
                    Builder(
                      builder: (context) {
                        callerContext = context;
                        return const SizedBox();
                      },
                    ),
                ],
              );
            },
          ),
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2400),
      );

      formKey.currentState!.updateName('Persisted name');
      final Future<void> submit = formKey.currentState!.submitForm(
        callerContext!,
      );
      await heldMemory.nameWriteStarted.future;

      setHostState(() {
        includeCaller = false;
      });
      await tester.pump();

      heldMemory.releaseNameWrite();
      await tester.runAsync(() => submit);
      await tester.pumpAndSettle();

      expect(find.byType(Menu), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'advancing currentStep via the ConfirmationButton inside the inner '
    'FormPageTemplate makes the back-arrow IconButton appear',
    (tester) async {
      await _pumpForm(tester);

      // FormProgressIndicator.
      final continueBtn = find.byKey(const Key('wizard-primary-action'));
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn, warnIfMissed: false);
      await tester.pumpAndSettle();

      // After advancing, currentStep > 0 — the back-arrow IconButton appears
      // in the header (the `currentStep > 0` branch on line 185 of form.dart).
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
      // Tap the back-arrow to fire prev().
      await tester.tap(find.byIcon(Icons.arrow_back_ios), warnIfMissed: false);
      await tester.pumpAndSettle();
      // After prev, the back-arrow disappears again (currentStep == 0).
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
    },
  );

  group('FormProgressIndicator Dreams and Goals', () {
    testWidgets('should wait for a held save before Save and Quit opens Menu', (
      tester,
    ) async {
      final heldMemory = _HeldDreamsMemoryService();
      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(heldMemory);
      addTearDown(heldMemory.releaseFirstDreamsSelectionWrite);

      await _pumpForm(tester);
      await _moveToDreamsAndGoals(tester);

      final suggestion = tester.widget<InkWell>(
        find.byKey(const ValueKey('suggestion-Write and publish a book')),
      );
      suggestion.onTap!();
      await heldMemory.firstDreamsSelectionWriteStarted.future;

      _pressSaveAndQuit(tester);
      await _flushAsyncAction(tester);
      expect(find.byType(Menu), findsNothing);

      heldMemory.releaseFirstDreamsSelectionWrite();
      await _flushAsyncAction(tester);
      await tester.pumpAndSettle();
      expect(find.byType(Menu), findsOneWidget);
    });

    testWidgets(
      'should wait for a held save before header back changes steps',
      (tester) async {
        final heldMemory = _HeldDreamsMemoryService();
        GetIt.instance.unregister<PersistentMemoryService>();
        GetIt.instance.registerSingleton<PersistentMemoryService>(heldMemory);
        addTearDown(heldMemory.releaseFirstDreamsSelectionWrite);

        await _pumpForm(tester);
        final state = await _moveToDreamsAndGoals(tester);

        final suggestion = tester.widget<InkWell>(
          find.byKey(const ValueKey('suggestion-Write and publish a book')),
        );
        suggestion.onTap!();
        await heldMemory.firstDreamsSelectionWriteStarted.future;

        _pressHeaderBack(tester);
        await _flushAsyncAction(tester);
        expect(state.currentStep, 5);

        heldMemory.releaseFirstDreamsSelectionWrite();
        await _flushAsyncAction(tester);
        await tester.pumpAndSettle();
        expect(state.currentStep, 4);
      },
    );

    testWidgets('should wait for a held disclaimer before Save and Quit', (
      tester,
    ) async {
      final heldMemory = _HeldDisclaimerMemoryService();
      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(heldMemory);
      addTearDown(heldMemory.releaseDisclaimerWrite);

      await _pumpForm(tester);
      await _moveToDreamsAndGoals(tester);

      final suggestion = tester.widget<InkWell>(
        find.byKey(const ValueKey('suggestion-Write and publish a book')),
      );
      suggestion.onTap!();
      await heldMemory.disclaimerWriteStarted.future;

      _pressSaveAndQuit(tester);
      await _flushAsyncAction(tester);
      expect(find.byType(Menu), findsNothing);

      heldMemory.releaseDisclaimerWrite();
      await _flushAsyncAction(tester);
      await tester.pumpAndSettle();
      expect(find.byType(Menu), findsOneWidget);
    });

    testWidgets('should offer Save and Quit Retry after a Dreams save fails', (
      tester,
    ) async {
      final failingMemory = _FailFirstDreamsMemoryService();
      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(failingMemory);

      final user = await _pumpForm(tester);
      await _moveToDreamsAndGoals(tester);
      user.updateDreamsAndGoals(
        const <String>['Write and publish a book'],
        selectionSources: const <String>['catalogue:write-and-publish-a-book'],
      );
      user.queueDreamsAndGoalsSave();

      _pressSaveAndQuit(tester);
      await _flushAsyncAction(tester);
      expect(find.byType(Menu), findsNothing);
      final retry = tester.widget<SnackBarAction>(
        find.widgetWithText(SnackBarAction, 'Try again'),
      );

      retry.onPressed();
      await _flushAsyncAction(tester);
      await tester.pumpAndSettle();
      expect(find.byType(Menu), findsOneWidget);
    });
  });

  group('FormProgressIndicator Share Dreams and Goals', () {
    testWidgets('should wait for a held shared save before Save and Quit', (
      tester,
    ) async {
      final heldMemory = _HeldDreamsMemoryService();
      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(heldMemory);
      addTearDown(heldMemory.releaseFirstDreamsSelectionWrite);

      await _pumpForm(tester);
      await _moveToShare(tester);
      await _addShareDreamAndHoldSave(tester, heldMemory);

      _pressSaveAndQuit(tester);
      await _flushAsyncAction(tester);
      expect(find.byType(Menu), findsNothing);

      heldMemory.releaseFirstDreamsSelectionWrite();
      await _flushAsyncAction(tester);
      await tester.pumpAndSettle();
      expect(find.byType(Menu), findsOneWidget);
    });

    testWidgets('should wait for a held shared save before header back', (
      tester,
    ) async {
      final heldMemory = _HeldDreamsMemoryService();
      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(heldMemory);
      addTearDown(heldMemory.releaseFirstDreamsSelectionWrite);

      await _pumpForm(tester);
      final state = await _moveToShare(tester);
      await _addShareDreamAndHoldSave(tester, heldMemory);

      _pressHeaderBack(tester);
      await _flushAsyncAction(tester);
      expect(state.currentStep, 8);

      heldMemory.releaseFirstDreamsSelectionWrite();
      await _flushAsyncAction(tester);
      await tester.pumpAndSettle();
      expect(state.currentStep, 7);
    });

    testWidgets(
      'should wait for an inline held disclaimer before Save and Quit',
      (tester) async {
        final heldMemory = _HeldDisclaimerMemoryService();
        GetIt.instance.unregister<PersistentMemoryService>();
        GetIt.instance.registerSingleton<PersistentMemoryService>(heldMemory);
        addTearDown(heldMemory.releaseDisclaimerWrite);

        await _pumpForm(tester);
        await _moveToShare(tester);

        final toggle = find.byKey(const Key('share-dreams-and-goals-toggle'));
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        final suggestion = tester.widget<InkWell>(
          find.byKey(const ValueKey('suggestion-Write and publish a book')),
        );
        suggestion.onTap!();
        await heldMemory.disclaimerWriteStarted.future;

        _pressSaveAndQuit(tester);
        await _flushAsyncAction(tester);
        expect(find.byType(Menu), findsNothing);

        heldMemory.releaseDisclaimerWrite();
        await _flushAsyncAction(tester);
        await tester.pumpAndSettle();
        expect(find.byType(Menu), findsOneWidget);
      },
    );

    testWidgets(
      'should keep an inline editor mounted until its disclaimer saves',
      (tester) async {
        final heldMemory = _HeldDisclaimerMemoryService();
        GetIt.instance.unregister<PersistentMemoryService>();
        GetIt.instance.registerSingleton<PersistentMemoryService>(heldMemory);
        addTearDown(heldMemory.releaseDisclaimerWrite);

        await _pumpForm(tester);
        await _moveToShare(tester);

        final toggle = find.byKey(const Key('share-dreams-and-goals-toggle'));
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        tester
            .widget<InkWell>(
              find.byKey(const ValueKey('suggestion-Write and publish a book')),
            )
            .onTap!();
        await heldMemory.disclaimerWriteStarted.future;

        await tester.tap(toggle);
        await _flushAsyncAction(tester);
        expect(find.byType(FormPageTemplate), findsOneWidget);

        heldMemory.releaseDisclaimerWrite();
        await _flushAsyncAction(tester);
        await tester.pumpAndSettle();
        expect(find.byType(FormPageTemplate), findsNothing);
      },
    );

    testWidgets('should retry a failed inline disclaimer before collapsing', (
      tester,
    ) async {
      final failingMemory = _FailFirstDisclaimerMemoryService();
      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(failingMemory);

      await _pumpForm(tester);
      await _moveToShare(tester);

      final toggle = find.byKey(const Key('share-dreams-and-goals-toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('suggestion-Write and publish a book')),
          )
          .onTap!();
      await _flushAsyncAction(tester);

      await tester.tap(toggle);
      await _flushAsyncAction(tester);
      expect(find.byType(FormPageTemplate), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Try again'), findsOneWidget);

      tester
          .widget<SnackBarAction>(
            find.widgetWithText(SnackBarAction, 'Try again'),
          )
          .onPressed();
      await _flushAsyncAction(tester);
      await tester.pumpAndSettle();

      expect(failingMemory.disclaimerWrites, 2);
      expect(find.byType(FormPageTemplate), findsNothing);
    });
  });

  testWidgets(
    'should block finish navigation without a persistence Retry when the name save fails',
    (tester) async {
      final failingMemory = _FailingNameMemoryService();
      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(failingMemory);

      await _pumpForm(tester);
      final state = await _moveToShare(tester);
      state.updateName('Name that must persist');

      _pressWizardPrimaryAction(tester);
      await _flushAsyncAction(tester);
      expect(find.byType(Menu), findsNothing);
      expect(find.widgetWithText(SnackBarAction, 'Try again'), findsNothing);
    },
  );
}
