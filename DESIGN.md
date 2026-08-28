---
name: Metsilon (Mazilon)
description: A supportive mental health app providing crisis plan tools, gratitude lists, and positive reflection.
version: 1.0.0
tags: [mental-health, wellness, support, minimal]
colorTokens:
  primary: "0xFFA688F8"
  secondary: "0xFFE3C6FF"
  surface: "0xFFFAF8F8"
  onSurface: "0xFF0F2851"
  success: "0xFF01B91E"
  error: "0xFFF44336"
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

| Token             | CSS Custom Property     | Value        | Purpose / Description                                  |
| :---------------- | :---------------------- | :----------- | :----------------------------------------------------- |
| **Primary**       | `--color-primary`       | `0xFFA688F8` | Calming violet, used as background for primary buttons |
| **Secondary**     | `--color-secondary`     | `0xFFE3C6FF` | Highlight soft purple, selected borders/indicators     |
| **On Surface**    | `--color-on-surface`    | `0xFF0F2851` | Primary body text, titles, dark contrast details       |
| **Surface**       | `--color-surface`       | `0xFFFAF8F8` | Default scaffold/canvas clean color                    |
| **Neutral Dark**  | `--color-neutral-dark`  | `0xFF9A9EB6` | Muted text, borders, inactive indicators               |
| **Neutral Light** | `--color-neutral-light` | `0xFFE7E7E7` | Filled card backgrounds, divider lines                 |
| **Success**       | `--color-success`       | `0xFF01B91E` | Success badges, checked checkmarks, safe items         |
| **Error**         | `--color-error`         | `0xFFF44336` | Destructive warnings, danger alerts, delete buttons    |
| **Background**    | `--color-bg`            | `0xFFF4F0EB` | Light mode screen backdrop tone                        |
| **Progress Track** | `--color-progress-track` | `0xFFD9D9D9` | Inactive progress-dot fill (no dark-mode value designed yet) |
| **Suggestion Card Outline** | `--color-suggestion-outline` | `0xFF01B99F` | Dashed border on an unselected onboarding-suggestion card — teal, distinct from Success green (no dark-mode value designed yet) |
| **Dark Logo Outline** | `--color-dark-logo-outline` | `0xFFFFFFFF` | Pure-white lower-letter outline in the dark-mode logo only; an artwork exception, not a standard text foreground |

### 2.2 Typography (Font Family: Rubik)

The application uses **Rubik** (referenced as `'Rubix'` in code font mappings).

- **Heading Large:** `fontSize: 28.0`, `fontWeight: FontWeight.w500` (Medium), `lineHeight: 36.4px` — Screen title headers.
- **Heading Medium:** `fontSize: 24.0`, `fontWeight: FontWeight.w500` (Medium), `lineHeight: 24.6px` — Section title headers.
- **Card Title:** `fontSize: 18.0`, `fontWeight: FontWeight.w500` (Medium), `lineHeight: 30.0px` — Highlight text inside cards.
- **Body Bold:** `fontSize: 16.0`, `fontWeight: FontWeight.w500` (Medium), `lineHeight: 19.0px` — Buttons, highlights.
- **Body Regular:** `fontSize: 16.0`, `fontWeight: FontWeight.w400` (Regular), `lineHeight: 19.0px` — Standard paragraphs.
- **Input Label:** `fontSize: 14.0`, `fontWeight: FontWeight.w500` (Medium), `lineHeight: 17.0px` — Textfield inputs.
- **Body Small:** `fontSize: 14.0`, `fontWeight: FontWeight.w400` (Regular), `lineHeight: 32.0px` — Muted hints.
- **Micro Detail:** `fontSize: 10.0`, `fontWeight: FontWeight.w400` (Regular), `lineHeight: 13.5px` — Helper labels.

### 2.3 Border Radii

- **`Radius: 20.0` (Standard Buttons):** Circular rounding for all action buttons.
- **`Radius: 16.0` (Card Containers):** Standard containers for list items and self-affirmation cards. (A one-off `15.0` variant exists on a single legacy element — treat `16.0` as the token; it accounts for 288 of the 289 card corner radii in the source file.)
- **`Radius: 24.0` (Dashed Add-Slot Pill):** Fixed corner radius for the shared dashed add-slot pill. Implemented as `AppRadii.dashedAddSlot`; preserves the established corner profile and dash cadence as text scales.
- **`Radius: 10.0` (Input Fields):** Rounded corners for text fields.
- **`Radius: 50.0` (Round Badges):** Fully rounded capsule widgets or floating action overlays.

### 2.4 Shadows & Elevation

