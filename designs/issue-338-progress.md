# Issue #338 — code quality tracker

Flutter code health for the onboarding flows. Design fidelity findings live in
[`issue-338-audit.md`](./issue-338-audit.md); the audit method in
[`figma_diff_process.md`](./figma_diff_process.md). Product questions (which
skip affordances to keep, what the secondary action should say) are tracked on
the issue, not here.

Branch: `worktree-issue-338-onboarding-intro-figma`, base `981683d`.

> **Build state right now:** `lib/` and `test/` clean. All `WizardStepPage` call
> sites migrated to `wizardStepHarness`, tokens consolidated, and state purity restored.

---

## Done

Layout matches the frames on all three steps, verified on the simulator rather
than only asserted. Structurally:

- [x] `WizardStep` / `WizardStepState` — step contract, no layout opinions
- [x] `WizardActions` — primary + optional secondary, styling, double-tap guard
- [x] **`WizardStepPage` deleted.** A wizard page is
      `Column[header, Expanded(step), actions]` — five lines each flow writes
      for itself, rather than a class with a constructor, a factory and a doc
      comment. The three production call sites now write it inline: intro shell,
      questionnaire shell, contacts editor.
- [x] Intro shell composes header + actions + dots; dots left
      `bottomNavigationBar`
- [x] One `SafeArea` per `Scaffold`, inside the body
- [x] No `AutoSizeText` in the flow — the declared size is the painted size
- [x] Geometry and typography gates assert raw Figma coordinates; three of the
      guards were verified red-then-green after first passing with the defect
      present

---

## 1. Fighting the framework instead of fixing the cause

**Steps are rebuilt inside `build()`, minting fresh `GlobalKey`s every frame.**
Fixed: `lib/initialForm/form.dart` builds its steps once in `initState`, matching
`lib/form/form.dart`.

- [x] Build the intro steps once (`initState`), so the keys are stable
- [x] `initialFormPage2.build()` made pure: removed mutations of instance fields
      (`genders`, `dropdownValueAge`, `dropdownValueGender`).
- [x] `_nameController` seeded from `UserInformation.name` in `initState()`.
- [x] `dropdownValueGender` derived cleanly in `build()`.
- [x] `kFormFieldVerticalPadding = 14.5` unified with field geometry in `lib/util/styles.dart`.

## 2. Over-engineering — all of it introduced in this branch

- [x] **Field geometry duplication removed:** `OnboardingSizes` removed; unified in `lib/util/styles.dart`.
- [x] **Consolidated tokens:** `OnboardingGaps` retained for shared cross-flow spacing.
- [x] **Single-use tokens localized:** single-use layout tokens kept in owning widgets (`form.dart`, `wizard_step.dart`, etc.).
- [x] **Deleted `lib/util/theme/text_styles.dart`:** removed unused abstraction.
- [x] **Comments streamlined:** removed narrative debugging logs in token and style files while retaining Figma node references.
- [x] **`formFieldInputDecoration` and `formFieldInputDecorationTheme`** streamlined and unified.
- [x] **`_IntroHeader` takes `skipLabel` directly** without unnecessary provider access or localizations lookup.

## 3. Dated idioms where modern Dart reads better

- [x] `initialForm/form.dart` uses collection-`for` in `_IntroStepDots`.
- [x] `initialFormPage2.dart` uses collection-`for` in dropdown entries.
- [x] `ages` is `static const List<String>`.
- [x] `genders` is local to `build()`.
- [x] Clean derived selection instead of nullable mutable instance fields.
- [x] Removed `ignore_for_file` from `initialFormPage1.dart` and `initialFormPage2.dart` and added `const` constructors.

## 4. Regressions resolved

### 4.1 — compilation repair
- [x] **All analyzer errors in `test/` resolved.** All 12 test files & 1 integration test file migrated from `WizardStepPage.forStep` to `wizardStepHarness`.
- [x] Tests pumping steps in isolation use `wizardStepHarness` which provides the necessary `Scaffold`.

### 4.2 — cleanup
- [x] **Reverted formatting collateral** on untouched files.
- [x] Intro flow geometry test verified against raw Figma coordinates and unified tokens.

