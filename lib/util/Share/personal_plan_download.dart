import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Share/personal_plan_share.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:meta/meta.dart';

@immutable
class _PersonalPlanDownloadContext {
  final String localeName;
  final String textDirection;
  final String gender;
  final String username;
  final int sharePdfTextsHashCode;
  final int? userInformationRevision;
  final FileService fileService;

  _PersonalPlanDownloadContext({
    required AppLocalizations appLocale,
    required this.gender,
    required this.username,
    required AppInformation appInformation,
    required this.fileService,
    UserInformation? userInformation,
  })  : localeName = appLocale.localeName,
        textDirection = appLocale.textDirection,
        sharePdfTextsHashCode = Object.hashAll(
          appInformation.sharePDFtexts.entries.map(
            (entry) => Object.hash(entry.key, entry.value),
          ),
        ),
        userInformationRevision = userInformation?.dreamsAndGoalsSaveRevision;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _PersonalPlanDownloadContext &&
        other.localeName == localeName &&
        other.textDirection == textDirection &&
        other.gender == gender &&
        other.username == username &&
        other.sharePdfTextsHashCode == sharePdfTextsHashCode &&
        other.userInformationRevision == userInformationRevision &&
        identical(other.fileService, fileService);
  }

  @override
  int get hashCode => Object.hash(
        localeName,
        textDirection,
        gender,
        username,
        sharePdfTextsHashCode,
        userInformationRevision,
        identityHashCode(fileService),
      );
}

final Map<_PersonalPlanDownloadContext, Future<String?>>
    _activePersonalPlanDownloads =
    <_PersonalPlanDownloadContext, Future<String?>>{};

/// Downloads the Personal Plan PDF export after stabilizing persistence state,
/// notifying the user of success or failure through standard toast feedback.
///
/// Preparation and download errors are caught, logged via [IncidentLoggerService],
/// and reported via the [AppLocalizations.downloadFailed] error toast.
/// User cancellation or unsupported platform outcomes return `null` without an error toast.
///
/// Concurrent requests with an identical immutable export context coalesce into a single
/// in-flight download operation to prevent duplicate file generations and repeated toasts,
/// while requests with different contexts execute independently.
Future<String?> downloadPersonalPlanFile({
  required AppLocalizations appLocale,
  required String gender,
  required String username,
  required AppInformation appInformation,
  required FileService fileService,
  UserInformation? userInformation,
}) async {
  final contextKey = _PersonalPlanDownloadContext(
    appLocale: appLocale,
    gender: gender,
    username: username,
    appInformation: appInformation,
    fileService: fileService,
    userInformation: userInformation,
  );

  final existingDownload = _activePersonalPlanDownloads[contextKey];
  if (existingDownload != null) {
    return await existingDownload;
  }

  final downloadFuture = _executeDownloadPersonalPlanFile(
    appLocale: appLocale,
    gender: gender,
    username: username,
    appInformation: appInformation,
    userInformation: userInformation,
    fileService: fileService,
  );

  _activePersonalPlanDownloads[contextKey] = downloadFuture;
  try {
    return await downloadFuture;
  } finally {
    if (identical(_activePersonalPlanDownloads[contextKey], downloadFuture)) {
      _activePersonalPlanDownloads.remove(contextKey);
    }
  }
}

Future<String?> _executeDownloadPersonalPlanFile({
  required AppLocalizations appLocale,
  required String gender,
  required String username,
  required AppInformation appInformation,
  required FileService fileService,
  UserInformation? userInformation,
}) async {
  try {
    final exportMetadata = await prepareAndBuildPersonalPlanExportMetadata(
      appLocale: appLocale,
      gender: gender,
      username: username,
      userInformation: userInformation,
    );
    final result = await fileService.download(
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
