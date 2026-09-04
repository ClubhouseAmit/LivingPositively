import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Share/personal_plan_share.dart';
import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/personal_plan_export_snapshot.dart';
import 'package:mazilon/util/userInformation.dart';

import '../../test_support/contract_persistent_memory_service.dart';

void main() {
  group('PersonalPlanExportSnapshot', () {
    late ContractPersistentMemoryService source;

    setUp(() {
      source = ContractPersistentMemoryService(
        initialValues: {
          'userSelectionPersonalPlan-DifficultEvents': ['trigger'],
          'userSelectionPersonalPlan-MakeSafer': ['support'],
          'userSelectionPersonalPlan-FeelBetter': ['wellness'],
          'userSelectionPersonalPlan-Distractions': ['activity'],
          'userSelectionPersonalPlan-SafeEnvironment': ['safe place'],
          'userSelectionPersonalPlan-DreamsAndGoals': ['goal'],
          'PhonePageSavedPhoneNames': ['friend'],
          'PhonePageSavedPhoneNumbers': ['1201'],
          customCategoriesKey: '[{"title":"Custom","description":"notes"}]',
        },
      );
    });

    test(
      'should capture every exported field without writing to the source',
      () async {
        final snapshot = await PersonalPlanExportSnapshot.capture(source);
        expect(snapshot.data, {
          'DifficultEvents': ['trigger'],
          'MakeSafer': ['support'],
          'FeelBetter': ['wellness'],
          'Distractions': ['activity'],
          'SafeEnvironment': ['safe place'],
          'DreamsAndGoals': ['goal'],
          'phoneNames': ['friend'],
          'phoneNumbers': ['1201'],
          'customCategoryTitles': ['Custom'],
          'customCategoryDescriptions': ['notes'],
        });
        expect(source.attemptedWrites, isEmpty);
        expect(
          () => snapshot.data['DreamsAndGoals']!.add('mutation'),
          throwsUnsupportedError,
        );
        expect(() => snapshot.data.clear(), throwsUnsupportedError);
      },
    );

    test(
      'should render only the captured values after the source changes',
      () async {
        final snapshot = await PersonalPlanExportSnapshot.capture(source);
        await source.reset();
        source.onRead = (_, _) => throw StateError('Renderer reread storage');
        final organized = await FileServiceImpl().organizeDataForFile(
          [
            'Activities',
            'Triggers',
            'Wellness',
            'Support',
            'Contacts',
            'Safety',
            'Goals',
          ],
          List<String>.filled(7, ''),
          const {},
          mainTitle: 'My plan',
          memoryService: source,
          snapshot: snapshot,
        );
        expect(organized['realData'], [
          ['activity'],
          ['trigger'],
          ['wellness'],
          ['support'],
          ['friend:1201'],
          ['safe place'],
          ['goal'],
          ['notes'],
        ]);
        expect(organized['titles'], [
          'Activities',
          'Triggers',
          'Wellness',
          'Support',
          'Contacts',
          'Safety',
          'Goals',
          'Custom',
        ]);
      },
    );

    test(
      'should exclude writes started during capture from every captured field',
      () async {
        final started = Completer<void>();
        final release = Completer<void>();
        source.onRead = (key, _) async {
          if (!started.isCompleted) {
            started.complete();
            await release.future;
          }
        };
        final capture = PersonalPlanExportSnapshot.capture(source);
        await started.future;
        final edit = source.setItem(
          'userSelectionPersonalPlan-DreamsAndGoals',
          PersistentMemoryType.StringList,
          ['new goal'],
        );
        final categoriesEdit = saveCustomCategoriesToStorage(const [
          MapEntry('New category', 'new notes'),
        ], memoryService: source);
        try {
          expect(source.attemptedWrites, isEmpty);
        } finally {
          release.complete();
        }
        final snapshot = await capture;
        await Future.wait([edit, categoriesEdit]);
        expect(snapshot.data['DreamsAndGoals'], ['goal']);
        expect(snapshot.data['customCategoryTitles'], ['Custom']);
        final next = await PersonalPlanExportSnapshot.capture(source);
        expect(next.data['DreamsAndGoals'], ['new goal']);
        expect(next.data['customCategoryTitles'], ['New category']);
        expect(next.fingerprint, isNot(snapshot.fingerprint));
      },
    );

    test(
      'should retry capture when a model save starts during the read',
      () async {
        final model = UserInformation(service: source);
        final started = Completer<void>();
        final release = Completer<void>();
        var readCount = 0;
        source.onRead = (key, _) async {
          if (key == customCategoriesKey) readCount++;
          if (!started.isCompleted) {
            started.complete();
            await release.future;
          }
        };
        final export = preparePersonalPlanExportSnapshot(
          userInformation: model,
        );
        await started.future;
        final save = model.saveCustomCategories(
          categories: const [MapEntry('Latest', 'Latest notes')],
        );
        release.complete();
        final snapshot = await export;
        await save;
        expect(snapshot.data['customCategoryTitles'], ['Latest']);
        expect(readCount, 2);
        model.dispose();
      },
    );

    test(
      'should fail after bounded retries if editing never settles',
      () async {
        final model = UserInformation(service: source);
        final saves = <Future<void>>[];
        source.onRead = (key, _) {
          if (key == customCategoriesKey) {
            saves.add(
              model.saveCustomCategories(
                categories: [MapEntry('Edit ${saves.length}', 'notes')],
              ),
            );
          }
        };
        await expectLater(
          preparePersonalPlanExportSnapshot(userInformation: model),
          throwsStateError,
        );
        await Future.wait(saves);
        expect(saves, hasLength(8));
        model.dispose();
      },
    );

    test(
      'should not let another store load or save replace the model or export',
      () async {
        final other = ContractPersistentMemoryService(
          initialValues: {
            customCategoriesKey:
                '[{"title":"Other","description":"other notes"}]',
          },
        );
        final model = UserInformation(service: source);
        await model.loadCustomCategories();
        final defaultSave = model.pendingCustomCategoriesSave;
        final loaded = await model.loadCustomCategories(memoryService: other);
        expect(loaded.single.key, 'Other');
        await model.saveCustomCategories(
          categories: const [MapEntry('Other edited', 'other edited notes')],
          memoryService: other,
        );
        expect(model.customCategories.single.key, 'Custom');
        expect(model.pendingCustomCategoriesSave, same(defaultSave));
        final defaultExport = await preparePersonalPlanExportSnapshot(
          userInformation: model,
        );
        final alternateExport = await preparePersonalPlanExportSnapshot(
          userInformation: model,
          memoryService: other,
        );
        expect(defaultExport.data['customCategoryTitles'], ['Custom']);
        expect(alternateExport.data['customCategoryTitles'], ['Other edited']);
        expect(source.attemptedWrites, isEmpty);
        expect(other.attemptedWrites, hasLength(3));
        model.dispose();
      },
    );

    test(
      'should reject implicit copying when saving to another source',
      () async {
        final model = UserInformation(service: source);
        final other = ContractPersistentMemoryService();
        await model.loadCustomCategories();
        await expectLater(
          model.saveCustomCategories(memoryService: other),
          throwsArgumentError,
        );
        expect(other.attemptedWrites, isEmpty);
        model.dispose();
      },
    );

    test(
      'should preserve legacy category parsing without writing a migration',
      () async {
        source.store.remove(customCategoriesKey);
        source.store[customCategoryTitlesKey] = [' Legacy ', '', 'ignored'];
        source.store[customCategoryDescriptionsKey] = [
          ' notes ',
          'empty title',
        ];
        final snapshot = await PersonalPlanExportSnapshot.capture(source);
        expect(snapshot.data['customCategoryTitles'], ['Legacy']);
        expect(snapshot.data['customCategoryDescriptions'], ['notes']);
        expect(source.attemptedWrites, isEmpty);
      },
    );

    test(
      'should reject incomplete contacts rather than render incorrect pairings',
      () async {
        source.store['PhonePageSavedPhoneNumbers'] = <String>[];
        await expectLater(
          PersonalPlanExportSnapshot.capture(source),
          throwsStateError,
        );
      },
    );
  });
}
