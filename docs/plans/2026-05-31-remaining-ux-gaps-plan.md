# Remaining UX Gaps Resolution Plan

Date: 2026-05-31
Scope: Mazilon Flutter mental-health support app
Source: Follow-up UX review after `docs/UX_GAPS.md` and ADR-005 phases A-E.

## Context

The original UX audit identified two S0 crisis-path issues and several S1 accessibility, RTL, and touch-target gaps. ADR-005 records that phases A-E have shipped:

- Phase A: crisis path hardening
- Phase B: accessibility pass
- Phase C: RTL pass
- Phase D: theme and semantic tokens
- Phase E: loading/error contract

The current review confirms the highest-risk crisis-path fixes appear present in source:

- Launch failures now show snackbar feedback and a copy fallback in `lib/util/Phone/phoneTextAndIcon.dart`.
- The SOS floating action button remains visible in fullscreen video in `lib/menu.dart`.
- Emergency country fallback is surfaced to users in `lib/util/Phone/EmergencyPhones.dart`.

Runtime visual inspection was limited. `flutter build web --release` succeeds, but headless screenshots stayed on a blank white frame. Before implementing the visual phases below, capture a real device/emulator baseline.

## Design Constraints

- Preserve existing architecture and page boundaries.
- Do not introduce a new shared abstraction unless an existing boundary already owns the behavior.
- Prefer the existing `AppColors`, `ThemeData`, `AsyncStateView`, localization, and Provider patterns.
- Keep each phase reviewable and reversible.
- Validate both RTL and LTR flows because Hebrew and Arabic support are first-class UX surfaces.

## Phase 0: Visual Baseline

Goal: establish current rendered behavior before changing UX.

Tasks:

- Capture screenshots for English LTR, Hebrew RTL, and Arabic RTL.
- Cover phone sizes around `375x812` and `390x844`, plus a tablet/wide viewport.
- Include startup, disclaimer, home, emergency, journal, positive traits, settings, wellness tools, and fullscreen video.
- Verify whether the blank web first frame is only a headless-review issue or a real startup problem.

Acceptance criteria:

- Screenshot set is attached to the implementation PR or saved in an agreed QA artifact location.
- Any real startup blank-screen issue is promoted ahead of lower-severity polish work.

## Phase 1: Onboarding And Trust

Goal: reduce friction and anxiety in first-run/legal flows.

Primary targets:

- `lib/disclaimerPage.dart`
- `lib/pages/SignIn_Pages/introduction.dart`

Tasks:

- Break the disclaimer into skimmable sections with headings.
- Add a clear progress or "what this is" structure without changing legal content.
- Revisit the trapped `PopScope(canPop: false)` behavior and confirm the intended exit model with a human before changing it.
- Replace raw startup/loading colors with theme tokens.

Acceptance criteria:

- Disclaimer remains legally complete but is easier to scan.
- Loading state uses `AppColors`/theme styling and existing accessible loading semantics.
- RTL alignment is verified in Hebrew and Arabic.

## Phase 2: Emergency Page Completion

Goal: make the emergency page the complete place for crisis contacts.

Primary targets:

- `lib/pages/phone.dart`
- Existing phone contact form/list code under `lib/form/`

Tasks:

- Add a direct "add/edit my emergency contact" affordance on the emergency page.
- Reuse existing phone contact data and form behavior instead of creating a parallel flow.
- Shorten or restructure the emergency-page disclaimer so emergency numbers remain immediately scannable.
- Keep emergency numbers, personal contacts, and fallback warnings visually distinct.

Acceptance criteria:

- A user can add or edit a personal emergency contact from the emergency page.
- Existing contact persistence remains unchanged.
- Emergency actions stay reachable and visually dominant on small phones.

## Phase 3: State And List Resilience

Goal: remove avoidable flicker, crashes, and empty states that reduce trust.

Primary targets:

- `lib/pages/home.dart`
- `lib/pages/journal.dart`
- `lib/pages/positive.dart`

Tasks:

- Move home personal-plan randomization out of `build()` so rebuilds do not change visible copy unexpectedly.
- Guard journal suggestion selection when the suggestion list is empty or shorter than three items.
- Replace empty `Container()` states with useful localized empty-state copy/actions.
- Replace the repeated delayed positive-trait popup with a non-nagging pattern, such as first-run-only persistence or inline guidance.

