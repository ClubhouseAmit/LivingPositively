// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/ui/reminder_debug_panel.dart';
import 'package:mazilon/features/notifications/ui/notification_toggle_card.dart';
import 'package:mazilon/features/notifications/ui/notification_permission_denied_card.dart';
import 'package:mazilon/features/notifications/ui/notification_signed_out_card.dart';
import 'package:mazilon/features/notifications/ui/reminder_settings_panel.dart';
import 'package:mazilon/features/notifications/ui/reminder_page_header.dart';
import 'package:mazilon/features/notifications/data/reminder_debug_recorder.dart';
import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/fcm_service.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
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
  bool _initialReminderChecked = false;
  int _initialReminderAttempts = 0;
  Timer? _initialReminderRetry;
  Future<void>? _initialRegistration;
  Future<void>? _accountRestore;
  String? _observedAccountId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    if (kDebugMode) loadReminderDebugPanelUnlocked();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userInfo = context.watch<UserInformation>();
    final accountId = userInfo.loggedIn ? userInfo.userId : '';
    if (accountId == _observedAccountId) return;
    _observedAccountId = accountId;
    _initialReminderRetry?.cancel();
    _initialReminderAttempts = 0;
    _initialReminderChecked = false;
    if (accountId.isNotEmpty) unawaited(_checkPermission());
  }

  @override
  void dispose() {
    _initialReminderRetry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission({bool requestPermission = false}) async {
    if (requestPermission) await FcmService.requestPermissionAndInitialize();
    final generation = ++_permissionCheckGeneration;
    final granted = await FcmService.hasPermission();
    final canRequestPermission =
        !granted && await FcmService.canRequestPermission();
    if (!mounted || generation != _permissionCheckGeneration) return;
    final userInfo = context.read<UserInformation>();
    final repository = NotificationRepository.forService(userInfo.service);
    if (userInfo.loggedIn && userInfo.userId.isNotEmpty) {
      try {
        await repository.activateAccount(userInfo.userId);
      } catch (_) {
        _showReminderMutationFailure();
      }
    }
    if (!mounted || generation != _permissionCheckGeneration) return;
    setState(() {
      _hasPermission = granted;
      _canRequestPermission = canRequestPermission;
    });
    if (granted) unawaited(FcmService.initialize());
    if (granted && !_initialReminderChecked) {
      _initialReminderChecked = true;
      unawaited(_initialRegistration = _ensureInitialReminder());
    }
    if (granted &&
        _accountRestore == null &&
        userInfo.loggedIn &&
        repository.pausedAccountRemindersFor(userInfo.userId).isNotEmpty) {
      unawaited(
        _accountRestore = repository.resumePausedReminders(userInfo).then((_) {
          if (mounted) setState(() {});
          _accountRestore = null;
        }),
      );
    }
  }

  Future<void> _ensureInitialReminder() async {
    _initialReminderRetry?.cancel();
    final userInfo = context.read<UserInformation>();
    if (!userInfo.loggedIn) {
      _initialReminderChecked = false;
      return;
    }
    final repository = NotificationRepository.forService(userInfo.service);
    if (repository.defaultOptOut ||
        repository.getPreference('default') != null) {
      return;
    }
    final status = await readDefaultReminderSchedule(userInformation: userInfo);
    final schedule = status.schedule;
    if (status.succeeded && schedule != null) {
      try {
        await repository.setPreference('default', schedule);
      } catch (_) {
        _showReminderMutationFailure();
      }
    }
    _initialReminderChecked = status.succeeded;
    if (mounted) setState(() {});
    if (!status.succeeded && mounted && ++_initialReminderAttempts < 3) {
      _initialReminderRetry = Timer(const Duration(seconds: 30), () {
        if (mounted && _hasPermission == true && !_initialReminderChecked) {
          _initialReminderChecked = true;
          unawaited(_initialRegistration = _ensureInitialReminder());
        }
      });
    }
  }

  Future<bool> _onToggle(bool value, UserInformation userInfo) async {
    if (value && _initialRegistration != null) await _initialRegistration;
    if (value && _hasPermission != true) {
      await _checkPermission();
      return false;
    }
    final applied = value
        ? await _enableReminder(userInfo)
        : await FcmScheduledNotificationService.cancelNotification(
            userInformation: userInfo,
            typeId: 'default',
          );
    if (!applied && (!value || _hasPermission != false)) {
      _showReminderMutationFailure();
    }
    if (applied && mounted) setState(() {});
    return applied;
  }

  Future<bool> _enableReminder(UserInformation userInfo) async {
    await FcmService.requestPermissionAndInitialize();
    if (!await FcmService.hasPermission()) {
      if (!mounted) return false;
      await _checkPermission();
      return false;
    }
    if (!mounted) return false;
    final preference = NotificationRepository.forService(
      userInfo.service,
    ).getSavedTime('default');
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
    if (_initialRegistration case final pending?) await pending;
    if (!mounted) return false;
    final userInfo = context.read<UserInformation>();
    final repository = NotificationRepository.forService(userInfo.service);
    if (repository.getPreference('default') == null) {
      try {
        await repository.setSavedTime(
          'default',
          NotificationPreference(hour: picked.hour, minute: picked.minute),
        );
        if (mounted) setState(() {});
        return true;
      } catch (_) {
        _showReminderMutationFailure();
        return false;
      }
    }
    if (_hasPermission != true || !await FcmService.hasPermission()) {
      await _checkPermission();
      return false;
    }
    if (!mounted) return false;
    final applied = await FcmScheduledNotificationService.registerNotification(
      userInformation: userInfo,
      typeId: 'default',
      hour: picked.hour,
      minute: picked.minute,
    );
    if (!applied) _showReminderMutationFailure();
    if (applied && mounted) setState(() {});
    return applied;
  }

  Future<bool> _registerTextReminder(
    String id,
    TimeOfDay time,
    String title,
    String body,
  ) async {
    if (_hasPermission != true || !await FcmService.hasPermission()) {
      _showReminderMutationFailure();
      return false;
    }
    if (!mounted) return false;
    return registerTextReminder(
      userInformation: context.read<UserInformation>(),
      typeId: id,
      hour: time.hour,
      minute: time.minute,
      title: title,
      body: body,
    );
  }

  Future<bool> _cancelTextReminder(String id) =>
      FcmScheduledNotificationService.cancelNotification(
        userInformation: context.read<UserInformation>(),
        typeId: id,
      );

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
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ReminderPageHeader(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '✨ ${appLocale.reminderAppSection}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.start,
      ),
      const SizedBox(height: AppSpacing.sm),
      Consumer<UserInformation>(builder: _buildReminderControls),
      Consumer<UserInformation>(builder: _buildAdditionalReminders),
      if (kDebugMode) ...[
        Consumer<UserInformation>(
          builder: (context, userInfo, _) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: _toggleDebugUnlock,
            child: Text(appLocale.notificationPageHeader(userInfo.gender)),
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
  );

  Widget _buildAdditionalReminders(
    BuildContext context,
    UserInformation userInfo,
    Widget? child,
  ) {
    if (!userInfo.loggedIn) return const SizedBox.shrink();
    final repository = NotificationRepository.forService(userInfo.service);
    if (userInfo.userId.isNotEmpty &&
        !repository.isActiveAccount(userInfo.userId)) {
      return const SizedBox.shrink();
    }
    return ReminderSettingsPanel(
      repository: repository,
      onRegister: _registerTextReminder,
      onCancel: _cancelTextReminder,
      onFailure: _showReminderMutationFailure,
    );
  }

  Widget _buildReminderControls(
    BuildContext context,
    UserInformation userInfo,
    Widget? child,
  ) {
    if (!userInfo.loggedIn) return const NotificationSignedOutCard();
    final repository = NotificationRepository.forService(userInfo.service);
    if (userInfo.userId.isNotEmpty &&
        !repository.isActiveAccount(userInfo.userId)) {
      return const SizedBox.shrink();
    }
    final preference = repository.getPreference('default');
    if (_hasPermission == false) {
      return NotificationPermissionDeniedCard(
        onRequestPermission: _requestReminderPermission,
        onCancelReminder: () => _onToggle(false, userInfo),
        canRequestPermission: _canRequestPermission,
        gender: userInfo.gender,
        requestPermissionBody: appLocale.notificationPageHeader(
          userInfo.gender,
        ),
      );
    }
    if (_hasPermission == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return NotificationToggleCard(
      emoji: '✨',
      badgeText: 'LP',
      title: appLocale.reminderAppTitle,
      subtitle: appLocale.reminderAppSubtitle,
      setTimeLabel: appLocale.notificationsSetTime,
      initialEnabled: preference != null,
      initialTime: switch (repository.getSavedTime('default')) {
        final saved? => TimeOfDay(hour: saved.hour, minute: saved.minute),
        null => NotificationToggleCard.defaultReminderTime,
      },
      onTimeSelected: _onPickedTime,
      onToggle: (value) => _onToggle(value, userInfo),
    );
  }

  Future<void> _requestReminderPermission() =>
      _checkPermission(requestPermission: true);
}
