import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:share_plus/share_plus.dart';

/// Prepares personal plan state by awaiting pending persistence writes when [userInformation]
/// is provided, and constructs the localized [PersonalPlanExportMetadata].
Future<PersonalPlanExportMetadata> prepareAndBuildPersonalPlanExportMetadata({
  required AppLocalizations appLocale,
  required String gender,
  required String username,
  UserInformation? userInformation,
}) async {
  if (userInformation != null) {
    await userInformation.prepareForPersonalPlanExport();
  }
  return buildPersonalPlanExportMetadata(
    appLocale,
    gender,
    username,
  );
}

/// Shares the Personal Plan PDF export with the given [message] after stabilizing persistence state.
///
/// When provided, [userInformation] triggers awaited personal-plan preparation.
/// [fileService] overrides the default [FileService] resolved from [GetIt].
///
/// Preparation, metadata, or sharing failures are caught, logged via [IncidentLoggerService],
/// and returned as `null` without throwing uncaught exceptions to callers.
Future<ShareResult?> sharePersonalPlanFile({
  required String message,
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
    return await service.share(
      message,
      exportMetadata.titles,
      exportMetadata.subTitles,
      appInformation.sharePDFtexts,
      ShareFileType.PDF,
      mainTitle: exportMetadata.mainTitle,
      textDirection: appLocale.textDirection,
      memoryService: userInformation?.service,
    );
  } catch (error, stackTrace) {
    try {
      if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
        await GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      }
    } catch (_) {}
    return null;
  }
}
