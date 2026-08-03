import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class ThanksItemSuggested extends StatefulWidget {
  const ThanksItemSuggested({
    required this.add, required this.inputText, super.key,
  });
  final Function add;
  final String inputText;

  @override
  State<ThanksItemSuggested> createState() => _ThanksItemSuggestedState();
}

class _ThanksItemSuggestedState extends State<ThanksItemSuggested> {
  String text = '';
  List<String> myThanks = [];
  List<String> thanksSuggestionsList = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
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
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DottedBorder(
            options: const RoundedRectDottedBorderOptions(
              radius: Radius.circular(20),
              dashPattern: [5, 5],
              color: Color.fromARGB(255, 12, 207, 19),
              strokeWidth: 2,
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 800 > 1000
                          ? 600
                          : 800 * 0.6 + 36,
                      height: 600 * 0.1,
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
          const SizedBox(width: 10),
          GestureDetector(
            key: Key((widget.key! as ValueKey).value + 'Add'),
            onTap: () => {
              widget.add(widget.inputText == '' ? text : widget.inputText),
              text =
                  thanksSuggestionsList[Random().nextInt(
                    thanksSuggestionsList.length,
                  )],
            },
            child: DottedBorder(
              options: const RoundedRectDottedBorderOptions(
                radius: Radius.circular(20),
                dashPattern: [5, 5],
                color: Color.fromARGB(255, 12, 207, 19),
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
                    const Icon(Icons.add, color: Colors.green, size: 20),
                    Transform.translate(
                      offset: const Offset(0.5, 0.5),
                      child: const Icon(Icons.add, color: Colors.green, size: 20),
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
