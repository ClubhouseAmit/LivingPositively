import 'package:flutter/material.dart';

class ThankYou extends StatefulWidget {
  const ThankYou({
    required this.text, required this.number, required this.edit, required this.remove, required this.myFocusNode, required this.date, required this.color, super.key,
  });
  final String text;
  final int number;
  final Function edit;
  final Function remove;
  final FocusNode myFocusNode;
  final String date;
  final Color color;

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
            constraints: const BoxConstraints(
              minHeight: 20,
              maxWidth: 800 * 0.8,
            ),

            // height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(95),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
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
                      child: const Icon(Icons.delete),
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
                      child: const Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(widget.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              color: Colors.purple,
              child: Text(widget.number.toString()),
            ),
          ),
        ],
      ),
    );
  }
}
