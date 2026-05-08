# Mazilon Coverage Gap Analysis

Generated: 2026-05-08 | Flutter 3.41.6 / Dart 3.11.4 | 93 tests passed

---

## Executive Summary

| Metric | Value |
|---|---|
| Overall line coverage | **27.6%** (2704 / 9780 instrumented lines) |
| Total `lib/` Dart files | 96 |
| Files in lcov (imported by tests) | 91 |
| Files not in lcov at all | 5 (never imported by any test) |
| Files with 0% coverage (in lcov) | 31 |
| Files with 1–49% coverage | 13 |
| Files with 50–99% coverage | 30 |
| Files with 100% coverage | 17 |
| Excluded (codegen / l10n / bootstrap) | 8 |

### Risk-Weighting Model

Each file receives a raw risk score 0–10:

| Factor | Weight | Rationale |
|---|---|---|
| Domain criticality | 0–4 pts | Emergency/auth/notification/Firebase/PDF/disclaimer = 4; journaling/personal-plan/persistence = 3; UI pages = 2; utilities = 1; enums/generated = 0 |
| LOC (uncovered lines) | 0–3 pts | >150 missed = 3; 50–150 = 2; 10–49 = 1; <10 = 0 |
| Complexity proxy (if/switch/try/catch per file, scaled to uncovered portion) | 0–2 pts | Score >80 in uncovered code = 2; 20–80 = 1; <20 = 0 |
| "Test exists but zero coverage" bonus | +1 pt | Cheap-win multiplier — signals broken import rather than missing test |

### Top-10 Risk-Weighted Gaps (punch list)

| Rank | File | Coverage | Risk Score | One-liner |
|---|---|---|---|---|
| 1 | `lib/util/Firebase/firebase_functions.dart` | 5.1% | 9.4 | 1387-line Firebase auth+data layer; 848 missed lines, 373 branchy operations |
| 2 | `lib/util/persistent_memory_service.dart` | 0% | 9.0 | SharedPreferences CRUD used by disclaimer, notifications, phone-plan; every line uncovered |
| 3 | `lib/pages/notifications/notification_service.dart` | 4.8% | 8.8 | Platform notification scheduling; `supportsReminderSettings` alone has 4 branches |
| 4 | `lib/disclaimerPage.dart` | 0% | 8.5 | Safety-legal gate that persists consent; test file exists but imports a fake widget |
| 5 | `lib/file_service.dart` | 0% | 8.5 | PDF/share pipeline including safety plan export; 99 missed lines across 6 async paths |
| 6 | `lib/util/PDF/create_pdf.dart` | 0% | 8.2 | PDF generation for safety plan; 131 missed lines, 137 complexity points |
| 7 | `lib/Locale/locale_service.dart` | 0% | 7.5 | Locale persistence controls which language all safety text renders in |
| 8 | `lib/pages/notifications/reminder_debug_panel.dart` | 0% | 7.0 | 159-complexity debug panel with real notification triggers |
| 9 | `lib/pages/UserSettings.dart` | 0% | 6.8 | 484-line settings page; test imports a stub widget, not the real one |
| 10 | `lib/pages/journal.dart` | 0% | 6.5 | 363-line journaling page; test imports a fake widget |

---

## Tier 1 — CRITICAL (Do First)

**Definition:** Domain criticality HIGH (score 3–4) AND current coverage ≤ 10%.

---

### `lib/util/Firebase/firebase_functions.dart`
- **LOC:** 1387 | **Covered:** 46/894 instrumented lines (5.1%) | **Missed:** 848 | **Risk:** 9.4
- **Why it matters:** This is the entire Firebase data layer — `FirebaseAuthService` (sign-in/sign-up with FirebaseAuth), `FirebaseFunctionsService` (read/write of gratitude journal, positive traits, personal safety plan, emergency phones, user profile, notification settings). A regression here silently destroys persistence of crisis-plan data. Auth error paths (`email-already-in-use`, `user-not-found`) are untested.
- **What to cover:**
  - `FirebaseAuthService.signUpWithEmailAndPassword` — happy path + `email-already-in-use` + other `FirebaseAuthException`
  - `FirebaseAuthService.signInWithEmailAndPassword` — happy path + `user-not-found` + `wrong-password`
  - All `set*` / `get*` methods for each data domain (journals, traits, safety-plan items, phone entries): happy path + empty-collection edge case + offline/throw path
  - All `delete*` methods with valid id + non-existent id
  - Use `fake_cloud_firestore` and `firebase_auth_mocks` packages (both are Flutter-test compatible).

