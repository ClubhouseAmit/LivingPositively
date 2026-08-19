// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:mazilon/util/styles.dart';

class NotificationToggleCard extends StatefulWidget {
  final String emoji;
  final String badgeText;
  final String title;
  final String subtitle;
  final Future<void> Function(bool)? onToggle;
  final Future<void> Function(TimeOfDay)? onTimeSelected;
  final TimeOfDay? initialTime;
  final bool initialEnabled;

  const NotificationToggleCard({
    super.key,
    required this.emoji,
    required this.badgeText,
    required this.title,
    required this.subtitle,
    this.onToggle,
    this.onTimeSelected,
    this.initialTime,
    this.initialEnabled = false,
  });

  @override
  State<NotificationToggleCard> createState() => _NotificationToggleCardState();
}

class _NotificationToggleCardState extends State<NotificationToggleCard> {
  bool _isSaving = false;

  TimeOfDay get _selectedTime =>
      widget.initialTime ?? const TimeOfDay(hour: 8, minute: 30);

  Future<void> _setEnabled() async {
    if (_isSaving || widget.onToggle == null) return;
    setState(() => _isSaving = true);
    try {
      await widget.onToggle!(!widget.initialEnabled);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectTime() async {
    if (_isSaving || widget.onTimeSelected == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await widget.onTimeSelected!(picked);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple, width: 1),
      ),
      child: Container(
        margin: EdgeInsets.all(5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.emoji),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryPurple,
                              Color.lerp(primaryPurple, appGreen, 0.15)!,
                              appGreen,
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                        child: Text(
                          widget.badgeText,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: Color.fromARGB(255, 119, 78, 230),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 210,
                    child: Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.initialEnabled)
                    GestureDetector(
                      onTap: _isSaving ? null : _selectTime,
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.blue),
                          Text(
                            _selectedTime.format(context),
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isSaving) ...[
                            SizedBox(width: 6),
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _isSaving ? null : _setEnabled,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                width: 55,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: widget.initialEnabled
                      ? LinearGradient(
                          colors: [
                            primaryPurple,
                            const Color.fromARGB(255, 42, 62, 188),
                          ],
                        )
                      : null,
                  color: widget.initialEnabled ? null : Colors.grey.shade300,
                ),
                child: AnimatedAlign(
                  duration: Duration(milliseconds: 250),
                  alignment: widget.initialEnabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
