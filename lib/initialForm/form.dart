import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';

import 'package:mazilon/util/styles.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/initialForm/toFormPage.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/initialForm/initialFormPage1.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/disclaimerPage.dart';

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
  List<Widget> steps = [];
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
        next: next,
        prev: prev,
        skip: skip,
        updateName: updateName,
      ),
      InitialFormPage2(next: next, prev: prev, updateName: updateName),
      ToFormPage(
        phonePageData: widget.phonePageData,
        changeLocale: widget.changeLocale,
      ),

      //<<<<<<<<<<<PAGES END HERE
    ];
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
          preferredSize: const Size.fromHeight(40),
          child: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: lightGray,
            automaticallyImplyLeading: currentStep != (steps.length - 1),
            leading: currentStep != (steps.length - 1)
                ? IconButton(
                    icon: myAutoSizedText(
                      appLocale.skipButton(gender),
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
                      null,
                      25,
                    ),
                    onPressed: () {
                      //## this is the part that skips BOTH forms from the initial screen.##//
                      debugPrint('skipping');
                      next();
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      prev();
                    },
                  ),
          ),
        ),
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            //visual representation of the progress of the form:
            children: List.generate(
              steps.length, // Adjust the number of stages here
              //Animated Container for a non-instant color change, otherwise can be container
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 15.0,
                height: 15.0,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  color: index <= currentStep ? appGreen : lightGray,
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }
}