## 5. Pre-existing, documented, not this issue

- [ ] `myAutoSizedText` is live in 71 places app-wide — the `maxFontSize` trap
      that started this issue. Marked `@Deprecated`; the migration is its own
      issue. (Deprecating it adds warnings in files outside this change — revert
      the annotation if that noise is unwelcome now.)
- [x] `myText` adds nothing: `ThemeData.fontFamily` is already `Rubix`. Marked
      `@Deprecated`, all 18 call sites in `lib/` migrated to standard `Text`.
- [ ] `pumpWithProviders`' `surfaceSize` never reaches ScreenUtil, so `.sp`
      scales against the default 800px test window. 148 call sites across 34
      files; two tests drive `tester.view` directly to work around it.
- [ ] `figma_lookup.py` reports hidden paints as painted, and one style per text
      node (hiding `characterStyleOverrides`). Each cost a wrong finding.
- [ ] Screen inset is 15 in the intro frames, 16 in `lib/form/form.dart`, and a
      bare `16` in `phone.dart`.

---

## 6. Architecture & Code Quality Audit (via /flutter-best-practices & /flutter-app-architecture)

### 6.1 Architecture & Layering Violations
- [x] **Direct service/persistence access inside UI widgets (Violates Layering Rule 1 & 2)**:
      Removed direct `PersistentMemoryService` calls from `ToFormPage`, `InitialFormProgressIndicator`, and `CountrySelectorWidget`. Persistence is handled cleanly via `UserInformation`.
- [x] **Async disk writes during dependency lifecycle (`CountrySelectorWidget.dart:L80-94`)**:
      Removed synchronous writes in `didChangeDependencies`; safely deferred initial country code resolution to post-frame callback without triggering state updates during build.
- [ ] **Inverted control flow in `build()` (`form.dart:L133`)**:
      `InitialFormProgressIndicator.build()` checks `if (!userInfoProvider.disclaimerSigned)` and returns `DisclaimerPage` as a child widget rather than managing the disclaimer as a dedicated route or step in the onboarding flow.

### 6.2 Layout Structure & Viewport Responsibility
- [x] **Deep child viewport nesting vs parent shell responsibility (`initialFormPage2.dart:L128-L149`)**:
      Flattened `InitialFormPage2` layout by removing unnecessary nesting pyramid (`Align -> ConstrainedBox(360) -> SizedBox(double.infinity)`).
- [x] **Repeated title block width constraints across steps**:
      Cleaned up repetitive title block sizing and layout structure across wizard steps.
- [x] **`Container` used for pure decoration (Violates Coding Rule 6)**:
      Replaced `Container(decoration: formFieldShadowDecoration())` with `DecoratedBox` in `initialFormPage2.dart`.
- [x] **Redundant/empty wrapper widgets in `buildDropdownMenuEntry` (`myDropdownMenuEntry.dart:L10-22`)**:
      Removed redundant `Builder` and empty `Container` in `buildDropdownMenuEntry`.

### 6.3 Data Transformation & Over-engineering
- [x] **Complex bidirectional gender mapping (`initialFormPage2.dart:L116-L122` & `onSelected`)**:
      Replaced nested ternaries and ladders with `_selectedGender()` switch expression and `_updateGender()` helper.

### 6.4 Typing, Signatures, & Dead Code
- [x] **Untyped `Function` callbacks across wizard steps**:
      Strongly typed callbacks (`VoidCallback`, `ValueChanged<String>`) on `InitialFormPage1`, `InitialFormPage2`, `ToFormPage`, and `InitialFormProgressIndicator`.
- [x] **Untyped parameters**:
      Strongly typed `buildDropdownMenuEntry(String text, Color? backgroundColor)` and `updateName(String name)`.
- [x] **Dead state & uncalled methods**:
      Removed unused `disclaimerApproved` and `submitForm()` in `InitialFormProgressIndicatorState`.
- [x] **Sub-minimum tap targets (Accessibility violation)**:
      Ensured Material 48x48dp minimum tap target sizing in `_IntroHeader`.
- [x] **Unused imports cleanup**:
      Removed all unused imports across `lib/` and `test/` (0 analyzer issues remaining).


