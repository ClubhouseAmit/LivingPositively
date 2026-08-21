import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/l10n/app_localizations_ar.dart';
import 'package:mazilon/l10n/app_localizations_en.dart';
import 'package:mazilon/l10n/app_localizations_he.dart';
import 'package:mazilon/util/persistent_memory_service.dart';

const String dreamsAndGoalsSelectionStorageKey =
    'userSelectionPersonalPlan-DreamsAndGoals';
const String dreamsAndGoalsSelectionSourcesStorageKey =
    'selectionSourcesPersonalPlan-DreamsAndGoals';
const String dreamsAndGoalsCustomSelectionsStorageKey =
    'addedStringsPersonalPlan-DreamsAndGoals';
const String dreamsAndGoalsCustomSelectionSource = 'custom';
const String _dreamsAndGoalsCatalogueSelectionSourcePrefix = 'catalogue:';

/// Immutable ids for the ordered Dreams and Goals catalogue.
///
/// The localized labels may change, but these ids retain the selection
/// identity used by local Personal Plan persistence.
const List<String> dreamsAndGoalsCatalogueIds = <String>[
  'write-and-publish-a-book',
  'learn-a-new-language',
  'fly-in-a-hot-air-balloon',
  'run-a-marathon-or-half-marathon',
  'run-five-kilometers',
  'start-my-own-business',
  'learn-to-play-a-musical-instrument',
  'volunteer-regularly',
  'travel-to-my-dream-destination',
  'complete-a-degree-or-certificate',
  'forgive-someone-who-hurt-me',
  'buy-my-own-home',
  'give-a-talk-to-an-audience',
  'go-skydiving',
  'learn-to-surf',
  'adopt-a-pet',
  'start-a-podcast-or-blog',
  'plant-and-tend-my-own-garden',
  'get-a-motorcycle-or-boat-license',
  'get-a-drivers-license',
  'overcome-my-greatest-fear',
  'see-the-northern-lights',
  'start-or-grow-a-family',
  'develop-an-invention-or-app',
  'attend-a-vipassana-workshop-or-silent-retreat',
  'write-a-song-or-musical-piece',
  'organize-a-large-gathering',
  'learn-to-cook-a-gourmet-meal',
  'achieve-financial-independence',
  'exhibit-my-work',
  'donate-a-meaningful-amount',
  'get-angry-less-often',
  'find-a-romantic-relationship',
  'earn-more-money',
];

const List<String> _dreamsAndGoalsCatalogueGenders = <String>[
  'male',
  'female',
  'other',
];

/// Returns the stable catalogue source for [index].
///
/// [index] must be in the inclusive-exclusive range
/// `[0, dreamsAndGoalsCatalogueIds.length)`; invalid indices throw
/// [RangeError].
String dreamsAndGoalsCatalogueSelectionSourceForIndex(int index) {
  if (index < 0 || index >= dreamsAndGoalsCatalogueIds.length) {
    throw RangeError.range(
      index,
      0,
      dreamsAndGoalsCatalogueIds.length - 1,
      'index',
    );
  }
  return '$_dreamsAndGoalsCatalogueSelectionSourcePrefix'
      '${dreamsAndGoalsCatalogueIds[index]}';
}

/// Whether [source] is a catalogue token backed by a known immutable id.
bool isDreamsAndGoalsCatalogueSelectionSource(String source) {
  if (!source.startsWith(_dreamsAndGoalsCatalogueSelectionSourcePrefix)) {
    return false;
  }
  final String id = source.substring(
    _dreamsAndGoalsCatalogueSelectionSourcePrefix.length,
  );
  return dreamsAndGoalsCatalogueIds.contains(id);
}

/// Returns the ordered localized Dreams and Goals catalogue for [gender].
List<String> retrieveDreamsAndGoalsList(
  AppLocalizations localization,
  String gender,
) {
  return <String>[
    localization.dreamsAndGoalsListNo0(gender),
    localization.dreamsAndGoalsListNo1(gender),
    localization.dreamsAndGoalsListNo2(gender),
    localization.dreamsAndGoalsListNo3(gender),
    localization.dreamsAndGoalsListNo4(gender),
    localization.dreamsAndGoalsListNo5(gender),
    localization.dreamsAndGoalsListNo6(gender),
    localization.dreamsAndGoalsListNo7(gender),
    localization.dreamsAndGoalsListNo8(gender),
    localization.dreamsAndGoalsListNo9(gender),
    localization.dreamsAndGoalsListNo10(gender),
    localization.dreamsAndGoalsListNo11(gender),
    localization.dreamsAndGoalsListNo12(gender),
    localization.dreamsAndGoalsListNo13(gender),
    localization.dreamsAndGoalsListNo14(gender),
    localization.dreamsAndGoalsListNo15(gender),
    localization.dreamsAndGoalsListNo16(gender),
    localization.dreamsAndGoalsListNo17(gender),
    localization.dreamsAndGoalsListNo18(gender),
    localization.dreamsAndGoalsListNo19(gender),
    localization.dreamsAndGoalsListNo20(gender),
    localization.dreamsAndGoalsListNo21(gender),
    localization.dreamsAndGoalsListNo22(gender),
    localization.dreamsAndGoalsListNo23(gender),
    localization.dreamsAndGoalsListNo24(gender),
    localization.dreamsAndGoalsListNo25(gender),
    localization.dreamsAndGoalsListNo26(gender),
    localization.dreamsAndGoalsListNo27(gender),
    localization.dreamsAndGoalsListNo28(gender),
    localization.dreamsAndGoalsListNo29(gender),
    localization.dreamsAndGoalsListNo30(gender),
    localization.dreamsAndGoalsListNo31(gender),
    localization.dreamsAndGoalsListNo32(gender),
    localization.dreamsAndGoalsListNo33(gender),
  ];
}

