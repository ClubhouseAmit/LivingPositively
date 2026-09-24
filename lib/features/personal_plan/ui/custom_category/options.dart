import 'package:mazilon/l10n/app_localizations.dart';

/// Returns the localized custom-category suggestions in their stable display
/// order. The final entry is the explicit free-form input option.
///
/// Callers should pass the returned list unchanged to custom-category editors
/// so the wizard and summary surfaces expose the same suggestions.
List<String> localizedCustomCategoryTitles(AppLocalizations localizations) => [
  localizations.customCategoryOptionEmpoweringQuotes,
  localizations.customCategoryOptionPastEvents,
  localizations.customCategoryOptionAboutMe,
  localizations.customCategoryOptionCustomInput,
];
