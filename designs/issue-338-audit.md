# Issue #338 — Onboarding intro flow, Figma ↔ Flutter audit

Property-level diff of the three onboarding intro screens against Figma frames
`1660:1264`, `1660:2242`, `1660:2278`, `1660:2313`, re-run against `main` after
PRs #342 and #344 landed.

- **Base commit:** `981683d`
- **Sources:** `lib/initialForm/` (`form.dart`, `initialFormPage1.dart`, `initialFormPage2.dart`, `CountrySelectorWidget.dart`, `toFormPage.dart`)
- **Method:** `designs/figma_diff_process.md`, steps 0–4

## Status

**Decisions taken.** Rubik is the app's only font family — Epilogue (field
labels) and Assistant (safety-plan buttons) are not adopted; those elements
render in Rubik at the design's sizes and weights. `myAutoSizedText` is gone
from these screens, so the declared size is the painted size. Nothing the
implementation already had is removed: the country field, its "?" tooltip and
the skip actions all stay, restyled rather than deleted.

**Typography** — done, covered by `test/initialForm/intro_flow_typography_test.dart`,
which pins the view to the 360px Figma frame width and asserts the design's own
numbers. Also fixed alongside it: the missing title colours on screens 1 and 2,
the invented green second paragraph on the safety-plan screen, the manual
`textDirection` branches CLAUDE.md forbids, and the name label's split into two
sizes.

**Structure** — done, pending render verification:

| Item | Change |
|---|---|
| Step dots | 10px circles, green outline until reached, filled after (`form.dart`) |
| App bar | Scaffold-coloured and flat; was a grey `surfaceContainerHighest` band the design has no counterpart for |
| Vertical layout | Screens 1 and 3 rebuilt as `Column[Expanded(scroll), actions]` so the actions pin above the dots; both were `Center` inside a scroll view, which shrink-wrapped and left a void |
| Illustrations | Width-driven at the design's proportion, height follows the artwork; were pinned to a fraction of screen height regardless of aspect |
| Form fields | One treatment for all four (name, age, gender, country): radius 16, 1px grey outline, no fill, card shadow |
| Safety-plan secondary | Transparent text link in purple; was a second solid pill identical to the CTA |
| `AppShadows` | Created at `lib/util/theme/shadows.dart` — DESIGN.md had mandated it since it was written without it existing. DESIGN.md §2.4's card values corrected to agree with its own frontmatter and with Figma |

**Deliberately not changed.** Button radius stays at 20 per DESIGN.md §2.3
rather than Figma's 15/16, and button height stays at 52 rather than the
design's 40, which is below a comfortable tap target. The scaffold background
stays `pageBackground` per DESIGN.md. Open decisions 2 and 3 (how many skip
affordances; "Skip" vs "fill later") remain product calls and are untouched.

**Still open.** `figma_lookup.py`'s hidden-paint bug and the
`pumpWithProviders` ScreenUtil trap are documented in
`designs/figma_diff_process.md` but not fixed at source.

---

## Headline

**Nothing in #338 was fixed by #342 or #344 — and the real font sizes are far
worse than the issue reports.**

#342 and #344 touched `lib/form/` (the questionnaire wizard) and shared theme
files. Neither touched `lib/initialForm/`, so every row of #338's table is still
live.

More importantly, the sizes quoted in the issue are the *declared* `fontSize`,
which on these screens is largely inert: `myAutoSizedText`'s fourth argument
(`maxFontSize`) is what actually renders, and it is 1.4×–2.6× larger again.

---

## 1. The size bug is a mechanism, not a set of typos

`myAutoSizedText` passes `maxLines: null` and these columns sit inside an
unbounded-height `SingleChildScrollView`. `AutoSizeText` therefore always "fits"
and settles on its ceiling — the `maxFontSize` argument — ignoring the
`fontSize` in the style. **Patching `fontSize` alone changes nothing on screen.**

Measured by pumping the real `InitialFormProgressIndicator` at 390×844, Hebrew
locale, and reading the resolved style off every rendered `Text`:

