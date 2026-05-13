// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get language => 'العربية';

  @override
  String get textDirection => 'rtl';

  @override
  String pageHomeWelcomeGender(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أهلاً وسهلاً!',
        'female': 'أهلاً وسهلاً!',
        'other': 'أهلاً وسهلاً!',
      },
    );
    return '$_temp0';
  }

  @override
  String greetings(Object username) {
    return 'مرحبًا، $username';
  }

  @override
  String otherSuggestions(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'اقتراحات أخرى',
        'female': 'اقتراحات أخرى',
        'other': 'اقتراحات أخرى',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionRestartGreeting(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'مرحبًا بك في Living Positively',
        'female': 'مرحبًا بكِ في Living Positively',
        'other': 'مرحبًا في Living Positively',
      },
    );
    return '$_temp0';
  }

  @override
  String addFormPageTemplateAdd(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إضافة',
        'female': 'إضافة',
        'other': 'إضافة',
      },
    );
    return '$_temp0';
  }

  @override
  String addThanksFormThank(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا',
        'female': 'شكرًا',
        'other': 'شكرًا',
      },
    );
    return '$_temp0';
  }

  @override
  String addFormEdit(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تعديل',
        'female': 'تعديل',
        'other': 'تعديل',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginLoginTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تسجيل الدخول إلى Living Positively',
        'female': 'تسجيل الدخول إلى Living Positively',
        'other': 'تسجيل الدخول إلى Living Positively',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginLoginButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تسجيل الدخول',
        'female': 'تسجيل الدخول',
        'other': 'تسجيل الدخول',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginLoginGoogleButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تسجيل الدخول باستخدام جوجل',
        'female': 'تسجيل الدخول باستخدام جوجل',
        'other': 'تسجيل الدخول باستخدام جوجل',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginLoginNoAccount(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ليس لديك حساب حتى الآن؟',
        'female': 'ليس لديكِ حساب حتى الآن؟',
        'other': 'ليس لديك حساب حتى الآن؟',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginLoginToSignup(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إنشاء حساب',
        'female': 'إنشاء حساب',
        'other': 'إنشاء حساب',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginLoginSkip(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تخطي إنشاء الحساب',
        'female': 'تخطي إنشاء الحساب',
        'other': 'تخطي إنشاء الحساب',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginSignUpTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إنشاء حساب في Living Positively',
        'female': 'إنشاء حساب في Living Positively',
        'other': 'إنشاء حساب في Living Positively',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginSignUpButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إنشاء حساب',
        'female': 'إنشاء حساب',
        'other': 'إنشاء حساب',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginSignUpExists(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'هل لديك حساب بالفعل؟',
        'female': 'هل لديكِ حساب بالفعل؟',
        'other': 'هل لديك حساب بالفعل؟',
      },
    );
    return '$_temp0';
  }

  @override
  String signupLoginSignUpToLogin(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تسجيل الدخول',
        'female': 'تسجيل الدخول',
        'other': 'تسجيل الدخول',
      },
    );
    return '$_temp0';
  }

  @override
  String personalPlanPageMyPlan(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'خطتي',
        'female': 'خطتي',
        'other': 'خطتي',
      },
    );
    return '$_temp0';
  }

  @override
  String personalPlanPageAllPlan(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لرؤية خطتي',
        'female': 'لرؤية خطتي',
        'other': 'لرؤية خطتي',
      },
    );
    return '$_temp0';
  }

  @override
  String personalPlanPageTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'خطتي الشخصية',
        'female': 'خطتي الشخصية',
        'other': 'خطتي الشخصية',
      },
    );
    return '$_temp0';
  }

  @override
  String personalPlanPageStartedDownload(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'بدأ التنزيل',
        'female': 'بدأ التنزيل',
        'other': 'بدأ التنزيل',
      },
    );
    return '$_temp0';
  }

  @override
  String personalPlanPageFinishDownload(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تم حفظ خطتك في \"التنزيلات\"',
        'female': 'تم حفظ خطتكِ في \"التنزيلات\"',
        'other': 'تم حفظ خطتك في \"التنزيلات\"',
      },
    );
    return '$_temp0';
  }

  @override
  String personalPlanPageFinish(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إنهاء',
        'female': 'إنهاء',
        'other': 'إنهاء',
      },
    );
    return '$_temp0';
  }

  @override
  String personalPlanPageHasFilled(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لتحديث الخطة',
        'female': 'لتحديث الخطة',
        'other': 'لتحديث الخطة',
      },
    );
    return '$_temp0';
  }

  @override
  String personalPlanPageDidNotFill(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لملء الخطة',
        'female': 'لملء الخطة',
        'other': 'لملء الخطة',
      },
    );
    return '$_temp0';
  }

  @override
  String homePagePersonalPlanMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'خطتي',
        'female': 'خطتي',
        'other': 'خطتي',
      },
    );
    return '$_temp0';
  }

  @override
  String homePagePersonalPlanSecondaryTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الأشياء التي ستجعلني أشعر بالتحسن الآن',
        'female': 'الأشياء التي ستجعلني أشعر بالتحسن الآن',
        'other': 'الأشياء التي ستجعلني أشعر بالتحسن الآن',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageTraitsMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'قائمة الصفات',
        'female': 'قائمة الصفات',
        'other': 'قائمة الصفات',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageTraitsSecondaryTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ما أجيده، يُنصح بقراءته مرة واحدة في اليوم',
        'female': 'ما أجيده، يُنصح بقراءته مرة واحدة في اليوم',
        'other': 'ما أجيده، يُنصح بقراءته مرة واحدة في اليوم',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageThanksMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'مجلة الامتنان',
        'female': 'مجلة الامتنان',
        'other': 'مجلة الامتنان',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageThanksSecondaryTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ما أنا ممتنّ له',
        'female': 'ما أنا ممتنّة له',
        'other': 'ما أنا ممتنّ له',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageThankyouPopup(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'هذه هي الطريقة لتعزيز مشاعر السعادة لديك.\nالتوصية أن تكون شاكرًا لخمسة أشياء على الأقل كل يوم.\nاستمر في العمل الجيد، وسنلتقي مرة أخرى غدًا.',
        'female':
            'هذه هي الطريقة لتعزيز مشاعر السعادة لديكِ.\nالتوصية أن تكوني شاكرةً لخمسة أشياء على الأقل كل يوم.\nاستمري في العمل الجيد، وسنلتقي مرة أخرى غدًا.',
        'other':
            'هذه هي الطريقة لتعزيز مشاعر السعادة لديك.\nالتوصية أن تكون شاكرًا لخمسة أشياء على الأقل كل يوم.\nاستمر في العمل الجيد، وسنلتقي مرة أخرى غدًا.',
      },
    );
    return '$_temp0';
  }

  @override
  String homePagePositiveTraitPopup(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'تصفّح قائمة صفاتك الإيجابية كل يوم.\nلا تتردد في إضافة المزيد — أضف بكل ثقة.',
        'female':
            'تصفّحي قائمة صفاتكِ الإيجابية كل يوم.\nلا تترددي في إضافة المزيد — أضيفي بكل ثقة.',
        'other':
            'تصفّح قائمة صفاتك الإيجابية كل يوم.\nلا تتردد في إضافة المزيد — أضف بكل ثقة.',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageGreetings(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'سعداء بعودتك 😊',
        'female': 'سعداء بعودتكِ 😊',
        'other': 'سعداء بعودتك 😊',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageAbout(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'عن التطبيق',
        'female': 'عن التطبيق',
        'other': 'عن التطبيق',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageWellnessTools(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أدوات العافية',
        'female': 'أدوات العافية',
        'other': 'أدوات العافية',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageFeelGood(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أشعر أنني بحالة جيدة',
        'female': 'أشعر أنني بحالة جيدة',
        'other': 'أشعر أنني بحالة جيدة',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageSync(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'مزامنة الحسابات',
        'female': 'مزامنة الحسابات',
        'other': 'مزامنة الحسابات',
      },
    );
    return '$_temp0';
  }

  @override
  String homePageBack(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إغلاق',
        'female': 'إغلاق',
        'other': 'إغلاق',
      },
    );
    return '$_temp0';
  }

  @override
  String sharePageHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'رائع!',
        'female': 'رائع!',
        'other': 'رائع!',
      },
    );
    return '$_temp0';
  }

  @override
  String sharePageSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'لقد أنشأت دليلاً يساعدك خلال اللحظات الصعبة!\nلنستكشف المزيد من أدوات الدعم الذاتي والمرونة النفسية',
        'female':
            'لقد أنشأتِ دليلاً يساعدكِ خلال اللحظات الصعبة!\nلنستكشف المزيد من أدوات الدعم الذاتي والمرونة النفسية',
        'other':
            'لقد أنشأت دليلاً يساعدك خلال اللحظات الصعبة!\nلنستكشف المزيد من أدوات الدعم الذاتي والمرونة النفسية',
      },
    );
    return '$_temp0';
  }

  @override
  String sharePageMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'يمكنك الآن مشاركة خطتك مع الأشخاص المقربين منك، أو تنزيلها على هاتفك',
        'female':
            'يمكنكِ الآن مشاركة خطتكِ مع الأشخاص المقربين منكِ، أو تنزيلها على هاتفكِ',
        'other':
            'يمكنك الآن مشاركة خطتك مع الأشخاص المقربين منك، أو تنزيلها على هاتفك',
      },
    );
    return '$_temp0';
  }

  @override
  String sharePageFinishButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'انتهيت!',
        'female': 'انتهيت!',
        'other': 'انتهيت!',
      },
    );
    return '$_temp0';
  }

  @override
  String sharePageShareTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'كيف تريد مشاركة خطتك؟',
        'female': 'كيف تريدين مشاركة خطتكِ؟',
        'other': 'كيف تريد مشاركة خطتك؟',
      },
    );
    return '$_temp0';
  }

  @override
  String sharePageEmergencySendButtonText(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'طارئ',
        'female': 'طارئ',
        'other': 'طارئ',
      },
    );
    return '$_temp0';
  }

  @override
  String sharePageRoutineSendButtonText(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'روتين',
        'female': 'روتين',
        'other': 'روتين',
      },
    );
    return '$_temp0';
  }

  @override
  String userSettingsTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تحديث الإعدادات',
        'female': 'تحديث الإعدادات',
        'other': 'تحديث الإعدادات',
      },
    );
    return '$_temp0';
  }

  @override
  String userSettingsHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إعدادات الحساب',
        'female': 'إعدادات الحساب',
        'other': 'إعدادات الحساب',
      },
    );
    return '$_temp0';
  }

  @override
  String userSettingsReset(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إعادة ضبط البيانات',
        'female': 'إعادة ضبط البيانات',
        'other': 'إعادة ضبط البيانات',
      },
    );
    return '$_temp0';
  }

  @override
  String userSettingsName(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'كيف تحب أن نناديك؟ (يمكنك استخدام لقب)',
        'female': 'كيف تحبين أن نناديكِ؟ (يمكنكِ استخدام لقب)',
        'other': 'كيف تحب أن نناديك؟ (يمكنك استخدام لقب)',
      },
    );
    return '$_temp0';
  }

  @override
  String userSettingsGender(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'كيف تفضل أن نخاطبك؟',
        'female': 'كيف تفضلين أن نخاطبك؟',
        'other': 'ما الصيغة المفضلة للمخاطبة؟',
      },
    );
    return '$_temp0';
  }

  @override
  String userSettingsAge(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ما هو عمرك؟',
        'female': 'ما هو عمركِ؟',
        'other': 'ما هو عمرك؟',
      },
    );
    return '$_temp0';
  }

  @override
  String settings(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إعدادات',
        'female': 'إعدادات',
        'other': 'إعدادات',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ما الذي يبقيني آمنًا؟',
        'female': 'ما الذي يبقيني آمنة؟',
        'other': 'ما الذي يبقيني آمنًا؟',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageSubTitle1(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'Living Positively - من أجل السعادة وتعزيز المرونة وتحسين نوعية الحياة',
        'female':
            'Living Positively - من أجل السعادة وتعزيز المرونة وتحسين نوعية الحياة',
        'other':
            'Living Positively - من أجل السعادة وتعزيز المرونة وتحسين نوعية الحياة',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageSubTitle2(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أدوات ممتازة للدعم الذاتي وتطوير المرونة النفسية.',
        'female': 'أدوات ممتازة للدعم الذاتي وتطوير المرونة النفسية.',
        'other': 'أدوات ممتازة للدعم الذاتي وتطوير المرونة النفسية.',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormFirstPageSkip(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تخطي',
        'female': 'تخطي',
        'other': 'تخطي',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormLastPageSkip(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تخطي الاستبيان',
        'female': 'تخطي الاستبيان',
        'other': 'تخطي الاستبيان',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormLastPageMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'خطتي الشخصية',
        'female': 'خطتي الشخصية',
        'other': 'خطتي الشخصية',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormLastPageSubTitle1(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'أنت مدعوّ لإنشاء خطة شخصية تقدم الدعم خلال اللحظات الصعبة، لك ولمن حولك.',
        'female':
            'أنتِ مدعوّة لإنشاء خطة شخصية تقدم الدعم خلال اللحظات الصعبة، لكِ ولمن حولكِ.',
        'other':
            'أنت مدعوّ لإنشاء خطة شخصية تقدم الدعم خلال اللحظات الصعبة، لك ولمن حولك.',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormLastPageSubTitle2(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'يُنصح بقضاء بضع دقائق الآن للتعامل بشكل أفضل مع التحديات المستقبلية.',
        'female':
            'يُنصح بقضاء بضع دقائق الآن للتعامل بشكل أفضل مع التحديات المستقبلية.',
        'other':
            'يُنصح بقضاء بضع دقائق الآن للتعامل بشكل أفضل مع التحديات المستقبلية.',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormSecondPageMainTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'هيا نتعرف عليك!',
        'female': 'هيا نتعرف عليكِ!',
        'other': 'هيا نتعرف عليك!',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormSecondPageSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'أهلاً! سعداء بوجودك هنا!\nنودّ أن نتعرف عليك بشكل أفضل حتى نتمكن من دعمك.',
        'female':
            'أهلاً! سعداء بوجودكِ هنا!\nنودّ أن نتعرف عليكِ بشكل أفضل حتى نتمكن من دعمكِ.',
        'other':
            'أهلاً! سعداء بوجودك هنا!\nنودّ أن نتعرف عليك بشكل أفضل حتى نتمكن من دعمك.',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تذكير بالمحفزات الشائعة وعوامل التصعيد',
        'female': 'تذكير بالمحفزات الشائعة وعوامل التصعيد',
        'other': 'تذكير بالمحفزات الشائعة وعوامل التصعيد',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'العوامل والأحداث التي شكّلت تحديًا بالنسبة لي في الماضي',
        'female': 'العوامل والأحداث التي شكّلت تحديًا بالنسبة لي في الماضي',
        'other': 'العوامل والأحداث التي شكّلت تحديًا بالنسبة لي في الماضي',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تحتاج إلى مساعدة؟ إليك بعض الاقتراحات',
        'female': 'تحتاجين إلى مساعدة؟ إليكِ بعض الاقتراحات',
        'other': 'بحاجة إلى مساعدة؟ هذه بعض الاقتراحات',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'انقر لإضافة الخيارات التي تناسب خطتك الشخصية',
        'female': 'انقري لإضافة الخيارات التي تناسب خطتكِ الشخصية',
        'other': 'انقر لإضافة الخيارات التي تناسب خطتك الشخصية',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'العلامات التحذيرية والتغيّرات التي قد ألاحظها على نفسي',
        'female': 'العلامات التحذيرية والتغيّرات التي قد ألاحظها على نفسي',
        'other': 'العلامات التحذيرية والتغيّرات التي قد ألاحظها على نفسي',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تذكير بأشياء ظهرت لي شخصيًا في الماضي',
        'female': 'تذكير بأشياء ظهرت لي شخصيًا في الماضي',
        'other': 'تذكير بأشياء ظهرت لي شخصيًا في الماضي',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تحتاج إلى مساعدة؟ إليك بعض الاقتراحات',
        'female': 'تحتاجين إلى مساعدة؟ إليكِ بعض الاقتراحات',
        'other': 'بحاجة إلى مساعدة؟ هذه بعض الاقتراحات',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'انقر لإضافة خيارات تناسب خطتك الشخصية',
        'female': 'انقري لإضافة خيارات تناسب خطتكِ الشخصية',
        'other': 'انقر لإضافة خيارات تناسب خطتك الشخصية',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لتحقيق التوازن ونمط حياة صحي - أدوات العافية والأدوية الشخصية',
        'female':
            'لتحقيق التوازن ونمط حياة صحي - أدوات العافية والأدوية الشخصية',
        'other':
            'لتحقيق التوازن ونمط حياة صحي - أدوات العافية والأدوية الشخصية',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'ما الذي يساعدني على تحسين حالتي المزاجية والاسترخاء والشعور بقدر أقل من التوتر؟\nأساليب وقائية يومية، وحتى زيادة الجرعات في حالات الطوارئ.',
        'female':
            'ما الذي يساعدني على تحسين حالتي المزاجية والاسترخاء والشعور بقدر أقل من التوتر؟\nأساليب وقائية يومية، وحتى زيادة الجرعات في حالات الطوارئ.',
        'other':
            'ما الذي يساعدني على تحسين حالتي المزاجية والاسترخاء والشعور بقدر أقل من التوتر؟\nأساليب وقائية يومية، وحتى زيادة الجرعات في حالات الطوارئ.',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تحتاج إلى مساعدة؟ إليك بعض الاقتراحات',
        'female': 'تحتاجين إلى مساعدة؟ إليكِ بعض الاقتراحات',
        'other': 'بحاجة إلى مساعدة؟ هذه بعض الاقتراحات',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'انقر لإضافة خيارات تناسب خطتك الشخصية',
        'female': 'انقري لإضافة خيارات تناسب خطتكِ الشخصية',
        'other': 'انقر لإضافة خيارات تناسب خطتك الشخصية',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'الدعم من محيطي عندما ألاحظ علامات الإنذار المبكر، وكيف أرغب في الحصول على المساعدة',
        'female':
            'الدعم من محيطي عندما ألاحظ علامات الإنذار المبكر، وكيف أرغب في الحصول على المساعدة',
        'other':
            'الدعم من محيطي عندما ألاحظ علامات الإنذار المبكر، وكيف أرغب في الحصول على المساعدة',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الطرق التي يمكن أن يساعدني بها محيطي في التأقلم',
        'female': 'الطرق التي يمكن أن يساعدني بها محيطي في التأقلم',
        'other': 'الطرق التي يمكن أن يساعدني بها محيطي في التأقلم',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferMidTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تحتاج إلى مساعدة؟ إليك بعض الاقتراحات',
        'female': 'تحتاجين إلى مساعدة؟ إليكِ بعض الاقتراحات',
        'other': 'بحاجة إلى مساعدة؟ هذه بعض الاقتراحات',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferMidSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'انقر لإضافة خيارات تناسب خطتك الشخصية',
        'female': 'انقري لإضافة خيارات تناسب خطتكِ الشخصية',
        'other': 'انقر لإضافة خيارات تناسب خطتك الشخصية',
      },
    );
    return '$_temp0';
  }

  @override
  String phonesPagePhone(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'هاتف',
        'female': 'هاتف',
        'other': 'هاتف',
      },
    );
    return '$_temp0';
  }

  @override
  String phonesPageName(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'اسم',
        'female': 'اسم',
        'other': 'اسم',
      },
    );
    return '$_temp0';
  }

  @override
  String phonesPageHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'من هم الأشخاص الذين يدعمونني والذين يمكنني اللجوء إليهم إذا شعرت بالضيق أو راودتني أفكار لإيذاء نفسي؟',
        'female':
            'من هم الأشخاص الذين يدعمونني والذين يمكنني اللجوء إليهم إذا شعرتُ بالضيق أو راودتني أفكار لإيذاء نفسي؟',
        'other':
            'من هم الأشخاص الذين يدعمونني والذين يمكنني اللجوء إليهم إذا شعرت بالضيق أو راودتني أفكار لإيذاء نفسي؟',
      },
    );
    return '$_temp0';
  }

  @override
  String phonesPageSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الأشخاص الذين يحبونني وسيساعدونني في تجاوز اللحظات الصعبة هم:',
        'female':
            'الأشخاص الذين يحبونني وسيساعدونني في تجاوز اللحظات الصعبة هم:',
        'other':
            'الأشخاص الذين يحبونني وسيساعدونني في تجاوز اللحظات الصعبة هم:',
      },
    );
    return '$_temp0';
  }

  @override
  String phonesPageManualTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إضافة يدويًا',
        'female': 'إضافة يدويًا',
        'other': 'إضافة يدويًا',
      },
    );
    return '$_temp0';
  }

  @override
  String phonesPageContactImportTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إضافة من قائمة جهات الاتصال',
        'female': 'إضافة من قائمة جهات الاتصال',
        'other': 'إضافة من قائمة جهات الاتصال',
      },
    );
    return '$_temp0';
  }

  @override
  String saveButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'حفظ',
        'female': 'حفظ',
        'other': 'حفظ',
      },
    );
    return '$_temp0';
  }

  @override
  String closeButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إلغاء',
        'female': 'إلغاء',
        'other': 'إلغاء',
      },
    );
    return '$_temp0';
  }

  @override
  String nextButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'متابعة',
        'female': 'متابعة',
        'other': 'متابعة',
      },
    );
    return '$_temp0';
  }

  @override
  String showMoreButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'عرض المزيد',
        'female': 'عرض المزيد',
        'other': 'عرض المزيد',
      },
    );
    return '$_temp0';
  }

  @override
  String introductionFormLastPageNext(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إلى الاستبيان',
        'female': 'إلى الاستبيان',
        'other': 'إلى الاستبيان',
      },
    );
    return '$_temp0';
  }

  @override
  String saveAndQuitButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إلى القائمة',
        'female': 'إلى القائمة',
        'other': 'إلى القائمة',
      },
    );
    return '$_temp0';
  }

  @override
  String confirmButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تأكيد',
        'female': 'تأكيد',
        'other': 'تأكيد',
      },
    );
    return '$_temp0';
  }

  @override
  String deleteButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'حذف',
        'female': 'حذف',
        'other': 'حذف',
      },
    );
    return '$_temp0';
  }

  @override
  String menu(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'القائمة',
        'female': 'القائمة',
        'other': 'القائمة',
      },
    );
    return '$_temp0';
  }

  @override
  String notifications(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تذكيرات',
        'female': 'تذكيرات',
        'other': 'تذكيرات',
      },
    );
    return '$_temp0';
  }

  @override
  String home(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الرئيسية',
        'female': 'الرئيسية',
        'other': 'الرئيسية',
      },
    );
    return '$_temp0';
  }

  @override
  String skipButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تخطي',
        'female': 'تخطي',
        'other': 'تخطي',
      },
    );
    return '$_temp0';
  }

  @override
  String select(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'اختيار',
        'female': 'اختيار',
        'other': 'اختيار',
      },
    );
    return '$_temp0';
  }

  @override
  String backButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'رجوع',
        'female': 'رجوع',
        'other': 'رجوع',
      },
    );
    return '$_temp0';
  }

  @override
  String dialButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'اتصال',
        'female': 'اتصال',
        'other': 'اتصال',
      },
    );
    return '$_temp0';
  }

  @override
  String yourContacts(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'جهات الاتصال الخاصة بك',
        'female': 'جهات الاتصال الخاصة بكِ',
        'other': 'جهات الاتصال الخاصة بك',
      },
    );
    return '$_temp0';
  }

  @override
  String emergencyNumbers(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أرقام الطوارئ',
        'female': 'أرقام الطوارئ',
        'other': 'أرقام الطوارئ',
      },
    );
    return '$_temp0';
  }

  @override
  String phonePageTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'أنت لست وحدك! إذا كنت في محنة الآن، يرجى التواصل مع إحدى جهات الاتصال المذكورة هنا',
        'female':
            'أنتِ لستِ وحدكِ! إذا كنتِ في محنة الآن، يرجى التواصل مع إحدى جهات الاتصال المذكورة هنا',
        'other':
            'أنت لست وحدك! إذا كنت في محنة الآن، يرجى التواصل مع إحدى جهات الاتصال المذكورة هنا',
      },
    );
    return '$_temp0';
  }

  @override
  String get whatsApp => 'واتساب';

  @override
  String get thanks => 'شكرًا';

  @override
  String get trait => 'سمة';

  @override
  String get link => 'رابط إلى الموقع';

  @override
  String get gallery => 'معرض';

  @override
  String get camera => 'كاميرا';

  @override
  String addImageButton(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إضافة صورة',
        'female': 'إضافة صورة',
        'other': 'إضافة صورة',
      },
    );
    return '$_temp0';
  }

  @override
  String addImageTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'من أين تضيف',
        'female': 'من أين تضيفين',
        'other': 'من أين تضيف',
      },
    );
    return '$_temp0';
  }

  @override
  String feelGoodTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'صور مشجعة وملهمة',
        'female': 'صور مشجعة وملهمة',
        'other': 'صور مشجعة وملهمة',
      },
    );
    return '$_temp0';
  }

  @override
  String feelGoodSubTitle(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'يوصى بإضافة صور مشجعة وملهمة ومبهجة. صور مبتسمة للعائلة والأصدقاء والهوايات والرحلات الناجحة والمزيد',
        'female':
            'يوصى بإضافة صور مشجعة وملهمة ومبهجة. صور مبتسمة للعائلة والأصدقاء والهوايات والرحلات الناجحة والمزيد',
        'other':
            'يوصى بإضافة صور مشجعة وملهمة ومبهجة. صور مبتسمة للعائلة والأصدقاء والهوايات والرحلات الناجحة والمزيد',
      },
    );
    return '$_temp0';
  }

  @override
  String get male => 'ذكر';

  @override
  String get notWillingToSay => 'أفضل عدم الإفصاح';

  @override
  String get noPermissionAllowedText => 'لم يتم منح الإذن';

  @override
  String get female => 'أنثى';

  @override
  String get nonBinary => 'غير ثنائي';

  @override
  String showAll(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إظهار الكل',
        'female': 'إظهار الكل',
        'other': 'إظهار الكل',
      },
    );
    return '$_temp0';
  }

  @override
  String notificationPageHeader(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أضف تذكيرًا لاستخدام Living Positively.',
        'female': 'أضيفي تذكيرًا لاستخدام Living Positively.',
        'other': 'إضافة تذكير لاستخدام Living Positively.',
      },
    );
    return '$_temp0';
  }

  @override
  String notificationSetTimeText(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'جدولة تذكير للوقت المحدد',
        'female': 'جدولة تذكير للوقت المحدد',
        'other': 'جدولة تذكير للوقت المحدد',
      },
    );
    return '$_temp0';
  }

  @override
  String notificationShowExampleNotification(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'عرض مثال للتذكير',
        'female': 'عرض مثال للتذكير',
        'other': 'عرض مثال للتذكير',
      },
    );
    return '$_temp0';
  }

  @override
  String notificationCancelNotification(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إلغاء الإشعار الحالي',
        'female': 'إلغاء الإشعار الحالي',
        'other': 'إلغاء الإشعار الحالي',
      },
    );
    return '$_temp0';
  }

  @override
  String finishedDownloading(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'انتهى التنزيل',
        'female': 'انتهى التنزيل',
        'other': 'انتهى التنزيل',
      },
    );
    return '$_temp0';
  }

  @override
  String downloadFailed(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'فشل التنزيل',
        'female': 'فشل التنزيل',
        'other': 'فشل التنزيل',
      },
    );
    return '$_temp0';
  }

  @override
  String selectLanguage(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'اختر اللغة',
        'female': 'اختاري اللغة',
        'other': 'اختر/ي اللغة',
      },
    );
    return '$_temp0';
  }

  @override
  String get validateEmpty => 'لا يمكن أن يكون الحقل فارغًا';

  @override
  String get moreVideos => 'مقاطع فيديو إضافية';

  @override
  String get noVideosAvailableForLocale =>
      'لا توجد مقاطع فيديو متاحة للغتك، نعتذر.';

  @override
  String get confirmResetTitle => 'هل أنت متأكد؟';

  @override
  String get shareRoutineMessage =>
      'هذه هي خطتي الشخصية التي تساعدني على الحفاظ على سلامتي. أرسلها إليك لأنني أرى أن لك دورًا فيها أيضًا. آمل أن يكون ذلك مناسبًا لك. سأقدّر كثيرًا موافقتك على المشاركة فيها عند الحاجة. شكرًا جزيلًا مقدمًا، وأتطلع إلى ردك.';

  @override
  String get shareOptions => 'خيارات المشاركة';

  @override
  String get shareFile => 'مشاركة ملف الخطة الشخصية';

  @override
  String get shareRoutine => 'مشاركة النص لإشراك الداعمين';

  @override
  String get shareEmergency => 'مشاركة النص في حالات الأزمات';

  @override
  String get shareEmergencyMessage =>
      'أنا لست بخير وأحتاج إلى المساعدة. سأقدّر دعمك في تفعيل خطتي الشخصية. شكرًا لك مقدمًا.';

  @override
  String get informationCollectionDisclaimer =>
      'المعلومات التي يتم جمعها:\n\nيقوم التطبيق فقط بجمع البيانات مجهولة المصدر والإحصائية لغرض التحليل وتحسين الخدمة. لا يمكن لهذه البيانات تحديد أي مستخدم فردي. ومن بين البيانات التي يتم جمعها:\n• بيانات استخدام التطبيق العامة (على سبيل المثال، الصفحات التي تم عرضها، وتكرار الاستخدام).\n• معلومات فنية عن الجهاز والنظام (نوع الجهاز، إصدار نظام التشغيل).\n• بيانات الموقع مجهولة المصدر - يتم جمعها فقط لتحليل الاتجاهات وأنماط الاستخدام، دون الارتباط بأي مستخدم يمكن تحديده.';

  @override
  String get addingContactDisclaimer =>
      'نحن لا نحفظ جهات الاتصال الخاصة بك، فهي لاستخدامك الشخصي فقط.';

  @override
  String notifyOnscheduledNotification(Object time) {
    return 'تم ضبط التذكير على $time';
  }

  @override
  String newTraitOrThanks(Object item) {
    return 'عنصر جديد: $item';
  }

  @override
  String todoListName(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'مجلة الامتنان',
        'female': 'مجلة الامتنان',
        'other': 'مجلة الامتنان',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ما سيساعدني الآن، حتى الخطوات الصغيرة هي تقدّم',
        'female': 'ما سيساعدني الآن، حتى الخطوات الصغيرة هي تقدّم',
        'other': 'ما سيساعدني الآن، حتى الخطوات الصغيرة هي تقدّم',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لديّ نقاط قوة',
        'female': 'لديّ نقاط قوة',
        'other': 'لديّ نقاط قوة',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لقد واجهتُ تحديات من قبل',
        'female': 'لقد واجهتُ تحديات من قبل',
        'other': 'لقد واجهتُ تحديات من قبل',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'يتغيّر المزاج مثل الطقس، وليس ثابتًا',
        'female': 'يتغيّر المزاج مثل الطقس، وليس ثابتًا',
        'other': 'يتغيّر المزاج مثل الطقس، وليس ثابتًا',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'المشاعر عابرة ومتغيّرة',
        'female': 'المشاعر عابرة ومتغيّرة',
        'other': 'المشاعر عابرة ومتغيّرة',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا قادر',
        'female': 'أنا قادرة',
        'other': 'أنا قادر',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لديّ القوة',
        'female': 'لديّ القوة',
        'other': 'لديّ القوة',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا أتعلّم الاسترخاء',
        'female': 'أنا أتعلّم الاسترخاء',
        'other': 'أنا أتعلّم الاسترخاء',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'بعد الانخفاضات يأتي الصعود',
        'female': 'بعد الانخفاضات يأتي الصعود',
        'other': 'بعد الانخفاضات يأتي الصعود',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لا بأس في البكاء',
        'female': 'لا بأس في البكاء',
        'other': 'لا بأس في البكاء',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على المساعدة',
        'female': 'شكرًا على المساعدة',
        'other': 'شكرًا على المساعدة',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'خذ لحظة لتبتسم',
        'female': 'خذي لحظة لتبتسمي',
        'other': 'خذ لحظة لتبتسم',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تذكّر أن تتنفس',
        'female': 'تذكّري أن تتنفسي',
        'other': 'تذكّر أن تتنفس',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الروتين يخلق الاستقرار',
        'female': 'الروتين يخلق الاستقرار',
        'other': 'الروتين يخلق الاستقرار',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الحركة تُخفّف التوتر',
        'female': 'الحركة تُخفّف التوتر',
        'other': 'الحركة تُخفّف التوتر',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لا بأس في طلب المساعدة',
        'female': 'لا بأس في طلب المساعدة',
        'other': 'لا بأس في طلب المساعدة',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لا بأس ألا تكون بخير',
        'female': 'لا بأس ألا تكوني بخير',
        'other': 'لا بأس ألا تكون بخير',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'حافظ على الوتيرة المناسبة لك',
        'female': 'حافظي على الوتيرة المناسبة لكِ',
        'other': 'حافظ على الوتيرة المناسبة لك',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ما الذي يمنحك القوة للاستمرار؟',
        'female': 'ما الذي يمنحكِ القوة للاستمرار؟',
        'other': 'ما الذي يمنحك القوة للاستمرار؟',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا قادر على تجاوز تحدياتي',
        'female': 'أنا قادرة على تجاوز تحدياتي',
        'other': 'أنا قادر على تجاوز تحدياتي',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا قادر على تهدئة جسدي وعقلي',
        'female': 'أنا قادرة على تهدئة جسدي وعقلي',
        'other': 'أنا قادر على تهدئة جسدي وعقلي',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo21(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لديّ التعاطف مع الذات',
        'female': 'لديّ التعاطف مع الذات',
        'other': 'لديّ التعاطف مع الذات',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo22(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا قويّ وقادر',
        'female': 'أنا قويّة وقادرة',
        'other': 'أنا قويّ وقادر',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo23(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا أتعلّم قبول نفسي',
        'female': 'أنا أتعلّم قبول نفسي',
        'other': 'أنا أتعلّم قبول نفسي',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo24(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا أقبل نفسي كما أنا',
        'female': 'أنا أقبل نفسي كما أنا',
        'other': 'أنا أقبل نفسي كما أنا',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo25(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أتعلّم أن ألاحظ صفاتي الإيجابية',
        'female': 'أتعلّم أن ألاحظ صفاتي الإيجابية',
        'other': 'أتعلّم أن ألاحظ صفاتي الإيجابية',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo26(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أتعرّف على مشاعري وأسمح لها بالمرور',
        'female': 'أتعرّف على مشاعري وأسمح لها بالمرور',
        'other': 'أتعرّف على مشاعري وأسمح لها بالمرور',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo27(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'يمكن للمشاعر أن تتغيّر بشكل طبيعي',
        'female': 'يمكن للمشاعر أن تتغيّر بشكل طبيعي',
        'other': 'يمكن للمشاعر أن تتغيّر بشكل طبيعي',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo28(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الحديث الإيجابي عن النفس يُعزّز احترام الذات',
        'female': 'الحديث الإيجابي عن النفس يُعزّز احترام الذات',
        'other': 'الحديث الإيجابي عن النفس يُعزّز احترام الذات',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo29(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الممارسة اليومية تؤدي إلى التحسّن',
        'female': 'الممارسة اليومية تؤدي إلى التحسّن',
        'other': 'الممارسة اليومية تؤدي إلى التحسّن',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo30(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنت لست وحدك!',
        'female': 'أنتِ لستِ وحدكِ!',
        'other': 'أنت لست وحدك!',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo31(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الممارسة اليومية تُحسّن مزاجي، والاستمرار يستحق كل هذا العناء',
        'female':
            'الممارسة اليومية تُحسّن مزاجي، والاستمرار يستحق كل هذا العناء',
        'other':
            'الممارسة اليومية تُحسّن مزاجي، والاستمرار يستحق كل هذا العناء',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo32(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا ذو قيمة',
        'female': 'أنا ذات قيمة',
        'other': 'أنا ذو قيمة',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo33(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا أؤمن بقدراتي',
        'female': 'أنا أؤمن بقدراتي',
        'other': 'أنا أؤمن بقدراتي',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo34(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا أستحق ذلك',
        'female': 'أنا أستحق ذلك',
        'other': 'أنا أستحق ذلك',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo35(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا أعمل على الشعور بالتحسّن',
        'female': 'أنا أعمل على الشعور بالتحسّن',
        'other': 'أنا أعمل على الشعور بالتحسّن',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo36(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الحياة تستحقّ العناء',
        'female': 'الحياة تستحقّ العناء',
        'other': 'الحياة تستحقّ العناء',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo37(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تشير الدراسات إلى أن الأفكار تؤثر على المشاعر',
        'female': 'تشير الدراسات إلى أن الأفكار تؤثر على المشاعر',
        'other': 'تشير الدراسات إلى أن الأفكار تؤثر على المشاعر',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo38(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا أستحقّ أن أكون سعيدًا',
        'female': 'أنا أستحقّ أن أكون سعيدةً',
        'other': 'أنا أستحقّ أن أكون سعيدًا',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo39(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أستطيع وسأفعل',
        'female': 'أستطيع وسأفعل',
        'other': 'أستطيع وسأفعل',
      },
    );
    return '$_temp0';
  }

  @override
  String inspirationalQuotesNo40(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنت عظيم كما أنت',
        'female': 'أنتِ عظيمة كما أنتِ',
        'other': 'أنت عظيم كما أنت',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على اللحظات الأسهل',
        'female': 'شكرًا على اللحظات الأسهل',
        'other': 'شكرًا على اللحظات الأسهل',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على وجبة جيدة',
        'female': 'شكرًا على وجبة جيدة',
        'other': 'شكرًا على وجبة جيدة',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على القدرة على التدريب',
        'female': 'شكرًا على القدرة على التدريب',
        'other': 'شكرًا على القدرة على التدريب',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على محادثة جيدة',
        'female': 'شكرًا على محادثة جيدة',
        'other': 'شكرًا على محادثة جيدة',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على النوم الجيد',
        'female': 'شكرًا على النوم الجيد',
        'other': 'شكرًا على النوم الجيد',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على النجاح',
        'female': 'شكرًا على النجاح',
        'other': 'شكرًا على النجاح',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على قضاء الوقت مع...',
        'female': 'شكرًا على قضاء الوقت مع...',
        'other': 'شكرًا على قضاء الوقت مع...',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على الطقس',
        'female': 'شكرًا على الطقس',
        'other': 'شكرًا على الطقس',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على وجود منزل',
        'female': 'شكرًا على وجود منزل',
        'other': 'شكرًا على وجود منزل',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على الصحة الجيدة',
        'female': 'شكرًا على الصحة الجيدة',
        'other': 'شكرًا على الصحة الجيدة',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على العائلة',
        'female': 'شكرًا على العائلة',
        'other': 'شكرًا على العائلة',
      },
    );
    return '$_temp0';
  }

  @override
  String thanksListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'شكرًا على الأصدقاء',
        'female': 'شكرًا على الأصدقاء',
        'other': 'شكرًا على الأصدقاء',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أعرف كيف أطلب المساعدة',
        'female': 'أعرف كيف أطلب المساعدة',
        'other': 'أعرف كيف أطلب المساعدة',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا ودود',
        'female': 'أنا ودودة',
        'other': 'أنا ودود',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا صديق جيد',
        'female': 'أنا صديقة جيدة',
        'other': 'أنا صديق جيد',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا على استعداد لبذل الجهد',
        'female': 'أنا على استعداد لبذل الجهد',
        'other': 'أنا على استعداد لبذل الجهد',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا مبدع',
        'female': 'أنا مبدعة',
        'other': 'أنا مبدع',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا قادر',
        'female': 'أنا قادرة',
        'other': 'أنا قادر',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لديّ نقاط قوة',
        'female': 'لديّ نقاط قوة',
        'other': 'لديّ نقاط قوة',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أعرف كيف أقود',
        'female': 'أعرف كيف أقود',
        'other': 'أعرف كيف أقود',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا منفتح على التجارب',
        'female': 'أنا منفتحة على التجارب',
        'other': 'أنا منفتح على التجارب',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لديّ المثابرة والصبر',
        'female': 'لديّ المثابرة والصبر',
        'other': 'لديّ المثابرة والصبر',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا صبور',
        'female': 'أنا صبورة',
        'other': 'أنا صبور',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا رياضي',
        'female': 'أنا رياضية',
        'other': 'أنا رياضي',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا قادر',
        'female': 'أنا قادرة',
        'other': 'أنا قادر',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا جيد في التنظيم',
        'female': 'أنا جيدة في التنظيم',
        'other': 'أنا جيد في التنظيم',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أعرف كيف ألعب',
        'female': 'أعرف كيف ألعب',
        'other': 'أعرف كيف ألعب',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أعرف كيف أطبخ',
        'female': 'أعرف كيف أطبخ',
        'other': 'أعرف كيف أطبخ',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا أب جيد',
        'female': 'أنا أم جيدة',
        'other': 'أعتني بأبنائي بمحبة ومسؤولية',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا قوي',
        'female': 'أنا قوية',
        'other': 'أنا قوي',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا ذكي',
        'female': 'أنا ذكية',
        'other': 'أنا ذكي',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا جميل',
        'female': 'أنا جميلة',
        'other': 'أنا جميل',
      },
    );
    return '$_temp0';
  }

  @override
  String traitsListNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أنا مضحك',
        'female': 'أنا مضحكة',
        'other': 'أنا مضحك',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'مشاهدة الأخبار',
        'female': 'مشاهدة الأخبار',
        'other': 'مشاهدة الأخبار',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'التوتر مع المقربين مني',
        'female': 'التوتر مع المقربين مني',
        'other': 'التوتر مع المقربين مني',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الخلافات أو النزاعات المتعددة',
        'female': 'الخلافات أو النزاعات المتعددة',
        'other': 'الخلافات أو النزاعات المتعددة',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لقد واجهتُ تحديات من قبل',
        'female': 'لقد واجهتُ تحديات من قبل',
        'other': 'لقد واجهتُ تحديات من قبل',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الظلم والإجحاف وانعدام الإنصاف',
        'female': 'الظلم والإجحاف وانعدام الإنصاف',
        'other': 'الظلم والإجحاف وانعدام الإنصاف',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'البطالة',
        'female': 'البطالة',
        'other': 'البطالة',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'فقدان',
        'female': 'فقدان',
        'other': 'فقدان',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تسريح العمال والبطالة',
        'female': 'تسريح العمال والبطالة',
        'other': 'تسريح العمال والبطالة',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الحمل الزائد',
        'female': 'الحمل الزائد',
        'other': 'الحمل الزائد',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الشعور بالضيق المالي',
        'female': 'الشعور بالضيق المالي',
        'other': 'الشعور بالضيق المالي',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الإجهاد وتعدد المهام',
        'female': 'الإجهاد وتعدد المهام',
        'other': 'الإجهاد وتعدد المهام',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أمور غير مكتملة',
        'female': 'أمور غير مكتملة',
        'other': 'أمور غير مكتملة',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'نظام غذائي غير منتظم',
        'female': 'نظام غذائي غير منتظم',
        'other': 'نظام غذائي غير منتظم',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'حرب',
        'female': 'حرب',
        'other': 'حرب',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الشعور بالانغلاق على النفس',
        'female': 'الشعور بالانغلاق على النفس',
        'other': 'الشعور بالانغلاق على النفس',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الحرمان من النوم',
        'female': 'الحرمان من النوم',
        'other': 'الحرمان من النوم',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'فقدان أحد الأحبّاء',
        'female': 'فقدان أحد الأحبّاء',
        'other': 'فقدان أحد الأحبّاء',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'فقدان الاستقرار والروتين',
        'female': 'فقدان الاستقرار والروتين',
        'other': 'فقدان الاستقرار والروتين',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'عندما لا يكون لديّ الوقت لتفريغ الطاقة والغضب',
        'female': 'عندما لا يكون لديّ الوقت لتفريغ الطاقة والغضب',
        'other': 'عندما لا يكون لديّ الوقت لتفريغ الطاقة والغضب',
      },
    );
    return '$_temp0';
  }

  @override
  String difficultEventsListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'التحفيز الزائد، وعدم اليقين، والتحولات',
        'female': 'التحفيز الزائد، وعدم اليقين، والتحولات',
        'other': 'التحفيز الزائد، وعدم اليقين، والتحولات',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يساعدوني في مشاريع مشتركة ذات معنى',
        'female': 'أن يساعدوني في مشاريع مشتركة ذات معنى',
        'other': 'أن يساعدوني في مشاريع مشتركة ذات معنى',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يستوضحوا ما يحدث لي ويفكروا معي في طريقة للتعامل معه',
        'female': 'أن يستوضحوا ما يحدث لي ويفكروا معي في طريقة للتعامل معه',
        'other': 'أن يستوضحوا ما يحدث لي ويفكروا معي في طريقة للتعامل معه',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يُشركوني في العمل التعاوني',
        'female': 'أن يُشركوني في العمل التعاوني',
        'other': 'أن يُشركوني في العمل التعاوني',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يزوروني',
        'female': 'أن يزوروني',
        'other': 'أن يزوروني',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يدعوني لممارسة لعبة',
        'female': 'أن يدعوني لممارسة لعبة',
        'other': 'أن يدعوني لممارسة لعبة',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يدعوني إلى نشاط مشترك',
        'female': 'أن يدعوني إلى نشاط مشترك',
        'other': 'أن يدعوني إلى نشاط مشترك',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يشجعوني على النوم بما فيه الكفاية',
        'female': 'أن يشجعوني على النوم بما فيه الكفاية',
        'other': 'أن يشجعوني على النوم بما فيه الكفاية',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ألا أبقى وحيدًا',
        'female': 'ألا أبقى وحيدةً',
        'other': 'ألا أبقى وحيدًا',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يدعوني إلى تناول وجبة',
        'female': 'أن يدعوني إلى تناول وجبة',
        'other': 'أن يدعوني إلى تناول وجبة',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن أحصل على طعام مُغذٍّ',
        'female': 'أن أحصل على طعام مُغذٍّ',
        'other': 'أن أحصل على طعام مُغذٍّ',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن أطلب من شخص أثق به أن يبقى معي',
        'female': 'أن أطلب من شخص أثق به أن يبقى معي',
        'other': 'أن أطلب من شخص أثق به أن يبقى معي',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يدعوني إلى المشي أو التنزه أو ممارسة نشاط بدني',
        'female': 'أن يدعوني إلى المشي أو التنزه أو ممارسة نشاط بدني',
        'other': 'أن يدعوني إلى المشي أو التنزه أو ممارسة نشاط بدني',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن أتجنب الأماكن التي تجعلني أشعر بعدم الأمان',
        'female': 'أن أتجنب الأماكن التي تجعلني أشعر بعدم الأمان',
        'other': 'أن أتجنب الأماكن التي تجعلني أشعر بعدم الأمان',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن أحتفظ بكمية صغيرة فقط من أدويتي معي',
        'female': 'أن أحتفظ بكمية صغيرة فقط من أدويتي معي',
        'other': 'أن أحتفظ بكمية صغيرة فقط من أدويتي معي',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'والباقي أعهد به إلى شخص أثق به',
        'female': 'والباقي أعهد به إلى شخص أثق به',
        'other': 'والباقي أعهد به إلى شخص أثق به',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'أن أطلب من شخص آخر أن يُبعد عني أي أشياء قد تُستخدم لإيذاء نفسي',
        'female':
            'أن أطلب من شخص آخر أن يُبعد عني أي أشياء قد تُستخدم لإيذاء نفسي',
        'other':
            'أن أطلب من شخص آخر أن يُبعد عني أي أشياء قد تُستخدم لإيذاء نفسي',
      },
    );
    return '$_temp0';
  }

  @override
  String makeSaferListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن يسألوا عن حالي',
        'female': 'أن يسألوا عن حالي',
        'other': 'أن يسألوا عن حالي',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'اليقظة الذهنية',
        'female': 'اليقظة الذهنية',
        'other': 'اليقظة الذهنية',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'وقت منتظم للزوجين / للعلاقات الاجتماعية خلال الأسبوع',
        'female': 'وقت منتظم للزوجين / للعلاقات الاجتماعية خلال الأسبوع',
        'other': 'وقت منتظم للزوجين / للعلاقات الاجتماعية خلال الأسبوع',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'قائمة نقاط القوة والمزايا',
        'female': 'قائمة نقاط القوة والمزايا',
        'other': 'قائمة نقاط القوة والمزايا',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'مجلة الامتنان',
        'female': 'مجلة الامتنان',
        'other': 'مجلة الامتنان',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن أعبّر حين أجد من يستمع لي',
        'female': 'أن أعبّر حين أجد من يستمع لي',
        'other': 'أن أعبّر حين أجد من يستمع لي',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'التمهّل ومحاولة عدم إثقال كاهلي',
        'female': 'التمهّل ومحاولة عدم إثقال كاهلي',
        'other': 'التمهّل ومحاولة عدم إثقال كاهلي',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الابتعاد عن المهام اليومية والشاشات',
        'female': 'الابتعاد عن المهام اليومية والشاشات',
        'other': 'الابتعاد عن المهام اليومية والشاشات',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'رؤية ضوء الشمس',
        'female': 'رؤية ضوء الشمس',
        'other': 'رؤية ضوء الشمس',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الخروج إلى الطبيعة',
        'female': 'الخروج إلى الطبيعة',
        'other': 'الخروج إلى الطبيعة',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الاستراحة',
        'female': 'الاستراحة',
        'other': 'الاستراحة',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'وقت هادئ لنفسي',
        'female': 'وقت هادئ لنفسي',
        'other': 'وقت هادئ لنفسي',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تنظيف الأسنان للحصول على إحساس منعش',
        'female': 'تنظيف الأسنان للحصول على إحساس منعش',
        'other': 'تنظيف الأسنان للحصول على إحساس منعش',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أو مضغ العلكة',
        'female': 'أو مضغ العلكة',
        'other': 'أو مضغ العلكة',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن أتلقى عناقًا من شخص أثق به',
        'female': 'أن أتلقى عناقًا من شخص أثق به',
        'other': 'أن أتلقى عناقًا من شخص أثق به',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أن أقول لنفسي: \"أنا مهم\"',
        'female': 'أن أقول لنفسي: \"أنا مهمة\"',
        'other': 'أن أقول لنفسي: \"أنا مهم\"',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'هناك أشخاص يحبونني',
        'female': 'هناك أشخاص يحبونني',
        'other': 'هناك أشخاص يحبونني',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'التركيز على التنفس / الأحاسيس الجسدية',
        'female': 'التركيز على التنفس / الأحاسيس الجسدية',
        'other': 'التركيز على التنفس / الأحاسيس الجسدية',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male':
            'أخذ قسط من الراحة بتغيير مكاني (على سبيل المثال، الانتقال إلى غرفة أخرى في المنزل)',
        'female':
            'أخذ قسط من الراحة بتغيير مكاني (على سبيل المثال، الانتقال إلى غرفة أخرى في المنزل)',
        'other':
            'أخذ قسط من الراحة بتغيير مكاني (على سبيل المثال، الانتقال إلى غرفة أخرى في المنزل)',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الذهاب في نزهة قصيرة بالخارج',
        'female': 'الذهاب في نزهة قصيرة بالخارج',
        'other': 'الذهاب في نزهة قصيرة بالخارج',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الخروج لاستنشاق هواء نقي (خارج المنزل أو حتى من الشرفة)',
        'female': 'الخروج لاستنشاق هواء نقي (خارج المنزل أو حتى من الشرفة)',
        'other': 'الخروج لاستنشاق هواء نقي (خارج المنزل أو حتى من الشرفة)',
      },
    );
    return '$_temp0';
  }

  @override
  String feelBetterListNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'مشاهدة مقاطع قصيرة',
        'female': 'مشاهدة مقاطع قصيرة',
        'other': 'مشاهدة مقاطع قصيرة',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo0(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أفكار انتحارية',
        'female': 'أفكار انتحارية',
        'other': 'أفكار انتحارية',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo1(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'انخفاض تقدير الذات',
        'female': 'انخفاض تقدير الذات',
        'other': 'انخفاض تقدير الذات',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo2(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الشعور بأنني لا أهمّ',
        'female': 'الشعور بأنني لا أهمّ',
        'other': 'الشعور بأنني لا أهمّ',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo3(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الرغبة في الانزواء أو الاختباء أو الاختفاء',
        'female': 'الرغبة في الانزواء أو الاختباء أو الاختفاء',
        'other': 'الرغبة في الانزواء أو الاختباء أو الاختفاء',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo4(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'التعب الشديد',
        'female': 'التعب الشديد',
        'other': 'التعب الشديد',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo5(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تراجع في القدرة على أداء المهام اليومية',
        'female': 'تراجع في القدرة على أداء المهام اليومية',
        'other': 'تراجع في القدرة على أداء المهام اليومية',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo6(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'فقدان أو نقص في الطاقة',
        'female': 'فقدان أو نقص في الطاقة',
        'other': 'فقدان أو نقص في الطاقة',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo7(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'القلق',
        'female': 'القلق',
        'other': 'القلق',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo8(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'انخفاض الرغبة الجنسية',
        'female': 'انخفاض الرغبة الجنسية',
        'other': 'انخفاض الرغبة الجنسية',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo9(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'اللامبالاة أو عدم الاكتراث',
        'female': 'اللامبالاة أو عدم الاكتراث',
        'other': 'اللامبالاة أو عدم الاكتراث',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo10(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الحساسية المفرطة',
        'female': 'الحساسية المفرطة',
        'other': 'الحساسية المفرطة',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo11(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'لوم الذات',
        'female': 'لوم الذات',
        'other': 'لوم الذات',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo12(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'زيادة وتصاعد في التسوّق',
        'female': 'زيادة وتصاعد في التسوّق',
        'other': 'زيادة وتصاعد في التسوّق',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo13(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'إهمال الذات',
        'female': 'إهمال الذات',
        'other': 'إهمال الذات',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo14(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الثقة المفرطة',
        'female': 'الثقة المفرطة',
        'other': 'الثقة المفرطة',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo15(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'القيام بأدنى الحدّ الأدنى - وحتى ذلك بجهد كبير',
        'female': 'القيام بأدنى الحدّ الأدنى - وحتى ذلك بجهد كبير',
        'other': 'القيام بأدنى الحدّ الأدنى - وحتى ذلك بجهد كبير',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo16(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ضعف الأداء',
        'female': 'ضعف الأداء',
        'other': 'ضعف الأداء',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo17(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'تسارع الأفكار في ذهني',
        'female': 'تسارع الأفكار في ذهني',
        'other': 'تسارع الأفكار في ذهني',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo18(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أفكار متسارعة وسريعة',
        'female': 'أفكار متسارعة وسريعة',
        'other': 'أفكار متسارعة وسريعة',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo19(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ضعف الثقة بالنفس',
        'female': 'ضعف الثقة بالنفس',
        'other': 'ضعف الثقة بالنفس',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo20(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'التردد',
        'female': 'التردد',
        'other': 'التردد',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo21(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'أفكار بطيئة ومشوّشة',
        'female': 'أفكار بطيئة ومشوّشة',
        'other': 'أفكار بطيئة ومشوّشة',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo22(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ازدياد الميل للاختلاط بالآخرين',
        'female': 'ازدياد الميل للاختلاط بالآخرين',
        'other': 'ازدياد الميل للاختلاط بالآخرين',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo23(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الانخراط الزائد مع الآخرين',
        'female': 'الانخراط الزائد مع الآخرين',
        'other': 'الانخراط الزائد مع الآخرين',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo24(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'كثرة التواجد في التجمعات',
        'female': 'كثرة التواجد في التجمعات',
        'other': 'كثرة التواجد في التجمعات',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo25(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'العزلة',
        'female': 'العزلة',
        'other': 'العزلة',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo26(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ملء كل لحظة من الوقت',
        'female': 'ملء كل لحظة من الوقت',
        'other': 'ملء كل لحظة من الوقت',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo27(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الخوف من البقاء وحيدًا',
        'female': 'الخوف من البقاء وحيدةً',
        'other': 'الخوف من البقاء وحيدًا',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo28(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الخوف من الفراغ',
        'female': 'الخوف من الفراغ',
        'other': 'الخوف من الفراغ',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo29(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الاستخدام المكثف للوسائط المختلفة',
        'female': 'الاستخدام المكثف للوسائط المختلفة',
        'other': 'الاستخدام المكثف للوسائط المختلفة',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo30(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'ازدياد الصداع',
        'female': 'ازدياد الصداع',
        'other': 'ازدياد الصداع',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo31(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الإفراط في تناول الطعام',
        'female': 'الإفراط في تناول الطعام',
        'other': 'الإفراط في تناول الطعام',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo32(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'النوم غير المنتظم',
        'female': 'النوم غير المنتظم',
        'other': 'النوم غير المنتظم',
      },
    );
    return '$_temp0';
  }

  @override
  String distractionsListNo33(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الأرق أو النوم الخفيف',
        'female': 'الأرق أو النوم الخفيف',
        'other': 'الأرق أو النوم الخفيف',
      },
    );
    return '$_temp0';
  }

  @override
  String get aboutPage1 =>
      'يُعدّ \"Living Positively\" منصة مصممة لتعزيز المرونة النفسية، والمساعدة في التعامل مع الأزمات المرتبطة بأفكار انتحارية، وتشجيع الإدارة الذاتية، وإنشاء شبكة دعم شخصية، وتعزيز حياة أفضل وذات جودة أعلى. تم تطويرها من قِبل منظمة النادي التابعة لجمعية أميت.\n\nيستخدم هذا التطبيق أدوات من مجال علم النفس الإيجابي، وإدارة المرض والتعافي، وأبحاث الوقاية من الانتحار.\n\nيجمع البرنامج الشخصي بين خطة الوقاية من الانتكاس من دورة IMR (إدارة المرض والتعافي) بالإضافة إلى خطة السلامة من ستانلي وبراون.\n\nمصطلح \"قائمة الامتنان\" قدّمته لنا الدكتورة شيرلي يوفال يائير لمجلة الامتنان وتم نشره هنا بموافقتها.\n\nيتم تطوير المنتج بالتعاون والإثراء المتبادل مع الحاضنة الاجتماعية في التخنيون، بمساعدة فريق التطوير.';

  @override
  String get aboutPage2 =>
      'التطبيق مخصص للاستخدام الشخصي لتحسين المرونة النفسية وتقديم الدعم والمساعدة عند الحاجة في حالات الأزمات.\n\nلا يمكن للتطبيق، وليس مصممًا، أن يحلّ محلّ مقدمي خدمات الصحة النفسية المحترفين. ولا يحلّ محلّ التشخيص المهني أو العلاج النفسي. الغرض من الأدوات المتكاملة هو مساعدتك ومساعدة محيطك على تحسين نوعية الحياة وتقديم الدعم أثناء الأزمات.\n\nيمكنك استخدام التطبيق لأغراض الدعم الذاتي و/أو دمجه كجزء من عملية علاجية مع أحد المتخصصين. إذا كنت بحاجة إلى تشخيص أو علاج شخصي، فمن المهم استشارة معالج متخصص. استخدام التطبيق هو على مسؤوليتك الشخصية.\n\nللعلم: يتم تخزين بياناتك الشخصية في التطبيق على جهازك فقط! لا يقوم التطبيق بجمع أو نقل المعلومات الشخصية، ولن يتم استخدامها أبدًا. لديك خيار تحديد ما تريد مشاركته من الداخل، مثل الخطة الشخصية، التي يُنصح بمشاركتها مع شبكتك الاجتماعية المقربة و/أو المتخصصين العلاجيين. إذا كنت لا توافق على شروط الاستخدام، يرجى إلغاء تثبيت التطبيق.';

  @override
  String get aboutTitle1 => 'حول التطبيق والاعتمادات';

  @override
  String get aboutTitle2 => 'شروط الاستخدام والخصوصية';

  @override
  String aboutVersionLabel(String version) {
    return 'إصدار تطبيق Living Positively: $version';
  }

  @override
  String locationSelect(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'الرجاء تحديد موقعك:',
        'female': 'الرجاء تحديد موقعكِ:',
        'other': 'الرجاء تحديد موقعك:',
      },
    );
    return '$_temp0';
  }

  @override
  String get disclaimerText =>
      'التطبيق مصمم للاستخدام الشخصي لتحسين المرونة النفسية وتقديم الدعم في أوقات الأزمات.\n\nولا يمكن ولا يهدف إلى استبدال مقدمي خدمات الصحة النفسية المحترفين. ولا يحلّ محلّ التشخيص المهني أو العلاج النفسي. تهدف الأدوات المدمجة في التطبيق إلى مساعدتك ومساعدة محيطك في تحسين نوعية الحياة وتقديم الدعم خلال الأوقات الصعبة.\n\nيمكنك استخدام التطبيق لأغراض الدعم الذاتي و/أو كجزء من عملية علاجية مع مقدم خدمة محترف. إذا كنت بحاجة إلى تشخيص أو علاج شخصي، فمن المهم استشارة معالج متخصص. استخدام التطبيق هو على مسؤوليتك الشخصية.\n\nيرجى ملاحظة: يتم تخزين بياناتك الشخصية داخل التطبيق على جهازك فقط! لا يقوم التطبيق بجمع أو نقل أي معلومات شخصية، ولن يتم استخدام هذه البيانات أبدًا. لديك خيار تحديد ما تريد مشاركته، مثل خطتك الشخصية، والتي يمكن مشاركتها مع جهات الاتصال الاجتماعية الوثيقة و/أو المتخصصين العلاجيين.\n\nإذا كنت لا توافق على شروط الاستخدام، يرجى إزالة التطبيق. إذا قبلت هذه الشروط، يرجى النقر على زر \"قبول\".';

  @override
  String get shareButtonText => 'مشاركة';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get shareAppMessage =>
      'هذا تطبيق LP (Living Positively). أستخدمه وأنصح به، ربما سيكون مفيدًا لك أيضًا.';

  @override
  String locationDisclaimer(String gender) {
    String _temp0 = intl.Intl.selectLogic(
      gender,
      {
        'male': 'يتم استخدام موقعك فقط لتخصيص أرقام SOS لبلدك.',
        'female': 'يتم استخدام موقعكِ فقط لتخصيص أرقام SOS لبلدكِ.',
        'other': 'يتم استخدام موقعك فقط لتخصيص أرقام SOS لبلدك.',
      },
    );
    return '$_temp0';
  }
}
