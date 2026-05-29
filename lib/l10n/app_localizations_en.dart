// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'English';

  @override
  String get textDirection => 'ltr';

  @override
  String pageHomeWelcomeGender(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Hi man!',
      'female': 'Hi woman!',
      'other': 'Hi there!',
    });
    return '$_temp0';
  }

  @override
  String greetings(Object username) {
    return 'Welcome, $username';
  }

  @override
  String otherSuggestions(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'other suggestions',
      'female': 'other suggestions',
      'other': 'other suggestions',
    });
    return '$_temp0';
  }

  @override
  String introductionRestartGreeting(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Welcome to Living Positively',
      'female': 'Welcome to Living Positively',
      'other': 'Welcome to Living Positively',
    });
    return '$_temp0';
  }

  @override
  String addFormPageTemplateAdd(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Add',
      'female': 'Add',
      'other': 'Add',
    });
    return '$_temp0';
  }

  @override
  String addThanksFormThank(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thanks',
      'female': 'Thanks',
      'other': 'Thanks',
    });
    return '$_temp0';
  }

  @override
  String addFormEdit(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Edit',
      'female': 'Edit',
      'other': 'Edit',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Login to Living Positively',
      'female': 'Login to Living Positively',
      'other': 'Login to Living Positively',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Login',
      'female': 'Login',
      'other': 'Login',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginGoogleButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Login using Google',
      'female': 'Login using Google',
      'other': 'Login using Google',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginNoAccount(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Don\'t have an account yet?',
      'female': 'Don\'t have an account yet?',
      'other': 'Don\'t have an account yet?',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginToSignup(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Signup',
      'female': 'Signup',
      'other': 'Signup',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginSkip(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Skip Signup',
      'female': 'Skip Signup',
      'other': 'Skip Signup',
    });
    return '$_temp0';
  }

  @override
  String signupLoginSignUpTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Signup to Living Positively',
      'female': 'Signup to Living Positively',
      'other': 'Signup to Living Positively',
    });
    return '$_temp0';
  }

  @override
  String signupLoginSignUpButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Signup',
      'female': 'Signup',
      'other': 'Signup',
    });
    return '$_temp0';
  }

  @override
  String signupLoginSignUpExists(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Already have an account?',
      'female': 'Already have an account?',
      'other': 'Already have an account?',
    });
    return '$_temp0';
  }

  @override
  String signupLoginSignUpToLogin(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Login',
      'female': 'Login',
      'other': 'Login',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageMyPlan(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'My Plan',
      'female': 'My Plan',
      'other': 'My Plan',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageAllPlan(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To see My Plan',
      'female': 'To see My Plan',
      'other': 'To see My Plan',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'My Personal Plan',
      'female': 'My Personal Plan',
      'other': 'My Personal Plan',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageStartedDownload(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Started downloading',
      'female': 'Started downloading',
      'other': 'Started downloading',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageFinishDownload(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Your plan was saved to \"Downloads\"',
      'female': 'Your plan was saved to \"Downloads\"',
      'other': 'Your plan was saved to \"Downloads\"',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageFinish(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Finish',
      'female': 'Finish',
      'other': 'Finish',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageHasFilled(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To update the plan',
      'female': 'To update the plan',
      'other': 'To update the plan',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageDidNotFill(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To fill the plan',
      'female': 'To fill the plan',
      'other': 'To fill the plan',
    });
    return '$_temp0';
  }

  @override
  String homePagePersonalPlanMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'My Plan',
      'female': 'My Plan',
      'other': 'My Plan',
    });
    return '$_temp0';
  }

  @override
  String homePagePersonalPlanSecondaryTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Things that will make me feel better now',
      'female': 'Things that will make me feel better now',
      'other': 'Things that will make me feel better now',
    });
    return '$_temp0';
  }

  @override
  String homePageTraitsMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Qualities List',
      'female': 'Qualities List',
      'other': 'Qualities List',
    });
    return '$_temp0';
  }

  @override
  String homePageTraitsSecondaryTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'What I\'m good at, recommended to read once a day',
      'female': 'What I\'m good at, recommended to read once a day',
      'other': 'What I\'m good at, recommended to read once a day',
    });
    return '$_temp0';
  }

  @override
  String homePageThanksMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Gratitude Journal',
      'female': 'Gratitude Journal',
      'other': 'Gratitude Journal',
    });
    return '$_temp0';
  }

  @override
  String homePageThanksSecondaryTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'What I\'m thankful for',
      'female': 'What I\'m thankful for',
      'other': 'What I\'m thankful for',
    });
    return '$_temp0';
  }

  @override
  String homePageThankyouPopup(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'This is how to strengthen your positive happiness muscle.\nThe recommendation is to be thankful for at least 5 things every day.\nKeep up the good work, and we’ll meet again tomorrow.',
      'female':
          'This is how to strengthen your positive happiness muscle.\nThe recommendation is to be thankful for at least 5 things every day.\nKeep up the good work, and we’ll meet again tomorrow.',
      'other':
          'This is how to strengthen your positive happiness muscle.\nThe recommendation is to be thankful for at least 5 things every day.\nKeep up the good work, and we’ll meet again tomorrow.',
    });
    return '$_temp0';
  }

  @override
  String homePagePositiveTraitPopup(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Check out your list of virtues everyday.\nFeel free to add more, don’t be shy - add more with a full heart.',
      'female':
          'Check out your list of virtues everyday.\nFeel free to add more, don’t be shy - add more with a full heart.',
      'other':
          'Check out your list of virtues everyday.\nFeel free to add more, don’t be shy - add more with a full heart.',
    });
    return '$_temp0';
  }

  @override
  String homePageGreetings(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'It\'s good to have you back :)',
      'female': 'It\'s good to have you back :)',
      'other': 'It\'s good to have you back :)',
    });
    return '$_temp0';
  }

  @override
  String homePageAbout(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'About',
      'female': 'About',
      'other': 'About',
    });
    return '$_temp0';
  }

  @override
  String homePageWellnessTools(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Wellness Tools',
      'female': 'Wellness Tools',
      'other': 'Wellness Tools',
    });
    return '$_temp0';
  }

  @override
  String homePageFeelGood(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Feel Good',
      'female': 'Feel Good',
      'other': 'Feel Good',
    });
    return '$_temp0';
  }

  @override
  String homePageSync(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Sync Accounts',
      'female': 'Sync Accounts',
      'other': 'Sync Accounts',
    });
    return '$_temp0';
  }

  @override
  String homePageBack(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Close',
      'female': 'Close',
      'other': 'Close',
    });
    return '$_temp0';
  }

  @override
  String sharePageHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Great!',
      'female': 'Great!',
      'other': 'Great!',
    });
    return '$_temp0';
  }

  @override
  String sharePageSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'You\'ve created a guide that will help you during moments of crisis!\nLet\'s explore more tools for self-help and mental resilience',
      'female':
          'You\'ve created a guide that will help you during moments of crisis!\nLet\'s explore more tools for self-help and mental resilience',
      'other':
          'You\'ve created a guide that will help you during moments of crisis!\nLet\'s explore more tools for self-help and mental resilience',
    });
    return '$_temp0';
  }

  @override
  String sharePageMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Now you can share your plan with the people close to you, or download it to your phone',
      'female':
          'Now you can share your plan with the people close to you, or download it to your phone',
      'other':
          'Now you can share your plan with the people close to you, or download it to your phone',
    });
    return '$_temp0';
  }

  @override
  String sharePageFinishButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'m Done!',
      'female': 'I\'m Done!',
      'other': 'I\'m Done!',
    });
    return '$_temp0';
  }

  @override
  String get sharePageAddCustomCategory => '+ Add a custom category';

  @override
  String get sharePageCustomCategoryTitle => 'Category Title';

  @override
  String get sharePageCustomCategoryDescription => 'Description';

  @override
  String get sharePageSaveCustomCategory => 'Add category';

  @override
  String get customCategoryOptionEmpoweringQuotes =>
      'Empowering quotes important to remember';

  @override
  String get customCategoryOptionPastEvents => 'Past events to remember';

  @override
  String get customCategoryOptionAboutMe =>
      'Things about me important to remember';

  @override
  String get customCategoryOptionCustomInput => 'Custom Input...';

  @override
  String sharePageShareTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'How would you like to share your plan?',
      'female': 'How would you like to share your plan?',
      'other': 'How would you like to share your plan?',
    });
    return '$_temp0';
  }

  @override
  String sharePageEmergencySendButtonText(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Emergency',
      'female': 'Emergency',
      'other': 'Emergency',
    });
    return '$_temp0';
  }

  @override
  String sharePageRoutineSendButtonText(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Routine',
      'female': 'Routine',
      'other': 'Routine',
    });
    return '$_temp0';
  }

  @override
  String userSettingsTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Update Settings',
      'female': 'Update Settings',
      'other': 'Update Settings',
    });
    return '$_temp0';
  }

  @override
  String userSettingsHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'User Settings',
      'female': 'User Settings',
      'other': 'User Settings',
    });
    return '$_temp0';
  }

  @override
  String userSettingsReset(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Reset Data',
      'female': 'Reset Data',
      'other': 'Reset Data',
    });
    return '$_temp0';
  }

  @override
  String userSettingsName(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'What should we call you?(feel free to use a nickname)',
      'female': 'What should we call you?(feel free to use a nickname)',
      'other': 'What should we call you?(feel free to use a nickname)',
    });
    return '$_temp0';
  }

  @override
  String userSettingsGender(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'How would you prefer to be called?',
      'female': 'How would you prefer to be called?',
      'other': 'How would you prefer to be called?',
    });
    return '$_temp0';
  }

  @override
  String userSettingsAge(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'What is your age?',
      'female': 'What is your age?',
      'other': 'What is your age?',
    });
    return '$_temp0';
  }

  @override
  String settings(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Settings',
      'female': 'Settings',
      'other': 'Settings',
    });
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'What keeps me safe?',
      'female': 'What keeps me safe?',
      'other': 'What keeps me safe?',
    });
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageSubTitle1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Living Positively - for happiness, increasing resilience, and improving quality of life',
      'female':
          'Living Positively - for happiness, increasing resilience, and improving quality of life',
      'other':
          'Living Positively - for happiness, increasing resilience, and improving quality of life',
    });
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageSubTitle2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Excellent tools for self-help and developing mental resilience.',
      'female':
          'Excellent tools for self-help and developing mental resilience.',
      'other':
          'Excellent tools for self-help and developing mental resilience.',
    });
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageSkip(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Skip',
      'female': 'Skip',
      'other': 'Skip',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageSkip(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Skip the Questionnaire',
      'female': 'Skip the Questionnaire',
      'other': 'Skip the Questionnaire',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'My Personal Plan',
      'female': 'My Personal Plan',
      'other': 'My Personal Plan',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageSubTitle1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'You\'re invited to create a personal plan that offers support during overwhelming moments, for both you and those around you.',
      'female':
          'You\'re invited to create a personal plan that offers support during overwhelming moments, for both you and those around you.',
      'other':
          'You\'re invited to create a personal plan that offers support during overwhelming moments, for both you and those around you.',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageSubTitle2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'It\'s recommended to spend a few minutes now to better handle future crises.',
      'female':
          'It\'s recommended to spend a few minutes now to better handle future crises.',
      'other':
          'It\'s recommended to spend a few minutes now to better handle future crises.',
    });
    return '$_temp0';
  }

  @override
  String introductionFormSecondPageMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Let\'s get to know you!',
      'female': 'Let\'s get to know you!',
      'other': 'Let\'s get to know you!',
    });
    return '$_temp0';
  }

  @override
  String introductionFormSecondPageSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Hi! So good you’re here!\nWe want to get to know you better so we can support you.',
      'female':
          'Hi! So good you’re here!\nWe want to get to know you better so we can support you.',
      'other':
          'Hi! So good you’re here!\nWe want to get to know you better so we can support you.',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Reminders of common triggers and escalation factors',
      'female': 'Reminders of common triggers and escalation factors',
      'other': 'Reminders of common triggers and escalation factors',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Factors and events that have been challenging for me in the past',
      'female':
          'Factors and events that have been challenging for me in the past',
      'other':
          'Factors and events that have been challenging for me in the past',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'No idea? Here are some suggestions',
      'female': 'No idea? Here are some suggestions',
      'other': 'No idea? Here are some suggestions',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Click to add options that suit your personal plan',
      'female': 'Click to add options that suit your personal plan',
      'other': 'Click to add options that suit your personal plan',
    });
    return '$_temp0';
  }

  @override
  String distractionsHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Symptoms and warning signs, unusual behaviors for me',
      'female': 'Symptoms and warning signs, unusual behaviors for me',
      'other': 'Symptoms and warning signs, unusual behaviors for me',
    });
    return '$_temp0';
  }

  @override
  String distractionsSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Reminders of things that have appeared personally for me in the past',
      'female':
          'Reminders of things that have appeared personally for me in the past',
      'other':
          'Reminders of things that have appeared personally for me in the past',
    });
    return '$_temp0';
  }

  @override
  String distractionsMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'No idea? Here are some suggestions',
      'female': 'No idea? Here are some suggestions',
      'other': 'No idea? Here are some suggestions',
    });
    return '$_temp0';
  }

  @override
  String distractionsMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Click to add options to suit your personal plan',
      'female': 'Click to add options to suit your personal plan',
      'other': 'Click to add options to suit your personal plan',
    });
    return '$_temp0';
  }

  @override
  String feelBetterHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'For balance and a healthy lifestyle - Wellness Tools - Personal Medications',
      'female':
          'For balance and a healthy lifestyle - Wellness Tools - Personal Medications',
      'other':
          'For balance and a healthy lifestyle - Wellness Tools - Personal Medications',
    });
    return '$_temp0';
  }

  @override
  String feelBetterSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'What helps me improve my mood, relax and feel less stressed?\nMethods for preventative maintenance, and even increase dosages - in emergency situations.',
      'female':
          'What helps me improve my mood, relax and feel less stressed?\nMethods for preventative maintenance, and even increase dosages - in emergency situations.',
      'other':
          'What helps me improve my mood, relax and feel less stressed?\nMethods for preventative maintenance, and even increase dosages - in emergency situations.',
    });
    return '$_temp0';
  }

  @override
  String feelBetterMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'No idea? Here are some suggestions',
      'female': 'No idea? Here are some suggestions',
      'other': 'No idea? Here are some suggestions',
    });
    return '$_temp0';
  }

  @override
  String feelBetterMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Click to add options to suit your personal plan',
      'female': 'Click to add options to suit your personal plan',
      'other': 'Click to add options to suit your personal plan',
    });
    return '$_temp0';
  }

  @override
  String makeSaferHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Support from my environment when I notice early warning signs, and how I’d like to be assisted',
      'female':
          'Support from my environment when I notice early warning signs, and how I’d like to be assisted',
      'other':
          'Support from my environment when I notice early warning signs, and how I’d like to be assisted',
    });
    return '$_temp0';
  }

  @override
  String makeSaferSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Ways my surroundings can help me cope',
      'female': 'Ways my surroundings can help me cope',
      'other': 'Ways my surroundings can help me cope',
    });
    return '$_temp0';
  }

  @override
  String makeSaferMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'No idea? Here are some suggestions',
      'female': 'No idea? Here are some suggestions',
      'other': 'No idea? Here are some suggestions',
    });
    return '$_temp0';
  }

  @override
  String makeSaferMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Click to add options to suit your personal plan',
      'female': 'Click to add options to suit your personal plan',
      'other': 'Click to add options to suit your personal plan',
    });
    return '$_temp0';
  }

  @override
  String phonesPagePhone(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Phone',
      'female': 'Phone',
      'other': 'Phone',
    });
    return '$_temp0';
  }

  @override
  String phonesPageName(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Name',
      'female': 'Name',
      'other': 'Name',
    });
    return '$_temp0';
  }

  @override
  String phonesPageHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Who are the people that support me, who I can turn to if I am distressed or thinking of harming myself?',
      'female':
          'Who are the people that support me, who I can turn to if I am distressed or thinking of harming myself?',
      'other':
          'Who are the people that support me, who I can turn to if I am distressed or thinking of harming myself?',
    });
    return '$_temp0';
  }

  @override
  String phonesPageSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'The people who love me and will help me get through the tough moments are:',
      'female':
          'The people who love me and will help me get through the tough moments are:',
      'other':
          'The people who love me and will help me get through the tough moments are:',
    });
    return '$_temp0';
  }

  @override
  String phonesPageManualTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Add manually',
      'female': 'Add manually',
      'other': 'Add manually',
    });
    return '$_temp0';
  }

  @override
  String phonesPageContactImportTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Add from contacts list',
      'female': 'Add from contacts list',
      'other': 'Add from contacts list',
    });
    return '$_temp0';
  }

  @override
  String saveButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Save',
      'female': 'Save',
      'other': 'Save',
    });
    return '$_temp0';
  }

  @override
  String closeButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Cancel',
      'female': 'Cancel',
      'other': 'Cancel',
    });
    return '$_temp0';
  }

  @override
  String nextButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Continue',
      'female': 'Continue',
      'other': 'Continue',
    });
    return '$_temp0';
  }

  @override
  String showMoreButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Show more',
      'female': 'Show more',
      'other': 'Show more',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageNext(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To the Questionnaire',
      'female': 'To the Questionnaire',
      'other': 'To the Questionnaire',
    });
    return '$_temp0';
  }

  @override
  String saveAndQuitButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To menu',
      'female': 'To menu',
      'other': 'To menu',
    });
    return '$_temp0';
  }

  @override
  String confirmButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Confirm',
      'female': 'Confirm',
      'other': 'Confirm',
    });
    return '$_temp0';
  }

  @override
  String deleteButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Delete',
      'female': 'Delete',
      'other': 'Delete',
    });
    return '$_temp0';
  }

  @override
  String menu(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Menu',
      'female': 'Menu',
      'other': 'Menu',
    });
    return '$_temp0';
  }

  @override
  String notifications(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Reminders',
      'female': 'Reminders',
      'other': 'Reminders',
    });
    return '$_temp0';
  }

  @override
  String home(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Home',
      'female': 'Home',
      'other': 'Home',
    });
    return '$_temp0';
  }

  @override
  String skipButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Skip',
      'female': 'Skip',
      'other': 'Skip',
    });
    return '$_temp0';
  }

  @override
  String select(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Select',
      'female': 'Select',
      'other': 'Select',
    });
    return '$_temp0';
  }

  @override
  String backButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Go back',
      'female': 'Go back',
      'other': 'Go back',
    });
    return '$_temp0';
  }

  @override
  String dialButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Call',
      'female': 'Call',
      'other': 'Call',
    });
    return '$_temp0';
  }

  @override
  String yourContacts(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Your contacts',
      'female': 'Your contacts',
      'other': 'Your contacts',
    });
    return '$_temp0';
  }

  @override
  String emergencyNumbers(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Emergency Numbers',
      'female': 'Emergency Numbers',
      'other': 'Emergency Numbers',
    });
    return '$_temp0';
  }

  @override
  String phonePageTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'You are not alone! If you are in distress right now, please reach out to one of the contacts listed here',
      'female':
          'You are not alone! If you are in distress right now, please reach out to one of the contacts listed here',
      'other':
          'You are not alone! If you are in distress right now, please reach out to one of the contacts listed here',
    });
    return '$_temp0';
  }

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get thanks => 'thanks';

  @override
  String get trait => 'trait';

  @override
  String get link => 'Link to site';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String addImageButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Add Image',
      'female': 'Add Image',
      'other': 'Add Image',
    });
    return '$_temp0';
  }

  @override
  String addImageTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Where to add from',
      'female': 'Where to add from',
      'other': 'Where to add from',
    });
    return '$_temp0';
  }

  @override
  String feelGoodTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Encouraging and uplifting images',
      'female': 'Encouraging and uplifting images',
      'other': 'Encouraging and uplifting images',
    });
    return '$_temp0';
  }

  @override
  String feelGoodSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'It is recommended to add encouraging, uplifting, and joyful images. Smiling pictures of family, friends, hobbies, successful trips, and more',
      'female':
          'It is recommended to add encouraging, uplifting, and joyful images. Smiling pictures of family, friends, hobbies, successful trips, and more',
      'other':
          'It is recommended to add encouraging, uplifting, and joyful images. Smiling pictures of family, friends, hobbies, successful trips, and more',
    });
    return '$_temp0';
  }

  @override
  String get male => 'Male';

  @override
  String get notWillingToSay => 'Not interested sharing';

  @override
  String get noPermissionAllowedText => 'Permission not granted';

  @override
  String get female => 'Female';

  @override
  String get nonBinary => 'Non binary';

  @override
  String showAll(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Show all',
      'female': 'Show all',
      'other': 'Show all',
    });
    return '$_temp0';
  }

  @override
  String notificationPageHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Add a reminder to use Living Positively',
      'female': 'Add a reminder to use Living Positively',
      'other': 'Add a reminder to use Living Positively',
    });
    return '$_temp0';
  }

  @override
  String notificationSetTimeText(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Schedule a reminder for the selected time',
      'female': 'Schedule a reminder for the selected time',
      'other': 'Schedule a reminder for the selected time',
    });
    return '$_temp0';
  }

  @override
  String notificationShowExampleNotification(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Show an example reminder',
      'female': 'Show an example reminder',
      'other': 'Show an example reminder',
    });
    return '$_temp0';
  }

  @override
  String notificationCancelNotification(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Cancel current notification',
      'female': 'Cancel current notification',
      'other': 'Cancel current notification',
    });
    return '$_temp0';
  }

  @override
  String finishedDownloading(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'finishedDownloading',
      'female': 'finishedDownloading',
      'other': 'finishedDownloading',
    });
    return '$_temp0';
  }

  @override
  String downloadFailed(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'download failed',
      'female': 'download failed',
      'other': 'download failed',
    });
    return '$_temp0';
  }

  @override
  String selectLanguage(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Select language',
      'female': 'Select language',
      'other': 'Select language',
    });
    return '$_temp0';
  }

  @override
  String get validateEmpty => 'Field cannot be empty';

  @override
  String get moreVideos => 'More videos';

  @override
  String get noVideosAvailableForLocale =>
      'No videos available for your locale, sorry.';

  @override
  String get confirmResetTitle => 'Are you sure?';

  @override
  String get shareRoutineMessage =>
      'Here is my personal plan that is meant to help keep me safe. I’m sending it to you because, in my view, you also have a part in it. I hope this works for you. I would greatly appreciate your agreement to take part in it if needed. Many thanks in advance, and I look forward to your reply.';

  @override
  String get shareOptions => 'Share Options';

  @override
  String get shareFile => 'Share file of personal plan';

  @override
  String get shareRoutine => 'Share text to involve supporters';

  @override
  String get shareEmergency => 'Share text in case of crises';

  @override
  String get shareEmergencyMessage =>
      'I’m not doing well and I need help. I would appreciate your support in activating my personal plan. Thank you in advance.';

  @override
  String get informationCollectionDisclaimer =>
      'Information Collected:\n\nThe application only collects anonymous and statistical data for the purpose of analysis and service improvement. This data cannot identify any individual user. Among the data collected:\n• General app usage data (e.g., pages viewed, frequency of use).\n• Technical information about the device and system (Device type, OS version).\n• Anonymous location data – collected solely for analyzing trends and usage patterns, without linking to any identifiable user.\n';

  @override
  String get addingContactDisclaimer =>
      'We do not save your contacts, it is for your own use.';

  @override
  String notifyOnscheduledNotification(Object time) {
    return 'Reminder set for $time';
  }

  @override
  String newTraitOrThanks(Object item) {
    return 'New $item';
  }

  @override
  String todoListName(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Gratitude Journal',
      'female': 'Gratitude Journal',
      'other': 'Gratitude Journal',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'What will help me now, even small steps are progress',
      'female': 'What will help me now, even small steps are progress',
      'other': 'What will help me now, even small steps are progress',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I have strengths',
      'female': 'I have strengths',
      'other': 'I have strengths',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'ve already faced challenges in the past',
      'female': 'I\'ve already faced challenges in the past',
      'other': 'I\'ve already faced challenges in the past',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Mood changes like the weather, which is not constant',
      'female': 'Mood changes like the weather, which is not constant',
      'other': 'Mood changes like the weather, which is not constant',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Emotions are fleeting and change',
      'female': 'Emotions are fleeting and change',
      'other': 'Emotions are fleeting and change',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am able',
      'female': 'I am able',
      'other': 'I am able',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I have strength',
      'female': 'I have strength',
      'other': 'I have strength',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'m learning to relax',
      'female': 'I\'m learning to relax',
      'other': 'I\'m learning to relax',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'After the declines come the ascents',
      'female': 'After the declines come the ascents',
      'other': 'After the declines come the ascents',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'It\'s okay to cry',
      'female': 'It\'s okay to cry',
      'other': 'It\'s okay to cry',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thanks for the help',
      'female': 'Thanks for the help',
      'other': 'Thanks for the help',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Take a moment to smile',
      'female': 'Take a moment to smile',
      'other': 'Take a moment to smile',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Remember to breathe',
      'female': 'Remember to breathe',
      'other': 'Remember to breathe',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Routine creates stability',
      'female': 'Routine creates stability',
      'other': 'Routine creates stability',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Movement releases tension',
      'female': 'Movement releases tension',
      'other': 'Movement releases tension',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'It\'s okay to ask for help',
      'female': 'It\'s okay to ask for help',
      'other': 'It\'s okay to ask for help',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'It\'s okay not to be okay',
      'female': 'It\'s okay not to be okay',
      'other': 'It\'s okay not to be okay',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Keep the pace that is right for you',
      'female': 'Keep the pace that is right for you',
      'other': 'Keep the pace that is right for you',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'What gives you the strength to continue?',
      'female': 'What gives you the strength to continue?',
      'other': 'What gives you the strength to continue?',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am capable of overcoming my challenges',
      'female': 'I am capable of overcoming my challenges',
      'other': 'I am capable of overcoming my challenges',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am capable of calming down my body and mind',
      'female': 'I am capable of calming down my body and mind',
      'other': 'I am capable of calming down my body and mind',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo21(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I have self compassion',
      'female': 'I have self compassion',
      'other': 'I have self compassion',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo22(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am strong and capable',
      'female': 'I am strong and capable',
      'other': 'I am strong and capable',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo23(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'m learning to accept myself',
      'female': 'I\'m learning to accept myself',
      'other': 'I\'m learning to accept myself',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo24(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I accept myself as I am',
      'female': 'I accept myself as I am',
      'other': 'I accept myself as I am',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo25(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'m learning to notice my positive traits',
      'female': 'I\'m learning to notice my positive traits',
      'other': 'I\'m learning to notice my positive traits',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo26(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I recognise my emotions and I allow them to pass',
      'female': 'I recognise my emotions and I allow them to pass',
      'other': 'I recognise my emotions and I allow them to pass',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo27(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Emotions can naturally change',
      'female': 'Emotions can naturally change',
      'other': 'Emotions can naturally change',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo28(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Positive self talk leads to self esteem',
      'female': 'Positive self talk leads to self esteem',
      'other': 'Positive self talk leads to self esteem',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo29(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Daily practice leads to improvement',
      'female': 'Daily practice leads to improvement',
      'other': 'Daily practice leads to improvement',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo30(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'You are not alone!',
      'female': 'You are not alone!',
      'other': 'You are not alone!',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo31(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Daily practice improves my mood, continuing is worth it',
      'female': 'Daily practice improves my mood, continuing is worth it',
      'other': 'Daily practice improves my mood, continuing is worth it',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo32(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am valuable',
      'female': 'I am valuable',
      'other': 'I am valuable',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo33(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I believe in my capabilities',
      'female': 'I believe in my capabilities',
      'other': 'I believe in my capabilities',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo34(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am worth it',
      'female': 'I am worth it',
      'other': 'I am worth it',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo35(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'m working on feeling better',
      'female': 'I\'m working on feeling better',
      'other': 'I\'m working on feeling better',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo36(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Life is worth it',
      'female': 'Life is worth it',
      'other': 'Life is worth it',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo37(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Studies show that thoughts affect emotions',
      'female': 'Studies show that thoughts affect emotions',
      'other': 'Studies show that thoughts affect emotions',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo38(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I deserve to be happy',
      'female': 'I deserve to be happy',
      'other': 'I deserve to be happy',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo39(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I can and I will',
      'female': 'I can and I will',
      'other': 'I can and I will',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo40(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'You are great just the way you are',
      'female': 'You are great just the way you are',
      'other': 'You are great just the way you are',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thanks for having easier moments',
      'female': 'Thanks for having easier moments',
      'other': 'Thanks for having easier moments',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thank you for a good meal',
      'female': 'Thank you for a good meal',
      'other': 'Thank you for a good meal',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thank you for being able to train',
      'female': 'Thank you for being able to train',
      'other': 'Thank you for being able to train',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thanks for a good conversation',
      'female': 'Thanks for a good conversation',
      'other': 'Thanks for a good conversation',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thank you for sleeping well',
      'female': 'Thank you for sleeping well',
      'other': 'Thank you for sleeping well',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thank you for succeeding',
      'female': 'Thank you for succeeding',
      'other': 'Thank you for succeeding',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thank you for spending time with',
      'female': 'Thank you for spending time with',
      'other': 'Thank you for spending time with',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thanks for the weather',
      'female': 'Thanks for the weather',
      'other': 'Thanks for the weather',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thank you for having a home',
      'female': 'Thank you for having a home',
      'other': 'Thank you for having a home',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thank you for good health',
      'female': 'Thank you for good health',
      'other': 'Thank you for good health',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thanks for family',
      'female': 'Thanks for family',
      'other': 'Thanks for family',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thank you for friends',
      'female': 'Thank you for friends',
      'other': 'Thank you for friends',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I know how to ask for help',
      'female': 'I know how to ask for help',
      'other': 'I know how to ask for help',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am friendly',
      'female': 'I am friendly',
      'other': 'I am friendly',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am a good friend',
      'female': 'I am a good friend',
      'other': 'I am a good friend',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'m ready to invest',
      'female': 'I\'m ready to invest',
      'other': 'I\'m ready to invest',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am creative',
      'female': 'I am creative',
      'other': 'I am creative',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am capable',
      'female': 'I am capable',
      'other': 'I am capable',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I have strengths',
      'female': 'I have strengths',
      'other': 'I have strengths',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I know how to drive',
      'female': 'I know how to drive',
      'other': 'I know how to drive',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'m open to experiences',
      'female': 'I\'m open to experiences',
      'other': 'I\'m open to experiences',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I have perseverance and patience',
      'female': 'I have perseverance and patience',
      'other': 'I have perseverance and patience',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am patient',
      'female': 'I am patient',
      'other': 'I am patient',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am sporty',
      'female': 'I am sporty',
      'other': 'I am sporty',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am able',
      'female': 'I am able',
      'other': 'I am able',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'m good at organizing',
      'female': 'I\'m good at organizing',
      'other': 'I\'m good at organizing',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I know how to play',
      'female': 'I know how to play',
      'other': 'I know how to play',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I know how to cook',
      'female': 'I know how to cook',
      'other': 'I know how to cook',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am a good father',
      'female': 'I am a good father',
      'other': 'I am a good father',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am strong',
      'female': 'I am strong',
      'other': 'I am strong',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am smart',
      'female': 'I am smart',
      'other': 'I am smart',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I am beautiful',
      'female': 'I am beautiful',
      'other': 'I am beautiful',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I\'m funny',
      'female': 'I\'m funny',
      'other': 'I\'m funny',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Watching the news',
      'female': 'Watching the news',
      'other': 'Watching the news',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Tension with those close to me',
      'female': 'Tension with those close to me',
      'other': 'Tension with those close to me',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Multiple arguments or disputes',
      'female': 'Multiple arguments or disputes',
      'other': 'Multiple arguments or disputes',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'I have already faced challenges in the past',
      'female': 'I have already faced challenges in the past',
      'other': 'I have already faced challenges in the past',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Injustice, unfairness and lack of fairness',
      'female': 'Injustice, unfairness and lack of fairness',
      'other': 'Injustice, unfairness and lack of fairness',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Unemployment',
      'female': 'Unemployment',
      'other': 'Unemployment',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Loss',
      'female': 'Loss',
      'other': 'Loss',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Layoffs, unemployment',
      'female': 'Layoffs, unemployment',
      'other': 'Layoffs, unemployment',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Overload',
      'female': 'Overload',
      'other': 'Overload',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Feeling of financial scarcity',
      'female': 'Feeling of financial scarcity',
      'other': 'Feeling of financial scarcity',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Stress, multitasking',
      'female': 'Stress, multitasking',
      'other': 'Stress, multitasking',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Unfinished things',
      'female': 'Unfinished things',
      'other': 'Unfinished things',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Irregular diet',
      'female': 'Irregular diet',
      'other': 'Irregular diet',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'War',
      'female': 'War',
      'other': 'War',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Closed',
      'female': 'Closed',
      'other': 'Closed',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Sleep deprivation',
      'female': 'Sleep deprivation',
      'other': 'Sleep deprivation',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Death of loved ones',
      'female': 'Death of loved ones',
      'other': 'Death of loved ones',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Loss of stability and routine',
      'female': 'Loss of stability and routine',
      'other': 'Loss of stability and routine',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'When I don\'t have time to release energy and aggression',
      'female': 'When I don\'t have time to release energy and aggression',
      'other': 'When I don\'t have time to release energy and aggression',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Stimulus overload, uncertainty, and transitions',
      'female': 'Stimulus overload, uncertainty, and transitions',
      'other': 'Stimulus overload, uncertainty, and transitions',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Help me with shared projects that give meaning',
      'female': 'Help me with shared projects that give meaning',
      'other': 'Help me with shared projects that give meaning',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'To find out what\'s happening to me and think with me about a way to cope',
      'female':
          'To find out what\'s happening to me and think with me about a way to cope',
      'other':
          'To find out what\'s happening to me and think with me about a way to cope',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Let me be included in collaborative work',
      'female': 'Let me be included in collaborative work',
      'other': 'Let me be included in collaborative work',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Let them visit me',
      'female': 'Let them visit me',
      'other': 'Let them visit me',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Let them invite me to play or play a game',
      'female': 'Let them invite me to play or play a game',
      'other': 'Let them invite me to play or play a game',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Let me be invited to a shared activity',
      'female': 'Let me be invited to a shared activity',
      'other': 'Let me be invited to a shared activity',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'They encourage me to sleep enough',
      'female': 'They encourage me to sleep enough',
      'other': 'They encourage me to sleep enough',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Don\'t stay alone',
      'female': 'Don\'t stay alone',
      'other': 'Don\'t stay alone',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Let them invite me to a meal',
      'female': 'Let them invite me to a meal',
      'other': 'Let them invite me to a meal',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To receive nourishing food',
      'female': 'To receive nourishing food',
      'other': 'To receive nourishing food',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To ask someone I trust to stay with me',
      'female': 'To ask someone I trust to stay with me',
      'other': 'To ask someone I trust to stay with me',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Let me be invited to a walk, hike, or physical activity',
      'female': 'Let me be invited to a walk, hike, or physical activity',
      'other': 'Let me be invited to a walk, hike, or physical activity',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Avoid places that make me feel unsafe',
      'female': 'Avoid places that make me feel unsafe',
      'other': 'Avoid places that make me feel unsafe',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To leave only a small amount of my medication with me',
      'female': 'To leave only a small amount of my medication with me',
      'other': 'To leave only a small amount of my medication with me',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'And the rest to entrust to someone I trust',
      'female': 'And the rest to entrust to someone I trust',
      'other': 'And the rest to entrust to someone I trust',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'To ask someone else to remove things from me that could be used to harm myself',
      'female':
          'To ask someone else to remove things from me that could be used to harm myself',
      'other':
          'To ask someone else to remove things from me that could be used to harm myself',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'that they will ask me',
      'female': 'that they will ask me',
      'other': 'that they will ask me',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Mindfulness',
      'female': 'Mindfulness',
      'other': 'Mindfulness',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Regular couple/social time during the week',
      'female': 'Regular couple/social time during the week',
      'other': 'Regular couple/social time during the week',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'List of strengths and advantages',
      'female': 'List of strengths and advantages',
      'other': 'List of strengths and advantages',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Gratitude journal',
      'female': 'Gratitude journal',
      'other': 'Gratitude journal',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To say when I have time to listen',
      'female': 'To say when I have time to listen',
      'other': 'To say when I have time to listen',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Slow down and try not to overload me too much',
      'female': 'Slow down and try not to overload me too much',
      'other': 'Slow down and try not to overload me too much',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To disconnect from daily tasks and screens',
      'female': 'To disconnect from daily tasks and screens',
      'other': 'To disconnect from daily tasks and screens',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To see sunlight',
      'female': 'To see sunlight',
      'other': 'To see sunlight',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Go out to nature',
      'female': 'Go out to nature',
      'other': 'Go out to nature',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Rest',
      'female': 'Rest',
      'other': 'Rest',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Quiet time for myself',
      'female': 'Quiet time for myself',
      'other': 'Quiet time for myself',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Brush your teeth to get a fresh taste in your mouth',
      'female': 'Brush your teeth to get a fresh taste in your mouth',
      'other': 'Brush your teeth to get a fresh taste in your mouth',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'or to take a chewing gum',
      'female': 'or to take a chewing gum',
      'other': 'or to take a chewing gum',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To receive a hug from someone I trust',
      'female': 'To receive a hug from someone I trust',
      'other': 'To receive a hug from someone I trust',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To tell myself: \'I am important\'',
      'female': 'To tell myself: \'I am important\'',
      'other': 'To tell myself: \'I am important\'',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'There are people who love me',
      'female': 'There are people who love me',
      'other': 'There are people who love me',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Focus on breathing / bodily sensations',
      'female': 'Focus on breathing / bodily sensations',
      'other': 'Focus on breathing / bodily sensations',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Taking a break by changing my location (e.g., moving to another room in the house)',
      'female':
          'Taking a break by changing my location (e.g., moving to another room in the house)',
      'other':
          'Taking a break by changing my location (e.g., moving to another room in the house)',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To go for a short walk outside',
      'female': 'To go for a short walk outside',
      'other': 'To go for a short walk outside',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Go outside for some fresh air (outside the house or even from the balcony)',
      'female':
          'Go outside for some fresh air (outside the house or even from the balcony)',
      'other':
          'Go outside for some fresh air (outside the house or even from the balcony)',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'To watch clips',
      'female': 'To watch clips',
      'other': 'To watch clips',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Suicidal thoughts',
      'female': 'Suicidal thoughts',
      'other': 'Suicidal thoughts',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Low self-esteem',
      'female': 'Low self-esteem',
      'other': 'Low self-esteem',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Feeling like I don\'t matter',
      'female': 'Feeling like I don\'t matter',
      'other': 'Feeling like I don\'t matter',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Desire to burrow, hide, or disappear',
      'female': 'Desire to burrow, hide, or disappear',
      'other': 'Desire to burrow, hide, or disappear',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Severe fatigue',
      'female': 'Severe fatigue',
      'other': 'Severe fatigue',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Decrease in function',
      'female': 'Decrease in function',
      'other': 'Decrease in function',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Loss or decrease in strength',
      'female': 'Loss or decrease in strength',
      'other': 'Loss or decrease in strength',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Anxieties',
      'female': 'Anxieties',
      'other': 'Anxieties',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Reduced sexuality',
      'female': 'Reduced sexuality',
      'other': 'Reduced sexuality',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Apathy or indifference',
      'female': 'Apathy or indifference',
      'other': 'Apathy or indifference',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Oversensitivity',
      'female': 'Oversensitivity',
      'other': 'Oversensitivity',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Self-blame',
      'female': 'Self-blame',
      'other': 'Self-blame',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Proliferation and escalation of shopping',
      'female': 'Proliferation and escalation of shopping',
      'other': 'Proliferation and escalation of shopping',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Self-neglect',
      'female': 'Self-neglect',
      'other': 'Self-neglect',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Overconfidence',
      'female': 'Overconfidence',
      'other': 'Overconfidence',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'To do the minimum of the minimum - and even that with great effort',
      'female':
          'To do the minimum of the minimum - and even that with great effort',
      'other':
          'To do the minimum of the minimum - and even that with great effort',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Poor functioning',
      'female': 'Poor functioning',
      'other': 'Poor functioning',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Mind is racing',
      'female': 'Mind is racing',
      'other': 'Mind is racing',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Thoughts are racing and fast',
      'female': 'Thoughts are racing and fast',
      'other': 'Thoughts are racing and fast',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Lack of confidence',
      'female': 'Lack of confidence',
      'other': 'Lack of confidence',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Hesitation',
      'female': 'Hesitation',
      'other': 'Hesitation',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo21(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Slow and confused thoughts',
      'female': 'Slow and confused thoughts',
      'other': 'Slow and confused thoughts',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo22(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Increased extroversion',
      'female': 'Increased extroversion',
      'other': 'Increased extroversion',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo23(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Involvement',
      'female': 'Involvement',
      'other': 'Involvement',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo24(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Gathering',
      'female': 'Gathering',
      'other': 'Gathering',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo25(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Seclusion',
      'female': 'Seclusion',
      'other': 'Seclusion',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo26(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Filling every space of time',
      'female': 'Filling every space of time',
      'other': 'Filling every space of time',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo27(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Fear of being alone',
      'female': 'Fear of being alone',
      'other': 'Fear of being alone',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo28(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Fear of emptiness',
      'female': 'Fear of emptiness',
      'other': 'Fear of emptiness',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo29(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Extensive use of various media',
      'female': 'Extensive use of various media',
      'other': 'Extensive use of various media',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo30(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'More headaches',
      'female': 'More headaches',
      'other': 'More headaches',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo31(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Overeating',
      'female': 'Overeating',
      'other': 'Overeating',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo32(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Irregular sleep',
      'female': 'Irregular sleep',
      'other': 'Irregular sleep',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo33(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Insomnia or light sleep',
      'female': 'Insomnia or light sleep',
      'other': 'Insomnia or light sleep',
    });
    return '$_temp0';
  }

  @override
  String get aboutPage1 =>
      'Living Positively is a platform designed to strengthen mental resilience, help cope with suicidal crisis situations, encourage self-management, create a personal support network, and promote better, higher-quality lives. It is developed by the clubhouse organization of the Amit Association.\n\nThis app utilizes tools from the field of positive psychology, illness management and recovery, and suicide prevention research.\n\nThe personal program combines a Relapse Prevention Plan from the IMR (Illness Management and Recovery) course along with the Safety Plan from Stanley and Brown.\n\nThe term \"Gratitude List\" was introduced to us by Dr. Shirley Yuval Yair for the gratitude journal and is published here with her approval.\n\nThe product is being developed in collaboration and mutual enrichment with the social incubator at the Technion, with the help of the development team.';

  @override
  String get aboutPage2 =>
      'The app is intended for personal use to improve mental resilience and provide support and assistance when needed in crisis situations.\n\nThe app cannot and is not designed to replace professional mental health providers. It does not replace professional diagnosis or psychotherapy. The purpose of the integrated tools is to help you and your environment improve quality of life and offer support during a crisis.\n\nYou can use the app for self-help purposes and/or integrate it as part of a therapeutic process with a professional. If you require diagnosis or personal treatment, it is important to consult a professional therapist. The use of the app is at your own personal responsibility.\n\nFor your attention: Your personal data in the app is stored only on your device! The app does not collect or transmit personal information, and it will never be used. You have the option to decide what to share from within, such as the personal plan, which is recommended to share with your close social network and/or therapeutic professionals. If you do not agree with the terms of use, please uninstall the app.';

  @override
  String get aboutTitle1 => 'About and Credits';

  @override
  String get aboutTitle2 => 'Terms of Use and Privacy';

  @override
  String aboutVersionLabel(String version) {
    return 'Living Positively App Version : $version';
  }

  @override
  String locationSelect(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Please select your location:',
      'female': 'Please select your location:',
      'other': 'Please select your location:',
    });
    return '$_temp0';
  }

  @override
  String get disclaimerText =>
      'The application is designed for personal use to improve mental resilience and provide support in times of crisis.\n\nIt cannot and is not intended to replace professional mental health providers. It does not substitute for a professional diagnosis or psychotherapeutic treatment. The tools integrated into the application aim to assist you and your environment in enhancing quality of life and offering support during challenging times.\n\nYou may use the application for self-help purposes and/or as part of a therapeutic process with a professional provider. If you require diagnosis or personal treatment, it is important to consult a professional therapist. The use of the application is at your own personal responsibility.\n\nPlease note: Your personal data within the application is stored only on your device! The application does not collect or transmit any personal information, and such data will never be used. You have the option to decide what to share, such as your personal plan, which may be shared with close social contacts and/or therapeutic professionals.\n\nIf you do not agree with the terms of use, please remove the application. If you accept these terms, please click the \"Accept\" button.';

  @override
  String get shareButtonText => 'Share';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get shareAppMessage =>
      'Here is the app LP (Living Positively). I use it and recommend it, maybe it will be helpful for you too.';

  @override
  String locationDisclaimer(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'Your location is only used in order to tailor the SOS numbers to your country.',
      'female':
          'Your location is only used in order to tailor the SOS numbers to your country.',
      'other':
          'Your location is only used in order to tailor the SOS numbers to your country.',
    });
    return '$_temp0';
  }

  @override
  String callFailedMessage(String number) {
    return 'Couldn\'t open the dialer for $number';
  }

  @override
  String get couldNotOpenApp => 'Couldn\'t open the app';

  @override
  String get copyNumberAction => 'Copy number';

  @override
  String get numberCopiedToast => 'Number copied';

  @override
  String emergencyCountryFallback(String country) {
    return 'Showing default emergency numbers ($country). They may not connect from your current location.';
  }

  @override
  String get menuTooltip => 'Menu';

  @override
  String get addItemTooltip => 'Add';

  @override
  String get downloadPlanTooltip => 'Download plan';

  @override
  String get sharePlanTooltip => 'Share plan';

  @override
  String get refreshQuoteTooltip => 'New quote';

  @override
  String get dismissQuoteTooltip => 'Dismiss quote';

  @override
  String callContactTooltip(String contact) {
    return 'Call $contact';
  }

  @override
  String get editEntryTooltip => 'Edit entry';

  @override
  String get deleteEntryTooltip => 'Delete entry';

  @override
  String get sosTooltip => 'SOS — emergency contacts';

  @override
  String get asyncLoadingLabel => 'Loading';

  @override
  String get asyncErrorMessage => 'Something went wrong.';

  @override
  String get asyncRetryButton => 'Try again';
}
