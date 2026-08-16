import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/userInformation.dart';

/// The four gender choices offered by the onboarding form and by user
/// settings.
///
/// [UserInformation] persists the choice across two fields — `gender`
/// ('male', 'female' or '') and `binary` — so a screen that wants the choice
/// itself has to reassemble it. This enum owns that reassembly, along with
/// the two other mappings the choice feeds: the localized dropdown label and
/// the key the suggestion lists are stored under.
enum Gender {
  male('male'),
  female('female'),
  nonBinary(''),
  unspecified('');

  const Gender(this.code);

  /// The value stored in `UserInformation.gender`, also passed to the
  /// gendered localized strings.
  final String code;

  /// The choice currently stored on [userInfo].
  ///
  /// `binary` wins over `gender`, matching how the choice is written back.
  static Gender of(UserInformation userInfo) =>
      userInfo.binary ? Gender.nonBinary : fromCode(userInfo.gender);

  /// The choice a stored [code] belongs to. An empty or unknown code is
  /// [Gender.unspecified] — non-binary is only distinguishable via `binary`.
  static Gender fromCode(String code) => switch (code) {
    'male' => Gender.male,
    'female' => Gender.female,
    _ => Gender.unspecified,
  };

  /// The choice labelled [label] in [locale], or null when none matches.
  static Gender? fromLabel(String label, AppLocalizations locale) {
    for (final gender in Gender.values) {
      if (gender.label(locale) == label) return gender;
    }
    return null;
  }

  /// Every label, in the order the dropdowns list them.
  static List<String> labels(AppLocalizations locale) => [
    for (final gender in Gender.values) gender.label(locale),
  ];

  String label(AppLocalizations locale) => switch (this) {
    Gender.male => locale.male,
    Gender.female => locale.female,
    Gender.nonBinary => locale.nonBinary,
    Gender.unspecified => locale.notWillingToSay,
  };

  /// Key the suggestion lists are keyed by: they only distinguish male,
  /// female and everyone else.
  String get listKey => code.isEmpty ? 'other' : code;

  /// Writes the choice back to the two fields [UserInformation] stores.
  void applyTo(UserInformation userInfo) {
    userInfo.updateBinary(this == Gender.nonBinary);
    userInfo.updateGender(code);
  }
}
