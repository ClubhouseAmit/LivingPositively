/// Converts a dictated phone-number candidate into ASCII phone characters.
///
/// The function recognizes spoken digits in English, Hebrew, and Arabic for
/// their respective locales. It also accepts common Unicode decimal digits,
/// a plus sign, and visual separators for every locale. It deliberately does
/// not decide whether the resulting number is valid for a country; callers
/// must apply their existing country-aware validation before replacing a field.
String? normalizeSpokenPhoneNumber(
  String transcript, {
  required String localeId,
}) {
  final digitWords = _digitWordsFor(localeId);
  final acceptsSpokenPhoneCharacters = digitWords.isNotEmpty;
  final candidate = StringBuffer();
  final tokenSource = acceptsSpokenPhoneCharacters
      ? transcript.replaceAll('+', ' + ')
      : transcript;
  final tokens = tokenSource
      .split(_tokenSeparators)
      .where((token) => token.isNotEmpty);

  for (final token in tokens) {
    if (acceptsSpokenPhoneCharacters && token == '+') {
      candidate.write('+');
      continue;
    }

    final spokenDigit = digitWords[_normalizeWord(token)];
    if (spokenDigit != null) {
      candidate.write(spokenDigit);
      continue;
    }

    for (final codePoint in token.runes) {
      final digit = _asciiDigitFor(codePoint);
      if (digit != null) {
        candidate.write(digit);
      }
    }
  }

  final result = candidate.toString();
  return result.isEmpty ? null : result;
}

final RegExp _tokenSeparators = RegExp(
  r'[\s,;:.!?\u060C\u061B\u061F()\[\]{}<>/\\|_\-\u05BE\u2010-\u2015\u2212\u200B-\u200F\u202A-\u202E\u2066-\u2069]+',
);

Map<String, String> _digitWordsFor(String localeId) {
  final languageCode = localeId.split(RegExp('[-_]')).first.toLowerCase();
  return switch (languageCode) {
    'en' => _englishDigitWords,
    'he' => _hebrewDigitWords,
    'ar' => _arabicDigitWords,
    _ => const <String, String>{},
  };
}

String _normalizeWord(String value) {
  return value
      .toLowerCase()
      .replaceAll(_hebrewOrArabicMarks, '')
      .replaceAll('\u0640', '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي');
}

final RegExp _hebrewOrArabicMarks = RegExp(
  r'[\u0591-\u05C7\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
);

String? _asciiDigitFor(int codePoint) {
  for (final zeroCodePoint in _decimalZeroCodePoints) {
    if (codePoint >= zeroCodePoint && codePoint <= zeroCodePoint + 9) {
      return String.fromCharCode(0x30 + codePoint - zeroCodePoint);
    }
  }
  return null;
}

const List<int> _decimalZeroCodePoints = <int>[
  0x0030,
  0x0660,
  0x06F0,
  0x0966,
  0x09E6,
  0x0A66,
  0x0AE6,
  0x0B66,
  0x0BE6,
  0x0C66,
  0x0CE6,
  0x0D66,
  0x0E50,
  0x0ED0,
  0x0F20,
  0x1040,
  0x17E0,
  0x1810,
  0xFF10,
];

const Map<String, String> _englishDigitWords = <String, String>{
  'zero': '0',
  'oh': '0',
  'o': '0',
  'one': '1',
  'two': '2',
  'three': '3',
  'four': '4',
  'five': '5',
  'six': '6',
  'seven': '7',
  'eight': '8',
  'nine': '9',
  'plus': '+',
};

const Map<String, String> _hebrewDigitWords = <String, String>{
  'אפס': '0',
  'אחת': '1',
  'אחד': '1',
  'שתיים': '2',
  'שתים': '2',
  'שניים': '2',
  'שנים': '2',
  'שתי': '2',
  'שלוש': '3',
  'שלושה': '3',
  'ארבע': '4',
  'ארבעה': '4',
  'חמש': '5',
  'חמישה': '5',
  'שש': '6',
  'ששה': '6',
  'שבע': '7',
  'שבעה': '7',
  'שמונה': '8',
  'תשע': '9',
  'תשעה': '9',
  'פלוס': '+',
};

const Map<String, String> _arabicDigitWords = <String, String>{
  'صفر': '0',
  'واحد': '1',
  'واحدة': '1',
  'اثنان': '2',
  'اثنين': '2',
  'اتنين': '2',
  'اثنتان': '2',
  'اثنتين': '2',
  'ثلاثة': '3',
  'ثلاث': '3',
  'تلاتة': '3',
  'اربعة': '4',
  'اربع': '4',
  'خمسة': '5',
  'ستة': '6',
  'سبعة': '7',
  'ثمانية': '8',
  'تسعة': '9',
  'تسع': '9',
  'زائد': '+',
  'موجب': '+',
};
