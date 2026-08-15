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
}

/// The buttons for a step: a filled primary and, when the step declares one, a
/// secondary rendered as a text link so the two don't read as equally
/// weighted. This is the part both flows genuinely share — the styling, the
/// design's 40pt pill, and the guard against a double tap advancing twice.
///
/// It carries no outer spacing. Whoever places it owns the gaps around it.
class WizardActions extends StatefulWidget {
  const WizardActions({super.key, required this.step});

  final WizardStep step;

  @override
  State<WizardActions> createState() => _WizardActionsState();
}

class _WizardActionsState extends State<WizardActions> {
  /// Taps are dropped while an action is running. Awaiting the action widens
  /// the gap between the tap and the step changing, and a second tap in that
  /// gap would advance the wizard twice — skipping a step.
  bool _actionInFlight = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_actionInFlight) {
      return;
    }
    _actionInFlight = true;
    try {
      await action();
    } catch (error, stackTrace) {
      // A step that could not save stays put rather than moving on with its
      // answers unsaved. The button is live again, so the user can retry.
      // TODO(#333): tell the user the save failed — there is no localized
      // copy for it yet.
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
      spacing: OnboardingGaps.primaryToSecondary,
      children: [
        // A plain Text, not ConfirmationButton: that helper labels through
        // `myAutoSizedText`, whose `maxFontSize` ceiling of 50 is what actually
        // paints, leaving the size below inert. See designs/issue-338-audit.md.
        TextButton(
          key: const Key('wizard-primary-action'),
          onPressed: () => _run(
            () async => widget.step.stepKey.currentState?.onPrimaryAction(),
          ),
          // `fixedSize` pins the paint to the design's 40 — `minimumSize` alone
          // is only a floor, and the label's own height pushes past it.
          // `padded` keeps the hit area at Material's 48 minimum around it.
          style: primaryButtonStyle(context).copyWith(
            fixedSize: const WidgetStatePropertyAll(
              Size.fromHeight(OnboardingSizes.primaryButtonHeight),
            ),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: myText(
            widget.step.primaryActionLabel(context),
            TextStyle(
              fontWeight: AppFontWeight.medium,
              fontSize: 18.sp,
              color: colorScheme.onPrimary,
            ),
            TextAlign.center,
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
            child: myText(
              secondaryLabel,
              TextStyle(
                fontWeight: AppFontWeight.medium,
                fontSize: 18.sp,
                color: colorScheme.primary,
              ),
              TextAlign.center,
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
