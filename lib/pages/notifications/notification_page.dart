// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/notifications/notification_toggle_card.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends LPExtendedState<NotificationPage> {
  void _onToggle(bool value, UserInformation userInfo) {
    if (!value) {
      FcmScheduledNotificationService.cancelNotification(
        context: context,
        typeId: 'default',
      );
    }
  }

  void _onPickedTime(
    TimeOfDay picked,
    AppLocalizations appLocale,
    UserInformation userInfo,
  ) {
    FcmScheduledNotificationService.registerNotification(
      context: context,
      typeId: 'default',
      hour: picked.hour,
      minute: picked.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider =
        Provider.of<UserInformation>(context, listen: false);

    final gender = userInfoProvider.gender;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 100),
                Container(
                  alignment: Alignment.topLeft,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                            text: 'Remind ',
                            style: TextStyle(color: primaryPurple)),
                        TextSpan(text: 'Me', style: TextStyle(color: appGreen)),
                      ],
                    ),
                  ),
                ),
                NotificationToggleCard(
                  emoji: "✨",
                  badgeText: "LP",
                  title: "מסר חיזוק יומי",
                  subtitle: "ניצוץ יומי עדין של תקווה ונחמה, להאיר את הדרך",
                  initialEnabled: userInfoProvider.getNotificationPreference('default') != null,
                  initialTime: userInfoProvider.getNotificationPreference('default') == null
                      ? null
                      : TimeOfDay(
                          hour: userInfoProvider.getNotificationPreference('default')!.hour,
                          minute: userInfoProvider.getNotificationPreference('default')!.minute,
                        ),
                  onTimeSelected: (time) =>
                      _onPickedTime(time, appLocale, userInfoProvider),
                  onToggle: (value) => _onToggle(value, userInfoProvider),
                ),
                Text(
                  appLocale!.notificationPageHeader(gender),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
