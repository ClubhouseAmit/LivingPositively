# Mazilon — UX Gaps Audit

**Date:** 2026-05-24
**Scope:** Flutter mental-health support app (Hebrew/English, iOS + Android + Web)
**Method:** Static read of `lib/` (pages, helpers, styles, navigation) — no device run. Findings reference `file:line` so issues can be reproduced and triaged.

This document is a prioritized inventory of UX gaps, not a fix plan. Each finding lists severity, the surface affected, and observable evidence. Severities follow this scale:

| Sev | Meaning |
|-----|---------|
| **S0** | Blocks a crisis-time task or risks user harm (silent failure on emergency call, trapped flow) |
| **S1** | Accessibility / safety regression for vulnerable users (touch targets, screen readers, locale) |
| **S2** | Visible polish / correctness gap that erodes trust |
| **S3** | Inconsistency or maintainability issue with downstream UX cost |

---

## 1. Cross-cutting findings

### 1.1 No design-system tokens (S3)
`lib/util/styles.dart:5-13` hardcodes nine palette colors as top-level mutable `Color` variables. There is no `ThemeData`, no semantic token (`onSurface`, `error`, `success`), no dark-mode definition, and no opacity ramp. Throughout the app, `Colors.blue`, `Colors.red`, `Colors.black45`, and one-off `Color.fromARGB(255, 68, 0, 255)` (`lib/pages/UserSettings.dart:267`) appear alongside the brand palette — i.e. the palette is decorative, not enforced.

**Consequences observed downstream:** destructive buttons styled with raw `Colors.red` (`myButtonStyle3`, `styles.dart:36-40`) instead of a semantic `error` token; locale-dropdown selected text in bright violet that does not appear elsewhere in the app; no way to do dark-mode in one PR.

### 1.2 Theme/MaterialApp does not define `theme:` (S2)
`lib/main.dart:410-428` constructs `MaterialApp` with no `theme` or `darkTheme`. Default Material 2 styles apply, with the brand palette layered on top piecewise. This is why focus rings, ripple colors, dialog backgrounds, and `TextSelectionTheme` are inconsistent across pages.

### 1.3 Screen-reader labels missing on icon-only controls (S1)
Icon buttons across the app are bare `IconButton` / `myTextButton` without `Semantics(label:)` or `tooltip:`. Verified in:
- `lib/pages/home.dart:150-154` — hamburger menu button
- `lib/pages/journal.dart:236-247` — add-entry button
- `lib/MainPageHelpers/personalPlanWidget.dart:108-136` — share & download buttons
- `lib/util/HomePage/inspirationalQuote.dart:74,84-91` — close & refresh
- `lib/util/Phone/phoneTextAndIcon.dart:11-20,102,106` — dialer affordances

For a mental-health app, TalkBack/VoiceOver coverage is not optional. Crisis users include people with visual impairment.

### 1.4 RTL / Hebrew alignment is inconsistent (S1)
The app supports `he` and `en`, but RTL handling is implemented ad-hoc rather than via `Directionality`-aware widgets:
- `lib/main_menu_dialog.dart:97-99` sets `textDirection: isRtl ? TextDirection.ltr : TextDirection.rtl` — inverted.
- `lib/util/HomePage/NameBar.dart:38` forces `CrossAxisAlignment.start` regardless of locale.
- `lib/util/HomePage/inspirationalQuote.dart:99-101` toggles padding `30.0` ↔ `0` between RTL and LTR — asymmetric on locale swap.
- `lib/MainPageHelpers/personalPlanWidget.dart:164-178` swaps the arrow icon for RTL but the surrounding `Row` keeps default LTR alignment.
- `lib/main_menu_dialog.dart:140,163,183` — menu rows pinned to `mainAxisAlignment.start` (should be `end` in RTL).

A Hebrew user sees jagged padding shifts and misplaced glyphs each time the locale changes.

### 1.5 No global loading / error contract (S2)
Async flows (form retrieval, video player init, share-sheet, locale change, quote fetch) have no shared loading affordance. Common pattern: a `FutureBuilder` shows `CircularProgressIndicator` only for `ConnectionState.waiting` and silently renders nothing on error.

