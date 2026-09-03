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

List<(String, String)> _pairs(List<MapEntry<String, String>> categories) => [
  for (final category in categories) (category.key, category.value),
];

void main() {
  group('ShareFormCustomCategoriesViewModel', () {
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
            <String>['Old'],
            <String>['Latest'],
            <String>['Latest'],
          ],
        );
      },
    );
  });
}
