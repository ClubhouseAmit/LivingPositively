import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations_en.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';

void main() {
  test('builds all default Personal Plan export metadata in display order', () {
    final localizations = AppLocalizationsEn();
    final metadata = buildPersonalPlanExportMetadata(localizations, 'male');

    expect(metadata.titles, [
      localizations.distractionsHeader('male'),
      localizations.difficultEventsHeader('male'),
      localizations.feelBetterHeader('male'),
      localizations.makeSaferHeader('male'),
      localizations.phonesPageHeader('male'),
      localizations.safeEnvironmentHeader('male'),
    ]);
    expect(metadata.subTitles, [
      localizations.distractionsSubTitle('male'),
      localizations.difficultEventsSubTitle('male'),
      localizations.feelBetterSubTitle('male'),
      localizations.makeSaferSubTitle('male'),
      localizations.phonesPageSubTitle('male'),
      localizations.safeEnvironmentSubTitle('male'),
    ]);
  });
}