---

### `lib/util/persistent_memory_service.dart`
- **LOC:** 98 | **Covered:** 0/39 instrumented lines (0%) | **Missed:** 39 | **Risk:** 9.0
- **Why it matters:** `SharedPreferencesService` is the local-persistence layer injected via GetIt throughout disclaimer signing, notification-time storage, and user profile. Zero coverage means we have no regression guard on `setItem` / `getItem` type-switching (5 branches each) or the error catch paths.
- **What to cover:**
  - `setItem` for each `PersistentMemoryType` (String, Int, Double, Bool, StringList)
  - `setItem` with empty key (early return branch)
  - `setItem` with null value (early return branch)
  - `getItem` for each type + default/unsupported-type exception
  - `reset()` happy path + exception path
  - Use `shared_preferences` fake via `SharedPreferences.setMockInitialValues({})`.

---

### `lib/pages/notifications/notification_service.dart`
- **LOC:** 210 | **Covered:** 3/63 instrumented lines (4.8%) | **Missed:** 60 | **Risk:** 8.8
- **Why it matters:** `NotificationsService` controls daily mental-health reminder scheduling. `supportsReminderSettings()` is the platform gate — if it regresses, Android reminders silently stop. `initializeNotification` has 4 branches around permission grant/deny. `cancelNotifications` has 2 paths (specific ID vs. cancel-all).
- **What to cover:**
  - `supportsReminderSettings()` — web=true → false; Android → true; iOS → false (use `platformOverride` injection already present in the signature, this is a "cheap win" since parameters are injectable)
  - `calculateTime(h, m)` — pure function, trivial unit test
  - `init()` — success path + timezone-lookup-throws path (error catch + fallback)
  - `cancelNotifications(null)` + `cancelNotifications(42)` + `cancelWorker=true` branch
  - Mock `FlutterLocalNotificationsPlugin` via `flutter_local_notifications` test helpers.

---

### `lib/disclaimerPage.dart`
- **LOC:** 115 | **Covered:** 0/42 instrumented lines (0%) | **Missed:** 42 | **Risk:** 8.5
- **Why it matters:** The disclaimer page is a legal and ethical gate — it records that the user accepted the suicide-prevention disclaimer before using the app. `updateDisclaimers` writes to SharedPreferences. If the button logic breaks, users bypass or infinitely re-see the disclaimer.
- **Cheap-win flag:** `test/DisclaimerPage/disclaimerPage.dart` exists but imports a **locally defined `DisclaimerPage`** class (a stub widget in the test file itself) — it never imports `package:mazilon/disclaimerPage.dart`. Fix the import and the existing widget tests will likely provide coverage immediately.
- **What to cover (after import fix):**
  - Render `DisclaimerPage` and verify disclaimer text appears
  - Tap "accept" button → verify `updateDisclaimers` calls `service.setItem("disclaimerConfirmed", Bool, true)`
  - Language select widget renders correctly
  - `_formatDisclaimerText` concatenates both disclaimer fields

---

### `lib/file_service.dart`
- **LOC:** 292 | **Covered:** 0/99 instrumented lines (0%) | **Missed:** 99 | **Risk:** 8.5
- **Why it matters:** `FileServiceImpl` orchestrates the PDF/share pipeline for the **personal safety plan** — one of the highest-risk features in the app. `getPrefsData()` reads 7 SharedPreferences keys; `share()` and `download()` each have branches for PDF vs. other formats; `shareTextOnly()` wraps share_plus.
- **What to cover:**
  - `getPrefsData()` — mock `PersistentMemoryService`, verify all 7 keys retrieved and mapped correctly
  - `share()` with `ShareFileType.PDF` path (mock `createPDF`)
  - `download()` success + file-picker cancel path
  - `shareTextOnly()` with non-empty string
  - Exception paths in all three public methods