Defined in `lib/util/theme/shadows.dart` as `AppShadows`.

- **Bottom Nav / Bottom Sheets** (`AppShadows.sheet`): `color: 0x14000000`, `offset: (0, -11)`, `blurRadius: 28`.
- **Default Card** (`AppShadows.card`): `color: 0x7AF1EDEA`, `offset: (0, 3)`, `blurRadius: 11`. Also used by form-field containers and raised buttons. Matches Figma effect style `2`.
- **Active / Highlight Card** (`AppShadows.active`): `color: 0x990F2851`, `offset: (0, 4)`, `blurRadius: 12`.

These agree with the `shadows` block in this file's frontmatter, which is the source of truth. The Default Card entry previously read `0x0F0E2851`, `(0, 4)`, blur `10` here while the frontmatter said otherwise; the frontmatter value is the one that matches the design file.

---

## 3. Base Reusable Components

Describe and construct layout features using these reusable primitives instead of coding custom layouts:

### 3.1 Text Wrappers

Ensure all raw text is styled using these helper widgets to correctly apply the Rubik font:

- **Standard Text:** `myText(content, style, align)`
- **Auto-Sized Text:** `myAutoSizedText(content, style, align, maxFontSize, [maxLines = 20])`

### 3.2 Action Buttons

- **Primary Confirmation Button:**
  Use `ConfirmationButton(context, function, text, style)`.
  _Flutter implementation details:_ TextButton with background color `AppColors.primary`, foreground color `AppColors.onPrimary`, border radius 20, containing `myAutoSizedText`.
- **Secondary / Reset / Cancel Button:**
  Use `CancelButton` or `ResetButton`.
  _Flutter details:_ TextButton with background color `AppColors.error`, foreground `AppColors.onError`, border radius 20, containing `myAutoSizedText`.
- **Generic Icon Button:**
  Use `myTextButton(function, icon, color, {tooltip})`.
- **Inline Text Link (tertiary action):**
  Use `LinkButton(function, icon, label, color, {designFontSize, iconSize, gap, minHeight})`.
  Coloured text with a leading icon and no button chrome — for tertiary
  actions such as "add your own" or "other suggestions". The icon is the
  first child so `Directionality` mirrors it to the reading-start side.
  _Note:_ padding and the minimum tap target are reset so the control matches
  the design's 32px text box; Material's default 48px minimum would inflate
  surrounding spacing. That is a deliberate trade against the 48px
  touch-target guideline — use `ConfirmationButton`/`myTextButton` where a
  full-size target matters.

### 3.3 Cards & List Items

- **Default Muted Card:**
  A container with background `AppColors.surface`, rounded corners 15.0, padding 16.0, and a thin border `Border.all(color: AppColors.neutralLight)`.
- **Active Selection Card:**
  A container with background `AppColors.surface`, rounded corners 15.0, padding 16.0, highlighted border `Border.all(color: AppColors.secondary, width: 2.0)`, and drop shadow `0x990F2851` (offset (0,4), blur 12).

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

The theme is wired in `lib/util/theme/app_theme.dart`.

```dart
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    colorScheme: appLightColorScheme,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.pageBackground,
    bottomAppBarTheme: const BottomAppBarThemeData(color: Colors.white),
    fontFamily: 'Rubix',
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    colorScheme: appDarkColorScheme,
    primaryColor: AppColors.darkPrimary,
    scaffoldBackgroundColor: AppColors.darkPageBackground,
    bottomAppBarTheme: const BottomAppBarThemeData(color: AppColors.darkNavBackground),
    fontFamily: 'Rubix',
  );
}
```

---

## 5. Design Guardrails & Don'ts

To preserve brand styling and prevent layout drift, ensure your AI agent code generation adheres to the following rules:

### 5.1 Color Anti-Patterns

- **Don't** hardcode raw hex values (e.g. `Color(0xFF...)` or `Colors.red`) directly in page widgets. Always reference semantic slots in `Theme.of(context).colorScheme` or use `AppColors`.
- **Don't** use arbitrary background colors. Scaffold backdrops must use `AppColors.pageBackground` (light mode) or `AppColors.darkPageBackground` (dark mode).

### 5.2 Component Spacing & Layout

- **Don't** stack more than two CTA buttons on a screen. Keep options minimal and clear.
- **Don't** hardcode form field widths. Always use the responsive `formFieldWidth(context)` wrapper.
- **Don't** nest card layouts inside other cards; use simple, clean list elements to maintain visual clarity.
- **Don't** design custom drop shadows. Only use drop shadows defined in the shadow tokens section via the `AppShadows` library.
