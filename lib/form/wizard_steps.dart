import 'package:flutter/material.dart';

import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

/// The onboarding wizard's steps, in the order the user walks through them.
///
/// This list *is* the wizard order: `FormProgressIndicator` moves an index
/// over it and the header's progress dots count its entries, so adding,
/// removing or reordering a step is a change to this file alone.
///
/// Most steps are the shared [FormPageTemplate], driven by the personal-plan
/// collection whose items and suggestions it shows; the contacts step and the
/// closing share step have widgets of their own.
List<Widget> buildWizardSteps({
  required VoidCallback next,
  required VoidCallback prev,
  required PhonePageData phonePageData,
  required void Function(BuildContext context) submit,
}) {
  //Keyed by collection name: every step occupies the same slot in the widget
  //tree, so without distinct keys Flutter would hand the next step the
  //previous step's State — its selected items and its "show more" count.
  FormPageTemplate planStep(String collectionName) => FormPageTemplate(
    key: ValueKey(collectionName),
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
    PhonePageForm(next: next, prev: prev, phonePageData: phonePageData),
    ShareForm(prev: prev, submit: submit),
  ];
}
