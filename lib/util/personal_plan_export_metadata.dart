import 'package:mazilon/l10n/app_localizations.dart';

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
    ],
    subTitles: [
      appLocale.distractionsSubTitle(gender),
      appLocale.difficultEventsSubTitle(gender),
      appLocale.feelBetterSubTitle(gender),
      appLocale.makeSaferSubTitle(gender),
      appLocale.phonesPageSubTitle(gender),
      appLocale.safeEnvironmentSubTitle(gender),
    ],
    mainTitle: mainTitle,
  );
}
