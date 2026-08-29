import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_content.dart';

void main() {
  group('MoodMedicineContent', () {
    test(
      'should provide complete activity and D.O.S.E. content in every locale',
      () {
        for (final Locale locale in AppLocalizations.supportedLocales) {
          final AppLocalizations localizations = lookupAppLocalizations(locale);
          final List<MoodMedicineActivityContent> activities =
              MoodMedicineContent.activities(localizations);
          final List<MoodMedicineDoseContent> doseItems =
              MoodMedicineContent.doseItems(localizations);

          expect(
            activities.map((MoodMedicineActivityContent item) => item.id),
            MoodMedicineContent.defaultActivityIds,
            reason: '${locale.languageCode} activity IDs',
          );
          expect(activities, hasLength(8));
          expect(doseItems, hasLength(4));
          for (final MoodMedicineActivityContent activity in activities) {
            expect(activity.label, isNotEmpty);
            expect(activity.description, isNotEmpty);
            expect(activity.guidance, isNotEmpty);
            expect(activity.sourceLabel, isNotEmpty);
            expect(activity.sourceUri.scheme, 'https');
          }
          for (final MoodMedicineDoseContent item in doseItems) {
            expect(item.title, isNotEmpty);
            expect(item.description, isNotEmpty);
          }
        }
      },
    );

    test('should use the corrected Arabic mood tracker label', () {
      final AppLocalizations arabic = lookupAppLocalizations(
        const Locale('ar'),
      );

      expect(arabic.moodMedicineLoading, contains('متتبع المزاج'));
    });
  });
}
