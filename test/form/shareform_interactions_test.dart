// Drives the IconButton onPressed handlers on ShareForm:
//   - share icon → invokes showShareDialog (lines 103-104)
//   - download icon → invokes fileService.download with the localized
//     headers, then dispatches a toast (lines 123-147)
//   - the finish button calls widget.submit
//
// We register a recording FileService fake via the shared scaffold to assert
// download() was called and to drive both the null-return (failure) and
// the success branches.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

const _dreamsAndGoalsSelectionKey =
    'userSelectionPersonalPlan-DreamsAndGoals';
const _dreamsAndGoalsAddedStringsKey =
    'addedStringsPersonalPlan-DreamsAndGoals';
const _dreamsAndGoalsSelectionSourcesKey =
    'selectionSourcesPersonalPlan-DreamsAndGoals';

class _DelayedDreamsMemoryService extends FakePersistentMemoryService {
  final Completer<void> _firstSelectionWrite = Completer<void>();
  bool firstSelectionWriteStarted = false;

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (key == _dreamsAndGoalsSelectionKey && !firstSelectionWriteStarted) {
      firstSelectionWriteStarted = true;
      await _firstSelectionWrite.future;
    }
    await super.setItem(key, type, value);
  }

  void releaseFirstSelectionWrite() {
    if (!_firstSelectionWrite.isCompleted) {
      _firstSelectionWrite.complete();
    }
  }
}

class _ExportReadingFileService extends NoopFileService {
  _ExportReadingFileService(this.memory);

  final PersistentMemoryService memory;
  List<String> dreamsAtDownload = const [];

  @override
  Future<String?> download(
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat, {
    required String mainTitle,
    required String textDirection,
  }) async {
    downloadCalls++;
    final storedDreams = await memory.getItem(
      _dreamsAndGoalsSelectionKey,
      PersistentMemoryType.StringList,
    );
    dreamsAtDownload = List<String>.from(storedDreams as Iterable);
    return 'downloaded-plan.pdf';
  }
}

class _FailingDreamsMemoryService extends FakePersistentMemoryService {
  bool failDreamsSelection = true;

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (key == _dreamsAndGoalsSelectionKey && failDreamsSelection) {
      throw StateError('Dreams persistence failed.');
    }
    await super.setItem(key, type, value);
  }
}

Future<void> _openDreamsAndGoalsAndAddOwnGoal(WidgetTester tester) async {
  final dreamsToggle = find.byKey(const Key('share-dreams-and-goals-toggle'));
  await tester.ensureVisible(dreamsToggle);
  await tester.tap(dreamsToggle);
  await tester.pumpAndSettle();

  final addOwn = find.text('Add my own personal dream or goal...');
  await tester.ensureVisible(addOwn);
  await tester.tap(addOwn);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), 'Immediate dream');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void _pressIconButton(WidgetTester tester, IconData icon) {
  final Finder iconFinder = find.byIcon(icon);
  final IconButton button = tester.widget<IconButton>(
    find.ancestor(of: iconFinder, matching: find.byType(IconButton)),
  );
  button.onPressed!();
}

Future<void> _pressIconButtonInAsyncZone(
  WidgetTester tester,
  IconData icon,
) async {
  final Finder iconFinder = find.byIcon(icon);
  final IconButton button = tester.widget<IconButton>(
    find.ancestor(of: iconFinder, matching: find.byType(IconButton)),
  );
  await tester.runAsync(() async {
    button.onPressed!();
    await Future<void>.delayed(Duration.zero);
  });
}

void _pressWizardPrimaryAction(WidgetTester tester) {
  final button = tester.widget<TextButton>(
    find.byKey(const Key('wizard-primary-action')),
  );
  button.onPressed!();
}

