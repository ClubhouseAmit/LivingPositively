import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';

/// Gap between the wizard header (progress dots) and the step content, and
/// between the step content and the primary button below it. Figma places the
/// header and the button at the same y on every frame, so both gaps live here
/// rather than in the individual steps.
const double _gapHeaderToContent = AppSpacing.xxl;
const double _gapContentToButton = AppSpacing.lg;

/// One step of the onboarding wizard.
///
/// A step renders **only its own content**. The chrome around it — the header
/// with the progress dots and the primary button at the bottom of the page —
/// belongs to [WizardStepPage], so the button lands at the same place on every
/// step and a new step cannot drift by drawing its own.
///
/// A step is created with a [GlobalKey] because that is how [WizardStepPage]
/// reaches [WizardStepState.onPrimaryAction] when its button is tapped; the
/// key doubles as the step's identity, so steps sharing a slot in the widget
/// tree don't inherit each other's state.
abstract class WizardStep extends StatefulWidget {
  const WizardStep({required GlobalKey<WizardStepState> key})
    : stepKey = key,
      super(key: key);

  /// This step's key, typed — the same object as [key].
  final GlobalKey<WizardStepState> stepKey;

  /// Label for the primary button while this step is showing.
  String primaryActionLabel(BuildContext context);

  @override
  WizardStepState createState();
}

/// The state of a [WizardStep]. Implementing [onPrimaryAction] is how a step
/// says what its primary button does — the step owns the behaviour, the page
/// owns where the button sits.
abstract class WizardStepState<T extends WizardStep>
    extends LPExtendedState<T> {
  /// Runs when the user taps the page's primary button. Implementations may
  /// be asynchronous; the page does not wait for them.
  void onPrimaryAction();
}

/// Lays out a single [WizardStep]: the step's content takes the space above a
/// primary button pinned to the bottom of the page.
///
/// The wizard uses this for every step. The contacts editor reached from the
/// SOS page reuses it too, which is why it knows nothing about progress dots
/// or step order.
class WizardStepPage extends StatelessWidget {
  const WizardStepPage({super.key, required this.step});

  final WizardStep step;

  @override
  Widget build(BuildContext context) {
    //SafeArea(bottom) keeps the pinned button clear of the home indicator —
    //callers inset the top themselves (the wizard does it with its AppBar).
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: _gapHeaderToContent),
        child: Column(
          children: [
            Expanded(child: step),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: _gapContentToButton,
              ),
              child: ConfirmationButton(
                context,
                () => step.stepKey.currentState?.onPrimaryAction(),
                step.primaryActionLabel(context),
                myTextStyle.copyWith(
                  fontWeight: AppFontWeight.medium,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
