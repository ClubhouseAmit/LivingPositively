import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/pages/notifications/reminder_debug_panel.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/pages/notifications/time_picker.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/theme/app_theme.dart';

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
  late TextEditingController _messageController;

  void setTime(int minute, int hour) {
    setState(() {
      _currentHour = hour;
      _currentMinute = minute;
    });
  }

  void saveNotificationTime(
    int hour,
    int minute,
    UserInformation userInfo,
  ) async {
    userInfo.updateNotificationHour(hour);
    userInfo.updateNotificationMinute(minute);
    setState(() {
      _currentHour = hour;
      _currentMinute = minute;
    });
  }

  void initializeNotification(
    List<String> quotes,
    UserInformation userInfo,
    Function createText,
    AppLocalizations appLocale,
  ) {
    NotificationsService.initializeNotification(
      quotes,
      _currentHour,
      _currentMinute,
      createText,
      appLocale,
      customMessage: userInfo.notificationMessage,
    );
    saveNotificationTime(_currentHour, _currentMinute, userInfo);
  }

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    NotificationsService.init(); // Initialize NotificationsHelper
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      var userInfo = context.read<UserInformation>();
      setState(() {
        _currentHour = userInfo.notificationHour;
        _currentMinute = userInfo.notificationMinute;
        _messageController.text = userInfo.notificationMessage;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(context);

    var gender = userInfoProvider.gender;
    final colorScheme = Theme.of(context).colorScheme;

    final quotes = retrieveInspirationalQuotes(appLocale, gender);

    final customMessageLabel = appLocale.notificationCustomMessageLabel;
    final customMessageHint = appLocale.notificationCustomMessageHint;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Divider(
            color: colorScheme.outline,
            height: 5, // Adjust the height as needed
          ),
          TimePicker(
            setTime: setTime,
            currentHour: _currentHour,
            currentMinute: _currentMinute,
          ),
          SizedBox(width: 15),
          Divider(
            color: colorScheme.outline,
            height: 5, // Adjust the height as needed
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customMessageLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    key: const Key('custom-reminder-message-field'),
                    controller: _messageController,
                    textDirection: appLocale.textDirection == 'rtl'
                        ? TextDirection.rtl
                        : null,
                    onChanged: (val) {
                      userInfoProvider.updateNotificationMessage(val);
                    },
                    decoration: InputDecoration(
                      hintText: customMessageHint,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Center(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton(
                onPressed: () => {
                  initializeNotification(
                    quotes,
                    userInfoProvider,
                    appLocale.notifyOnscheduledNotification,
                    appLocale,
                  ),
                },
                child: Text(
                  appLocale.notificationSetTimeText(gender),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
            ),
          ),
          SizedBox(height: 25),
          Center(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: AppColors.neutralDark, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton(
                onPressed: () => {
                  NotificationsService.cancelNotifications(
                    null,
                    cancelWorker: true,
                  ),
                },
                child: Text(
                  appLocale.notificationCancelNotification(gender),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.neutralDark,
                    fontWeight: FontWeight.w600,
                  ),
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
                    Divider(color: colorScheme.outline, height: 5),
                    ReminderDebugPanel(),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