---

### `lib/util/PDF/create_pdf.dart`
- **LOC:** 252 | **Covered:** 0/131 instrumented lines (0%) | **Missed:** 131 | **Risk:** 8.2
- **Why it matters:** PDF output is the primary export of the personal safety plan. `createPDF` loops across data sections; helper functions `getDirection`, `getAlign`, `getAlignment` each have RTL/LTR branches critical to Arabic/Hebrew rendering.
- **What to cover:**
  - `getDirection("hello")` → `ltr`; `getDirection("שלום")` → `rtl`
  - `getAlign` and `getAlignment` for both branches
  - `createPDF` with realistic safety-plan data: multi-section, empty section (skipped), single section
  - Use `flutter_test` binding to provide asset bundle for font/image loading, or mock `rootBundle`.

---

### `lib/Locale/locale_service.dart`
- **LOC:** 34 | **Covered:** 0/10 instrumented lines (0%) | **Missed:** 10 | **Risk:** 7.5
- **Why it matters:** `LocaleServiceImpl` is the locale store injected app-wide. `getLocaleName()` has 4 branches (ar/he/en/default). If this regresses, all localized safety text renders in the wrong language.
- **What to cover:**
  - `getLocaleName()` is not easily unit-testable without a device locale override; inject via `LanguageCode` abstraction or use `LocaleServiceImpl.locale` static override
  - `setLocale(null)` → falls back to `getLocaleName()`
  - `setLocale("ar")` → `getLocale()` returns "ar"
  - `getLocale()` when locale is null (uses device default)

---

## Tier 2 — HIGH

**Definition:** Large/complex files with low coverage that are not safety-critical, OR medium-criticality with heavy uncovered surface.

---

### `lib/util/Form/firebase_functions.dart` (Firebase) — see Tier 1
Already covered above.

---

### `lib/pages/UserSettings.dart`
- **LOC:** 484 | **Covered:** 0/222 instrumented lines (0%) | **Risk:** 6.8
- **Note — Cheap Win:** `test/UserSettings/UserSettings_test.dart` exists but imports a local stub `UserSettings` widget. Fix import to `package:mazilon/pages/UserSettings.dart`.
- **What to cover:** Settings save flow (name/age/gender), locale change propagation, photo-picker integration (mock `ImagePickerService`), phone-page data update, navigation back.

---

### `lib/pages/journal.dart`
- **LOC:** 363 | **Covered:** 0/178 instrumented lines (0%) | **Risk:** 6.5
- **Note — Cheap Win:** `test/Thanks/Journal_test.dart` imports a local `journal.dart` stub. Fix import.
- **What to cover:** Add gratitude entry, delete entry, suggestion refresh cycle, `todayThankYousFunc` filtering (today vs. old dates), empty-state rendering.

---

### `lib/pages/positive.dart`
- **LOC:** 348 | **Covered:** 0/170 instrumented lines (0%) | **Risk:** 6.2
- **Note — Cheap Win:** `test/POSITIVE/positiveTest.dart` exists — verify whether it imports the real widget.
- **What to cover:** Add/remove positive trait, suggestion cycling, empty-state, persistence mock.

---

### `lib/pages/PersonalPlan/myPlanPageFull.dart`
- **LOC:** 289 | **Covered:** 0/131 instrumented lines (0%) | **Risk:** 6.0
- **Why it matters:** This is the full personal safety plan — a clinical-grade feature. No coverage at all.
- **What to cover:** Load plan categories, toggle items on/off, PDF export trigger, share trigger, localized section headers.

---

### `lib/form/form.dart` / `lib/form/phonePageListItem.dart` / `lib/form/phonePageform.dart`
- Combined: 666 LOC, 0% coverage across all three, 297 combined missed lines
- **What to cover:** Form navigation steps, phone entry add/edit/delete, validation logic for empty fields, country-code selection propagation.

---

### `lib/initialForm/initialFormPage2.dart` / `lib/initialForm/toFormPage.dart`
- Combined: 439 LOC, 0% coverage, 215 missed lines
- **Note — Cheap Win:** `test/initialForm/initialFormPage2_Test.dart` and `test/initialForm/toFormPage_Test.dart` exist. Verify imports point to real classes.
- **What to cover:** Multi-step onboarding flow, gender/age dropdown selection, locale selection affecting subsequent pages.

