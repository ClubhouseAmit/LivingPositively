import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

//Item for the bottom Navigation in the home page
Widget bottomNavigationItem(
  bool current,
  dynamic icon,
  String text, {
  AutoSizeGroup? textGroup,
}) {
  return Builder(
    builder: (context) {
      final color = current
          ? Theme.of(context).colorScheme.primary
          : const Color(0xFF9A9EB6);

      Widget iconWidget;
      if (icon is IconData) {
        iconWidget = Icon(icon, color: color, size: 24);
      } else if (icon is String && icon.endsWith('.svg')) {
        iconWidget = SvgPicture.asset(
          icon,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        );
      } else if (icon is Widget) {
        iconWidget = icon;
      } else {
        iconWidget = Icon(Icons.help_outline, color: color, size: 24);
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 4),
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


