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
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Share/LP_share_alert_dialog.dart';
import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';
import 'package:share_plus/share_plus.dart';

import '../helpers/widget_test_scaffold.dart';
import 'shareform_test.mocks.dart' as shareform_mocks;

const _dreamsAndGoalsSelectionKey = 'userSelectionPersonalPlan-DreamsAndGoals';
const _dreamsAndGoalsAddedStringsKey =
    'addedStringsPersonalPlan-DreamsAndGoals';
const _dreamsAndGoalsSelectionSourcesKey =
    'selectionSourcesPersonalPlan-DreamsAndGoals';
const _customCategoriesKey = 'customCategories';
const _customCategoryTitlesKey = 'customCategoryTitles';
const _customCategoryDescriptionsKey = 'customCategoryDescriptions';
const _customCategoriesLegacyCommitKey = 'customCategoriesLegacyCommit';
const _dreamsAndGoalsPersistenceKeys = <String>[
  _dreamsAndGoalsSelectionKey,
  _dreamsAndGoalsSelectionSourcesKey,
  _dreamsAndGoalsAddedStringsKey,
];

class _MockPersistentMemoryService
    extends shareform_mocks.MockPersistentMemoryService {}

class _MemoryWrite {
  _MemoryWrite(this.key, this.type, dynamic value)
    : value = type == PersistentMemoryType.StringList
          ? List<String>.from(value as Iterable)
          : value;

  final String key;
  final PersistentMemoryType type;
  final dynamic value;
}

class _DreamsMemoryHarness {
  _DreamsMemoryHarness({
    List<String> initialSelections = const <String>[],
    List<String> initialSelectionSources = const <String>[],
    List<String> initialCustomItems = const <String>[],
    List<String> initialCustomCategoryTitles = const <String>[],
    List<String> initialCustomCategoryDescriptions = const <String>[],
    this.delayFirstSelectionWrite = false,
  }) : _initialSelections = List<String>.from(initialSelections),
       _initialSelectionSources = List<String>.from(initialSelectionSources),
       _initialCustomItems = List<String>.from(initialCustomItems),
       _initialCustomCategoryTitles = List<String>.from(
         initialCustomCategoryTitles,
       ),
       _initialCustomCategoryDescriptions = List<String>.from(
         initialCustomCategoryDescriptions,
       ) {
    when(service.setItem(any, any, any)).thenAnswer(_setItem);
    when(service.getItem(any, any)).thenAnswer(_getItem);
    when(service.reset()).thenAnswer((_) async {});
  }

  final _MockPersistentMemoryService service = _MockPersistentMemoryService();
  final List<String> _initialSelections;
  final List<String> _initialSelectionSources;
  final List<String> _initialCustomItems;
  final List<String> _initialCustomCategoryTitles;
  final List<String> _initialCustomCategoryDescriptions;
  final Completer<void> _firstSelectionWrite = Completer<void>();
  final List<_MemoryWrite> completedWrites = <_MemoryWrite>[];
  final List<String> readKeys = <String>[];
  final bool delayFirstSelectionWrite;
  bool firstSelectionWriteStarted = false;
  bool failSelectionWrite = false;
  bool failAllDreamsWrites = false;

  Future<void> _setItem(Invocation invocation) async {
    final String key = invocation.positionalArguments[0] as String;
    final PersistentMemoryType type =
        invocation.positionalArguments[1] as PersistentMemoryType;
    final dynamic value = invocation.positionalArguments[2];
    if (key == _dreamsAndGoalsSelectionKey &&
        delayFirstSelectionWrite &&
        !firstSelectionWriteStarted) {
      firstSelectionWriteStarted = true;
      await _firstSelectionWrite.future;
    }
    final bool isDreamsAndGoalsKey = _dreamsAndGoalsPersistenceKeys.contains(
      key,
    );
    if ((key == _dreamsAndGoalsSelectionKey && failSelectionWrite) ||
        (isDreamsAndGoalsKey && failAllDreamsWrites)) {
      throw StateError('Dreams persistence failed.');
    }
    completedWrites.add(_MemoryWrite(key, type, value));
  }

  void releaseFirstSelectionWrite() {
    if (!_firstSelectionWrite.isCompleted) {
      _firstSelectionWrite.complete();
    }
  }