---

### `lib/main.dart`
- **LOC:** 431 | **Covered:** 3/177 instrumented lines (1.7%) | **Risk:** 5.5
- Bootstrap + navigation router. Hard to fully unit-test but key branches: `main()` initialization sequence, GetIt registrations, `supportsReminderSettings` gate in startup, route generation switch.
- Consider integration-test coverage rather than unit tests.

---

### `lib/util/appInformation.dart`
- **LOC:** 394 | **Covered:** 55/160 instrumented lines (34.4%) | **Missed:** 105 | **Risk:** 5.0
- `AppInformation` ChangeNotifier holds app-wide state. Uncovered sections (lines ~124–149) are the update/notify methods. These are invoked by settings save flows — covered indirectly once UserSettings tests are fixed.

---

### `lib/util/Form/retrieveInformation.dart`
- **LOC:** 244 | **Covered:** 90/187 instrumented lines (48.1%) | **Missed:** 97 | **Risk:** 4.8
- `retrieveInformation` is a large switch with 4 cases + default throw. The uncovered half (lines 21–32) is the input-routing logic. Cover each case (`PersonalPlan-DifficultEvents`, `PersonalPlan-MakeSafer`, `PersonalPlan-FeelBetter`, `PersonalPlan-Distractions`) + the default-throw path.

---

## Tier 3 — MEDIUM

**Definition:** Smaller widgets or utilities with notable gaps but lower blast radius.

---

### `lib/util/userInformation.dart`
- **LOC:** 200 | **Covered:** 78/97 (80.4%) | **Missed:** 19
- Uncovered: lines 49–68 — the `fromJson`/deserialization path. Critical if Firebase data shape changes. Cover `UserInformation.fromJson` with valid + missing-field input.

---

### `lib/MainPageHelpers/MainPageList/mainpage_list_widget.dart`
- **LOC:** 263 | **Covered:** 57/121 (47.1%) | **Missed:** 64
- Uncovered lines 41–51 are the "no items" empty-state branch. Add test: render with empty list, verify empty-state widget appears.

---

### `lib/menu.dart`
- **LOC:** 401 | **Covered:** 111/171 (64.9%) | **Missed:** 60
- Uncovered: drawer navigation callbacks (lines 79–98). Add tap tests for each menu item routing.

---

### `lib/util/styles.dart`
- **LOC:** 145 | **Covered:** 36/70 (51.4%) | **Missed:** 34
- Uncovered: lines 67–91 — RTL-specific style branches. Cover `getTextStyle` with RTL locale mock.

---

### `lib/pages/notifications/reminder_debug_panel.dart`
- **LOC:** 281 | **Covered:** 0/127 (0%) | **Risk:** 7.0
- Debug-only panel but it integrates real notification logic. Cover `ReminderDebugPanel` render, button tap for "test notification", clear-log button, guard that debug panel is conditionally shown only in debug mode.

---

### `lib/pages/notifications/set_notification_widget.dart`
- **LOC:** 174 | **Covered:** 0/85 (0%)
- Covers the notification-time picker UI. Cover: time selection, save interaction → calls `initializeNotification`, platform guard for non-Android.

---

### `lib/util/Phone/EmergencyPhones.dart`
- **LOC:** 189 | **Covered:** 65/85 (76.5%) | **Missed:** 20
- Uncovered: lines 11–12, 41–48, 102–106 — constructor defaults and `launchUrl` callback branches. Cover tap on phone number → `launchUrl` called with `tel:` scheme (mock `url_launcher`).

---

### `lib/util/FormAnswer/addFormAnswer.dart`
- **LOC:** 140 | **Covered:** 43/59 (72.9%) | **Missed:** 16
- Uncovered lines 50–51, 87–90, 110–111, 121–122 are error/null paths. Cover with empty input and null-provider cases.

---

### `lib/util/Thanks/AddForm.dart`
- **LOC:** 167 | **Covered:** 0/64 (0%)
- **Cheap Win:** `test/Thanks/AddForm.dart` and `test/thanksListWidget/AddForm.dart` exist — verify they import the real widget.
- Cover: render `AddForm`, add a suggestion item, verify it appears in the list.

