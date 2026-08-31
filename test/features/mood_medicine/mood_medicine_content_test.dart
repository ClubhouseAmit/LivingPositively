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

    test('should preserve the approved activity and D.O.S.E. colour cues', () {
      expect(MoodMedicineContent.activityColors, const <String, Color>{
        MoodMedicineContent.physicalActivityId: Color(0xFF1875D1),
        MoodMedicineContent.restorativeSleepId: Color(0xFF993399),
        MoodMedicineContent.nourishingMealId: Color(0xFFFFD54E),
        MoodMedicineContent.socialConnectionId: Color(0xFFF34235),
        MoodMedicineContent.daylightNatureId: Color(0xFF7BB241),
        MoodMedicineContent.musicId: Color(0xFF0899CC),
        MoodMedicineContent.laughterId: Color(0xFFFF8642),
        MoodMedicineContent.actsOfKindnessId: Color(0xFFFE9701),
      });

      final AppLocalizations english = lookupAppLocalizations(
        const Locale('en'),
      );
      expect(
        MoodMedicineContent.activities(
          english,
        ).map((MoodMedicineActivityContent item) => item.color),
        MoodMedicineContent.defaultActivityIds.map(
          (String id) => MoodMedicineContent.activityColors[id],
        ),
      );
      expect(
        MoodMedicineContent.doseItems(
          english,
        ).map((MoodMedicineDoseContent item) => (item.kind, item.color)),
        const <(MoodMedicineDoseKind, Color)>[
          (MoodMedicineDoseKind.dopamine, Color(0xFF009933)),
          (MoodMedicineDoseKind.oxytocin, Color(0xFF993399)),
          (MoodMedicineDoseKind.serotonin, Color(0xFFFF8642)),
          (MoodMedicineDoseKind.endorphins, Color(0xFF0899CC)),
        ],
      );
    });
  });
}
