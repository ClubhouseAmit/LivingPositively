import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/disclaimerPage.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/initialForm/initialFormPage1.dart';
import 'package:mazilon/initialForm/initialFormPage2.dart';
import 'package:mazilon/initialForm/toFormPage.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class InitialFormProgressIndicator extends StatefulWidget {

  const InitialFormProgressIndicator({
    required this.phonePageData, required this.changeLocale, super.key,
  });
  final PhonePageData phonePageData;
  final Function changeLocale;

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
  Future<void> getHasFilled() async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    final hasFilledValue = await service.getItem(
      'hasFilled',
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

  Future<void> submitForm() async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    if (name.isNotEmpty) {
      await service.setItem('name', PersistentMemoryType.String, name);
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
      (route) => false,
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
      child: PageLayoutWrapper(
        backgroundColor: Colors.white,
        sliverAppBar: PremiumGlassAppBar(
          variant: AppBarVariant.detailScreen,
          toolbarHeight: 50,
          onBackPressed: currentStep > 0 ? prev : null,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 300,
          ), // Specify the duration of the animation
          transitionBuilder: (child, animation) {
            const begin = Offset(1, 0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          child: steps[currentStep],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            //visual representation of the progress of the form:
            children: List.generate(
              steps.length, // Adjust the number of stages here
              //Animated Container for a non-instant color change, otherwise can be container
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 15,
                height: 15,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: index <= currentStep
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }
}
