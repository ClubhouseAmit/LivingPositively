// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/auth/auth_page.dart';
import 'package:mazilon/pages/notifications/notification_toggle_card.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends LPExtendedState<NotificationPage>
    with WidgetsBindingObserver {
  bool? _hasPermission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    loadReminderDebugPanelUnlocked();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await FcmService.hasPermission();
    if (mounted) setState(() => _hasPermission = granted);
  }

  Future<void> _onToggle(bool value, UserInformation userInfo) async {
    final preference = userInfo.getNotificationPreference('default');
    final succeeded = value
        ? await FcmScheduledNotificationService.registerNotification(
            context: context,
            typeId: 'default',
            hour: preference?.hour ?? 8,
            minute: preference?.minute ?? 30,
          )
        : await FcmScheduledNotificationService.cancelNotification(
            context: context,
            typeId: 'default',
          );
    if (!succeeded && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(appLocale.asyncErrorMessage)));
    }
  }

  Future<void> _onPickedTime(
    TimeOfDay picked,
    AppLocalizations appLocale,
  ) async {
    final succeeded =
        await FcmScheduledNotificationService.registerNotification(
          context: context,
          typeId: 'default',
          hour: picked.hour,
          minute: picked.minute,
        );
    if (!succeeded && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(appLocale.asyncErrorMessage)));
    }
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
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );

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
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    appLocale.notifications(gender),
                    style: TextStyle(
                      color: primaryPurple,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Consumer<UserInformation>(
                  builder: (context, userInfo, _) {
                    if (!userInfo.loggedIn) {
                      return _NotSignedInCard();
                    }
                    if (_hasPermission == false) {
                      return _PermissionDeniedCard();
                    }
                    final preference = userInfo.getNotificationPreference(
                      'default',
                    );
                    return NotificationToggleCard(
                      emoji: "✨",
                      badgeText: "LP",
                      title: appLocale.notifications(gender),
                      subtitle: appLocale.notificationPageHeader(gender),
                      initialEnabled: preference != null,
                      initialTime: TimeOfDay(
                        hour: preference?.hour ?? 8,
                        minute: preference?.minute ?? 30,
                      ),
                      onTimeSelected: (time) => _onPickedTime(time, appLocale),
                      onToggle: (value) => _onToggle(value, userInfo),
                    );
                  },
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: _toggleDebugUnlock,
                  child: Text(appLocale.notificationPageHeader(gender)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotSignedInCard extends StatefulWidget {
  const _NotSignedInCard();

  @override
  State<_NotSignedInCard> createState() => _NotSignedInCardState();
}

class _NotSignedInCardState extends LPExtendedState<_NotSignedInCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            appLocale.authNotSignedInTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            appLocale.authNotSignedInBody,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AuthPage(fromNotifications: true),
              ),
            ),
            icon: const Icon(Icons.login_outlined),
            label: Text(appLocale.authNotSignedInButton),
          ),
        ],
      ),
    );
  }
}

class _PermissionDeniedCard extends StatefulWidget {
  const _PermissionDeniedCard();

  @override
  State<_PermissionDeniedCard> createState() => _PermissionDeniedCardState();
}

class _PermissionDeniedCardState
    extends LPExtendedState<_PermissionDeniedCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 40,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            appLocale.notificationsPermissionDeniedTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            appLocale.notificationsPermissionDeniedBody,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: openAppSettings,
            icon: const Icon(Icons.settings_outlined),
            label: Text(appLocale.notificationsOpenSettings),
          ),
        ],
      ),
    );
  }
}
