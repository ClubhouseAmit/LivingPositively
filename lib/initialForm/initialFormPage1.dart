// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//The first page of the initial form
//all text is in the CMS and is fetched from there
class InitialFormPage1 extends WizardStep {
  final Function next;
  final Function skip;
  final Function prev;
  final Function updateName;

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
  String? secondaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.skipButton(Provider.of<UserInformation>(context).gender);

  @override
  WizardStepState<InitialFormPage1> createState() => _InitialFormPage1State();
}

class _InitialFormPage1State extends WizardStepState<InitialFormPage1> {
  @override
  Future<void> onPrimaryAction() async => widget.next();

  @override
  Future<void> onSecondaryAction() async => widget.skip();

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;

    // Mirrors the Figma frame's vertical structure (frame 2, node 1660:1264):
    // a title block, then the illustration with equal slack above and below it.
    // The actions and step dots belong to the wizard shell, not to this step.
    // Frame 2 pins the title block to the top (y 104) and leaves near-equal
    // slack above and below the illustration (68 / 63). So: title block first,
    // illustration centred in whatever remains. `spaceEvenly` would instead
    // put a third of the slack *above* the title and push it down the screen.
    return Column(
      children: [
        // Title block — Figma Frame 199 (1660:2837): VERTICAL, itemSpacing 16,
        // cross-axis centred, and narrower than the content column so the copy
        // wraps the way the design does.
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: OnboardingSizes.titleBlockWidth.w,
          ),
          child: Column(
            key: const Key('intro-title-block'),
            mainAxisSize: MainAxisSize.min,
            spacing: OnboardingGaps.withinBlock,
            children: [
              myText(
                appLocale.introductionFormFirstPageMainTitle(gender),
                TextStyle(
                  fontSize: 26.sp,
                  fontWeight: AppFontWeight.medium,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                TextAlign.center,
              ),
              myText(
                appLocale.introductionFormFirstPageSubTitle1(gender),
                TextStyle(
                  fontSize: 16.sp,
                  fontWeight: AppFontWeight.regular,
                  color: Theme.of(context).colorScheme.outline,
                ),
                TextAlign.center,
              ),
              myText(
                appLocale.introductionFormFirstPageSubTitle2(gender),
                TextStyle(
                  fontSize: 16.sp,
                  fontWeight: AppFontWeight.medium,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                TextAlign.center,
              ),
            ],
          ),
        ),
        // The illustration is a 214pt circle on a 360pt frame — just under 60%
        // of the width, centred in the space the title block leaves. It scales
        // down rather than overflowing when that space is short.
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
