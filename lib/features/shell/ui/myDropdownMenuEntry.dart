import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Dropdown menu entry builder for settings and form dropdowns.
DropdownMenuEntry<String> buildDropdownMenuEntry(
  String text,
  Color? backgroundColor,
) {
  return DropdownMenuEntry<String>(
    value: text,
    label: text,
    labelWidget: Builder(
      builder: (context) => Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.normal,
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16.sp,
        ),
      ),
    ),
    style: MenuItemButton.styleFrom(foregroundColor: backgroundColor),
  );
}
