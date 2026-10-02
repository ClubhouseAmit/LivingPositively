import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/shell/ui/app_time_format.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/async/browser_time_format.dart';

void main() {
  group('browserUses24HourFormat', () {
    if (!kIsWeb) {
      test('should return null on native platforms', () {
        expect(browserUses24HourFormat(), isNull);
        expect(browserUses24HourFormat(locale: 'en-GB'), isNull);
      });
      return;
    }

    test('should resolve the browser default without an app locale', () {
      expect(browserUses24HourFormat(), isA<bool>());
    });

    test('should resolve en-US as a 12-hour clock', () {
      expect(browserUses24HourFormat(locale: 'en-US'), isFalse);
    });

    test('should resolve en-GB as a 24-hour clock', () {
      expect(browserUses24HourFormat(locale: 'en-GB'), isTrue);
    });

    test('should honor explicit 12-hour cycles in a 24-hour locale', () {
      expect(browserUses24HourFormat(locale: 'en-GB-u-hc-h11'), isFalse);
      expect(browserUses24HourFormat(locale: 'en-GB-u-hc-h12'), isFalse);
    });

    test('should honor explicit 24-hour cycles in a 12-hour locale', () {
      expect(browserUses24HourFormat(locale: 'en-US-u-hc-h23'), isTrue);
      expect(browserUses24HourFormat(locale: 'en-US-u-hc-h24'), isTrue);
    });

    test('should return null when Intl rejects a locale', () {
      expect(browserUses24HourFormat(locale: 'not_a_locale'), isNull);
    });

    for (final languageCode in ['en', 'ar', 'he']) {
      testWidgets(
        'should apply the browser preference with $languageCode app language',
        (tester) async {
          final browserPreference = browserUses24HourFormat();
          expect(browserPreference, isA<bool>());
          late bool rootPreference;
          late String formattedTime;
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(languageCode),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: appLocalizationsDelegates,
              builder: appTimeFormatBuilder,
              home: Builder(
                builder: (context) {
                  rootPreference = MediaQuery.alwaysUse24HourFormatOf(context);
                  formattedTime = const TimeOfDay(
                    hour: 20,
                    minute: 5,
                  ).format(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
          expect(rootPreference, browserPreference);
          final period = languageCode == 'ar' ? 'م' : 'PM';
          expect(
            formattedTime,
            browserPreference! ? '20:05' : '8:05 $period',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
