# Mazilon Coverage Status

Generated: 2026-05-08 — pairs with `coverage-gap-analysis.md` (the original roadmap).

## Headline

| Metric | Baseline | Now | Change |
|---|---|---|---|
| Tests | 93 | 410 + 8 skipped | +325 |
| Filtered global coverage (excl codegen) | ~35% | **59.9%** | +25 pts |
| Raw global coverage (incl codegen) | 27.6% | ~40% | +12 pts |
| Files at 0% coverage | 31 | 11 | −20 |
| Tier 1 critical at <50% | 7/7 | 1/7 | 6 closed |
| Coverage gate | none | enforced in CI | new |

`flutter test --coverage` now runs in CI on every push/PR (see `.github/workflows/main.yml`); the gate `dart run scripts/check_coverage.dart` blocks merges that violate per-tier thresholds.

## What landed (by batch)

### Batch 1 — Real-widget rewrites (replaces stub-test anti-pattern)
- Deleted duplicate stub widgets in `test/DisclaimerPage/disclaimerPage.dart` and `test/UserSettings/UserSettings.dart`; rewrote consumer tests to import production classes.
- New tests for `Journal` (real widget), `UserSettings`, `disclaimerPage`, AddForm, plus `test/helpers/widget_test_scaffold.dart` reusable provider+GetIt fixture.
- 8 widget-integration tests in `Journal_test.dart` and `menu_test.dart` are `skip: true` pending PhonePageData provider/dialog scaffolding (tracked in TODO comments).

### Batch 2 — Persistence & locale (pure-Dart) — 51 tests
- `test/util/persistent_memory_service_test.dart` — every `PersistentMemoryType` branch + error paths.
- `test/util/type_utils_test.dart`, `test/util/languages_util_functions_test.dart`.
- `test/Locale/locale_service_test.dart` — locale fallback + persistence.
- `test/util/logger_service_test.dart` — Sentry-disabled paths.
- `test/iFx/service_locator_test.dart` — DI registration completeness.

### Batch 3 — Notifications — 11 tests
- `notification_service_unit_test.dart` for `calculateTime` + `supportsReminderSettings` platform-override branches.
- `time_picker_test.dart` widget render with boundary values.

### Batch 4 — PDF / file export — 24 tests
- `PDF/create_pdf_test.dart` — RTL/LTR direction branches, multi-section + empty section handling, font/asset bundle loaded from `flutter_test` binding.
- `file_service/file_service_test.dart` — getPrefsData/filterEmptyData/formatPhonesText/checkEmptyMessage + share PDF / non-PDF / shareTextOnly catch path.
- `AnalyticsService/AnalyticsService_test.dart`.

### Batch 5 — Firebase functions — 61 tests
- `lib/util/Firebase/firebase_functions.dart` from **5.1% → 62.4%** (1387 LOC file).
- 5 test files under `test/Firebase/`: helpers, loadUserInformation, loadAppInfoFromJson, loadAppFromFirebase switch branches, CRUD helpers.
- Production code minimally extended with optional `FirebaseFirestore? firestore` param (defaults to `FirebaseFirestore.instance`) on 14 functions to enable `fake_cloud_firestore` injection.
- **Deferred:** `FirebaseAuthService.signUp/signIn` — `firebase_auth_mocks` is incompatible with this repo's `firebase_core ^4.6.0` + `uuid ^4.5.3`. Either generate Mockito mocks via `build_runner` or wait for an `auth_mocks` release that supports newer firebase_core.

### Batch 7 — Sign-in flow — 13 tests
- `SignIn/form_container_test.dart` — password-visibility toggle, `onFieldSubmitted` wiring, eye icon state.
- `SignIn/popup_toast_test.dart` — platform-channel mock + tolerance for empty/long messages.
- `SignIn/sign_callback_test.dart` — navigation no-op on `false`, navigates on `true`.