| Element | Figma | Declared in code | Actually renders | Ratio |
|---|---|---|---|---|
| Welcome title | 26 / w500 | `40.sp` / bold | **60.0** / w700 | 2.3× |
| Welcome subtitle 1 | 16 / w400 | `18.sp` / bold | **35.0** / w700 | 2.2× |
| Welcome subtitle 2 | 16 / w500 | `16.sp` / bold | **35.0** / w700 | 2.2× |
| Welcome buttons ×2 | 18 / w500 | `20.sp` / bold | **44.4** / w700 | 2.5× |
| Get-to-know title | 26 / w500 | `30` / bold | 30.0 / w700 | 1.15× |
| Get-to-know subtitle | 16 / w400 | `15` / bold | 15.0 / w700 | 0.94× |
| Field labels ×4 | 14 / w600 | `20` / normal | **20.0** / w400 | 1.4× |
| Dropdown items | 16 / w400 | `16.sp` capped 25 | 25.0 — see note | — |
| Get-to-know button | 18 / w500 | `20` / bold | 20.0 / w700 | 1.1× |
| Safety-plan title | 26 / w500 | `40.sp` / bold | **60.0** / w700 | 2.3× |
| Safety-plan subtitles ×2 | 16 / w500 | `14.sp` / bold | **31.1** / w700 | 1.9× |
| Safety-plan buttons ×2 | 17 / w600 | `20.sp` / bold | **44.4** / w700 | 2.6× |
| Header skip link | 16 / w500 | `12.sp` / bold | 17.0 / w700 | 1.06× |

Note the two rows that behave: the get-to-know-you title and subtitle already
pass `maxFontSize == fontSize`, so they render as written. That is the shape the
fix needs everywhere — or, better, a wrapper that cannot be called with the two
out of step.

Every weight in the flow is `w700`; the design never uses a weight above `w600`.

### The dropdown row is a measurement artifact, not a production bug

`pumpWithProviders` accepts a `surfaceSize`, but ScreenUtil reads the *window*,
which `setSurfaceSize` does not change. Under that helper `.sp` therefore scales
against the default 800px test window rather than the requested width — a factor
of 2.22 at `designSize: Size(360, 690)`.

That inflated the one measured row above that is `.sp`-derived: `16.sp` resolved
past the `> 25 ? 25` clamp in `myDropdownMenuEntry.dart:17` and reported 25.0. On
a real 390-wide device `16.sp` is ≈17.3 and the clamp never fires. **Dropdown
items are not oversized in production.**

Every other row above comes from an `AutoSizeText` `maxFontSize` ceiling, which
is a raw number and unaffected — those figures stand.

Production is configured correctly: `main.dart:550` puts `ScreenUtilInit` above
`MaterialApp` with `builder:`, so `.sp` scales by real device width.

**This is a live trap for anyone writing layout tests here.** 148 call sites
across 34 test files pass `surfaceSize` and silently get an 800px ScreenUtil
scale. Two tests now drive `tester.view` directly to work around it. Fixing
`pumpWithProviders` to set the view alongside the surface would correct all of
them at once, but it changes the sizes every existing layout assertion was tuned
against, so it needs its own change and a full-suite run.

---

## 2. Three corrections to the issue as filed

### The progress indicator is not the wizard's component

#338 says the implementation "reuses the wizard's rounded-rectangle-pill
progress component." It doesn't. `lib/initialForm/form.dart:206-221` builds its
own inline indicator — 15×15, `borderRadius 5`, active `colorScheme.tertiary`,
inactive `surfaceContainerHighest`.

`StepDotsIndicator` in `lib/util/styles.dart:282` is a *separate* component added
by #344 for the questionnaire wizard, whose own Figma source really does specify
18×8 pills. There are two indicator designs and three implementations, and the
fix is a third shape, not a reuse of the second.

### Skip does exist in the design — on one screen

#338 says the skip affordance is absent from Figma entirely. Frames 2 and 19
have none, correct. But frames 17 and 28 **do** carry a header link `דלג/י`
(node `1660:2302`, Rubik 16 / w500 / `#0F2851`, start-aligned).

Meanwhile the welcome screen currently renders **two** skips — the shared AppBar
one from `form.dart:163` plus a second full-width `ConfirmationButton` at
`initialFormPage1.dart:107` — against a design that has zero.

### The secondary button is confirmed transparent — but the manifest says otherwise

#338's most important structural claim is right: `מלאי אחר כך` is a bare text
link. Confirming it required raw node JSON, because `figma_lookup.py manifest`
reports `fills: ["#A688F8"]` for node `1660:2320` — the fill is present but
carries `"visible": false`. Read from the manifest alone, that node looks like a
solid purple pill identical to the primary CTA. See §6 for the tooling fix.