  Future<dynamic> _getItem(Invocation invocation) async {
    final String key = invocation.positionalArguments[0] as String;
    final PersistentMemoryType type =
        invocation.positionalArguments[1] as PersistentMemoryType;
    readKeys.add(key);
    if (key == _customCategoriesKey) {
      if (type != PersistentMemoryType.String) {
        throw StateError('Unexpected PersistentMemoryService read type: $type');
      }
      for (final _MemoryWrite write in completedWrites.reversed) {
        if (write.key == key && write.type == PersistentMemoryType.String) {
          return write.value as String?;
        }
      }
      return null;
    }
    if (key == _customCategoriesLegacyCommitKey) {
      if (type != PersistentMemoryType.String) {
        throw StateError('Unexpected PersistentMemoryService read type: $type');
      }
      for (final _MemoryWrite write in completedWrites.reversed) {
        if (write.key == key && write.type == PersistentMemoryType.String) {
          return write.value as String?;
        }
      }
      return null;
    }
    if (type != PersistentMemoryType.StringList) {
      throw StateError('Unexpected PersistentMemoryService read type: $type');
    }
    switch (key) {
      case _customCategoryTitlesKey:
        return _latestStringList(key, _initialCustomCategoryTitles);
      case _customCategoryDescriptionsKey:
        return _latestStringList(key, _initialCustomCategoryDescriptions);
      case _dreamsAndGoalsSelectionKey:
        return _latestStringList(key, _initialSelections);
      case _dreamsAndGoalsSelectionSourcesKey:
        return _latestStringList(key, _initialSelectionSources);
      case _dreamsAndGoalsAddedStringsKey:
        return _latestStringList(key, _initialCustomItems);
      default:
        throw StateError('Unexpected PersistentMemoryService read: $key');
    }
  }

  List<String> _latestStringList(String key, List<String> fallback) {
    for (final _MemoryWrite write in completedWrites.reversed) {
      if (write.key == key && write.type == PersistentMemoryType.StringList) {
        return List<String>.from(write.value as Iterable);
      }
    }
    return List<String>.from(fallback);
  }

  List<String> completedStringList(String key) {
    return _latestStringList(key, const <String>[]);
  }

  List<_MemoryWrite> completedWritesFor(String key) {
    return completedWrites.where((write) => write.key == key).toList();
  }

  List<String> completedDreamsAndGoalsWriteKeys() {
    return completedWrites
        .where((write) => _dreamsAndGoalsPersistenceKeys.contains(write.key))
        .map((write) => write.key)
        .toList(growable: false);
  }
}

class _ExportReadingFileService extends NoopFileService {
  _ExportReadingFileService(this.memory);

  final PersistentMemoryService memory;
  PersistentMemoryService? memoryServiceAtDownload;
  List<String> dreamsAtDownload = const [];
  List<String> dreamsSourcesAtDownload = const [];
  List<String> dreamsCustomItemsAtDownload = const [];

  @override
  Future<String?> download(
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat, {
    required String mainTitle,
    required String textDirection,
    PersistentMemoryService? memoryService,
    Set<String>? approvedPdfHosts,
  }) async {
    downloadCalls++;
    memoryServiceAtDownload = memoryService;
    final storedDreams = await memory.getItem(
      _dreamsAndGoalsSelectionKey,
      PersistentMemoryType.StringList,
    );
    final storedSources = await memory.getItem(
      _dreamsAndGoalsSelectionSourcesKey,
      PersistentMemoryType.StringList,
    );
    final storedCustomItems = await memory.getItem(
      _dreamsAndGoalsAddedStringsKey,
      PersistentMemoryType.StringList,
    );
    dreamsAtDownload = List<String>.from(storedDreams as Iterable);
    dreamsSourcesAtDownload = List<String>.from(storedSources as Iterable);
    dreamsCustomItemsAtDownload = List<String>.from(
      storedCustomItems as Iterable,
    );
    return 'downloaded-plan.pdf';
  }
}

