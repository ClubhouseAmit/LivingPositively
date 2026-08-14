// ignore_for_file: annotate_overrides
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/form/formpagetemplate.dart';
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

/// Width budget for the controls flanking the centred progress dots. The
/// dots are centred on the screen (per the design) rather than in the space
/// left over by their neighbours, so a long label would otherwise run into
/// them — the design's own copy is short ("דלג/י") but this app's is
/// "save and exit", and Arabic is longer still. Bounding the label lets
/// `myAutoSizedText` shrink it instead of colliding.
const double _headerSideControlMaxFraction = 0.30;

List<String> pages = [
  'PersonalPlan-Distractions',
  'PersonalPlan-DifficultEvents',
  'PersonalPlan-FeelBetter',
  'PersonalPlan-MakeSafer',
  'PersonalPlan-SafeEnvironment',
];

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

  void submitForm(mycontext) async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    if (name.isNotEmpty) {
      await service.setItem("name", PersistentMemoryType.String, name);
    }
    navigateToMenu(mycontext);
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

  List<Widget> steps = [];
  @override
  void initState() {
    super.initState();
    //initialize steps on form load:
    //if you want to add a page on the personal plan form, add it here:
    //use formpageTemplate.dart for checkbox pages with data from database below and selected items above.
    //create your own class for other pages.

    steps = [
      FormPageTemplate(
        key: UniqueKey(),
        next: next,
        prev: prev,
        collectionName: pages[0],
      ),
      FormPageTemplate(
        key: UniqueKey(),
        next: next,
        prev: prev,
        collectionName: pages[1],
      ),
      FormPageTemplate(
        key: UniqueKey(),
        next: next,
        prev: prev,
        collectionName: pages[2],
      ),
      FormPageTemplate(
        key: UniqueKey(),
        next: next,
        prev: prev,
        collectionName: pages[3],
      ),
      //<<<<<<<<<<<CHECKBOX PAGES END HERE
      //add contacts page:
      PhonePageForm(
        next: next,
        prev: prev,
        phonePageData: widget.phonePageData,
      ),
      FormPageTemplate(
        key: UniqueKey(),
        next: next,
        prev: prev,
        collectionName: pages[4],
      ),
      ShareForm(prev: prev, submit: submitForm),
    ];
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
          prev();
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
            flexibleSpace: SafeArea(
              bottom: false,
              //Skip link, progress dots and back chevron share one line,
              //vertically centred on each other (Figma: all three centre on
              //the same y). SafeArea keeps them below the status bar instead
              //of centring across it, and the row sits at the bottom of the
              //bar so the gap to the page title matches the design.
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  //Same screen-edge inset as the page body below.
                  padding: const EdgeInsets.symmetric(
                    horizontal: _screenInset,
                  ),
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
                              prev();
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
                            maxWidth:
                                MediaQuery.sizeOf(context).width *
                                _headerSideControlMaxFraction,
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 33),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              navigateToMenu(context);
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
        //animation for switching between pages:
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _screenInset),
          child: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 300,
            ), // Specify the duration of the animation
            transitionBuilder: (Widget child, Animation<double> animation) {
              var begin = const Offset(1.0, 0.0);
              var end = Offset.zero;
              var tween = Tween(begin: begin, end: end);

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            child: steps[currentStep],
          ),
        ),
      ),
    );
  }
}
