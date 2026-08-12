import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

List<Widget> buildMainMenuItems({
  required BuildContext context,
  required AppLocalizations appLocale,
  required UserInformation userInformation,
  required PhonePageData phonePageData,
  required Function changeLocale,
  required bool isWeb,
  required VoidCallback onAboutPressed,
  required VoidCallback onNotificationsPressed,
  VoidCallback? onAnyPressed,
}) {
  final gender = userInformation.gender;
  final age = userInformation.age;

  return [
    MenuItemButton(
      leadingIcon: const Icon(Icons.people),
      onPressed: () {
        onAnyPressed?.call();
        onAboutPressed();
      },
      child: Text(appLocale.homePageAbout(gender)),
    ),
    if (NotificationsService.supportsReminderSettings(isWebOverride: isWeb))
      MenuItemButton(
        leadingIcon: const Icon(Icons.notification_add),
        onPressed: () {
          onAnyPressed?.call();
          onNotificationsPressed();
        },
        child: Text(appLocale.notifications(gender)),
      ),
    MenuItemButton(
      leadingIcon: const Icon(Icons.settings),
      onPressed: () {
        onAnyPressed?.call();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserSettings(
              phonePageData: phonePageData,
              username: userInformation.name,
              age: age,
              gender: gender,
              changeLocale: changeLocale,
            ),
          ),
        );
      },
      child: Text(appLocale.settings(gender)),
    ),
    MenuItemButton(
      leadingIcon: const Icon(Icons.share),
      onPressed: () async {
        onAnyPressed?.call();
        await SharePlus.instance.share(
          ShareParams(
            text: '${appLocale.shareAppMessage}\n ${_shareAppUrl(appLocale)}',
            subject: 'Living Positively App',
          ),
        );
      },
      child: Text(appLocale.shareButtonText),
    ),
    MenuItemButton(
      key: const Key('mainMenuContactUsButton'),
      leadingIcon: const Icon(Icons.email),
      onPressed: () async {
        onAnyPressed?.call();
        await _openContactUs(appLocale);
      },
      child: Text(appLocale.contactUs),
    ),
  ];
}

class MainMenuAnchor extends StatelessWidget {
  final UserInformation userInformation;
  final PhonePageData phonePageData;
  final Function changeLocale;
  final bool isWeb;
  final VoidCallback onAboutPressed;
  final VoidCallback onNotificationsPressed;
  final Widget? child;

  const MainMenuAnchor({
    super.key,
    required this.userInformation,
    required this.phonePageData,
    required this.changeLocale,
    required this.onAboutPressed,
    required this.onNotificationsPressed,
    this.isWeb = kIsWeb,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return MenuAnchor(
      key: const Key('mainMenuDialog'),
      style: MenuStyle(
        shape: WidgetStateProperty.all<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      builder:
          (BuildContext context, MenuController controller, Widget? childWidget) {
        if (child != null) {
          return InkWell(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: child,
          );
        }
        return IconButton(
          key: const Key('mainMenuButton'),
          icon: Icon(
            Icons.settings_outlined,
            color: colorScheme.primary,
            size: 26,
          ),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        );
      },
      menuChildren: buildMainMenuItems(
        context: context,
        appLocale: appLocale,
        userInformation: userInformation,
        phonePageData: phonePageData,
        changeLocale: changeLocale,
        isWeb: isWeb,
        onAboutPressed: onAboutPressed,
        onNotificationsPressed: onNotificationsPressed,
      ),
    );
  }
}

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
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        key: const Key('mainMenuDialog'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: IconButton(
                  key: const Key('mainMenuCloseButton'),
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ),
              ...buildMainMenuItems(
                context: dialogContext,
                appLocale: appLocale,
                userInformation: userInformation,
                phonePageData: phonePageData,
                changeLocale: changeLocale,
                isWeb: isWeb,
                onAboutPressed: onAboutPressed,
                onNotificationsPressed: onNotificationsPressed,
                onAnyPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
