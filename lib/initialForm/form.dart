import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/l10n/app_localizations.dart';

import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/initialForm/toFormPage.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/initialForm/initialFormPage1.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/disclaimerPage.dart';

// Every design-derived number for this flow lives in OnboardingGaps /
// OnboardingSizes (lib/util/theme/spacing.dart), keyed to the Figma node it
// came from. Nothing is declared here.

class InitialFormProgressIndicator extends StatefulWidget {
  final PhonePageData phonePageData;
  final Function changeLocale;

  const InitialFormProgressIndicator({
    super.key,
    required this.phonePageData,
    required this.changeLocale,
  });

  @override
  InitialFormProgressIndicatorState createState() =>
      InitialFormProgressIndicatorState();
}

class InitialFormProgressIndicatorState
    extends LPExtendedState<InitialFormProgressIndicator> {
  int currentStep = 0;
  String name = '';
  bool disclaimerApproved = false;

  bool hasFilled = false;
  List<WizardStep> steps = [];
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

  void next() {
    setState(() {
      //currentStep = steps.length - 1;
      if (currentStep < steps.length - 1) currentStep++;
      //## this is the part that skips the initial form.##//
    });
  }

  void skip() {
    setState(() {
      currentStep = steps.length - 1;
      //if (currentStep < steps.length - 1) currentStep++;
      //## this is the part that skips the initial form.##//
    });
  }

  void prev() {
    setState(() {
      if (currentStep > 0) currentStep--;
    });
  }

  void updateName(name) {
    setState(() {
      this.name = name;
    });
  }

  void submitForm() async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    if (name.isNotEmpty) {
      await service.setItem("name", PersistentMemoryType.String, name);
    }
    navigateToMenu();
  }

  void navigateToMenu() {
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

  //List<Widget> steps = [];
  @override
  void initState() {
    super.initState();
    getHasFilled();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );

    final gender = userInfoProvider.gender;
    if (!userInfoProvider.disclaimerSigned) {
      return DisclaimerPage(changeLocale: widget.changeLocale);
    }
    steps = [
      //<<<<<<<<<<<INITIALFORM PAGES START HERE
      //IF YOU WANT TO ADD PAGES TO INITAL FORM DO IT HERE:
      InitialFormPage1(
        key: GlobalKey<WizardStepState>(debugLabel: 'welcome'),
        next: next,
        prev: prev,
        skip: skip,
        updateName: updateName,
      ),
      InitialFormPage2(
        key: GlobalKey<WizardStepState>(debugLabel: 'personal-info'),
        next: next,
        prev: prev,
        updateName: updateName,
      ),
      ToFormPage(
        key: GlobalKey<WizardStepState>(debugLabel: 'safety-plan-intro'),
        phonePageData: widget.phonePageData,
        changeLocale: widget.changeLocale,
      ),

      //<<<<<<<<<<<PAGES END HERE
    ];
    final step = steps[currentStep];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        } else {
          prev();
        }
      },
      child: Scaffold(
        // No AppBar and no bottomNavigationBar: the design frames carry neither,
        // and splitting the page across three widgets meant no single one could
        // see the whole vertical stack — which is how the title ended up sitting
        // low. Header, content and footer are now slots on one page.
        //
        // The SafeArea belongs here, inside the Scaffold's body: the Scaffold
        // keeps painting its background edge to edge, and only the content is
        // inset. Hoisting it above MaterialApp instead inset the Scaffold too,
        // which left the status-bar and home-indicator strips unpainted — black
        // bands down both edges of every screen.
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OnboardingSizes.screenInset,
            ),
            child: Column(
              children: [
                _IntroHeader(
                  isLastStep: currentStep == steps.length - 1,
                  onSkip: next,
                  onBack: prev,
                  gender: gender,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                // AnimatedSwitcher's default layout is a Stack aligned centre,
                // which vertically centres whichever step is showing. A step
                // whose content fills the height doesn't notice; one that sizes
                // to its content — the personal-info form — gets pushed down,
                // and its title stopped lining up with the other two steps'.
                // Expanding gives every step the same content box.
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  fit: StackFit.expand,
                  children: [...previousChildren, ?currentChild],
                ),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  var begin = const Offset(1.0, 0.0);
                  var end = Offset.zero;
                  var tween = Tween(begin: begin, end: end);
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                    child: KeyedSubtree(key: ValueKey(currentStep), child: step),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: OnboardingGaps.dotsToBottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: OnboardingGaps.actionsToDots,
                    children: [
                      WizardActions(step: step),
                      _IntroStepDots(
                        stepCount: steps.length,
                        currentStep: currentStep,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header row: the back chevron on the reading-start edge, the skip link on the
/// reading-end edge. Figma node 1660:2302 (frames 17/28) places the skip link at
/// the frame's left, which is the end side in RTL. Frames 2 and 19 carry no
/// header control at all; both are kept as deliberate product additions.
///
/// Owns its own top offset, so the page needs no gap of its own.
class _IntroHeader extends StatelessWidget {
  const _IntroHeader({
    required this.isLastStep,
    required this.onSkip,
    required this.onBack,
    required this.gender,
  });

  final bool isLastStep;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final String gender;

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        top: OnboardingGaps.chromeToHeader,
        bottom: OnboardingGaps.headerToTitle,
      ),
      child: SizedBox(
        height: OnboardingSizes.headerHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLastStep)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  key: const Key('intro-header-back'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: onBack,
                ),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: const Key('intro-header-skip'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, OnboardingSizes.headerHeight),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  //## this is the part that skips BOTH forms from the initial screen.##//
                  onPressed: onSkip,
                  child: myText(
                    appLocale.skipButton(gender),
                    TextStyle(
                      fontWeight: AppFontWeight.medium,
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Step indicator. Figma nodes 1660:1269-1271 (frame 2) and 1660:2337-2339
/// (frame 19): 10pt circles on a 21pt pitch, filled green up to and including
/// the current step and drawn as a green outline beyond it.
///
/// Distinct from the questionnaire wizard's `StepDotsIndicator`, whose design
/// really is pills.
class _IntroStepDots extends StatelessWidget {
  const _IntroStepDots({required this.stepCount, required this.currentStep});

  final int stepCount;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      // Pitch comes from the Row's spacing, not a per-dot margin, so a dot's
      // own box is the 10pt circle the design specifies.
      spacing: OnboardingSizes.dotGap,
      children: List.generate(stepCount, (index) {
        return AnimatedContainer(
          key: ValueKey('intro-step-dot-$index'),
          duration: const Duration(milliseconds: 300),
          width: OnboardingSizes.dotSize,
          height: OnboardingSizes.dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= currentStep ? green : Colors.transparent,
            border: Border.all(color: green, width: 1),
          ),
        );
      }),
    );
  }
}