---

### `lib/pages/thankYou.dart`
- **LOC:** 153 | **Covered:** 0/46 (0%)
- **Cheap Win:** `test/Thanks/thankYou.dart` exists — check import.
- Cover: render thank-you list, empty state, date display format.

---

### `lib/util/Phone/phoneTextAndIcon.dart`
- **LOC:** 115 | **Covered:** 33/55 (60%) | **Missed:** 22
- Uncovered: lines 8–18, 23 — the icon + text widget initialization path. Cover render with each phone type.

---

### `lib/MainPageHelpers/MainPageList/list_utils.dart`
- **LOC:** 136 | **Covered:** 17/63 (27%) | **Missed:** 46
- `buildListFromType` switch; uncovered cases for `GratitudeJournal`, `QualitiesList`. Cover each `PagesCode` value.

---

## Tier 4 — LOW / Cosmetic

These files have gaps but low risk:

| File | Coverage | Missed | Notes |
|---|---|---|---|
| `lib/util/type_utils.dart` | 50% | 2 lines | `castToStringList` null path |
| `lib/util/languages_util_functions.dart` | 61.5% | 5 lines | Cover `getDirectionOfText` with mixed-script string |
| `lib/MainPageHelpers/MainPageList/mainpage_list_body_widget.dart` | 50% | 9 lines | Empty vs. populated list rendering |
| `lib/MainPageHelpers/personalPlanWidget.dart` | 89.6% | 8 lines | Conditional show-empty-state branches |
| `lib/util/Share/LP_share_alert_dialog.dart` | 89.7% | 4 lines | Share dialog cancel path |
| `lib/pages/phone.dart` | 93.1% | 4 lines | Lines 108–115: error handling branch |
| `lib/util/disclaimerLanguageSelect.dart` | 97.8% | 1 line | Line 40: trivial branch |
| `lib/pages/home.dart` | 97.1% | 2 lines | Lines 120–121 |
| `lib/util/personalPlanItem.dart` | 94.4% | 1 line | Line 36 |
| `lib/pages/WellnessTools/wellnessTools.dart` | 95.6% | 4 lines | Lines 40–44 |
| `lib/pages/FeelGood/image_display_item.dart` | 88.9% | 6 lines | Image null/absent branch |

---

## Excluded Files

These files should be excluded from coverage gates:

| File | Reason |
|---|---|
| `lib/l10n/app_localizations.dart` | Flutter codegen — ARB-generated base class |
| `lib/l10n/app_localizations_ar.dart` | Flutter codegen — 3865 LOC, 11.7% (only strings tested by existing l10n tests) |
| `lib/l10n/app_localizations_en.dart` | Flutter codegen — 3886 LOC |
| `lib/l10n/app_localizations_he.dart` | Flutter codegen — 3858 LOC |
| `lib/l10n/l10n.dart` | Codegen helper (8 LOC) — not in lcov |
| `lib/util/Firebase/firebase_options.dart` | FlutterFire CLI-generated config (secrets/platform configs) |
| `lib/global_enums.dart` | Pure enum declarations, no executable logic — not in lcov |
| `lib/main.dart` | App bootstrap; partial coverage acceptable; full coverage requires integration tests |

---

## "Cheap Wins" — Tests Exist but Coverage is Zero (or near-zero)

These files have a corresponding test file but the test does NOT import the real production class. Fixing the import in the test file is likely the only change needed to get immediate coverage.

