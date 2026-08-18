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
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/global_enums.dart';
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
    final storedDreams = await memory.getItem(
      _dreamsAndGoalsSelectionKey,
      PersistentMemoryType.StringList,
    );
    dreamsAtDownload = List<String>.from(storedDreams as Iterable);
    return 'downloaded-plan.pdf';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServiceLocators services;
  late UserInformation user;

  setUp(() {
    services = registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(() {
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
          submit: (_) {},
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 1800),
    );

    // The share icon is the first IconButton.
    final shareIcon = find.byIcon(Icons.share);
    expect(shareIcon, findsOneWidget);
    await tester.tap(shareIcon, warnIfMissed: false);
    await tester.pumpAndSettle();
    // showShareDialog opens an AlertDialog/Dialog from
    // util/Share/show_share_dialog.dart — verify a Dialog mounted without
    // crashing.
    expect(find.byType(Dialog), findsWidgets);
  });

  testWidgets('tapping the download IconButton invokes FileService.download '
      '(null result → toast)', (tester) async {
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

    final downloadIcon = find.byIcon(Icons.download);
    expect(downloadIcon, findsOneWidget);
    await tester.tap(downloadIcon, warnIfMissed: false);
    // The download future + toast both schedule timers via showToast →
    // FlutterToast platform channel — drain a tick.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(services.files.downloadCalls, 1);
  });

  group('ShareForm', () {
    testWidgets('should persist a just-selected dream before exporting', (
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

      await _openDreamsAndGoalsAndAddOwnGoal(tester);
      expect(user.dreamsAndGoals, ['Immediate dream']);
      expect(delayedMemory.firstSelectionWriteStarted, isTrue);

      final downloadIcon = find.byIcon(Icons.download);
      await tester.ensureVisible(downloadIcon);
      await tester.tap(downloadIcon);
      await tester.pumpAndSettle();

      expect(exportFiles.dreamsAtDownload, ['Immediate dream']);
      expect(
        delayedMemory.store[_dreamsAndGoalsAddedStringsKey],
        ['Immediate dream'],
      );
      expect(
        delayedMemory.store[_dreamsAndGoalsSelectionSourcesKey],
        ['custom'],
      );

      delayedMemory.releaseFirstSelectionWrite();
    });

    testWidgets('should persist a just-selected dream before finishing', (
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
      addTearDown(delayedMemory.releaseFirstSelectionWrite);

      await pumpWithProviders(
        tester,
        wizardStepHarness(
          ShareForm(
            key: GlobalKey<WizardStepState>(),
            prev: () {},
            submit: (_) {
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

      delayedMemory.store[_dreamsAndGoalsSelectionKey] = <String>[];
      delayedMemory.store[_dreamsAndGoalsAddedStringsKey] = <String>[];
      delayedMemory.store[_dreamsAndGoalsSelectionSourcesKey] = <String>[];

      final finishButton = find.byKey(const Key('wizard-primary-action'));
      await tester.ensureVisible(finishButton);
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      expect(dreamsAtSubmit, ['Immediate dream']);
      expect(
        delayedMemory.store[_dreamsAndGoalsAddedStringsKey],
        ['Immediate dream'],
      );
      expect(delayedMemory.store[_dreamsAndGoalsSelectionSourcesKey], ['custom']);

      delayedMemory.releaseFirstSelectionWrite();
    });
  });

  testWidgets('tapping the finish button calls widget.submit with context', (
    tester,
  ) async {
    var submitCalls = 0;
    await pumpWithProviders(
      tester,
      wizardStepHarness(
        ShareForm(
          key: GlobalKey<WizardStepState>(),
          prev: () {},
          submit: (_) => submitCalls++,
        ),
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 1800),
    );

    final finishButton = find.ancestor(
      of: find.text("I'm Done!"),
      matching: find.byType(TextButton),
    );
    expect(finishButton, findsOneWidget);
    await tester.ensureVisible(finishButton);
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    expect(submitCalls, 1);
  });
}