Examples:
- `lib/pages/FeelGood/feelGood.dart:105-139` — `error` branch missing
- `lib/MainPageHelpers/personalPlanWidget.dart:113-136` — toast "finished" fires even if file write failed
- `lib/util/Phone/phoneTextAndIcon.dart:39-43` — `dialPhone` swallows `launchUrl` failures
- `lib/pages/SignIn_Pages/introduction.dart:45-48` — loader has no timeout and no `Semantics` label

### 1.6 Touch targets routinely below 44 dp (S1)
- `lib/util/Phone/phoneTextAndIcon.dart:11-20` — `CircleAvatar(radius: 20)` is a 40 dp dialer target.
- `lib/pages/thankYou.dart:114-144` — edit/delete `MaterialButton` cluster lacks padding; transparent `splashColor` removes tap affordance.
- `lib/pages/UserSettings.dart:228-235` — `height: 35`, vertical content-padding `6.0` — input field is barely tap-able and the cursor target is even smaller.
- `lib/menu.dart:295-308` — SOS FAB uses an unscaled `fontSize: 10`; label can become unreadable while text-scale is large, while the FAB itself is hidden during full-screen video (`menu.dart:289`).

### 1.7 Fixed font sizes bypass user system text-scale (S1)
`flutter_screenutil` (`.sp`) is used inconsistently. Fixed sizes appear in:
- `lib/pages/thankYou.dart:101` (`fontSize: 20`)
- `lib/pages/FeelGood/feelGood.dart:86-93` (`fontSize: 30`)
- `lib/menu.dart:303` (`fontSize: 10`)
- `lib/MainPageHelpers/MainPageList/mainpage_list_widget.dart:50-52` (`min(24, 14.sp)` clamps *upward* on large screens)

Users who enlarge system text — common in mental-health and elderly demographics — see clipped or shrunken UI.

---

## 2. Crisis & safety flow (S0/S1) — highest priority

The app's most load-bearing flow is "the user is in distress and needs a number". Findings here block or degrade that flow.

### 2.1 SOS is hidden when the user is most likely to need it (S0)
`lib/menu.dart:289` hides the SOS FAB *and* the bottom nav (`menu.dart:320`) whenever `isFullScreen == true` — i.e., while watching a Wellness Tools video. There is no alternative crisis affordance during that state. A user who is triggered mid-video has no fast path to an emergency number.

### 2.2 Dial-failure is silent (S0)
`lib/util/Phone/phoneTextAndIcon.dart:39-43` calls `launchUrl(...)` inside try/await with no error UI. If the OS rejects the URI (sim missing, restricted profile, malformed 4-digit number on iOS, denied permission), the user believes the call is dialing. There is no haptic, snackbar, or fallback "Copy number" action. This is the single highest-risk gap in the codebase.

Related: `phoneTextAndIcon.dart:55-61` (`openWhatsApp`) and `:71-84` (`openTextMessage`) have the same silent-failure shape.

### 2.3 Emergency grid falls back to wrong country silently (S1)
`lib/util/Phone/EmergencyPhones.dart:45-50` reverts to `defaultEmergencyCountry` if country detection fails. The user is never told. In a Hebrew-speaking user roaming abroad, they may see Israeli numbers that won't connect.

### 2.4 Emergency-add not reachable from Emergency page (S2)
Adding a personal emergency contact is only available from Settings (`lib/pages/UserSettings.dart`) and from the initial-form flow. `lib/pages/phone.dart` itself has no "add my own number" affordance — a discoverability gap on the page where the intent is most likely formed.

### 2.5 Disclaimer is a wall-of-text trap (S1)
`lib/disclaimerPage.dart:57` sets `PopScope(canPop: false)`. `:68-91` renders two long Hebrew/English paragraphs with no headings, no progress indicator, no "read more" pacing. `.sp` font scaling on a tablet maxes the body text at `40` (`:77,91`), pushing it past readable line length. A user already in distress cannot exit, cannot skim, and cannot tell how much more they must scroll.

---

## 3. Page-by-page findings