class _UnavailableShareFileService extends NoopFileService {
  @override
  Future<ShareResult?> share(
    String message,
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat, {
    required String mainTitle,
    required String textDirection,
    PersistentMemoryService? memoryService,
    Set<String>? approvedPdfHosts,
  }) async {
    shareCalls++;
    return ShareResult.unavailable;
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

void _seedMultipleCustomDreams(UserInformation user) {
  user.updateDreamsAndGoals(
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

  testWidgets(
    'ShareForm forwards its explicit memory service to the share dialog',
    (tester) async {
      final explicitMemory = _DreamsMemoryHarness();

      await pumpWithProviders(
        tester,
        wizardStepHarness(
          ShareForm(
            key: GlobalKey<WizardStepState>(),
            prev: () {},
            submit: (_) async {},
            memoryService: explicitMemory.service,
          ),
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 1800),
      );

      await _pressIconButtonInAsyncZone(tester, Icons.share);
      await _flushAsyncAction(tester);
      await tester.pumpAndSettle();

      final dialog = tester.widget<LPShareAlertDialog>(
        find.byType(LPShareAlertDialog),
      );
      expect(dialog.memoryService, same(explicitMemory.service));
    },
  );

  testWidgets(
    'ShareForm shows localized feedback when Personal Plan file sharing is unavailable',
    (tester) async {
      final unavailableFiles = _UnavailableShareFileService();
      final locator = GetIt.instance;
      locator.unregister<FileService>();
      locator.registerSingleton<FileService>(unavailableFiles);

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
      final localizations = AppLocalizations.of(
        tester.element(find.byType(ShareForm)),
      )!;

      await _pressIconButtonInAsyncZone(tester, Icons.share);
      await _flushAsyncAction(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text(localizations.shareFile));
      await _flushAsyncAction(tester);
      await tester.pumpAndSettle();

      expect(unavailableFiles.shareCalls, 1);
      expect(find.text(localizations.personalPlanShareFailed), findsOneWidget);
    },
  );

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
        final injectedMemory = _DreamsMemoryHarness();
        user = UserInformation(service: injectedMemory.service)
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

        final hasFilledWrites = injectedMemory.completedWritesFor('hasFilled');
        expect(hasFilledWrites, hasLength(1));
        expect(hasFilledWrites.single.type, PersistentMemoryType.Bool);
        expect(hasFilledWrites.single.value, isTrue);
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

    group('Dreams and Goals', () {
      test('should reject unexpected persistence reads', () async {
        final memory = _DreamsMemoryHarness();

        await expectLater(
          memory.service.getItem(
            'unapproved-key',
            PersistentMemoryType.StringList,
          ),
          throwsA(
            isA<StateError>().having(
              (StateError error) => error.message,
              'message',
              'Unexpected PersistentMemoryService read: unapproved-key',
            ),
          ),
        );
      });

      testWidgets(
        'should open and edit multiple custom Dreams without changing their provenance',
        (tester) async {
          final memory = _DreamsMemoryHarness();
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.registerSingleton<PersistentMemoryService>(memory.service);
          user = UserInformation(service: memory.service)
            ..gender = 'other'
            ..localeName = 'en';
          _seedMultipleCustomDreams(user);

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

          final Finder dreamsToggle = find.byKey(
            const Key('share-dreams-and-goals-toggle'),
          );
          await tester.ensureVisible(dreamsToggle);
          await tester.tap(dreamsToggle);
          await tester.pumpAndSettle();

          final Finder addOwn = find.text(
            'Add my own personal dream or goal...',
          );
          final Finder firstCustomDream = find.text('First custom dream');
          expect(find.byType(AlertDialog), findsNothing);
          expect(addOwn, findsOneWidget);
          expect(firstCustomDream, findsOneWidget);
          expect(find.text('Second custom dream'), findsOneWidget);
          expect(
            tester.getTopLeft(addOwn).dy,
            lessThan(tester.getTopLeft(firstCustomDream).dy),
          );

          await tester.ensureVisible(firstCustomDream);
          await tester.tap(firstCustomDream);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField),
            'Edited first custom dream',
          );
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          await _flushAsyncAction(tester);

          expect(user.dreamsAndGoals, const <String>[
            'Write and publish a book',
            'Edited first custom dream',
            'Learn a new language',
            'Second custom dream',
          ]);
          expect(user.dreamsAndGoalsSelectionSources, const <String>[
            'catalogue:write-and-publish-a-book',
            'custom',
            'catalogue:learn-a-new-language',
            'custom',
          ]);
          expect(
            memory.completedStringList(_dreamsAndGoalsSelectionKey),
            user.dreamsAndGoals,
          );
          expect(
            memory.completedStringList(_dreamsAndGoalsSelectionSourcesKey),
            user.dreamsAndGoalsSelectionSources,
          );
          expect(
            memory.completedStringList(_dreamsAndGoalsAddedStringsKey),
            const <String>['Edited first custom dream', 'Second custom dream'],
          );
          expect(find.text('First custom dream'), findsNothing);
          expect(find.text('Edited first custom dream'), findsOneWidget);
          expect(find.text('Second custom dream'), findsOneWidget);
        },
      );

      testWidgets('should open the Share dialog with multiple custom Dreams', (
        tester,
      ) async {
        final memory = _DreamsMemoryHarness();
        final locator = GetIt.instance;
        locator.unregister<PersistentMemoryService>();
        locator.registerSingleton<PersistentMemoryService>(memory.service);
        user = UserInformation(service: memory.service)
          ..gender = 'other'
          ..localeName = 'en';
        _seedMultipleCustomDreams(user);

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

        _pressIconButton(tester, Icons.share);
        await tester.pumpAndSettle();
        expect(find.byType(LPShareAlertDialog), findsOneWidget);
      });

      testWidgets('should download and finish with multiple custom Dreams', (
        tester,
      ) async {
        final memory = _DreamsMemoryHarness();
        final exportFiles = _ExportReadingFileService(memory.service);
        final locator = GetIt.instance;
        locator.unregister<PersistentMemoryService>();
        locator.unregister<FileService>();
        locator.registerSingleton<PersistentMemoryService>(memory.service);
        locator.registerSingleton<FileService>(exportFiles);
        user = UserInformation(service: memory.service)
          ..gender = 'other'
          ..localeName = 'en';
        _seedMultipleCustomDreams(user);
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

        _pressIconButton(tester, Icons.download);
        await _flushAsyncAction(tester);

        expect(exportFiles.downloadCalls, 1);
        expect(exportFiles.dreamsAtDownload, user.dreamsAndGoals);
        expect(
          exportFiles.dreamsSourcesAtDownload,
          user.dreamsAndGoalsSelectionSources,
        );
        expect(exportFiles.dreamsCustomItemsAtDownload, const <String>[
          'First custom dream',
          'Second custom dream',
        ]);

        _pressWizardPrimaryAction(tester);
        for (var attempt = 0; attempt < 10 && submitCalls == 0; attempt++) {
          await _flushAsyncAction(tester);
        }

        expect(submitCalls, 1);
        expect(
          memory.completedStringList(_dreamsAndGoalsAddedStringsKey),
          const <String>['First custom dream', 'Second custom dream'],
        );
        await tester.pump(const Duration(seconds: 2));
      });

      testWidgets(
        'should retry the full multiple-custom snapshot before downloading',
        (tester) async {
          final memory = _DreamsMemoryHarness()..failAllDreamsWrites = true;
          final exportFiles = _ExportReadingFileService(memory.service);
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.unregister<FileService>();
          locator.registerSingleton<PersistentMemoryService>(memory.service);
          locator.registerSingleton<FileService>(exportFiles);
          user = UserInformation(service: memory.service)
            ..gender = 'other'
            ..localeName = 'en';
          _seedMultipleCustomDreams(user);

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

          _pressIconButton(tester, Icons.download);
          await _flushAsyncAction(tester);

          expect(exportFiles.downloadCalls, 0);
          expect(
            find.widgetWithText(SnackBarAction, 'Try again'),
            findsOneWidget,
          );
          expect(user.dreamsAndGoals, const <String>[
            'Write and publish a book',
            'First custom dream',
            'Learn a new language',
            'Second custom dream',
          ]);
          memory.failAllDreamsWrites = false;
          tester
              .widget<SnackBarAction>(
                find.widgetWithText(SnackBarAction, 'Try again'),
              )
              .onPressed();
          await _flushAsyncAction(tester);

          expect(exportFiles.downloadCalls, 1);
          expect(exportFiles.dreamsAtDownload, user.dreamsAndGoals);
          expect(
            exportFiles.dreamsSourcesAtDownload,
            user.dreamsAndGoalsSelectionSources,
          );
          expect(exportFiles.dreamsCustomItemsAtDownload, const <String>[
            'First custom dream',
            'Second custom dream',
          ]);
          expect(
            memory.completedStringList(_dreamsAndGoalsSelectionKey),
            user.dreamsAndGoals,
          );
          expect(
            memory.completedStringList(_dreamsAndGoalsSelectionSourcesKey),
            user.dreamsAndGoalsSelectionSources,
          );
          expect(
            memory.completedStringList(_dreamsAndGoalsAddedStringsKey),
            const <String>['First custom dream', 'Second custom dream'],
          );
          for (final key in <String>[
            _dreamsAndGoalsSelectionKey,
            _dreamsAndGoalsSelectionSourcesKey,
            _dreamsAndGoalsAddedStringsKey,
          ]) {
            expect(memory.completedWritesFor(key), hasLength(1));
          }
          await tester.pump(const Duration(seconds: 2));
        },
      );

      testWidgets(
        'should wait for the latest shared dream snapshot before exporting',
        (tester) async {
          final delayedMemory = _DreamsMemoryHarness(
            delayFirstSelectionWrite: true,
          );
          final exportFiles = _ExportReadingFileService(delayedMemory.service);
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.unregister<FileService>();
          locator.registerSingleton<PersistentMemoryService>(
            delayedMemory.service,
          );
          locator.registerSingleton<FileService>(exportFiles);
          addTearDown(delayedMemory.releaseFirstSelectionWrite);
          user = UserInformation(service: delayedMemory.service)
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
            delayedMemory.completedStringList(_dreamsAndGoalsAddedStringsKey),
            ['Immediate dream'],
          );
          expect(
            delayedMemory.completedStringList(
              _dreamsAndGoalsSelectionSourcesKey,
            ),
            ['custom', 'catalogue:write-and-publish-a-book'],
          );
          await tester.pump(const Duration(seconds: 2));
        },
      );

      testWidgets(
        'should serialize one rapid duplicate download while persistence is delayed',
        (tester) async {
          final memory = _DreamsMemoryHarness(delayFirstSelectionWrite: true);
          final exportFiles = _ExportReadingFileService(memory.service);
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.unregister<FileService>();
          locator.registerSingleton<PersistentMemoryService>(memory.service);
          locator.registerSingleton<FileService>(exportFiles);
          addTearDown(memory.releaseFirstSelectionWrite);
          user = UserInformation(service: memory.service)
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

          _pressIconButton(tester, Icons.download);
          _pressIconButton(tester, Icons.download);
          await _flushAsyncAction(tester);

          expect(memory.firstSelectionWriteStarted, isTrue);
          expect(memory.completedDreamsAndGoalsWriteKeys(), isEmpty);
          expect(exportFiles.downloadCalls, 0);

          memory.releaseFirstSelectionWrite();
          await _flushAsyncAction(tester);

          expect(exportFiles.downloadCalls, 1);
          expect(
            memory.completedDreamsAndGoalsWriteKeys(),
            _dreamsAndGoalsPersistenceKeys,
          );
          await tester.pump(const Duration(seconds: 2));
        },
      );

      testWidgets(
        'should run one Finish while a previous Finish action is in flight',
        (tester) async {
          final Completer<void> finishGate = Completer<void>();
          final GlobalKey<WizardStepState> stepKey =
              GlobalKey<WizardStepState>();
          var submitCalls = 0;

          await pumpWithProviders(
            tester,
            wizardStepHarness(
              ShareForm(
                key: stepKey,
                prev: () {},
                submit: (_) async {
                  submitCalls++;
                  await finishGate.future;
                },
              ),
            ),
            userInformation: user,
            surfaceSize: const Size(1024, 1800),
          );

          _pressWizardPrimaryAction(tester);
          for (var attempt = 0; attempt < 10 && submitCalls == 0; attempt++) {
            await _flushAsyncAction(tester);
          }
          expect(submitCalls, 1);

          final Future<void> duplicateFinish = stepKey.currentState!
              .onPrimaryAction();
          await _flushAsyncAction(tester);
          expect(submitCalls, 1);

          finishGate.complete();
          await duplicateFinish;
          await tester.pump();

          _pressWizardPrimaryAction(tester);
          for (var attempt = 0; attempt < 10 && submitCalls == 1; attempt++) {
            await _flushAsyncAction(tester);
          }
          expect(submitCalls, 2);
        },
      );

      testWidgets('should serialize rapid multiple-custom downloads', (
        tester,
      ) async {
        final memory = _DreamsMemoryHarness(delayFirstSelectionWrite: true);
        final exportFiles = _ExportReadingFileService(memory.service);
        final locator = GetIt.instance;
        locator.unregister<PersistentMemoryService>();
        locator.unregister<FileService>();
        locator.registerSingleton<PersistentMemoryService>(memory.service);
        locator.registerSingleton<FileService>(exportFiles);
        user = UserInformation(service: memory.service)
          ..gender = 'other'
          ..localeName = 'en';
        _seedMultipleCustomDreams(user);
        addTearDown(memory.releaseFirstSelectionWrite);

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

        _pressIconButton(tester, Icons.download);
        _pressIconButton(tester, Icons.download);
        await _flushAsyncAction(tester);

        expect(memory.firstSelectionWriteStarted, isTrue);
        expect(exportFiles.downloadCalls, 0);

        memory.releaseFirstSelectionWrite();
        await _flushAsyncAction(tester);

        expect(exportFiles.downloadCalls, 1);
        expect(exportFiles.dreamsCustomItemsAtDownload, const <String>[
          'First custom dream',
          'Second custom dream',
        ]);
        await tester.pump(const Duration(seconds: 2));
      });

      testWidgets(
        'should repair malformed Dreams metadata before downloading without an extra save',
        (tester) async {
          final recordingMemory = _DreamsMemoryHarness(
            initialSelections: const <String>['Write and publish a book'],
            initialSelectionSources: const <String>[
              'catalogue:learn-a-new-language',
            ],
            initialCustomItems: const <String>['Stale custom item'],
          );
          final exportFiles = _ExportReadingFileService(
            recordingMemory.service,
          );
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.unregister<FileService>();
          locator.registerSingleton<PersistentMemoryService>(
            recordingMemory.service,
          );
          locator.registerSingleton<FileService>(exportFiles);
          user = UserInformation(service: recordingMemory.service)
            ..gender = 'other'
            ..localeName = 'en'
            ..dreamsAndGoals = <String>['Write and publish a book']
            ..dreamsAndGoalsSelectionSources = <String>[
              'catalogue:learn-a-new-language',
            ];
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

          _pressIconButton(tester, Icons.download);
          await _flushAsyncAction(tester);

          expect(exportFiles.downloadCalls, 1);
          expect(exportFiles.dreamsAtDownload, ['Write and publish a book']);
          expect(exportFiles.dreamsSourcesAtDownload, [
            'catalogue:write-and-publish-a-book',
          ]);
          expect(exportFiles.dreamsCustomItemsAtDownload, isEmpty);
          expect(
            recordingMemory.readKeys,
            containsAll(<String>[
              _customCategoryTitlesKey,
              _customCategoryDescriptionsKey,
              _dreamsAndGoalsSelectionKey,
              _dreamsAndGoalsSelectionSourcesKey,
              _dreamsAndGoalsAddedStringsKey,
            ]),
          );
          expect(
            recordingMemory.completedDreamsAndGoalsWriteKeys(),
            _dreamsAndGoalsPersistenceKeys,
          );
          expect(
            recordingMemory.completedStringList(_dreamsAndGoalsSelectionKey),
            ['Write and publish a book'],
          );
          expect(
            recordingMemory.completedStringList(
              _dreamsAndGoalsSelectionSourcesKey,
            ),
            ['catalogue:write-and-publish-a-book'],
          );
          expect(
            recordingMemory.completedStringList(_dreamsAndGoalsAddedStringsKey),
            isEmpty,
          );
          await tester.pump(const Duration(seconds: 2));
        },
      );

      testWidgets(
        'should repair empty legacy sources before mounting and persist an edited row',
        (tester) async {
          final memory = _DreamsMemoryHarness(
            initialSelections: const <String>['Write and publish a book'],
            delayFirstSelectionWrite: true,
          );
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.registerSingleton<PersistentMemoryService>(memory.service);
          addTearDown(memory.releaseFirstSelectionWrite);
          user = UserInformation(service: memory.service)
            ..gender = 'other'
            ..localeName = 'en'
            ..dreamsAndGoals = <String>['Write and publish a book']
            ..dreamsAndGoalsSelectionSources = <String>[];

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

          final Finder dreamsToggle = find.byKey(
            const Key('share-dreams-and-goals-toggle'),
          );
          await tester.ensureVisible(dreamsToggle);
          await tester.tap(dreamsToggle);
          await tester.pump();

          expect(memory.firstSelectionWriteStarted, isTrue);
          expect(user.dreamsAndGoalsSelectionSources, <String>[
            'catalogue:write-and-publish-a-book',
          ]);
          expect(find.text('Write and publish a book'), findsNothing);

          memory.releaseFirstSelectionWrite();
          await tester.pumpAndSettle();

          expect(find.text('Write and publish a book'), findsOneWidget);
          final Finder selectedDream = find.text('Write and publish a book');
          await tester.ensureVisible(selectedDream);
          await tester.tap(selectedDream);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField),
            'My revised own goal',
          );
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          await _flushAsyncAction(tester);

          expect(tester.takeException(), isNull);
          expect(user.dreamsAndGoals, <String>['My revised own goal']);
          expect(user.dreamsAndGoalsSelectionSources, <String>['custom']);
          expect(
            memory.completedStringList(_dreamsAndGoalsSelectionKey),
            <String>['My revised own goal'],
          );
          expect(
            memory.completedStringList(_dreamsAndGoalsSelectionSourcesKey),
            <String>['custom'],
          );
          expect(
            memory.completedStringList(_dreamsAndGoalsAddedStringsKey),
            <String>['My revised own goal'],
          );
        },
      );

