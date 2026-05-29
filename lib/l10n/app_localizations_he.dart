// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get language => 'עברית';

  @override
  String get textDirection => 'rtl';

  @override
  String pageHomeWelcomeGender(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שלום לך גבר',
      'female': 'שלום לך אישה',
      'other': 'שלום לך',
    });
    return '$_temp0';
  }

  @override
  String greetings(Object username) {
    return 'היי, $username';
  }

  @override
  String otherSuggestions(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הצעות אחרות',
      'female': 'הצעות אחרות',
      'other': 'הצעות אחרות',
    });
    return '$_temp0';
  }

  @override
  String introductionRestartGreeting(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ברוכים הבאים לLiving Positively',
      'female': 'ברוכים הבאים לLiving Positively',
      'other': 'ברוכים הבאים לLiving Positively',
    });
    return '$_temp0';
  }

  @override
  String addFormPageTemplateAdd(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הוספה',
      'female': 'הוספה',
      'other': 'הוספה',
    });
    return '$_temp0';
  }

  @override
  String addThanksFormThank(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה',
      'female': 'תודה',
      'other': 'תודה',
    });
    return '$_temp0';
  }

  @override
  String addFormEdit(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ערוך',
      'female': 'ערוך',
      'other': 'ערוך',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'התחברות לLiving Positively',
      'female': 'התחברות לLiving Positively',
      'other': 'התחברות לLiving Positively',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'התחברות',
      'female': 'התחברות',
      'other': 'התחברות',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginGoogleButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'התחברות באמצעות גוגל',
      'female': 'התחברות באמצעות גוגל',
      'other': 'התחברות באמצעות גוגל',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginNoAccount(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '?אין לך חשבון',
      'female': '?אין לך חשבון',
      'other': '?אין לך חשבון',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginToSignup(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לרישום',
      'female': 'לרישום',
      'other': 'לרישום',
    });
    return '$_temp0';
  }

  @override
  String signupLoginLoginSkip(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לדילוג על הרישום',
      'female': 'לדילוג על הרישום',
      'other': 'לדילוג על הרישום',
    });
    return '$_temp0';
  }

  @override
  String signupLoginSignUpTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הרשמה לLiving Positively',
      'female': 'הרשמה לLiving Positively',
      'other': 'הרשמה לLiving Positively',
    });
    return '$_temp0';
  }

  @override
  String signupLoginSignUpButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'רישום',
      'female': 'רישום',
      'other': 'רישום',
    });
    return '$_temp0';
  }

  @override
  String signupLoginSignUpExists(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '?כבר יש לך חשבון',
      'female': '?כבר יש לך חשבון',
      'other': '?כבר יש לך חשבון',
    });
    return '$_temp0';
  }

  @override
  String signupLoginSignUpToLogin(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'להתחברות',
      'female': 'להתחברות',
      'other': 'להתחברות',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageMyPlan(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'התוכנית שלי',
      'female': 'התוכנית שלי',
      'other': 'התוכנית שלי',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageAllPlan(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לכל התוכנית',
      'female': 'לכל התוכנית',
      'other': 'לכל התוכנית',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'התוכנית האישית שלי',
      'female': 'התוכנית האישית שלי',
      'other': 'התוכנית האישית שלי',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageStartedDownload(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ההורדה החלה',
      'female': 'ההורדה החלה',
      'other': 'ההורדה החלה',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageFinishDownload(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'התוכנית ירדה להורדות',
      'female': 'התוכנית ירדה להורדות',
      'other': 'התוכנית ירדה להורדות',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageFinish(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אישור',
      'female': 'אישור',
      'other': 'אישור',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageHasFilled(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לעדכון התוכנית',
      'female': 'לעדכון התוכנית',
      'other': 'לעדכון התוכנית',
    });
    return '$_temp0';
  }

  @override
  String personalPlanPageDidNotFill(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'למילוי',
      'female': 'למילוי',
      'other': 'למילוי',
    });
    return '$_temp0';
  }

  @override
  String homePagePersonalPlanMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'התכנית שלי',
      'female': 'התכנית שלי',
      'other': 'התכנית שלי',
    });
    return '$_temp0';
  }

  @override
  String homePagePersonalPlanSecondaryTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'דברים שיעשו לי טוב עכשיו',
      'female': 'דברים שיעשו לי טוב עכשיו',
      'other': 'דברים שיעשו לי טוב עכשיו',
    });
    return '$_temp0';
  }

  @override
  String homePageTraitsMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'רשימת מעלות',
      'female': 'רשימת מעלות',
      'other': 'רשימת מעלות',
    });
    return '$_temp0';
  }

  @override
  String homePageTraitsSecondaryTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'במה אני חזק, מומלץ לקרוא פעם ביום',
      'female': 'במה אני חזקה, מומלץ לקרוא פעם ביום',
      'other': 'חוזקות שלי, מומלץ לקרוא פעם ביום',
    });
    return '$_temp0';
  }

  @override
  String homePageThanksMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודו ליסט',
      'female': 'תודו ליסט',
      'other': 'תודו ליסט',
    });
    return '$_temp0';
  }

  @override
  String homePageThanksSecondaryTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'על מה אני מודה היום',
      'female': 'על מה אני מודה היום',
      'other': 'על מה אני מודה היום',
    });
    return '$_temp0';
  }

  @override
  String homePageThankyouPopup(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'זאת הדרך לחזק את שריר האושר החיובי שלך. ההמלצה היא כל יום להודות לפחות על 5 דברים בחיים שלך. יישר כוח וניפגש שוב מחר',
      'female':
          'זאת הדרך לחזק את שריר האושר החיובי שלך. ההמלצה היא כל יום להודות לפחות על 5 דברים בחיים שלך. יישר כוח וניפגש שוב מחר',
      'other':
          ' זאת הדרך לחזק את שריר האושר החיובי שלך. ההמלצה היא כל יום להודות לפחות על 5 דברים בחיים שלך. יישר כוח וניפגש שוב מחר',
    });
    return '$_temp0';
  }

  @override
  String homePagePositiveTraitPopup(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'ההמלצה היא כל יום להביט ברשימת המעלות שלך. וכשיש דבר מה להוסיף, לא להתבייש ולהוסיף ללא שיפוטיות ובלב שלם',
      'female':
          ' ההמלצה היא כל יום להביט ברשימת המעלות שלך. וכשיש דבר מה להוסיף, לא להתבייש ולהוסיף ללא שיפוטיות ובלב שלם',
      'other':
          ' ההמלצה היא כל יום להביט ברשימת המעלות שלך. וכשיש דבר מה להוסיף, לא להתבייש ולהוסיף ללא שיפוטיות ובלב שלם',
    });
    return '$_temp0';
  }

  @override
  String homePageGreetings(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'טוב לראות אותך :)',
      'female': 'טוב לראות אותך :)',
      'other': 'טוב לראות אותך :)',
    });
    return '$_temp0';
  }

  @override
  String homePageAbout(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אודות',
      'female': 'אודות',
      'other': 'אודות',
    });
    return '$_temp0';
  }

  @override
  String homePageWellnessTools(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'כלי תמיכה',
      'female': 'כלי תמיכה',
      'other': 'כלי תמיכה',
    });
    return '$_temp0';
  }

  @override
  String homePageFeelGood(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'להרגיש טוב',
      'female': 'להרגיש טוב',
      'other': 'להרגיש טוב',
    });
    return '$_temp0';
  }

  @override
  String homePageSync(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'סנכרון מכשירים',
      'female': 'סנכרון מכשירים',
      'other': 'סנכרון מכשירים',
    });
    return '$_temp0';
  }

  @override
  String homePageBack(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'סגירה',
      'female': 'סגירה',
      'other': 'סגירה',
    });
    return '$_temp0';
  }

  @override
  String sharePageHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'איזה כיף!',
      'female': 'איזה כיף!',
      'other': 'איזה כיף!',
    });
    return '$_temp0';
  }

  @override
  String sharePageSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'יצרת לך מדריך שיעזור לך ברגעי משבר! בוא ונכיר כלים נוספים לעזרה עצמית ולחוסן נפשי',
      'female':
          'יצרת לך מדריך שיעזור לך ברגעי משבר! בואי ונכיר כלים נוספים לעזרה עצמית ולחוסן נפשי',
      'other':
          'יצרת לך מדריך שיעזור לך ברגעי משבר! הבה ונכיר כלים נוספים לעזרה עצמית ולחוסן נפשי',
    });
    return '$_temp0';
  }

  @override
  String sharePageMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'עכשיו אתה יכול לשתף את התוכנית עם הקרובים אליך או להוריד אותה כקובץ',
      'female':
          'עכשיו את יכולה לשתף את התוכנית עם הקרובים אלייך או להוריד אותה כקובץ',
      'other': 'עכשיו ניתן לשתף את התוכנית עם הקרובים לך או להוריד אותה כקובץ',
    });
    return '$_temp0';
  }

  @override
  String sharePageFinishButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'סיימתי!',
      'female': 'סיימתי!',
      'other': 'סיימתי!',
    });
    return '$_temp0';
  }

  @override
  String get sharePageAddCustomCategory => '+ הוספת קטגוריה';

  @override
  String get sharePageCustomCategoryTitle => 'כותרת הקטגוריה';

  @override
  String get sharePageCustomCategoryDescription => 'תיאור';

  @override
  String get sharePageSaveCustomCategory => 'הוספת קטגוריה';

  @override
  String get customCategoryOptionEmpoweringQuotes =>
      'משפטים מחזקים שחשוב לי לזכור';

  @override
  String get customCategoryOptionPastEvents => 'אירועים מהעבר לתזכורת';

  @override
  String get customCategoryOptionAboutMe => 'דברים עלי שחשוב לי שנזכור';

  @override
  String get customCategoryOptionCustomInput => 'אפשרות לכתוב משהו מקורי משלי';

  @override
  String sharePageShareTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'איך תרצה לשתף את התוכנית?',
      'female': 'איך תרצי לשתף את התוכנית?',
      'other': 'איך תרצו לשתף את התוכנית?',
    });
    return '$_temp0';
  }

  @override
  String sharePageEmergencySendButtonText(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'חירום',
      'female': 'חירום',
      'other': 'חירום',
    });
    return '$_temp0';
  }

  @override
  String sharePageRoutineSendButtonText(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שגרה',
      'female': 'שגרה',
      'other': 'שגרה',
    });
    return '$_temp0';
  }

  @override
  String userSettingsTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'עדכון פרטים אישיים',
      'female': 'עדכון פרטים אישיים',
      'other': 'עדכון פרטים אישיים',
    });
    return '$_temp0';
  }

  @override
  String userSettingsHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הגדרות משתמש',
      'female': 'הגדרות משתמש',
      'other': 'הגדרות משתמש',
    });
    return '$_temp0';
  }

  @override
  String userSettingsReset(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'איפוס חשבון',
      'female': 'איפוס חשבון',
      'other': 'איפוס חשבון',
    });
    return '$_temp0';
  }

  @override
  String userSettingsName(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מהו שמי?(אפשר גם לרשום כינוי)',
      'female': 'מהו שמי?(אפשר גם לרשום כינוי)',
      'other': 'מהו שמי?(אפשר גם לרשום כינוי)',
    });
    return '$_temp0';
  }

  @override
  String userSettingsGender(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'כיצד הייתי רוצה שיפנו אלי?',
      'female': 'כיצד הייתי רוצה שיפנו אלי?',
      'other': 'כיצד הייתי רוצה שיפנו אלי?',
    });
    return '$_temp0';
  }

  @override
  String userSettingsAge(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מהו גילי?',
      'female': 'מהו גילי?',
      'other': 'מהו גילי?',
    });
    return '$_temp0';
  }

  @override
  String settings(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הגדרות',
      'female': 'הגדרות',
      'other': 'הגדרות',
    });
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מה ששומר עלי',
      'female': 'מה ששומר עלי',
      'other': 'מה ששומר עלי',
    });
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageSubTitle1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'Living Positively - לשיפור איכות החיים, הגברת החוסן והאושר',
      'female': 'Living Positively - לשיפור איכות החיים, הגברת החוסן והאושר',
      'other': 'Living Positively - לשיפור איכות החיים, הגברת החוסן והאושר',
    });
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageSubTitle2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'כלים מעולים לעזרה עצמית ופיתוח חוסן נפשי.',
      'female': 'כלים מעולים לעזרה עצמית ופיתוח חוסן נפשי.',
      'other': 'כלים מעולים לעזרה עצמית ופיתוח חוסן נפשי.',
    });
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageSkip(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לדילוג',
      'female': 'לדילוג',
      'other': 'לדילוג',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageSkip(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'דלג על השאלון',
      'female': 'דלגי על השאלון',
      'other': 'דלג.י על השאלון',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'התוכנית האישית שלי',
      'female': 'התוכנית האישית שלי',
      'other': 'התוכנית האישית שלי',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageSubTitle1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'מוזמן ליצור תכנית אישית, שתיתן לך ולסביבה יד ברגעים שבהם הכל הופך ליותר מדי',
      'female':
          'מוזמנת ליצור תכנית אישית, שתיתן לך ולסביבה יד ברגעים שבהם הכל הופך ליותר מדי',
      'other':
          'הזמנה ליצור תכנית אישית, שתיתן לך ולסביבה יד ברגעים שבהם הכל הופך ליותר מדי',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageSubTitle2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מומלץ להקדיש כמה דקות עכשיו. כדי לעבור בקלות רגעי משבר עתידיים',
      'female':
          'מומלץ להקדיש כמה דקות עכשיו. כדי לעבור בקלות רגעי משבר עתידיים',
      'other': 'מומלץ להקדיש כמה דקות עכשיו. כדי לעבור בקלות רגעי משבר עתידיים',
    });
    return '$_temp0';
  }

  @override
  String introductionFormSecondPageMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'בוא נכיר',
      'female': 'בואי נכיר',
      'other': 'בוא/י נכיר',
    });
    return '$_temp0';
  }

  @override
  String introductionFormSecondPageSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'היי, שמחים שהגעת! נשמח להכיר אותך קצת כדי שנוכל לדעת איך לפנות אליך',
      'female':
          'היי, שמחות שהגעת! נשמח להכיר אותך קצת כדי שנוכל לדעת איך לפנות אלייך',
      'other':
          'היי, כיף שהגעת! נשמח להכיר אותך קצת כדי שנוכל לדעת איך לפנות בצורה הנוחה לך ביותר',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תזכורות לטריגרים נפוצים וגורמי הסלמה',
      'female': 'תזכורות לטריגרים נפוצים וגורמי הסלמה',
      'other': 'תזכורות לטריגרים נפוצים וגורמי הסלמה',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'גורמים ואירועים שהקשו עלי בעבר',
      'female': 'גורמים ואירועים שהקשו עלי בעבר',
      'other': 'גורמים ואירועים שהקשו עלי בעבר',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אין לך רעיון? הנה כמה הצעות',
      'female': 'אין לך רעיון? הנה כמה הצעות',
      'other': 'אין לך רעיון? הנה כמה הצעות',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לחץ כדי להוסיף אפשרויות המתאימות לך לתכנית האישית שלך',
      'female': 'לחץ כדי להוסיף אפשרויות המתאימות לך לתכנית האישית שלך',
      'other': 'לחץ כדי להוסיף אפשרויות המתאימות לך לתכנית האישית שלך',
    });
    return '$_temp0';
  }

  @override
  String distractionsHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'סימפטומים וסימני אזהרה, התנהגויות לא רגילות עבורי',
      'female': 'סימפטומים וסימני אזהרה',
      'other': 'סימפטומים וסימני אזהרה',
    });
    return '$_temp0';
  }

  @override
  String distractionsSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תזכורות לדברים שהופיעו בעבר אצלי אישית',
      'female': 'תזכורות לדברים שהופיעו בעבר אצלי אישית',
      'other': 'תזכורות לדברים שהופיעו בעבר אצלי אישית',
    });
    return '$_temp0';
  }

  @override
  String distractionsMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אין לך רעיון? קבל כמה הצעות',
      'female': 'אין לך רעיון? קבלי כמה הצעות',
      'other': 'אין לך רעיון? הנה כמה הצעות',
    });
    return '$_temp0';
  }

  @override
  String distractionsMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לחץ כדי להוסיף אפשרויות המתאימות לך לתכנית האישית שלך',
      'female': 'לחצי כדי להוסיף אפשרויות המתאימות לך לתכנית האישית שלך',
      'other': 'ללחוץ כדי להוסיף אפשרויות המתאימות לך לתכנית האישית שלך',
    });
    return '$_temp0';
  }

  @override
  String feelBetterHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לאיזון ואורח חיים בריא - Wellness Tools- תרופות אישיות',
      'female': 'לאיזון ואורח חיים בריא - Wellness Tools- תרופות אישיות',
      'other': 'תרופות אישיות - Wellness Tools - לאיזון אורח חיים בריא',
    });
    return '$_temp0';
  }

  @override
  String feelBetterSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'מה עוזר לי לשפר את מצב הרוח, להירגע, להרגיש קצת פחות לחץ. דרכים שבהן כדאי לי להשתמש ולהיעזר כתחזוקה מונעת, וכשיש צורך במצבי חירום אפילו להגביר מינונים.',
      'female':
          'דרכים שבהן כדאי לי להשתמש ולהיעזר כתחזוקה מונעת, וכשיש צורך במצבי חירום אפילו להגביר מינונים.',
      'other':
          'דרכים שבהן כדאי לי להשתמש ולהיעזר כתחזוקה מונעת, וכשיש צורך במצבי חירום אפילו להגביר מינונים.',
    });
    return '$_temp0';
  }

  @override
  String feelBetterMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אין לך רעיון? הנה כמה הצעות',
      'female': 'אין לך רעיון? הנה כמה הצעות',
      'other': 'אין לך רעיון? הנה כמה הצעות',
    });
    return '$_temp0';
  }

  @override
  String feelBetterMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לחץ כדי להוסיף אפשרויות המתאימות לך לתכנית הבטחון שלך',
      'female': 'לחצי כדי להוסיף אפשרויות המתאימות לך לתכנית הבטחון שלך',
      'other': 'לחצ.י כדי להוסיף אפשרויות המתאימות לך לתכנית הבטחון שלך',
    });
    return '$_temp0';
  }

  @override
  String makeSaferHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'תמיכות ועזרה מהסביבה כשאני חווה סימני אזהרה מוקדמים, איך הייתי רוצה שיעזרו לי',
      'female':
          'תמיכות ועזרה מהסביבה כשאני חווה סימני אזהרה מוקדמים, איך הייתי רוצה שיעזרו לי',
      'other':
          'תמיכות ועזרה מהסביבה כשאני חווה סימני אזהרה מוקדמים, איך הייתי רוצה שיעזרו לי',
    });
    return '$_temp0';
  }

  @override
  String makeSaferSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'דרכים שבהן הסביבה יכולה לעזור לי להתמודד.',
      'female': 'דרכים שבהן הסביבה יכולה לעזור לי להתמודד.',
      'other': 'דרכים שבהן הסביבה יכולה לעזור לי להתמודד.',
    });
    return '$_temp0';
  }

  @override
  String makeSaferMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אין לך רעיון? קבל כמה הצעות',
      'female': 'אין לך רעיון? קבלי כמה הצעות',
      'other': 'אין לך רעיון? קבל.י כמה הצעות',
    });
    return '$_temp0';
  }

  @override
  String makeSaferMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לחץ כדי להוסיף אפשרויות המתאימות לך לתכנית הבטחון שלך',
      'female': 'לחצי כדי להוסיף אפשרויות המתאימות לך לתכנית הבטחון שלך',
      'other': 'לחצ.י כדי להוסיף אפשרויות המתאימות לך לתכנית הבטחון שלך',
    });
    return '$_temp0';
  }

  @override
  String phonesPagePhone(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'טלפון',
      'female': 'טלפון',
      'other': 'טלפון',
    });
    return '$_temp0';
  }

  @override
  String phonesPageName(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שם',
      'female': 'שם',
      'other': 'שם',
    });
    return '$_temp0';
  }

  @override
  String phonesPageHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'מי האנשים שתומכים בי,שאני יכול לפנות אליהם אם אני במצוקה או חושב לפגוע בעצמי',
      'female':
          'מי האנשים שתומכים בי, שאני יכולה לפנות אליהם אם אני במצוקה או חושבת לפגוע בעצמי',
      'other':
          'מי האנשים שתומכים בי,שאוכל לפנות אליהם אם אני במצוקה או עם מחשבות על פגיעה עצמית',
    });
    return '$_temp0';
  }

  @override
  String phonesPageSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'האנשים שאוהבים אותי ויעזרו לי לצלוח את הרגעים הקשים הם:',
      'female': 'האנשים שאוהבים אותי ויעזרו לי לצלוח את הרגעים הקשים הם:',
      'other': 'האנשים שאוהבים אותי ויעזרו לי לצלוח את הרגעים הקשים הם:',
    });
    return '$_temp0';
  }

  @override
  String phonesPageManualTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הוספה ידנית',
      'female': 'הוספה ידנית',
      'other': 'הוספה ידנית',
    });
    return '$_temp0';
  }

  @override
  String phonesPageContactImportTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הוספה מאנשי קשר',
      'female': 'הוספה מאנשי קשר',
      'other': 'הוספה מאנשי קשר',
    });
    return '$_temp0';
  }

  @override
  String saveButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שמור',
      'female': 'שמרי',
      'other': 'שמור',
    });
    return '$_temp0';
  }

  @override
  String closeButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'בטל',
      'female': 'בטלי',
      'other': 'בטל',
    });
    return '$_temp0';
  }

  @override
  String nextButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'המשך',
      'female': 'המשיכי',
      'other': 'המשכ.י',
    });
    return '$_temp0';
  }

  @override
  String showMoreButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'להציג עוד',
      'female': 'להציג עוד',
      'other': 'להציג עוד',
    });
    return '$_temp0';
  }

  @override
  String introductionFormLastPageNext(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'למילוי השאלון',
      'female': 'למילוי השאלון',
      'other': 'למילוי השאלון',
    });
    return '$_temp0';
  }

  @override
  String saveAndQuitButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לשמור ולצאת',
      'female': 'לשמור ולצאת',
      'other': 'לשמור ולצאת',
    });
    return '$_temp0';
  }

  @override
  String confirmButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אישור',
      'female': 'אישור',
      'other': 'אישור',
    });
    return '$_temp0';
  }

  @override
  String deleteButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מחיקה',
      'female': 'מחיקה',
      'other': 'מחיקה',
    });
    return '$_temp0';
  }

  @override
  String menu(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תפריט',
      'female': 'תפריט',
      'other': 'תפריט',
    });
    return '$_temp0';
  }

  @override
  String notifications(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תזכורות',
      'female': 'תזכורות',
      'other': 'תזכורות',
    });
    return '$_temp0';
  }

  @override
  String home(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'בית',
      'female': 'בית',
      'other': 'בית',
    });
    return '$_temp0';
  }

  @override
  String skipButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'דלג',
      'female': 'דלגי',
      'other': 'דלג.י',
    });
    return '$_temp0';
  }

  @override
  String select(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'בחר',
      'female': 'בחרי',
      'other': 'בחר.י',
    });
    return '$_temp0';
  }

  @override
  String backButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'חזרה',
      'female': 'חזרה',
      'other': 'חזרה',
    });
    return '$_temp0';
  }

  @override
  String dialButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'חיוג',
      'female': 'חיוג',
      'other': 'חיוג',
    });
    return '$_temp0';
  }

  @override
  String yourContacts(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אנשי הקשר שלך',
      'female': 'אנשי הקשר שלך',
      'other': 'אנשי הקשר שלך',
    });
    return '$_temp0';
  }

  @override
  String emergencyNumbers(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מספרי חירום',
      'female': 'מספרי חירום',
      'other': 'מספרי חירום',
    });
    return '$_temp0';
  }

  @override
  String phonePageTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אתה לא לבד! אם אתה עכשיו במצוקה נא פנה לאחד הגורמים הרשומים פה',
      'female': 'את לא לבד! אם את עכשיו במצוקה נא פנה לאחד הגורמים הרשומים פה',
      'other': 'הנך לא לבד! אם הנך עכשיו במצוקה נא פנה לאחד הגורמים הרשומים פה',
    });
    return '$_temp0';
  }

  @override
  String get whatsApp => 'ווצאפ';

  @override
  String get thanks => 'תודה';

  @override
  String get trait => 'מעלה';

  @override
  String get link => 'קישור לאתר';

  @override
  String get gallery => 'גלריה';

  @override
  String get camera => 'מצלמה';

  @override
  String addImageButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הוספת תמונה',
      'female': 'הוספת תמונה',
      'other': 'הוספת תמונה',
    });
    return '$_temp0';
  }

  @override
  String addImageTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מהיכן להוסיף את התמונה?',
      'female': 'מהיכן להוסיף את התמונה?',
      'other': 'מהיכן להוסיף את התמונה?',
    });
    return '$_temp0';
  }

  @override
  String feelGoodTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תמונות מעודדות ומחזקות',
      'female': 'תמונות מעודדות ומחזקות',
      'other': 'תמונות מעודדות ומחזקות',
    });
    return '$_temp0';
  }

  @override
  String feelGoodSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'מומלץ להוסיף תמונות מעודדות, מחזקות ומשמחות. תמונות מעוררות חיוך של משפחה, חברים וחברות, תחביבים, טיולים מוצלחים ועוד.',
      'female':
          'מומלץ להוסיף תמונות מעודדות, מחזקות ומשמחות. תמונות מעוררות חיוך של משפחה, חברים וחברות, תחביבים, טיולים מוצלחים ועוד.',
      'other':
          'מומלץ להוסיף תמונות מעודדות, מחזקות ומשמחות. תמונות מעוררות חיוך של משפחה, חברים וחברות, תחביבים, טיולים מוצלחים ועוד.',
    });
    return '$_temp0';
  }

  @override
  String get male => 'אתה';

  @override
  String get notWillingToSay => 'אחר';

  @override
  String get noPermissionAllowedText => 'הרשאה לא ניתנה';

  @override
  String get female => 'את';

  @override
  String get nonBinary => 'לשון מעורבת';

  @override
  String showAll(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ראה הכל',
      'female': 'ראי הכל',
      'other': 'ראה.י הכל',
    });
    return '$_temp0';
  }

  @override
  String notificationPageHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הוסף תזכורת לשימוש ב Living Positively',
      'female': 'הוספי תזכורת לשימוש ב Living Positively',
      'other': 'להוספת תזכורת לשימוש ב Living Positively',
    });
    return '$_temp0';
  }

  @override
  String notificationSetTimeText(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'קבע תזכורת לזמן שנבחר',
      'female': 'קבעי תזכורת לזמן שנבחר',
      'other': 'לקביעת תזכורת לזמן שנבחר',
    });
    return '$_temp0';
  }

  @override
  String notificationShowExampleNotification(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הצג תזכורת לדוגמא',
      'female': 'הצגי תזכורת לדוגמא',
      'other': 'להצגת תזכורת לדוגמא',
    });
    return '$_temp0';
  }

  @override
  String notificationCancelNotification(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לביטול תזכורת נוכחית',
      'female': 'לביטול תזכורת נוכחית',
      'other': 'לביטול תזכורת נוכחית',
    });
    return '$_temp0';
  }

  @override
  String finishedDownloading(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הקובץ שלך ירד',
      'female': 'הקובץ שלך ירד',
      'other': 'הקובץ שלך ירד',
    });
    return '$_temp0';
  }

  @override
  String downloadFailed(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ההורדה נכשלה',
      'female': 'ההורדה נכשלה',
      'other': 'ההורדה נכשלה',
    });
    return '$_temp0';
  }

  @override
  String selectLanguage(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'בחר שפה',
      'female': 'בחרי שפה',
      'other': 'בחר.י שפה',
    });
    return '$_temp0';
  }

  @override
  String get validateEmpty => 'השדה אינו יכול להיות ריק';

  @override
  String get moreVideos => 'סרטונים נוספים';

  @override
  String get noVideosAvailableForLocale => 'אין סרטונים זמינים בשפה שבחרת.';

  @override
  String get confirmResetTitle => 'האם את/ה בטוח/ה?';

  @override
  String get shareRoutineMessage =>
      'הנה התוכנית האישית שלי שנועדה לעזור לשמור עלי. שלחתי לך זאת כי מבחינתי גם לך יש חלק בה. מקווה שזה מתאים לך .אעריך מאוד את הסכמתך לקחת בה חלק בעת הצורך. בהרבה תודה מראש ומצפה לתשובתך.';

  @override
  String get shareOptions => 'אפשרויות שיתוף';

  @override
  String get shareFile => 'שיתוף קובץ של התוכנית האישית';

  @override
  String get shareRoutine => 'שיתוף הודעה כדי לערב תומכים';

  @override
  String get shareEmergency => 'שיתוף הודעה במקרה של משבר';

  @override
  String get shareEmergencyMessage =>
      'אני במצב לא טוב ויש לי צורך בעזרה.אשמח לעזרתך בהפעלת התוכנית האישית שלי. בתודה מראש.';

  @override
  String get informationCollectionDisclaimer =>
      'מידע שנאסף\n\nהאפליקציה אוספת נתונים אנונימיים בלבד, לצורכי ניתוח סטטיסטי ושיפור השירות. נתונים אלה אינם מאפשרים לזהות משתמש מסוים. בין היתר, אנו עשויים לאסוף:\n•נתוני שימוש כלליים באפליקציה (כגון דפים שנצפו, תדירות שימוש).\n• מידע טכני על סוג המכשיר והמערכת (Device type, OS version).\n• נתוני מיקום אנונימיים – נאספים אך ורק לצורכי ניתוח מגמות ושימושים, ללא שיוך למשתמש מזוהה.';

  @override
  String get addingContactDisclaimer =>
      'אנחנו לא שומרים את אנשי הקשר, הם לשימושך האישי.';

  @override
  String notifyOnscheduledNotification(Object time) {
    return 'תזכורת נקבעה לשעה $time';
  }

  @override
  String newTraitOrThanks(Object item) {
    return '$item חדשה';
  }

  @override
  String todoListName(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודו ליסט',
      'female': 'תודו ליסט',
      'other': 'תודו ליסט',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מה יעזור לי כעת, גם צעדים קטנים זאת התקדמות',
      'female': 'מה יעזור לי כעת, גם צעדים קטנים זאת התקדמות',
      'other': 'מה יעזור לי כעת, גם צעדים קטנים זאת התקדמות',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'יש בי חוזקות',
      'female': 'יש בי חוזקות',
      'other': 'יש בי חוזקות',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'בעבר כבר התמודדתי עם אתגרים',
      'female': 'בעבר כבר התמודדתי עם אתגרים',
      'other': 'בעבר כבר התמודדתי עם אתגרים',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מצב הרוח משתנה כמו מזג האוויר שאינו קבוע',
      'female': 'מצב הרוח משתנה כמו מזג האוויר שאינו קבוע',
      'other': 'מצב הרוח משתנה כמו מזג האוויר שאינו קבוע',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'רגשות חולפים ומשתנים',
      'female': 'רגשות חולפים ומשתנים',
      'other': 'רגשות חולפים ומשתנים',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני מסוגל',
      'female': 'אני מסוגלת',
      'other': 'אני מסוגל.ת',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'יש לי כוחות',
      'female': 'יש לי כוחות',
      'other': 'יש לי כוחות',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני לומד להירגע',
      'female': 'אני לומדת להירגע',
      'other': 'אני לומד.ת להירגע',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אחרי הירידות באות העליות',
      'female': 'אחרי הירידות באות העליות',
      'other': 'אחרי הירידות באות העליות',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'זה בסדר לבכות',
      'female': 'זה בסדר לבכות',
      'other': 'זה בסדר לבכות',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה על היש',
      'female': 'תודה על היש',
      'other': 'תודה על היש',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'קח רגע לחייך',
      'female': 'קחי רגע לחייך',
      'other': 'קח/י רגע לחייך',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לזכור לנשום',
      'female': 'לזכור לנשום',
      'other': 'לזכור לנשום',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שגרה מייצרת יציבות',
      'female': 'שגרה מייצרת יציבות',
      'other': 'שגרה מייצרת יציבות',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תנועה מוציאה מיקפאון',
      'female': 'תנועה מוציאה מיקפאון',
      'other': 'תנועה מוציאה מיקפאון',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'זה בסדר לבקש עזרה',
      'female': 'זה בסדר לבקש עזרה',
      'other': 'זה בסדר לבקש עזרה',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'זה בסדר לא להיות בסדר',
      'female': 'זה בסדר לא להיות בסדר',
      'other': 'זה בסדר לא להיות בסדר',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שמור על הקצב שנכון לך',
      'female': 'שמרי על הקצב שנכון לך',
      'other': 'שמור/י על הקצב שנכון לך',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מה נותן לך כוח להמשיך?',
      'female': 'מה נותן לך כוח להמשיך?',
      'other': 'מה נותן לך כוח להמשיך?',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני יכול להתמודד',
      'female': 'אני יכולה להתמודד',
      'other': 'אני יכול/ה להתמודד',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני יכול להרגיע את הגוף והנפש שלי',
      'female': 'אני יכולה להרגיע את הגוף והנפש שלי',
      'other': 'אני יכול/ה להרגיע את הגוף והנפש שלי',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo21(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'יש לי חמלה עצמית',
      'female': 'יש לי חמלה עצמית',
      'other': 'יש לי חמלה עצמית',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo22(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני חזק ומסוגל',
      'female': 'אני חזקה ומסוגלת',
      'other': 'אני חזק/ה ומסוגל/ת',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo23(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני לומד לקבל את עצמי',
      'female': 'אני לומדת לקבל את עצמי',
      'other': 'אני לומד/ת לקבל את עצמי',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo24(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני מקבל את עצמי כמו שאני',
      'female': 'אני מקבלת את עצמי כמו שאני',
      'other': 'אני מקבל/ת את עצמי כמו שאני',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo25(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני לומד להבחין באיכויות שלי',
      'female': 'אני לומדת להבחין באיכויות שלי',
      'other': 'אני לומד/ת להבחין באיכויות שלי',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo26(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני מכיר ברגשותיי ונותן להם לחלוף',
      'female': 'אני מכירה ברגשותיי ונותנת להם לחלוף',
      'other': 'אני מכיר/ה ברגשותיי ונותן/ת להם לחלוף',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo27(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'רגשות משתנים באופן טבעי',
      'female': 'רגשות משתנים באופן טבעי',
      'other': 'רגשות משתנים באופן טבעי',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo28(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'דיבור עצמי חיובי מוביל לביטחון עצמי',
      'female': 'דיבור עצמי חיובי מוביל לביטחון עצמי',
      'other': 'דיבור עצמי חיובי מוביל לביטחון עצמי',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo29(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תרגול יום יומי מביא לשיפור',
      'female': 'תרגול יום יומי מביא לשיפור',
      'other': 'תרגול יום יומי מביא לשיפור',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo30(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אתה לא לבד',
      'female': 'את לא לבד',
      'other': 'את/ה לא לבד',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo31(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אימון יום יומי משפר את מצב הרוח, שווה להמשיך!',
      'female': 'אימון יום יומי משפר את מצב הרוח, שווה להמשיך!',
      'other': 'אימון יום יומי משפר את מצב הרוח, שווה להמשיך!',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo32(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני בעל ערך',
      'female': 'אני בעלת ערך',
      'other': 'אני בעל/ת ערך',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo33(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני מאמין ביכולות שלי',
      'female': 'אני מאמינה ביכולות שלי',
      'other': 'אני מאמין/ה ביכולות שלי',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo34(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני שווה',
      'female': 'אני שווה',
      'other': 'אני שווה',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo35(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני עובד על להרגיש טוב יותר',
      'female': 'אני עובדת על להרגיש טוב יותר',
      'other': 'אני עובד/ת על להרגיש טוב יותר',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo36(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'החיים שווים את זה',
      'female': 'החיים שווים את זה',
      'other': 'החיים שווים את זה',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo37(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מחקרים מראים שהמחשבות משפיעות על הרגשות',
      'female': 'מחקרים מראים שהמחשבות משפיעות על הרגשות',
      'other': 'מחקרים מראים שהמחשבות משפיעות על הרגשות',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo38(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מגיע לי לשמוח',
      'female': 'מגיע לי לשמוח',
      'other': 'מגיע לי לשמוח',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo39(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני יכול ואני אצליח',
      'female': 'אני יכולה ואני אצליח',
      'other': 'אני יכול/ה ואני אצליח',
    });
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo40(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אתה נהדר פשוט כמו שאתה',
      'female': 'את נהדרת פשוט כמו שאת',
      'other': 'אתה/את נהדר/ה פשוט כמו שאתה/את',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה שיש לי רגעים קלים יותר',
      'female': 'תודה שיש לי רגעים קלים יותר',
      'other': 'תודה שיש לי רגעים קלים יותר',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה על ארוחה טובה',
      'female': 'תודה על ארוחה טובה',
      'other': 'תודה על ארוחה טובה',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה שהצלחתי להתאמן',
      'female': 'תודה שהצלחתי להתאמן',
      'other': 'תודה שהצלחתי להתאמן',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה על שיחה טובה',
      'female': 'תודה על שיחה טובה',
      'other': 'תודה על שיחה טובה',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה שישנתי טוב',
      'female': 'תודה שישנתי טוב',
      'other': 'תודה שישנתי טוב',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה שהצלחתי',
      'female': 'תודה שהצלחתי',
      'other': 'תודה שהצלחתי',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה על בילוי עם',
      'female': 'תודה על בילוי עם',
      'other': 'תודה על בילוי עם',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה על מזג האוויר',
      'female': 'תודה על מזג האוויר',
      'other': 'תודה על מזג האוויר',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה שיש לי בית',
      'female': 'תודה שיש לי בית',
      'other': 'תודה שיש לי בית',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה על בריאות טובה',
      'female': 'תודה על בריאות טובה',
      'other': 'תודה על בריאות טובה',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה על משפחה',
      'female': 'תודה על משפחה',
      'other': 'תודה על משפחה',
    });
    return '$_temp0';
  }

  @override
  String thanksListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תודה על חברים',
      'female': 'תודה על חברות',
      'other': 'תודה על חברים',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני יודע לבקש עזרה',
      'female': 'אני יודעת לבקש עזרה',
      'other': 'אני יודע/ת לבקש עזרה',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני חברותי',
      'female': 'אני חברתית',
      'other': 'אני חברותי/ת',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני חבר טוב',
      'female': 'אני חברה טובה',
      'other': 'אני חבר/ה טוב/ה',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני מוכן להשקיע',
      'female': 'אני מוכנה להשקיע',
      'other': 'אני מוכנ/ה להשקיע',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני יצירתי',
      'female': 'אני יצירתית',
      'other': 'אני יצירתי/ת',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני מסוגל',
      'female': 'אני מסוגלת',
      'other': 'אני מסוגל/ת',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'יש לי כוחות',
      'female': 'יש לי כוחות',
      'other': 'יש לי כוחות',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני יודע לנהוג',
      'female': 'אני יודעת לנהוג',
      'other': 'אני יודע/ת לנהוג',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני פתוח להתנסויות',
      'female': 'אני פתוחה להתנסויות',
      'other': 'אני פתוח/ה להתנסויות',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'יש לי כוח התמדה וסבל',
      'female': 'יש לי כוח התמדה וסבל',
      'other': 'יש לי כוח התמדה וסבל',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני סבלני',
      'female': 'אני סבלנית',
      'other': 'אני סבלני/ת',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני ספורטיבי',
      'female': 'אני ספורטיבית',
      'other': 'אני ספורטיבי/ת',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני מסוגל',
      'female': 'אני מסוגלת',
      'other': 'אני מסוגל/ת',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני טוב בארגון',
      'female': 'אני טובה בארגון',
      'other': 'אני טוב/ה בארגון',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני יודע לנגן',
      'female': 'אני יודעת לנגן',
      'other': 'אני יודע/ת לנגן',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני יודע לבשל',
      'female': 'אני יודעת לבשל',
      'other': 'אני יודע/ת לבשל',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני אבא טוב',
      'female': 'אני אמא טובה',
      'other': 'אני הורה טוב',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני חזק',
      'female': 'אני חזקה',
      'other': 'אני חזק/ה',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני חכם',
      'female': 'אני חכמה',
      'other': 'אני חכם/ה',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני יפה',
      'female': 'אני יפה',
      'other': 'אני יפה',
    });
    return '$_temp0';
  }

  @override
  String traitsListNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אני מצחיק',
      'female': 'אני מצחיקה',
      'other': 'אני מצחיק/ה',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'צפייה בחדשות',
      'female': 'צפייה בחדשות',
      'other': 'צפייה בחדשות',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מתח עם הקרובים לי',
      'female': 'מתח עם הקרובים לי',
      'other': 'מתח עם הקרובים לי',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ריבים או וויכוחים מרובים',
      'female': 'ריבים או וויכוחים מרובים',
      'other': 'ריבים או וויכוחים מרובים',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'בעבר כבר התמודדתי עם אתגרים',
      'female': 'בעבר כבר התמודדתי עם אתגרים',
      'other': 'בעבר כבר התמודדתי עם אתגרים',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'עוול, אי צדק וחוסר הגינות',
      'female': 'עוול, אי צדק וחוסר הגינות',
      'other': 'עוול, אי צדק וחוסר הגינות',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'חוסר תעסוקה',
      'female': 'חוסר תעסוקה',
      'other': 'חוסר תעסוקה',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אובדן',
      'female': 'אובדן',
      'other': 'אובדן',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'פיטורין, אבטלה',
      'female': 'פיטורין, אבטלה',
      'other': 'פיטורין, אבטלה',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'עומס יתר',
      'female': 'עומס יתר',
      'other': 'עומס יתר',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תחושה של מחסור כלכלי',
      'female': 'תחושה של מחסור כלכלי',
      'other': 'תחושה של מחסור כלכלי',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לחץ, ריבוי משימות',
      'female': 'לחץ, ריבוי משימות',
      'other': 'לחץ, ריבוי משימות',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'דברים לא גמורים',
      'female': 'דברים לא גמורים',
      'other': 'דברים לא גמורים',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תזונה לא סדירה',
      'female': 'תזונה לא סדירה',
      'other': 'תזונה לא סדירה',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מלחמה',
      'female': 'מלחמה',
      'other': 'מלחמה',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'סגר',
      'female': 'סגר',
      'other': 'סגר',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מחסור בשינה',
      'female': 'מחסור בשינה',
      'other': 'מחסור בשינה',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מוות של קרובים',
      'female': 'מוות של קרובים',
      'other': 'מוות של קרובים',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אובדן של יציבות ושגרה',
      'female': 'אובדן של יציבות ושגרה',
      'other': 'אובדן של יציבות ושגרה',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'כשאין לי זמן להוציא אנרגיה ואגרסיות',
      'female': 'כשאין לי זמן להוציא אנרגיה ואגרסיות',
      'other': 'כשאין לי זמן להוציא אנרגיה ואגרסיות',
    });
    return '$_temp0';
  }

  @override
  String difficultEventsListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'עומס גירויים, חוסר וודאות ומעברים',
      'female': 'עומס גירויים, חוסר וודאות ומעברים',
      'other': 'עומס גירויים, חוסר וודאות ומעברים',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שיעזרו לי עם פרוייקטים משותפים שנותנים משמעות',
      'female': 'שיעזרו לי עם פרוייקטים משותפים שנותנים משמעות',
      'other': 'שיעזרו לי עם פרוייקטים משותפים שנותנים משמעות',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לברר מה קורה איתי ולחשוב איתי על דרך ההתמודדות',
      'female': 'לברר מה קורה איתי ולחשוב איתי על דרך ההתמודדות',
      'other': 'לברר מה קורה איתי ולחשוב איתי על דרך ההתמודדות',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שיזמינו אותי לעשייה משותפת',
      'female': 'שיזמינו אותי לעשייה משותפת',
      'other': 'שיזמינו אותי לעשייה משותפת',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שיבקרו אותי',
      'female': 'שיבקרו אותי',
      'other': 'שיבקרו אותי',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שיזמינו אותי לנגינה או משחק',
      'female': 'שיזמינו אותי לנגינה או משחק',
      'other': 'שיזמינו אותי לנגינה או משחק',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שיזמינו אותי לפעילות משותפת',
      'female': 'שיזמינו אותי לפעילות משותפת',
      'other': 'שיזמינו אותי לפעילות משותפת',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שיעודדו אותי לישון מספיק',
      'female': 'שיעודדו אותי לישון מספיק',
      'other': 'שיעודדו אותי לישון מספיק',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לא להישאר לבד',
      'female': 'לא להישאר לבד',
      'other': 'לא להישאר לבד',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שיזמינו אותי לארוחה',
      'female': 'שיזמינו אותי לארוחה',
      'other': 'שיזמינו אותי לארוחה',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לקבל אוכל מזין',
      'female': 'לקבל אוכל מזין',
      'other': 'לקבל אוכל מזין',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לבקש ממישהו שאני סומך עליו להישאר איתי',
      'female': 'לבקש ממישהו שאני סומכת עליו להישאר איתי',
      'other': 'לבקש ממישהו שאני סומך.ת עליו להישאר איתי',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שיזמינו אותי להליכה או טיול או לפעילות גופנית',
      'female': 'שיזמינו אותי להליכה או טיול או לפעילות גופנית',
      'other': 'שיזמינו אותי להליכה או טיול או לפעילות גופנית',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'להימנע ממקומות שגורמים לי להרגיש לא בטוח',
      'female': 'להימנע ממקומות שגורמים לי להרגיש לא בטוחה',
      'other': 'להימנע ממקומות שגורמים לי להרגיש לא בטוח',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'להשאיר אצלי כמות קטנה בלבד של התרופות שלי',
      'female': 'להשאיר אצלי כמות קטנה בלבד של התרופות שלי',
      'other': 'להשאיר אצלי כמות קטנה בלבד של התרופות שלי',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ואת השאר להפקיד בידי מישהו שאני סומך עליו',
      'female': 'ואת השאר להפקיד בידי מישהו שאני סומכת עליו',
      'other': 'ואת השאר להפקיד בידי מישהו שאני סומך/ת עליו/ה',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לבקש ממישהו אחר להרחיק ממני דברים שעלולים לשמש אותי לפגוע בעצמי',
      'female':
          'לבקש ממישהי אחרת להרחיק ממני דברים שעלולים לשמש אותי לפגוע בעצמי',
      'other':
          'לבקש ממישהו אחר להרחיק ממני דברים שעלולים לשמש אותי לפגוע בעצמי',
    });
    return '$_temp0';
  }

  @override
  String makeSaferListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שישאלו אותי',
      'female': 'שישאלו אותי',
      'other': 'שישאלו אותי',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מיינדפולנס',
      'female': 'מיינדפולנס',
      'other': 'מיינדפולנס',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'זמן זוגי/חברתי קבוע בשבוע',
      'female': 'זמן זוגי/חברתי קבוע בשבוע',
      'other': 'זמן זוגי/חברתי קבוע בשבוע',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'רשימת חוזקות ומעלות',
      'female': 'רשימת חוזקות ומעלות',
      'other': 'רשימת חוזקות ומעלות',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'יומן הכרת תודה',
      'female': 'יומן הכרת תודה',
      'other': 'יומן הכרת תודה',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'להגיד מתי יש לי פנות להקשיב',
      'female': 'להגיד מתי יש לי פנות להקשיב',
      'other': 'להגיד מתי יש לי פנות להקשיב',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'להאט ולהשתדל לא להעמיס עלי יותר מידי',
      'female': 'להאט ולהשתדל לא להעמיס עלי יותר מידי',
      'other': 'להאט ולהשתדל לא להעמיס עלי יותר מידי',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'להתנתק ממשימות היום יום וממסכים',
      'female': 'להתנתק ממשימות היום יום וממסכים',
      'other': 'להתנתק ממשימות היום יום וממסכים',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לראות אור שמש',
      'female': 'לראות אור שמש',
      'other': 'לראות אור שמש',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לצאת לטבע',
      'female': 'לצאת לטבע',
      'other': 'לצאת לטבע',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מנוחה',
      'female': 'מנוחה',
      'other': 'מנוחה',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'זמן שקט לעצמי',
      'female': 'זמן שקט לעצמי',
      'other': 'זמן שקט לעצמי',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לצחצח שיניים כדי לקבל טעם רענן בפה',
      'female': 'לצחצח שיניים כדי לקבל טעם רענן בפה',
      'other': 'לצחצח שיניים כדי לקבל טעם רענן בפה',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'או לקחת מסטיק',
      'female': 'או לקחת מסטיק',
      'other': 'או לקחת מסטיק',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לקבל חיבוק ממישהו שאני סומך עליו',
      'female': 'לקבל חיבוק ממישהי שאני סומכת עליה',
      'other': 'לקבל חיבוק ממישהו/מישהי שאני סומך/ת עליהם',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לומר לעצמי: \'אני חשוב\'',
      'female': 'לומר לעצמי: \'אני חשובה\'',
      'other': 'לומר לעצמי: \'אני חשוב.ה\'',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'יש אנשים שאוהבים אותי',
      'female': 'יש אנשים שאוהבות אותי',
      'other': 'יש אנשים שאוהבים אותי',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'להתמקד בנשימה / בתחושות הגופניות',
      'female': 'להתמקד בנשימה / בתחושות הגופניות',
      'other': 'להתמקד בנשימה / בתחושות הגופניות',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לקחת הפסקה על ידי שינוי המיקום שלי (למשל, לעבור לחדר אחר בבית)',
      'female':
          'לקחת הפסקה על ידי שינוי המיקום שלי (למשל, לעבור לחדר אחר בבית)',
      'other': 'לקחת הפסקה על ידי שינוי המיקום שלי (למשל, לעבור לחדר אחר בבית)',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לצאת להליכה קצרה בחוץ',
      'female': 'לצאת להליכה קצרה בחוץ',
      'other': 'לצאת להליכה קצרה בחוץ',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לצאת לנשום קצת אוויר צח (מחוץ לבית או אפילו מהמרפסת)',
      'female': 'לצאת לנשום קצת אוויר צח (מחוץ לבית או אפילו מהמרפסת)',
      'other': 'לצאת לנשום קצת אוויר צח (מחוץ לבית או אפילו מהמרפסת)',
    });
    return '$_temp0';
  }

  @override
  String feelBetterListNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לצפות בקליפים',
      'female': 'לצפות בקליפים',
      'other': 'לצפות בקליפים',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מחשבות אובדניות',
      'female': 'מחשבות אובדניות',
      'other': 'מחשבות אובדניות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ביטחון עצמי נמוך',
      'female': 'ביטחון עצמי נמוך',
      'other': 'ביטחון עצמי נמוך',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תחושה שלא אכפת ממני',
      'female': 'תחושה שלא אכפת ממני',
      'other': 'תחושה שלא אכפת ממני',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'רצון להתחפר ולהתחבא או להיעלם',
      'female': 'רצון להתחפר ולהתחבא או להיעלם',
      'other': 'רצון להתחפר ולהתחבא או להיעלם',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'עייפות קשה',
      'female': 'עייפות קשה',
      'other': 'עייפות קשה',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ירידה בתפקוד',
      'female': 'ירידה בתפקוד',
      'other': 'ירידה בתפקוד',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'חוסר או ירידה בכוחות',
      'female': 'חוסר או ירידה בכוחות',
      'other': 'חוסר או ירידה בכוחות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'חרדות',
      'female': 'חרדות',
      'other': 'חרדות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מיניות מופחתת',
      'female': 'מיניות מופחתת',
      'other': 'מיניות מופחתת',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אפאטיות או אדישות',
      'female': 'אפאטיות או אדישות',
      'other': 'אפאטיות או אדישות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'רגישות יתר',
      'female': 'רגישות יתר',
      'other': 'רגישות יתר',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'האשמה עצמית',
      'female': 'האשמה עצמית',
      'other': 'האשמה עצמית',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'פזרנות והעלאת מינון הקניות',
      'female': 'פזרנות והעלאת מינון הקניות',
      'other': 'פזרנות והעלאת מינון הקניות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הזנחה עצמית',
      'female': 'הזנחה עצמית',
      'other': 'הזנחה עצמית',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'ביטחון יתר',
      'female': 'ביטחון יתר',
      'other': 'ביטחון יתר',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'לעשות את המינימום של המינימום - וגם זה במאמץ רב',
      'female': 'לעשות את המינימום של המינימום - וגם זה במאמץ רב',
      'other': 'לעשות את המינימום של המינימום - וגם זה במאמץ רב',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תפקוד ירוד',
      'female': 'תפקוד ירוד',
      'other': 'תפקוד ירוד',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מוח רץ',
      'female': 'מוח רץ',
      'other': 'מוח רץ',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מחשבות מתרוצצות ומהירות',
      'female': 'מחשבות מתרוצצות ומהירות',
      'other': 'מחשבות מתרוצצות ומהירות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'חוסר ביטחון',
      'female': 'חוסר ביטחון',
      'other': 'חוסר ביטחון',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הססנות',
      'female': 'הססנות',
      'other': 'הססנות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo21(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מחשבות איטיות ומבולבלות',
      'female': 'מחשבות איטיות ומבולבלות',
      'other': 'מחשבות איטיות ומבולבלות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo22(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מוחצנות מוגברת',
      'female': 'מוחצנות מוגברת',
      'other': 'מוחצנות מוגברת',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo23(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'השתבללות',
      'female': 'השתבללות',
      'other': 'השתבללות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo24(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'התכנסות',
      'female': 'התכנסות',
      'other': 'התכנסות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo25(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'הסתגרות',
      'female': 'הסתגרות',
      'other': 'הסתגרות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo26(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'מילוי כל חלל הזמן',
      'female': 'מילוי כל חלל הזמן',
      'other': 'מילוי כל חלל הזמן',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo27(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'חשש מזמן לבד',
      'female': 'חשש מזמן לבד',
      'other': 'חשש מזמן לבד',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo28(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'חשש מריק',
      'female': 'חשש מריק',
      'other': 'חשש מריק',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo29(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שימוש רב במדיות שונות',
      'female': 'שימוש רב במדיות שונות',
      'other': 'שימוש רב במדיות שונות',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo30(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'יותר כאבי ראש',
      'female': 'יותר כאבי ראש',
      'other': 'יותר כאבי ראש',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo31(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'תיאבון יתר',
      'female': 'תיאבון יתר',
      'other': 'תיאבון יתר',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo32(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'שינה לא סדירה',
      'female': 'שינה לא סדירה',
      'other': 'שינה לא סדירה',
    });
    return '$_temp0';
  }

  @override
  String distractionsListNo33(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'נדודי שינה או שינה מעוטה',
      'female': 'נדודי שינה או שינה מעוטה',
      'other': 'נדודי שינה או שינה מעוטה',
    });
    return '$_temp0';
  }

  @override
  String get aboutPage1 =>
      'Living Positively היא פלטפורמה לחיזוק החוסן הנפשי, להתמודדות עם מצבי משבר אובדניים, לעידוד ניהול עצמי, ליצירת רשת תמיכה אישית וחיים איכותיים וטובים יותר. מבית היוצר של עמותת קלאבהאוס עמית. \n\nבאפליקציה זו נעשה שימוש בכלים מעולם הפסיכולוגיה החיובית, ניהול מחלה והחלמה וחקר מניעת האובדנות.\n\nהתוכנית האישית משלבת את תוכנית המנע להישנות (Relapse Prevention Plan) מקורס IMR ניהול מחלה והחלמה (Illness Management and Recovery) יחד עם תוכנית הביטחון (Safety Plan) של סטנלי ובראון.\n\nהמושג \"תודו ליסט\" ניתן לנו ע\"י  ד\"ר שירלי יובל יאיר, עבור יומן התודה ומפורסם כאן  באישורה.\n\nהמוצר בבנייה משותפת והפרייה הדדית עם החממה החברתית של הטכניון בעזרת צוות הפיתוח ';

  @override
  String get aboutPage2 =>
      'האפליקציה נועדה לשימוש אישי למטרות שיפור החוסן הנפשי וקבלת תמיכה ועזרה בעת הצורך במצבי משבר.\n\nהאפליקציה אינה יכולה, ואינה מיועדת, להחליף גורמים מקצועיים בתחום בריאות הנפש. היא לא מחליפה אבחון מקצועי ולא טיפול פסיכותרפי. מטרת הכלים המשולבים בה היא לסייע לך ולסביבה לשפר את איכות החיים ולתמוך בעת משבר.\n\nניתן להשתמש באפליקציה לצורך עזרה עצמית, ו/או לשלב אותה כחלק מתהליך טיפולי מול גורם מקצועי. אם יש לך צורך באבחון או בטיפול אישי, חשוב להתייעץ עם גורם טיפולי מקצועי. השימוש באפליקציה הינו באחריותך האישית.\n\nלתשומת ליבך הנתונים האישיים שלך באפליקציה נשמרים במכשיר הטלפון רק עבורך! האפליקציה אינה אוספת או מעבירה מידע אישי, ולעולם לא ייעשה בו שימוש. לך האפשרות להחליט במה לשתף מתוכה, למשל את התוכנית האישית שמומלץ לשתף עם הסביבה החברתית הקרובה ו/או גורמים טיפוליים. אם אינך מסכימ/ה עם תנאי השימוש נא להסיר את האפליקציה.';

  @override
  String get aboutTitle1 => 'אודות ותודות';

  @override
  String get aboutTitle2 => 'תנאי שימוש ופרטיות';

  @override
  String aboutVersionLabel(String version) {
    return 'גרסת האפליקציה Living Positively: $version';
  }

  @override
  String locationSelect(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'אנא בחר את  מיקומך:',
      'female': 'אנא בחרי את מיקומך:',
      'other': 'אנא בחר.י את מיקומך:',
    });
    return '$_temp0';
  }

  @override
  String get disclaimerText =>
      'האפליקציה נועדה לשימוש אישי למטרות שיפור החוסן הנפשי וקבלת תמיכה ועזרה בעת הצורך במצבי משבר.\n\nהאפליקציה אינה יכולה, ואינה מיועדת, להחליף גורמים מקצועיים בתחום בריאות הנפש. היא לא מחליפה אבחון מקצועי ולא טיפול פסיכותרפי. מטרת הכלים המשולבים בה היא לסייע לך ולסביבה לשפר את איכות החיים ולתמוך בעת משבר.\n\nניתן להשתמש באפליקציה לצורך עזרה עצמית, ו/או לשלב אותה כחלק מתהליך טיפולי מול גורם מקצועי. אם יש לך צורך באבחון או בטיפול אישי, חשוב להתייעץ עם גורם טיפולי מקצועי. השימוש באפליקציה הינו באחריותך האישית.\n\nלתשומת ליבך: הנתונים האישיים שלך באפליקציה נשמרים במכשיר הטלפון רק עבורך! האפליקציה אינה אוספת או מעבירה מידע אישי, ולעולם לא ייעשה בו שימוש. לך האפשרות להחליט במה לשתף מתוכה, למשל את התוכנית האישית שמומלץ לשתף עם הסביבה החברתית הקרובה ו/או גורמים טיפוליים.\n\nאם אינך מסכימ/ה עם תנאי השימוש נא להסיר את האפליקציה, במידה והנ\"ל מוסכם עליך נא ללחוץ על כפתור \"אישור\"';

  @override
  String get shareButtonText => 'שיתוף';

  @override
  String get contactUs => 'יצירת קשר';

  @override
  String get shareAppMessage =>
      'הנה אפליקציית LP(Living Positively) שאני עושה בה שימוש ומומלצת, אולי תהיה לעזר גם עבורך.';

  @override
  String locationDisclaimer(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male':
          'האפליקציה משתמשת במיקום שלך אך ורק כדי להתאים את מספרי החירום למיקומך.',
      'female':
          'האפליקציה משתמשת במיקום שלך אך ורק כדי להתאים את מספרי החירום למיקומך.',
      'other':
          'האפליקציה משתמשת במיקום שלך אך ורק כדי להתאים את מספרי החירום למיקומך.',
    });
    return '$_temp0';
  }

  @override
  String callFailedMessage(String number) {
    return 'לא ניתן לחייג את $number';
  }

  @override
  String get couldNotOpenApp => 'לא ניתן לפתוח את האפליקציה';

  @override
  String get copyNumberAction => 'העתק מספר';

  @override
  String get numberCopiedToast => 'המספר הועתק';

  @override
  String emergencyCountryFallback(String country) {
    return 'מוצגים מספרי חירום ברירת מחדל ($country). ייתכן שלא יפעלו ממיקומך.';
  }

  @override
  String get menuTooltip => 'תפריט';

  @override
  String get addItemTooltip => 'הוספה';

  @override
  String get downloadPlanTooltip => 'הורדת התוכנית';

  @override
  String get sharePlanTooltip => 'שיתוף התוכנית';

  @override
  String get refreshQuoteTooltip => 'ציטוט חדש';

  @override
  String get dismissQuoteTooltip => 'סגירת הציטוט';

  @override
  String callContactTooltip(String contact) {
    return 'התקשרות אל $contact';
  }

  @override
  String get editEntryTooltip => 'עריכת רשומה';

  @override
  String get deleteEntryTooltip => 'מחיקת רשומה';

  @override
  String get sosTooltip => 'SOS – אנשי קשר בשעת חירום';

  @override
  String get asyncLoadingLabel => 'טוען';

  @override
  String get asyncErrorMessage => 'משהו השתבש';

  @override
  String get asyncRetryButton => 'ניסיון חוזר';
}
