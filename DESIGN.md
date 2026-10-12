---
name: Metsilon (Mazilon)
description: A supportive mental health app providing crisis plan tools, gratitude lists, and positive reflection.
version: 1.0.0
tags: [mental-health, wellness, support, minimal]
colorTokens:
  accentPrimary: "0xFFB44FDD"
  darkAccentPrimary: "0xFFB968D9"
  accentContainer: "0xFFE8DDFF"
  surfaceCanvas: "0xFFF4EFE8"
  surfaceRaised: "0xFFFBF9F6"
  contentPrimary: "0xFF16264A"
  statusSuccess: "0xFF256C41"
  statusDanger: "0xFFB3261E"
  darkLogoOutline: "0xFFFFFFFF"
borderRadii:
  button: 20
  card: 16
  input: 10
  badge: 50
  dashedAddSlot: 24
shadows:
  sheet: { color: "0x14000000", offset: [0, -11], blur: 28 }
  card: { color: "0x7AF1EDEA", offset: [0, 3], blur: 11 }
  active: { color: "0x990F2851", offset: [0, 4], blur: 12 }
---

# Metsilon (Mazilon) Design System (DESIGN.md)

This file defines the core design philosophy, styling tokens, and base reusable components of the Metsilon application. It serves as the primary instructions file for developers and AI agents generating or modifying UI components.

---

## 1. Product & Principles

### Product Purpose & Audience

Metsilon (Mazilon) serves individuals in highly vulnerable or distressed moments by providing personal safety planning, gratitude journaling, positive self-reflection, and low-friction emergency contact access. In these moments of limited attention and emotional bandwidth, the interface acts as a supportive companion.

### Brand Personality & Tone

- **Calm & Safe:** The interface should feel steady, steadying, and warm rather than clinical, complex, or attention-seeking.
- **Practical & Low-Pressure:** It must prioritize action over styling, minimizing mental load and clutter in crisis moments.

### Core Design Principles

1.  **Crisis First:** Emergency contact access must remain reachable and prominent in every app state.
2.  **Single Clear Next Action:** Distressed users are guided by one primary action, avoiding walls of choices or dense text blocks.
3.  **Predictable & Responsive:** Layouts must behave consistently across Hebrew (RTL), English (LTR), text scaling, and various screen widths.
4.  **Local Alignment:** All component behavior and styling must align with established boundaries in the codebase.

---

## 2. Design Tokens

### 2.1 Colors

Source of truth: the LP-DS Figma file, page **Colors**, frame "Variables
Documentation - Color Tokens" (node 88:332). Every Figma variable is an
`AppColors` constant in `lib/design_system/tokens/colors.dart`: the light-mode
value under the camelCased Figma name, the dark-mode value under the same name
prefixed with `dark`. Alpha variants carry the opacity in the hex alpha byte.

**New code uses these names.** Prefer `Theme.of(context).colorScheme` where a
slot exists (it already resolves light/dark); otherwise pick `x` / `darkX` the
same way existing code does.

