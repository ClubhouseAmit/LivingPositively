import 'package:flutter/material.dart';

import 'package:dotted_border/dotted_border.dart';

class PositiveTraitItemSug extends StatefulWidget {
  final Function add;
  final String inputText;
  const PositiveTraitItemSug({
    super.key,
    required this.add,
    required this.inputText,
  });

  @override
  State<PositiveTraitItemSug> createState() => _PositiveTraitItemSugState();
}

class _PositiveTraitItemSugState extends State<PositiveTraitItemSug> {
  String text = '';
  List<String> myPositiveTraits = [];

  // void loadData() async {}

  @override
  void initState() {
    super.initState();
    //loadData();
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: "Rubix",
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 12, 207, 19),
                          ),
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
            key: Key('addPositiveSuggesstion'),
            onTap: () => {widget.add()},
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
