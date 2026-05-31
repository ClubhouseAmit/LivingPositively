import 'package:flutter/material.dart';
import 'dart:math';

import 'package:dotted_border/dotted_border.dart';

class ThanksItemSuggested extends StatefulWidget {
  final Function add;
  final String inputText;
  const ThanksItemSuggested({
    super.key,
    required this.add,
    required this.inputText,
  });

  @override
  State<ThanksItemSuggested> createState() => _ThanksItemSuggestedState();
}

class _ThanksItemSuggestedState extends State<ThanksItemSuggested> {
  String text = '';
  List<String> myThanks = [];
  List<String> thanksSuggestionsList = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
  ];
  @override
  void initState() {
    super.initState();

    text =
        thanksSuggestionsList[Random().nextInt(thanksSuggestionsList.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: const Radius.circular(20),
              dashPattern: const [5, 5],
              color: const Color.fromARGB(255, 12, 207, 19),
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
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 1000
                          ? 600
                          : MediaQuery.of(context).size.width * 0.6 + 36,
                      height: MediaQuery.of(context).size.height * 0.1,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          widget.inputText == '' ? text : widget.inputText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
            key: Key((widget.key as ValueKey).value + "Add"),
            onTap: () => {
              widget.add(widget.inputText == '' ? text : widget.inputText),
              text =
                  thanksSuggestionsList[Random().nextInt(
                    thanksSuggestionsList.length,
                  )],
            },
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: const Radius.circular(20),
                dashPattern: const [5, 5],
                color: const Color.fromARGB(255, 12, 207, 19),
                strokeWidth: 2,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Icon(Icons.add, color: Colors.green, size: 20),
                    Transform.translate(
                      offset: Offset(0.5, 0.5),
                      child: Icon(Icons.add, color: Colors.green, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
