// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:mazilon/pages/notifications/time_picker.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class SetNotificationWidget extends StatefulWidget {
  const SetNotificationWidget({super.key});

  @override
  State<SetNotificationWidget> createState() => _SetNotificationWidgetState();
}

class _SetNotificationWidgetState
    extends LPExtendedState<SetNotificationWidget> {
  int _currentHour = 12;
  int _currentMinute = 0;

  void setTime(int minute, int hour) {
    setState(() {
      _currentHour = hour;
      _currentMinute = minute;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pref = context
          .read<UserInformation>()
          .getNotificationPreference('default');
      if (pref != null) {
        setState(() {
          _currentHour = pref.hour;
          _currentMinute = pref.minute;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);
    final gender = userInfoProvider.gender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(color: Colors.black, height: 5),
        TimePicker(
          setTime: setTime,
          currentHour: _currentHour,
          currentMinute: _currentMinute,
        ),
        SizedBox(width: 15),
        Divider(color: Colors.black, height: 5),
        SizedBox(height: 25),
        Center(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 96, 139, 103).withOpacity(0.7),
              borderRadius: BorderRadius.circular(7),
            ),
            child: TextButton(
              onPressed: () => FcmScheduledNotificationService.registerNotification(
                context: context,
                typeId: 'default',
                hour: _currentHour,
                minute: _currentMinute,
              ),
              child: Text(
                appLocale!.notificationSetTimeText(gender),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        SizedBox(height: 25),
        Center(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 138, 139, 96).withOpacity(0.7),
              borderRadius: BorderRadius.circular(7),
            ),
            child: TextButton(
              onPressed: () {
                // TODO: wire up example notification via FCM when needed
              },
              child: Text(
                appLocale!.notificationShowExampleNotification(gender),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        SizedBox(height: 25),
        Center(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 139, 96, 96).withOpacity(0.7),
              borderRadius: BorderRadius.circular(7),
            ),
            child: TextButton(
              onPressed: () => FcmScheduledNotificationService.cancelNotification(
                context: context,
                typeId: 'default',
              ),
              child: Text(
                appLocale!.notificationCancelNotification(gender),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
