// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderDebugPanel extends StatefulWidget {
  const ReminderDebugPanel({super.key});

  @override
  State<ReminderDebugPanel> createState() => _ReminderDebugPanelState();
}

class _ReminderDebugPanelState extends State<ReminderDebugPanel> {
  String? _lastFireAt;
  String? _lastStatus;
  String? _lastError;
  String? _lastTask;
  List<String> _recentEvents = const [];
  PermissionStatus? _notificationStatus;
  PermissionStatus? _batteryOptStatus;
  bool _loading = false;
  bool _busy = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    PermissionStatus? notif;
    PermissionStatus? battery;
    if (_isAndroid) {
      notif = await Permission.notification.status;
      battery = await Permission.ignoreBatteryOptimizations.status;
    }
    if (!mounted) return;
    setState(() {
      _lastFireAt = prefs.getString(reminderDebugLastFireAtKey);
      _lastStatus = prefs.getString(reminderDebugLastStatusKey);
      _lastError = prefs.getString(reminderDebugLastErrorKey);
      _lastTask = prefs.getString(reminderDebugLastTaskKey);
      _recentEvents =
          prefs.getStringList(reminderDebugRecentEventsKey) ?? const [];
      _notificationStatus = notif;
      _batteryOptStatus = battery;
      _loading = false;
    });
  }

  Future<void> _reschedule() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final userInfo = context.read<UserInformation>();
      final appLocale = AppLocalizations.of(context);
      if (appLocale == null) return;
      final quotes = retrieveInspirationalQuotes(appLocale, userInfo.gender);
      await NotificationsService.initializeNotification(
        quotes,
        userInfo.notificationHour,
        userInfo.notificationMinute,
        appLocale.notifyOnscheduledNotification,
        appLocale,
      );
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearHistory() async {
    await clearReminderDebugEvents();
    await _refresh();
  }

  Future<void> _copyDiagnostics() async {
    final payload = const JsonEncoder.withIndent('  ').convert({
      'capturedAt': DateTime.now().toIso8601String(),
      'platform': _isAndroid ? 'android' : defaultTargetPlatform.toString(),
      'lastFireAt': _lastFireAt,
      'lastStatus': _lastStatus,
      'lastTask': _lastTask,
      'lastError': _lastError,
      'notificationPermission': _permLabel(_notificationStatus),
      'batteryOptimizationExempt': _permLabel(_batteryOptStatus),
      'recentEvents': _recentEvents,
    });
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics copied to clipboard')),
    );
  }

  static String _permLabel(PermissionStatus? status) {
    if (status == null) return 'n/a';
    return status.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = context.watch<UserInformation>();
    final scheduledTime =
        '${userInfo.notificationHour.toString().padLeft(2, '0')}:${userInfo.notificationMinute.toString().padLeft(2, '0')}';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        title: const Text(
          'Reminder debug panel',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Diagnose why scheduled reminders may not be firing',
          style: TextStyle(fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          _row('Scheduled time', scheduledTime),
          _row('Last fire at', _lastFireAt ?? '—'),
          _row('Last status', _lastStatus ?? '—',
              valueColor: _statusColor(_lastStatus)),
          _row('Last task', _lastTask ?? '—'),
          if ((_lastError ?? '').isNotEmpty)
            _row('Last error', _lastError!, valueColor: Colors.red.shade700),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          _row('Notification permission', _permLabel(_notificationStatus),
              valueColor: _permColor(_notificationStatus)),
          _row('Battery optimization exempt', _permLabel(_batteryOptStatus),
              valueColor: _permColor(_batteryOptStatus)),
          if (!_isAndroid)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'WorkManager-backed reminders run on Android only.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _loading ? null : _refresh,
                child: const Text('Refresh'),
              ),
              OutlinedButton(
                onPressed: (_busy || !_isAndroid) ? null : _reschedule,
                child: const Text('Reschedule now'),
              ),
              OutlinedButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open app settings'),
              ),
              OutlinedButton(
                onPressed: _copyDiagnostics,
                child: const Text('Copy diagnostics'),
              ),
              OutlinedButton(
                onPressed: _recentEvents.isEmpty ? null : _clearHistory,
                child: const Text('Clear history'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'Recent events (${_recentEvents.length})',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _recentEvents.isEmpty
                ? const Text(
                    'No events recorded yet.',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _recentEvents.reversed
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: SelectableText(
                              e,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }

  Color? _statusColor(String? status) {
    switch (status) {
      case reminderDebugStatusSuccess:
        return Colors.green.shade700;
      case reminderDebugStatusFailure:
        return Colors.red.shade700;
      default:
        return null;
    }
  }

  Color? _permColor(PermissionStatus? status) {
    if (status == null) return null;
    if (status.isGranted) return Colors.green.shade700;
    if (status.isPermanentlyDenied || status.isDenied) {
      return Colors.red.shade700;
    }
    return null;
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(fontSize: 12, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
