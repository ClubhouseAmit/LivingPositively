/// Consistent spacing tokens for the app.
///
/// Base unit: 4dp (Material Design standard)
/// Scale: xs (1×), sm (2×), md (3×), lg (4×), xl (5×), xxl (6×), xxxl (8×)
abstract class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

/// Border-radius tokens used by shared layout affordances.
abstract class AppRadii {
  /// Standard card radius from the design system.
  static const card = 16.0;

  /// Fixed dashed add-slot pill radius that preserves its dash cadence.
  static const dashedAddSlot = 24.0;
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
