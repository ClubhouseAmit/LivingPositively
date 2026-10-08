import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/suggested_list_item.dart';
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

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

  // Add the trait to the list and show a new suggestion. SuggestedListItem
  // calls this once its shrink ends.
  Future<void> _addSuggestion() async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    var myPositiveTraitsValue = TypeUtils.castToStringList(
      await service.getItem("positiveTraits", PersistentMemoryType.StringList),
    );
    if (!mounted) return;
    setState(() {
      widget.add(
        widget.inputText == '' ? text : widget.inputText,
        userInfoProvider,
      );
      myPositiveTraits = myPositiveTraitsValue;
      myPositiveTraits.add(widget.inputText == '' ? text : widget.inputText);

      List<String> tempTraitSuggestionList = widget.fullSuggestionList;

      positiveTraitsSuggestionList = List.from(widget.fullSuggestionList);

      for (String suggestion in tempTraitSuggestionList) {
        if (positiveTraitsSuggestionList.length > 1 &&
            myPositiveTraits.contains(suggestion)) {
          positiveTraitsSuggestionList.remove(suggestion);
        }
      }

      if (positiveTraitsSuggestionList.isNotEmpty) {
        text =
            positiveTraitsSuggestionList[Random().nextInt(
              positiveTraitsSuggestionList.length,
            )];
      }
    });
  }

  // build the positive trait item suggested widget
  @override
  Widget build(BuildContext context) {
    // get the appInformation and userInformation providers

    loadData(context);
    if (!show) {
      return Container();
    }
    return SuggestedListItem(
      text: widget.inputText == '' ? text : widget.inputText,
      onAdd: _addSuggestion,
    );
  }
}
