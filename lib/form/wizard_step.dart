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
  void onPrimaryAction();
}

class WizardStepPage extends StatelessWidget {
  const WizardStepPage({super.key, required this.step});

  final WizardStep step;

  @override
  Widget build(BuildContext context) {
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
