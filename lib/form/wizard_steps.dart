import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/form/custom_category_step.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/util/persistent_memory_service.dart';

List<WizardStep> buildWizardSteps({
  required VoidCallback next,
  required VoidCallback prev,
  required PhonePageData phonePageData,
  required FutureOr<void> Function(BuildContext context) submit,
  PersistentMemoryService? memoryService,
  List<MapEntry<String, String>> customCategories = const [],
  CustomCategorySave? onCustomCategorySaved,
  Future<void> Function(MapEntry<String, String>)? onNewCustomCategorySaved,
  Future<void> Function(int index)? onCustomCategoryDeleted,
  void Function(int step)? goToStep,
  int? shareStepIndex,
}) {
  FormPageTemplate planStep(String collectionName) => FormPageTemplate(
    key: GlobalKey<WizardStepState>(debugLabel: collectionName),
    next: next,
    prev: prev,
    collectionName: collectionName,
  );

  final steps = <WizardStep>[
    planStep('PersonalPlan-Distractions'),
    planStep('PersonalPlan-DifficultEvents'),
    planStep('PersonalPlan-FeelBetter'),
    planStep('PersonalPlan-MakeSafer'),
    planStep('PersonalPlan-SafeEnvironment'),
    planStep('PersonalPlan-DreamsAndGoals'),
  ];

  for (final (index, category) in customCategories.indexed) {
    steps.add(
      CustomCategoryStep(
        key: GlobalKey<WizardStepState>(debugLabel: 'custom-category-$index'),
        index: index,
        category: category,
        next: next,
        onSave: onCustomCategorySaved ?? (_, _) async {},
        onDelete: onCustomCategoryDeleted,
      ),
    );
  }
  steps.add(
    AddCustomCategoryStep(
      key: GlobalKey<WizardStepState>(debugLabel: 'add-custom-category'),
      index: customCategories.length,
      next: next,
      onSave: onNewCustomCategorySaved ?? (_) async {},
    ),
  );
  steps.add(
    PhonePageForm(
      key: GlobalKey<WizardStepState>(debugLabel: 'contacts'),
      next: next,
      prev: prev,
      phonePageData: phonePageData,
    ),
  );
  steps.add(
    ShareForm(
      key: GlobalKey<WizardStepState>(debugLabel: 'share'),
      prev: prev,
      submit: submit,
      memoryService: memoryService,
      goToStep: goToStep,
      shareStepIndex: shareStepIndex ?? 8 + customCategories.length,
    ),
  );
  return steps;
}
