import 'package:flutter/material.dart';

import 'package:mazilon/features/shell/ui/LP_extended_state.dart';

/// A step in an onboarding wizard: what its action is called, and what happens
/// when it runs. Deliberately free of layout opinions — the two flows frame
/// their pages differently, and everything that varied between them turned out
/// to be layout, never contract.
abstract class WizardStep extends StatefulWidget {
  const WizardStep({required GlobalKey<WizardStepState> key})
    : stepKey = key,
      super(key: key);

  final GlobalKey<WizardStepState> stepKey;

  String primaryActionLabel(BuildContext context);

  /// Label for an optional secondary action. Null — the default — means the
  /// step has a single action.
  String? secondaryActionLabel(BuildContext context) => null;

  @override
  WizardStepState createState();
}

abstract class WizardStepState<T extends WizardStep>
    extends LPExtendedState<T> {
  /// Persists this step's answers and then moves the wizard on. The caller
  /// awaits it, so a step that saves asynchronously must not navigate until
  /// the save has completed.
  Future<void> onPrimaryAction();

  /// Invoked only when the step declares a [WizardStep.secondaryActionLabel].
  Future<void> onSecondaryAction() async {}

  /// Persists pending state before the wizard leaves this step from a header
  /// navigation control. Most steps have no additional work.
  Future<void> persistBeforeExit() async {}

  /// Retries [persistBeforeExit] after a header-navigation save failure.
  Future<void> retryPersistBeforeExit() => persistBeforeExit();
}
