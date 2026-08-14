import 'package:flutter/material.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/suggestion_add_button.dart';

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
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final itemCount = thankYous.length < dates.length
        ? thankYous.length
        : dates.length;
    for (int i = 0; i < itemCount; i++) {
      if (dates[i].startsWith(todayDate)) {
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
          SuggestionAddButton(
            onPressed: () {
              // Add the thank you and update the suggested value.
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
          ),

          const SizedBox(width: 10),
          // the design of the suggested thank you (a dotted border with the text of the thank you)
          Expanded(
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: const Radius.circular(20),
                dashPattern: const [5, 5],
                color: Theme.of(context).colorScheme.tertiary,
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
                  child: Align(
                    alignment: appLocale.textDirection == "rtl"
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: AutoSizeText(
                      widget.inputText == ''
                          ? text
                          : widget.inputText,
                      maxLines: 3,
                      minFontSize: 14,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: "Rubix",
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
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
