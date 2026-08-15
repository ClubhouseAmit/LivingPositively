import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/spoken_phone_number_normalizer.dart';

void main() {
  group('normalizeSpokenPhoneNumber', () {
    test('should normalize English spoken digits and a spoken plus sign', () {
      expect(
        normalizeSpokenPhoneNumber(
          'plus nine seven two zero five zero one two three four five six seven',
          localeId: 'en-US',
        ),
        '+9720501234567',
      );
    });

    test('should normalize Hebrew spoken digits and a spoken plus sign', () {
      expect(
        normalizeSpokenPhoneNumber(
          'פלוס תשע שבע שתיים אפס חמש אפס אחד שתיים שלוש ארבע חמש שש שבע',
          localeId: 'he-IL',
        ),
        '+9720501234567',
      );
    });

    test('should normalize Arabic spoken digits and a spoken plus sign', () {
      expect(
        normalizeSpokenPhoneNumber(
          'زائد تسعة سبعة اثنان صفر خمسة صفر واحد اثنان ثلاثة أربعة خمسة ستة سبعة',
          localeId: 'ar-SA',
        ),
        '+9720501234567',
      );
    });

    test(
      'should treat Arabic and Hebrew punctuation as spoken-digit separators',
      () {
        expect(
          normalizeSpokenPhoneNumber(
            'زائد تسعة، سبعة؛ اثنان صفر',
            localeId: 'ar-SA',
          ),
          '+9720',
        );
        expect(
          normalizeSpokenPhoneNumber(
            'פלוס תשע־שבע, שתיים אפס',
            localeId: 'he-IL',
          ),
          '+9720',
        );
      },
    );

    test(
      'should normalize only Unicode digits and separators for other locales',
      () {
        expect(
          normalizeSpokenPhoneNumber('+٩٧٢ (۰۵۰)-１２３ ٤٥٦٧', localeId: 'fr-FR'),
          '9720501234567',
        );
        expect(
          normalizeSpokenPhoneNumber('+ plus ٣٤', localeId: 'fr-FR'),
          '34',
        );
      },
    );

    test('should ignore unsupported spoken words for other locales', () {
      expect(normalizeSpokenPhoneNumber('one two ٣٤', localeId: 'fr-FR'), '34');
    });

    test(
      'should ignore unrecognized words while retaining recognized digits',
      () {
        expect(
          normalizeSpokenPhoneNumber('one contact two', localeId: 'en-US'),
          '12',
        );
      },
    );

    test('should return null when a transcript has no phone characters', () {
      expect(
        normalizeSpokenPhoneNumber('call my contact', localeId: 'en-US'),
        isNull,
      );
    });
  });
}
