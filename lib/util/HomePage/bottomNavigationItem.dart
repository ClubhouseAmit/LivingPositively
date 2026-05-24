import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mazilon/util/styles.dart';

//Item for the bottom Navigation in the home page
Widget bottomNavigationItem(
  bool current,
  IconData icon,
  String text, {
  AutoSizeGroup? textGroup,
}) {
  Color color = current ? primaryPurple : darkGray;
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: Icon(
          icon,
          color: color,
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AutoSizeText(text,
              group: textGroup,
              maxFontSize: 25,
              style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14.sp)
                  .copyWith(fontFamily: 'Rubix'),
              textAlign: TextAlign.center,
              maxLines: 1),
        ),
      )
    ],
  );
}
