import 'package:mazilon/util/gender.dart';
import 'package:mazilon/l10n/app_localizations_ar.dart';
import 'package:mazilon/l10n/app_localizations_en.dart';
import 'package:mazilon/l10n/app_localizations_he.dart';

const String dreamsAndGoalsCustomSelectionSource = 'custom';
const String _dreamsAndGoalsCatalogueSelectionSourcePrefix = 'catalogue:';

/// Immutable ids for the ordered Dreams and Goals catalogue.
///
/// The localized labels may change, but the ids retain the selection identity
/// used by the Personal Plan form and its local persistence.
const List<String> dreamsAndGoalsCatalogueIds = <String>[
  'write-and-publish-a-book',
  'learn-a-new-language',
  'fly-in-a-hot-air-balloon',
  'run-a-marathon-or-half-marathon',
  'run-five-kilometers',
  'start-my-own-business',
  'learn-to-play-a-musical-instrument',
  'volunteer-regularly',
  'travel-to-my-dream-destination',
  'complete-a-degree-or-certificate',
  'forgive-someone-who-hurt-me',
  'buy-my-own-home',
  'give-a-talk-to-an-audience',
  'go-skydiving',
  'learn-to-surf',
  'adopt-a-pet',
  'start-a-podcast-or-blog',
  'plant-and-tend-my-own-garden',
  'get-a-motorcycle-or-boat-license',
  'get-a-drivers-license',
  'overcome-my-greatest-fear',
  'see-the-northern-lights',
  'start-or-grow-a-family',
  'develop-an-invention-or-app',
  'attend-a-vipassana-workshop-or-silent-retreat',
  'write-a-song-or-musical-piece',
  'organize-a-large-gathering',
  'learn-to-cook-a-gourmet-meal',
  'achieve-financial-independence',
  'exhibit-my-work',
  'donate-a-meaningful-amount',
  'get-angry-less-often',
  'find-a-romantic-relationship',
  'earn-more-money',
];

const List<String> _dreamsAndGoalsCatalogueGenders = <String>[
  'male',
  'female',
  'other',
];

String dreamsAndGoalsCatalogueSelectionSourceForIndex(int index) {
  return '$_dreamsAndGoalsCatalogueSelectionSourcePrefix'
      '${dreamsAndGoalsCatalogueIds[index]}';
}

bool isDreamsAndGoalsCatalogueSelectionSource(String source) {
  if (!source.startsWith(_dreamsAndGoalsCatalogueSelectionSourcePrefix)) {
    return false;
  }
  final id = source.substring(
    _dreamsAndGoalsCatalogueSelectionSourcePrefix.length,
  );
  return dreamsAndGoalsCatalogueIds.contains(id);
}

/// Returns the stable source token for a known localized catalogue label.
///
/// This is deliberately exact: a legacy own goal that happens to equal a
/// catalogue label cannot be distinguished after the fact and migrates as the
/// corresponding catalogue selection. New selections always retain their
/// explicit source token instead of relying on this lookup.
String? dreamsAndGoalsSelectionSourceForLocalizedText(String text) {
  final localizations = <dynamic>[
    AppLocalizationsEn(),
    AppLocalizationsHe(),
    AppLocalizationsAr(),
  ];

  for (final localization in localizations) {
    for (final gender in _dreamsAndGoalsCatalogueGenders) {
      final index = retrieveDreamsAndGoalsList(
        localization,
        gender,
      ).indexOf(text);
      if (index >= 0) {
        return dreamsAndGoalsCatalogueSelectionSourceForIndex(index);
      }
    }
  }
  return null;
}

