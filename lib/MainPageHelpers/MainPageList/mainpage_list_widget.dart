import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/MainPageHelpers/MainPageList/mainpage_list_body_widget.dart';
import 'package:mazilon/MainPageHelpers/MainPageList/list_utils.dart';
import 'package:mazilon/MainPageHelpers/show_all_button.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/HomePage/sectionBarHome.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/Traits/positiveTraitItemSug.dart';

// the trait list widget, it shows the list of the traits
// this code is related to "מעלות" section in homepage.
// this code is similar to thanksListWidget.dart .
class ListWidget extends StatefulWidget {
  final Function(BuildContext, PagesCode)
  onTabTapped; // the function to navigate to another page
  final PagesCode pageCode; // the title of the widget
  const ListWidget({
    super.key,
    required this.onTabTapped,
    required this.pageCode,
  });
  @override
  State<ListWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends LPExtendedState<ListWidget> {
  List<String> todayThankYous = [];
  List<String> listItems = [];
  @override
  void initState() {
    super.initState();
  }

  void showThankYouPopup(UserInformation userInfoProvider) {
    Future.delayed(const Duration(seconds: 0), () {
      if (!mounted) {
        return;
      }
      final gender = userInfoProvider.gender;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(''),
            content: Text(
              appLocale.homePageThankyouPopup(gender),
              // Plain `.sp` so the popup respects the user's text-scale.
              // The previous `min(24, 14.sp)` capped upward on large devices,
              // shrinking the message exactly when the user asked for larger
              // text — see UX_GAPS §1.7.
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text(
                  appLocale.confirmButton(gender),
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  void editThanksState(
    List<String> thankyousTemp,
    List<String> datesTemp,
    userInfoProvider,
  ) {
    setState(() {
      userInfoProvider.updateThanks({
        'thanks': thankyousTemp,
        'dates': datesTemp,
      });

      todayThankYous = todayThankYousFunc(thankyousTemp, datesTemp);
    });
  }

  void editTraitsState(positivetraitsTemp, userInfoProvider) {
    setState(() {
      userInfoProvider.updatePositiveTraits(positivetraitsTemp);
    });
  }

  Function getSuggestionBox(appLocale) {
    if (widget.pageCode == PagesCode.QualitiesList) {
      return (stopShowingNumber, gender) =>
          buildPositiveTraitItemSug(stopShowingNumber, gender, appLocale);
    } else {
      return (stopShowingNumber, gender) =>
          buildThanksItemSug(stopShowingNumber, gender, appLocale);
    }
  }

  void editTrait(String title, [String text = '', int index = 0]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddForm(
          add: (positiveTrait, userInfoProvider) => addPositiveTrait(
            positiveTrait,
            userInfoProvider,
            editTraitsState,
          ),
          index: index,
          edit: (text, index, userInfoProvider) =>
              editPositiveTrait(text, index, userInfoProvider, editTraitsState),
          text: text,
          formTitle: title,
        );
      },
    );
  }

  void editThanks(String title, [String text = '', int index = 0]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddForm(
          add: (thankYou, userInfoProvider) => addThankYou(
            thankYou,
            userInfoProvider,
            editThanksState,
            showThankYouPopup,
          ),
          index: index,
          edit: (text, index, userInfoProvider) =>
              editThankYou(text, index, userInfoProvider, editThanksState),
          text: text,
          formTitle: title,
        );
      },
    );
  }

  Function(int index) editItemFunction(
    userInfoProvider,
    thanksListLength,
    traitsListlength,
  ) {
    if (widget.pageCode == PagesCode.GratitudeJournal) {
      return (index) => editThanks(
        appLocale.thanks,
        todayThankYous[index],
        thanksListLength - todayThankYous.length + index,
      );
    } else {
      return (index) => editTrait(
        appLocale.trait,
        userInfoProvider.positiveTraits[index],
        traitsListlength - userInfoProvider.positiveTraits.length + index,
      );
    }
  }

  Function(int index) removeItemFunction(
    userInfoProvider,
    thanksListLength,
    traitsListlength,
  ) {
    if (widget.pageCode == PagesCode.GratitudeJournal) {
      return (index) => removeThankYou(
        thanksListLength - todayThankYous.length + index,
        userInfoProvider,
        editThanksState,
      );
    } else {
      return (index) => removePositiveTrait(
        traitsListlength - userInfoProvider.positiveTraits.length + index,
        userInfoProvider,
        editTraitsState,
      );
    }
  }

  Widget buildThanksItemSug(stopShowingNumber, gender, appLocale) {
    return ThanksItemSuggested(
      stopShowing: stopShowingNumber,
      add: (thankYou, userInfoProvider) => {
        addThankYou(
          thankYou,
          userInfoProvider,
          editThanksState,
          showThankYouPopup,
        ),
      },
      inputText: "",
      fullSuggestionList: retrieveThanksList(
        appLocale,
        gender == "" ? "other" : gender,
      ),
    );
  }

  Widget buildPositiveTraitItemSug(stopShowingNumber, gender, appLocale) {
    return PositiveTraitItemSug(
      stopShowing: stopShowingNumber,
      add: (trait, userInfoProvider) => {
        addPositiveTrait(trait, userInfoProvider, editTraitsState),
      },
      inputText: "",
      fullSuggestionList: retrieveTraitsList(
        appLocale,
        gender == "" ? "other" : gender,
      ),
    );
  }

  void addItemFunction() {
    if (widget.pageCode == PagesCode.QualitiesList) {
      editTrait(appLocale.trait); // the function to add a trait
    } else {
      editThanks(appLocale.thanks); // the function to add a thanks
    }
  }

  // build the trait list widget
  @override
  Widget build(BuildContext context) {
    // get the app information provider and the user information provider

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;
    final traitsListlength = userInfoProvider.positiveTraits.length;
    final thanksListLength = userInfoProvider.thanks['thanks']?.length ?? 0;
    todayThankYous = todayThankYousFunc(
      userInfoProvider.thanks["thanks"] ?? [],
      userInfoProvider.thanks["dates"] ?? [],
    );
    final pageData = getLocalizedTextForLists(
      appLocale,
      gender,
      widget.pageCode,
    );
    final listItems = getListItems(
      widget.pageCode,
      userInfoProvider,
      todayThankYous,
    );
    final sugBox = getSuggestionBox(appLocale);
    return SizedBox(
      // the width of the widget is 800 if the screen width is more than 1000, otherwise it is the screen width
      width: MediaQuery.of(context).size.width > 1000
          ? 800
          : MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          children: [
            // the section bar of the trait list ,
            // which contains the title, the icon, the subheader and the add icon,
            // when its clicked it navigates to the add trait page
            SectionBarHome(
              textWidget: TextButton(
                onPressed: () {
                  widget.onTabTapped(context, widget.pageCode);
                },
                child: myAutoSizedText(
                  pageData['mainTitle'],
                  TextStyle(
                    fontSize: 24.sp, // the font size of the title
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // the color of the title
                  ),
                  null,
                  40,
                ),
              ),
              icon: pageData["icon"], // the icon of the section bar
              icons: [
                // add button with the add icon
                IconButton(
                  icon: mainpageListsAddIcon,
                  tooltip: appLocale.addItemTooltip,
                  onPressed: addItemFunction,
                ),
              ],

              // the subheader of the section bar
              subHeader: pageData['secondaryTitle'] ?? "",
            ),
            // gap between the section bar and the trait list
            const SizedBox(height: 10),
            // a suggested trait with add button
            sugBox(1, gender),
            sugBox(2, gender),
            sugBox(3, gender),
            ListBodyWidget(
              listItems: listItems,
              editItems: editItemFunction(
                userInfoProvider,
                thanksListLength,
                traitsListlength,
              ),
              removeItems: removeItemFunction(
                userInfoProvider,
                thanksListLength,
                traitsListlength,
              ),
            ),
            // the list of the traits
            // the see all button
            ShowAllButton(
              onTabTapped: widget.onTabTapped,
              pageCode: widget.pageCode,
            ),
          ],
        ),
      ),
    );
  }
}
