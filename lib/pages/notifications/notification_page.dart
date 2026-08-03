import 'package:flutter/material.dart';
import 'package:mazilon/pages/notifications/reminder_debug_recorder.dart';
import 'package:mazilon/pages/notifications/set_notification_widget.dart';
import 'package:mazilon/util/HomePage/premium_glass_app_bar.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/page_layout_wrapper.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({this.onBackPressed, super.key});
  final VoidCallback? onBackPressed;

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
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );

    final gender = userInfoProvider.gender;
    return PageLayoutWrapper(
      sliverAppBar: PremiumGlassAppBar(
        variant: AppBarVariant.detailScreen,
        onBackPressed: widget.onBackPressed,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: _toggleDebugUnlock,
          child: Text(
            appLocale.notificationPageHeader(gender),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Spacing.md),
          Text(
            appLocale.notificationPageHeader(gender),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: Spacing.lg),
          SetNotificationWidget(),
        ],
      ),
    );
  }
}