---

## 3. Welcome — frame 2 (`1660:1264`)

| Property | Figma | Code | Verdict |
|---|---|---|---|
| Title colour | `#0F2851` (style *blue*) | no colour set → inherits default body text colour (`initialFormPage1.dart:45`) | mismatch |
| Subtitle 1 colour | `#9A9EB6` (*grey*) | `colorScheme.outline` → `#9A9EB6` | match |
| Subtitle 2 colour | `#01B91E` (*green*) | `colorScheme.tertiary` → `#01B91E` | match |
| Illustration | 214×214 circle, y 328–542 | `w × 0.6`, `h × 0.3`, `BoxFit.scaleDown` (`:86-94`) | mismatch |
| CTA container | 330×40, r16, `#A688F8`, shadow `0x7AF1EDEA` (0,3) b11 | full-width, r20, primary, no shadow | mismatch |
| Secondary action | absent | second full-width `ConfirmationButton` (`:107-117`) | extra |
| Dots — shape | 10×10 circle, pitch 21 | 15×15, radius 5, pitch 25 (`form.dart:209-220`) | mismatch |
| Dots — inactive | transparent + 1px `#01B91E` outline | solid `#E7E7E7` fill, no border | mismatch |
| Dots — active | solid `#01B91E` | `colorScheme.tertiary` → `#01B91E` | match |
| Dots — fill order | cumulative, right-to-left | `index <= currentStep` under RTL `Row` | match |

---

## 4. Get-to-know-you — frames 28 & 17 (`1660:2278` / `1660:2242`)

| Property | Figma | Code | Verdict |
|---|---|---|---|
| Title colour | `#0F2851` | no colour set → inherits default (`initialFormPage2.dart:166-176`) | mismatch |
| Field container | 330×53, r16, 1px `#9A9EB6`, **no fill**, card shadow | three different treatments — see rows below | mismatch |
| ↳ name field | as above | default `OutlineInputBorder()` → r4 (`:203-209`) | mismatch |
| ↳ age / gender | as above | bare `DropdownMenu`, all defaults (`:228`, `:262`) | mismatch |
| ↳ country | as above | r8, `#E7E7E7` fill, one-off shadow `rgba(0,0,0,.1)` (0,1) b0 (`CountrySelectorWidget.dart:150-169`) | mismatch |
| Label family | Epilogue w600 | Rubix w400 — see decision 1 | decision |
| Name label structure | one node, 32px line box | split on `"("` into two `Text`s at 20 and 18 (`:45-86`) | mismatch |
| Label alignment | align RIGHT (reading start) | manual `textDirection` branch (`:64-66`, `:102-104`) | violates CLAUDE.md |
| Country field | absent | present — deliberate crisis-safety feature | accepted |
| "?" tooltip button | absent | 44×44 `TextButton` (`CountrySelectorWidget.dart:129-145`) | extra |
| Header skip link | Rubik 16 / w500 / `#0F2851`, start-aligned | `12.sp` bold in AppBar `IconButton` (`form.dart:163-176`) | mismatch |

---

## 5. Safety-plan intro — frame 19 (`1660:2313`)

| Property | Figma | Code | Verdict |
|---|---|---|---|
| Title colour | `#0F2851` | `colorScheme.onSurface` → `#0F2851` (`toFormPage.dart:71`) | match |
| Subtitle structure | **one** grey node, both paragraphs (`1660:2317`) | two `Text`s: `outline` (grey) then **`tertiary` (green)** (`:80-98`) | mismatch |
| Primary CTA | 330×40, r15, `#A688F8`, no stroke | `primaryButtonStyle` → r20, intrinsic width (`:137`) | mismatch |
| Secondary action | 330×34, **transparent**, no stroke, purple label | `primaryButtonStyle().copyWith(padding)` — solid purple pill, white label (`:162-177`) | mismatch |
| Secondary copy | `מלאי אחר כך` (fill later) | `appLocale.skipButton` → "Skip" | decision |
| Button family | Assistant w600 17 | Rubix w700 — see decision 1 | decision |
| Illustration | 240×175, y 347–522 | `myImage(w × 0.8, h × 0.4)` (`:104`) | mismatch |
| Dots — all filled | 3 solid green (step 3 of 3) | cumulative fill — correct behaviour, wrong shape | partial |

