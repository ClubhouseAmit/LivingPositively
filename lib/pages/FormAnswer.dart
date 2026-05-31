import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/LP_extended_state.dart';

import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/FormAnswer/addFormAnswer.dart';

//the template for the answers in the personal plan questionnaire
//this is used in the formpagetemplate to display(remove/edit) the selected/inserted user promptss
class FormAnswer extends StatefulWidget {
  final String text;
  final Function edit;
  final Function remove;
  final int num;

  const FormAnswer({
    super.key,
    required this.text,
    required this.edit,
    required this.remove,
    required this.num,
  });

  @override
  State<FormAnswer> createState() => _FormAnswerState();
}

class _FormAnswerState extends LPExtendedState<FormAnswer> {
  String tempMyAnswer = '';
  @override
  Widget build(BuildContext context) {
    void editAnswer(String text, int index) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AddFormAnswer(index: index, edit: widget.edit, text: text);
        },
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width > 1000
          ? 800
          : MediaQuery.of(context).size.width * 0.6,
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Icon(
                            Icons.circle,
                            color: primaryPurple,
                            size: 10,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width > 1000
                                ? 600
                                : MediaQuery.of(context).size.width - 150,
                            child: myAutoSizedText(
                              widget.text,

                              //maxLines: 10,
                              TextStyle(fontSize: 16.sp),
                              appLocale.textDirection == "rtl"
                                  ? TextAlign.right
                                  : TextAlign.left,
                              28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            editAnswer(widget.text, widget.num - 1);
                            return;
                          },
                          child: const Icon(
                            Icons.edit,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: returnSizedBox(context, 12)),
                    SizedBox(
                      width: 30,
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            widget.remove(widget.num - 1);
                            setState(() {});
                          },
                          child: const Icon(
                            Icons.delete,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
