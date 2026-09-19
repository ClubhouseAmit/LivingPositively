import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Item widget for the bottom Navigation in the home page.
Widget bottomNavigationItem(
  bool current,
  Widget Function(Color color) iconBuilder,
  String text, {
  AutoSizeGroup? textGroup,
}) {
  return Builder(
    builder: (context) {
      final color = current
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconBuilder(color),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AutoSizeText(
              text,
              group: textGroup,
              minFontSize: 6,
              maxFontSize: 12,
              style: TextStyle(
                fontWeight: current ? FontWeight.w600 : FontWeight.normal,
                color: color,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      );
    },
  );
}
