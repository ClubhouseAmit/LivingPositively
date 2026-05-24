import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/languages_util_functions.dart';

void main() {
  group('languageName', () {
    test('en -> English', () => expect(languageName('en'), 'English'));
    test('he -> עברית', () => expect(languageName('he'), 'עברית'));
    test('ar -> العربية', () => expect(languageName('ar'), 'العربية'));
    test('unknown code passes through',
        () => expect(languageName('xx'), 'xx'));
  });

  group('languageCode', () {
    test('English -> en', () => expect(languageCode('English'), 'en'));
    test('עברית -> he', () => expect(languageCode('עברית'), 'he'));
    test('العربية -> ar', () => expect(languageCode('العربية'), 'ar'));
    test('unknown name passes through',
        () => expect(languageCode('Klingon'), 'Klingon'));
  });

  group('getDirectionOfText', () {
    test('Hebrew text returns rtl',
        () => expect(getDirectionOfText('שלום'), 'rtl'));
    test('English text returns ltr',
        () => expect(getDirectionOfText('hello'), 'ltr'));
    test('mixed text with Hebrew returns rtl',
        () => expect(getDirectionOfText('hello שלום'), 'rtl'));
    test('digits-only text defaults to ltr',
        () => expect(getDirectionOfText('12345'), 'ltr'));
    test('empty string defaults to ltr',
        () => expect(getDirectionOfText(''), 'ltr'));
    test('punctuation-only defaults to ltr',
        () => expect(getDirectionOfText('!!!'), 'ltr'));
  });
}