      testWidgets(
        'should ignore a second Dreams toggle while source repair is in flight',
        (tester) async {
          final memory = _DreamsMemoryHarness(
            initialSelections: const <String>['Write and publish a book'],
            delayFirstSelectionWrite: true,
          );
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.registerSingleton<PersistentMemoryService>(memory.service);
          addTearDown(memory.releaseFirstSelectionWrite);
          user = UserInformation(service: memory.service)
            ..gender = 'other'
            ..localeName = 'en'
            ..dreamsAndGoals = <String>['Write and publish a book']
            ..dreamsAndGoalsSelectionSources = <String>[];

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

          final Finder dreamsToggle = find.byKey(
            const Key('share-dreams-and-goals-toggle'),
          );
          await tester.ensureVisible(dreamsToggle);
          await tester.tap(dreamsToggle);
          await tester.pump();

          expect(memory.firstSelectionWriteStarted, isTrue);

          await tester.tap(dreamsToggle);
          await tester.pump();

          expect(find.text('Write and publish a book'), findsNothing);

          memory.releaseFirstSelectionWrite();
          await tester.pumpAndSettle();

          expect(find.text('Write and publish a book'), findsOneWidget);
        },
      );

      testWidgets(
        'should keep the Dreams editor closed until failed repair is retried',
        (tester) async {
          final memory = _DreamsMemoryHarness(
            initialSelections: const <String>['Write and publish a book'],
          )..failSelectionWrite = true;
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.registerSingleton<PersistentMemoryService>(memory.service);
          user = UserInformation(service: memory.service)
            ..gender = 'other'
            ..localeName = 'en'
            ..dreamsAndGoals = <String>['Write and publish a book']
            ..dreamsAndGoalsSelectionSources = <String>[];

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

          final Finder dreamsToggle = find.byKey(
            const Key('share-dreams-and-goals-toggle'),
          );
          await tester.ensureVisible(dreamsToggle);
          await tester.tap(dreamsToggle);
          await _flushAsyncAction(tester);

          expect(find.text('Write and publish a book'), findsNothing);
          expect(
            find.widgetWithText(SnackBarAction, 'Try again'),
            findsOneWidget,
          );

          memory.failSelectionWrite = false;
          tester
              .widget<SnackBarAction>(
                find.widgetWithText(SnackBarAction, 'Try again'),
              )
              .onPressed();
          await _flushAsyncAction(tester);
          await tester.pumpAndSettle();

          expect(user.dreamsAndGoalsSelectionSources, <String>[
            'catalogue:write-and-publish-a-book',
          ]);
          expect(find.text('Write and publish a book'), findsOneWidget);
        },
      );

