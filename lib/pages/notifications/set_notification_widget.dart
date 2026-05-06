// ignore_for_file: prefer_const_constructors

import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/pages/notifications/reminder_debug_panel.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/pages/notifications/time_picker.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';

import 'package:mazilon/util/persistent_memory_service.dart';
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

  void saveNotificationTime(
      int hour, int minute, UserInformation userInfo) async {
    userInfo.updateNotificationHour(hour);
    userInfo.updateNotificationMinute(minute);
    setState(() {
      _currentHour = hour;
      _currentMinute = minute;
    });
  }

  void initializeNotification(List<String> quotes, UserInformation userInfo,
      Function createText, AppLocalizations appLocale) {
    NotificationsService.initializeNotification(
        quotes, _currentHour, _currentMinute, createText, appLocale);
    saveNotificationTime(_currentHour, _currentMinute, userInfo);
  }

  @override
  void initState() {
    super.initState();
    NotificationsService.init(); // Initialize NotificationsHelper
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      var userInfo = context.read<UserInformation>();
      setState(() {
        _currentHour = userInfo.notificationHour;
        _currentMinute = userInfo.notificationMinute;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);

    var gender = userInfoProvider.gender;

    final quotes = retrieveInspirationalQuotes(appLocale, gender);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(
          color: Colors.black,
          height: 5, // Adjust the height as needed
        ),
        TimePicker(
          setTime: setTime,
          currentHour: _currentHour,
          currentMinute: _currentMinute,
        ),
        SizedBox(width: 15),
        Divider(
          color: Colors.black,
          height: 5, // Adjust the height as needed
        ),
        SizedBox(height: 25),
        Center(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 96, 139, 103).withOpacity(0.7),
              borderRadius: BorderRadius.circular(7),
            ),
            child: TextButton(
              onPressed: () => {
                initializeNotification(quotes, userInfoProvider,
                    appLocale!.notifyOnscheduledNotification, appLocale)
              },
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
              onPressed: () => {
                NotificationsService.showNotification('Living Positively',
                    quotes[Random().nextInt(quotes.length)]),
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
              onPressed: () => {
                NotificationsService.cancelNotifications(null,
                    cancelWorker: true)
              },
              child: Text(
                appLocale!.notificationCancelNotification(gender),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        if (NotificationsService.supportsReminderSettings())
          ValueListenableBuilder<bool>(
            valueListenable: reminderDebugPanelUnlocked,
            builder: (context, unlocked, _) {
              if (!kDebugMode && !unlocked) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 25),
                  Divider(color: Colors.black, height: 5),
                  ReminderDebugPanel(),
                ],
              );
            },
          ),
      ],
    );
  }
}
