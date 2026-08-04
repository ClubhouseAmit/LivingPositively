import 'package:flutter/foundation.dart';

//this it the app's information class, with it we store and display it across the app.
//We update this information in firebase_functions.dart
class AppInformation with ChangeNotifier {
  String disclaimerText;
  String disclaimerNext;
  String reminderMainTitle;
  String reminderSubTitle;
  String homeTitleGreeting;
  Map<String, String> personalPlanMainTitle;
  Map<String, String> personalPlanSubTitle;
  Map<String, String> traitMainTitle;
  Map<String, String> traitSubTitle;
  Map<String, String> journalMainTitle;
  Map<String, String> journalSubTitle;
  Map<String, String> journalPopUpText;
  Map<String, String> positiveTraitsPopUpText;
  Map<String, String> popupBack;
  Map<String, String> othersuggestions;

  Map<String, String> aboutPageText;
  Map<String, String> returnToPlanStrings;
  Map<String, String> warningHomePageTitles;
  Map<String, String> traitsHomePageTitles;
  Map<String, String> introductionFormFirstPage;
  Map<String, String> introductionFormSecondPage;
  Map<String, String> introductionFormLastPage;
  Map<String, String> signUpLoginPage;
  Map<String, String> personalInformationForm;
  Map<String, List<String>> homePageInspirationalQuotes;
  Map<String, String> shareMessages;
  Map<String, String> sharePDFtexts;
  List<String> thanksSuggestionsList;
  List<String> phonePersonalPlanText;
  Map<String, String> extraMenuStrings;

  Map<String, List<String>>
      positiveTraitsSuggestionsList; //TODO PR: was List<String> before, pushed into main with mistake, didnt notice

  Map<String, String> formPhonePage;
  Map<String, List<String>> phonePageTitles;
  Map<String, String> formDifficultEventsTitles;
  Map<String, String> formDistractionsTitles;
  Map<String, String> formFeelBetterTitles;
  Map<String, String> formMakeSaferTitles;
  Map<String, String> formSharePageTitles;
  Map<String, String> formSkipButtonText;
  Map<String, String> feelGoodPageTitles;
  Map<String, String> syncPages;
  List<String> test1; //use for testing when stuff is not working

  DateTime? lastUpdated;
  String appVersion;

  List<String> DifficultEventsSug;
  List<String> DistractionsSug;
  List<String> FeelBetterSug;
  List<String> MakeSaferSug;
  Map<String, String> addFormStrings; //
  Map<String, String> addThanksFormStrings; //
  Map<String, String> addFormPageTemplateStrings;
  Map<String, String> IntroductionRestart;
  Map<String, List<String>> wellnessVideos;
  //add me here
  AppInformation({
    //add me here as well

    this.reminderMainTitle = '',
    this.reminderSubTitle = '',
    this.homeTitleGreeting = '',
    this.test1 = const [],
    this.returnToPlanStrings = const {},
    this.personalPlanMainTitle = const {},
    this.personalPlanSubTitle = const {},
    this.warningHomePageTitles = const {},
    this.traitsHomePageTitles = const {},
    this.traitMainTitle = const {},
    this.traitSubTitle = const {},
    this.journalMainTitle = const {},
    this.journalSubTitle = const {},
    this.personalInformationForm = const {},
    this.introductionFormFirstPage = const {},
    this.introductionFormSecondPage = const {},
    this.introductionFormLastPage = const {},
    this.homePageInspirationalQuotes = const {},
    this.lastUpdated,
    this.shareMessages = const {},
    this.thanksSuggestionsList = const [],
    this.phonePersonalPlanText = const [],
    this.positiveTraitsSuggestionsList = const {},
    this.journalPopUpText = const {},
    this.positiveTraitsPopUpText = const {},
    this.formPhonePage = const {},
    this.phonePageTitles = const {},
    this.formDifficultEventsTitles = const {},
    this.formDistractionsTitles = const {},
    this.formFeelBetterTitles = const {},
    this.formMakeSaferTitles = const {},
    this.formSharePageTitles = const {},
    this.appVersion = '',
    this.DifficultEventsSug = const [],
    this.DistractionsSug = const [],
    this.FeelBetterSug = const [],
    this.MakeSaferSug = const [],
    this.sharePDFtexts = const {},
    this.wellnessVideos = const {},
    this.aboutPageText = const {},
    this.disclaimerText = '',
    this.disclaimerNext = '',
    this.formSkipButtonText = const {},
    this.feelGoodPageTitles = const {},
    this.extraMenuStrings = const {},
    this.syncPages = const {},
    this.popupBack = const {},
    this.signUpLoginPage = const {},
    this.addFormStrings = const {}, //
    this.addThanksFormStrings = const {}, //
    this.addFormPageTemplateStrings = const {}, //
    this.IntroductionRestart = const {},
    this.othersuggestions = const {}, //
  });

