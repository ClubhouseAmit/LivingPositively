import 'package:flutter/material.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dotted_border/dotted_border.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/suggestion_add_button.dart';

import 'package:mazilon/util/type_utils.dart';

import 'package:provider/provider.dart';
import 'package:mazilon/util/userInformation.dart';

// the positive trait item suggested widget, it shows a suggested positive trait text and an add button
//its used in positive trait page/homepage in todo list section to suggest a trait to the user
// we use this in 2 ways , if the input text is not empty, it will show the input text in the suggestion
// if the input text is empty, it will show a random trait from the suggested traits list that is not written today
//this is similar to thanksItemSug.dart but for the positive traits
// (it has some differences in the way suggestion is randomized, we dont look at traits written today but at traits written all time)

class PositiveTraitItemSug extends StatefulWidget {
  final Function add; // the function to add the trait to the list of traits
  final String inputText; // the input text of the suggested trait
  final List<String> fullSuggestionList;
  final int stopShowing;
  const PositiveTraitItemSug({
    super.key,
    required this.stopShowing,
    required this.add,
    required this.inputText,
    required this.fullSuggestionList,
  });

  @override
  State<PositiveTraitItemSug> createState() => _PositiveTraitItemSugState();
}

class _PositiveTraitItemSugState extends LPExtendedState<PositiveTraitItemSug> {
  String text = ''; // the text of the suggested trait (initially empty)
  List<String> myPositiveTraits = []; // the list of the traits
  List<String> positiveTraitsSuggestionList = [];
  bool show = true; // the list of the suggested traits
  void loadData(BuildContext context) {
    // get the shared preferences
    if (widget.inputText != "") {
      return;
    }
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );

    setState(() {
      myPositiveTraits = userInfoProvider.positiveTraits;

      List<String> tempTraitSuggestionList = widget.fullSuggestionList;

      positiveTraitsSuggestionList = List.from(widget.fullSuggestionList);
      // remove the traits that are already written by the user
      for (String suggestion in tempTraitSuggestionList) {
        if (positiveTraitsSuggestionList.length > 1 &&
            myPositiveTraits.contains(suggestion)) {
          positiveTraitsSuggestionList.remove(suggestion);
        }
      }
      if (widget.stopShowing > 0 &&
          positiveTraitsSuggestionList.length < widget.stopShowing) {
        show = false;
      } else {
        show = true;
      }
      text =
          positiveTraitsSuggestionList[Random().nextInt(
            positiveTraitsSuggestionList.length,
          )];
    });
  }

  @override
  void initState() {
    super.initState();
  }

  // build the positive trait item suggested widget
  @override
  Widget build(BuildContext context) {
    // get the appInformation and userInformation providers

    loadData(context);
    if (!show) {
      return Container();
    }
    return Container(
      padding: const EdgeInsets.all(10),
      // the row that contains the suggested trait and the add button
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // the add button
          SuggestionAddButton(
            onPressed: () async {
              // Add the trait to the list and show a new suggestion.
              PersistentMemoryService service =
                  GetIt.instance<
                    PersistentMemoryService
                  >(); // Get the persistent memory service instance

              final userInfoProvider = Provider.of<UserInformation>(
                context,
                listen: false,
              );
              var myPositiveTraitsValue = TypeUtils.castToStringList(
                await service.getItem(
                  "positiveTraits",
                  PersistentMemoryType.StringList,
                ),
              );
              setState(() {
                widget.add(
                  widget.inputText == '' ? text : widget.inputText,
                  userInfoProvider,
                );
                myPositiveTraits = myPositiveTraitsValue;
                myPositiveTraits.add(
                  widget.inputText == '' ? text : widget.inputText,
                );

                List<String> tempTraitSuggestionList =
                    widget.fullSuggestionList;

                positiveTraitsSuggestionList = List.from(
                  widget.fullSuggestionList,
                );

                for (String suggestion in tempTraitSuggestionList) {
                  if (positiveTraitsSuggestionList.length > 1 &&
                      myPositiveTraits.contains(suggestion)) {
                    positiveTraitsSuggestionList.remove(suggestion);
                  }
                }

                // positiveTraitsSuggestionList.remove(text);
                if (positiveTraitsSuggestionList.isNotEmpty) {
                  text =
                      positiveTraitsSuggestionList[Random().nextInt(
                        positiveTraitsSuggestionList.length,
                      )];
                }
              });
            },
          ),

          // gap between the text and the add button
          const SizedBox(width: 10),

          // the design of the suggested trait (a dotted border with the trait text)
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
                      widget.inputText == '' ? text : widget.inputText,
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
        ],
      ),
    );
  }
}
