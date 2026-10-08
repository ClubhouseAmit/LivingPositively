import 'package:flutter/material.dart';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dotted_border/dotted_border.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/features/shell/ui/suggestion_add_button.dart';

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

class _PositiveTraitItemSugState extends LPExtendedState<PositiveTraitItemSug>
    with SingleTickerProviderStateMixin {
  // Same shrink as the home page suggestions (DashedListWidget).
  static const Duration _kCollapseDuration = Duration(milliseconds: 400);
  late final AnimationController _collapse;
  late final Animation<double> _collapseOpacity;
  late final Animation<double> _collapseSize;

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
    _collapse = AnimationController(vsync: this, duration: _kCollapseDuration);
    _collapseOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _collapse,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );
    _collapseSize = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _collapse,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _collapse.dispose();
    super.dispose();
  }

  // Shrink the suggestion away, then add the trait to the list and show a
  // new suggestion. Shared by the add button and the suggestion text.
  Future<void> _addSuggestion() async {
    if (_collapse.isAnimating) return; // one add per shrink
    await _collapse.forward();
    if (!mounted) return;
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

      // positiveTraitsSuggestionList.remove(text);
      if (positiveTraitsSuggestionList.isNotEmpty) {
        text =
            positiveTraitsSuggestionList[Random().nextInt(
              positiveTraitsSuggestionList.length,
            )];
      }
    });
    _collapse.reset();
  }

  // build the positive trait item suggested widget
  @override
  Widget build(BuildContext context) {
    // get the appInformation and userInformation providers

    loadData(context);
    if (!show) {
      return Container();
    }
    return SizeTransition(
      sizeFactor: _collapseSize,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: _collapseOpacity,
        child: _suggestionRow(),
      ),
    );
  }

  // the row that contains the suggested trait and the add button
  Widget _suggestionRow() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // the add button
          SuggestionAddButton(onPressed: _addSuggestion),

          // gap between the text and the add button
          const SizedBox(width: 10),

          // the design of the suggested trait (a dotted border with the trait text)
          // tapping the text adds it too, like the home page
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _addSuggestion,
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
          ),
        ],
      ),
    );
  }
}