  void updateReminderMainTitle(String title) {
    reminderMainTitle = title;
    notifyListeners();
  }

  void updateReminderSubTitle(String subTitle) {
    reminderSubTitle = subTitle;
    notifyListeners();
  }

  void updateHomeTitleGreeting(String greeting) {
    homeTitleGreeting = greeting;
    notifyListeners();
  }

  void updatePersonalPlanMainTitle(Map<String, String> title) {
    personalPlanMainTitle = {...title};
    notifyListeners();
  }

  void updatePersonalPlanSubTitle(Map<String, String> subTitle) {
    personalPlanSubTitle = {...subTitle};
    notifyListeners();
  }

  void updateTraitMainTitle(Map<String, String> title) {
    traitMainTitle = {...title};
    notifyListeners();
  }

  void updateTraitSubTitle(Map<String, String> subTitle) {
    traitSubTitle = {...subTitle};
    notifyListeners();
  }

  void updateJournalMainTitle(Map<String, String> title) {
    journalMainTitle = {...title};
    notifyListeners();
  }

  void updateJournalSubTitle(Map<String, String> subTitle) {
    journalSubTitle = {...subTitle};
    notifyListeners();
  }

  void updateReturnToPlanStrings(Map<String, String> strings) {
    returnToPlanStrings = strings;
    notifyListeners();
  }

  void updateWarningHomePageTitles(Map<String, String> titles) {
    warningHomePageTitles = titles;
    notifyListeners();
  }

  void updateTraitsHomePageTitles(Map<String, String> titles) {
    traitsHomePageTitles = titles;
    notifyListeners();
  }

  void updateIntroductionFormFirstPage(Map<String, String> form) {
    introductionFormFirstPage = form;
    notifyListeners();
  }

  void updateIntroductionFormSecondPage(Map<String, String> form) {
    introductionFormSecondPage = form;
    notifyListeners();
  }

  void updateIntroductionFormLastPage(Map<String, String> form) {
    introductionFormLastPage = form;
    notifyListeners();
  }

  void updatePersonalInformationForm(Map<String, String> form) {
    personalInformationForm = form;
    notifyListeners();
  }

  void updateLastUpdated(DateTime date) {
    lastUpdated = date;
    notifyListeners();
  }

  void updateHomePageInspirationalQuotes(Map<String, List<String>> quotes) {
    homePageInspirationalQuotes = quotes;
    notifyListeners();
  }

  void updateTest1(List<String> test) {
    test1 = [...test];
    notifyListeners();
  }

  void updateShareMessages(Map<String, String> messages) {
    shareMessages = messages;
    notifyListeners();
  }

  void updateThanksSuggestionsList(List<String> suggestions) {
    thanksSuggestionsList = [...suggestions];
    notifyListeners();
  }

  void updatePositiveTraitsSuggestionsList(
      Map<String, List<String>> suggestions) {
    positiveTraitsSuggestionsList = {...suggestions};
    notifyListeners();
  }

  void updateJournalPopUpText(Map<String, String> text) {
    journalPopUpText = {...text};
    notifyListeners();
  }

