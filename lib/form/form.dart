// ignore_for_file: annotate_overrides
import 'dart:math' show max;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/async/persistence_retry_snack_bar.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/form/wizard_steps.dart';
import 'package:mazilon/menu.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:provider/provider.dart';

import 'package:mazilon/util/userInformation.dart';

/// Screen-edge inset for the onboarding wizard — the Figma frames place the
/// header controls and the page content on the same margin, so the header
/// and the body share this one value rather than drifting apart.
const double _screenInset = 16;

/// Clearance between the centred progress dots and the controls flanking
/// them. The dots are centred on the screen (per the design) rather than in
/// the space left over by their neighbours, so a long label runs into them
/// unless it is bounded — the design's own copy is short ("דלג/י") but this
/// app's is "save and exit", and Arabic is longer still. The bound is the
/// space actually left beside the dots, so it holds at any width; a fixed
/// fraction of the screen did not, and the label overlapped the dots below
/// about 400px in every language.
const double _headerControlGutter = 8;

/// Width available to one side control at [screenWidth] for [stepCount] dots.
double headerSideControlMaxWidth(double screenWidth, int stepCount) => max(
  0.0,
  (screenWidth - _screenInset * 2 - stepDotsWidth(stepCount)) / 2 -
      _headerControlGutter,
);

class FormProgressIndicator extends StatefulWidget {
  final PhonePageData phonePageData;
  final Function changeLocale;

  const FormProgressIndicator({
    super.key,
    required this.phonePageData,
    required this.changeLocale,
  });

  @override
  FormProgressIndicatorState createState() => FormProgressIndicatorState();
}

class FormProgressIndicatorState
    extends LPExtendedState<FormProgressIndicator> {
  int currentStep = 0;
  String name = '';
  bool _headerNavigationInFlight = false;

  void next() {
    setState(() {
      if (currentStep < steps.length - 1) currentStep++;
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

  Future<void> submitForm(BuildContext context) async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    if (name.isNotEmpty) {
      await service.setItem("name", PersistentMemoryType.String, name);
    }
    if (!context.mounted) return;
    navigateToMenu(context);
  }

  void navigateToMenu(mycontext) {
    Navigator.pushAndRemoveUntil(
      mycontext,
      MaterialPageRoute(
        builder: (context) => Menu(
          phonePageData: widget.phonePageData,
          hasFilled: true,
          changeLocale: widget.changeLocale,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _persistThenNavigate(
    BuildContext context,
    VoidCallback navigate, {
    bool retry = false,
  }) async {
    if (_headerNavigationInFlight) {
      return;
    }
    _headerNavigationInFlight = true;
    try {
      final WizardStepState? stepState =
          steps[currentStep].stepKey.currentState;
      if (retry) {
        await stepState?.retryPersistBeforeExit();
      } else {
        await stepState?.persistBeforeExit();
      }
      if (mounted) {
        navigate();
      }
    } catch (error, stackTrace) {
      if (retry) {
        await _captureHeaderRetryFailure(error, stackTrace);
      }
      if (mounted) {
        _showHeaderPersistenceFailure(
          () => _persistThenNavigate(context, navigate, retry: true),
        );
      }
    } finally {
      _headerNavigationInFlight = false;
    }
  }

  void _showHeaderPersistenceFailure(Future<void> Function() retry) {
    showPersistenceRetrySnackBar(context, retry);
  }

  Future<void> _captureHeaderRetryFailure(
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      await GetIt.instance<IncidentLoggerService>().captureLog(
        error,
        stackTrace: stackTrace,
      );
    } catch (_) {
      // Logging is best effort; it must not hide the retry affordance.
    }
  }

  List<WizardStep> steps = [];
  @override
  void initState() {
    super.initState();
    steps = buildWizardSteps(
      next: next,
      prev: prev,
      phonePageData: widget.phonePageData,
      submit: submitForm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );

    final gender = userInfoProvider.gender;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        } else {
          await _persistThenNavigate(context, prev);
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            //no separate header container in the Figma template — the skip
            //link and progress dots sit directly on the page background.
            backgroundColor: Colors.transparent,
            //Skip link, progress dots and back chevron share one line,
            //vertically centred on each other (Figma: all three centre on the
            //same y). SafeArea keeps them below the status bar instead of
            //centring across it, and the row sits at the bottom of the bar so
            //the gap to the page title matches the design.
            flexibleSpace: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  //Same screen-edge inset as the page body below.
                  padding: const EdgeInsets.symmetric(horizontal: _screenInset),
                  //A Stack, not a Row: the design centres the progress dots
                  //on the screen, independent of the two controls flanking
                  //them. In a Row they would instead centre in the leftover
                  //space between a wide skip label and a narrow chevron.
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      StepDotsIndicator(
                        context,
                        stepCount: steps.length,
                        currentStep: currentStep,
                      ),
                      //Figma: the chevron is an 11x20 glyph sitting on the
                      //screen-edge inset, not a padded icon button.
                      if (currentStep > 0)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.arrow_back_ios, size: 20),
                            onPressed: () {
                              unawaited(_persistThenNavigate(context, prev));
                            },
                          ),
                        ),
                      //TextButton, not IconButton: IconButton sizes its
                      //tap target for a small square icon, which forced
                      //this multi-word label to wrap onto two lines. The
                      //padding reset keeps the label on the screen-edge
                      //inset set by the Padding above.
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: headerSideControlMaxWidth(
                              MediaQuery.sizeOf(context).width,
                              steps.length,
                            ),
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 33),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              unawaited(
                                _persistThenNavigate(
                                  context,
                                  () => navigateToMenu(context),
                                ),
                              );
                            },
                            child: myAutoSizedText(
                              appLocale.saveAndQuitButton(gender),
                              TextStyle(
                                fontWeight: AppFontWeight.medium,
                                fontSize: 16.sp,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              null,
                              16,
                              1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Top inset is the AppBar's; this only guards the bottom.
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _screenInset),
            // This flow's header and step dots live in the Scaffold's AppBar
            // above, so there is nothing above the step here.
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: OnboardingGaps.questionnaireHeaderToContent,
                    ),
                    child: steps[currentStep],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: OnboardingGaps.questionnaireAroundActions,
                  ),
                  child: WizardActions(step: steps[currentStep]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
