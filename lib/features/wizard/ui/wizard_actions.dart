import 'package:flutter/material.dart';

import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/features/wizard/ui/wizard_step.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// The buttons for a step: a filled primary and, when the step declares one,
/// a secondary so the two don't read as equally weighted.
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: OnboardingGaps.withinBlock,
      children: [
        Button(
          key: const Key('wizard-primary-action'),
          label: widget.step.primaryActionLabel(context),
          onPressed: () => _run(
            () async => widget.step.stepKey.currentState?.onPrimaryAction(),
          ),
        ),
        if (secondaryLabel != null)
          Button(
            key: const Key('wizard-secondary-action'),
            label: secondaryLabel,
            variant: ButtonVariant.secondary,
            onPressed: () => _run(
              () async => widget.step.stepKey.currentState?.onSecondaryAction(),
            ),
          ),
      ],
    );
  }
}
