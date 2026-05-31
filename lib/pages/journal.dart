import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/pages/thankYou.dart';
import 'package:mazilon/util/Thanks/thanksItemSug.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

//Journal page, where the user can write thank you notes (add , edit, remove notes)
//the user can also see suggested thank you notes and refresh them
//(the code here is not related to todo list in home page, its the thank you notes page)
class Journal extends StatefulWidget {
  final List<String> fullSuggestionList;
  const Journal({required this.fullSuggestionList, super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends LPExtendedState<Journal> {
  List<String> thankYous = []; //list of thank you notes
  List<FocusNode> focusNodes = []; //list of focus nodes for each thank you note
  List<String> dates = []; //list of dates for each thank you note
  FocusNode myFocusNode = FocusNode(); //focus node for the text field
  String journalMainTitle = ''; //journal main title
  String journalSubTitle = ''; //journal sub title
  String sug1 = ''; //suggested thank you note 1
  String sug2 = ''; //suggested thank you note 2
  String sug3 = ''; //suggested thank you note 3
  int counter =
      0; //counter for the number of thank you notes you added (reset to 0 every time you enter the journal page again)
  List<String> thanksSuggestionList = []; //list of thank you notes suggestions
  List<String> todayThankYousFunc(List<String> thankYous, List<String> dates) {
    List<String> todayThankYous = [];
    DateTime now = DateTime.now();
    String formattedDate = intl.DateFormat('yyyy-MM-dd – kk:mm').format(now);

    for (int i = 0; i < dates.length; i++) {
      if (dates[i].substring(0, 10) == formattedDate.substring(0, 10)) {
        todayThankYous.add(thankYous[i]);
      }
    }
    return todayThankYous;
  }

  //load the thank you notes and suggestions from the shared preferences
  void loadData(BuildContext context) {
    debugPrint("loading journal");
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );

    setState(() {
      thankYous = userInfoProvider.thanks['thanks'] ?? [];
      dates = dates = userInfoProvider.thanks['dates'] ?? [];
      for (var _ in thankYous) {
        focusNodes.add(FocusNode());
      }
      List<String> tempThanksSuggestionList = List.from(
        widget.fullSuggestionList,
      );
      thanksSuggestionList = List.from(tempThanksSuggestionList);

      // remove the thank you notes suggestions that are already in the thank you notes list
      for (String suggestion in tempThanksSuggestionList) {
        if (thanksSuggestionList.length > 3 && thankYous.contains(suggestion)) {
          thanksSuggestionList.remove(suggestion);
        }
      }
      var indices = List<int>.generate(thanksSuggestionList.length, (i) => i);
      indices.shuffle();
      sug1 = thanksSuggestionList[indices[0]];
      sug2 =
          thanksSuggestionList[indices[thanksSuggestionList.length > 1
              ? 1
              : 0]];
      sug3 =
          thanksSuggestionList[indices[thanksSuggestionList.length > 2
              ? 2
              : 0]];
    });
  }

  // change the thank you note text at the index to the new text
  void editThankYou(String text, int index, UserInformation userinfoProvider) {
    setState(() {
      thankYous[index] = text;
      userinfoProvider.updateThanks({
        'thanks': thankYous,
        'dates': userinfoProvider.thanks['dates'] ?? [],
      });
    });
  }

  // remove the thank you note at the index
  void removeThankYou(int removeIndex, UserInformation userInfoProvider) {
    List<String> thankyousTemp = userInfoProvider.thanks['thanks'] ?? [];
    List<String> datesTemp = userInfoProvider.thanks['dates'] ?? [];
    thankyousTemp.removeAt(removeIndex);
    datesTemp.removeAt(removeIndex);
    setState(() {
      userInfoProvider.updateThanks({
        'thanks': thankyousTemp,
        'dates': datesTemp,
      });
      thankYous = thankyousTemp;
      focusNodes.removeAt(removeIndex);
      dates = datesTemp;
    });
  }

  // add the thank you note to the list
  void addThankYou(String thankYou, UserInformation userInfoProvider) {
    counter = counter < 6 ? counter + 1 : counter;
    List<String> thankyousTemp = userInfoProvider.thanks['thanks'] ?? [];
    List<String> datesTemp = userInfoProvider.thanks['dates'] ?? [];
    thankyousTemp.add(thankYou);
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    datesTemp.add(formattedDate);
    setState(() {
      userInfoProvider.updateThanks({
        'thanks': thankyousTemp,
        'dates': datesTemp,
      });
      thankYous = thankyousTemp;
      focusNodes.add(FocusNode());

      dates = datesTemp;
    });
    //show the popup after adding the first thank you note (every time you enter the journal page)
    if (todayThankYousFunc(
          userInfoProvider.thanks["thanks"] ?? [],
          userInfoProvider.thanks["dates"] ?? [],
        ).length ==
        1) {
      showThankYouPopup(userInfoProvider);
    }
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent("Item added to Gratitude Journal");
    //you can show the popup after adding the i-th thank you note (every time you enter the journal page)
    // if(counter == i){
    //   showPopupFunction();
    // }
  }

  //show the popup with the text from the shared preferences
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
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15.sp),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  appLocale.confirmButton(gender),
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  //load the data when the page is opened
  @override
  void initState() {
    super.initState();
  }

  // function we call when we want to add/edit a thank you note (to open the popup with the text field which is AddForm widget)
  void editThanks(String title, [String text = '', int index = 0]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddForm(
          add: addThankYou,
          index: index,
          edit: editThankYou,
          text: text,
          formTitle: title,
        );
      },
    );
  }

  // build the journal page
  @override
  Widget build(BuildContext context) {
    // get the app and user information providers

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final gender = userInfoProvider.gender;
    debugPrint("loading journal");
    loadData(context);
    return KeyboardDismisser(
      gestures: const [GestureType.onTap, GestureType.onPanUpdateAnyDirection],
      child: Scaffold(
        backgroundColor: appWhite,
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 40, 20, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: myAutoSizedText(
                          appLocale.homePageThanksMainTitle(gender),
                          TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30.sp,
                          ),
                          null,
                          60,
                        ),
                      ),

                      //the add button to add a new thank you note
                      IconButton(
                        //when the button is pressed, open the popup with empty text field to write a new thank you note
                        onPressed: () {
                          editThanks(appLocale.thanks);
                        },
                        tooltip: appLocale.addItemTooltip,
                        icon: Icon(Icons.add, size: 50.0, color: primaryPurple),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      //the subtitle of the journal page
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: myAutoSizedText(
                          appLocale.homePageThanksSecondaryTitle(gender),
                          TextStyle(
                            color: darkGray,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          null,
                          30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            //the list of thank you notes
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => ThankYou(
                text: thankYous[index],
                number: (index + 1),
                edit: (String text, int index) {
                  editThanks(appLocale.thanks, text, index);
                },
                remove: (int index) => removeThankYou(index, userInfoProvider),
                myFocusNode: focusNodes[index],
                date: dates[index],
                color: Colors.black,
              ),
              itemCount: thankYous.length,
            ),
            thankYous.isEmpty
                ? Container()
                : Divider(color: darkGray, indent: 30, endIndent: 30),
            //the suggested thank you notes
            ThanksItemSuggested(
              stopShowing: 3,
              add: addThankYou,
              inputText: sug1,
              fullSuggestionList: retrieveThanksList(
                appLocale,
                gender == "" ? "other" : gender,
              ),
            ),
            ThanksItemSuggested(
              stopShowing: 2,
              add: addThankYou,
              inputText: sug2,
              fullSuggestionList: retrieveThanksList(
                appLocale,
                gender == "" ? "other" : gender,
              ),
            ),
            ThanksItemSuggested(
              stopShowing: 1,
              add: addThankYou,
              inputText: sug3,
              fullSuggestionList: retrieveThanksList(
                appLocale,
                gender == "" ? "other" : gender,
              ),
            ),
            //the button to refresh the suggested thank you notes and get 3 new suggestions
            TextButton(
              onPressed: () async {
                setState(() {
                  //remove the thank you notes suggestions that are already in the thank you notes list (a.k.a chosen by the user already)
                  List<String> tempThanksSuggestionList = List.from(
                    widget.fullSuggestionList,
                  );
                  thanksSuggestionList = List.from(tempThanksSuggestionList);
                  for (String suggestion in tempThanksSuggestionList) {
                    if (thanksSuggestionList.length > 3 &&
                        thankYous.contains(suggestion)) {
                      thanksSuggestionList.remove(suggestion);
                    }
                  }
                  var indices = List<int>.generate(
                    thanksSuggestionList.length,
                    (i) => i,
                  );
                  indices.shuffle();
                  sug1 = thanksSuggestionList[indices[0]];
                  sug2 =
                      thanksSuggestionList[indices[thanksSuggestionList.length >
                              1
                          ? 1
                          : 0]];
                  sug3 =
                      thanksSuggestionList[indices[thanksSuggestionList.length >
                              2
                          ? 2
                          : 0]];
                });
              },
              //the text of the refresh button
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    appLocale.otherSuggestions(gender),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: appGreen,
                    ),
                  ),
                  const SizedBox(width: 1.0),
                  Icon(Icons.refresh, color: appGreen),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
