import 'package:flutter/material.dart';

class ThankYou extends StatefulWidget {
  final String text;
  final int number;
  final Function edit;
  final Function remove;
  final FocusNode myFocusNode;
  final String date;
  final Color color;
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

  String tempThankYou = '';
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
                  SizedBox(
                    width: 50,
                    child: MaterialButton(
                      key: Key('deleteThankYou${widget.number}'),
                      onPressed: () {
                        widget.remove(widget.number - 1);
                        setState(() {
                          editable = false;
                        });
                      },
                      splashColor: Colors.transparent,
                      enableFeedback: false,
                      child: Icon(Icons.delete),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: MaterialButton(
                      key: Key('editThankYou${widget.number}'),
                      onPressed: () {
                        widget.edit(widget.text, widget.number - 1);
                      },
                      splashColor: Colors.transparent,
                      enableFeedback: false,
                      child: Icon(Icons.edit),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(widget.text),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                ],
              ),
            ),
          ),
          SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              color: Colors.purple,
              child: Text(widget.number.toString()),
            ),
          ),
        ],
      ),
    );
  }
}
