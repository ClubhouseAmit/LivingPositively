import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';

const double _gapHeaderToContent = AppSpacing.xxl;
const double _gapContentToButton = AppSpacing.lg;

abstract class WizardStep extends StatefulWidget {
  const WizardStep({required GlobalKey<WizardStepState> key})
    : stepKey = key,
      super(key: key);

  final GlobalKey<WizardStepState> stepKey;

  String primaryActionLabel(BuildContext context);

  @override
  WizardStepState createState();
}

abstract class WizardStepState<T extends WizardStep>
    extends LPExtendedState<T> {
  /// Persists this step's answers and then moves the wizard on. The page
  /// awaits it, so a step that saves asynchronously must not navigate until
  /// the save has completed.
  Future<void> onPrimaryAction();
}

class WizardStepPage extends StatefulWidget {
  const WizardStepPage({super.key, required this.step});

  final WizardStep step;

  @override
  State<WizardStepPage> createState() => _WizardStepPageState();
}

class _WizardStepPageState extends State<WizardStepPage> {
  /// Taps are dropped while a primary action is running. Awaiting the action
  /// widens the gap between the tap and the step changing, and a second tap
  /// in that gap would advance the wizard twice — skipping a step.
  bool _actionInFlight = false;

  Future<void> _runPrimaryAction() async {
    if (_actionInFlight) {
      return;
    }
    _actionInFlight = true;
    try {
      await widget.step.stepKey.currentState?.onPrimaryAction();
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: _gapHeaderToContent),
        child: Column(
          children: [
            Expanded(child: widget.step),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: _gapContentToButton,
              ),
              child: ConfirmationButton(
                context,
                _runPrimaryAction,
                widget.step.primaryActionLabel(context),
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
