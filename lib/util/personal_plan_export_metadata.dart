import 'package:mazilon/l10n/app_localizations.dart';
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
