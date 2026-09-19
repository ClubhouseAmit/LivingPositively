/// Consistent spacing tokens for the app.
///
/// Base unit: 4dp. Scale: xs (1×), sm (2×), md (3×), lg (4×), xl (5×),
/// xxl (6×), xxxl (8×). Relocated verbatim from `lib/util/theme/spacing.dart`
/// as step 1 of the design-system extraction — this file had no Material
/// import to begin with.
abstract class AppSpacing {
  /// 1dp rule — dividers. Off the 4dp scale on purpose: a 4dp rule
  /// reads as a bar, not a separator.
  static const hairline = 1.0;

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Text-field height. DESIGN.md §3.4.
  static const input = 40.0;
}

/// Border-radius tokens used by shared layout affordances.
abstract class AppRadii {
  /// Standard card radius from the design system.
  static const card = 16.0;

  /// Standard action-button radius. DESIGN.md §2.3 documents this as
  /// "Standard Buttons", but until `Button` (design-system step 3) no
  /// named token existed for it — `primaryButtonStyle`/`destructiveButtonStyle`
  /// hardcoded this same radius directly on their `RoundedRectangleBorder`.
  static const button = 20.0;

  /// Fixed dashed add-slot pill radius that preserves its dash cadence.
  static const dashedAddSlot = 24.0;

  /// Fully rounded capsule — badges, progress track, switch track.
  /// DESIGN.md §2.3 "Round Badges".
  static const badge = 50.0;

  /// Text-field corners. DESIGN.md §2.3 "Input Fields".
  static const input = 10.0;
}

/// Semantic spacing shared between onboarding flows (intro and questionnaire).
abstract class OnboardingGaps {
  /// Section heading to caption (Figma: Frame 223).
  static const labelToCaption = AppSpacing.xs;

  /// Card to card and suggestions link (Figma: Frames 210, 216, 223).
  static const withinGroup = AppSpacing.sm;

  /// Field label to field box (Figma: Frame 28 Group 143; 32 + 5 + 53 = 90).
  static const labelToField = 5.0;

  /// Title to subtitle, row to row (Figma: Frames 199, 205, 207 itemSpacing 16).
  static const withinBlock = AppSpacing.lg;

  /// Container block to block.
  static const betweenBlocks = AppSpacing.lg;

  /// Questionnaire wizard: header to step content.
  static const questionnaireHeaderToContent = AppSpacing.xxl;

  /// Questionnaire wizard: vertical padding around action buttons.
  static const questionnaireAroundActions = AppSpacing.lg;
}
