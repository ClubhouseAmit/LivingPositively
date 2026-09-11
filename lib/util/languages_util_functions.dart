/// Returns the canonical language subtag for locale-based text handling.
///
/// Maps the legacy Hebrew alias `iw` to `he`. Keep the original locale ID for
/// requests to providers that may require their native identifier.
String canonicalLanguageCodeForLocale(String localeId) {
  final code = localeId.split(RegExp('[-_]')).first.toLowerCase();
  return code == 'iw' ? 'he' : code;
}

String languageName(String code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'he':
      return 'עברית';
    case 'ar':
      return 'العربية';
    default:
      return code; // Return the code itself if no match found
  }
}

String getDirectionOfText(String text) {
  final regex = RegExp(r'[a-z]');
  final regexHebrew = RegExp(r'[\u0590-\u05FF]');
  if (regexHebrew.hasMatch(text)) {
    return "rtl"; // Hebrew or Arabic text
  } else if (regex.hasMatch(text)) {
    return "ltr"; // English or other Latin text
  } else {
    return "ltr"; // Default to LTR for other cases
  }
}

String languageCode(String name) {
  switch (name) {
    case 'English':
      return 'en';
    case 'עברית':
      return 'he';
    case 'العربية':
      return 'ar';
    default:
      return name; // Return the name itself if no match found
  }
}
