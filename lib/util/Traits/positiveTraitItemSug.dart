import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/suggestion_add_button.dart';
import 'package:mazilon/util/theme/spacing.dart';
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
  const PositiveTraitItemSug({
    required this.stopShowing,
    required this.add,
    required this.inputText,
    required this.fullSuggestionList,
    super.key,
  });
  final Function add; // the function to add the trait to the list of traits
  final String inputText; // the input text of the suggested trait
  final List<String> fullSuggestionList;
  final int stopShowing;

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
    if (widget.inputText != '') {
      return;
    }
    final userInfoProvider = Provider.of<UserInformation>(
      context,
    );

    setState(() {
      myPositiveTraits = userInfoProvider.positiveTraits;

      final tempTraitSuggestionList = widget.fullSuggestionList;

      positiveTraitsSuggestionList = List.from(widget.fullSuggestionList);
      // remove the traits that are already written by the user
      for (final suggestion in tempTraitSuggestionList) {
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
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.xs,
        horizontal: Spacing.sm,
      ),
      // the row that contains the suggested trait and the add button
      child: Row(
        children: [
          // the design of the suggested trait (a dotted border with the trait text)
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

          // gap between the text and the add button
          const SizedBox(width: 10),

          // the add button (right side, aligned with the 3-dot action buttons)
          SuggestionAddButton(
            onPressed: () async {
              // Add the trait to the list and show a new suggestion.
              final service =
                  GetIt.instance<
                    PersistentMemoryService
                  >(); // Get the persistent memory service instance

              final userInfoProvider = Provider.of<UserInformation>(
                context,
                listen: false,
              );
              final myPositiveTraitsValue = TypeUtils.castToStringList(
                await service.getItem(
                  'positiveTraits',
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

                final tempTraitSuggestionList = widget.fullSuggestionList;

                positiveTraitsSuggestionList = List.from(
                  widget.fullSuggestionList,
                );

                for (final suggestion in tempTraitSuggestionList) {
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
        ],
      ),
    );
  }
}
