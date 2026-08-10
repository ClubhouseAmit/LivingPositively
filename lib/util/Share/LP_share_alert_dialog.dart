import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';

import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Share/LP_alert_dialog.dart';
import 'package:mazilon/util/Share/LP_alert_dialog_box_item.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class LPShareAlertDialog extends StatefulWidget {
  const LPShareAlertDialog({
    super.key,
  });

  @override
  State<LPShareAlertDialog> createState() => _LPShareAlertDialogState();
}

Future<void> shareFile(appLocale, gender, appInfoProvider) async {
  var fileService = GetIt.instance<FileService>();
  await fileService.share(
      "",
      [
        appLocale!.distractionsHeader(gender),
        appLocale!.difficultEventsHeader(gender),
        appLocale!.feelBetterHeader(gender),
        appLocale!.makeSaferHeader(gender),
        appLocale!.phonesPageHeader(gender),
        appLocale!.safeEnvironmentHeader(gender),
      ],
      [
        appLocale!.distractionsSubTitle(gender),
        appLocale!.difficultEventsSubTitle(gender),
        appLocale!.feelBetterSubTitle(gender),
        appLocale!.makeSaferSubTitle(gender),
        appLocale!.phonesPageSubTitle(gender),
        appLocale!.makeSaferSubTitle(gender),
      ],
      appInfoProvider.sharePDFtexts,
      ShareFileType.PDF,
      appLocale.textDirection);
}

class _LPShareAlertDialogState extends LPExtendedState<LPShareAlertDialog> {
  @override
  Widget build(BuildContext context) {
    FileService fileService = GetIt.instance<FileService>();
    AppInformation appInfoProvider = Provider.of<AppInformation>(context);
    UserInformation userInfoProvider = Provider.of<UserInformation>(context);
    String gender = userInfoProvider.gender;

    return LPAlertDialog(
      title: appLocale.shareOptions,
      actions: [
        LPAlertDialogBoxItem(
          onPressed: () => shareFile(appLocale, gender, appInfoProvider),
          buttonText: appLocale.shareFile,
          icon: Icons.insert_drive_file_outlined,
        ),
        LPAlertDialogBoxItem(
          onPressed: () async {
            await fileService.shareTextOnly(appLocale.shareRoutineMessage);
            // Handle routine share
          },
          buttonText: appLocale.shareRoutine,
          icon: Icons.access_time,
        ),
        LPAlertDialogBoxItem(
          onPressed: () async {
            await fileService.shareTextOnly(appLocale.shareEmergencyMessage);
            // Handle emergency share
          },
          buttonText: appLocale.shareEmergency,
          icon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }
}
