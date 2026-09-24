import 'package:flutter/material.dart' hide Text;
import 'package:permission_handler/permission_handler.dart';

import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/features/shell/ui/LP_extended_state.dart';
import 'package:mazilon/features/shell/ui/styles.dart';

class NotificationPermissionDeniedCard extends StatefulWidget {
  const NotificationPermissionDeniedCard({
    required this.onRequestPermission,
    required this.onCancelReminder,
    required this.canRequestPermission,
    required this.gender,
    required this.requestPermissionBody,
    super.key,
  });

  final Future<void> Function() onRequestPermission;
  final Future<bool> Function() onCancelReminder;
  final bool canRequestPermission;
  final String gender;
  final String requestPermissionBody;

  @override
  State<NotificationPermissionDeniedCard> createState() =>
      _NotificationPermissionDeniedCardState();
}

class _NotificationPermissionDeniedCardState
    extends LPExtendedState<NotificationPermissionDeniedCard> {
  bool _requesting = false;
  bool _cancelling = false;

  Future<void> _requestPermission() async {
    if (_requesting || _cancelling) return;
    setState(() => _requesting = true);
    try {
      await widget.onRequestPermission();
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _cancelReminder() async {
    if (_requesting || _cancelling) return;
    setState(() => _cancelling = true);
    try {
      await widget.onCancelReminder();
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 40,
            color: Colors.grey,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.canRequestPermission
                ? appLocale.notificationsEnable
                : appLocale.notificationsPermissionDeniedTitle,
            style: AppTextStyle.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs + AppSpacing.hairline * 2),
          Text(
            widget.canRequestPermission
                ? widget.requestPermissionBody
                : appLocale.notificationsPermissionDeniedBody,
            style: AppTextStyle.bodySmall,
            color: Colors.grey,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) => Column(
    children: [
      Button(
        onPressed: !widget.canRequestPermission || _requesting || _cancelling
            ? null
            : _requestPermission,
        label: appLocale.notificationsEnable,
      ),
      const SizedBox(height: AppSpacing.sm),
      Button(
        onPressed: _requesting || _cancelling ? null : _cancelReminder,
        label: appLocale.notificationCancelNotification(widget.gender),
        variant: ButtonVariant.secondary,
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
  );
}