| Figma token | `AppColors` (light / dark) | Light | Dark |
| :-- | :-- | :-- | :-- |
| `accent/container` | `accentContainer` / `darkAccentContainer` | `#E8DDFF` | `#4F378B` |
| `accent/highlight` | `accentHighlight` / `darkAccentHighlight` | `#F2ED4E` | `#D8D34A` |
| `accent/muted` | `accentMuted` / `darkAccentMuted` | `#DC9BF6` | `#DD89FF` |
| `accent/on-container` | `accentOnContainer` / `darkAccentOnContainer` | `#22005D` | `#EADDFF` |
| `accent/primary` | `accentPrimary` / `darkAccentPrimary` | `#B44FDD` | `#B968D9` |
| `accent/wash` | `accentWash` / `darkAccentWash` | `#EFE9FE` | `#2C2440` |
| `action/emergency` | `actionEmergency` / `darkActionEmergency` | `#33373D` | `#7C838E` |
| `content/on-accent` | `contentOnAccent` / `darkContentOnAccent` | `#FFFFFF` | `#2A1A5E` |
| `content/on-emergency` | `contentOnEmergency` / `darkContentOnEmergency` | `#FFFFFF` | `#FFFFFF` |
| `content/on-inverse` | `contentOnInverse` / `darkContentOnInverse` | `#F5EFF7` | `#322F35` |
| `content/placeholder` | `contentPlaceholder` / `darkContentPlaceholder` | `#5C6066` | `#7A736B` |
| `content/primary` | `contentPrimary` / `darkContentPrimary` | `#16264A` | `#F2EDE6` |
| `content/primary 12%` | `contentPrimary12` / `darkContentPrimary12` | `#16264A @12%` | `#F2EDE6 @12%` |
| `content/secondary` | `contentSecondary` / `darkContentSecondary` | `#596271` | `#C0B9B2` |
| `content/tertiary` | `contentTertiary` / `darkContentTertiary` | `#B6BCC6` | `#6A635C` |
| `effect/hairline` | `effectHairline` / `darkEffectHairline` | `#D5CAC1` | `#4F4740` |
| `effect/highlight` | `effectHighlight` / `darkEffectHighlight` | `#FFFFFF @55%` | `#FFFFFF @16%` |
| `effect/scrim` | `effectScrim` / `darkEffectScrim` | `#000000 @32%` | `#000000 @60%` |
| `effect/shadow` | `effectShadow` / `darkEffectShadow` | `#16264A @7%` | `#000000 @50%` |
| `nav/inactive` | `navInactive` / `darkNavInactive` | `#8A8E97` | `#8A8279` |
| `plan/professional` | `planProfessional` / `darkPlanProfessional` | `#3A5BA9` | `#B4C5FF` |
| `plan/professional-container` | `planProfessionalContainer` / `darkPlanProfessionalContainer` | `#DBE1FF` | `#22407F` |
| `plan/support` | `planSupport` / `darkPlanSupport` | `#206A50` | `#8CD6B4` |
| `plan/support-container` | `planSupportContainer` / `darkPlanSupportContainer` | `#A8F2CF` | `#0C4A34` |
| `plan/trigger` | `planTrigger` / `darkPlanTrigger` | `#8F4B45` | `#FFB4AB` |
| `plan/trigger-container` | `planTriggerContainer` / `darkPlanTriggerContainer` | `#FFDAD5` | `#5F1F1B` |
| `plan/warning` | `planWarning` / `darkPlanWarning` | `#8B5000` | `#FFB77C` |
| `plan/warning-container` | `planWarningContainer` / `darkPlanWarningContainer` | `#FFDCC2` | `#5C3600` |
| `plan/wellness` | `planWellness` / `darkPlanWellness` | `#6A4FBF` | `#D0BCFF` |
| `plan/wellness-container` | `planWellnessContainer` / `darkPlanWellnessContainer` | `#E8DDFF` | `#4F378B` |
| `status/danger` | `statusDanger` / `darkStatusDanger` | `#B3261E` | `#F2B8B5` |
| `status/danger-container` | `statusDangerContainer` / `darkStatusDangerContainer` | `#F9DEDC` | `#8C1D18` |
| `status/success` | `statusSuccess` / `darkStatusSuccess` | `#256C41` | `#7FE0A5` |
| `status/success-container` | `statusSuccessContainer` / `darkStatusSuccessContainer` | `#A8F2C0` | `#1E5236` |
| `surface/backdrop` | `surfaceBackdrop` / `darkSurfaceBackdrop` | `#DFDAD3` | `#0E0D0C` |
| `surface/canvas` | `surfaceCanvas` / `darkSurfaceCanvas` | `#F4EFE8` | `#161412` |
| `surface/disabled` | `surfaceDisabled` / `darkSurfaceDisabled` | `#EBE4DA @75%` | `#100F0D @75%` |
| `surface/featured` | `surfaceFeatured` / `darkSurfaceFeatured` | `#14264C` | `#2A2438` |
| `surface/inverse` | `surfaceInverse` / `darkSurfaceInverse` | `#322F35` | `#E9E1DA` |
| `surface/raised` | `surfaceRaised` / `darkSurfaceRaised` | `#FBF9F6` | `#221F1C` |
| `surface/raised-high` | `surfaceRaisedHigh` / `darkSurfaceRaisedHigh` | `#FFFFFF` | `#2B2725` |
| `surface/raised-highest` | `surfaceRaisedHighest` / `darkSurfaceRaisedHighest` | `#F2EBE4` | `#363230` |
| `surface/raised-highest 90` | `surfaceRaisedHighest90` / `darkSurfaceRaisedHighest90` | `#F2EBE4 @90%` | `#363230 @90%` |
| `surface/sunken` | `surfaceSunken` / `darkSurfaceSunken` | `#EBE4DA` | `#100F0D` |
| `surface/white` | `surfaceWhite` / `darkSurfaceWhite` | `#FFFFFF` | `#FFFFFF` |
| `surface/white 75` | `surfaceWhite75` / `darkSurfaceWhite75` | `#FFFFFF @75%` | `#FFFFFF @75%` |

