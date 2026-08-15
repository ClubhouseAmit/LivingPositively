import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/initialForm/toFormPage.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/initialForm/initialFormPage1.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/disclaimerPage.dart';

// Design-derived layout constants for the onboarding intro flow.
const double _screenInset = 15.0;
const double _chromeToHeader = 27.0;
const double _headerToTitle = 20.0;
const double _headerHeight = 33.0;
const double _actionsToDots = 28.0;
const double _dotsToBottom = 26.0;
const double _dotSize = 10.0;
const double _dotGap = 11.0;

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
  bool hasFilled = false;
  List<WizardStep> steps = [];

  void getHasFilled() async {
    final service = GetIt.instance<PersistentMemoryService>();
    final hasFilledValue = await service.getItem(
      "hasFilled",
      PersistentMemoryType.Bool,
    );
    if (mounted) {
      setState(() {
        hasFilled = hasFilledValue ?? false;
      });
    }
  }

  void next() {
    setState(() {
      if (currentStep < steps.length - 1) currentStep++;
    });
  }

  void skip() {
    setState(() {
      currentStep = steps.length - 1;
    });
  }

  void prev() {
    setState(() {
      if (currentStep > 0) currentStep--;
    });
  }

  void updateName(String name) {
    setState(() {
      this.name = name;
    });
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

  @override
  void initState() {
    super.initState();
    getHasFilled();
    steps = [
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
    ];
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _screenInset,
            ),
            child: Column(
              children: [
                _IntroHeader(
                  isLastStep: currentStep == steps.length - 1,
                  onSkip: next,
                  onBack: prev,
                  skipLabel: appLocale.skipButton(gender),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
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
                    bottom: _dotsToBottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: _actionsToDots,
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
/// reading-end edge (Figma node 1660:2302).
class _IntroHeader extends StatelessWidget {
  const _IntroHeader({
    required this.isLastStep,
    required this.onSkip,
    required this.onBack,
    required this.skipLabel,
  });

  final bool isLastStep;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: _chromeToHeader,
        bottom: _headerToTitle,
      ),
      child: SizedBox(
        height: _headerHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLastStep)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  key: const Key('intro-header-back'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, _headerHeight),
                  ),
                  onPressed: onSkip,
                  child: Text(
                    skipLabel,
                    style: TextStyle(
                      fontWeight: AppFontWeight.medium,
                      fontSize: 16.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Step indicator (Figma nodes 1660:1269-1271 / 1660:2337-2339).
class _IntroStepDots extends StatelessWidget {
  const _IntroStepDots({required this.stepCount, required this.currentStep});

  final int stepCount;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: _dotGap,
      children: [
        for (int index = 0; index < stepCount; index++)
          AnimatedContainer(
            key: ValueKey('intro-step-dot-$index'),
            duration: const Duration(milliseconds: 300),
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index <= currentStep ? green : Colors.transparent,
              border: Border.all(color: green, width: 1),
            ),
          ),
      ],
    );
  }
}