| Production File | Coverage | Test File(s) | Diagnosis |
|---|---|---|---|
| `lib/disclaimerPage.dart` | 0% | `test/DisclaimerPage/disclaimerPage.dart` | Test defines its own `DisclaimerPage` stub widget inline; never imports `package:mazilon/disclaimerPage.dart` |
| `lib/pages/UserSettings.dart` | 0% | `test/UserSettings/UserSettings_test.dart` | Test imports `UserSettings.dart` (local stub), not the real page |
| `lib/pages/journal.dart` | 0% | `test/Thanks/Journal_test.dart` + `test/Thanks/journal.dart` | `Journal_test.dart` imports local `journal.dart` stub |
| `lib/pages/positive.dart` | 0% | `test/POSITIVE/positiveTest.dart` | Verify — likely same pattern |
| `lib/pages/thankYou.dart` | 0% | `test/Thanks/thankYou.dart` | Local stub pattern |
| `lib/util/Thanks/AddForm.dart` | 0% | `test/Thanks/AddForm.dart`, `test/thanksListWidget/AddForm.dart` | Both likely define local stubs |
| `lib/pages/WellnessTools/player.dart` | 0% | `test/WellnessTools/player.dart` | Local stub pattern |
| `lib/initialForm/initialFormPage1.dart` | 0% | `test/initialForm/initialFormPage1_Test.dart` | Imports confirmed via mock file; check if real widget is exercised |
| `lib/initialForm/toFormPage.dart` | 0% | `test/initialForm/toFormPage_Test.dart` | Check import |
| `lib/initialForm/form.dart` | 0% | `test/initialForm/form_Test.dart` | Check import |

**Pattern explanation:** Most test files in this repo were authored as self-contained widget tests that duplicate (not import) the widget under test. This means 93 tests pass cleanly — but they exercise the stub, not production code. Correcting imports across these 10 files is the highest-leverage action in the entire roadmap.

---

## Recommended CI Coverage Thresholds

Given the current baseline of 27.6% and the prevalence of Firebase/platform dependencies that require mocking:

| Gate | Target | Rationale |
|---|---|---|
| **Global line coverage** | 50% now → 70% in 3 months → 85% at full roadmap completion | Aggressive but reachable; excludes codegen files |
| **Tier 1 (critical) files** | 80% minimum per file | Safety/auth/persistence must be tested |
| **Tier 2 (high) files** | 60% minimum per file | Large pages with complex logic |
| **Tier 3 (medium) files** | 50% minimum per file | Utility/widget tier |
| **Excluded files** | No gate (0% acceptable) | Codegen, bootstrap |

Recommended `lcov` exclude patterns in CI:
```
--ignore-filename-regex 'lib/l10n/app_localizations.*\.dart'
--ignore-filename-regex 'lib/util/Firebase/firebase_options\.dart'
--ignore-filename-regex 'lib/global_enums\.dart'
--ignore-filename-regex 'lib/l10n/l10n\.dart'
```

---

## Suggested Order of Attack

Batched into ~10-file chunks, ordered by risk-score × fix-effort ratio.

### Batch 1: Cheap Wins — Fix Test Imports (est. 1–2 days)

Fix the 10 test files that import local stubs instead of production classes. This single action will likely raise global coverage from 27.6% to ~40–45% with zero new test code.

1. `test/DisclaimerPage/disclaimerPage.dart` → import `package:mazilon/disclaimerPage.dart`
2. `test/UserSettings/UserSettings_test.dart` → import `package:mazilon/pages/UserSettings.dart`
3. `test/Thanks/Journal_test.dart` + `test/Thanks/journal.dart` → import `package:mazilon/pages/journal.dart`
4. `test/POSITIVE/positiveTest.dart` → import `package:mazilon/pages/positive.dart`
5. `test/Thanks/thankYou.dart` → import `package:mazilon/pages/thankYou.dart`
6. `test/Thanks/AddForm.dart` + `test/thanksListWidget/AddForm.dart` → import `package:mazilon/util/Thanks/AddForm.dart`
7. `test/WellnessTools/player.dart` → import `package:mazilon/pages/WellnessTools/player.dart`
8. `test/initialForm/toFormPage_Test.dart` + `test/initialForm/form_Test.dart` → verify imports

After fixing imports, re-run `flutter test --coverage` and re-evaluate. Many tests will need minor mock/provider additions but the skeletons are already there.

### Batch 2: Persistence & Locale Layer (est. 2–3 days)

These are pure-Dart or near-pure-Dart services that do not require a full Flutter widget harness.

