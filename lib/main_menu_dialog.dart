import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/UserSettings.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _hebrewContactUsUrl =
    'https://hebsite.livepositively.club/%D7%AA%D7%9E%D7%99%D7%9B%D7%94';
const _englishContactUsUrl = 'https://engsite.livepositively.club/support';
const _hebrewShareAppUrl = 'https://hebsite.livepositively.club';
const _englishShareAppUrl = 'https://engsite.livepositively.club';

String _shareAppUrl(AppLocalizations appLocale) {
  return appLocale.localeName.startsWith('he')
      ? _hebrewShareAppUrl
      : _englishShareAppUrl;
}

String _contactUsUrl(AppLocalizations appLocale) {
  return appLocale.localeName.startsWith('he')
      ? _hebrewContactUsUrl
      : _englishContactUsUrl;
}

Future<void> _openContactUs(AppLocalizations appLocale) async {
  final uri = Uri.parse(_contactUsUrl(appLocale));
  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  );
  if (!launched) {
    debugPrint('Could not launch $uri');
  }
}

/// Identifiers for the menu items returned by [showMenu].
enum _MenuAction { about, notifications, settings, share, contactUs }

void showMainMenuDialog({
  required BuildContext context,
  required BuildContext anchorContext,
  required AppLocalizations appLocale,
  required UserInformation userInformation,
  required PhonePageData phonePageData,
  required Function changeLocale,
  required bool isWeb,
  required VoidCallback onAboutPressed,
  required VoidCallback onNotificationsPressed,
}) {
  final gender = userInformation.gender;
  final age = userInformation.age;

  // Compute the anchor position for the popover.
  final anchorBox = anchorContext.findRenderObject() as RenderBox?;
  final overlayBox =
      Overlay.of(context).context.findRenderObject() as RenderBox?;

  RelativeRect position;
  if (anchorBox != null && overlayBox != null) {
    final anchorOffset = anchorBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    position = RelativeRect.fromLTRB(
      anchorOffset.dx,
      anchorOffset.dy + anchorBox.size.height,
      anchorOffset.dx + anchorBox.size.width,
      0,
    );
  } else {
    // Fallback when render objects aren't available.
    final mediaQuery = MediaQuery.of(context);
    position = RelativeRect.fromLTRB(
      12,
      mediaQuery.padding.top + kToolbarHeight,
      12,
      0,
    );
  }

  // Build the list of menu items.
  final items = <PopupMenuEntry<_MenuAction>>[
    PopupMenuItem<_MenuAction>(
      key: const Key('mainMenuAboutButton'),
      value: _MenuAction.about,
      child: _MenuRow(
        icon: LucideIcons.users,
        label: appLocale.homePageAbout(gender),
      ),
    ),
    if (NotificationsService.supportsReminderSettings(isWebOverride: isWeb))
      PopupMenuItem<_MenuAction>(
        value: _MenuAction.notifications,
        child: _MenuRow(
          icon: LucideIcons.bell,
          label: appLocale.notifications(gender),
        ),
      ),
    PopupMenuItem<_MenuAction>(
      value: _MenuAction.settings,
      child: _MenuRow(
        icon: LucideIcons.settings,
        label: appLocale.settings(gender),
      ),
    ),
    PopupMenuItem<_MenuAction>(
      value: _MenuAction.share,
      child: _MenuRow(
        icon: LucideIcons.share,
        label: appLocale.shareButtonText,
      ),
    ),
    PopupMenuItem<_MenuAction>(
      key: const Key('mainMenuContactUsButton'),
      value: _MenuAction.contactUs,
      child: _MenuRow(
        icon: LucideIcons.mail,
        label: appLocale.contactUs,
      ),
    ),
  ];

  unawaited(showMenu<_MenuAction>(
    context: context,
    position: position,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 8,
    items: items,
  ).then((action) async {
    if (action == null) return;

    switch (action) {
      case _MenuAction.about:
        onAboutPressed();
      case _MenuAction.notifications:
        onNotificationsPressed();
      case _MenuAction.settings:
        if (!context.mounted) return;
        unawaited(
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => UserSettings(
                phonePageData: phonePageData,
                username: userInformation.name,
                age: age,
                gender: gender,
                changeLocale: changeLocale,
              ),
            ),
          ),
        );
      case _MenuAction.share:
        await SharePlus.instance.share(
          ShareParams(
            text:
                '${appLocale.shareAppMessage}\n'
                ' ${_shareAppUrl(appLocale)}',
            subject: 'Living Positively App',
          ),
        );
      case _MenuAction.contactUs:
        await _openContactUs(appLocale);
    }
  }));
}

/// A simple icon + label row used inside each [PopupMenuItem].
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
