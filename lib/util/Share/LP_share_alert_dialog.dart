import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';

import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Share/LP_alert_dialog.dart';
import 'package:mazilon/util/Share/LP_alert_dialog_box_item.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class LPShareAlertDialog extends StatefulWidget {
  const LPShareAlertDialog({super.key});

  @override
  State<LPShareAlertDialog> createState() => _LPShareAlertDialogState();
}

Future<ShareResult?> shareFile(
  AppLocalizations appLocale,
  String gender,
  String username,
  AppInformation appInfoProvider,
) {
  final fileService = GetIt.instance<FileService>();
  final exportMetadata = buildPersonalPlanExportMetadata(appLocale, gender, username);
  return fileService.share(
    "",
    exportMetadata.titles,
    exportMetadata.subTitles,
    appInfoProvider.sharePDFtexts,
    ShareFileType.PDF,
    mainTitle: exportMetadata.mainTitle,
    textDirection: appLocale.textDirection,
  );
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
          onPressed: () async {
            final personalPlanShareFailed = appLocale.personalPlanShareFailed;
            final shareResult = await shareFile(
              appLocale,
              gender,
              userInfoProvider.name,
              appInfoProvider,
            );
            if (!context.mounted) {
              return;
            }
            if (shareResult == null ||
                shareResult.status == ShareResultStatus.unavailable) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(content: Text(personalPlanShareFailed)),
              );
            }
          },
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
