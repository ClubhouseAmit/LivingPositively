import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/menu.dart';
import 'package:mazilon/form/form.dart';
import 'package:mazilon/form/wizard_step.dart';

import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

//the page before the personal plan questionnaire that allows the user to fill the questionnaire or skip it.
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
  String? secondaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.skipButton(Provider.of<UserInformation>(context).gender);

  @override
  WizardStepState<ToFormPage> createState() => _ToFormPageState();
}

class _ToFormPageState extends WizardStepState<ToFormPage> {
  bool hasFilled = false;
  void getHasFilled() async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    var hasFilledValue = await service.getItem(
      "hasFilled",
      PersistentMemoryType.Bool,
    );

    setState(() {
      hasFilled = hasFilledValue ?? false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getHasFilled();
  }

  @override
  Future<void> onPrimaryAction() async {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FormProgressIndicator(
              phonePageData: widget.phonePageData,
              changeLocale: widget.changeLocale,
            ), //place collections here
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(-1.0, 0.0);
          var end = Offset.zero;
          var tween = Tween(begin: begin, end: end);
          var offsetAnimation = animation.drive(tween);

          var fadeTween = Tween(begin: 0.0, end: 1.0);
          var fadeAnimation = animation.drive(fadeTween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
      ),
    );
  }

  @override
  Future<void> onSecondaryAction() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => Menu(
          phonePageData: widget.phonePageData,
          hasFilled: hasFilled,
          changeLocale: widget.changeLocale,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    var gender = userInfoProvider.gender;

    // Same vertical structure as the welcome step (frame 19, node 1660:2313):
    // title block, then the illustration with equal slack either side. The
    // actions and step dots belong to the wizard shell.
    return Column(
      children: [
        // Title block — Figma Frame 207 (1660:2846): VERTICAL, itemSpacing 16,
        // narrower than the content column so the copy wraps as designed.
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
                appLocale.introductionFormLastPageMainTitle(gender),
                TextStyle(
                  fontSize: 26.sp,
                  fontWeight: AppFontWeight.medium,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                TextAlign.center,
              ),
              // Both paragraphs are one Figma text node (1660:2317) whose base
              // is grey / Medium — but it carries per-character overrides the
              // manifest does not surface, and they differ per paragraph:
              //   run 18 (first):  fontWeight 400, keeps the node's grey
              //   run 16 (second): fill #01B91E, keeps the node's Medium
              // Reading only the node-level values says "one grey node", which
              // is how the green accent came to be removed in an earlier pass.
              myText(
                appLocale.introductionFormLastPageSubTitle1(gender),
                TextStyle(
                  fontSize: 16.sp,
                  fontWeight: AppFontWeight.regular,
                  color: Theme.of(context).colorScheme.outline,
                ),
                TextAlign.center,
              ),
              myText(
                appLocale.introductionFormLastPageSubTitle2(gender),
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
