import 'package:flutter/material.dart';
import 'dart:math';

class InspirationalQuote extends StatefulWidget {
  final List<String> quotes;
  const InspirationalQuote({super.key, required this.quotes});
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
        key: Key('InspirationalQuote'),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        width: MediaQuery.of(context).size.width > 1000
            ? 800
            : MediaQuery.of(context).size.width,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setShow();
                  },
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 0, 10),
                    child: Icon(Icons.close),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(widget.quotes[number])),
                /*  myAutoSizedText(
                    widget.quotes[number],
                    TextStyle(color: appWhite, fontSize: 26.sp),
                    TextAlign.right,
                    14),*/
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.refresh, size: 35),
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
    );
  }
}
