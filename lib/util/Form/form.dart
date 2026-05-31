// ignore_for_file: annotate_overrides
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/menu.dart';

import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/util/styles.dart';
import 'package:provider/provider.dart';

import 'package:mazilon/util/userInformation.dart';

import 'package:mazilon/l10n/app_localizations.dart';

List<String> pages = [
  'PersonalPlan-DifficultEvents',
  'PersonalPlan-MakeSafer',
  'PersonalPlan-FeelBetter',
  'PersonalPlan-Distractions',
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

class FormProgressIndicatorState extends State<FormProgressIndicator> {
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

  void navigateToShare() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ShareForm(prev: prev, submit: submitForm),
      ),
      (Route<dynamic> route) => false,
    );
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
        next: navigateToShare,
        prev: prev,
        phonePageData: widget.phonePageData,
      ),

      //ShareForm(prev: prev, submit: submitForm),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );

    final gender = userInfoProvider.gender;
    final appLocale = AppLocalizations.of(context);
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
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Container(
                  height: constraints.maxHeight,
                  color: lightGray,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: currentStep > (0)
                            ? MainAxisAlignment.spaceBetween
                            : MainAxisAlignment.end,
                        children: [
                          if (currentStep > (0))
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: () {
                                prev();
                              },
                            ),
                          IconButton(
                            icon: myAutoSizedText(
                              appLocale!.saveAndQuitButton(gender),
                              TextStyle(fontSize: 23.sp),
                              null,
                              23,
                            ),
                            onPressed: () {
                              //clicked next button:

                              //clicked skip button:
                              navigateToMenu(context);
                            },
                          ),
                        ],
                      ),
                      // Bottom widget
                      // Progress indicator for the form:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          1 + pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 20.0,
                            height: 10.0,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              color: index <= currentStep
                                  ? primaryPurple
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        //animation for switching between pages:
        body: AnimatedSwitcher(
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
    );
  }
}