9. `lib/util/persistent_memory_service.dart` — unit test with `SharedPreferences.setMockInitialValues`
10. `lib/Locale/locale_service.dart` — unit test; inject `locale` static field
11. `lib/util/logger_service.dart` — unit test; mock `Sentry.isEnabled`; cover both branches of `captureLog`
12. `lib/util/type_utils.dart` — 2 missing lines; trivial
13. `lib/util/languages_util_functions.dart` — 5 missing lines; add RTL-script test case
14. `lib/iFx/service_locator.dart` — unit test with overridden GetIt registrations

### Batch 3: Notification Service (est. 2–3 days)

Platform-gated but has injectable overrides.

15. `lib/pages/notifications/notification_service.dart` — `supportsReminderSettings` has platform/web overrides in its signature; cover all branches
16. `lib/pages/notifications/time_picker.dart` — small, 25 missed lines
17. `lib/pages/notifications/notification_page.dart` — 28 missed lines; widget test with provider mocks
18. `lib/pages/notifications/set_notification_widget.dart` — 85 missed lines; mock `NotificationsService`

### Batch 4: PDF / File Export (est. 2–3 days)

Requires asset-bundle mocking.

19. `lib/util/PDF/create_pdf.dart` — unit test with mocked `rootBundle`; cover both `getDirection`/`getAlign` branches
20. `lib/file_service.dart` — mock `PersistentMemoryService`, `createPDF`, `share_plus`
21. `lib/AnalyticsService.dart` — 11 missed lines; mock Firebase Analytics

### Batch 5: Firebase Functions (est. 3–5 days)

Largest single file; use `fake_cloud_firestore` + `firebase_auth_mocks`.

22. `lib/util/Firebase/firebase_functions.dart` — start with `FirebaseAuthService` (2 methods, well-isolated), then `FirebaseFunctionsService` write methods, then read methods
23. `lib/pages/FormAnswer.dart` — depends on Firebase; mock Firestore

### Batch 6: Personal Plan Pages (est. 3–4 days)

Full widget tests with provider scaffolding.

24. `lib/pages/PersonalPlan/myPlanPageFull.dart`
25. `lib/pages/PersonalPlan/myPlan.dart`
26. `lib/util/Form/retrieveInformation.dart` (uncovered 48.1% → 90%+)
27. `lib/util/Form/formPagePhoneModel.dart` (10.6% → 80%)

### Batch 7: Sign-In / User Flow (est. 2–3 days)

28. `lib/pages/SignIn_Pages/firstPage.dart`
29. `lib/pages/SignIn_Pages/introduction.dart`
30. `lib/util/SignIn/form_container.dart` (not in lcov)
31. `lib/util/SignIn/sign_callback.dart` (not in lcov)

### Batch 8: Form Pages Completion (est. 2–3 days)

32. `lib/form/form.dart`
33. `lib/form/phonePageListItem.dart`
34. `lib/form/phonePageform.dart`
35. `lib/form/shareform.dart`
36. `lib/initialForm/initialFormPage2.dart`

### Batch 9: UI Polish & Utilities (est. 1–2 days)

37. `lib/util/appInformation.dart` (34% → 80%)
38. `lib/util/userInformation.dart` (80% → 95%): cover `fromJson`
39. `lib/util/styles.dart` (51% → 85%): RTL style branches
40. `lib/menu.dart` (64% → 85%): drawer navigation callbacks
41. `lib/MainPageHelpers/MainPageList/list_utils.dart` (27% → 80%)
42. `lib/MainPageHelpers/MainPageList/mainpage_list_widget.dart` (47% → 80%)

### Batch 10: Tier 4 Cleanup (est. 1 day)

43–52. Remaining Tier 3/4 files (EmergencyPhones gap, phoneTextAndIcon, addFormAnswer, reminder_debug_panel, etc.)

---

## Files Not in lcov (Never Imported by Any Test)

These 5 files have no lcov entry at all — they are not imported transitively by any test file:

| File | LOC | Notes |
|---|---|---|
| `lib/global_enums.dart` | 27 | Exclude from gate; pure enums |
| `lib/l10n/l10n.dart` | 8 | Exclude from gate; codegen helper |
| `lib/util/Form/form.dart` | 252 | Should be covered in Batch 8 |
| `lib/util/SignIn/form_container.dart` | 96 | Should be covered in Batch 7 |
| `lib/util/SignIn/sign_callback.dart` | 22 | Should be covered in Batch 7 |
