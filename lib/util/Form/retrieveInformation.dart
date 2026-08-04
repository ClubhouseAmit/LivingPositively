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
          textLocalization, gender == "" ? "other" : gender);

      break;
    case 'PersonalPlan-MakeSafer':
      header = textLocalization.makeSaferHeader(gender);
      subTitle = textLocalization.makeSaferSubTitle(gender);
      midTitle = textLocalization.makeSaferMidTitle(gender);
      midSubTitle = textLocalization.makeSaferMidSubTitle(gender);
      list = retrieveMakeSaferList(
          textLocalization, gender == "" ? "other" : gender);

      break;
    case 'PersonalPlan-FeelBetter':
      header = textLocalization.feelBetterHeader(gender);
      subTitle = textLocalization.feelBetterSubTitle(gender);
      midTitle = textLocalization.feelBetterMidTitle(gender);
      midSubTitle = textLocalization.feelBetterMidSubTitle(gender);
      list = retrieveFeelBetterList(
          textLocalization, gender == "" ? "other" : gender);

      break;
    case 'PersonalPlan-Distractions':
      header = textLocalization.distractionsHeader(gender);
      subTitle = textLocalization.distractionsSubTitle(gender);
      midTitle = textLocalization.distractionsMidTitle(gender);
      midSubTitle = textLocalization.distractionsMidSubTitle(gender);
      list = retrieveDistractionsList(
          textLocalization, gender == "" ? "other" : gender);

      break;
    default:
      throw Exception('Invalid collection name');
  }
  nextButtonText = textLocalization.nextButton(gender);
  showMoreButtonText = textLocalization.showMoreButton(gender);

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