### 3.1 Home — `lib/pages/home.dart`
- **(S2)** `:133` calls `setRandomPersonalWidgetText(...)` from inside `build()`. Each rebuild re-randomises the headline copy; the personal-plan widget flickers between four states on locale change, scroll, theme refresh, or any provider notify. Anti-pattern — should be in `initState` / `didChangeDependencies`.
- **(S2)** `:137-139` `AppBar(scrolledUnderElevation: 0, backgroundColor: lightGray)` on a `lightGray` body removes the bar boundary entirely on scroll. No drop shadow, no divider — header becomes invisible against scrolling content.
- **(S3)** `:192` adds a bare `SizedBox(height: 70)` at the bottom to clear the FAB. Magic number tied to FAB size in `menu.dart:52`.

### 3.2 Personal Plan widget — `lib/MainPageHelpers/personalPlanWidget.dart`
- **(S2)** `:140-157` `GridView` aspect ratio `12 / 4` ignores content length; long Hebrew bullets overflow with no `TextOverflow` strategy.
- **(S2)** `:127` Download success toast fires unconditionally regardless of file-write outcome.
- **(S1)** `:159-179` "View All" is a `GestureDetector` with no `Semantics(button: true)` and no ripple — feels like static text to keyboard / screen-reader users.

### 3.3 Inspirational Quote — `lib/util/HomePage/inspirationalQuote.dart`
- **(S2)** `:62` Container height fixed at `120` — long Hebrew quotes clip.
- **(S1)** `:104` `widget.quotes[number]` indexes without bounds check; empty list crashes.
- **(S2)** `:52` Once dismissed via `Visibility(visible: showText)` there is no undo control. The user cannot bring the quote back without re-launching.

### 3.4 Gratitude Journal — `lib/pages/journal.dart`
- **(S1)** `:62-67` / `:209` FocusNodes appear to be created during `build` rather than in `initState`; potential leak + focus jump on every rebuild.
- **(S2)** `:291` Empty state renders `Container()` — user sees nothing where the empty-state guidance should be.
- **(S0-adjacent S2)** `:333` `sug1 = thanksSuggestionList[indices[0]]` crashes if `thanksSuggestionList` is empty. For a gratitude prompt the worst case is a crash, but a crash on first run is a retention killer.
- **(S2)** `:150-177` "First entry" celebration popup is delayed 10 s, locking the screen; user has already moved on.

### 3.5 Positive Traits — `lib/pages/positive.dart`
- **(S2)** `:128-156` Modal popup fires after a fixed 10 s delay, every entry into the page, with no "don't show again" — classic nag.
- **(S2)** `:282-299` Three-suggestion UI uses pairwise `!=` checks; identical short lists collapse to a single rendered suggestion silently.
- **(S1)** `:225-241` `Expanded` + conditional `TextAlign` only handles RTL; LTR leaves alignment to default.

### 3.6 Thank-you entry widget — `lib/pages/thankYou.dart`
- **(S1)** `:114-144` Edit/delete buttons lack labels, lack confirmation, lack haptic. A misclicked delete on a journal entry has no undo.
- **(S2)** `:101` Fixed `fontSize: 20` + `TextOverflow.ellipsis` truncates without an expand affordance.

### 3.7 Phone / Emergency — `lib/pages/phone.dart` & helpers
- See §2 above for S0 findings.
- **(S2)** `phone.dart:78-84` Disclaimer paragraph at top of page is long-form, not scannable, and competes for attention with the emergency grid.
- **(S2)** `EmergencyPhones.dart:62-82` `minHeight: 170` for items forces vertical scroll of the *emergency* list on small phones.
- **(S1)** `EmergencyPhones.dart:101-188` `InkWell` items have no hover/pressed visual delta and no `Semantics`.

### 3.8 User Settings — `lib/pages/UserSettings.dart`
- **(S2)** `:227-244` Container `width: 300` hardcoded; on phones < 360 dp the form overflows.
- **(S2)** `:267,310` Selected dropdown text in `ARGB(255,68,0,255)` — a color that exists nowhere else in the app.
- **(S2)** `:298-303` Gender selection logic relies on nested ternaries that don't reconcile cleanly when `binary=true, gender='male'` — UI shows `nonBinary` selected.
- **(S1)** No validation feedback on empty name; submit silently no-ops or applies an empty string.
- **(S2)** Locale dropdown changes locale but does not re-render localized strings until next route push (verify on device).
- **(S2)** `:400-474` Reset confirmation `Dialog` ignores Material insets; full-width on landscape.

