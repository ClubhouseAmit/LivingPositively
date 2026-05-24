import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/Locale/locale_service.dart';

void main() {
  group('LocaleServiceImpl', () {
    setUp(() {
      LocaleServiceImpl.locale = null;
    });

    test('setLocale with explicit value updates getLocale', () {
      final service = LocaleServiceImpl();
      service.setLocale('he');
      expect(service.getLocale(), 'he');
    });

    test('setLocale("ar") then getLocale returns "ar"', () {
      final service = LocaleServiceImpl();
      service.setLocale('ar');
      expect(service.getLocale(), 'ar');
    });

    test('setLocale(null) falls back to getLocaleName default', () {
      final service = LocaleServiceImpl();
      service.setLocale(null);
      expect(['ar', 'he', 'en'], contains(service.getLocale()));
    });

    test('getLocale returns getLocaleName when locale not set', () {
      final service = LocaleServiceImpl();
      expect(['ar', 'he', 'en'], contains(service.getLocale()));
    });

    test('getLocaleName returns one of the supported codes', () {
      final name = LocaleServiceImpl.getLocaleName();
      expect(['ar', 'he', 'en'], contains(name));
    });

    test('locale persists across multiple instances (static field)', () {
      final a = LocaleServiceImpl();
      a.setLocale('en');
      final b = LocaleServiceImpl();
      expect(b.getLocale(), 'en');
    });
  });
}
