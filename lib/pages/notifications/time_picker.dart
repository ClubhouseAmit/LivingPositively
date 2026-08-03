// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:mazilon/pages/notifications/notification_service.dart'; // Assuming this now refers to NotificationsHelper

import 'package:numberpicker/numberpicker.dart';

class TimePicker extends StatefulWidget {
  const TimePicker({
    required this.setTime, required this.currentHour, required this.currentMinute, super.key,
  });
  final int currentHour;
  final int currentMinute;
  final Function setTime;

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  TimeOfDay calculateTime() {
    return TimeOfDay(hour: widget.currentHour, minute: widget.currentMinute);
  }

  @override
  void initState() {
    super.initState();
    NotificationsService.init(); // Initialize NotificationsHelper
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NumberPicker(
            zeroPad: true,
            infiniteLoop: true,
            selectedTextStyle: TextStyle(fontSize: 25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            minValue: 0,
            maxValue: 59,
            value: widget.currentMinute,
            onChanged: (value) => widget.setTime(value, widget.currentHour),
          ),
          NumberPicker(
            zeroPad: true,
            infiniteLoop: true,
            selectedTextStyle: TextStyle(fontSize: 25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            minValue: 0,
            maxValue: 23,
            value: widget.currentHour,
            onChanged: (value) => widget.setTime(widget.currentMinute, value),
          ),
        ],
      ),
    );
  }
}