Future<void> _flushAsyncAction(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const toastChannel = MethodChannel('PonnamKarthik/fluttertoast');
  late TestServiceLocators services;
  late UserInformation user;

  setUp(() {
    services = registerTestServices(locale: 'en');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (_) async => true);
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, null);
    resetTestServices();
  });

  testWidgets('tapping the share IconButton opens the share dialog', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      wizardStepHarness(
        ShareForm(
          key: GlobalKey<WizardStepState>(),
          prev: () {},
          submit: (_) async {},
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 1800),
    );

    // The share icon is the first IconButton.
    final shareIcon = find.byIcon(Icons.share);
    expect(shareIcon, findsOneWidget);
    await _pressIconButtonInAsyncZone(tester, Icons.share);
    await _flushAsyncAction(tester);
    await tester.pumpAndSettle();
    expect(find.byType(LPShareAlertDialog), findsOneWidget);
  });

  testWidgets('tapping the download IconButton invokes FileService.download '
      '(null result → toast)', (tester) async {
    await pumpWithProviders(
      tester,
      wizardStepHarness(
        ShareForm(
          key: GlobalKey<WizardStepState>(),
          prev: () {},
          submit: (_) async {},
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 1800),
    );

    final downloadIcon = find.byIcon(Icons.download);
    expect(downloadIcon, findsOneWidget);
    await _pressIconButtonInAsyncZone(tester, Icons.download);
    await _flushAsyncAction(tester);

    expect(services.files.downloadCalls, 1);
    await tester.pump(const Duration(seconds: 2));
  });

  group('ShareForm', () {
    testWidgets(
      'should persist has-filled through the injected UserInformation service',
      (tester) async {
        final injectedMemory = FakePersistentMemoryService();
        user = UserInformation(service: injectedMemory)
          ..gender = 'other'
          ..localeName = 'en';

        await pumpWithProviders(
          tester,
          wizardStepHarness(
            ShareForm(
              key: GlobalKey<WizardStepState>(),
              prev: () {},
              submit: (_) {},
            ),
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 1800),
        );
        await _flushAsyncAction(tester);

        expect(injectedMemory.store['hasFilled'], isTrue);
        expect(services.memory.store['hasFilled'], isNull);
      },
    );

    testWidgets(
      'should not show a persistence Retry when the finish action fails',
      (tester) async {
        var actionCalls = 0;
        final stepKey = GlobalKey<WizardStepState>();

        await pumpWithProviders(
          tester,
          wizardStepHarness(
            ShareForm(
              key: stepKey,
              prev: () {},
              submit: (_) {
                actionCalls++;
                throw StateError('finish action failed');
              },
            ),
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 1800),
        );

        await tester.runAsync(() async {
          await expectLater(
            stepKey.currentState!.onPrimaryAction(),
            throwsA(
              isA<StateError>().having(
                (StateError error) => error.message,
                'message',
                'finish action failed',
              ),
            ),
          );
        });
        await tester.pump();

        expect(actionCalls, 1);
        expect(find.widgetWithText(SnackBarAction, 'Try again'), findsNothing);
      },
    );

    testWidgets('should wait for the latest shared dream snapshot before exporting', (
      tester,
    ) async {
      final delayedMemory = _DelayedDreamsMemoryService();
      final exportFiles = _ExportReadingFileService(delayedMemory);
      final locator = GetIt.instance;
      locator.unregister<PersistentMemoryService>();
      locator.unregister<FileService>();
      locator.registerSingleton<PersistentMemoryService>(delayedMemory);
      locator.registerSingleton<FileService>(exportFiles);
      addTearDown(delayedMemory.releaseFirstSelectionWrite);
      user = UserInformation(service: delayedMemory)
        ..gender = 'other'
        ..localeName = 'en';

      await pumpWithProviders(
        tester,
        wizardStepHarness(
          ShareForm(
            key: GlobalKey<WizardStepState>(),
            prev: () {},
            submit: (_) async {},
          ),
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 1800),
      );

      await _openDreamsAndGoalsAndAddOwnGoal(tester);
      expect(user.dreamsAndGoals, ['Immediate dream']);
      expect(delayedMemory.firstSelectionWriteStarted, isTrue);

      final suggestion = tester.widget<InkWell>(
        find.byKey(const ValueKey('suggestion-Write and publish a book')),
      );
      suggestion.onTap!();
      await tester.pump();

      _pressIconButton(tester, Icons.download);
      await _flushAsyncAction(tester);
      expect(exportFiles.downloadCalls, 0);

      delayedMemory.releaseFirstSelectionWrite();
      await _flushAsyncAction(tester);

      expect(exportFiles.downloadCalls, 1);
      expect(exportFiles.dreamsAtDownload, [
        'Immediate dream',
        'Write and publish a book',
      ]);
      expect(
        delayedMemory.store[_dreamsAndGoalsAddedStringsKey],
        ['Immediate dream'],
      );
      expect(
        delayedMemory.store[_dreamsAndGoalsSelectionSourcesKey],
        ['custom', 'catalogue:write-and-publish-a-book'],
      );
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('should wait for the latest shared dream snapshot before finishing', (
      tester,
    ) async {
      final delayedMemory = _DelayedDreamsMemoryService();
      final exportFiles = _ExportReadingFileService(delayedMemory);
      List<String>? dreamsAtSubmit;
      final locator = GetIt.instance;
      locator.unregister<PersistentMemoryService>();
      locator.unregister<FileService>();
      locator.registerSingleton<PersistentMemoryService>(delayedMemory);
      locator.registerSingleton<FileService>(exportFiles);
      user = UserInformation(service: delayedMemory)
        ..gender = 'other'
        ..localeName = 'en';
      addTearDown(delayedMemory.releaseFirstSelectionWrite);

      await pumpWithProviders(
        tester,
        wizardStepHarness(
          ShareForm(
            key: GlobalKey<WizardStepState>(),
            prev: () {},
            submit: (_) async {
              dreamsAtSubmit = List<String>.from(
                delayedMemory.store[_dreamsAndGoalsSelectionKey] as Iterable,
              );
            },
          ),
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 1800),
      );

      await _openDreamsAndGoalsAndAddOwnGoal(tester);
      expect(delayedMemory.firstSelectionWriteStarted, isTrue);

      final suggestion = tester.widget<InkWell>(
        find.byKey(const ValueKey('suggestion-Write and publish a book')),
      );
      suggestion.onTap!();
      await tester.pump();

      _pressWizardPrimaryAction(tester);
      await _flushAsyncAction(tester);
      expect(dreamsAtSubmit, isNull);

      delayedMemory.releaseFirstSelectionWrite();
      await _flushAsyncAction(tester);

      expect(dreamsAtSubmit, [
        'Immediate dream',
        'Write and publish a book',
      ]);
      expect(
        delayedMemory.store[_dreamsAndGoalsAddedStringsKey],
        ['Immediate dream'],
      );
      expect(delayedMemory.store[_dreamsAndGoalsSelectionSourcesKey], [
        'custom',
        'catalogue:write-and-publish-a-book',
      ]);
    });

    testWidgets(
      'should block download and finish on a save failure until Retry succeeds',
      (tester) async {
        final failingMemory = _FailingDreamsMemoryService();
        final exportFiles = _ExportReadingFileService(failingMemory);
        final locator = GetIt.instance;
        locator.unregister<PersistentMemoryService>();
        locator.unregister<FileService>();
        locator.registerSingleton<PersistentMemoryService>(failingMemory);
        locator.registerSingleton<FileService>(exportFiles);
        user = UserInformation(service: failingMemory)
          ..gender = 'other'
          ..localeName = 'en';
        var submitCalls = 0;

        await pumpWithProviders(
          tester,
          wizardStepHarness(
            ShareForm(
              key: GlobalKey<WizardStepState>(),
              prev: () {},
              submit: (_) async {
                submitCalls++;
              },
            ),
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 1800),
        );

        _pressIconButton(tester, Icons.download);
        await _flushAsyncAction(tester);
        expect(exportFiles.downloadCalls, 0);
        expect(
          find.widgetWithText(SnackBarAction, 'Try again'),
          findsOneWidget,
        );

        failingMemory.failDreamsSelection = false;
        tester
            .widget<SnackBarAction>(
              find.widgetWithText(SnackBarAction, 'Try again'),
            )
            .onPressed();
        await _flushAsyncAction(tester);
        expect(exportFiles.downloadCalls, 1);

        failingMemory.failDreamsSelection = true;
        _pressWizardPrimaryAction(tester);
        await _flushAsyncAction(tester);
        expect(submitCalls, 0);
        expect(
          find.widgetWithText(SnackBarAction, 'Try again'),
          findsOneWidget,
        );

        failingMemory.failDreamsSelection = false;
        tester
            .widget<SnackBarAction>(
              find.widgetWithText(SnackBarAction, 'Try again'),
            )
            .onPressed();
        await _flushAsyncAction(tester);
        expect(submitCalls, 1);
        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets(
      'should log a failed persistence Retry before offering it again',
      (tester) async {
        final failingMemory = _FailingDreamsMemoryService();
        final locator = GetIt.instance;
        locator.unregister<PersistentMemoryService>();
        locator.registerSingleton<PersistentMemoryService>(failingMemory);
        user = UserInformation(service: failingMemory)
          ..gender = 'other'
          ..localeName = 'en';

        await pumpWithProviders(
          tester,
          wizardStepHarness(
            ShareForm(
              key: GlobalKey<WizardStepState>(),
              prev: () {},
              submit: (_) {},
            ),
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 1800),
        );

        _pressIconButton(tester, Icons.download);
        await _flushAsyncAction(tester);
        tester
            .widget<SnackBarAction>(
              find.widgetWithText(SnackBarAction, 'Try again'),
            )
            .onPressed();
        await _flushAsyncAction(tester);

        expect(services.logger.captured, isNotEmpty);
        expect(services.logger.captured.last, isA<StateError>());
        expect(
          find.widgetWithText(SnackBarAction, 'Try again'),
          findsOneWidget,
        );
      },
    );

  });

  testWidgets('should support a synchronous submit callback', (
    tester,
  ) async {
    var submitCalls = 0;
    final stepKey = GlobalKey<WizardStepState>();
    await pumpWithProviders(
      tester,
      wizardStepHarness(
        ShareForm(
          key: stepKey,
          prev: () {},
          submit: (_) {
            submitCalls++;
          },
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 1800),
    );

    await tester.runAsync(() => stepKey.currentState!.onPrimaryAction());

    expect(submitCalls, 1);
  });

  testWidgets('should await an asynchronous submit callback', (tester) async {
    final Completer<void> completion = Completer<void>();
    final stepKey = GlobalKey<WizardStepState>();
    var submitCalls = 0;
    var actionCompleted = false;

    await pumpWithProviders(
      tester,
      wizardStepHarness(
        ShareForm(
          key: stepKey,
          prev: () {},
          submit: (_) async {
            submitCalls++;
            await completion.future;
          },
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 1800),
    );

    late Future<void> action;
    await tester.runAsync(() async {
      action = stepKey.currentState!.onPrimaryAction().then((_) {
        actionCompleted = true;
      });
      await Future<void>.delayed(Duration.zero);
    });

    expect(submitCalls, 1);
    expect(actionCompleted, isFalse);

    completion.complete();
    await tester.runAsync(() => action);

    expect(actionCompleted, isTrue);
  });
}
