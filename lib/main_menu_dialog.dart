import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/UserSettings.dart';
import 'package:mazilon/pages/notifications/notification_service.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _hebrewContactUsUrl =
    'https://sites.google.com/mishol.org/matzilon/%D7%AA%D7%9E%D7%99%D7%9B%D7%94';
const _englishContactUsUrl =
    'https://sites.google.com/mishol.org/living-positively/support';

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
  final mediaQuery = MediaQuery.of(context);
  final screenWidth = mediaQuery.size.width;
  final isRtl = appLocale.textDirection == "rtl";
  final maxMenuWidth = screenWidth - 24 < 260 ? screenWidth - 24 : 260.0;
  final minMenuWidth = maxMenuWidth < 180 ? maxMenuWidth : 180.0;
  final menuWidth = (screenWidth * (isRtl ? 0.38 : 0.45))
      .clamp(minMenuWidth, maxMenuWidth)
      .toDouble();
  final anchorBox = anchorContext.findRenderObject();
  final overlayBox = Overlay.of(context).context.findRenderObject();
  var menuLeft = isRtl ? 12.0 : screenWidth - menuWidth - 12.0;
  var menuTop = mediaQuery.padding.top + kToolbarHeight;

  if (anchorBox is RenderBox && overlayBox is RenderBox) {
    final anchorOffset =
        anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    menuLeft = isRtl
        ? anchorOffset.dx
        : anchorOffset.dx + anchorBox.size.width - menuWidth;
    menuTop = anchorOffset.dy + anchorBox.size.height + 8;
  }

  menuLeft = menuLeft.clamp(12.0, screenWidth - menuWidth - 12.0).toDouble();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: menuLeft,
            top: menuTop,
            width: menuWidth,
            child: Material(
              key: const Key('mainMenuDialog'),
              color: Colors.white,
              elevation: 24.0,
              shape: Border.all(
                color: primaryPurple,
                width: 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    textDirection:
                        isRtl ? TextDirection.ltr : TextDirection.rtl,
                    children: [
                      IconButton(
                        key: const Key('mainMenuCloseButton'),
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      Expanded(
                        child: Align(
                          alignment: isRtl
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: TextButton(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people),
                                const SizedBox(width: 20),
                                Text(appLocale.homePageAbout(gender)),
                              ],
                            ),
                            onPressed: () {
                              onAboutPressed();
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  _notificationButton(
                    context: context,
                    appLocale: appLocale,
                    gender: gender,
                    isWeb: isWeb,
                    onNotificationsPressed: onNotificationsPressed,
                  ),
                  TextButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 20),
                        Text(appLocale.settings(gender)),
                      ],
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UserSettings(
                                  phonePageData: phonePageData,
                                  username: userInformation.name,
                                  age: age,
                                  gender: gender,
                                  changeLocale: changeLocale,
                                )),
                      );
                    },
                  ),
                  TextButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.share),
                        const SizedBox(width: 20),
                        Text(appLocale.shareButtonText),
                      ],
                    ),
                    onPressed: () async {
                      await SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${appLocale.shareAppMessage}\n https://sites.google.com/mishol.org/matzilon/%D7%91%D7%99%D7%AA',
                          subject: 'Living Positively App',
                        ),
                      );
                    },
                  ),
                  TextButton(
                    key: const Key('mainMenuContactUsButton'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.email),
                        const SizedBox(width: 20),
                        Text(appLocale.contactUs),
                      ],
                    ),
                    onPressed: () async {
                      await _openContactUs(appLocale);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget _notificationButton({
  required BuildContext context,
  required AppLocalizations appLocale,
  required String gender,
  required bool isWeb,
  required VoidCallback onNotificationsPressed,
}) {
  if (!NotificationsService.supportsReminderSettings(isWebOverride: isWeb)) {
    return const SizedBox.shrink();
  }

  return TextButton(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Icon(Icons.notification_add),
        const SizedBox(width: 20),
        Text(appLocale.notifications(gender)),
      ],
    ),
    onPressed: () {
      onNotificationsPressed();
      Navigator.of(context).pop();
    },
  );
}
