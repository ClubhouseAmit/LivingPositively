import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// The page before the personal plan questionnaire that allows the user to fill the questionnaire or skip it.
class ToFormPage extends WizardStep {
  final PhonePageData phonePageData;
  final Function changeLocale;

  const ToFormPage({
    required super.key,
    required this.phonePageData,
    required this.changeLocale,
  });

  @override
  String primaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.introductionFormLastPageNext(Provider.of<UserInformation>(context).gender);

  @override
  WizardStepState<ToFormPage> createState() => _ToFormPageState();
}

class _ToFormPageState extends WizardStepState<ToFormPage> {
  void nextPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => FormProgressIndicator(
          phonePageData: widget.phonePageData,
          changeLocale: widget.changeLocale,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Future<void> onPrimaryAction() async {
    nextPage();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    var gender = userInfoProvider.gender;

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
                appLocale.introductionFormLastPageMainTitle(gender),
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: AppFontWeight.medium,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                appLocale.introductionFormLastPageSubTitle1(gender),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: AppFontWeight.regular,
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                appLocale.introductionFormLastPageSubTitle2(gender),
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
        // Figma node 1660:2321 is 240x175 on a 360pt frame — two thirds of the
        // width, centred in the space the title block leaves.
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Image.asset(
                'assets/images/initialFormPage3.png',
                width: MediaQuery.sizeOf(context).width * 0.66 > 440
                    ? 440
                    : MediaQuery.sizeOf(context).width * 0.66,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
