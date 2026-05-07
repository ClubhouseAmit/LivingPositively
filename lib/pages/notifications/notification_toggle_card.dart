// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class NotificationToggleCard extends StatefulWidget {
  final String emoji;
  final String badgeText;
  final String title;
  final String subtitle;
  final ValueChanged<bool>? onToggle;
  final ValueChanged<TimeOfDay>? onTimeSelected;
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
  bool _isEnabled = false;
  late TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialEnabled;
    _selectedTime = widget.initialTime ?? TimeOfDay(hour: 8, minute: 30);
  }

  void setEnabled() {
    setState(() => _isEnabled = !_isEnabled);
    widget.onToggle?.call(_isEnabled);
    if (!_isEnabled) {
      _selectedTime = TimeOfDay(hour: 8, minute: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider =
        Provider.of<UserInformation>(context, listen: false);
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
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.emoji),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
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
                              stops: [0.0, 0.5, 1.5],
                            )),
                        child: Text(widget.badgeText,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 8),
                      Text(widget.title,
                          style: TextStyle(
                              color: Color.fromARGB(255, 119, 78, 230),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ]),
                    SizedBox(
                        width: 210,
                        child: Text(widget.subtitle,
                            style: TextStyle(
                                color: primaryPurple,
                                fontSize: 10,
                                fontWeight: FontWeight.bold))),
                    if (_isEnabled)
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedTime = picked);
                            widget.onTimeSelected?.call(picked);
                          }
                        },
                        child: _selectedTime != null
                            ? Row(children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.blue,
                                ),
                                Text(_selectedTime!.format(context),
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ])
                            : Text('Set time',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                      )
                  ]),
            ),
            GestureDetector(
              onTap: () {
                setEnabled();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 250),
                width: 55,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: _isEnabled
                      ? LinearGradient(
                          colors: [
                            primaryPurple,
                            const Color.fromARGB(255, 42, 62, 188),
                          ],
                        )
                      : null,
                  color: _isEnabled ? null : Colors.grey.shade300,
                ),
                child: AnimatedAlign(
                  duration: Duration(milliseconds: 250),
                  alignment:
                      _isEnabled ? Alignment.centerRight : Alignment.centerLeft,
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
            )
          ]),
        ));
  }
}
