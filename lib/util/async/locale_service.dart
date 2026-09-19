import 'package:language_code/language_code.dart';

abstract class LocaleService {
  String getLocale();
  void setLocale(String? locale);
}

class LocaleServiceImpl implements LocaleService {
  static String? locale;

  static String getLocaleName() {
    final deviceLocale = LanguageCode.rawLocale;
    switch (deviceLocale.languageCode) {
      case 'ar':
        return 'ar';
      case 'he':
        return 'he';
      case 'en':
        return 'en';
      default:
        return 'en';
    }
  }

  @override
  String getLocale() {
    return locale ?? getLocaleName();
  }

  @override
  void setLocale(String? newLocale) {
    locale = newLocale ?? getLocaleName();
  }
}
