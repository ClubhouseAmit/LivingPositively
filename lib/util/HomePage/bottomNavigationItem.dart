import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

//Item for the bottom Navigation in the home page
Widget bottomNavigationItem(
  bool current,
  IconData icon,
  String text, {
  AutoSizeGroup? textGroup,
}) {
  return Builder(
    builder: (context) {
      final color = current
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline;
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AutoSizeText(
              text,
              group: textGroup,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12.sp,
              ).copyWith(fontFamily: 'Rubix'),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      );
    },
  );
}