/// Restores one source token per saved Dreams and Goals row.
///
/// Valid stored tokens remain authoritative so an explicitly custom value
/// equal to a catalogue label stays custom. Missing, malformed, or legacy
/// source entries are reconstructed from all supported localized catalogues.
List<String> normalizeDreamsAndGoalsSelectionSources(
  List<String> selectedItems,
  List<String> storedSources,
) {
  return List<String>.generate(selectedItems.length, (index) {
    if (index < storedSources.length) {
      final source = storedSources[index];
      if (source == dreamsAndGoalsCustomSelectionSource ||
          isDreamsAndGoalsCatalogueSelectionSource(source)) {
        return source;
      }
    }
    return dreamsAndGoalsSelectionSourceForLocalizedText(
          selectedItems[index],
        ) ??
        dreamsAndGoalsCustomSelectionSource;
  });
}

List<String> dreamsAndGoalsCustomItems(
  List<String> selectedItems,
  List<String> selectionSources,
) {
  final sources = normalizeDreamsAndGoalsSelectionSources(
    selectedItems,
    selectionSources,
  );
  return <String>[
    for (final (index, item) in selectedItems.indexed)
      if (sources[index] == dreamsAndGoalsCustomSelectionSource) item,
  ];
}

//this function is used in the form pages to get the correct information for each page
Map<String, dynamic> retrieveInformation(name, gender, textLocalization) {
  String header;
  String subTitle;
  String midTitle;
  String midSubTitle;
  String nextButtonText;
  String showMoreButtonText;
  List<String> list;

  switch (name) {
    case 'PersonalPlan-DifficultEvents':
      header = textLocalization.difficultEventsHeader(gender);
      subTitle = textLocalization.difficultEventsSubTitle(gender);
      midTitle = textLocalization.difficultEventsMidTitle(gender);
      midSubTitle = textLocalization.difficultEventsMidSubTitle(gender);
      list = retrieveDifficultEventsList(
        textLocalization,
        Gender.fromCode(gender).listKey,
      );

      break;
    case 'PersonalPlan-MakeSafer':
      header = textLocalization.makeSaferHeader(gender);
      subTitle = textLocalization.makeSaferSubTitle(gender);
      midTitle = textLocalization.makeSaferMidTitle(gender);
      midSubTitle = textLocalization.makeSaferMidSubTitle(gender);
      list = retrieveMakeSaferList(
        textLocalization,
        Gender.fromCode(gender).listKey,
      );

      break;
    case 'PersonalPlan-FeelBetter':
      header = textLocalization.feelBetterHeader(gender);
      subTitle = textLocalization.feelBetterSubTitle(gender);
      midTitle = textLocalization.feelBetterMidTitle(gender);
      midSubTitle = textLocalization.feelBetterMidSubTitle(gender);
      list = retrieveFeelBetterList(
        textLocalization,
        Gender.fromCode(gender).listKey,
      );

      break;
    case 'PersonalPlan-Distractions':
      header = textLocalization.distractionsHeader(gender);
      subTitle = textLocalization.distractionsSubTitle(gender);
      midTitle = textLocalization.distractionsMidTitle(gender);
      midSubTitle = textLocalization.distractionsMidSubTitle(gender);
      list = retrieveDistractionsList(
        textLocalization,
        Gender.fromCode(gender).listKey,
      );

      break;
    case 'PersonalPlan-SafeEnvironment':
      header = textLocalization.safeEnvironmentHeader(gender);
      subTitle = textLocalization.safeEnvironmentSubTitle(gender);
      midTitle = textLocalization.makeSaferMidTitle(gender);
      midSubTitle = textLocalization.makeSaferMidSubTitle(gender);
      list = retrieveSafeEnvironmentList(
        textLocalization,
        Gender.fromCode(gender).listKey,
      );

      break;
    case 'PersonalPlan-DreamsAndGoals':
      header = textLocalization.dreamsAndGoalsHeader(gender);
      subTitle = textLocalization.dreamsAndGoalsSubTitle(gender);
      midTitle = textLocalization.makeSaferMidTitle(gender);
      midSubTitle = textLocalization.makeSaferMidSubTitle(gender);
      list = retrieveDreamsAndGoalsList(
        textLocalization,
        Gender.fromCode(gender).listKey,
      );

      break;
    default:
      throw Exception('Invalid collection name');
  }
  nextButtonText = textLocalization.nextButton(gender);
  showMoreButtonText = textLocalization.otherSuggestions(gender);

  return {
    'header': header,
    'subTitle': subTitle,
    'midTitle': midTitle,
    'midSubTitle': midSubTitle,
    'nextButtonText': nextButtonText,
    'showMoreButtonText': showMoreButtonText,
    'list': list,
  };
}