      testWidgets(
        'should wait for the latest shared dream snapshot before finishing',
        (tester) async {
          final delayedMemory = _DreamsMemoryHarness(
            delayFirstSelectionWrite: true,
          );
          final exportFiles = _ExportReadingFileService(delayedMemory.service);
          List<String>? dreamsAtSubmit;
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.unregister<FileService>();
          locator.registerSingleton<PersistentMemoryService>(
            delayedMemory.service,
          );
          locator.registerSingleton<FileService>(exportFiles);
          user = UserInformation(service: delayedMemory.service)
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
                  dreamsAtSubmit = delayedMemory.completedStringList(
                    _dreamsAndGoalsSelectionKey,
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
            delayedMemory.completedStringList(_dreamsAndGoalsAddedStringsKey),
            ['Immediate dream'],
          );
          expect(
            delayedMemory.completedStringList(
              _dreamsAndGoalsSelectionSourcesKey,
            ),
            ['custom', 'catalogue:write-and-publish-a-book'],
          );
        },
      );

      testWidgets(
        'should block download and finish on a save failure until Retry succeeds',
        (tester) async {
          final failingMemory = _DreamsMemoryHarness()
            ..failAllDreamsWrites = true;
          final exportFiles = _ExportReadingFileService(failingMemory.service);
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.unregister<FileService>();
          locator.registerSingleton<PersistentMemoryService>(
            failingMemory.service,
          );
          locator.registerSingleton<FileService>(exportFiles);
          user = UserInformation(service: failingMemory.service)
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
          final int capturedRevision = user.dreamsAndGoalsSaveRevision;

          failingMemory.failAllDreamsWrites = false;
          tester
              .widget<SnackBarAction>(
                find.widgetWithText(SnackBarAction, 'Try again'),
              )
              .onPressed();
          await _flushAsyncAction(tester);
          expect(exportFiles.downloadCalls, 1);
          expect(user.dreamsAndGoalsSaveRevision, capturedRevision);
          for (final key in <String>[
            _dreamsAndGoalsSelectionKey,
            _dreamsAndGoalsSelectionSourcesKey,
            _dreamsAndGoalsAddedStringsKey,
          ]) {
            expect(failingMemory.completedWritesFor(key), hasLength(1));
          }
          expect(
            failingMemory.completedDreamsAndGoalsWriteKeys(),
            _dreamsAndGoalsPersistenceKeys,
          );

          failingMemory.failAllDreamsWrites = true;
          _pressWizardPrimaryAction(tester);
          await _flushAsyncAction(tester);
          expect(submitCalls, 0);
          expect(
            find.widgetWithText(SnackBarAction, 'Try again'),
            findsOneWidget,
          );

          failingMemory.failAllDreamsWrites = false;
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
          final failingMemory = _DreamsMemoryHarness()
            ..failSelectionWrite = true;
          final locator = GetIt.instance;
          locator.unregister<PersistentMemoryService>();
          locator.registerSingleton<PersistentMemoryService>(
            failingMemory.service,
          );
          user = UserInformation(service: failingMemory.service)
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
  });

