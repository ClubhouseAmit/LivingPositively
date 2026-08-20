import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';

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

const double _primaryButtonHeight = 40.0;

/// The buttons for a step: a filled primary and, when the step declares one, a
/// secondary rendered as a text link so the two don't read as equally
/// weighted.
class WizardActions extends StatefulWidget {
  const WizardActions({super.key, required this.step});

  final WizardStep step;

  @override
  State<WizardActions> createState() => _WizardActionsState();
}

class _WizardActionsState extends State<WizardActions> {
  bool _actionInFlight = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_actionInFlight) {
      return;
    }
    _actionInFlight = true;
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('Wizard step could not complete: $error\n$stackTrace');
    } finally {
      _actionInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondaryLabel = widget.step.secondaryActionLabel(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: OnboardingGaps.withinBlock,
      children: [
        TextButton(
          key: const Key('wizard-primary-action'),
          onPressed: () => _run(
            () async => widget.step.stepKey.currentState?.onPrimaryAction(),
          ),
          style: primaryButtonStyle(context).copyWith(
            fixedSize: const WidgetStatePropertyAll(
              Size.fromHeight(_primaryButtonHeight),
            ),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(
            widget.step.primaryActionLabel(context),
            style: TextStyle(
              fontWeight: AppFontWeight.medium,
              fontSize: 18.sp,
              color: colorScheme.onPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (secondaryLabel != null)
          TextButton(
            key: const Key('wizard-secondary-action'),
            onPressed: () => _run(
              () async => widget.step.stepKey.currentState?.onSecondaryAction(),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: colorScheme.primary,
            ),
            child: Text(
              secondaryLabel,
              style: TextStyle(
                fontWeight: AppFontWeight.medium,
                fontSize: 18.sp,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

// There is deliberately no page widget here. A wizard page is
// `Column[header, Expanded(step), actions]` — five lines each flow writes for
// itself. Wrapping that in a class bought nothing and cost a constructor, a
// factory and a doc comment; worse, an earlier version took `topGap`/`bottomGap`
// parameters, which is a shared layout whose spacing comes from the caller.
