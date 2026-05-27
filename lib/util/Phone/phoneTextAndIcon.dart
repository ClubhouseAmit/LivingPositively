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
        builder: (innerContext) {
          final locale = AppLocalizations.of(innerContext);
          final tooltip = locale?.callContactTooltip(contact) ?? contact;
          // Tooltip wires `message` into both the visible long-press hint
          // and the Semantics label, so TalkBack/VoiceOver announce
          // "Call <contact> button" instead of an unlabeled icon. The 48dp
          // SizedBox is the minimum Material tap target — the CircleAvatar
          // (radius 20 → 40dp visual) keeps the same look but the hit area
          // grows to the WCAG-recommended size (UX_GAPS §1.6).
          return Tooltip(
            message: tooltip,
            child: Semantics(
              button: true,
              child: SizedBox(
                width: 48,
                height: 48,
                child: InkWell(
                  onTap: () => launchWithFeedback(
                    innerContext,
                    phone,
                    isCallFailure: true,
                    launch: () => dialPhone(phone),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 20, // adjust as needed
                      backgroundColor: primaryPurple,
                      foregroundColor: appWhite,
                      child: const Icon(
                        Icons.phone,
                        size: 20,
                      ), // adjust as needed
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
              30,
            ), // present the contacts from myContacts list
          ),
        ),
      ),
    ],
  );
}

/// Captures `ScaffoldMessenger` and `AppLocalizations` from [context]
/// *before* awaiting [launch], then routes a failed launch to
/// [showLaunchFailureSnackBar]. Centralizing the capture-before-await
/// pattern keeps the invariant in one place — callers can't accidentally
/// reach for a stale context after an `await` (the bug that motivated
/// ADR-005 §A.1).
///
/// "Failure" covers both a `false` return value AND a thrown exception
/// (e.g. `PlatformException` for unsupported schemes, `ArgumentError`
/// for malformed URIs) from `url_launcher` — both paths reach the user
/// as the same recoverable snackbar.
///
/// [number] is the value offered to the snackbar's "Copy number" action;
/// pass an empty string for launches that have no number worth copying
/// (e.g. opening a web link).
Future<void> launchWithFeedback(
  BuildContext context,
  String number, {
  required bool isCallFailure,
  required Future<bool> Function() launch,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final locale = AppLocalizations.of(context);
  bool ok;
  try {
    ok = await launch();
  } catch (error, stackTrace) {
    debugPrint('launchWithFeedback caught $error\n$stackTrace');
    ok = false;
  }
  if (!ok) {
    showLaunchFailureSnackBar(
      messenger,
      locale,
      number,
      isCallFailure: isCallFailure,
    );
  }
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
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(appLocale.numberCopiedToast),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
      duration: const Duration(seconds: 6),
    ),
  );
}

/// Wraps `launchUrl` so the four public action helpers share one
/// "launch + log on false + return launched" shape.
///
/// [mode] is forwarded to `launchUrl`; pass `LaunchMode.externalApplication`
/// for app handoffs (WhatsApp, browser). The default
/// `LaunchMode.platformDefault` matches `launchUrl(uri)`'s historical
/// behavior for `tel:` and `sms:`.
Future<bool> _launchUriWithLogging(
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  final launched = await launchUrl(uri, mode: mode);
  if (!launched) {
    debugPrint('Could not launch $uri');
  }
  return launched;
}

Future<bool> dialPhone(String number) =>
    _launchUriWithLogging(_dialPhoneUri(number));

Uri _dialPhoneUri(String number) {
  final trimmedNumber = number.trim();
  if (defaultTargetPlatform == TargetPlatform.android &&
      RegExp(r'^\d{4}$').hasMatch(trimmedNumber)) {
    return Uri.parse('tel:${Uri.encodeComponent('$trimmedNumber ')}');
  }
  return Uri.parse('tel:$trimmedNumber');
}

Future<bool> openWhatsApp(String number) => _launchUriWithLogging(
  Uri.parse('https://wa.me/$number'),
  mode: LaunchMode.externalApplication,
);

Future<bool> openSite(String url) =>
    _launchUriWithLogging(Uri.parse(url), mode: LaunchMode.externalApplication);

Future<bool> openTextMessage(String number, {String body = ''}) {
  final trimmedBody = body.trim();
  final uri = trimmedBody.isEmpty
      ? Uri(scheme: 'sms', path: number)
      : Uri(
          scheme: 'sms',
          path: number,
          queryParameters: {'body': trimmedBody},
        );
  return _launchUriWithLogging(uri);
}

Widget getTextIconWidget(String text, Function onClick, IconData icon) {
  return SizedBox(
    child: Row(
      children: [
        myText(
          text,
          TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 18.sp > 35 ? 35 : 20.sp,
          ),
          null,
        ),
        SizedBox(width: 5.0),
        // Button to make a phone call. Tooltip carries the visible long-press
        // hint and the announced label; Semantics(button: true) ensures the
        // GestureDetector reads as a button rather than plain text.
        // 48dp tap target per UX_GAPS §1.6.
        Tooltip(
          message: text,
          child: Semantics(
            button: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: GestureDetector(
                onTap: () async {
                  onClick();
                },
                child: Center(
                  child: CircleAvatar(
                    radius: 20, // adjust as needed
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    child: Icon(icon, size: 20), // adjust as needed
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.0),
      ],
    ),
  );
}
