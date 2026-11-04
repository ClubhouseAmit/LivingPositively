/// Button measurements from the LP-DS Figma file, page "Buttons" (70:2383).
///
/// Owned here rather than borrowed from `AppRadii`/`AppSpacing` values that
/// happen to match: a badge or spacing change must not reshape the buttons.
/// Padding and gaps do use `AppSpacing`, since those are the shared scale.
abstract class LpButtonSizes {
  /// Figma radius 99: a full pill at any button height.
  static const pillRadius = 99.0;
  static const border = 1.0;

  /// Minimum tap area, whatever the visible size.
  static const minTapTarget = 48.0;

  // -- LpButton --
  static const heightM = 48.0;
  static const heightS = 32.0;
  static const minWidthM = 72.0;
  static const minWidthS = 48.0;
  static const iconM = 22.0;
  static const iconS = 18.0;

  // -- LpButton.icon --
  static const iconButtonXs = 24.0;
  static const iconButtonS = 32.0;
  static const iconButtonM = 48.0;
  static const iconButtonIconXs = 16.0;
  static const iconButtonIconS = 24.0;
  static const iconButtonIconM = 40.0;
  static const iconButtonRadius = 20.0;
  static const iconButtonPressedRadius = 8.0;

  // -- LpButtonVariant.text --
  static const textButtonHeight = 32.0;
  static const textButtonMinWidth = 48.0;
  static const textButtonIcon = 16.0;
}