### 3.9 Wellness Tools — `lib/pages/WellnessTools/wellnessTools.dart`
- **(S1)** `:161-193` No captions / transcripts for video content — failing WCAG 1.2.x for prerecorded media in a mental-health app.
- **(S2)** `:66-72` Empty state uses fixed `18.sp` without `AutoSizeText` — overflows on small phones.
- **(S2)** `:100,126,144` Fullscreen text toggle is not animated; chrome appears/disappears abruptly.
- **(S0-adjacent S1)** See §2.1 — fullscreen hides crisis affordance.

### 3.10 Feel Good — `lib/pages/FeelGood/feelGood.dart`
- **(S1)** `:61-74` `PreferredSize` AppBar `150` dp with no `SafeArea`; logo can overlap status bar on notched devices.
- **(S2)** `:105-139` `FutureBuilder` error branch unhandled; failure renders empty grid.
- **(S2)** `:57-59` Image delete is immediate, no undo, no confirmation.
- **(S3)** `:86-93` Title `fontSize: 30` not `.sp`.

### 3.11 Navigation — `lib/menu.dart` & `lib/main_menu_dialog.dart`
- See §2.1 for fullscreen-hides-everything (S0).
- **(S2)** `menu.dart:277-281` Back button logic only kicks in when `current == Home`; deeper pages have no in-app back affordance.
- **(S1)** `menu.dart:327-397` Bottom nav buttons have no `Semantics` `selected:` state — screen reader cannot announce active tab.
- **(S2)** `main_menu_dialog.dart:52-70` Dialog positioning recomputes from `RenderBox` lookup with unsafe fallback; on edge cases the menu can render off-screen.
- **(S1)** `main_menu_dialog.dart:97-99` Inverted RTL `textDirection` (see §1.4).

### 3.12 Sign-in flow — `lib/pages/SignIn_Pages/`
- **(S2)** `introduction.dart:38,45-48` Loading screen uses raw `Colors.blue` and an unlabeled `CircularProgressIndicator`.
- **(S2)** `firstPage.dart:37-56` Routing tree mixes `enteredBefore`, `disclaimerSigned`, `firsttime`, and `hasFilled` flags with overlapping conditions; one branch can render an unhandled blank state.

---

## 4. Recommended next steps

These are *not* part of the gap audit; they're the suggested triage order if you commit to addressing the above.

1. **Crisis path hardening (S0):** wire `launchUrl` failures to a visible fallback (snackbar + tappable "Copy number"); show SOS even in full-screen video; surface country-fallback notice in `EmergencyPhones.dart`.
2. **Accessibility pass (S1):** add `Semantics(label:)` / `tooltip:` to every icon-only control along the home → plan → phone path; replace fixed font sizes with `.sp` where the surrounding widget already opts in.
3. **RTL pass (S1):** stop branching on `isRtl` for `textDirection`/padding; lean on `Directionality.of(context)` and start/end edge insets.
4. **Theme + tokens (S3 → unlocks S2 fixes):** define `ThemeData` (light + dark), move palette to semantic tokens, replace `Colors.red` destructive buttons with `colorScheme.error`.
5. **Loading/error contract (S2):** one shared `AsyncValue`-style widget (loading / error-with-retry / empty / data) and route every `FutureBuilder` through it.

---

## 5. Appendix — design-system reference (target state)

A reference design system was generated for this app via the `ui-ux-pro-max` skill (mental-health / wellness profile):

| Role | Token | Hex |
|------|-------|-----|
| Primary | `primary` | `#8B5CF6` (calming lavender — close to existing `primaryPurple #A688F8`) |
| Secondary | `secondary` | `#C4B5FD` |
| CTA / success | `success` | `#10B981` (replaces ad-hoc `appGreen`) |
| Background | `surface` | `#FAF5FF` |
| Text | `onSurface` | `#4C1D95` |

Typography target: **Lora** (headings) + **Raleway** (body) — calm/wellness pairing. Current app uses `Rubix` for all text (`styles.dart:100,112`) which biases playful rather than supportive; worth A/B'ing.

Anti-patterns to avoid when remediating: flat design without depth, text-heavy pages (currently triggered by `disclaimerPage.dart` and `phone.dart` header copy).
