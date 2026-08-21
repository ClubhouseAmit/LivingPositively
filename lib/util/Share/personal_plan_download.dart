import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Share/personal_plan_share.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';

/// Downloads the Personal Plan PDF export after stabilizing persistence state,
/// notifying the user of success or failure through standard toast feedback.
///
/// Preparation and download errors are caught, logged via [IncidentLoggerService],
/// and reported via the [AppLocalizations.downloadFailed] error toast.
/// User cancellation or unsupported platform outcomes return `null` without an error toast.
Future<String?> downloadPersonalPlanFile({
  required AppLocalizations appLocale,
  required String gender,
  required String username,
  required AppInformation appInformation,
  UserInformation? userInformation,
  FileService? fileService,
}) async {
  try {
    final exportMetadata = await prepareAndBuildPersonalPlanExportMetadata(
      appLocale: appLocale,
      gender: gender,
      username: username,
      userInformation: userInformation,
    );
    final service = fileService ?? GetIt.instance<FileService>();
    final result = await service.download(
      exportMetadata.titles,
      exportMetadata.subTitles,
      appInformation.sharePDFtexts,
      ShareFileType.PDF,
      mainTitle: exportMetadata.mainTitle,
      textDirection: appLocale.textDirection,
    );
    if (result != null) {
      await showToast(message: appLocale.finishedDownloading(gender));
    }
    return result;
  } catch (error, stackTrace) {
    try {
      if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
        await GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      }
    } catch (_) {}
    await showToast(message: appLocale.downloadFailed(gender));
    return null;
  }
}
