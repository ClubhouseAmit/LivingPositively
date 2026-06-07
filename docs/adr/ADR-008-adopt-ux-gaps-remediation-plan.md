# ADR-008: Adopt UX Gaps Remediation Tail Plan

- **Status**: proposed
- **Date**: 2026-06-06
- **Deciders**: <leave blank for author to fill>
- **Tags**: ux, accessibility, rtl, crisis-safety, data-integrity, flutter

## Context

ADR-005 established the first UX remediation track for the Mazilon Flutter
mental-health support app. ADR-007 then captured the remaining UX work after
ADR-005 phases A-E. Since that decision, follow-up PRs closed additional gaps
around emergency contact reachability, destructive confirmations, empty states,
bottom-navigation semantics, launch-failure feedback, and the shared async
contract.

[`docs/UX_GAPS_REMEDIATION.md`](../UX_GAPS_REMEDIATION.md) is the current tail
plan after the 2026-06-06 validation pass. It records the remaining safety,
accessibility, localization, data-integrity, and polish work. The remaining
issues are not the original S0 crisis launch failures, but several are still S1
risks because they affect vulnerable users, personal crisis resources,
screen-reader access, legal-gate clarity, media accessibility, and recovery from
destructive actions.

The product context is stable:

- Mazilon is a product UI for distressed or vulnerable users, not a brand
  surface.
- Crisis access must remain reachable and visually primary.
- Users need one clear next action, not high-density legal or wellness copy at
  moments of stress.
- Hebrew, English, Arabic, large text, screen readers, and small screens remain
  first-class constraints.
- Improvements must stay local to existing Flutter boundaries unless a human
  explicitly approves architecture change.

Volatility to contain:

- Wellness CMS data is volatile. Missing keys, malformed video IDs, absent
  transcripts, and misaligned lists must degrade into recoverable UI states
  rather than crashes or inaccessible selectors.
- Localized strings and text length are volatile. Layout must absorb Hebrew,
  English, Arabic, RTL/LTR direction, and large text without per-screen hacks.
- Legal/disclaimer wording may change. Presentation can become more skimmable,
  but legal content and the back-navigation gate remain product/legal decisions.
- User-authored safety content is stable in importance. Deletion, empty drafts,
  and invalid saved state need confirmation, validation, cancel, or undo paths.
- Visual design tokens are stabilizing. Touched code should use `AppColors`,
  `ThemeData`, Material affordances, `.sp`, `myAutoSizedText` where local, and
  RTL-aware layout instead of new one-off styling.
- Broad redesign, dark-mode parity, typography replacement, shared dialog
  frameworks, shared form frameworks, and Material 3 migration are separate
  decisions.

## Decision

Adopt `docs/UX_GAPS_REMEDIATION.md` as the active decision-backed tail backlog
for the remaining UX remediation work. This ADR refines ADR-007 with the newer
validated backlog and supersedes ADR-007's phase sequencing wherever the two
documents conflict. ADR-007 remains historical context for the prior follow-up
plan.

The approved implementation sequence is:

1. **UX Phase F: profile/contact integrity.** Implement Task 1.2 and Task 1.4.
   Validate profile names, preserve gender state when settings are confirmed
   without changes, fix active language highlighting, validate personal
   emergency contacts, prevent blank contact persistence, and add recovery for
   contact deletion.

2. **UX Phase G: media and home resilience.** Implement Task 1.1 and Task 1.5.
   Add a captions/transcript path for wellness videos where package and content
   ownership allow it, guard malformed CMS data, replace bare video list taps
   with Material semantics, and make the inspirational quote card safe for empty
   data with an undo path for dismiss.

3. **UX Phase H: disclaimer and crisis copy.** Implement Task 1.3 and Task 2.1.
   Remove duplicated disclaimer copy, split the legal gate into skimmable
   localized sections, keep the language selector reachable, and demote the
   Phone page contact disclaimer so emergency numbers and personal contacts stay
   visually higher priority.

4. **UX Phase I: destructive recovery.** Implement Task 1.6 and Task 2.2. Add
   confirmation for personal-plan answer deletion, complete Feel Good image
   delete dialog copy, and label fullscreen image controls.

5. **UX Phase J: preview polish.** Implement Task 2.3. Replace brittle
   personal-plan preview sizing with text-scale-aware layout and replace the
   bare "View all" gesture with a standard Material affordance.

Each phase must follow these guard rails:

- Keep changes local to the existing page, widget, provider, model, or factory
  boundary that already owns the behavior.
- Do not create shared dialog, form, validation, UX service, or component
  frameworks unless a human explicitly approves that architecture.
- Route colors through `AppColors`, `Theme.of(context)`, or existing style
  helpers. Do not add one-off colors.
- Use `AsyncStateView` only where the flow has a real async loading, error,
  empty, or retry contract.
- Add all new user-visible strings to Hebrew, English, and Arabic
  localizations.
- Use `Semantics`, tooltips, Material focus/pressed states, 48 dp touch targets,
  `.sp`, and directional layout primitives where relevant.
- Add focused widget tests for behavior and recovery paths, not only
  constructor or source tests.
- Keep the aggregate coverage gate green.

If implementation discovers a new S0 crisis-path failure or a data-loss risk
with higher severity than the current phase, that finding may be promoted ahead
of the sequence. The promotion must be documented in the PR or a follow-up ADR
if it changes scope across boundaries.

## Consequences

### Positive

- Establishes `UX_GAPS_REMEDIATION.md` as the current source of truth for the
  remaining UX backlog.
- Keeps the remediation program focused on crisis safety, accessibility,
  localization, data integrity, and recovery instead of broad visual redesign.
- Preserves ADR-005's existing implementation seams: `AppColors`, `ThemeData`,
  `AsyncStateView`, localization, Provider, Semantics, and local page/widget
  ownership.
- Produces small, reviewable PRs with explicit test expectations.
- Makes volatile CMS data, localization, and legal copy visible planning inputs.

### Negative

- Several small PRs require more coordination than a single broad UX sweep.
- Some wellness media accessibility work depends on player-package capability
  and transcript ownership outside the Flutter widgets.
- Keeping validation and confirmation behavior local may duplicate small amounts
  of code until a human approves a shared boundary.
- Legal-gate presentation changes may require product or legal review even when
  the wording itself is not changed.

### Neutral

- This ADR does not authorize production code changes by itself. It authorizes
  the implementation sequence and constraints for future PRs.
- This ADR does not authorize dark-mode parity, typography migration,
  marketing/brand redesign, Material 3 migration, or broad architecture change.
- File and line references in `UX_GAPS_REMEDIATION.md` are planning evidence.
  Implementers must re-check current source before editing because line numbers
  may drift.
- ADR-007 remains useful historical context, but the active tail backlog is now
  `UX_GAPS_REMEDIATION.md`.

## Links

- [`docs/UX_GAPS_REMEDIATION.md`](../UX_GAPS_REMEDIATION.md)
- [`docs/UX_GAPS.md`](../UX_GAPS.md)
- [`docs/adr/ADR-005-resolve-ux-gaps.md`](ADR-005-resolve-ux-gaps.md)
- [`docs/adr/ADR-007-resolve-remaining-ux-gaps.md`](ADR-007-resolve-remaining-ux-gaps.md)
- [`PRODUCT.md`](../../PRODUCT.md)
