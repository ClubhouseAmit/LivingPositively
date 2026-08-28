// ignore_for_file: prefer_const_constructors

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mazilon/pages/auth/auth_page.dart';
import 'package:mazilon/pages/notifications/reminder_debug_panel.dart';
import 'package:mazilon/pages/notifications/notification_toggle_card.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/l10n/app_localizations.dart';
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
  bool _canRequestPermission = false;
  int _permissionCheckGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    if (kDebugMode) loadReminderDebugPanelUnlocked();
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
    final generation = ++_permissionCheckGeneration;
    final granted = await FcmService.hasPermission();
    final canRequestPermission =
        !granted && await FcmService.canRequestPermission();
    if (granted) {
      await FcmService.initialize();
    }
    if (!mounted || generation != _permissionCheckGeneration) return;
    setState(() {
      _hasPermission = granted;
      _canRequestPermission = canRequestPermission;
    });
  }

  Future<bool> _onToggle(bool value, UserInformation userInfo) async {
    // Disabling a reminder is safe and necessary even if notification
    // permission was later revoked. Only enabling needs a confirmed grant.
    if (value && _hasPermission != true) {
      _showReminderMutationFailure();
      return false;
    }
    final applied = value
        ? await _enableReminder(userInfo)
        : await FcmScheduledNotificationService.cancelNotification(
            context: context,
            typeId: 'default',
          );
    if (!applied) _showReminderMutationFailure();
    return applied;
  }

  Future<bool> _enableReminder(UserInformation userInfo) async {
    // Initialization can still be pending on iOS immediately after a user
    // grants permission because APNs has not supplied its token yet. The
    // permission result, rather than FCM initialization, controls this UI.
    await FcmService.requestPermissionAndInitialize();
    if (!await FcmService.hasPermission()) {
      if (!mounted) return false;
      await _checkPermission();
      return false;
    }
    if (!mounted) return false;
    final preference = userInfo.getNotificationPreference('default');
    return FcmScheduledNotificationService.registerNotification(
      context: context,
      typeId: 'default',
      hour: preference?.hour ?? NotificationToggleCard.defaultReminderTime.hour,
      minute:
          preference?.minute ??
          NotificationToggleCard.defaultReminderTime.minute,
    );
  }

  Future<bool> _onPickedTime(TimeOfDay picked) async {
    if (_hasPermission != true) {
      _showReminderMutationFailure();
      return false;
    }
    final applied = await FcmScheduledNotificationService.registerNotification(
      context: context,
      typeId: 'default',
      hour: picked.hour,
      minute: picked.minute,
    );
    if (!applied) _showReminderMutationFailure();
    return applied;
  }

  void _showReminderMutationFailure() {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(appLocale.asyncErrorMessage)));
  }

  Future<void> _toggleDebugUnlock() async {
    final unlocked = await toggleReminderDebugPanelUnlocked();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          unlocked
              ? appLocale.notificationsDebugPanelEnabled
              : appLocale.notificationsDebugPanelHidden,
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
                    final preference = userInfo.getNotificationPreference(
                      'default',
                    );
                    // A schedule that was already registered must remain
                    // removable after OS permission is revoked. New reminder
                    // creation stays behind the permission prompt.
                    if (_hasPermission == false && preference == null) {
                      return _PermissionDeniedCard(
                        onRequestPermission: _requestReminderPermission,
                        canRequestPermission: _canRequestPermission,
                        requestPermissionBody: appLocale.notificationPageHeader(
                          gender,
                        ),
                      );
                    }
                    if (_hasPermission == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return NotificationToggleCard(
                      emoji: "✨",
                      badgeText: "LP",
                      title: appLocale.notifications(gender),
                      subtitle: appLocale.notificationPageHeader(gender),
                      setTimeLabel: appLocale.notificationsSetTime,
                      initialEnabled: preference != null,
                      initialTime: preference == null
                          ? null
                          : TimeOfDay(
                              hour: preference.hour,
                              minute: preference.minute,
                            ),
                      onTimeSelected: _onPickedTime,
                      onToggle: (value) => _onToggle(value, userInfo),
                    );
                  },
                ),
                if (kDebugMode) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: _toggleDebugUnlock,
                    child: Text(appLocale.notificationPageHeader(gender)),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: reminderDebugPanelUnlocked,
                    builder: (context, unlocked, _) {
                      if (!unlocked) return const SizedBox.shrink();
                      return const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: ReminderDebugPanel(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestReminderPermission() async {
    final generation = ++_permissionCheckGeneration;
    await FcmService.requestPermissionAndInitialize();
    final granted = await FcmService.hasPermission();
    final canRequestPermission =
        !granted && await FcmService.canRequestPermission();
    if (!mounted || generation != _permissionCheckGeneration) return;
    setState(() {
      _hasPermission = granted;
      _canRequestPermission = canRequestPermission;
    });
  }
}

class _NotSignedInCard extends StatelessWidget {
  const _NotSignedInCard();

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
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
  final Future<void> Function() onRequestPermission;
  final bool canRequestPermission;
  final String requestPermissionBody;

  const _PermissionDeniedCard({
    required this.onRequestPermission,
    required this.canRequestPermission,
    required this.requestPermissionBody,
  });

  @override
  State<_PermissionDeniedCard> createState() => _PermissionDeniedCardState();
}

class _PermissionDeniedCardState
    extends LPExtendedState<_PermissionDeniedCard> {
  bool _requesting = false;

  Future<void> _requestPermission() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await widget.onRequestPermission();
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

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
            widget.canRequestPermission
                ? appLocale.notificationsEnable
                : appLocale.notificationsPermissionDeniedTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            widget.canRequestPermission
                ? widget.requestPermissionBody
                : appLocale.notificationsPermissionDeniedBody,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _requesting ? null : _requestPermission,
            icon: const Icon(Icons.notifications_outlined),
            label: Text(appLocale.notificationsEnable),
          ),
          if (!widget.canRequestPermission)
            LinkButton(
              openAppSettings,
              Icons.settings_outlined,
              appLocale.notificationsOpenSettings,
              Theme.of(context).colorScheme.primary,
              designFontSize: 16,
              minHeight: 44,
            ),
        ],
      ),
    );
  }
}
