import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/share_form_custom_categories_view_model.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';

import '../../test_support/contract_persistent_memory_service.dart';

final class _RecordingIncidentLogger implements IncidentLoggerService {
  final List<Object> errors = <Object>[];

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    errors.add(exception as Object);
  }

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}

final class _GatedIncidentLogger implements IncidentLoggerService {
  final Completer<void> firstReportStarted = Completer<void>();
  final Completer<void> releaseFirstReport = Completer<void>();
  final List<Object> errors = <Object>[];

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    errors.add(exception as Object);
    if (errors.length == 1) {
      firstReportStarted.complete();
      await releaseFirstReport.future;
    }
  }

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}

List<(String, String)> _pairs(List<MapEntry<String, String>> categories) => [
  for (final category in categories) (category.key, category.value),
];

void main() {
  group('ShareFormCustomCategoriesViewModel', () {
    for (final alternate in [false, true]) {
      test(
        'should wait for and retry initial load (alternate: $alternate)',
        () async {
          final memory = ContractPersistentMemoryService(
            initialValues: {
              customCategoriesKey: jsonEncode([
                {'title': 'Stored', 'description': 'Notes'},
              ]),
            },
          );
          final model = UserInformation(
            service: alternate ? ContractPersistentMemoryService() : memory,
          );
          final viewModel = ShareFormCustomCategoriesViewModel(
            userInformation: model,
            memoryService: memory,
            incidentLogger: _RecordingIncidentLogger(),
          );
          addTearDown(viewModel.dispose);
          final gate = Completer<void>();
          final started = Completer<void>();
          var fail = true;
          memory.onRead = (key, type) async {
            if (key != customCategoriesKey) return;
            if (!started.isCompleted) started.complete();
            await gate.future;
            if (fail) throw StateError('Read failed');
          };
          final loading = viewModel.load();
          await started.future;
          var completed = false;
          final preparation = viewModel.prepareForAction().then((value) {
            completed = true;
            return value;
          });
          await Future<void>.delayed(Duration.zero);
          expect(completed, isFalse);
          gate.complete();
          await loading;
          expect(await preparation, isFalse);
          expect(viewModel.state, isA<ShareFormCustomCategoriesLoadFailure>());
          expect(await viewModel.prepareForAction(retry: true), isFalse);
          fail = false;
          expect(await viewModel.prepareForAction(retry: true), isTrue);
          expect(_pairs(viewModel.state.categories), [('Stored', 'Notes')]);
        },
      );
    }

    test(
      'should retry a newer sibling failure without replaying its own snapshot',
      () async {
        final memory = ContractPersistentMemoryService();
        final model = UserInformation(service: memory);
        final viewModel = ShareFormCustomCategoriesViewModel(
          userInformation: model,
          incidentLogger: _RecordingIncidentLogger(),
        );
        addTearDown(viewModel.dispose);
        await viewModel.load();
        await viewModel.save(const [MapEntry('Old', 'Own save')]);
        memory.onPersist = (key, type, value) {
          if (key == customCategoriesKey) throw StateError('Sibling failure');
        };
        await expectLater(
          model.saveCustomCategories(
            categories: const [MapEntry('New', 'Sibling save')],
          ),
          throwsStateError,
        );
        expect(await viewModel.prepareForAction(), isFalse);
        expect(await viewModel.prepareForAction(retry: true), isFalse);
        memory.onPersist = null;
        expect(await viewModel.prepareForAction(retry: true), isTrue);
        expect(_pairs(model.customCategories), [('New', 'Sibling save')]);
        expect(_pairs(viewModel.state.categories), [('New', 'Sibling save')]);
      },
    );

    for (final alternate in [false, true]) {
      test(
        'should block actions through a failed and held retry (alternate: $alternate)',
        () async {
          final memory = ContractPersistentMemoryService();
          final model = UserInformation(
            service: alternate ? ContractPersistentMemoryService() : memory,
          );
          final viewModel = ShareFormCustomCategoriesViewModel(
            userInformation: model,
            memoryService: memory,
            incidentLogger: _RecordingIncidentLogger(),
          );
          addTearDown(viewModel.dispose);
          var fail = true;
          final gate = Completer<void>();
          final started = Completer<void>();
          memory.onPersist = (key, type, value) async {
            if (key != customCategoriesKey) return;
            if (fail) throw StateError('Save failed');
            if (!started.isCompleted) started.complete();
            await gate.future;
          };
          await viewModel.save(const [MapEntry('Latest', 'Notes')]);
          model.updateName('Unrelated change');
          expect(await viewModel.prepareForAction(), isFalse);
          expect(await viewModel.prepareForAction(retry: true), isFalse);
          fail = false;
          var completed = false;
          final retry = viewModel.prepareForAction(retry: true).then((ready) {
            completed = true;
            return ready;
          });
          await started.future;
          expect(completed, isFalse);
          gate.complete();
          expect(await retry, isTrue);
          expect(_pairs(viewModel.state.categories), [('Latest', 'Notes')]);
          if (alternate) expect(model.customCategories, isEmpty);
        },
      );
    }

    test(
      'should keep an alternate export source isolated from the user model',
      () async {
        final defaultMemory = ContractPersistentMemoryService();
        final alternateMemory = ContractPersistentMemoryService(
          initialValues: {
            customCategoriesKey: jsonEncode([
              {'title': 'Stored title', 'description': 'Stored description'},
            ]),
          },
        );
        final userInformation = UserInformation(
          service: defaultMemory,
          customCategories: const [MapEntry('Default', 'Model value')],
        );
        final viewModel = ShareFormCustomCategoriesViewModel(
          userInformation: userInformation,
          memoryService: alternateMemory,
        );
        addTearDown(viewModel.dispose);

        await viewModel.load();
        expect(_pairs(viewModel.state.categories), [
          ('Stored title', 'Stored description'),
        ]);
        expect(_pairs(userInformation.customCategories), [
          ('Default', 'Model value'),
        ]);

        await viewModel.save(const [
          MapEntry('  Edited title  ', ' Edited description '),
          MapEntry('', 'discarded'),
        ]);

        expect(_pairs(viewModel.state.categories), [
          ('Edited title', 'Edited description'),
        ]);
        expect(_pairs(userInformation.customCategories), [
          ('Default', 'Model value'),
        ]);
        expect(defaultMemory.store.containsKey(customCategoriesKey), isFalse);
        expect(
          jsonDecode(alternateMemory.store[customCategoriesKey] as String),
          [
            {'title': 'Edited title', 'description': 'Edited description'},
          ],
        );
      },
    );

    test(
      'should report a failure and retry only the latest snapshot',
      () async {
        final memory = ContractPersistentMemoryService();
        final incidentLogger = _RecordingIncidentLogger();
        var rejectCanonicalWrite = true;
        memory.onPersist = (key, type, value) {
          if (key == customCategoriesKey && rejectCanonicalWrite) {
            throw StateError('intentional save failure');
          }
        };
        final userInformation = UserInformation(service: memory);
        final viewModel = ShareFormCustomCategoriesViewModel(
          userInformation: userInformation,
          incidentLogger: incidentLogger,
        );
        addTearDown(viewModel.dispose);

        await viewModel.save(const [MapEntry('Old', 'Failed')]);
        expect(viewModel.state, isA<ShareFormCustomCategoriesSaveFailure>());
        expect(incidentLogger.errors, hasLength(1));

        rejectCanonicalWrite = false;
        await viewModel.save(const [MapEntry('Latest', 'Saved')]);
        await viewModel.retryLatestSave();

        expect(viewModel.state, isA<ShareFormCustomCategoriesReady>());
        expect(_pairs(viewModel.state.categories), [('Latest', 'Saved')]);
        expect(
          memory.completedWrites
              .where(
                (write) =>
                    write.key == customCategoryTitlesKey &&
                    write.type == PersistentMemoryType.StringList,
              )
              .map((write) => write.value),
          [
            <String>['Latest'],
            <String>['Latest'],
          ],
        );
      },
    );

    test(
      'should keep newer ready state when stale failure reporting finishes',
      () async {
        final memory = ContractPersistentMemoryService();
        final incidentLogger = _GatedIncidentLogger();
        var rejectOldSnapshot = true;
        memory.onPersist = (key, type, value) {
          if (key == customCategoriesKey && rejectOldSnapshot) {
            throw StateError('old save failed');
          }
        };
        final userInformation = UserInformation(service: memory);
        final viewModel = ShareFormCustomCategoriesViewModel(
          userInformation: userInformation,
          incidentLogger: incidentLogger,
        );
        addTearDown(viewModel.dispose);

        final oldSave = viewModel.save(const [MapEntry('Old', 'Failed')]);
        await incidentLogger.firstReportStarted.future;

        rejectOldSnapshot = false;
        await viewModel.save(const [MapEntry('New', 'Saved')]);
        expect(viewModel.state, isA<ShareFormCustomCategoriesReady>());
        expect(_pairs(viewModel.state.categories), [('New', 'Saved')]);

        incidentLogger.releaseFirstReport.complete();
        await oldSave;

        expect(incidentLogger.errors, hasLength(1));
        expect(viewModel.state, isA<ShareFormCustomCategoriesReady>());
        expect(_pairs(viewModel.state.categories), [('New', 'Saved')]);
      },
    );

    test('should drain an accepted save before closing', () async {
      final saveStarted = Completer<void>();
      final releaseSave = Completer<void>();
      final memory = ContractPersistentMemoryService();
      memory.onPersist = (key, type, value) async {
        if (key == customCategoriesKey) {
          saveStarted.complete();
          await releaseSave.future;
        }
      };
      final userInformation = UserInformation(service: memory);
      final viewModel = ShareFormCustomCategoriesViewModel(
        userInformation: userInformation,
      );

      final save = viewModel.save(const [MapEntry('Pending', 'Snapshot')]);
      await saveStarted.future;
      var closeCompleted = false;
      final close = viewModel.close().then((_) => closeCompleted = true);
      await Future<void>.delayed(Duration.zero);
      expect(closeCompleted, isFalse);

      releaseSave.complete();
      await Future.wait<void>([save, close]);
      expect(closeCompleted, isTrue);

      final attemptedWriteCount = memory.attemptedWrites.length;
      await viewModel.save(const [MapEntry('Ignored', 'After close')]);
      expect(memory.attemptedWrites, hasLength(attemptedWriteCount));
    });
  });
}