**Theme mapping** (`lib/util/async/app_theme.dart`, same in both modes):
`primary` → accent/primary · `primaryContainer`, `secondary` → accent/container ·
`tertiary` → status/success · `surface` → surface/raised · `onSurface` →
content/primary · `onSurfaceVariant` → content/secondary · `error` →
status/danger · `outline` → content/secondary (it is read as muted text;
content/tertiary is under 4.5:1) · `outlineVariant`, dividers, input
borders → effect/hairline · `surfaceContainerHighest` → surface/raised-highest ·
scaffold → surface/canvas · cards → surface/raised-high. Figma has no
`on-danger` / `on-success` token yet, so `onError` / `onTertiary` use
content/on-accent.

**Known contrast gaps (shipped as designed, tracked in #433):**
- `content/on-accent` on `accent/primary` — the primary button label — is
  4.12:1 (light) / 4.29:1 (dark), under WCAG AA's 4.5:1 for normal text.
- `effect/hairline` as an idle input border is 1.6:1 (light) / 1.4:1 (dark),
  under WCAG 1.4.11's 3:1 for component boundaries. Fine for dividers.

#### Legacy aliases (do not use in new code)

The pre-#431 names still compile and now point at Figma tokens. They will be
deleted once nothing reads them.

| Legacy | Now | Legacy (dark) | Now |
| :-- | :-- | :-- | :-- |
| `primary` | `accentPrimary` | `darkPrimary` | `darkAccentPrimary` |
| `onPrimary`, `onError`, `onSuccess` | `contentOnAccent` | `darkOnPrimary`, `darkOnError`, `darkOnSuccess` | `darkContentOnAccent` |
| `secondary` | `accentContainer` | `darkSecondary` | `darkAccentContainer` |
| `onSecondary` | `accentOnContainer` | `darkOnSecondary` | `darkAccentOnContainer` |
| `surface` | `surfaceRaised` | `darkSurface`, `darkNavBackground` | `darkSurfaceRaised` |
| `white` | `surfaceRaisedHigh` | `darkSurfaceContainer` | `darkSurfaceRaisedHigh` |
| `pageBackground` | `surfaceCanvas` | `darkPageBackground` | `darkSurfaceCanvas` |
| `onSurface` | `contentPrimary` | `darkOnSurface` | `darkContentPrimary` |
| `error` | `statusDanger` | `darkError` | `darkStatusDanger` |
| `success` | `statusSuccess` | `darkSuccess` | `darkStatusSuccess` |
| `neutralLight` | `effectHairline` | `darkOutline` | `darkContentSecondary` |
| `neutralDark` | `contentSecondary` | | |
| `mutedForeground` | `contentSecondary` | | |

#### Not yet in Figma

| Token | Value | Purpose |
| :-- | :-- | :-- |
| `progressTrack` | `0xFFD9D9D9` | Inactive progress-dot fill (same in both modes) |
| `suggestionCardOutline` | `0xFF01B99F` | Dashed border on an unselected onboarding-suggestion card (same in both modes) |
| `darkLogoOutline` | `0xFFFFFFFF` | Lower-letter outline in the dark-mode logo only; artwork exception, not a text foreground |
| `pdfTint` | `0xfaf6fd` | PDF-export tint, kept byte-identical |

### 2.2 Typography (Font Family: Heebo)

The application uses **Heebo** (family `'Heebo'`, `AppTypeScale.family`),
bundled in `fonts/` at weights 400, 500, 600, 700 and 800 under the SIL Open
Font License (`fonts/Heebo-OFL.txt`). It replaced Rubik in #431.

Source of truth: the LP-DS Figma file, page **Typography** (node 7:193). Every
Figma text style is an `AppTypeScale` token in
`lib/design_system/tokens/type_scale.dart`, camelCased from its Figma name
(`Heading/H1` → `AppTypeScale.headingH1`).

Where the line height below says *auto*, Figma uses the font's own line height
(1.46875 × size for Heebo). The token leaves `height` unset, and Flutter
renders the same thing. A fixed line height is set as `height`.

| Figma style | `AppTypeScale` | Size / weight | Line height |
|---|---|---|---|
| Display/Huge ExtraBold | `displayHugeExtraBold` | 68 / 800 | 74 |
| Display/Huge Regular | `displayHugeRegular` | 68 / 400 | 74 |
| Display/Hero ExtraBold | `displayHeroExtraBold` | 34 / 800 | 44 |
| Display/Hero regular | `displayHeroRegular` | 34 / 400 | 44 |
| Heading/H1 | `headingH1` | 28 / 500 | auto |
| Heading/H2 | `headingH2` | 22 / 600 | auto |
| Heading/H3 | `headingH3` | 20 / 700 | auto |
| Heading/H4 | `headingH4` | 17 / 700 | auto |
| Title/Large | `titleLarge` | 17 / 600 | auto |
| Title/Base | `titleBase` | 16 / 400 | auto |
| Title/Base Bold | `titleBaseBold` | 16 / 700 | 20 |
| Title/Small | `titleSmall` | 15 / 600 | auto |
| Title/Small Bold | `titleSmallBold` | 15 / 700 | auto |
| Title/Small Bold Uppercase | `titleSmallBoldUppercase` | 12 / 600, uppercase | auto |
| Body/Large | `bodyLarge` | 17 / 400 | auto |
| Body/Base | `bodyBase` | 16 / 400 | auto |
| Body/Base Medium | `bodyBaseMedium` | 16 / 500 | auto |
| Body/Base Paragraph | `bodyBaseParagraph` | 16 / 400 | 22 |
| Body/Small | `bodySmall` | 15 / 400 | auto |
| Body/Small Paragraph | `bodySmallParagraph` | 15 / 400 | 20 |
| Body/XSmall | `bodyXSmall` | 14 / 400 | auto |
| Label/Large | `labelLarge` | 14 / 600 | auto |
| Label/Large Uppercase | `labelLargeUppercase` | 14 / 600, uppercase | auto |
| Label/Base | `labelBase` | 13 / 600 | auto |
| Label/Small | `labelSmall` | 12 / 600 | auto |
| Caption/Base | `captionBase` | 13 / 400 | auto |
| Caption/Small | `captionSmall` | 12 / 400, letter spacing 0.06 | 18 |
| Caption/Micro | `captionMicro` | 10 / 600, letter spacing 0.05 | 16 |

`TextStyle` has no text-case setting, so for the two *Uppercase* styles the
caller upper-cases the string.

#### Material slots

`_appTextTheme` in `lib/util/async/app_theme.dart` points Material's
`ThemeData.textTheme` slots at these tokens, and `AppTextStyle` in
`lib/design_system/widgets/text.dart` uses the same mapping. Call sites use
`Theme.of(context).textTheme.<slot>` or `AppTextStyle.<slot>`. Do not declare
`fontSize` directly on a screen. No `.sp`: these sizes are the literal design
values; device-independent scaling is `MediaQuery.textScaler`'s job, not a
second scaling system stacked on top (see the code doc comment for why).

| Material slot | Role in the app | `AppTypeScale` token |
|---|---|---|
| `headlineLarge` | Screen title headers | `headingH1` |
| `headlineMedium` | Section title headers | `headingH2` |
| `headlineSmall` | | `headingH3` |
| `titleLarge` | Highlight text inside cards | `titleLarge` |
| `titleMedium` | | `bodyBaseMedium` |
| `titleSmall` | Textfield inputs (Figma text fields use Title/Base) | `titleBase` |
| `labelLarge` | Buttons (Figma buttons use Title/Small) | `titleSmall` |
| `bodyLarge` | Standard paragraphs | `bodyBase` |
| `bodyMedium` | | `bodySmall` |
| `bodySmall` | Muted hints | `bodyXSmall` |
| `labelSmall` | Helper labels | `captionMicro` |

Material and Figma use some of the same names for different things (Material's
`bodyLarge` is Figma's `Body/Base`, not `Body/Large`). `AppTypeScale` always
means the Figma style.

### 2.3 Border Radii

- **`Radius: 20.0` (Standard Buttons):** Circular rounding for all action buttons.
- **`Radius: 16.0` (Card Containers):** Standard containers for list items and self-affirmation cards. (A one-off `15.0` variant exists on a single legacy element — treat `16.0` as the token; it accounts for 288 of the 289 card corner radii in the source file.)
- **`Radius: 24.0` (Dashed Add-Slot Pill):** Fixed corner radius for the shared dashed add-slot pill. Implemented as `AppRadii.dashedAddSlot`; preserves the established corner profile and dash cadence as text scales.
- **`Radius: 10.0` (Input Fields):** Rounded corners for text fields.
- **`Radius: 50.0` (Round Badges):** Fully rounded capsule widgets or floating action overlays.

### 2.4 Shadows & Elevation

Defined in `lib/design_system/tokens/shadows.dart` as `AppShadows`.

- **Bottom Nav / Bottom Sheets** (`AppShadows.sheet`): `color: 0x14000000`, `offset: (0, -11)`, `blurRadius: 28`.
- **Default Card** (`AppShadows.card`): `color: 0x7AF1EDEA`, `offset: (0, 3)`, `blurRadius: 11`. Also used by form-field containers and raised buttons. Matches Figma effect style `2`.
- **Active / Highlight Card** (`AppShadows.active`): `color: 0x990F2851`, `offset: (0, 4)`, `blurRadius: 12`.

These agree with the `shadows` block in this file's frontmatter, which is the source of truth. The Default Card entry previously read `0x0F0E2851`, `(0, 4)`, blur `10` here while the frontmatter said otherwise; the frontmatter value is the one that matches the design file.

---

## 3. Base Reusable Components

Describe and construct layout features using these reusable primitives instead of coding custom layouts:

### 3.1 Text Wrappers

`Text` (`lib/design_system/widgets/text.dart`) is the preferred way to render tokenized text. Import it with `import 'package:mazilon/design_system/widgets/text.dart';`, hide Flutter's `Text` at the widgets/material import, and select the matching `AppTextStyle` token, for example: `Text('label', style: AppTextStyle.bodyLarge)`.

For the remaining ~6 DESIGN.md text categories that do not yet have named `AppTextStyle` tokens, use a §2.2 token via `Theme.of(context).textTheme.<slot>` with Flutter's `Text` (prefix the Flutter import), or use `myText(content, style, align)` to apply the Heebo font family for one-off text. Do not hand-write `fontSize`/`fontWeight`. `myAutoSizedText(content, style, align, maxFontSize, [maxLines = 20])` still applies the Heebo font family for one-off text that doesn't fit a token, but `myAutoSizedText` is `@Deprecated` (`lib/util/styles.dart:252`) — its `maxFontSize` argument silently overrides `style.fontSize` whenever `maxLines` is left unbounded, which is how #359's off-screen-button bug happened. Prefer Flutter's `Text`/`myText` at a §2.2 size over reaching for it.

### 3.2 Action Buttons

- **Primary Confirmation Button:**
  Prefer `Button` (`lib/design_system/widgets/button.dart`) with the `primary` variant: `Button(label: 'Confirm', onPressed: onConfirm, variant: ButtonVariant.primary)`.
- **Secondary / Reset / Cancel Button:**
  Prefer `Button` with the `destructive` variant: `Button(label: 'Cancel', onPressed: onCancel, variant: ButtonVariant.destructive)`.
- **Legacy Primary / Reset / Cancel Widgets:**
  `ConfirmationButton(context, function, text, style)`, `CancelButton`, and `ResetButton` remain for existing call sites, but `Button` replaces them for new work. `Button` defaults to full width; set `fullWidth: false` when the surrounding layout owns the width.
- **Generic Icon Button:**
  `Button` has no icon variant yet. Continue to use `myTextButton(function, icon, color, {tooltip})` for this role.
- **Inline Text Link (tertiary action):**
  `Button` has no link variant yet. Continue to use `LinkButton(function, icon, label, color, {designFontSize, iconSize, gap, minHeight})` for this role.
  Coloured text with a leading icon and no button chrome — for tertiary
  actions such as "add your own" or "other suggestions". The icon is the
  first child so `Directionality` mirrors it to the reading-start side.
  _Note:_ padding and the minimum tap target are reset so the control matches
  the design's 32px text box; Material's default 48px minimum would inflate
  surrounding spacing. That is a deliberate trade against the 48px
  touch-target guideline — use `Button`/`myTextButton` where a
  full-size target matters.

### 3.3 Cards & List Items

Implemented by `Card` (`lib/design_system/widgets/card.dart`), the
design system's platform-agnostic card — use it instead of Material's
`Card` (hide Material's name at the import) or a hand-rolled `Container`.

- **Default Card:**
  `Card`'s own default: background `AppColors.white`, radius `AppRadii.card`
  (16.0), padding `AppSpacing.lg` (16.0), shadow `AppShadows.card`. Updated
  2026-09-19 from `AppColors.surface` to `AppColors.white` — a deliberate
  design change, not a legacy value.
- **Default Muted Card:**
  A container with background `AppColors.surface`, rounded corners 15.0, padding 16.0, and a thin border `Border.all(color: AppColors.neutralLight)`.
- **Active Selection Card:**
  A container with background `AppColors.surface`, rounded corners 15.0, padding 16.0, highlighted border `Border.all(color: AppColors.secondary, width: 2.0)`, and drop shadow `0x990F2851` (offset (0,4), blur 12).

### 3.3a Sheets

`Sheet` (`lib/design_system/widgets/sheet.dart`) is a bottom panel: top
corners `AppRadii.card`, padding `AppSpacing.lg`, shadow `AppShadows.sheet`.
Present it with `showSheet(context: context, sheet: Sheet(child: …))`.
Hide Flutter's names at the import if the file also uses Material.

### 3.4 Input Fields / Text Fields

- **Text Form Field:**
  Inputs must have a height of 40.0, rounded corners 10.0, outline border `OutlineInputBorder(borderSide: BorderSide(color: AppColors.neutralLight))`.
  The width must be dynamically wrapped inside `formFieldWidth(context)` to prevent overflow on mobile.

### 3.5 Headers & Progress

- **Linear Step Indicator:**
  Use `LinearProgressIndicator` with height 4.0, background color `AppColors.neutralLight`, and progress value color `AppColors.primary`.
- **Dot Step Indicator (wizard flows):**
  Use `StepDotsIndicator(context, stepCount:, currentStep:, {dotWidth, dotHeight, gap})`.
  One pill per step, 18x8 with fully rounded ends, filled `AppColors.primary`
  up to and including the current step and `AppColors.progressTrack` beyond.
  The onboarding wizard's design specifies discrete dots rather than the
  continuous bar above; centre them on the screen (not between the flanking
  controls) as the design does.
- **Page Header Group:**
  A `Column` containing a `LinearProgressIndicator` (if in a wizard), a spacer, a Heading Large text (`fontSize: 28.0`, aligned right for RTL), and a small Caption text (`fontSize: 14.0`, `color: AppColors.neutralDark`, aligned right).

### 3.6 Navigation Bar

- **Bottom Navigation Bar:**
  A custom `BottomNavigationBar` with background color `AppColors.surface` (light mode) or `AppColors.darkNavBackground` (dark mode), item labels, and active item tint `AppColors.primary`.

---

## 4. Theme Integration Code

The theme is wired in `lib/util/async/app_theme.dart`: `buildLightTheme()` /
`buildDarkTheme()` build `ThemeData` from `appLightColorScheme` /
`appDarkColorScheme`, and both read only Figma-named `AppColors` tokens (see the
theme mapping in §2.1). `main.dart` picks between them from the user's dark-mode
setting (`UserInformation.usesDarkModeAt`: always light, always dark, or
scheduled) — not from the OS brightness.

`AppColors.darkLogoOutline` is intentionally not assigned to `ThemeData` or
`ColorScheme`. `LivingPositivelyLogo` reads it directly because it applies only
to the dark-mode artwork contour; regular dark-mode text continues to use
`AppColors.darkContentPrimary`.

---

## 5. Design Guardrails & Don'ts

To preserve brand styling and prevent layout drift, ensure your AI agent code generation adheres to the following rules:

### 5.1 Color Anti-Patterns

- **Don't** hardcode raw hex values (e.g. `Color(0xFF...)` or `Colors.red`) directly in page widgets. Always reference semantic slots in `Theme.of(context).colorScheme` or use a Figma-named `AppColors` token (§2.1) — not a legacy alias.
- **Don't** use arbitrary background colors. Scaffold backdrops must use `AppColors.surfaceCanvas` (light mode) or `AppColors.darkSurfaceCanvas` (dark mode).

### 5.2 Component Spacing & Layout

- **Don't** stack more than two CTA buttons on a screen. Keep options minimal and clear.
- **Don't** hardcode form field widths. Always use the responsive `formFieldWidth(context)` wrapper.
- **Don't** nest card layouts inside other cards; use simple, clean list elements to maintain visual clarity.
- **Don't** design custom drop shadows. Only use drop shadows defined in the shadow tokens section via the `AppShadows` library.
