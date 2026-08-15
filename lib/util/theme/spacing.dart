/// Consistent spacing tokens for the app.
///
/// Base unit: 4dp (Material Design standard)
/// Scale: xs (1×), sm (2×), md (3×), lg (4×), xl (5×), xxl (6×), xxxl (8×)
///
/// Usage:
/// ```dart
/// padding: EdgeInsets.symmetric(
///   horizontal: AppSpacing.lg,
///   vertical: AppSpacing.md,
/// )
/// ```
abstract class AppSpacing {
  // Extra small: 4dp
  static const xs = 4.0;

  // Small: 8dp
  static const sm = 8.0;

  // Medium: 12dp
  static const md = 12.0;

  // Large: 16dp (default padding)
  static const lg = 16.0;

  // Extra large: 20dp
  static const xl = 20.0;

  // Extra extra large: 24dp
  static const xxl = 24.0;

  // Extra extra extra large: 32dp
  static const xxxl = 32.0;
}

/// Gaps between the *named containers* of an onboarding Figma frame, shared by
/// both onboarding flows.
///
/// These are semantic names for design boundaries, not a second scale — each
/// resolves to an [AppSpacing] step. They exist because a gap identified by the
/// two containers it separates survives a redesign, while `SizedBox(height: 16)`
/// scattered across five files does not.
///
/// Sources — the auto-layout `itemSpacing` on the frames' own containers, which
/// is the only vertical spacing the designer actually set. Everything else
/// between blocks is free positioning on the canvas, i.e. slack, and must be
/// expressed as flex rather than as a constant:
///
///   questionnaire  Android Large - 10/15  Frame 210 / 216 / 223
///   intro          Android Large - 2/28/19  Frames 199/205/207, 201/204/206
abstract class OnboardingGaps {
  /// Section heading to its caption. Figma: Frame 223's inner label group.
  static const labelToCaption = AppSpacing.xs;

  /// Card to card, and cards to the "other suggestions" link.
  static const withinGroup = AppSpacing.sm;

  /// A field's label to the field itself. Figma frame 28, Group 143: the label
  /// box ends at 267 and the field starts at 272, inside a group that is
  /// exactly 90 tall (32 + 5 + 53). Off the 4pt scale on purpose — the group
  /// height is the thing the design fixes, and 5 is what makes it land.
  static const labelToField = 5.0;

  /// Title to subtitle, row to row, rows to "add your own".
  /// Figma: title-block `itemSpacing` — 16 on Frames 199/205/207 too, so the
  /// two flows genuinely share this one.
  static const withinBlock = AppSpacing.lg;

  /// Title block to items block to suggestions block.
  static const betweenBlocks = AppSpacing.lg;

  /// Last action to the step dots, inside the intro flow's actions block.
  /// Figma: Frames 201/204/206 `itemSpacing` — 28.
  static const actionsToDots = 28.0;

  /// Primary button to the secondary link beneath it.
  /// Figma: frame 19, node 1660:2845 "Row 3".
  static const primaryToSecondary = AppSpacing.lg;

  /// Top of the usable area to the header control. Figma: the status bar ends
  /// at 24 and the header (node 1660:2302) starts at 51.
  ///
  /// Relative to the safe area, not the screen: the app consumes the device
  /// inset once in `main.dart`, and nothing below that can find out how tall it
  /// was — `MediaQuery.removePadding` zeroes `viewPadding` as well as
  /// `padding`. So this reproduces the design's spacing *below the chrome*,
  /// which on a device with a taller status bar than the frame's 24 puts the
  /// page correspondingly lower down the screen.
  static const chromeToHeader = 27.0;

  /// Header control's baseline to the title block below it.
  /// Figma: header bottom 84 to Frames 199/205/207 at 104.
  static const headerToTitle = 20.0;

  /// Step dots to the bottom of the usable screen. Figma: Group 470's bottom
  /// (726) sits 26 above the frame's bottom chrome (752).
  static const dotsToBottom = 26.0;

  /// Questionnaire wizard: its header to the step's first content. Carried over
  /// from #344, where it was `_gapHeaderToContent`; that flow's Figma frames
  /// have not been re-measured here, so this preserves the shipped value rather
  /// than claiming a node for it.
  static const questionnaireHeaderToContent = AppSpacing.xxl;

  /// Questionnaire wizard: above and below its action button. Carried over from
  /// #344's `_gapContentToButton`, same caveat.
  static const questionnaireAroundActions = AppSpacing.lg;
}

/// Sizes of onboarding elements, as opposed to the gaps between them.
/// Same sourcing rule as [OnboardingGaps]: every value names the Figma node it
/// came from, and nothing here is chosen because it looked about right.
///
/// These live beside the gaps rather than next to their call sites so that a
/// design change is one edit in one file. Scattering them across the widgets
/// that happen to use them is what made the same 40pt button height get
/// defined twice, in two files, with nothing keeping them in step.
abstract class OnboardingSizes {
  /// Screen-edge inset of every full-width block. Figma: actions blocks and
  /// field groups sit at x 15 on a 360pt frame.
  static const screenInset = 15.0;

  /// The header control row. Figma nodes 1660:2302 (skip, 33 tall) and
  /// 1660:2340 (chevron) — the taller of the two sets the row.
  static const headerHeight = 33.0;

  /// Painted height of the primary pill. Figma nodes 1660:1272,
  /// I1660:2301;325:1 and 1660:2319 are all 40 tall.
  static const primaryButtonHeight = 40.0;

  /// Step dots. Figma nodes 1660:1269-1271 — 10pt circles on a 21pt pitch
  /// (Group 470 is 52 wide for three: 10 + 11 + 10 + 11 + 10).
  static const dotSize = 10.0;
  static const dotGap = 11.0;

  /// Form field box. Figma frame 28, Group 75: 53 tall, 16pt radius.
  static const fieldHeight = 53.0;
  static const fieldRadius = 16.0;

  /// Field label. Figma nodes 1660:2288/2294/2300: 14pt type in a 32pt line
  /// box, which is what makes the label+field group exactly 90 tall.
  static const fieldLabelSize = 14.0;
  static const fieldLabelBox = 32.0;
  static const fieldLabelHeight = fieldLabelBox / fieldLabelSize;

  /// Width of an intro title block on the 360pt frame. The three frames set
  /// 238 / 258 / 228 (Frames 199 / 205 / 207) — copy-width choices around a
  /// common ~240, not three different intentions — so one value carries all
  /// three rather than a per-screen inset. Applied with ScreenUtil's `.w` so
  /// it keeps its proportion on wider devices.
  static const titleBlockWidth = 240.0;
}
