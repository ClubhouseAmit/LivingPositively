import 'package:flutter/material.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:mazilon/util/LP_extended_state.dart';

import 'package:mazilon/util/styles.dart';

import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

// the thanks item suggested widget, it shows a suggested thank you text and an add button
//its used in journal/homepage in todo list section to suggest a thank you to the user
// we use this in 2 ways , if the input text is not empty, it will show the input text in the suggestion
// if the input text is empty, it will show a random thank you from the suggested thank yous list that is not written today
class ThanksItemSuggested extends StatefulWidget {
  final Function add; // the function to add the thankyou to the list
  final String inputText; // the input text of the thank you
  final List<String> fullSuggestionList;
  final int stopShowing;
  const ThanksItemSuggested({
    super.key,
    required this.add,
    required this.inputText,
    required this.stopShowing,
    required this.fullSuggestionList,
  });

  @override
  State<ThanksItemSuggested> createState() => _ThanksItemSuggestedState();
}

class _ThanksItemSuggestedState extends LPExtendedState<ThanksItemSuggested> {
  String text = ''; // the text of the suggested thank you (initially empty)
  List<String> myThanks = []; // the list of the thank yous
  List<String> thanksSuggestionList =
      []; // the list of the suggested thank yous
  bool show = true;
  // function to get the thank yous written today (the date of the thank you is today)
  List<String> todayThankYousFunc(List<String> thankYous, List<String> dates) {
    List<String> todayThankYous = [];
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    for (int i = 0; i < dates.length; i++) {
      if (dates[i].substring(0, 10) == formattedDate.substring(0, 10)) {
        todayThankYous.add(thankYous[i]);
      }
    }
    return todayThankYous;
  }

  void loadData(BuildContext context) {
    // get the shared preferences

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    setState(() {
      List<String> thankYous = userInfoProvider.thanks['thanks'] ?? [];
      List<String> dates = userInfoProvider.thanks['dates'] ?? [];

      myThanks = todayThankYousFunc(thankYous, dates);
      List<String> tempThanksSuggestionList = List.from(
        widget.fullSuggestionList,
      );

      thanksSuggestionList = List.from(tempThanksSuggestionList);
      // remove the thank yous that are already written today from the suggested thank yous
      for (String suggestion in tempThanksSuggestionList) {
        if (thanksSuggestionList.length > 1 && myThanks.contains(suggestion)) {
          thanksSuggestionList.remove(suggestion);
        }
      }
      if (widget.stopShowing > 0 &&
          thanksSuggestionList.length < widget.stopShowing) {
        show = false;
      } else {
        show = true;
      }
      text =
          thanksSuggestionList[Random().nextInt(thanksSuggestionList.length)];
    });
  }

  @override
  void initState() {
    super.initState();
  }

  // build the thanks item suggested widget
  @override
  Widget build(BuildContext context) {
    // get the appInformation provider

    final userInfoProvider = Provider.of<UserInformation>(context);
    loadData(context);
    if (!show) {
      return Container();
    }
    return Container(
      padding: const EdgeInsets.all(10),
      // the row that contains the suggested thank you and the add button
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // the add button
          GestureDetector(
            // when the add button is clicked ,
            // add the thank you to the list of thank yous and update the suggested thank you to a new one
            onTap: () {
              setState(() {
                widget.add(
                  widget.inputText == '' ? text : widget.inputText,
                  userInfoProvider,
                );
                List<String> thankYous =
                    userInfoProvider.thanks['thanks'] ?? [];
                List<String> dates = userInfoProvider.thanks['dates'] ?? [];
                myThanks = todayThankYousFunc(thankYous, dates);
                myThanks.add(widget.inputText == '' ? text : widget.inputText);
                List<String> tempThanksSuggestionList = List.from(
                  widget.fullSuggestionList,
                );
                thanksSuggestionList = List.from(tempThanksSuggestionList);
                for (String suggestion in tempThanksSuggestionList) {
                  if (thanksSuggestionList.length > 1 &&
                      myThanks.contains(suggestion)) {
                    thanksSuggestionList.remove(suggestion);
                  }
                }
                if (thanksSuggestionList.isNotEmpty) {
                  text =
                      thanksSuggestionList[Random().nextInt(
                        thanksSuggestionList.length,
                      )];
                }
              });
            },
            // the design of the add button
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: const Radius.circular(20),
                dashPattern: const [5, 5],
                color: const Color.fromARGB(255, 12, 207, 19),
                strokeWidth: 2,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.add, // the icon of the add button
                      color: Colors.green, // the color of the icon
                      size: 20, // the size of the icon
                    ),
                    Transform.translate(
                      offset: const Offset(0.5, 0.5),
                      child: const Icon(
                        Icons.add,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),
          // the design of the suggested thank you (a dotted border with the text of the thank you)
          DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: const Radius.circular(20),
              dashPattern: const [5, 5],
              color: appGreen,
              strokeWidth: 2,
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7.0),
                child: Row(
                  children: [
                    Container(
                      alignment: appLocale.textDirection == "rtl"
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      width: MediaQuery.of(context).size.width > 1000
                          ? 600
                          : MediaQuery.of(context).size.width * 0.6 + 36,
                      height: MediaQuery.of(context).size.height * 0.1,
                      // the text of the suggested thank you
                      child: AutoSizeText(
                        widget.inputText == ''
                            ? text
                            : widget
                                  .inputText, // if the input text is empty, show the suggested thank you text
                        maxLines:
                            3, // the maximum number of lines of the text, if the text is more than 3 lines,
                        // it will be ellipsized , adjust as needed
                        minFontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: "Rubix",
                          fontSize: 14.sp, // the text size
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // gap between the text and the add button
        ],
      ),
    );
  }
}