---

## 6. Cross-cutting findings not in the issue

### Two screens never set a title colour

`initialFormPage1.dart:45` and `initialFormPage2.dart:168` build their titles
with no `color`, so the title inherits the ambient body text colour rather than
`AppColors.onSurface`. `toFormPage.dart:71` sets it correctly — same screen
family, three files, two behaviours.

### The green second paragraph on the safety-plan screen is invented

Figma has a single grey text node carrying both paragraphs. The code splits it
and paints the second one `colorScheme.tertiary` (green). On the *welcome*
screen the green second subtitle **is** correct — likely where the pattern was
copied from.

### DESIGN.md contradicts itself on the card shadow

The frontmatter token `shadows.card` — `0x7AF1EDEA, (0,3), blur 11` — matches the
Figma field and button shadow exactly. But §2.4's prose lists "Default Card" as
`0x0F0E2851, (0,4), blur 10`, a different value. §2.4 also mandates using "the
`AppShadows` library", which does not exist anywhere in `lib/`. Whoever fixes the
field styling needs this resolved first.

### Scaffold background divergence is documented, not a bug

All four frames are `#FAF8F8`; the app renders `AppColors.pageBackground`
`#F4F0EB`. DESIGN.md explicitly requires `pageBackground` for scaffold backdrops,
so this is a deliberate divergence. **Do not "fix" it.**

### figma_lookup.py reports hidden paints as visible

`_manifest_walk` does not check the `visible` flag on individual paint entries,
so hidden fills and strokes appear in the manifest as if painted. Two nodes in
this audit alone are affected: `1660:2320` (hidden fill) and `1660:2319` (hidden
stroke). Skipping `visible == false` paints is a one-line fix and prevents a
category of confidently-wrong findings.

---

## 7. Open decisions

These change what the fix looks like, so they want an answer before the code is
written.

**1. Epilogue and Assistant — implement, or treat as design drift?**
The design specifies two families the app has never shipped, for 3 field labels
and 2 buttons. Neither font file exists in `fonts/`. DESIGN.md §2.2 declares
Rubik the app's only family, and its "Input Label" token (14 / w500) already
matches the Figma label *size* exactly. *Recommend: keep Rubik*, adopt the Figma
sizes and weights, and raise the two families separately as a design-system
question.

**2. How many skip affordances should the welcome screen have?**
Design says zero on welcome and safety-plan, one header link on get-to-know-you.
The app shows two on welcome. *Recommend: drop the in-body button*, keep the
header link, restyle it to the frame-17 spec — but this is a product call, since
skip is a deliberate addition beyond the mockup.

**3. "Skip" or "fill later" on the safety-plan screen?**
The copy difference matters more than the styling for a crisis-safety feature —
"skip" implies discarding, "fill later" implies deferring. Needs a content owner,
not a developer.

**4. Shared text widgets, or per-call-site fixes?**
#338 argues for shared `HeadingText` / `BodyText` / `ButtonText` widgets. The
`maxFontSize` mechanism strengthens that: the bug is a two-argument API that lets
size and ceiling drift apart. *Recommend: a wrapper that takes one size* and
derives the ceiling, so the failure mode becomes unrepresentable.

---

## 8. What was verified, and what wasn't

- **Verified by execution.** Every rendered size and weight in §1, read off the
  real widget tree at 390×844 in Hebrew via a temporary probe test (since
  removed).
- **Verified from source.** All colour-token mappings, against
  `lib/util/theme/app_theme.dart`; all Figma values, against
  `figma_full_dump.json` — with hidden-paint claims re-checked in raw node JSON.
- **Not verified.** Step 5 of the diff process — no simulator screenshot, no
  ink-band measurement. Every spacing and geometry row above is read from Figma
  coordinates and Dart source, not from pixels. The illustration and CTA geometry
  findings in particular deserve a render before anyone tunes numbers.
- **Not verified.** Runtime colours. The probe ran under a bare `MaterialApp`, so
  its colour output reflected Material 3 defaults rather than `buildLightTheme()`.
  Colour rows come from reading the token wiring, not from observing pixels.
- **Resolved.** The dropdown's 25.0 reading was a test-harness artifact, not a
  production value — see the note in §1. `myDropdownMenuEntry.dart` is shared
  with `UserSettings.dart` and was left untouched.
