import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/suggestion_add_button.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// the thanks item suggested widget, it shows a suggested thank you text and an add button
//its used in journal/homepage in todo list section to suggest a thank you to the user
// we use this in 2 ways , if the input text is not empty, it will show the input text in the suggestion
// if the input text is empty, it will show a random thank you from the suggested thank yous list that is not written today
class ThanksItemSuggested extends StatefulWidget {
  const ThanksItemSuggested({
    required this.add,
    required this.inputText,
    required this.stopShowing,
    required this.fullSuggestionList,
    super.key,
  });
  final Function add; // the function to add the thankyou to the list
  final String inputText; // the input text of the thank you
  final List<String> fullSuggestionList;
  final int stopShowing;

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
    final todayThankYous = <String>[];
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final itemCount = thankYous.length < dates.length
        ? thankYous.length
        : dates.length;
    for (var i = 0; i < itemCount; i++) {
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
    );
    setState(() {
      final thankYous = userInfoProvider.thanks['thanks'] ?? [];
      final dates = userInfoProvider.thanks['dates'] ?? [];

      myThanks = todayThankYousFunc(thankYous, dates);
      final tempThanksSuggestionList = List<String>.from(
        widget.fullSuggestionList,
      );

      thanksSuggestionList = List.from(tempThanksSuggestionList);
      // remove the thank yous that are already written today from the suggested thank yous
      for (final suggestion in tempThanksSuggestionList) {
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
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.xs,
        horizontal: Spacing.sm,
      ),
      // the row that contains the suggested thank you and the add button
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              alignment: AlignmentDirectional.centerStart,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: AutoSizeText(
                  widget.inputText == '' ? text : widget.inputText,
                  maxLines: 1,
                  minFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: Spacing.sm),
          // the add button (right side, aligned with the 3-dot action buttons)
          SuggestionAddButton(
            onPressed: () {
              // Add the thank you and update the suggested value.
              setState(() {
                widget.add(
                  widget.inputText == '' ? text : widget.inputText,
                  userInfoProvider,
                );
                final thankYous = userInfoProvider.thanks['thanks'] ?? [];
                final dates = userInfoProvider.thanks['dates'] ?? [];
                myThanks = todayThankYousFunc(thankYous, dates);
                myThanks.add(widget.inputText == '' ? text : widget.inputText);
                final tempThanksSuggestionList = List<String>.from(
                  widget.fullSuggestionList,
                );
                thanksSuggestionList = List.from(tempThanksSuggestionList);
                for (final suggestion in tempThanksSuggestionList) {
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
        ],
      ),
    );
  }
}
