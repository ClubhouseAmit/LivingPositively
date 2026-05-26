// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:mazilon/util/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/l10n/app_localizations.dart';

// This widget is a dialog box for making emergency phone calls and sending WhatsApp messages.
class EmergencyDialogBox extends StatelessWidget {
  final String number; // The phone number to dial or message
  final String whatsappNumber;
  final String link;
  final String textNumber;
  final String textMessage;
  final String linkType;
  final bool hasWhatsApp;
  final bool hasLink;
  final bool canCall;
  const EmergencyDialogBox(
      {super.key,
      required this.number,
      required this.whatsappNumber,
      required this.link,
      this.textNumber = '',
      this.textMessage = '',
      this.linkType = 'website',
      required this.hasWhatsApp,
      required this.canCall,
      required this.hasLink});

  @override
  Widget build(BuildContext context) {
    UserInformation userInfoProvider = Provider.of<UserInformation>(context);
    final appLocale = AppLocalizations.of(context);
    final gender = userInfoProvider.gender;
    final hasText = textNumber.trim().isNotEmpty;
    final isChatLink = linkType == 'chat';
    return AlertDialog(
      // Title of the dialog box
      title: myText(
          appLocale!.select(gender),
          TextStyle(
              fontWeight: FontWeight.normal, fontSize: 18.sp > 40 ? 40 : 20.sp),
          null),
      // Content of the dialog box, which includes options to make a call or send a WhatsApp message
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                if (canCall)
                  getTextIconWidget(
                    appLocale!.dialButton(gender),
                    () async {
                      // Capture messenger before await to avoid mounted/race issues (strategy b).
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final locale = AppLocalizations.of(context);
                      final ok = await dialPhone(number);
                      if (!ok) {
                        showLaunchFailureSnackBar(
                          messenger,
                          locale,
                          number,
                          isCallFailure: true,
                        );
                      }
                    },
                    Icons.phone,
                  ),
                if (hasText)
                  getTextIconWidget(
                    'Text',
                    () async {
                      // Capture messenger before await to avoid mounted/race issues (strategy b).
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final locale = AppLocalizations.of(context);
                      final ok = await openTextMessage(
                        textNumber,
                        body: textMessage,
                      );
                      if (!ok) {
                        showLaunchFailureSnackBar(
                          messenger,
                          locale,
                          textNumber,
                          isCallFailure: false,
                        );
                      }
                    },
                    Icons.sms,
                  ),
                if (hasWhatsApp)
                  getTextIconWidget(appLocale!.whatsApp, () async {
                    // Capture messenger before await to avoid mounted/race issues (strategy b).
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    final locale = AppLocalizations.of(context);
                    final ok = await openWhatsApp(whatsappNumber);
                    if (!ok) {
                      showLaunchFailureSnackBar(
                        messenger,
                        locale,
                        whatsappNumber,
                        isCallFailure: false,
                      );
                    }
                  }, Icons.chat),

                if (hasLink)
                  getTextIconWidget(
                    isChatLink ? 'Chat' : appLocale.link,
                    () async {
                      // Capture messenger before await to avoid mounted/race issues (strategy b).
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final locale = AppLocalizations.of(context);
                      final ok = await openSite(link);
                      if (!ok) {
                        showLaunchFailureSnackBar(
                          messenger,
                          locale,
                          '',
                          isCallFailure: false,
                        );
                      }
                    },
                    isChatLink ? Icons.chat_bubble_outline : Icons.language,
                  ),

                // Button to make a phone call
              ],
            ),
          ],
        ),
      ),
      // Back button to close the dialog box
      actions: <Widget>[
        TextButton(
          child: myText(
              appLocale!.backButton(gender),
              TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp > 30 ? 30 : 20.sp),
              null),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
