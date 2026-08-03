import 'dart:math';

import 'package:flutter/material.dart';

class InspirationalQuote extends StatefulWidget {
  const InspirationalQuote({required this.quotes, super.key});
  final List<String> quotes;
  @override
  _InspirationalQuoteState createState() => _InspirationalQuoteState();
}

class _InspirationalQuoteState extends State<InspirationalQuote> {
  bool showText = true;
  String quote = '';
  int number = 0;
  void setShow() {
    {
      setState(() {
        showText = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    number = Random().nextInt(widget.quotes.length);
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: showText,
      child: Container(
        key: const Key('InspirationalQuote'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        width: 800,
        height: 120,
        child: Column(
          (
                  onTap: () {
                    setShow();
       setShow                   padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
                    child: const Icon(Icons.close),
                  ),
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAx Expanded(
                  child: Text(
                    widget.quotes[number],
                  ),
                ),
                /*  myAutoSizedText(
                    widget.quotes[number],
                    TextStyle(color: appWhite, fontSize: 26.sp),
                    TextAlign.right,
                    14),*/
                const SizedBox(
                  width: 10,
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
  const                   size: 35,
                  ),
                  onPressed: () {
                    setState(() {
                      number = Random().nextInt(widget.quotes.length);
                    });
                    // Put the code to be executed on button press here.
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    )
  }
}
