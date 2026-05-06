// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/pages/notifications/set_notification_widget.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends LPExtendedState<NotificationPage> {
  @override
  void initState() {
    super.initState();
    loadReminderDebugPanelUnlocked();
  }

  Future<void> _toggleDebugUnlock() async {
    final unlocked = await toggleReminderDebugPanelUnlocked();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          unlocked
              ? 'Reminder debug panel enabled'
              : 'Reminder debug panel hidden',
        ),
        duration: const Duration(seconds: 2),
      ),
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
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: _toggleDebugUnlock,
                  child: Text(
                    appLocale!.notificationPageHeader(gender),
                  ),
                ),
                SizedBox(height: 20),
                SetNotificationWidget()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