/// Returns the source token for a known localized catalogue [text].
///
/// Legacy custom text equal to a catalogue label is indistinguishable without
/// source metadata and therefore resolves to the matching catalogue token.
/// Explicitly saved `custom` tokens remain authoritative in
/// [normalizeDreamsAndGoalsSelectionSources].
String? dreamsAndGoalsSelectionSourceForLocalizedText(String text) {
  final List<AppLocalizations> localizations = <AppLocalizations>[
    AppLocalizationsEn(),
    AppLocalizationsHe(),
    AppLocalizationsAr(),
  ];

  for (final AppLocalizations localization in localizations) {
    for (final String gender in _dreamsAndGoalsCatalogueGenders) {
      final int index = retrieveDreamsAndGoalsList(
        localization,
        gender,
      ).indexOf(text);
      if (index >= 0) {
        return dreamsAndGoalsCatalogueSelectionSourceForIndex(index);
      }
    }
  }
  return null;
}

/// Returns one validated source per [selectedItems] row.
///
/// An explicit `custom` source is always retained, including when its text
/// matches a catalogue label. Catalogue tokens are retained only when their id
/// exactly matches the token reconstructed from the corresponding localized
/// row. Missing, malformed, surplus, and mismatched sources are reconstructed
/// from the row text or become `custom` when no catalogue match exists.
List<String> normalizeDreamsAndGoalsSelectionSources(
  List<String> selectedItems,
  List<String> storedSources,
) {
  return List<String>.generate(selectedItems.length, (int index) {
    final String? reconstructedSource =
        dreamsAndGoalsSelectionSourceForLocalizedText(selectedItems[index]);
    if (index < storedSources.length) {
      final String storedSource = storedSources[index];
      if (storedSource == dreamsAndGoalsCustomSelectionSource) {
        return dreamsAndGoalsCustomSelectionSource;
      }
      if (storedSource == reconstructedSource &&
          isDreamsAndGoalsCatalogueSelectionSource(storedSource)) {
        return storedSource;
      }
    }
    return reconstructedSource ?? dreamsAndGoalsCustomSelectionSource;
  });
}

/// Returns only the selected rows whose source is explicitly `custom`.
List<String> dreamsAndGoalsCustomItems(
  List<String> selectedItems,
  List<String> selectionSources,
) {
  final List<String> normalizedSources =
      normalizeDreamsAndGoalsSelectionSources(selectedItems, selectionSources);
  return <String>[
    for (final (int index, String item) in selectedItems.indexed)
      if (normalizedSources[index] == dreamsAndGoalsCustomSelectionSource) item,
  ];
}

/// An immutable three-key local-persistence payload for Dreams and Goals.
final class DreamsAndGoalsPersistenceSnapshot {
  DreamsAndGoalsPersistenceSnapshot._({
    required List<String> selections,
    required List<String> selectionSources,
    required List<String> customSelections,
  }) : selections = List<String>.unmodifiable(selections),
       selectionSources = List<String>.unmodifiable(selectionSources),
       customSelections = List<String>.unmodifiable(customSelections);

  /// Creates a validated snapshot from positional selected rows and sources.
  ///
  /// This preserves every selected row, including multiple explicit `custom`
  /// rows. Source normalization never drops valid custom goals.
  factory DreamsAndGoalsPersistenceSnapshot.fromSelections(
    List<String> selections,
    List<String> selectionSources,
  ) {
    if (selections.length != selectionSources.length) {
      throw ArgumentError.value(
        selectionSources,
        'selectionSources',
        'Must contain one source for every selected Dreams and Goals row.',
      );
    }
    final List<String> selectedCopy = List<String>.from(selections);
    final List<String> normalizedSources =
        normalizeDreamsAndGoalsSelectionSources(selectedCopy, selectionSources);
    return DreamsAndGoalsPersistenceSnapshot._(
      selections: selectedCopy,
      selectionSources: normalizedSources,
      customSelections: dreamsAndGoalsCustomItems(
        selectedCopy,
        normalizedSources,
      ),
    );
  }

  /// Ordered localized display text selected by the user.
  final List<String> selections;

  /// One validated source token for every item in [selections].
  final List<String> selectionSources;

  /// The explicit custom subset of [selections].
  final List<String> customSelections;
}

/// Persists every Dreams and Goals storage key from one immutable [snapshot].
///
/// Writes complete sequentially: selections, source tokens, then custom-only
/// selections. A failed write stops this attempt before later keys begin.
Future<void> persistDreamsAndGoalsSnapshot(
  PersistentMemoryService service,
  DreamsAndGoalsPersistenceSnapshot snapshot,
) async {
  await service.setItem(
    dreamsAndGoalsSelectionStorageKey,
    PersistentMemoryType.StringList,
    snapshot.selections,
  );
  await service.setItem(
    dreamsAndGoalsSelectionSourcesStorageKey,
    PersistentMemoryType.StringList,
    snapshot.selectionSources,
  );
  await service.setItem(
    dreamsAndGoalsCustomSelectionsStorageKey,
    PersistentMemoryType.StringList,
    snapshot.customSelections,
  );
}
