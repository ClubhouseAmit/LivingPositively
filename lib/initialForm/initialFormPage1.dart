import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// The first page of the initial form.
class InitialFormPage1 extends WizardStep {
  final VoidCallback next;
  final VoidCallback skip;
  final VoidCallback prev;
  final ValueChanged<String> updateName;

  const InitialFormPage1({
    required super.key,
    required this.next,
    required this.skip,
    required this.prev,
    required this.updateName,
  });

  @override
  String primaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.nextButton(Provider.of<UserInformation>(context).gender);

  @override
  WizardStepState<InitialFormPage1> createState() => _InitialFormPage1State();
}

class _InitialFormPage1State extends WizardStepState<InitialFormPage1> {
  @override
  Future<void> onPrimaryAction() async => widget.next();

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;

    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 240.w),
          child: Column(
            key: const Key('intro-title-block'),
            mainAxisSize: MainAxisSize.min,
            spacing: OnboardingGaps.withinBlock,
            children: [
              Text(
                appLocale.introductionFormFirstPageMainTitle(gender),
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: AppFontWeight.medium,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                appLocale.introductionFormFirstPageSubTitle1(gender),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: AppFontWeight.regular,
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                appLocale.introductionFormFirstPageSubTitle2(gender),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: AppFontWeight.medium,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Illustration — centred in remaining space.
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Image.asset(
                'assets/images/initialFormPage1.png',
                width: MediaQuery.sizeOf(context).width * 0.6 > 400
                    ? 400
                    : MediaQuery.sizeOf(context).width * 0.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
