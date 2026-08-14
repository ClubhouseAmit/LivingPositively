import 'package:flutter/material.dart';

import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

/// The onboarding wizard's steps, in the order the user walks through them.
///
/// This list *is* the wizard order: `FormProgressIndicator` moves an index
/// over it and the header's progress dots count its entries, so adding,
/// removing or reordering a step is a change to this file alone.
///
/// Most steps are the shared [FormPageTemplate], driven by the personal-plan
/// collection whose items and suggestions it shows; the contacts step and the
/// closing share step have widgets of their own. None of them draws the
/// primary button — `WizardStepPage` does, from the label and action each step
/// declares.
List<WizardStep> buildWizardSteps({
  required VoidCallback next,
  required VoidCallback prev,
  required PhonePageData phonePageData,
  required void Function(BuildContext context) submit,
}) {
  //Every step is created with a GlobalKey: it identifies the step (they all
  //share one slot in the widget tree, so without distinct keys Flutter would
  //hand the next step the previous step's State) and it is how the page
  //reaches the step's primary action. Built once, in initState, so the keys
  //stay stable for as long as the wizard is open.
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
    //The last step the user fills in, immediately before the closing page.
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
    ),
  ];
}
