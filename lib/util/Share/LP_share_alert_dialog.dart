import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';

import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/LP_extended_state.dart';
import 'package:mazilon/util/Share/LP_alert_dialog.dart';
import 'package:mazilon/util/Share/LP_alert_dialog_box_item.dart';
import 'package:mazilon/util/Share/personal_plan_share.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class LPShareAlertDialog extends StatefulWidget {
  const LPShareAlertDialog({super.key, this.memoryService});

  final PersistentMemoryService? memoryService;

  @override
  State<LPShareAlertDialog> createState() => _LPShareAlertDialogState();
}

/// Shares the Personal Plan PDF export with an empty message using [sharePersonalPlanFile].
///
/// [userInformation] is optional and triggers awaited personal-plan preparation when provided.
/// [fileService] is an injectable override with a [GetIt] fallback.
/// [memoryService] takes precedence over [UserInformation.service] and supplies
/// the persisted Personal Plan selections and custom categories used for the
/// PDF. When omitted, [UserInformation.service] is used.
/// Preparation, metadata, or sharing failures are caught, logged, and returned as `null`.
Future<ShareResult?> shareFile(
  AppLocalizations appLocale,
  String gender,
  String username,
  AppInformation appInfoProvider, {
  UserInformation? userInformation,
  FileService? fileService,
  PersistentMemoryService? memoryService,
}) {
  return sharePersonalPlanFile(
    message: "",
    appLocale: appLocale,
    gender: gender,
    username: username,
    appInformation: appInfoProvider,
    userInformation: userInformation,
    fileService: fileService,
    memoryService: memoryService,
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
              userInformation: userInfoProvider,
              fileService: fileService,
              memoryService: widget.memoryService,
            );
            if (!context.mounted) {
              return;
            }
            if (shareResult == null ||
                shareResult.status == ShareResultStatus.unavailable) {
              ScaffoldMessenger.maybeOf(
                context,
              )?.showSnackBar(SnackBar(content: Text(personalPlanShareFailed)));
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