List<String> retrieveInspirationalQuotes(localization, gender) {
  List<String> inspirationalQuotes = [];
  //debugPrint(gender);
  inspirationalQuotes.add(localization.inspirationalQuotesNo0(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo1(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo2(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo3(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo4(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo5(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo6(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo7(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo8(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo9(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo10(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo11(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo12(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo13(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo14(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo15(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo16(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo17(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo18(gender));
  inspirationalQuotes.add(localization.inspirationalQuotesNo19(gender));
  return inspirationalQuotes;
}

List<String> retrieveThanksList(localization, gender) {
  List<String> thanksList = [];
  thanksList.add(localization.thanksListNo0(gender));
  thanksList.add(localization.thanksListNo1(gender));
  thanksList.add(localization.thanksListNo2(gender));
  thanksList.add(localization.thanksListNo3(gender));
  thanksList.add(localization.thanksListNo4(gender));
  thanksList.add(localization.thanksListNo5(gender));
  thanksList.add(localization.thanksListNo6(gender));
  thanksList.add(localization.thanksListNo7(gender));
  thanksList.add(localization.thanksListNo8(gender));
  thanksList.add(localization.thanksListNo9(gender));
  thanksList.add(localization.thanksListNo10(gender));
  thanksList.add(localization.thanksListNo11(gender));
  return thanksList;
}

List<String> retrieveTraitsList(localization, gender) {
  List<String> traitsList = [];
  traitsList.add(localization.traitsListNo0(gender));
  traitsList.add(localization.traitsListNo1(gender));
  traitsList.add(localization.traitsListNo2(gender));
  traitsList.add(localization.traitsListNo3(gender));
  traitsList.add(localization.traitsListNo4(gender));
  traitsList.add(localization.traitsListNo5(gender));
  traitsList.add(localization.traitsListNo6(gender));
  traitsList.add(localization.traitsListNo7(gender));
  traitsList.add(localization.traitsListNo8(gender));
  traitsList.add(localization.traitsListNo9(gender));
  traitsList.add(localization.traitsListNo10(gender));
  traitsList.add(localization.traitsListNo12(gender));
  traitsList.add(localization.traitsListNo13(gender));
  traitsList.add(localization.traitsListNo14(gender));
  traitsList.add(localization.traitsListNo15(gender));
  traitsList.add(localization.traitsListNo16(gender));
  traitsList.add(localization.traitsListNo17(gender));
  traitsList.add(localization.traitsListNo18(gender));
  traitsList.add(localization.traitsListNo19(gender));
  traitsList.add(localization.traitsListNo20(gender));

  return traitsList;
}

List<String> retrieveDifficultEventsList(localization, gender) {
  List<String> difficultEventsList = [];
  difficultEventsList.add(localization.difficultEventsListNo0(gender));
  difficultEventsList.add(localization.difficultEventsListNo1(gender));
  difficultEventsList.add(localization.difficultEventsListNo2(gender));
  difficultEventsList.add(localization.difficultEventsListNo3(gender));
  difficultEventsList.add(localization.difficultEventsListNo4(gender));
  difficultEventsList.add(localization.difficultEventsListNo5(gender));
  difficultEventsList.add(localization.difficultEventsListNo6(gender));
  difficultEventsList.add(localization.difficultEventsListNo7(gender));
  difficultEventsList.add(localization.difficultEventsListNo8(gender));
  difficultEventsList.add(localization.difficultEventsListNo9(gender));
  difficultEventsList.add(localization.difficultEventsListNo10(gender));
  difficultEventsList.add(localization.difficultEventsListNo12(gender));
  difficultEventsList.add(localization.difficultEventsListNo13(gender));
  difficultEventsList.add(localization.difficultEventsListNo14(gender));
  difficultEventsList.add(localization.difficultEventsListNo15(gender));
  difficultEventsList.add(localization.difficultEventsListNo16(gender));
  difficultEventsList.add(localization.difficultEventsListNo17(gender));
  difficultEventsList.add(localization.difficultEventsListNo18(gender));
  difficultEventsList.add(localization.difficultEventsListNo19(gender));

  return difficultEventsList;
}

List<String> retrieveMakeSaferList(localization, gender) {
  List<String> makeSaferList = [];
  makeSaferList.add(localization.makeSaferListNo0(gender));
  makeSaferList.add(localization.makeSaferListNo1(gender));
  makeSaferList.add(localization.makeSaferListNo2(gender));
  makeSaferList.add(localization.makeSaferListNo3(gender));
  makeSaferList.add(localization.makeSaferListNo4(gender));
  makeSaferList.add(localization.makeSaferListNo5(gender));
  makeSaferList.add(localization.makeSaferListNo6(gender));
  makeSaferList.add(localization.makeSaferListNo7(gender));
  makeSaferList.add(localization.makeSaferListNo8(gender));
  makeSaferList.add(localization.makeSaferListNo9(gender));
  makeSaferList.add(localization.makeSaferListNo10(gender));
  makeSaferList.add(localization.makeSaferListNo12(gender));
  makeSaferList.add(localization.makeSaferListNo13(gender));
  makeSaferList.add(localization.makeSaferListNo14(gender));
  makeSaferList.add(localization.makeSaferListNo15(gender));
  makeSaferList.add(localization.makeSaferListNo16(gender));

  return makeSaferList;
}

List<String> retrieveFeelBetterList(localization, gender) {
  List<String> feelBetterList = [];
  feelBetterList.add(localization.feelBetterListNo0(gender));
  feelBetterList.add(localization.feelBetterListNo1(gender));
  feelBetterList.add(localization.feelBetterListNo2(gender));
  feelBetterList.add(localization.feelBetterListNo3(gender));
  feelBetterList.add(localization.feelBetterListNo4(gender));
  feelBetterList.add(localization.feelBetterListNo5(gender));
  feelBetterList.add(localization.feelBetterListNo6(gender));
  feelBetterList.add(localization.feelBetterListNo7(gender));
  feelBetterList.add(localization.feelBetterListNo8(gender));
  feelBetterList.add(localization.feelBetterListNo9(gender));
  feelBetterList.add(localization.feelBetterListNo10(gender));
  feelBetterList.add(localization.feelBetterListNo12(gender));
  feelBetterList.add(localization.feelBetterListNo13(gender));
  feelBetterList.add(localization.feelBetterListNo14(gender));
  feelBetterList.add(localization.feelBetterListNo15(gender));
  feelBetterList.add(localization.feelBetterListNo16(gender));
  feelBetterList.add(localization.feelBetterListNo17(gender));
  feelBetterList.add(localization.feelBetterListNo18(gender));
  feelBetterList.add(localization.feelBetterListNo19(gender));
  feelBetterList.add(localization.feelBetterListNo20(gender));

  return feelBetterList;
}

List<String> retrieveDistractionsList(localization, gender) {
  List<String> distractionsList = [];
  distractionsList.add(localization.distractionsListNo0(gender));
  distractionsList.add(localization.distractionsListNo1(gender));
  distractionsList.add(localization.distractionsListNo2(gender));
  distractionsList.add(localization.distractionsListNo3(gender));
  distractionsList.add(localization.distractionsListNo4(gender));
  distractionsList.add(localization.distractionsListNo5(gender));
  distractionsList.add(localization.distractionsListNo6(gender));
  distractionsList.add(localization.distractionsListNo7(gender));
  distractionsList.add(localization.distractionsListNo8(gender));
  distractionsList.add(localization.distractionsListNo9(gender));
  distractionsList.add(localization.distractionsListNo10(gender));
  distractionsList.add(localization.distractionsListNo12(gender));
  distractionsList.add(localization.distractionsListNo13(gender));
  distractionsList.add(localization.distractionsListNo14(gender));
  distractionsList.add(localization.distractionsListNo15(gender));
  distractionsList.add(localization.distractionsListNo16(gender));
  distractionsList.add(localization.distractionsListNo17(gender));
  distractionsList.add(localization.distractionsListNo18(gender));
  distractionsList.add(localization.distractionsListNo19(gender));
  distractionsList.add(localization.distractionsListNo20(gender));
  distractionsList.add(localization.distractionsListNo21(gender));
  distractionsList.add(localization.distractionsListNo22(gender));
  distractionsList.add(localization.distractionsListNo23(gender));
  distractionsList.add(localization.distractionsListNo24(gender));
  distractionsList.add(localization.distractionsListNo25(gender));
  distractionsList.add(localization.distractionsListNo26(gender));
  distractionsList.add(localization.distractionsListNo27(gender));
  distractionsList.add(localization.distractionsListNo28(gender));
  distractionsList.add(localization.distractionsListNo29(gender));
  distractionsList.add(localization.distractionsListNo30(gender));
  distractionsList.add(localization.distractionsListNo31(gender));
  distractionsList.add(localization.distractionsListNo32(gender));
  distractionsList.add(localization.distractionsListNo33(gender));

  return distractionsList;
}

List<String> retrieveSafeEnvironmentList(localization, gender) {
  return [
    localization.safeEnvironmentListNo0(gender),
    localization.safeEnvironmentListNo1(gender),
    localization.safeEnvironmentListNo2(gender),
    localization.safeEnvironmentListNo3(gender),
  ];
}

List<String> retrieveDreamsAndGoalsList(localization, gender) {
  return [
    localization.dreamsAndGoalsListNo0(gender),
    localization.dreamsAndGoalsListNo1(gender),
    localization.dreamsAndGoalsListNo2(gender),
    localization.dreamsAndGoalsListNo3(gender),
    localization.dreamsAndGoalsListNo4(gender),
    localization.dreamsAndGoalsListNo5(gender),
    localization.dreamsAndGoalsListNo6(gender),
    localization.dreamsAndGoalsListNo7(gender),
    localization.dreamsAndGoalsListNo8(gender),
    localization.dreamsAndGoalsListNo9(gender),
    localization.dreamsAndGoalsListNo10(gender),
    localization.dreamsAndGoalsListNo11(gender),
    localization.dreamsAndGoalsListNo12(gender),
    localization.dreamsAndGoalsListNo13(gender),
    localization.dreamsAndGoalsListNo14(gender),
    localization.dreamsAndGoalsListNo15(gender),
    localization.dreamsAndGoalsListNo16(gender),
    localization.dreamsAndGoalsListNo17(gender),
    localization.dreamsAndGoalsListNo18(gender),
    localization.dreamsAndGoalsListNo19(gender),
    localization.dreamsAndGoalsListNo20(gender),
    localization.dreamsAndGoalsListNo21(gender),
    localization.dreamsAndGoalsListNo22(gender),
    localization.dreamsAndGoalsListNo23(gender),
    localization.dreamsAndGoalsListNo24(gender),
    localization.dreamsAndGoalsListNo25(gender),
    localization.dreamsAndGoalsListNo26(gender),
    localization.dreamsAndGoalsListNo27(gender),
    localization.dreamsAndGoalsListNo28(gender),
    localization.dreamsAndGoalsListNo29(gender),
    localization.dreamsAndGoalsListNo30(gender),
    localization.dreamsAndGoalsListNo31(gender),
    localization.dreamsAndGoalsListNo32(gender),
    localization.dreamsAndGoalsListNo33(gender),
  ];
}
