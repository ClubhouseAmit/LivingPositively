import 'package:mazilon/l10n/app_localizations.dart';

class PersonalPlanExportMetadata {
  const PersonalPlanExportMetadata({
    required this.titles,
    required this.subTitles,
  });

  final List<String> titles;
  final List<String> subTitles;
}

PersonalPlanExportMetadata buildPersonalPlanExportMetadata(
  AppLocalizations appLocale,
  String gender,
) {
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
  );
}