Acceptance criteria:

- No `setState` is triggered from `build()` for home randomization.
- Journal and positive-trait suggestions do not crash or silently collapse when lists are short.
- Empty journal/trait states guide the next action.

## Phase 4: Destructive Actions

Goal: prevent accidental loss of personal content.

Primary targets:

- `lib/pages/thankYou.dart`
- `lib/pages/FeelGood/image_display_item.dart`

Tasks:

- Add confirmation or undo for journal and positive-trait deletions.
- Keep edit/delete controls at accessible touch sizes with clear semantics/tooltips.
- Tighten image-delete dialog copy and semantics.
- Prefer snackbar undo where the underlying data model can support reversible deletion without broad refactoring; otherwise use confirmation.

Acceptance criteria:

- Deleting user-authored content requires confirmation or offers undo.
- Screen readers announce edit/delete controls clearly.
- Existing tests for journal, positive traits, and Feel Good still pass.

## Phase 5: Responsive And RTL Layout Polish

Goal: remove layout brittleness from fixed dimensions and directional branching.

Primary targets:

- `lib/pages/UserSettings.dart`
- `lib/util/HomePage/inspirationalQuote.dart`
- `lib/MainPageHelpers/personalPlanWidget.dart`
- `lib/main_menu_dialog.dart`

Tasks:

- Replace hard `width: 300` and `height: 35` settings inputs with responsive constraints and Material minimum tap targets.
- Replace fixed quote height with content-aware layout that handles longer localized quotes.
- Rework the personal-plan grid so longer Hebrew/Arabic text does not overflow.
- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, and inherited `Directionality` instead of manual left/right branching where feasible.
- Align main-menu rows correctly in RTL without changing menu ownership.

Acceptance criteria:

- Settings fields do not overflow on narrow phones.
- Quote and personal-plan content do not clip at large text scale.
- Main menu row order and alignment feel native in RTL and LTR.

## Phase 6: Wellness Accessibility

Goal: make wellness video content usable for users who cannot rely on audio.

Primary targets:

- `lib/pages/WellnessTools/wellnessTools.dart`
- `lib/pages/WellnessTools/player.dart`

Tasks:

- Add captions/transcripts or transcript links for prerecorded wellness videos.
- Confirm content source and ownership before adding transcript text.
- Smooth fullscreen chrome transitions so content does not abruptly jump.
- Validate SOS visibility and tap behavior over fullscreen video.

Acceptance criteria:

- Every video has a caption/transcript path or an explicitly tracked content gap.
- Fullscreen transitions are visually stable.
- SOS remains visible and usable in fullscreen.

## Phase 7: Visual System Consolidation

Goal: reduce color and typography drift without redesigning the product.

Primary targets:

- `lib/util/theme/app_theme.dart`
- `lib/util/styles.dart`
- Remaining raw color call sites found during phased work

Tasks:

- Continue replacing raw colors with `AppColors` and `Theme.of(context).colorScheme`.
- Keep `Rubix` unless a human approves a typography change.
- Treat the `ui-ux-pro-max` Lora/Raleway suggestion as a design-review input, not an implementation decision.
- Avoid broad restyling while functional UX gaps remain.

Acceptance criteria:

- New or touched UI uses semantic tokens.
- No new one-off color literals are added for user-facing UI without justification.
- Typography remains consistent unless product/design explicitly approves a change.

## Verification Strategy

Each phase should include:

- Focused widget tests for changed behavior where feasible.
- `flutter test` or a narrower relevant test suite.
- Manual screenshot review for English, Hebrew, and Arabic.
- Small-phone verification around `375x812` or equivalent.
- Accessibility spot check for labels, roles, and large text scale.

## Recommended Order

1. Phase 0: Visual Baseline
2. Phase 1: Onboarding And Trust
3. Phase 2: Emergency Page Completion
4. Phase 3: State And List Resilience
5. Phase 4: Destructive Actions
6. Phase 5: Responsive And RTL Layout Polish
7. Phase 6: Wellness Accessibility
8. Phase 7: Visual System Consolidation

Emergency-page work stays near the front because it is crisis-adjacent. Visual-system work stays last unless a touched file already needs token cleanup.
