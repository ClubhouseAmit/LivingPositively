import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/l10n/app_localizations_ar.dart';
import 'package:mazilon/l10n/app_localizations_en.dart';
import 'package:mazilon/l10n/app_localizations_he.dart';
import 'package:mazilon/util/dreams_and_goals_selection.dart';

void main() {
  group('Dreams and Goals selection helpers', () {
    test(
      'should create stable tokens for the first and last catalogue ids',
      () {
        expect(
          dreamsAndGoalsCatalogueSelectionSourceForIndex(0),
          'catalogue:${dreamsAndGoalsCatalogueIds.first}',
        );
        expect(
          dreamsAndGoalsCatalogueSelectionSourceForIndex(
            dreamsAndGoalsCatalogueIds.length - 1,
          ),
          'catalogue:${dreamsAndGoalsCatalogueIds.last}',
        );
      },
    );

    test('should reject catalogue indices outside the documented range', () {
      expect(
        () => dreamsAndGoalsCatalogueSelectionSourceForIndex(-1),
        throwsRangeError,
      );
      expect(
        () => dreamsAndGoalsCatalogueSelectionSourceForIndex(
          dreamsAndGoalsCatalogueIds.length,
        ),
        throwsRangeError,
      );
    });

    test(
      'should map every English Hebrew and Arabic catalogue label to its id',
      () {
        final List<AppLocalizations> localizations = <AppLocalizations>[
          AppLocalizationsEn(),
          AppLocalizationsHe(),
          AppLocalizationsAr(),
        ];

        for (final AppLocalizations localization in localizations) {
          for (final String gender in <String>['male', 'female', 'other']) {
            final List<String> labels = retrieveDreamsAndGoalsList(
              localization,
              gender,
            );
            expect(labels, hasLength(dreamsAndGoalsCatalogueIds.length));

            for (final (int index, String label) in labels.indexed) {
              expect(
                dreamsAndGoalsSelectionSourceForLocalizedText(label),
                dreamsAndGoalsCatalogueSelectionSourceForIndex(index),
                reason: '${localization.runtimeType} $gender item $index',
              );
            }
          }
        }
      },
    );

    test('should repair mismatched catalogue tokens from the row text', () {
      const List<String> selected = <String>[
        'Write and publish a book',
        'Learn a new language',
      ];

      expect(
        normalizeDreamsAndGoalsSelectionSources(selected, const <String>[
          'catalogue:learn-a-new-language',
          'catalogue:write-and-publish-a-book',
        ]),
        const <String>[
          'catalogue:write-and-publish-a-book',
          'catalogue:learn-a-new-language',
        ],
      );
    });

    test('should keep a catalogue-label own goal explicitly custom', () {
      const List<String> selected = <String>['Write and publish a book'];
      const List<String> sources = <String>[
        dreamsAndGoalsCustomSelectionSource,
      ];

      expect(
        normalizeDreamsAndGoalsSelectionSources(selected, sources),
        sources,
      );
      expect(dreamsAndGoalsCustomItems(selected, sources), selected);
    });

    test(
      'should reconstruct malformed sources and preserve unknown rows custom',
      () {
        expect(
          normalizeDreamsAndGoalsSelectionSources(
            const <String>[
              'Write and publish a book',
              'A goal outside the catalogue',
            ],
            const <String>['catalogue:not-a-real-id'],
          ),
          const <String>[
            'catalogue:write-and-publish-a-book',
            dreamsAndGoalsCustomSelectionSource,
          ],
        );
      },
    );
  });
}
