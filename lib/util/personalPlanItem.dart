import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:auto_size_text/auto_size_text.dart';

//This is to display the showcased Items in the home page under the "Personal Plan" section
class PersonalPlanItem extends StatefulWidget {
  final String text;
  const PersonalPlanItem({super.key, required this.text});

  @override
  State<PersonalPlanItem> createState() => _PersonalPlanItemState();
}

class _PersonalPlanItemState extends State<PersonalPlanItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: 200,
        minWidth: 100,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: AutoSizeText(
            widget.text,
            minFontSize: 12,
            maxFontSize: 30,
            maxLines: 2,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.normal,
              color: Colors.black,
              fontFamily: 'Rubix',
            ),
            overflowReplacement: AutoSizeText(
              widget.text.length > 13
                  ? '${widget.text.substring(0, 13)}...'
                  : widget.text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                fontFamily: 'Rubix',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
