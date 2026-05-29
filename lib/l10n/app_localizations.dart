import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('he'),
  ];

  /// The Current Language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// direction of the text
  ///
  /// In en, this message translates to:
  /// **'ltr'**
  String get textDirection;

  /// testing gender
  ///
  /// In en, this message translates to:
  /// **'{gender, select, male {Hi man!} female {Hi woman!} other {Hi there!}}'**
  String pageHomeWelcomeGender(String gender);

  /// a greeting message
  ///
  /// In en, this message translates to:
  /// **'Welcome, {username}'**
  String greetings(Object username);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{other suggestions} female{other suggestions} other{other suggestions}}'**
  String otherSuggestions(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Welcome to Living Positively} female{Welcome to Living Positively} other{Welcome to Living Positively}}'**
  String introductionRestartGreeting(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Add} female{Add} other{Add}}'**
  String addFormPageTemplateAdd(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thanks} female{Thanks} other{Thanks}}'**
  String addThanksFormThank(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Edit} female{Edit} other{Edit}}'**
  String addFormEdit(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Login to Living Positively} female{Login to Living Positively} other{Login to Living Positively}}'**
  String signupLoginLoginTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Login} female{Login} other{Login}}'**
  String signupLoginLoginButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Login using Google} female{Login using Google} other{Login using Google}}'**
  String signupLoginLoginGoogleButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Don\'t have an account yet?} female{Don\'t have an account yet?} other{Don\'t have an account yet?}}'**
  String signupLoginLoginNoAccount(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Signup} female{Signup} other{Signup}}'**
  String signupLoginLoginToSignup(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Skip Signup} female{Skip Signup} other{Skip Signup}}'**
  String signupLoginLoginSkip(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Signup to Living Positively} female{Signup to Living Positively} other{Signup to Living Positively}}'**
  String signupLoginSignUpTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Signup} female{Signup} other{Signup}}'**
  String signupLoginSignUpButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Already have an account?} female{Already have an account?} other{Already have an account?}}'**
  String signupLoginSignUpExists(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Login} female{Login} other{Login}}'**
  String signupLoginSignUpToLogin(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{My Plan} female{My Plan} other{My Plan}}'**
  String personalPlanPageMyPlan(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To see My Plan} female{To see My Plan} other{To see My Plan}}'**
  String personalPlanPageAllPlan(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{My Personal Plan} female{My Personal Plan} other{My Personal Plan}}'**
  String personalPlanPageTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Started downloading} female{Started downloading} other{Started downloading}}'**
  String personalPlanPageStartedDownload(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Your plan was saved to \"Downloads\"} female{Your plan was saved to \"Downloads\"} other{Your plan was saved to \"Downloads\"}}'**
  String personalPlanPageFinishDownload(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Finish} female{Finish} other{Finish}}'**
  String personalPlanPageFinish(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To update the plan} female{To update the plan} other{To update the plan}}'**
  String personalPlanPageHasFilled(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To fill the plan} female{To fill the plan} other{To fill the plan}}'**
  String personalPlanPageDidNotFill(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{My Plan} female{My Plan} other{My Plan}}'**
  String homePagePersonalPlanMainTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Things that will make me feel better now} female{Things that will make me feel better now} other{Things that will make me feel better now}}'**
  String homePagePersonalPlanSecondaryTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Qualities List} female{Qualities List} other{Qualities List}}'**
  String homePageTraitsMainTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{What I\'m good at, recommended to read once a day} female{What I\'m good at, recommended to read once a day} other{What I\'m good at, recommended to read once a day}}'**
  String homePageTraitsSecondaryTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Gratitude Journal} female{Gratitude Journal} other{Gratitude Journal}}'**
  String homePageThanksMainTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{What I\'m thankful for} female{What I\'m thankful for} other{What I\'m thankful for}}'**
  String homePageThanksSecondaryTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{This is how to strengthen your positive happiness muscle.\nThe recommendation is to be thankful for at least 5 things every day.\nKeep up the good work, and we’ll meet again tomorrow.} female{This is how to strengthen your positive happiness muscle.\nThe recommendation is to be thankful for at least 5 things every day.\nKeep up the good work, and we’ll meet again tomorrow.} other{This is how to strengthen your positive happiness muscle.\nThe recommendation is to be thankful for at least 5 things every day.\nKeep up the good work, and we’ll meet again tomorrow.}}'**
  String homePageThankyouPopup(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Check out your list of virtues everyday.\nFeel free to add more, don’t be shy - add more with a full heart.} female{Check out your list of virtues everyday.\nFeel free to add more, don’t be shy - add more with a full heart.} other{Check out your list of virtues everyday.\nFeel free to add more, don’t be shy - add more with a full heart.}}'**
  String homePagePositiveTraitPopup(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{It\'s good to have you back :)} female{It\'s good to have you back :)} other{It\'s good to have you back :)}}'**
  String homePageGreetings(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{About} female{About} other{About}}'**
  String homePageAbout(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Wellness Tools} female{Wellness Tools} other{Wellness Tools}}'**
  String homePageWellnessTools(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Feel Good} female{Feel Good} other{Feel Good}}'**
  String homePageFeelGood(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Sync Accounts} female{Sync Accounts} other{Sync Accounts}}'**
  String homePageSync(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Close} female{Close} other{Close}}'**
  String homePageBack(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Great!} female{Great!} other{Great!}}'**
  String sharePageHeader(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{You\'ve created a guide that will help you during moments of crisis!\nLet\'s explore more tools for self-help and mental resilience} female{You\'ve created a guide that will help you during moments of crisis!\nLet\'s explore more tools for self-help and mental resilience} other{You\'ve created a guide that will help you during moments of crisis!\nLet\'s explore more tools for self-help and mental resilience}}'**
  String sharePageSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Now you can share your plan with the people close to you, or download it to your phone} female{Now you can share your plan with the people close to you, or download it to your phone} other{Now you can share your plan with the people close to you, or download it to your phone}}'**
  String sharePageMidTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'m Done!} female{I\'m Done!} other{I\'m Done!}}'**
  String sharePageFinishButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'+ Add a custom category'**
  String get sharePageAddCustomCategory;

  ///
  ///
  /// In en, this message translates to:
  /// **'Category Title'**
  String get sharePageCustomCategoryTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sharePageCustomCategoryDescription;

  ///
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get sharePageSaveCustomCategory;

  ///
  ///
  /// In en, this message translates to:
  /// **'Empowering quotes important to remember'**
  String get customCategoryOptionEmpoweringQuotes;

  ///
  ///
  /// In en, this message translates to:
  /// **'Past events to remember'**
  String get customCategoryOptionPastEvents;

  ///
  ///
  /// In en, this message translates to:
  /// **'Things about me important to remember'**
  String get customCategoryOptionAboutMe;

  ///
  ///
  /// In en, this message translates to:
  /// **'Custom Input...'**
  String get customCategoryOptionCustomInput;

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{How would you like to share your plan?} female{How would you like to share your plan?} other{How would you like to share your plan?}}'**
  String sharePageShareTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Emergency} female{Emergency} other{Emergency}}'**
  String sharePageEmergencySendButtonText(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Routine} female{Routine} other{Routine}}'**
  String sharePageRoutineSendButtonText(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Update Settings} female{Update Settings} other{Update Settings}}'**
  String userSettingsTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{User Settings} female{User Settings} other{User Settings}}'**
  String userSettingsHeader(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Reset Data} female{Reset Data} other{Reset Data}}'**
  String userSettingsReset(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{What should we call you?(feel free to use a nickname)} female{What should we call you?(feel free to use a nickname)} other{What should we call you?(feel free to use a nickname)}}'**
  String userSettingsName(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{How would you prefer to be called?} female{How would you prefer to be called?} other{How would you prefer to be called?}}'**
  String userSettingsGender(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{What is your age?} female{What is your age?} other{What is your age?}}'**
  String userSettingsAge(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Settings} female{Settings} other{Settings}}'**
  String settings(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{What keeps me safe?} female{What keeps me safe?} other{What keeps me safe?}}'**
  String introductionFormFirstPageMainTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Living Positively - for happiness, increasing resilience, and improving quality of life} female{Living Positively - for happiness, increasing resilience, and improving quality of life} other{Living Positively - for happiness, increasing resilience, and improving quality of life}}'**
  String introductionFormFirstPageSubTitle1(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Excellent tools for self-help and developing mental resilience.} female{Excellent tools for self-help and developing mental resilience.} other{Excellent tools for self-help and developing mental resilience.}}'**
  String introductionFormFirstPageSubTitle2(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Skip} female{Skip} other{Skip}}'**
  String introductionFormFirstPageSkip(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Skip the Questionnaire} female{Skip the Questionnaire} other{Skip the Questionnaire}}'**
  String introductionFormLastPageSkip(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{My Personal Plan} female{My Personal Plan} other{My Personal Plan}}'**
  String introductionFormLastPageMainTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{You\'re invited to create a personal plan that offers support during overwhelming moments, for both you and those around you.} female{You\'re invited to create a personal plan that offers support during overwhelming moments, for both you and those around you.} other{You\'re invited to create a personal plan that offers support during overwhelming moments, for both you and those around you.}}'**
  String introductionFormLastPageSubTitle1(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{It\'s recommended to spend a few minutes now to better handle future crises.} female{It\'s recommended to spend a few minutes now to better handle future crises.} other{It\'s recommended to spend a few minutes now to better handle future crises.}}'**
  String introductionFormLastPageSubTitle2(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Let\'s get to know you!} female{Let\'s get to know you!} other{Let\'s get to know you!}}'**
  String introductionFormSecondPageMainTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Hi! So good you’re here!\nWe want to get to know you better so we can support you.} female{Hi! So good you’re here!\nWe want to get to know you better so we can support you.} other{Hi! So good you’re here!\nWe want to get to know you better so we can support you.}}'**
  String introductionFormSecondPageSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Reminders of common triggers and escalation factors} female{Reminders of common triggers and escalation factors} other{Reminders of common triggers and escalation factors}}'**
  String difficultEventsHeader(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Factors and events that have been challenging for me in the past} female{Factors and events that have been challenging for me in the past} other{Factors and events that have been challenging for me in the past}}'**
  String difficultEventsSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{No idea? Here are some suggestions} female{No idea? Here are some suggestions} other{No idea? Here are some suggestions}}'**
  String difficultEventsMidTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Click to add options that suit your personal plan} female{Click to add options that suit your personal plan} other{Click to add options that suit your personal plan}}'**
  String difficultEventsMidSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Symptoms and warning signs, unusual behaviors for me} female{Symptoms and warning signs, unusual behaviors for me} other{Symptoms and warning signs, unusual behaviors for me}}'**
  String distractionsHeader(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Reminders of things that have appeared personally for me in the past} female{Reminders of things that have appeared personally for me in the past} other{Reminders of things that have appeared personally for me in the past}}'**
  String distractionsSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{No idea? Here are some suggestions} female{No idea? Here are some suggestions} other{No idea? Here are some suggestions}}'**
  String distractionsMidTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Click to add options to suit your personal plan} female{Click to add options to suit your personal plan} other{Click to add options to suit your personal plan}}'**
  String distractionsMidSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{For balance and a healthy lifestyle - Wellness Tools - Personal Medications} female{For balance and a healthy lifestyle - Wellness Tools - Personal Medications} other{For balance and a healthy lifestyle - Wellness Tools - Personal Medications}}'**
  String feelBetterHeader(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{What helps me improve my mood, relax and feel less stressed?\nMethods for preventative maintenance, and even increase dosages - in emergency situations.} female{What helps me improve my mood, relax and feel less stressed?\nMethods for preventative maintenance, and even increase dosages - in emergency situations.} other{What helps me improve my mood, relax and feel less stressed?\nMethods for preventative maintenance, and even increase dosages - in emergency situations.}}'**
  String feelBetterSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{No idea? Here are some suggestions} female{No idea? Here are some suggestions} other{No idea? Here are some suggestions}}'**
  String feelBetterMidTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Click to add options to suit your personal plan} female{Click to add options to suit your personal plan} other{Click to add options to suit your personal plan}}'**
  String feelBetterMidSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Support from my environment when I notice early warning signs, and how I’d like to be assisted} female{Support from my environment when I notice early warning signs, and how I’d like to be assisted} other{Support from my environment when I notice early warning signs, and how I’d like to be assisted}}'**
  String makeSaferHeader(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Ways my surroundings can help me cope} female{Ways my surroundings can help me cope} other{Ways my surroundings can help me cope}}'**
  String makeSaferSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{No idea? Here are some suggestions} female{No idea? Here are some suggestions} other{No idea? Here are some suggestions}}'**
  String makeSaferMidTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Click to add options to suit your personal plan} female{Click to add options to suit your personal plan} other{Click to add options to suit your personal plan}}'**
  String makeSaferMidSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Phone} female{Phone} other{Phone}}'**
  String phonesPagePhone(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Name} female{Name} other{Name}}'**
  String phonesPageName(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Who are the people that support me, who I can turn to if I am distressed or thinking of harming myself?} female{Who are the people that support me, who I can turn to if I am distressed or thinking of harming myself?} other{Who are the people that support me, who I can turn to if I am distressed or thinking of harming myself?}}'**
  String phonesPageHeader(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{The people who love me and will help me get through the tough moments are:} female{The people who love me and will help me get through the tough moments are:} other{The people who love me and will help me get through the tough moments are:}}'**
  String phonesPageSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Add manually} female{Add manually} other{Add manually}}'**
  String phonesPageManualTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Add from contacts list} female{Add from contacts list} other{Add from contacts list}}'**
  String phonesPageContactImportTitle(String gender);

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Save} female{Save} other{Save}}'**
  String saveButton(String gender);

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Cancel} female{Cancel} other{Cancel}}'**
  String closeButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Continue} female{Continue} other{Continue}}'**
  String nextButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Show more} female{Show more} other{Show more}}'**
  String showMoreButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To the Questionnaire} female{To the Questionnaire} other{To the Questionnaire}}'**
  String introductionFormLastPageNext(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To menu} female{To menu} other{To menu}}'**
  String saveAndQuitButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Confirm} female{Confirm} other{Confirm}}'**
  String confirmButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Delete} female{Delete} other{Delete}}'**
  String deleteButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Menu} female{Menu} other{Menu}}'**
  String menu(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Reminders} female{Reminders} other{Reminders}}'**
  String notifications(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Home} female{Home} other{Home}}'**
  String home(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Skip} female{Skip} other{Skip}}'**
  String skipButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Select} female{Select} other{Select}}'**
  String select(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Go back} female{Go back} other{Go back}}'**
  String backButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Call} female{Call} other{Call}}'**
  String dialButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Your contacts} female{Your contacts} other{Your contacts}}'**
  String yourContacts(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Emergency Numbers} female{Emergency Numbers} other{Emergency Numbers}}'**
  String emergencyNumbers(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{You are not alone! If you are in distress right now, please reach out to one of the contacts listed here} female{You are not alone! If you are in distress right now, please reach out to one of the contacts listed here} other{You are not alone! If you are in distress right now, please reach out to one of the contacts listed here}}'**
  String phonePageTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  ///
  ///
  /// In en, this message translates to:
  /// **'thanks'**
  String get thanks;

  ///
  ///
  /// In en, this message translates to:
  /// **'trait'**
  String get trait;

  ///
  ///
  /// In en, this message translates to:
  /// **'Link to site'**
  String get link;

  ///
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  ///
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @addImageButton.
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Add Image} female{Add Image} other{Add Image}}'**
  String addImageButton(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Where to add from} female{Where to add from} other{Where to add from}}'**
  String addImageTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Encouraging and uplifting images} female{Encouraging and uplifting images} other{Encouraging and uplifting images}}'**
  String feelGoodTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{It is recommended to add encouraging, uplifting, and joyful images. Smiling pictures of family, friends, hobbies, successful trips, and more} female{It is recommended to add encouraging, uplifting, and joyful images. Smiling pictures of family, friends, hobbies, successful trips, and more} other{It is recommended to add encouraging, uplifting, and joyful images. Smiling pictures of family, friends, hobbies, successful trips, and more}}'**
  String feelGoodSubTitle(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @notWillingToSay.
  ///
  /// In en, this message translates to:
  /// **'Not interested sharing'**
  String get notWillingToSay;

  ///
  ///
  /// In en, this message translates to:
  /// **'Permission not granted'**
  String get noPermissionAllowedText;

  ///
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  ///
  ///
  /// In en, this message translates to:
  /// **'Non binary'**
  String get nonBinary;

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Show all} female{Show all} other{Show all}}'**
  String showAll(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Add a reminder to use Living Positively} female{Add a reminder to use Living Positively} other{Add a reminder to use Living Positively}}'**
  String notificationPageHeader(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Schedule a reminder for the selected time} female{Schedule a reminder for the selected time} other{Schedule a reminder for the selected time}}'**
  String notificationSetTimeText(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Show an example reminder} female{Show an example reminder} other{Show an example reminder}}'**
  String notificationShowExampleNotification(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Cancel current notification} female{Cancel current notification} other{Cancel current notification}}'**
  String notificationCancelNotification(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{finishedDownloading} female{finishedDownloading} other{finishedDownloading}}'**
  String finishedDownloading(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{download failed} female{download failed} other{download failed}}'**
  String downloadFailed(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Select language} female{Select language} other{Select language}}'**
  String selectLanguage(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'Field cannot be empty'**
  String get validateEmpty;

  ///
  ///
  /// In en, this message translates to:
  /// **'More videos'**
  String get moreVideos;

  ///
  ///
  /// In en, this message translates to:
  /// **'No videos available for your locale, sorry.'**
  String get noVideosAvailableForLocale;

  ///
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get confirmResetTitle;

  ///
  ///
  /// In en, this message translates to:
  /// **'Here is my personal plan that is meant to help keep me safe. I’m sending it to you because, in my view, you also have a part in it. I hope this works for you. I would greatly appreciate your agreement to take part in it if needed. Many thanks in advance, and I look forward to your reply.'**
  String get shareRoutineMessage;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share Options'**
  String get shareOptions;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share file of personal plan'**
  String get shareFile;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share text to involve supporters'**
  String get shareRoutine;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share text in case of crises'**
  String get shareEmergency;

  ///
  ///
  /// In en, this message translates to:
  /// **'I’m not doing well and I need help. I would appreciate your support in activating my personal plan. Thank you in advance.'**
  String get shareEmergencyMessage;

  ///
  ///
  /// In en, this message translates to:
  /// **'Information Collected:\n\nThe application only collects anonymous and statistical data for the purpose of analysis and service improvement. This data cannot identify any individual user. Among the data collected:\n• General app usage data (e.g., pages viewed, frequency of use).\n• Technical information about the device and system (Device type, OS version).\n• Anonymous location data – collected solely for analyzing trends and usage patterns, without linking to any identifiable user.\n'**
  String get informationCollectionDisclaimer;

  ///
  ///
  /// In en, this message translates to:
  /// **'We do not save your contacts, it is for your own use.'**
  String get addingContactDisclaimer;

  /// message
  ///
  /// In en, this message translates to:
  /// **'Reminder set for {time}'**
  String notifyOnscheduledNotification(Object time);

  ///
  ///
  /// In en, this message translates to:
  /// **'New {item}'**
  String newTraitOrThanks(Object item);

  /// No description provided for @todoListName.
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Gratitude Journal} female{Gratitude Journal} other{Gratitude Journal}}'**
  String todoListName(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{What will help me now, even small steps are progress} female{What will help me now, even small steps are progress} other{What will help me now, even small steps are progress}}'**
  String inspirationalQuotesNo0(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I have strengths} female{I have strengths} other{I have strengths}}'**
  String inspirationalQuotesNo1(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'ve already faced challenges in the past} female{I\'ve already faced challenges in the past} other{I\'ve already faced challenges in the past}}'**
  String inspirationalQuotesNo2(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Mood changes like the weather, which is not constant} female{Mood changes like the weather, which is not constant} other{Mood changes like the weather, which is not constant}}'**
  String inspirationalQuotesNo3(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Emotions are fleeting and change} female{Emotions are fleeting and change} other{Emotions are fleeting and change}}'**
  String inspirationalQuotesNo4(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am able} female{I am able} other{I am able}}'**
  String inspirationalQuotesNo5(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I have strength} female{I have strength} other{I have strength}}'**
  String inspirationalQuotesNo6(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'m learning to relax} female{I\'m learning to relax} other{I\'m learning to relax}}'**
  String inspirationalQuotesNo7(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{After the declines come the ascents} female{After the declines come the ascents} other{After the declines come the ascents}}'**
  String inspirationalQuotesNo8(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{It\'s okay to cry} female{It\'s okay to cry} other{It\'s okay to cry}}'**
  String inspirationalQuotesNo9(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thanks for the help} female{Thanks for the help} other{Thanks for the help}}'**
  String inspirationalQuotesNo10(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Take a moment to smile} female{Take a moment to smile} other{Take a moment to smile}}'**
  String inspirationalQuotesNo11(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Remember to breathe} female{Remember to breathe} other{Remember to breathe}}'**
  String inspirationalQuotesNo12(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Routine creates stability} female{Routine creates stability} other{Routine creates stability}}'**
  String inspirationalQuotesNo13(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Movement releases tension} female{Movement releases tension} other{Movement releases tension}}'**
  String inspirationalQuotesNo14(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{It\'s okay to ask for help} female{It\'s okay to ask for help} other{It\'s okay to ask for help}}'**
  String inspirationalQuotesNo15(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{It\'s okay not to be okay} female{It\'s okay not to be okay} other{It\'s okay not to be okay}}'**
  String inspirationalQuotesNo16(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Keep the pace that is right for you} female{Keep the pace that is right for you} other{Keep the pace that is right for you}}'**
  String inspirationalQuotesNo17(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{What gives you the strength to continue?} female{What gives you the strength to continue?} other{What gives you the strength to continue?}}'**
  String inspirationalQuotesNo18(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am capable of overcoming my challenges} female{I am capable of overcoming my challenges} other{I am capable of overcoming my challenges}}'**
  String inspirationalQuotesNo19(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am capable of calming down my body and mind} female{I am capable of calming down my body and mind} other{I am capable of calming down my body and mind}}'**
  String inspirationalQuotesNo20(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I have self compassion} female{I have self compassion} other{I have self compassion}}'**
  String inspirationalQuotesNo21(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am strong and capable} female{I am strong and capable} other{I am strong and capable}}'**
  String inspirationalQuotesNo22(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'m learning to accept myself} female{I\'m learning to accept myself} other{I\'m learning to accept myself}}'**
  String inspirationalQuotesNo23(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I accept myself as I am} female{I accept myself as I am} other{I accept myself as I am}}'**
  String inspirationalQuotesNo24(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'m learning to notice my positive traits} female{I\'m learning to notice my positive traits} other{I\'m learning to notice my positive traits}}'**
  String inspirationalQuotesNo25(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I recognise my emotions and I allow them to pass} female{I recognise my emotions and I allow them to pass} other{I recognise my emotions and I allow them to pass}}'**
  String inspirationalQuotesNo26(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Emotions can naturally change} female{Emotions can naturally change} other{Emotions can naturally change}}'**
  String inspirationalQuotesNo27(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Positive self talk leads to self esteem} female{Positive self talk leads to self esteem} other{Positive self talk leads to self esteem}}'**
  String inspirationalQuotesNo28(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Daily practice leads to improvement} female{Daily practice leads to improvement} other{Daily practice leads to improvement}}'**
  String inspirationalQuotesNo29(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{You are not alone!} female{You are not alone!} other{You are not alone!}}'**
  String inspirationalQuotesNo30(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Daily practice improves my mood, continuing is worth it} female{Daily practice improves my mood, continuing is worth it} other{Daily practice improves my mood, continuing is worth it}}'**
  String inspirationalQuotesNo31(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am valuable} female{I am valuable} other{I am valuable}}'**
  String inspirationalQuotesNo32(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I believe in my capabilities} female{I believe in my capabilities} other{I believe in my capabilities}}'**
  String inspirationalQuotesNo33(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am worth it} female{I am worth it} other{I am worth it}}'**
  String inspirationalQuotesNo34(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'m working on feeling better} female{I\'m working on feeling better} other{I\'m working on feeling better}}'**
  String inspirationalQuotesNo35(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Life is worth it} female{Life is worth it} other{Life is worth it}}'**
  String inspirationalQuotesNo36(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Studies show that thoughts affect emotions} female{Studies show that thoughts affect emotions} other{Studies show that thoughts affect emotions}}'**
  String inspirationalQuotesNo37(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I deserve to be happy} female{I deserve to be happy} other{I deserve to be happy}}'**
  String inspirationalQuotesNo38(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I can and I will} female{I can and I will} other{I can and I will}}'**
  String inspirationalQuotesNo39(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{You are great just the way you are} female{You are great just the way you are} other{You are great just the way you are}}'**
  String inspirationalQuotesNo40(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thanks for having easier moments} female{Thanks for having easier moments} other{Thanks for having easier moments}}'**
  String thanksListNo0(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thank you for a good meal} female{Thank you for a good meal} other{Thank you for a good meal}}'**
  String thanksListNo1(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thank you for being able to train} female{Thank you for being able to train} other{Thank you for being able to train}}'**
  String thanksListNo2(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thanks for a good conversation} female{Thanks for a good conversation} other{Thanks for a good conversation}}'**
  String thanksListNo3(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thank you for sleeping well} female{Thank you for sleeping well} other{Thank you for sleeping well}}'**
  String thanksListNo4(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thank you for succeeding} female{Thank you for succeeding} other{Thank you for succeeding}}'**
  String thanksListNo5(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thank you for spending time with} female{Thank you for spending time with} other{Thank you for spending time with}}'**
  String thanksListNo6(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thanks for the weather} female{Thanks for the weather} other{Thanks for the weather}}'**
  String thanksListNo7(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thank you for having a home} female{Thank you for having a home} other{Thank you for having a home}}'**
  String thanksListNo8(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thank you for good health} female{Thank you for good health} other{Thank you for good health}}'**
  String thanksListNo9(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thanks for family} female{Thanks for family} other{Thanks for family}}'**
  String thanksListNo10(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thank you for friends} female{Thank you for friends} other{Thank you for friends}}'**
  String thanksListNo11(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I know how to ask for help} female{I know how to ask for help} other{I know how to ask for help}}'**
  String traitsListNo0(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am friendly} female{I am friendly} other{I am friendly}}'**
  String traitsListNo1(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am a good friend} female{I am a good friend} other{I am a good friend}}'**
  String traitsListNo2(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'m ready to invest} female{I\'m ready to invest} other{I\'m ready to invest}}'**
  String traitsListNo3(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am creative} female{I am creative} other{I am creative}}'**
  String traitsListNo4(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am capable} female{I am capable} other{I am capable}}'**
  String traitsListNo5(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I have strengths} female{I have strengths} other{I have strengths}}'**
  String traitsListNo6(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I know how to drive} female{I know how to drive} other{I know how to drive}}'**
  String traitsListNo7(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'m open to experiences} female{I\'m open to experiences} other{I\'m open to experiences}}'**
  String traitsListNo8(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I have perseverance and patience} female{I have perseverance and patience} other{I have perseverance and patience}}'**
  String traitsListNo9(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am patient} female{I am patient} other{I am patient}}'**
  String traitsListNo10(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am sporty} female{I am sporty} other{I am sporty}}'**
  String traitsListNo11(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am able} female{I am able} other{I am able}}'**
  String traitsListNo12(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'m good at organizing} female{I\'m good at organizing} other{I\'m good at organizing}}'**
  String traitsListNo13(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I know how to play} female{I know how to play} other{I know how to play}}'**
  String traitsListNo14(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I know how to cook} female{I know how to cook} other{I know how to cook}}'**
  String traitsListNo15(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am a good father} female{I am a good father} other{I am a good father}}'**
  String traitsListNo16(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am strong} female{I am strong} other{I am strong}}'**
  String traitsListNo17(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am smart} female{I am smart} other{I am smart}}'**
  String traitsListNo18(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I am beautiful} female{I am beautiful} other{I am beautiful}}'**
  String traitsListNo19(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I\'m funny} female{I\'m funny} other{I\'m funny}}'**
  String traitsListNo20(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Watching the news} female{Watching the news} other{Watching the news}}'**
  String difficultEventsListNo0(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Tension with those close to me} female{Tension with those close to me} other{Tension with those close to me}}'**
  String difficultEventsListNo1(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Multiple arguments or disputes} female{Multiple arguments or disputes} other{Multiple arguments or disputes}}'**
  String difficultEventsListNo2(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{I have already faced challenges in the past} female{I have already faced challenges in the past} other{I have already faced challenges in the past}}'**
  String difficultEventsListNo3(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Injustice, unfairness and lack of fairness} female{Injustice, unfairness and lack of fairness} other{Injustice, unfairness and lack of fairness}}'**
  String difficultEventsListNo4(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Unemployment} female{Unemployment} other{Unemployment}}'**
  String difficultEventsListNo5(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Loss} female{Loss} other{Loss}}'**
  String difficultEventsListNo6(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Layoffs, unemployment} female{Layoffs, unemployment} other{Layoffs, unemployment}}'**
  String difficultEventsListNo7(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Overload} female{Overload} other{Overload}}'**
  String difficultEventsListNo8(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Feeling of financial scarcity} female{Feeling of financial scarcity} other{Feeling of financial scarcity}}'**
  String difficultEventsListNo9(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Stress, multitasking} female{Stress, multitasking} other{Stress, multitasking}}'**
  String difficultEventsListNo10(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Unfinished things} female{Unfinished things} other{Unfinished things}}'**
  String difficultEventsListNo11(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Irregular diet} female{Irregular diet} other{Irregular diet}}'**
  String difficultEventsListNo12(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{War} female{War} other{War}}'**
  String difficultEventsListNo13(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Closed} female{Closed} other{Closed}}'**
  String difficultEventsListNo14(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Sleep deprivation} female{Sleep deprivation} other{Sleep deprivation}}'**
  String difficultEventsListNo15(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Death of loved ones} female{Death of loved ones} other{Death of loved ones}}'**
  String difficultEventsListNo16(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Loss of stability and routine} female{Loss of stability and routine} other{Loss of stability and routine}}'**
  String difficultEventsListNo17(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{When I don\'t have time to release energy and aggression} female{When I don\'t have time to release energy and aggression} other{When I don\'t have time to release energy and aggression}}'**
  String difficultEventsListNo18(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Stimulus overload, uncertainty, and transitions} female{Stimulus overload, uncertainty, and transitions} other{Stimulus overload, uncertainty, and transitions}}'**
  String difficultEventsListNo19(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Help me with shared projects that give meaning} female{Help me with shared projects that give meaning} other{Help me with shared projects that give meaning}}'**
  String makeSaferListNo0(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To find out what\'s happening to me and think with me about a way to cope} female{To find out what\'s happening to me and think with me about a way to cope} other{To find out what\'s happening to me and think with me about a way to cope}}'**
  String makeSaferListNo1(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Let me be included in collaborative work} female{Let me be included in collaborative work} other{Let me be included in collaborative work}}'**
  String makeSaferListNo2(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Let them visit me} female{Let them visit me} other{Let them visit me}}'**
  String makeSaferListNo3(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Let them invite me to play or play a game} female{Let them invite me to play or play a game} other{Let them invite me to play or play a game}}'**
  String makeSaferListNo4(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Let me be invited to a shared activity} female{Let me be invited to a shared activity} other{Let me be invited to a shared activity}}'**
  String makeSaferListNo5(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{They encourage me to sleep enough} female{They encourage me to sleep enough} other{They encourage me to sleep enough}}'**
  String makeSaferListNo6(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Don\'t stay alone} female{Don\'t stay alone} other{Don\'t stay alone}}'**
  String makeSaferListNo7(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Let them invite me to a meal} female{Let them invite me to a meal} other{Let them invite me to a meal}}'**
  String makeSaferListNo8(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To receive nourishing food} female{To receive nourishing food} other{To receive nourishing food}}'**
  String makeSaferListNo9(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To ask someone I trust to stay with me} female{To ask someone I trust to stay with me} other{To ask someone I trust to stay with me}}'**
  String makeSaferListNo10(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Let me be invited to a walk, hike, or physical activity} female{Let me be invited to a walk, hike, or physical activity} other{Let me be invited to a walk, hike, or physical activity}}'**
  String makeSaferListNo11(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Avoid places that make me feel unsafe} female{Avoid places that make me feel unsafe} other{Avoid places that make me feel unsafe}}'**
  String makeSaferListNo12(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To leave only a small amount of my medication with me} female{To leave only a small amount of my medication with me} other{To leave only a small amount of my medication with me}}'**
  String makeSaferListNo13(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{And the rest to entrust to someone I trust} female{And the rest to entrust to someone I trust} other{And the rest to entrust to someone I trust}}'**
  String makeSaferListNo14(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To ask someone else to remove things from me that could be used to harm myself} female{To ask someone else to remove things from me that could be used to harm myself} other{To ask someone else to remove things from me that could be used to harm myself}}'**
  String makeSaferListNo15(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{that they will ask me} female{that they will ask me} other{that they will ask me}}'**
  String makeSaferListNo16(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Mindfulness} female{Mindfulness} other{Mindfulness}}'**
  String feelBetterListNo0(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Regular couple/social time during the week} female{Regular couple/social time during the week} other{Regular couple/social time during the week}}'**
  String feelBetterListNo1(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{List of strengths and advantages} female{List of strengths and advantages} other{List of strengths and advantages}}'**
  String feelBetterListNo2(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Gratitude journal} female{Gratitude journal} other{Gratitude journal}}'**
  String feelBetterListNo3(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To say when I have time to listen} female{To say when I have time to listen} other{To say when I have time to listen}}'**
  String feelBetterListNo4(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Slow down and try not to overload me too much} female{Slow down and try not to overload me too much} other{Slow down and try not to overload me too much}}'**
  String feelBetterListNo5(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To disconnect from daily tasks and screens} female{To disconnect from daily tasks and screens} other{To disconnect from daily tasks and screens}}'**
  String feelBetterListNo6(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To see sunlight} female{To see sunlight} other{To see sunlight}}'**
  String feelBetterListNo7(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Go out to nature} female{Go out to nature} other{Go out to nature}}'**
  String feelBetterListNo8(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Rest} female{Rest} other{Rest}}'**
  String feelBetterListNo9(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Quiet time for myself} female{Quiet time for myself} other{Quiet time for myself}}'**
  String feelBetterListNo10(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Brush your teeth to get a fresh taste in your mouth} female{Brush your teeth to get a fresh taste in your mouth} other{Brush your teeth to get a fresh taste in your mouth}}'**
  String feelBetterListNo11(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{or to take a chewing gum} female{or to take a chewing gum} other{or to take a chewing gum}}'**
  String feelBetterListNo12(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To receive a hug from someone I trust} female{To receive a hug from someone I trust} other{To receive a hug from someone I trust}}'**
  String feelBetterListNo13(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To tell myself: \'I am important\'} female{To tell myself: \'I am important\'} other{To tell myself: \'I am important\'}}'**
  String feelBetterListNo14(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{There are people who love me} female{There are people who love me} other{There are people who love me}}'**
  String feelBetterListNo15(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Focus on breathing / bodily sensations} female{Focus on breathing / bodily sensations} other{Focus on breathing / bodily sensations}}'**
  String feelBetterListNo16(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Taking a break by changing my location (e.g., moving to another room in the house)} female{Taking a break by changing my location (e.g., moving to another room in the house)} other{Taking a break by changing my location (e.g., moving to another room in the house)}}'**
  String feelBetterListNo17(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To go for a short walk outside} female{To go for a short walk outside} other{To go for a short walk outside}}'**
  String feelBetterListNo18(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Go outside for some fresh air (outside the house or even from the balcony)} female{Go outside for some fresh air (outside the house or even from the balcony)} other{Go outside for some fresh air (outside the house or even from the balcony)}}'**
  String feelBetterListNo19(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To watch clips} female{To watch clips} other{To watch clips}}'**
  String feelBetterListNo20(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Suicidal thoughts} female{Suicidal thoughts} other{Suicidal thoughts}}'**
  String distractionsListNo0(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Low self-esteem} female{Low self-esteem} other{Low self-esteem}}'**
  String distractionsListNo1(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Feeling like I don\'t matter} female{Feeling like I don\'t matter} other{Feeling like I don\'t matter}}'**
  String distractionsListNo2(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Desire to burrow, hide, or disappear} female{Desire to burrow, hide, or disappear} other{Desire to burrow, hide, or disappear}}'**
  String distractionsListNo3(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Severe fatigue} female{Severe fatigue} other{Severe fatigue}}'**
  String distractionsListNo4(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Decrease in function} female{Decrease in function} other{Decrease in function}}'**
  String distractionsListNo5(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Loss or decrease in strength} female{Loss or decrease in strength} other{Loss or decrease in strength}}'**
  String distractionsListNo6(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Anxieties} female{Anxieties} other{Anxieties}}'**
  String distractionsListNo7(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Reduced sexuality} female{Reduced sexuality} other{Reduced sexuality}}'**
  String distractionsListNo8(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Apathy or indifference} female{Apathy or indifference} other{Apathy or indifference}}'**
  String distractionsListNo9(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Oversensitivity} female{Oversensitivity} other{Oversensitivity}}'**
  String distractionsListNo10(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Self-blame} female{Self-blame} other{Self-blame}}'**
  String distractionsListNo11(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Proliferation and escalation of shopping} female{Proliferation and escalation of shopping} other{Proliferation and escalation of shopping}}'**
  String distractionsListNo12(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Self-neglect} female{Self-neglect} other{Self-neglect}}'**
  String distractionsListNo13(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Overconfidence} female{Overconfidence} other{Overconfidence}}'**
  String distractionsListNo14(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{To do the minimum of the minimum - and even that with great effort} female{To do the minimum of the minimum - and even that with great effort} other{To do the minimum of the minimum - and even that with great effort}}'**
  String distractionsListNo15(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Poor functioning} female{Poor functioning} other{Poor functioning}}'**
  String distractionsListNo16(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Mind is racing} female{Mind is racing} other{Mind is racing}}'**
  String distractionsListNo17(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Thoughts are racing and fast} female{Thoughts are racing and fast} other{Thoughts are racing and fast}}'**
  String distractionsListNo18(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Lack of confidence} female{Lack of confidence} other{Lack of confidence}}'**
  String distractionsListNo19(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Hesitation} female{Hesitation} other{Hesitation}}'**
  String distractionsListNo20(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Slow and confused thoughts} female{Slow and confused thoughts} other{Slow and confused thoughts}}'**
  String distractionsListNo21(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Increased extroversion} female{Increased extroversion} other{Increased extroversion}}'**
  String distractionsListNo22(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Involvement} female{Involvement} other{Involvement}}'**
  String distractionsListNo23(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Gathering} female{Gathering} other{Gathering}}'**
  String distractionsListNo24(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Seclusion} female{Seclusion} other{Seclusion}}'**
  String distractionsListNo25(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Filling every space of time} female{Filling every space of time} other{Filling every space of time}}'**
  String distractionsListNo26(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Fear of being alone} female{Fear of being alone} other{Fear of being alone}}'**
  String distractionsListNo27(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Fear of emptiness} female{Fear of emptiness} other{Fear of emptiness}}'**
  String distractionsListNo28(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Extensive use of various media} female{Extensive use of various media} other{Extensive use of various media}}'**
  String distractionsListNo29(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{More headaches} female{More headaches} other{More headaches}}'**
  String distractionsListNo30(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Overeating} female{Overeating} other{Overeating}}'**
  String distractionsListNo31(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Irregular sleep} female{Irregular sleep} other{Irregular sleep}}'**
  String distractionsListNo32(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Insomnia or light sleep} female{Insomnia or light sleep} other{Insomnia or light sleep}}'**
  String distractionsListNo33(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'Living Positively is a platform designed to strengthen mental resilience, help cope with suicidal crisis situations, encourage self-management, create a personal support network, and promote better, higher-quality lives. It is developed by the clubhouse organization of the Amit Association.\n\nThis app utilizes tools from the field of positive psychology, illness management and recovery, and suicide prevention research.\n\nThe personal program combines a Relapse Prevention Plan from the IMR (Illness Management and Recovery) course along with the Safety Plan from Stanley and Brown.\n\nThe term \"Gratitude List\" was introduced to us by Dr. Shirley Yuval Yair for the gratitude journal and is published here with her approval.\n\nThe product is being developed in collaboration and mutual enrichment with the social incubator at the Technion, with the help of the development team.'**
  String get aboutPage1;

  ///
  ///
  /// In en, this message translates to:
  /// **'The app is intended for personal use to improve mental resilience and provide support and assistance when needed in crisis situations.\n\nThe app cannot and is not designed to replace professional mental health providers. It does not replace professional diagnosis or psychotherapy. The purpose of the integrated tools is to help you and your environment improve quality of life and offer support during a crisis.\n\nYou can use the app for self-help purposes and/or integrate it as part of a therapeutic process with a professional. If you require diagnosis or personal treatment, it is important to consult a professional therapist. The use of the app is at your own personal responsibility.\n\nFor your attention: Your personal data in the app is stored only on your device! The app does not collect or transmit personal information, and it will never be used. You have the option to decide what to share from within, such as the personal plan, which is recommended to share with your close social network and/or therapeutic professionals. If you do not agree with the terms of use, please uninstall the app.'**
  String get aboutPage2;

  ///
  ///
  /// In en, this message translates to:
  /// **'About and Credits'**
  String get aboutTitle1;

  ///
  ///
  /// In en, this message translates to:
  /// **'Terms of Use and Privacy'**
  String get aboutTitle2;

  /// The app version label shown on the about page.
  ///
  /// In en, this message translates to:
  /// **'Living Positively App Version : {version}'**
  String aboutVersionLabel(String version);

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Please select your location:} female{Please select your location:} other{Please select your location:}}'**
  String locationSelect(String gender);

  ///
  ///
  /// In en, this message translates to:
  /// **'The application is designed for personal use to improve mental resilience and provide support in times of crisis.\n\nIt cannot and is not intended to replace professional mental health providers. It does not substitute for a professional diagnosis or psychotherapeutic treatment. The tools integrated into the application aim to assist you and your environment in enhancing quality of life and offering support during challenging times.\n\nYou may use the application for self-help purposes and/or as part of a therapeutic process with a professional provider. If you require diagnosis or personal treatment, it is important to consult a professional therapist. The use of the application is at your own personal responsibility.\n\nPlease note: Your personal data within the application is stored only on your device! The application does not collect or transmit any personal information, and such data will never be used. You have the option to decide what to share, such as your personal plan, which may be shared with close social contacts and/or therapeutic professionals.\n\nIf you do not agree with the terms of use, please remove the application. If you accept these terms, please click the \"Accept\" button.'**
  String get disclaimerText;

  ///
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButtonText;

  /// Main menu item that opens the external support/contact page.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  ///
  ///
  /// In en, this message translates to:
  /// **'Here is the app LP (Living Positively). I use it and recommend it, maybe it will be helpful for you too.'**
  String get shareAppMessage;

  ///
  ///
  /// In en, this message translates to:
  /// **'{gender,select,male{Your location is only used in order to tailor the SOS numbers to your country.} female{Your location is only used in order to tailor the SOS numbers to your country.} other{Your location is only used in order to tailor the SOS numbers to your country.}}'**
  String locationDisclaimer(String gender);

  /// Snackbar shown when launching the system dialer fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the dialer for {number}'**
  String callFailedMessage(String number);

  /// Generic snackbar for WhatsApp/SMS/web launch failures
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the app'**
  String get couldNotOpenApp;

  /// Snackbar action label that copies the failed number to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get copyNumberAction;

  /// Confirmation toast after copying a phone number to clipboard
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get numberCopiedToast;

  /// Banner shown when country detection fails and the grid falls back to the default country
  ///
  /// In en, this message translates to:
  /// **'Showing default emergency numbers ({country}). They may not connect from your current location.'**
  String emergencyCountryFallback(String country);

  /// Tooltip / TalkBack label for the icon-only hamburger menu button
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// Tooltip / TalkBack label for icon-only add buttons (journal entry, list item)
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addItemTooltip;

  /// Tooltip / TalkBack label for the icon-only download button on the personal plan widget
  ///
  /// In en, this message translates to:
  /// **'Download plan'**
  String get downloadPlanTooltip;

  /// Tooltip / TalkBack label for the icon-only share button on the personal plan widget
  ///
  /// In en, this message translates to:
  /// **'Share plan'**
  String get sharePlanTooltip;

  /// Tooltip / TalkBack label for the icon-only refresh button on the inspirational quote widget
  ///
  /// In en, this message translates to:
  /// **'New quote'**
  String get refreshQuoteTooltip;

  /// Tooltip / TalkBack label for the icon-only close (X) button on the inspirational quote widget
  ///
  /// In en, this message translates to:
  /// **'Dismiss quote'**
  String get dismissQuoteTooltip;

  /// Tooltip / TalkBack label for the icon-only dialer affordance next to a personal emergency contact name
  ///
  /// In en, this message translates to:
  /// **'Call {contact}'**
  String callContactTooltip(String contact);

  /// Tooltip / TalkBack label for the icon-only edit button on a thank-you / trait entry
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntryTooltip;

  /// Tooltip / TalkBack label for the icon-only delete button on a thank-you / trait entry
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntryTooltip;

  /// Tooltip / TalkBack label for the floating SOS button
  ///
  /// In en, this message translates to:
  /// **'SOS — emergency contacts'**
  String get sosTooltip;

  /// Phase E (ADR-005 §Decision step 5): Semantics/TalkBack label announced while a shared async view is in its loading state. Gender-neutral on purpose so the shared widget needs no gender plumbing.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get asyncLoadingLabel;

  /// Phase E (ADR-005 §Decision step 5): generic message shown in the shared async view's error state, paired with a retry action.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get asyncErrorMessage;

  /// Phase E (ADR-005 §Decision step 5): label for the retry button in the shared async view's error state.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get asyncRetryButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
