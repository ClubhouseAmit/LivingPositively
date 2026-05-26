import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';

Widget phoneContact(String phone, String contact) {
  return Row(
    children: <Widget>[
      // Builder gives us a context that's inside the surrounding Scaffold's
      // subtree, so ScaffoldMessenger.maybeOf works in the tap callback.
      Builder(
        builder: (innerContext) => InkWell(
          onTap: () async {
            // Capture messenger + locale BEFORE the await to avoid mounted/race
            // (same strategy as emergencyDialogBox.dart per ADR-005 §A.1).
            final messenger = ScaffoldMessenger.maybeOf(innerContext);
            final locale = AppLocalizations.of(innerContext);
            final ok = await dialPhone(phone);
            if (!ok) {
              showLaunchFailureSnackBar(
                messenger,
                locale,
                phone,
                isCallFailure: true,
              );
            }
          },
          child: CircleAvatar(
            radius: 20, // adjust as needed
            backgroundColor: primaryPurple,
            foregroundColor: appWhite,
            child: const Icon(Icons.phone, size: 20), // adjust as needed
          ),
        ),
      ),
      const SizedBox(width: 10.0), // adjust as needed
      Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: myAutoSizedText(
                contact,
                TextStyle(fontWeight: FontWeight.normal, fontSize: 20.sp),
                null,
                30), // present the contacts from myContacts list
          ),
        ),
      ),
    ],
  );
}

/// Shows a snackbar describing a [launchUrl] failure, with an optional
/// "Copy number" action that writes [number] to the clipboard. The
/// [messenger] and [appLocale] must be captured before the async gap so we
/// avoid the `context.mounted` race after a dialog closes.
///
/// Used by both [phoneContact] (personal emergency contacts) and
/// `EmergencyDialogBox` (system emergency numbers). See ADR-005 §A.1.
void showLaunchFailureSnackBar(
  ScaffoldMessengerState? messenger,
  AppLocalizations? appLocale,
  String number, {
  required bool isCallFailure,
}) {
  if (messenger == null || appLocale == null) return;
  HapticFeedback.heavyImpact();
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        isCallFailure
            ? appLocale.callFailedMessage(number)
            : appLocale.couldNotOpenApp,
      ),
      action: number.isEmpty
          ? null
          : SnackBarAction(
              label: appLocale.copyNumberAction,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: number));
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(SnackBar(
                  content: Text(appLocale.numberCopiedToast),
                  duration: const Duration(seconds: 2),
                ));
              },
            ),
      duration: const Duration(seconds: 6),
    ),
  );
}

Future<bool> dialPhone(String number) async {
  final uri = _dialPhoneUri(number);
  final launched = await launchUrl(uri);
  if (!launched) {
    debugPrint('Could not launch $uri');
  }
  return launched;
}

Uri _dialPhoneUri(String number) {
  final trimmedNumber = number.trim();
  if (defaultTargetPlatform == TargetPlatform.android &&
      RegExp(r'^\d{4}$').hasMatch(trimmedNumber)) {
    return Uri.parse('tel:${Uri.encodeComponent('$trimmedNumber ')}');
  }
  return Uri.parse('tel:$trimmedNumber');
}

Future<bool> openWhatsApp(String number) async {
  final uri = Uri.parse('https://wa.me/$number');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    debugPrint('Could not launch $uri');
  }
  return launched;
}

Future<bool> openSite(String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    debugPrint('Could not launch $uri');
  }
  return launched;
}

Future<bool> openTextMessage(String number, {String body = ''}) async {
  final trimmedBody = body.trim();
  final uri = trimmedBody.isEmpty
      ? Uri(scheme: 'sms', path: number)
      : Uri(
          scheme: 'sms',
          path: number,
          queryParameters: {'body': trimmedBody},
        );
  final launched = await launchUrl(uri);
  if (!launched) {
    debugPrint('Could not launch $uri');
  }
  return launched;
}

Widget getTextIconWidget(
  String text,
  Function onClick,
  IconData icon,
) {
  return SizedBox(
      child: Row(
    children: [
      myText(
          text,
          TextStyle(
              fontWeight: FontWeight.normal, fontSize: 18.sp > 35 ? 35 : 20.sp),
          null),
      SizedBox(width: 5.0),
      // Button to make a phone call
      GestureDetector(
        child: CircleAvatar(
          radius: 20, // adjust as needed
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          child: Icon(icon, size: 20), // adjust as needed
        ),
        onTap: () async {
          onClick();
        },
      ),
      SizedBox(width: 10.0),
    ],
  ));
}
