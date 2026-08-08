import 'package:flutter/material.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/UserSettings.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import "package:mazilon/util/Firebase/fcm_service.dart";

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
    final anchorOffset = anchorBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );

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
    pageBuilder:
        (
          BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          final closeButton = IconButton(
            key: const Key('mainMenuCloseButton'),
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          );
          final aboutButton = Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _buildMainMenuAction(
                icon: Icons.people,
                label: appLocale.homePageAbout(gender),
                mainAxisSize: MainAxisSize.min,
                onPressed: () {
                  onAboutPressed();
                  Navigator.of(context).pop();
                },
              ),
            ),
          );

          return Stack(
            children: [
              Positioned(
                left: menuLeft,
                top: menuTop,
                width: menuWidth,
                child: Material(
                  key: const Key('mainMenuDialog'),
                  color: Theme.of(buildContext).colorScheme.surface,
                  elevation: 24.0,
                  shape: Border.all(
                    color: Theme.of(buildContext).colorScheme.primary,
                    width: 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        textDirection: TextDirection.ltr,
                        children: isRtl
                            ? [closeButton, aboutButton]
                            : [aboutButton, closeButton],
                      ),
                      _notificationButton(
                        context: context,
                        appLocale: appLocale,
                        gender: gender,
                        isWeb: isWeb,
                        onNotificationsPressed: onNotificationsPressed,
                      ),
                      _buildMainMenuAction(
                        icon: Icons.settings,
                        label: appLocale.settings(gender),
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
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMainMenuAction(
                        icon: Icons.share,
                        label: appLocale.shareButtonText,
                        onPressed: () async {
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                                  '${appLocale.shareAppMessage}\n ${_shareAppUrl(appLocale)}',
                              subject: 'Living Positively App',
                            ),
                          );
                        },
                      ),
                      _buildMainMenuAction(
                        key: const Key('mainMenuContactUsButton'),
                        icon: Icons.email,
                        label: appLocale.contactUs,
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

Widget _buildMainMenuAction({
  Key? key,
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
  MainAxisSize mainAxisSize = MainAxisSize.max,
}) {
  return TextButton(
    key: key,
    onPressed: onPressed,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: mainAxisSize,
      children: [Icon(icon), const SizedBox(width: 20), Text(label)],
    ),
  );
}

Widget _notificationButton({
  required BuildContext context,
  required AppLocalizations appLocale,
  required String gender,
  required bool isWeb,
  required VoidCallback onNotificationsPressed,
}) {
  if (!FcmService.supportsReminderSettings(isWebOverride: isWeb)) {
    return const SizedBox.shrink();
  }

  return _buildMainMenuAction(
    icon: Icons.notification_add,
    label: appLocale.notifications(gender),
    onPressed: () {
      onNotificationsPressed();
      Navigator.of(context).pop();
    },
  );
}
