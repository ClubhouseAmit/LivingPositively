import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mazilon/form/formpagetemplate.dart';
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
}) {
  FormPageTemplate planStep(String collectionName) => FormPageTemplate(
    key: GlobalKey<WizardStepState>(debugLabel: collectionName),
    next: next,
    prev: prev,
    collectionName: collectionName,
  );

  return [
    planStep('PersonalPlan-Distractions'),
    planStep('PersonalPlan-DifficultEvents'),
    planStep('PersonalPlan-FeelBetter'),
    planStep('PersonalPlan-MakeSafer'),
    planStep('PersonalPlan-SafeEnvironment'),
    planStep('PersonalPlan-DreamsAndGoals'),
    PhonePageForm(
      key: GlobalKey<WizardStepState>(debugLabel: 'contacts'),
      next: next,
      prev: prev,
      phonePageData: phonePageData,
    ),
    ShareForm(
      key: GlobalKey<WizardStepState>(debugLabel: 'share'),
      prev: prev,
      submit: submit,
      memoryService: memoryService,
    ),
  ];
}
