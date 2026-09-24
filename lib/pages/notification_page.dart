// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/notifications/ui/reminder_debug_panel.dart';
import 'package:mazilon/features/notifications/ui/notification_toggle_card.dart';
import 'package:mazilon/features/notifications/ui/notification_permission_denied_card.dart';
import 'package:mazilon/features/notifications/ui/notification_signed_out_card.dart';
import 'package:mazilon/features/notifications/data/reminder_debug_recorder.dart';
import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/fcm_service.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
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
    if (!mounted || generation != _permissionCheckGeneration) return;
    setState(() {
      _hasPermission = granted;
      _canRequestPermission = canRequestPermission;
    });
    // Permission controls this page. Token/APNs setup is best-effort and may
    // take much longer while the device is offline, so it must not hold the
    // permission UI in its loading state.
    if (granted) unawaited(FcmService.initialize());
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
            userInformation: userInfo,
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
    final preference = NotificationRepository.forService(
      userInfo.service,
    ).getPreference('default');
    return FcmScheduledNotificationService.registerNotification(
      userInformation: userInfo,
      typeId: 'default',
      hour: preference?.hour ?? NotificationToggleCard.defaultReminderTime.hour,
      minute:
          preference?.minute ??
          NotificationToggleCard.defaultReminderTime.minute,
    );
  }

  Future<bool> _onPickedTime(TimeOfDay picked) async {
    // The operating-system setting can change while this page stays mounted.
    // Read it again immediately before a mutation instead of relying on the
    // last lifecycle check.
    if (_hasPermission != true || !await FcmService.hasPermission()) {
      unawaited(_checkPermission());
      _showReminderMutationFailure();
      return false;
    }
    if (!mounted) return false;
    final userInfo = context.read<UserInformation>();
    final applied = await FcmScheduledNotificationService.registerNotification(
      userInformation: userInfo,
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: AppSpacing.xl * 5),
                Consumer<UserInformation>(
                  builder: (context, userInfo, _) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: myText(
                      appLocale.notifications(userInfo.gender),
                      TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                      TextAlign.start,
                    ),
                  ),
                ),
                Consumer<UserInformation>(builder: _buildReminderControls),
                if (kDebugMode) ...[
                  Consumer<UserInformation>(
                    builder: (context, userInfo, _) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: _toggleDebugUnlock,
                      child: Text(
                        appLocale.notificationPageHeader(userInfo.gender),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: reminderDebugPanelUnlocked,
                    builder: (context, unlocked, _) {
                      if (!unlocked) return const SizedBox.shrink();
                      return const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xxl),
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

  Widget _buildReminderControls(
    BuildContext context,
    UserInformation userInfo,
    Widget? child,
  ) {
    final gender = userInfo.gender;
    if (!userInfo.loggedIn) return const NotificationSignedOutCard();
    final preference = NotificationRepository.forService(
      userInfo.service,
    ).getPreference('default');
    // An existing reminder remains removable after OS permission is revoked.
    if (_hasPermission == false && preference == null) {
      return NotificationPermissionDeniedCard(
        onRequestPermission: _requestReminderPermission,
        onCancelReminder: () => _onToggle(false, userInfo),
        canRequestPermission: _canRequestPermission,
        gender: gender,
        requestPermissionBody: appLocale.notificationPageHeader(gender),
      );
    }
    if (_hasPermission == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return NotificationToggleCard(
      emoji: '✨',
      badgeText: 'LP',
      title: appLocale.notifications(gender),
      subtitle: appLocale.notificationPageHeader(gender),
      setTimeLabel: appLocale.notificationsSetTime,
      initialEnabled: preference != null,
      initialTime: preference == null
          ? null
          : TimeOfDay(hour: preference.hour, minute: preference.minute),
      onTimeSelected: _onPickedTime,
      onToggle: (value) => _onToggle(value, userInfo),
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
