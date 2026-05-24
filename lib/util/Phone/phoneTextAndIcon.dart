import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';

Widget phoneContact(String phone, String contact) {
  return Row(
    children: <Widget>[
      InkWell(
        onTap: () async {
          await dialPhone(phone);
        },
        child: CircleAvatar(
          radius: 20, // adjust as needed
          backgroundColor: primaryPurple,
          foregroundColor: appWhite,
          child: const Icon(Icons.phone, size: 20), // adjust as needed
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

Future<void> dialPhone(String number) async {
  final uri = _dialPhoneUri(number);
  if (!await launchUrl(uri)) {
    debugPrint('Could not launch $uri');
  }
}

Uri _dialPhoneUri(String number) {
  final trimmedNumber = number.trim();
  if (defaultTargetPlatform == TargetPlatform.android &&
      RegExp(r'^\d{4}$').hasMatch(trimmedNumber)) {
    return Uri.parse('tel:${Uri.encodeComponent('$trimmedNumber ')}');
  }
  return Uri.parse('tel:$trimmedNumber');
}

Future<void> openWhatsApp(String number) async {
  final uri = Uri.parse('https://wa.me/$number');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    debugPrint('Could not launch $uri');
  }
}

Future<void> openSite(String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    debugPrint('Could not launch $uri');
  }
}

Future<void> openTextMessage(String number, {String body = ''}) async {
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