  void updatePositiveTraitsPopUpText(Map<String, String> text) {
    positiveTraitsPopUpText = {...text};
    notifyListeners();
  }

  void updateFormPhonePage(Map<String, String> form) {
    formPhonePage = form;
    notifyListeners();
  }

  void updatePhonePageTitles(Map<String, List<String>> titles) {
    phonePageTitles = titles;
    notifyListeners();
  }

  void updateFormDifficultEventsTitles(Map<String, String> titles) {
    formDifficultEventsTitles = titles;
    notifyListeners();
  }

  void updateFormDistractionsTitles(Map<String, String> titles) {
    formDistractionsTitles = titles;
    notifyListeners();
  }

  void updateFormFeelBetterTitles(Map<String, String> titles) {
    formFeelBetterTitles = titles;
    notifyListeners();
  }

  void updateFormMakeSaferTitles(Map<String, String> titles) {
    formMakeSaferTitles = titles;
    notifyListeners();
  }

  void updateFormSharePageTitles(Map<String, String> titles) {
    formSharePageTitles = {...titles};

    notifyListeners();
  }

  void updatePhonePersonalPlanText(texts) {
    phonePersonalPlanText = [...texts];
    notifyListeners();
  }

  void updateAppVersion(String version) {
    appVersion = version;
    notifyListeners();
  }

  void updateDifficultEventsSug(List<String> sug) {
    DifficultEventsSug = [...sug];
    notifyListeners();
  }

  void updateDistractionsSug(List<String> sug) {
    DistractionsSug = [...sug];
    notifyListeners();
  }

  void updateFeelBetterSug(List<String> sug) {
    FeelBetterSug = [...sug];
    notifyListeners();
  }

  void updateMakeSaferSug(List<String> sug) {
    MakeSaferSug = [...sug];
    notifyListeners();
  }

  void updateSharePDFtexts(Map<String, String> texts) {
    sharePDFtexts = {...texts};
    notifyListeners();
  }

  void updateWellnessVideos(Map<String, List<String>> videos) {
    wellnessVideos = {...videos};
    notifyListeners();
  }

  void updateAboutPageText(Map<String, String> texts) {
    aboutPageText = {...texts};
    notifyListeners();
  }

  void updateDisclaimerPageText(String text) {
    disclaimerText = text;
    notifyListeners();
  }

  void updateDisclaimerPageNext(String text) {
    disclaimerNext = text;
    notifyListeners();
  }

  void updateFormSkipButtonText(Map<String, String> text) {
    formSkipButtonText = {...text};
    notifyListeners();
  }

  void updateFeelGoodPageTitles(Map<String, String> text) {
    feelGoodPageTitles = {...text};
    notifyListeners();
  }

  void updateExtraMenuStrings(Map<String, String> text) {
    extraMenuStrings = {...text};
    notifyListeners();
  }

  void updateSyncPages(Map<String, String> text) {
    syncPages = {...text};
    notifyListeners();
  }

  void updatePopupBack(Map<String, String> text) {
    popupBack = {...text};
    notifyListeners();
  }

  void updateSignUpLoginPage(Map<String, String> text) {
    signUpLoginPage = {...text};
    notifyListeners();
  }

  void updateAddFormStrings(Map<String, String> text) {
    //
    addFormStrings = {...text};
    notifyListeners();
  }

  void updateAddThanksFormStrings(Map<String, String> text) {
    //
    addThanksFormStrings = {...text};
    notifyListeners();
  }

  void updateAddFormPageTemplateStrings(Map<String, String> text) {
    addFormPageTemplateStrings = {...text};
    notifyListeners();
  }

  void updateIntroductionRestart(Map<String, String> text) {
    IntroductionRestart = {...text};
    notifyListeners();
  }

  void updateOtherSuggestions(Map<String, String> title) {
    othersuggestions = {...title};
    notifyListeners();
  }

  //add me here
}
