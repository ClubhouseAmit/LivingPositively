import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

List<String> pages = [
  'PersonalPlan-DifficultEvents',
  'PersonalPlan-MakeSafer',
  'PersonalPlan-FeelBetter',
  'PersonalPlan-Distractions',
];

class FormProgressIndicator extends StatefulWidget {

  const FormProgressIndicator({
    required this.phonePageData, required this.changeLocale, super.key,
  });
  final PhonePageData phonePageData;
  final Function changeLocale;

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

  void updateName(String name) {
    setState(() {
      this.name = name;
    });
  }

  Future<void> submitForm(BuildContext mycontext) async {
    final service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    if (name.isNotEmpty) {
      await service.setItem('name', PersistentMemoryType.String, name);
    }
    navigateToMenu(mycontext);
  }

  void navigateToShare() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ShareForm(prev: prev, submit: submitForm),
      ),
      (route) => false,
    );
  }

  void navigateToMenu(BuildContext mycontext) {
    Navigator.pushAndRemoveUntil(
      mycontext,
      MaterialPageRoute(
        builder: (context) => Menu(
          phonePageData: widget.phonePageData,
          hasFilled: true,
          changeLocale: widget.changeLocale,
        ),
      ),
      (route) => false,
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
      child: PageLayoutWrapper(
        backgroundColor: Colors.white,
        sliverAppBar: PremiumGlassAppBar(
          variant: AppBarVariant.detailScreen,
          toolbarHeight: 90,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: currentStep > 0
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
                  if (currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: prev,
                    ),
                  TextButton(
                    child: AutoSizeText(
                      appLocale.saveAndQuitButton(gender),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    onPressed: () {
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
                    width: 20,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: index <= currentStep
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ).toList(),
              ),
            ],
          ),
        ),
        //animation for switching between pages:
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
      ),
    );
  }
}
