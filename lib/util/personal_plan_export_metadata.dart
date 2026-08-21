import 'package:get_it/get_it.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';

class PersonalPlanExportMetadata {
  const PersonalPlanExportMetadata({
    required this.titles,
    required this.subTitles,
    required this.mainTitle,
  });

  final List<String> titles;
  final List<String> subTitles;
  final String mainTitle;
}

PersonalPlanExportMetadata buildPersonalPlanExportMetadata(
  AppLocalizations appLocale,
  String gender,
  String username,
) {
  final mainTitle = username.trim().isEmpty
      ? appLocale.personalPlanPdfTitle
      : appLocale.personalPlanPdfTitleWithName(username);

  return PersonalPlanExportMetadata(
    titles: [
      appLocale.distractionsHeader(gender),
      appLocale.difficultEventsHeader(gender),
      appLocale.feelBetterHeader(gender),
      appLocale.makeSaferHeader(gender),
      appLocale.phonesPageHeader(gender),
      appLocale.safeEnvironmentHeader(gender),
      appLocale.dreamsAndGoalsHeader(gender),
    ],
    subTitles: [
      appLocale.distractionsSubTitle(gender),
      appLocale.difficultEventsSubTitle(gender),
      appLocale.feelBetterSubTitle(gender),
      appLocale.makeSaferSubTitle(gender),
      appLocale.phonesPageSubTitle(gender),
      appLocale.safeEnvironmentSubTitle(gender),
      appLocale.dreamsAndGoalsSubTitle(gender),
    ],
    mainTitle: mainTitle,
  );
}

/// Awaits all pending Dreams and Goals persistence writes and repairs selection
/// sources before a Personal Plan export reads data from local storage.
Future<void> preparePersonalPlanExport(UserInformation userInformation) {
  return userInformation.prepareForPersonalPlanExport();
}

/// Downloads the Personal Plan PDF export after stabilizing persistence state,
/// notifying the user of success or failure through standard toast feedback.
Future<void> downloadPersonalPlanFile({
  required AppLocalizations appLocale,
  required String gender,
  required String username,
  required AppInformation appInformation,
  required String textDirection,
  UserInformation? userInformation,
  FileService? fileService,
}) async {
  if (userInformation != null) {
    await preparePersonalPlanExport(userInformation);
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
    return;
  }
  showToast(message: appLocale.finishedDownloading(gender));
}
