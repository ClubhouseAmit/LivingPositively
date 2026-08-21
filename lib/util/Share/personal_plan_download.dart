import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';
import 'package:mazilon/util/userInformation.dart';

/// Downloads the Personal Plan PDF export after stabilizing persistence state,
/// notifying the user of success or failure through standard toast feedback.
///
/// Preparation and download failures are caught and reported via error toast
/// without leaking uncaught exceptions to UI callers.
Future<String?> downloadPersonalPlanFile({
  required AppLocalizations appLocale,
  required String gender,
  required String username,
  required AppInformation appInformation,
  required String textDirection,
  UserInformation? userInformation,
  FileService? fileService,
}) async {
  try {
    if (userInformation != null) {
      await userInformation.prepareForPersonalPlanExport();
    }
    final service = fileService ?? GetIt.instance<FileService>();
    final exportMetadata = buildPersonalPlanExportMetadata(
      appLocale,
      gender,
      username,
    );
    final result = await service.download(
      exportMetadata.titles,
      exportMetadata.subTitles,
      appInformation.sharePDFtexts,
      ShareFileType.PDF,
      mainTitle: exportMetadata.mainTitle,
      textDirection: textDirection,
    );
    if (result == null) {
      showToast(message: appLocale.downloadFailed(gender));
      return null;
    }
    showToast(message: appLocale.finishedDownloading(gender));
    return result;
  } catch (error, stackTrace) {
    showToast(message: appLocale.downloadFailed(gender));
    return null;
  }
}
