import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/styles.dart';

// the thank you widget, it shows the thank you text and the number of the thank you
//although its name is thank you, it can be used for any trait , we used it for the positive trait also.
class ThankYou extends StatefulWidget {
  final String text; // the text of the thank you/trait
  final int number; // the number of the thank you/trait
  final Function edit; // the function to edit the thank you/trait
  final Function remove; // the function to remove the thank you/trait
  final FocusNode myFocusNode; // the focus node of the thank you/trait
  final String date; // the date of the thank you/trait
  final Color color; // the color of the thank you/trait text
  const ThankYou({
    super.key,
    required this.text,
    required this.number,
    required this.edit,
    required this.remove,
    required this.myFocusNode,
    required this.date,
    required this.color,
  });
  @override
  State<ThankYou> createState() => _ThankYouState();
}

class _ThankYouState extends State<ThankYou> {
  bool editable = false;
  @override
  void initState() {
    editable = widget.text.isEmpty;
    if (editable) {
      widget.myFocusNode.requestFocus();
    }
    super.initState();
  }

  // build the thank you widget
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // the number of the thank you/trait (in a circle)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              color: primaryPurple, // the color of the circle
              child: myAutoSizedText(
                // the number of the thank you/trait
                widget.number.toString(),
                TextStyle(
                  // the style of the number
                  color: appWhite,
                  fontSize: widget.number < 10 ? 14.sp : 10.sp,
                  fontWeight: FontWeight.bold,
                ),
                null,
                30,
              ),
            ),
          ),
          // gap between the text and the number
          const SizedBox(width: 10),

          Container(
            constraints: BoxConstraints(
              minHeight: 20,
              maxWidth: MediaQuery.sizeOf(context).width * 0.8,
            ),
            // height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(95),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 15),

                  // the text of the thank you/trait
                  Expanded(
                    child: Container(
                      child: AutoSizeText(
                        widget.text,
                        maxLines: 4,
                        minFontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          // .sp so system text-scale enlarges the entry
                          // copy alongside the rest of the journal.
                          fontSize: 20.sp,
                          fontWeight: FontWeight.normal,
                          color: widget.color, // the color of the text
                        ),
                      ),
                    ),
                  ),

                  // gap between the buttons and the text
                  const SizedBox(width: 15),
                  // the edit button
                  SizedBox(
                    width: 50,
                    child: Tooltip(
                      message: locale?.editEntryTooltip ?? 'Edit entry',
                      child: MaterialButton(
                        onPressed: () {
                          widget.edit(widget.text, widget.number - 1);
                        },
                        splashColor: Colors.transparent,
                        enableFeedback: false,
                        child: const Icon(Icons.edit),
                      ),
                    ),
                  ),

                  // the delete button
                  SizedBox(
                    width: 50,
                    child: Tooltip(
                      message: locale?.deleteEntryTooltip ?? 'Delete entry',
                      child: MaterialButton(
                        onPressed: () {
                          widget.remove(widget.number - 1);
                          setState(() {
                            editable = false;
                          });
                        },
                        splashColor: Colors.transparent,
                        enableFeedback: false,
                        child: const Icon(Icons.delete),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