  testWidgets('should support a synchronous submit callback', (tester) async {
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

  testWidgets(
    'stabilization loop ensures concurrent Dreams edit persists before primary action finishes',
    (tester) async {
      final stepKey = GlobalKey<WizardStepState>();
      var submitCalls = 0;

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

      // Concurrently update dreams and goals to advance save revision while action runs
      user.updateDreamsAndGoals(['Goal Alpha'], selectionSources: ['custom']);

      await tester.runAsync(() async {
        await stepKey.currentState!.onPrimaryAction();
      });

      expect(submitCalls, 1);
      expect(user.dreamsAndGoals, contains('Goal Alpha'));
    },
  );

  testWidgets(
    'normal successful edit writes each of the three keys exactly once and avoids redundant save on share action',
    (tester) async {
      final memory = _DreamsMemoryHarness();
      final exportFiles = _ExportReadingFileService(memory.service);
      final locator = GetIt.instance;
      locator.unregister<PersistentMemoryService>();
      locator.unregister<FileService>();
      locator.registerSingleton<PersistentMemoryService>(memory.service);
      locator.registerSingleton<FileService>(exportFiles);
      user = UserInformation(service: memory.service)
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

      // Assert that inline save wrote each key once
      expect(
        memory.completedWritesFor(_dreamsAndGoalsSelectionKey),
        hasLength(1),
      );
      expect(
        memory.completedWritesFor(_dreamsAndGoalsSelectionSourcesKey),
        hasLength(1),
      );
      expect(
        memory.completedWritesFor(_dreamsAndGoalsAddedStringsKey),
        hasLength(1),
      );

      // Now trigger download action.
      _pressIconButton(tester, Icons.download);
      await _flushAsyncAction(tester);

      expect(exportFiles.downloadCalls, 1);
      // The action must NOT have written the keys a second time since inline save was already durable
      expect(
        memory.completedWritesFor(_dreamsAndGoalsSelectionKey),
        hasLength(1),
      );
      expect(
        memory.completedWritesFor(_dreamsAndGoalsSelectionSourcesKey),
        hasLength(1),
      );
      expect(
        memory.completedWritesFor(_dreamsAndGoalsAddedStringsKey),
        hasLength(1),
      );
      expect(find.widgetWithText(SnackBarAction, 'Try again'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets(
    'ShareForm loads custom categories using explicit memoryService parameter',
    (tester) async {
      final explicitMemory = _DreamsMemoryHarness(
        initialCustomCategoryTitles: ['Special Goal Category'],
        initialCustomCategoryDescriptions: ['Special Description'],
      );

      user = UserInformation()
        ..gender = 'other'
        ..localeName = 'en';

      await pumpWithProviders(
        tester,
        wizardStepHarness(
          ShareForm(
            key: GlobalKey<WizardStepState>(),
            prev: () {},
            submit: (_) async {},
            memoryService: explicitMemory.service,
          ),
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 1800),
      );
      await tester.pumpAndSettle();

      expect(find.text('Special Goal Category'), findsOneWidget);
      expect(find.text('Special Description'), findsOneWidget);
    },
  );

  testWidgets(
    'ShareForm forwards its explicit memory service to the download export',
    (tester) async {
      final userMemory = _DreamsMemoryHarness();
      final exportMemory = _DreamsMemoryHarness();
      final exportFiles = _ExportReadingFileService(exportMemory.service);
      final locator = GetIt.instance;
      locator.unregister<FileService>();
      locator.registerSingleton<FileService>(exportFiles);
      user = UserInformation(service: userMemory.service)
        ..gender = 'other'
        ..localeName = 'en';

      await pumpWithProviders(
        tester,
        wizardStepHarness(
          ShareForm(
            key: GlobalKey<WizardStepState>(),
            prev: () {},
            submit: (_) async {},
            memoryService: exportMemory.service,
          ),
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 1800),
      );
      await tester.pumpAndSettle();

      await _pressIconButtonInAsyncZone(tester, Icons.download);
      await _flushAsyncAction(tester);
      await _flushAsyncAction(tester);

      expect(exportFiles.downloadCalls, 1);
      expect(exportFiles.memoryServiceAtDownload, same(exportMemory.service));
    },
  );

  testWidgets(
    'ShareForm saveCustomCategories throws StateError when memory service is null',
    (tester) async {
      expect(
        () => saveCustomCategoriesToStorage([], memoryService: null),
        throwsA(isA<StateError>()),
      );
    },
  );
}
