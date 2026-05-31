# ADR-007: Resolve Remaining UX Gaps After ADR-005

- **Status**: proposed
- **Date**: 2026-05-31
- **Deciders**: <leave blank for author to fill>
- **Tags**: ux, accessibility, rtl, crisis-safety, wellness, flutter

## Context

ADR-005 accepted and shipped the first UX remediation track for the Mazilon
Flutter mental-health support app. That work closed the highest-risk S0
crisis-path gaps and established the first cross-cutting UX foundations:

- explicit launch-failure feedback for calls, SMS, WhatsApp, and external apps;
- SOS visibility during fullscreen wellness video;
- country-fallback disclosure for emergency numbers;
- screen-reader labels and touch-target fixes on the main crisis path;
- RTL directionality cleanup;
- `ThemeData` plus semantic `AppColors`;
- a shared loading/error contract through `AsyncStateView`.

The follow-up plan in
[`docs/plans/2026-05-31-remaining-ux-gaps-plan.md`](../plans/2026-05-31-remaining-ux-gaps-plan.md)
identifies the remaining UX work after ADR-005 phases A-E. These gaps are no
longer the original S0 blockers, but they still affect user trust, vulnerable
user flows, RTL quality, and safe handling of personal content.

The most important remaining surfaces are:

- first-run trust and disclaimer readability;
- emergency-page completeness for personal crisis contacts;
- state/list resilience in home, journal, and positive-trait flows;
- destructive actions on user-authored content;
- responsive and RTL layout polish;
- wellness video captions/transcripts;
- continued visual-token consolidation.

Volatility to contain:

- Legal/disclaimer wording may change, but the app should keep a skimmable,
  low-anxiety presentation pattern stable.
- Crisis-contact data and emergency-number behavior are stable user-safety
  responsibilities; page layout and entry affordances may change.
- Localization content, text length, and RTL/LTR direction are volatile and
  must be absorbed by layout choices rather than one-off branching.
- Visual tokens should continue to stabilize; typography and broad visual
  redesign remain product/design decisions, not implementation defaults.
- Video content ownership and transcript availability are external to the
  Flutter codebase and must be confirmed before adding transcript text.

Runtime visual inspection during the follow-up review was limited: a release
web build succeeded, but headless screenshots remained on a blank white frame.
That uncertainty is itself a planning input: visual implementation must begin
with real device/emulator screenshots before lower-priority polish changes.

## Decision

Adopt the remaining UX remediation plan as a staged follow-up to ADR-005.
The work will be delivered in small, separately reviewable phases. Each phase
must preserve existing architecture and page boundaries, prefer existing
patterns (`AppColors`, `ThemeData`, `AsyncStateView`, localization, Provider),
and avoid new shared abstractions unless an existing boundary already owns the
behavior.

The approved sequence is:

1. **Phase 0: Visual baseline.** Capture real-device/emulator screenshots for
   English LTR, Hebrew RTL, and Arabic RTL at small-phone and wider viewports.
   Verify whether the blank web first frame is a headless-only artifact or a
   real startup issue. Promote any real startup blank screen ahead of polish
   work.

2. **Phase 1: Onboarding and trust.** Restructure the disclaimer into
   skimmable sections without changing legal content. Revisit
   `PopScope(canPop: false)` only with human confirmation of the intended exit
   model. Replace raw startup/loading colors with theme tokens.

3. **Phase 2: Emergency page completion.** Add a direct add/edit affordance for
   personal emergency contacts on the emergency page by reusing existing phone
   contact data and form/list behavior. Shorten or restructure the page
   disclaimer so emergency actions remain immediately scannable.

4. **Phase 3: State and list resilience.** Remove rebuild-driven home
   randomization, guard short/empty suggestion lists, replace empty
   `Container()` states with localized guidance, and replace the repeated
   delayed positive-trait popup with a non-nagging pattern.

5. **Phase 4: Destructive actions.** Add confirmation or undo for journal,
   positive-trait, and image deletion paths where personal user content can be
   lost. Prefer snackbar undo only where the existing data model can support
   reversible deletion without broad refactoring; otherwise use confirmation.

6. **Phase 5: Responsive and RTL layout polish.** Replace hard-coded field
   widths/heights, fixed quote height, brittle personal-plan grid sizing, and
   manual left/right branching with constraint-aware and directionality-aware
   layout.

7. **Phase 6: Wellness accessibility.** Add a caption/transcript path for
   prerecorded wellness videos, after confirming content source and ownership.
   Smooth fullscreen chrome transitions and re-validate SOS behavior over the
   player.

8. **Phase 7: Visual-system consolidation.** Continue migrating touched UI
   from raw colors to semantic tokens. Keep `Rubix` unless a human explicitly
   approves typography changes. Treat the `ui-ux-pro-max` typography suggestion
   as design-review input, not an implementation decision.

Emergency-page work stays near the front because it is crisis-adjacent.
Visual-system consolidation stays last unless a touched file already needs
token cleanup.

Each phase must include focused widget tests where feasible, a relevant
`flutter test` run or narrower suite, and manual screenshot review for English,
Hebrew, and Arabic at small-phone scale.

## Consequences

### Positive

- Keeps ADR-005's user-safety trajectory moving without reopening the shipped
  crisis-path foundation.
- Turns the remaining UX plan into a decision record with reviewable scope and
  phase ordering.
- Preserves existing architecture while still addressing trust, accessibility,
  RTL, and content-loss risks.
- Makes real visual baselining mandatory before implementing polish changes.
- Keeps emergency-page completion prioritized because it is crisis-adjacent.

### Negative

- Adds several small PRs instead of one broad UX sweep, increasing coordination
  overhead.
- Some improvements, especially captions/transcripts, require content ownership
  decisions outside the Flutter codebase.
- Reworking disclaimer presentation may require legal/product review before
  implementation, even if wording is unchanged.
- Confirmation/undo behavior may expose existing data-model limitations in
  journal, positive-trait, or image flows.

### Neutral

- This ADR does not authorize broad redesign, new architecture, Material 3
  migration, or typography replacement.
- Existing `AppColors`, `ThemeData`, `AsyncStateView`, localization, and
  Provider patterns remain the preferred implementation seams.
- Phase order may be adjusted after Phase 0 if baseline screenshots reveal a
  startup or layout problem with higher user impact.
- AgentDB registration requested by the local `adr-create` skill is not part of
  the repository artifact and depends on MCP tool availability in the active
  agent session.

## Links

- [`docs/plans/2026-05-31-remaining-ux-gaps-plan.md`](../plans/2026-05-31-remaining-ux-gaps-plan.md)
- [`docs/UX_GAPS.md`](../UX_GAPS.md)
- [`docs/adr/ADR-005-resolve-ux-gaps.md`](ADR-005-resolve-ux-gaps.md)
