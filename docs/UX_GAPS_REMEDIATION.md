# Mazilon UX Gaps Remediation Plan

**Date:** 2026-06-06
**Companion to:** `docs/UX_GAPS.md` (audit, 2026-05-24)
**Product context:** `PRODUCT.md` (product register, distressed users, WCAG AA + safety)
**Scope:** Remaining UX gaps after Phases A-E and follow-up PRs (#277-#282)
**Constraint:** Plan only. No production code changes are part of this document.

---

## Context

The five-phase remediation program closed the highest-risk issues from
`docs/UX_GAPS.md`: crisis launch failures, broad semantics/RTL gaps, theme
tokens, and async loading/error handling. Current source validation shows that
all known S0 findings and many S1 findings are resolved.

This plan captures the remaining backlog, including corrections found during
the 2026-06-06 `impeccable` validation pass.

### Product north star

Mazilon is a product UI, not a brand surface. Design serves distressed users who
may need fast help, low cognitive load, clear recovery, and accessible controls
while attention and emotional bandwidth are limited.

The remediation rules are:

- Crisis access stays reachable in every app state.
- Distressed users get one clear next action, not walls of text.
- Destructive or dismissive actions need confirmation, undo, or recovery.
- Hebrew, English, Arabic, large text, screen readers, and small screens remain
  first-class constraints.
- Changes stay local to existing Flutter boundaries unless architecture is
  explicitly approved by a human.

### Items verified as already resolved

| Audit ref | Finding | Current evidence |
|---|---|---|
| 1.1 / 1.2 | No theme/token contract | `lib/util/theme/app_theme.dart` defines `AppColors`, `ColorScheme`, light theme, and dark-theme stub. |
| 1.3 / 1.6 | Main icon-only controls and small phone tap target | Home, phone, quote, plan, and bottom nav now use tooltip/semantics patterns; `phoneContact` uses a 48 dp hit area. |
| 1.5 | No shared async contract | `AsyncStateView` exists and Feel Good image loading routes through it. |
| 2.1 | SOS hidden in fullscreen video | `lib/menu.dart` keeps the SOS FAB visible in fullscreen. |
| 2.2 | Dial failure silent | `launchWithFeedback` routes call/app failures to a localized snackbar with copy-number recovery. |
| 2.3 | Emergency country fallback silent | `EmergencyPhonesGrid` renders a live-region fallback banner when country mapping is missing. |
| 2.4 | Emergency-add not reachable from Phone page | `lib/pages/phone.dart` exposes `phonePageManageContactsButton` and opens `PhonePageForm`. |
| 3.4 / 3.5 | Journal and Positive empty states | Both pages now render localized empty guidance instead of blank containers. |
| 3.6 | Journal/trait row delete has no confirmation | `ThankYou` now shows a localized `AlertDialog` before deleting. |
| 3.10 | FeelGood image delete immediate | `image_display_item.dart` now asks for confirmation before delete. Title/body still missing; see Task 2.2. |
| 3.11 | Bottom nav selected state missing | `menu.dart` wraps nav buttons in `Semantics(selected:)`. |

### Guard rails for every remaining task

Reuse existing infrastructure. Do not create cross-cutting abstractions unless
the existing boundary already owns the responsibility.

- Colors: use `AppColors` / existing theme tokens. No new one-off colors.
- Async: use `AsyncStateView` where a real async loading/error/empty contract is
  needed.
- Controls: use `Semantics`, `tooltip`, Material focus/pressed states, and 48 dp
  minimum touch targets.
- Errors: announce inline or live-region feedback where the user can fix the
  problem.
- Text: use `.sp`, `myAutoSizedText` where already local, and RTL-aware
  alignment/insets.
- Strings: add all new copy to `app_localizations` for Hebrew, English, and
  Arabic.
- Tests: add real widget tests for behavior, not only constructor/source tests.
- Coverage: keep the aggregate coverage gate green.

---

## Remaining gaps and tasks

### Priority 1 - Safety, accessibility, and data integrity

#### Task 1.1 - Wellness media accessibility and data safety - S1

**Where:**

- `lib/pages/WellnessTools/player.dart:28-31`
- `lib/pages/WellnessTools/wellnessTools.dart:34-36,65,103-126,151-180`
- `lib/pages/WellnessTools/more_videos_item.dart:28-62`
- CMS `videoData`: `videoId`, `videoHeadline`, `videoDescription`

**Why:**

Deaf/HoH users cannot access spoken wellness content without captions or
transcripts. The current video UI also assumes perfect CMS shape: IDs are long
enough for `substring(0, 11)`, every map key exists, and all value lists are
aligned. In a wellness flow, bad CMS data should degrade gracefully, not crash or
show an inaccessible selector.

**Approach:**

1. Enable YouTube captions where supported by the current player package, and
   default caption language to the active locale when possible.
2. Add optional `videoTranscript` to `videoData`. Render it below the
   description as a localized, RTL-aware collapsible transcript.
3. Guard video data before rendering: missing keys, empty IDs, malformed short
   IDs, and misaligned list lengths should route to a localized empty/error
   state instead of force unwraps or substring crashes.
4. Replace the bare `GestureDetector` in `MoreVideosItem` with a Material
   affordance that exposes button semantics, label/tooltip, focus, and pressed
   state.
5. Keep the selected-video item out of the list without returning a zero-context
   `Container()` that creates confusing separator gaps.

**Files:**

- `wellnessTools.dart`
- `player.dart`
- `VideoPlayerPageFactory.dart`
- `more_videos_item.dart`
- `app_localizations`
- CMS/schema documentation for wellness videos

**Tests:**

- Captions/player flag is configured or the package limitation is documented.
- Transcript tile renders when `videoTranscript[index]` is present.
- Transcript tile is absent when transcript is empty.
- Short or missing `videoId` does not crash.
- Misaligned `videoData` lists show a recoverable empty/error state.
- More video item exposes semantics and triggers selection via tap/keyboard.

**Effort:** M.

#### Task 1.2 - Profile form validation and gender state integrity - S1

**Where:**

- `lib/pages/UserSettings.dart:49,251-265,319-342,363-380,396-425`
- `lib/initialForm/initialFormPage2.dart:190-203,299-318`

**Why:**

The settings name field is a bare `TextField` and writes directly to the
provider on every change. Empty names can persist. The initial form has the same
name-validation gap and calls `updateName(name!)`.

There is a second state-integrity bug: `dropdownValueGender` starts as `''` in
settings. If a user opens settings and confirms without changing gender, the
confirm path can clear gender state because it compares and writes from that
stale local value.

The language dropdown also highlights English rather than the selected locale
because its menu entry color is based on `locale == 'en'`.

**Approach:**

1. Wrap name editing in a local `Form` and convert both settings and initial
   form name fields to `TextFormField`.
2. Validate trimmed non-empty names. Do not commit empty names to the provider.
3. Stage settings edits locally and commit on valid confirmation, or otherwise
   ensure provider updates only happen after validation.
4. Initialize `dropdownValueGender` from current provider state before render,
   and only update gender/binary from a real selected value.
5. Fix selected-color logic for language dropdown entries so the active locale,
   not hard-coded English, is highlighted.
6. Keep any mapping helper local to the existing settings/initial-form boundary;
   do not introduce shared profile abstractions.

**Files:**

- `UserSettings.dart`
- `initialForm/initialFormPage2.dart`
- `app_localizations` (`nameRequiredError`, if not already present)

**Tests:**

- Empty settings name shows inline localized error and blocks pop/save.
- Valid settings name saves and pops as before.
- Empty initial-form name blocks next-step navigation.
- Opening settings and confirming without touching gender preserves gender and
  binary state.
- Active locale entry is highlighted for Hebrew, English, and Arabic.

**Effort:** M.

#### Task 1.3 - Disclaimer pacing, deduplication, and legal-gate clarity - S1

**Where:**

- `lib/disclaimerPage.dart:38-40`
- `lib/disclaimerPage.dart:55-107`

**Why:**

The page intentionally blocks back navigation with `PopScope(canPop:false)`, but
the user is met with long legal copy and no pacing. Current source also
duplicates `informationCollectionDisclaimer`: `_formatDisclaimerText` includes
it, then the widget renders the same string again as a second paragraph.

A distressed first-run user should be able to skim the purpose, understand the
data/consent requirement, and find the confirm action without feeling trapped.

**Approach:**

1. Remove duplicated legal copy.
2. Split content into two or three localized sections with bold headings:
   purpose, information collection, and consent.
3. Add a short summary above the full text.
4. Constrain line length on wide screens.
5. Keep the language selector available at the top.
6. Keep `canPop:false` unless a human changes the legal requirement.
7. If confirmation is gated on scroll-to-bottom, show a visible localized
   "scroll for more" affordance so the exit path is discoverable.

**Files:**

- `disclaimerPage.dart`
- `app_localizations`
- existing disclaimer tests

**Tests:**

- Legal copy is not duplicated.
- Section headings render in Hebrew, English, and Arabic.
- Confirm behavior remains legal-gate compliant.
- Optional scroll gating enables confirmation only after the full content is
  reachable and announces the state change.

**Effort:** M.

#### Task 1.4 - Emergency contact editor validation and recovery - S1

**Where:**

- `lib/form/phonePageform.dart:36-67,176-187`
- `lib/form/phonePageListItem.dart:60-66,99-105,133-168,176-193`
- `lib/util/Form/formPagePhoneModel.dart:133-153`

**Why:**

The Phone page now exposes emergency-contact editing, but the editor still lets
users create empty contact rows, save blank names/numbers, and delete personal
emergency contacts immediately. These are user-created crisis resources, so
loss or invalid saved state is a safety problem, not cosmetic polish.

**Approach:**

1. Convert contact name/number rows to a local form with validation.
2. Require non-empty contact name and dialable phone number before persisting.
3. Treat a manually added row as a draft until it validates; do not persist
   blank name/number pairs.
4. Add cancel behavior for an empty draft row.
5. Add confirmation or snackbar undo for contact deletion. Confirmation is
   simpler; undo is acceptable only if the model can restore safely without
   racing persistence.
6. Add localized labels/tooltips for edit, save, cancel, and delete controls.
7. Use the existing `launchWithFeedback` pattern anywhere the editor itself can
   initiate a call.

**Files:**

- `phonePageform.dart`
- `phonePageListItem.dart`
- `formPagePhoneModel.dart`
- `app_localizations`

**Tests:**

- Manual add does not persist a blank contact.
- Empty name and empty number show localized validation errors.
- Valid contact saves and appears on `PhonePage`.
- Delete requires confirmation or can be undone.
- Canceling a blank draft removes the draft row.

**Effort:** M.

#### Task 1.5 - Inspirational quote empty-data fallback and undo - S1/S2

**Where:**

- `lib/util/HomePage/inspirationalQuote.dart:23-35,38-45,51-127`

**Why:**

The current widget crashes when the quotes list is empty because both
`initState` and refresh call `Random().nextInt(widget.quotes.length)`. The
existing remediation task correctly adds an undo path for dismiss, but the empty
data crash should be bundled because both issues are local to the quote card.

**Approach:**

1. If `quotes` is empty, do not render a crashing card. Prefer a quiet hidden
   state or a localized unavailable message only if it is useful.
2. Disable or hide refresh when no quote is available.
3. On dismiss, show a localized snackbar with Undo that restores `showText`.
4. Keep the existing tooltip/semantics work on close and refresh.

**Files:**

- `inspirationalQuote.dart`
- `app_localizations` (`quoteDismissedUndo` or equivalent)

**Tests:**

- Empty quotes list does not throw.
- Refresh is unavailable or safe when the list is empty.
- Dismiss shows Undo.
- Undo restores the quote.

**Effort:** S.

#### Task 1.6 - Personal-plan answer deletion confirmation - S1

**Where:**

- `lib/pages/FormAnswer.dart:88-121`

**Why:**

`FormAnswer` represents answers in the personal-plan questionnaire. Delete
currently calls `widget.remove(widget.num - 1)` immediately. Since this content
can become part of a user's safety plan, it should follow the same destructive
action rule now applied to gratitude/trait rows.

**Approach:**

1. Add localized confirmation before deleting a form answer.
2. Preserve edit behavior.
3. Add tooltip/semantics labels to edit and delete icon buttons.
4. Keep changes local to `FormAnswer`; do not centralize destructive-dialog
   behavior unless there is already an approved shared boundary.

**Files:**

- `FormAnswer.dart`
- `app_localizations`

**Tests:**

- Delete opens confirmation.
- Cancel preserves the answer.
- Confirm removes the expected answer index.
- Edit/delete controls expose localized semantics.

**Effort:** S.

### Priority 2 - Crisis-page and interface polish

#### Task 2.1 - Phone disclaimer copy and placement - S2

**Where:**

- `lib/pages/phone.dart:70-85`
- `lib/form/phonePageform.dart:188-203`

**Why:**

The contact disclaimer is bold, paragraph-length copy placed high in the Phone
page. On the crisis page it competes with the emergency numbers and personal
contacts. The same copy appears again at the bottom of the editor form.

**Approach:**

1. Demote the Phone page disclaimer to a compact single-line note plus info
   affordance, or move it nearer the contact-management section.
2. Keep emergency numbers and personal contacts visually higher priority.
3. Use a localized expansion pattern for full copy when users request it.
4. Apply the same compact treatment in `PhonePageForm` so the editor does not
   end with a text wall.

**Files:**

- `phone.dart`
- `phonePageform.dart`
- `app_localizations`

**Tests:**

- Emergency grid remains reachable without reading the full disclaimer.
- Compact disclaimer expands/collapses and is screen-reader discoverable.
- Full disclaimer copy remains available.

**Effort:** S.

#### Task 2.2 - FeelGood delete dialog title/body and fullscreen controls - S2

**Where:**

- `lib/pages/FeelGood/image_display_item.dart:16-84`

**Why:**

The delete confirmation exists, but its `AlertDialog` has no title or body, so
the destructive decision is under-explained and weakly announced. The fullscreen
photo dialog also uses icon-only `TextButton`s for back and delete without clear
labels.

**Approach:**

1. Add localized title and one-line body to the delete confirmation.
2. Label back/delete controls with tooltips/semantics.
3. Keep the current fullscreen image behavior and page swiping.

**Files:**

- `image_display_item.dart`
- `app_localizations`

**Tests:**

- Confirmation dialog renders localized title/body.
- Cancel preserves the image.
- Confirm deletes the current image.
- Back/delete controls expose accessible names.

**Effort:** XS/S.

#### Task 2.3 - Personal-plan preview layout and activation polish - S2

**Where:**

- `lib/MainPageHelpers/personalPlanWidget.dart:162-189`

**Why:**

The preview grid still uses a fixed `childAspectRatio: 12 / 4`, which can
compress longer Hebrew or large-text content. The "View all" affordance is a
bare `GestureDetector`; semantics adds a button role, but it lacks Material
focus, ripple, hover, and keyboard activation.

**Approach:**

1. Replace the fixed grid ratio with a layout that can grow or wrap based on
   content length and text scale.
2. Use a Material `TextButton`, `InkWell`, or equivalent existing component for
   "View all" so focus/pressed states and keyboard activation are standard.
3. Keep the visual hierarchy compact; this is a home preview, not the full
   plan.

**Files:**

- `personalPlanWidget.dart`
- existing personal-plan preview tests

**Tests:**

- Long Hebrew preview item does not overflow.
- Large text scale keeps preview readable.
- "View all" activates via tap and keyboard.
- Semantics exposes a localized button label.

**Effort:** S.

---

## Suggested sequencing

| PR | Contents | Severity | Effort |
|---|---|---:|---:|
| UX Phase F - profile/contact integrity | Task 1.2, Task 1.4 | S1 | M |
| UX Phase G - media and home resilience | Task 1.1, Task 1.5 | S1/S2 | M |
| UX Phase H - disclaimer and crisis copy | Task 1.3, Task 2.1 | S1/S2 | M |
| UX Phase I - destructive recovery | Task 1.6, Task 2.2 | S1/S2 | S |
| UX Phase J - preview polish | Task 2.3 | S2 | S |

Each PR should:

- Extend `app_localizations` for Hebrew, English, and Arabic.
- Keep RTL-aware alignment and directional insets.
- Route colors through `AppColors` or existing theme tokens.
- Add real widget tests for the new behavior.
- Keep the aggregate coverage gate green.

---

## Out of scope / accept as-is

- **Dark mode parity:** `darkTheme` remains a light-theme stub from Phase D.
  Full dark-mode design is a separate explicit goal, not part of this tail
  backlog.
- **Typography migration:** Rubix to Lora/Raleway remains an A/B candidate from
  the audit appendix. It is not a functional UX gap.
- **Broad architecture changes:** No new shared UX service, dialog framework, or
  form framework should be introduced for these tasks without human approval.
- **Marketing/brand redesign:** The active register is product. Improvements
  should make the app safer, clearer, and more recoverable, not more decorative.