### Batch 9 — UI utilities (agent)
- `userInformation_test.dart` (`fromJson`, every `update*` method).
- `appInformation_test.dart` (60+ ChangeNotifier methods).
- `styles_test.dart` (RTL branches).
- `MainPageHelpers/list_utils_test.dart`, `mainpage_list_widget_test.dart` (empty-state).
- `EmergencyPhones_test.dart` (launchUrl callback).
- `Phone/phoneTextAndIcon_test.dart`.
- `FormAnswer/addFormAnswer_test.dart` (null/error paths).
- `menu_test.dart` (3 of 6 tests skipped — see Batch 1).
- `form/retrieveInformation_test.dart` (every switch case).

### Batch 11 — CI coverage gate — landed
- `scripts/check_coverage.dart` parses `lcov.info`, applies excludes (`app_localizations*`, `firebase_options`, `global_enums`, `l10n.dart`), enforces global + per-tier thresholds.
- `.github/workflows/main.yml` updated: `flutter test --coverage`, then `dart run scripts/check_coverage.dart`, lcov uploaded as artifact.

## Gate configuration (`scripts/check_coverage.dart`)

| Threshold | Floor | Notes |
|---|---|---|
| Global | 55% | Currently 59.9% |
| Tier 1 (Firebase, persistence, disclaimer, file_service, PDF, locale) | 50% per file | All meet floor |
| Tier 2 (UserSettings, journal, myPlan) | 40% per file | All meet floor |
| Excluded | 0% | codegen + bootstrap |

Tier 2 will expand as Batch 8 / 6 gaps land (positive.dart, myPlanPageFull, form/form, all initialForm/* pages).

## What's deferred

These items were scoped in the gap analysis but not closed in this session. Each is a clean, focused follow-up:

| File | Current | Reason deferred |
|---|---|---|
| `lib/main.dart` | 1.7% | Bootstrap/route generation; needs integration tests, not unit tests |
| `lib/pages/positive.dart` | 0% | Heavy widget — the test stub-widget wasn't deleted yet; same pattern as Journal/UserSettings to follow |
| `lib/initialForm/*.dart` (4 files, ~350 LOC) | 0% | Multi-step onboarding wizards; need full provider + Navigator mocking |
| `lib/form/*.dart` (4 files, ~370 LOC) | 0% | Multi-step form wizards; same as above |
| `lib/pages/PersonalPlan/myPlanPageFull.dart` | 0% | Clinical-grade safety plan; needs provider scaffolding |
| `lib/pages/notifications/reminder_debug_panel.dart` | 0% | Debug panel + real notifications integration |
| `lib/pages/notifications/set_notification_widget.dart` | 0% | Notification picker widget; needs `NotificationsService` mock |
| `lib/pages/notifications/notification_service.dart` (initializeNotification, scheduleNotification) | 12.7% | Platform plugins (`flutter_local_notifications`, `workmanager`) cannot be exercised in `flutter test`; integration-test territory |
| `FirebaseAuthService.signIn/signUp` | 0% | `firebase_auth_mocks` incompatible; needs Mockito codegen |

Each deferred item now has a TODO in `scripts/check_coverage.dart` and the original `coverage-gap-analysis.md` to reach for.

## Pattern established for future contributors

1. **Real production widgets only.** Never duplicate a `lib/...dart` widget into `test/...dart` and test the duplicate. The pattern in `test/helpers/widget_test_scaffold.dart` is the only sanctioned shape: register fakes on GetIt, wrap in MultiProvider + MaterialApp + ScreenUtilInit.
2. **Service layer fakes over mocks.** Implement the abstract `PersistentMemoryService` / `IncidentLoggerService` / `AnalyticsService` interfaces with simple in-memory recorders rather than reach for Mockito for these.
3. **Inject Firestore.** When testing functions that call `FirebaseFirestore.instance`, add an optional `FirebaseFirestore? firestore` named param defaulting to `.instance`, then pass `FakeFirebaseFirestore()` from tests. Already done for 14 helpers in `firebase_functions.dart`.
4. **Mock platform channels** (path_provider, fluttertoast) via `setMockMethodCallHandler` only when unit-testing a function that touches the channel directly. For widget tests, prefer mocking the higher-level service.
5. **`flutter test --coverage` runs in CI** — write tests for new code as you write the code, the gate will fail otherwise.
