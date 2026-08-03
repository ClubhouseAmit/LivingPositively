import 'package:flutter/material.dart';


//this is the widget we use in the drop down menu for age selection
DropdownMenuEntry<String> buildDropdownMenuEntry(text, backgroundColor) {
  return DropdownMenuEntry(
    value: text,
    label: text,
    labelWidget: Builder(
      builder: (context) => Container(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
    ),
    style: MenuItemButton.styleFrom(foregroundColor: Colors.transparent),
  );
}
