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

## Round 2 — deferred items closed

Generated: 2026-05-14 — picks up where the deferred list above leaves off.

### Headline

| Metric | Round 1 | Round 2 | Change |
|---|---|---|---|
| Tests | 410 + 8 skipped | 441 + 8 skipped | +31 |
| Filtered global coverage (excl codegen) | 59.9% | **69.7%** | +9.8 pts |
| Tier 2 floor | 40% | 40% (now applied to 15 files) | +12 files in tier |
| Global floor | 55% | 65% | +10 pts |

### What landed

#### Batch A — Notifications widgets — 10 tests, 2 files

- `test/notifications/set_notification_widget_test.dart` (6 tests). Pumps the real `SetNotificationWidget` on iOS so `NotificationsService.supportsReminderSettings()` short-circuits before the WorkManager/permission flow. Stubs `IOSFlutterLocalNotificationsPlugin` via `registerWith()` to avoid the `LateInitializationError` on the plugin's platform interface, and installs an in-test `WorkmanagerPlatform` subclass so cancel/register calls don't throw `UnimplementedError`. Covers: structural render (TimePicker + 3 buttons), platform guard removes ReminderDebugPanel on iOS, post-frame `_currentHour/_currentMinute` flow from `UserInformation`, "set time" listener wiring (verifies `updateNotificationHour`/`updateNotificationMinute` fire), "cancel notifications" hits both `WorkmanagerPlatform.cancelAll` and the local-notifications channel's `cancelAll`, and "show example" does not throw. `lib/pages/notifications/set_notification_widget.dart`: **0% → 84.7%**.
- `test/notifications/reminder_debug_panel_test.dart` (4 tests). Real `ReminderDebugPanel` widget wrapped in a `Scaffold` (the panel uses `ListTile` and needs a Material ancestor). Seeds `SharedPreferences.setMockInitialValues` with `reminderDebugLast*` keys so `_refresh()` finds non-empty values. Verifies the expansion tile renders, expanded diagnostics surface the seeded `2025-01-01T12:00:00.000Z` / `success` / `NotificationWorker0900Periodic` values + scheduled `09:00` from `UserInformation`, the "Reschedule now" button is disabled on non-Android, and the "Refresh" button rebuilds without throwing. `lib/pages/notifications/reminder_debug_panel.dart`: **0% → 69.3%**. `reminder_debug_recorder.dart` also rises to **85.7%** via prefs reads.

#### Cleanup
- Deleted `test/initialForm/initialFormPage1.dart` — a leftover stub widget that duplicated the production class. The existing `_Test.dart` files in `test/initialForm/` already import the real `lib/initialForm/*.dart` widgets; no test code needed to move.

### Per-file deltas (vs round 1)

| File | R1 | R2 |
|---|---|---|
| `lib/pages/notifications/set_notification_widget.dart` | 0% | **84.7%** |
| `lib/pages/notifications/reminder_debug_panel.dart` | 0% | **69.3%** |
| `lib/pages/notifications/reminder_debug_recorder.dart` | 0% | **85.7%** |
| `lib/pages/notifications/time_picker.dart` | n/a | 84.0% |
| Global filtered coverage | 59.9% | **69.74%** |

### Punted

- **`lib/initialForm/*.dart` (4 files, ~350 LOC, still 0%).** The existing test files (`test/initialForm/*_Test.dart`) already exercise these widgets via `Mockito` and pass in isolation, but flutter test's default discovery glob is `*_test.dart` (lowercase), so the capital-T names mean these tests are silently skipped in CI. Renaming them is in scope, BUT doing so exposes pre-existing setUp/test-body double-registration bugs in `test/form/formpagetemplate_Test.dart` and the initialForm tests themselves (e.g. `getIt.registerLazySingleton<PersistentMemoryService>` called both in `setUp` and in the test body without an intervening `unregister`). Fixing those bugs is beyond the established "don't refactor for testability" guard rail. Tracked as a TODO comment block in `scripts/check_coverage.dart`.
- **`lib/main.dart`** — bootstrap/route generation, out of unit-test scope per the task brief.

### Production code changes

None. Round 2 is test-only; no library code modified.

### `skip: true` tests

No new skips. The 8 pre-existing skips from round 1 (3 in `Journal_test.dart`, 5 in `menu_test.dart` for PhonePageData provider/dialog scaffolding) remain untouched.

## Round 3 — initialForm rename + double-registration fix

Generated: 2026-05-15 — clears the round-2 "punted" list.

### Headline

| Metric | Round 2 | Round 3 | Change |
|---|---|---|---|
| Tests | 441 + 8 skipped | 454 + 8 skipped | +13 |
| Filtered global coverage (excl codegen) | 69.74% | **74.15%** | +4.41 pts |
| Files in tier 2 | 14 | 18 (+ initialForm/*) | +4 |
| Global floor | 65% | 70% | +5 pts |

### What landed

#### Test rename — `_Test.dart` → `_test.dart`

Flutter's test discovery glob is `*_test.dart` (lowercase); the capital-T files were silently skipped in CI. `git mv`'d to preserve history:

- `test/initialForm/form_Test.dart` + `.mocks.dart` → `_test.dart`
- `test/initialForm/initialFormPage1_Test.dart` + `.mocks.dart` → `_test.dart`
- `test/initialForm/initialFormPage2_Test.dart` + `.mocks.dart` → `_test.dart`
- `test/initialForm/toFormPage_Test.dart` → `_test.dart` (no mocks; body is commented out, kept as placeholder)
- `test/form/formpagetemplate_Test.dart` + `.mocks.dart` → `_test.dart`
- `test/form/shareform_Test.dart` + `.mocks.dart` → `_test.dart`

Inside each renamed file, the `import 'X_Test.mocks.dart'` line was updated to `_test.mocks.dart`. The Mockito-generated `.mocks.dart` files reference the source-file path only in a leading comment (no `part of`), so they keep working without regeneration.

#### Double-registration bug fix

`test/form/formpagetemplate_test.dart` registered `PersistentMemoryService` twice: once in `setUp()` and again in the body of the single `testWidgets` block — the second registration would have thrown `Object/factory with type PersistentMemoryService is already registered` had the test ever run under the lowercase discovery name. Removed the redundant registration; the setUp version is sufficient (and uses the same `MockPersistentMemoryService` from `share_and_download_test.mocks.dart`). No other test in the renamed set has the same bug (form_Test.dart and the initialForm files all call `GetIt.instance.reset()` inside setUp before registering, so they're idempotent).

### Per-file deltas (vs round 2)

| File | R2 | R3 |
|---|---|---|
| `lib/initialForm/initialFormPage1.dart` | 0% | **98.0%** |
| `lib/initialForm/initialFormPage2.dart` | 0% | **84.7%** |
| `lib/initialForm/form.dart` | 0% | **65.2%** |
| `lib/initialForm/toFormPage.dart` | 0% | **70.5%** |
| `lib/initialForm/CountrySelectorWidget.dart` | n/a | **85.9%** (pulled in transitively) |
| `lib/form/formpagetemplate.dart` | ~40% | **61.1%** |
| `lib/form/shareform.dart` | ~40% | **73.2%** |
| `lib/util/Firebase/firebase_functions.dart` | 62.4% | **64.4%** (transitive) |
| Global filtered coverage | 69.74% | **74.15%** |

The `initialForm/*.dart` files are now formal tier-2 entries in `scripts/check_coverage.dart`; the old TODO comment block in that file is removed. The global floor moves from 65% → 70% to lock in the new headroom.

### Production code changes

None. Round 3 is purely test rename + one stale duplicate-registration removal. `lib/` is untouched.

### Still deferred

- **`lib/main.dart`** — bootstrap/route generation (~1.7% covered). Integration-test territory; not addressable via `flutter test` unit suite.
- **`lib/pages/notifications/notification_service.dart` `initializeNotification` / `scheduleNotification` branches** — direct `flutter_local_notifications` + `workmanager` plugin calls that require a real platform binding. The pure-Dart sub-methods (`calculateTime`, `supportsReminderSettings`, top-level `cancel*`) are covered; the platform-bound branches stay at ~12% and are tracked as integration tests, not unit tests.
- **FirebaseAuthService.signUp/signIn** — already landed via Mockito codegen in `test/Firebase/firebase_auth_service_test.dart` (7 tests). Not actually deferred any more; the round-2 doc listed it but the tests were authored after that doc was written. Listed here for accuracy.

### `skip: true` tests

No new skips. The 8 pre-existing skips from round 1 (3 in `Journal_test.dart`, 5 in `menu_test.dart`) remain untouched.

## Round 4 — deferred items closed (notifications plugin paths, FormAnswer, FeelGood image picker, sign-in pages, interaction coverage)

Generated: 2026-05-16 — picks up the residual deferred items from round 3 and pushes filtered coverage past 79%.

### Headline

| Metric | Round 3 | Round 4 | Change |
|---|---|---|---|
| Tests | 454 + 8 skipped | 509 + 8 skipped | +55 |
| Filtered global coverage (excl codegen) | 74.15% | **79.31%** | +5.16 pts |
| Files at 0% (filtered) | 4 | **0** | −4 |
| Global floor | 70% | 75% | +5 pts |

### What landed

#### Notifications — initialize/cancel + notification page

- `test/notifications/notification_service_initialize_test.dart` (~295 LOC). Exercises the `NotificationsService.initializeNotification` and `cancelNotifications` static entry-points directly — the platform-bound branches that were marked "integration-test territory" in round 3. Reuses the round-2 plugin-stub pattern: registers a real `IOSFlutterLocalNotificationsPlugin` / `AndroidFlutterLocalNotificationsPlugin` implementation via `registerWith()` to avoid the `LateInitializationError`, installs a recording `WorkmanagerPlatform` subclass, and stubs the local-notifications `MethodChannel`. Covers iOS init permission-request branch, Android channel-create branch, and the cross-platform `cancelAll`. `lib/pages/notifications/notification_service.dart`: **12.7% → 66.7%**.
- `test/notifications/notification_page_test.dart`. Real `NotificationPage` widget pumped via scaffold. `lib/pages/notifications/notification_page.dart`: **~0% → 96.4%**.
- `test/notifications/reminder_debug_panel_test.dart` (extended). Two new tests: clipboard `Copy diagnostics` (mocks `SystemChannels.platform` for `Clipboard.setData`, verifies JSON payload contains `capturedAt` / `lastFireAt` / `notificationPermission` and a `SnackBar` surfaces) and `Clear history` button rebuilds without throwing. `lib/pages/notifications/reminder_debug_panel.dart`: **69.3% → 82.7%**.

#### Sign-in flow — disclaimer wrapper + introduction

- `test/SignIn/firstPage_test.dart`. Real `firstPage` widget; `disclaimerSigned=false` branch renders `DisclaimerPage`, `true` branch renders the post-disclaimer entry. `lib/pages/SignIn_Pages/firstPage.dart`: **0% → 100%**.
- `test/SignIn/introduction_test.dart`. Real `Introduction` widget; Scaffold + CircularProgressIndicator + greeting render. `lib/pages/SignIn_Pages/introduction.dart`: **0% → 100%**.

#### Thanks / FormAnswer — real-widget rewrites + interactions

- `test/Thanks/AddForm_real_test.dart`. Real `AddForm` dialog; renders TextFormField + close/save buttons, exercises both submit and cancel paths. `lib/util/Thanks/AddForm.dart`: **partial → 100%**.
- `test/Thanks/journal_interactions_test.dart`. Real `Journal` widget — tap-delete flow (`removeThankYou`) and `editThankYou` closure (routes through `AddForm` seeded with existing text). `lib/pages/journal.dart`: → **73.0%**.
- `test/FormAnswer/FormAnswer_real_test.dart`. Real production `FormAnswer` page + `addFormAnswer` helper. `lib/pages/FormAnswer.dart`: → **100%**. `lib/util/FormAnswer/addFormAnswer.dart`: → **100%**.

#### FeelGood / image picker service

- `test/FeelGood/image_picker_service_impl_test.dart`. Image-picker plugin stubbed via `setMockMethodCallHandler`; pick-image success, pick-image cancellation (null), and gallery error path. `lib/pages/FeelGood/image_picker_service_impl.dart`: **0% → 66.7%**.

#### Firebase load branches

- `test/Firebase/firebase_functions_load_firebase_branches_test.dart` (~378 LOC). Targets the residual branches in `loadAppFromFirebase` switch + nested helpers that weren't reached by the round-1 Firebase batch — additional doc-shape edge cases via `FakeFirebaseFirestore`. `lib/util/Firebase/firebase_functions.dart`: **64.4% → 68.0%**.

#### MainPageHelpers — interactions

- `test/MainPageHelpers/mainpage_list_widget_interactions_test.dart`. Real `MainPageListWidget` — add/edit/delete row interactions, drag-reorder gesture, empty-state callback wiring. `lib/MainPageHelpers/MainPageList/mainpage_list_widget.dart`: prior partial → **60.3%**.

#### Form template branches

- `test/form/formpagetemplate_branches_test.dart`. Real `FormPageTemplate` with multiple page-type branches (text/phone/list) and the back-button + share-completion branches not previously reached. `lib/form/formpagetemplate.dart`: **61.1% → 65.9%**.

#### Tooling

- `scripts/file_coverage.dart` — small helper that dumps per-file `pct  hit/total  path` sorted ascending, with an optional path-substring filter. Useful for quickly identifying the next coverage gap. Not part of CI; ad-hoc dev tool.

### Per-file deltas (vs round 3)

| File | R3 | R4 |
|---|---|---|
| `lib/pages/notifications/notification_service.dart` | 12.7% | **66.7%** |
| `lib/pages/notifications/notification_page.dart` | ~0% | **96.4%** |
| `lib/pages/notifications/reminder_debug_panel.dart` | 69.3% | **82.7%** |
| `lib/pages/SignIn_Pages/firstPage.dart` | 0% | **100%** |
| `lib/pages/SignIn_Pages/introduction.dart` | 0% | **100%** |
| `lib/pages/FeelGood/image_picker_service_impl.dart` | 0% | **66.7%** |
| `lib/pages/FormAnswer.dart` | partial | **100%** |
| `lib/util/Thanks/AddForm.dart` | partial | **100%** |
| `lib/util/FormAnswer/addFormAnswer.dart` | partial | **100%** |
| `lib/pages/journal.dart` | ~40% | **73.0%** |
| `lib/MainPageHelpers/MainPageList/mainpage_list_widget.dart` | ~25% | **60.3%** |
| `lib/util/Firebase/firebase_functions.dart` | 64.4% | **68.0%** |
| `lib/form/formpagetemplate.dart` | 61.1% | **65.9%** |
| Global filtered coverage | 74.15% | **79.31%** |

### Production code changes

None. Round 4 is test-only; `git diff` against `lib/` shows zero changes. The round-1 `firestore` injection-param refactor in `firebase_functions.dart` is the only `lib/` modification across the whole coverage initiative, and that hasn't been touched since.

### `skip: true` tests

No new skips. The 8 pre-existing skips from round 1 (3 in `Journal_test.dart`, 5 in `menu_test.dart`) remain untouched.

### Still deferred

- **`lib/main.dart`** (1.7%). Bootstrap, runApp wiring, generated route table — integration-test territory only, out of unit-test scope.
- **`lib/pages/WellnessTools/player.dart`** (5.3%). Wraps `YoutubePlayerController` + native player view; the controller's `addListener` callback and `metadata.videoId` getters require the platform view to be live. Integration-test territory.
- **`lib/util/logger_service.dart`** (10.5%). `initializeSentry` calls `runApp` and `SentryFlutter.init` — cannot exercise without bootstrapping a real Flutter binding. The `captureLog` branch is gated on the static `Sentry.isEnabled` flag which is false in `flutter test` (no init), so the inner branch is also platform-bound.
- **`lib/AnalyticsService.dart`** (36.4%). The `MixPanelService.init` body and `trackEvent` post-init are gated on a non-empty `String.fromEnvironment('MIXPANEL_PROJECT_TOKEN')`, which is empty under `flutter test`. The empty-token short-circuit branches are covered.

### CI floor

Raised from 70% → **75%** in `scripts/check_coverage.dart`. Current 79.31% leaves ~4 pts of headroom — enough to absorb test churn from new features without breaking the gate, while still ratcheting on every round.

## Round 5 — tier-3 polish (interaction tests for previously-rendered widgets)

Generated: 2026-05-16 — squeezes the remaining tier-3/4 interaction surfaces.

### Headline

| Metric | Round 4 | Round 5 | Change |
|---|---|---|---|
| Tests | 509 + 8 skipped | 564 + 8 skipped | +55 |
| Filtered global coverage (excl codegen) | 79.31% | **85.21%** | +5.90 pts |
| Files at 100% (filtered) | 22 | **25** | +3 |
| Global floor | 75% | 80% | +5 pts |

### What landed

Round 5 is exclusively new test files — `git diff lib/` is empty. Every gain
comes from driving interaction paths through the same production widgets that
rounds 1–4 only rendered around.

#### Suggestion-widget interactions — `thanksItemSug` / `positiveTraitItemSug` to 100%

- `test/Thanks/thanksItemSug_test.dart` (4 tests). Drives the tap-add
  GestureDetector, the inputText-override branch, and the `show == false`
  branch (`stopShowing` > available suggestions makes `build()` return an
  empty `Container()`).
- `test/util/positiveTraitItemSug_test.dart` (4 tests). Same pattern for the
  positive-traits sibling, plus a `FakePersistentMemoryService`-backed read
  in the on-tap path to exercise the `service.getItem('positiveTraits', …)`
  await branch.
- `lib/util/Thanks/thanksItemSug.dart`: 75.6% → **100%**.
- `lib/util/Traits/positiveTraitItemSug.dart`: 69.6% → **100%**.

#### Journal `addThankYou` + first-of-day popup

- `test/Thanks/journal_add_via_suggestion_test.dart` (2 tests). Taps the
  add button on a rendered `ThanksItemSuggested` to invoke
  `Journal.addThankYou`, then drives the `Future.delayed(0)` post-tap
  popup. Covers the "1st entry of the day → AlertDialog" branch
  (lines 116–170 of `lib/pages/journal.dart`).
- `lib/pages/journal.dart`: 73.0% → **96.6%**.

#### Positive page — add/remove/edit interactions

- `test/POSITIVE/positive_interactions_test.dart` (4 tests). Suggestion-tap
  invokes `addPositiveTrait`; the row's trash icon invokes
  `removePositiveTrait`; the header IconButton + per-row edit icon open
  AddForm via `editNotification`. `lib/pages/positive.dart`: 73.5% → **95.3%**.

#### Home `MainPageList/ListWidget` — every closure on both pageCodes

- `test/MainPageHelpers/mainpage_list_widget_full_interactions_test.dart`
  (5 tests). Covers `buildThanksItemSug` / `buildPositiveTraitItemSug`,
  `showThankYouPopup`, both `editItemFunction` arms, both
  `removeItemFunction` arms, and the dialog seeded-text branch.
  `lib/MainPageHelpers/MainPageList/mainpage_list_widget.dart`:
  60.3% → **90.9%**.

#### Form-wizard interactions — `formpagetemplate` + form/initialForm progress indicators

- `test/form/formpagetemplate_interactions_test.dart` (6 tests). Empty-text
  validate branch, non-empty add path, CheckboxListTile toggle (both add-
  and remove-by-index branches), show-more button, every `collectionName`
  arm of `createSelection` (DifficultEvents, MakeSafer, FeelBetter,
  Distractions), and `editItem`/`removeItem` via the row's trash icon.
  `lib/form/formpagetemplate.dart`: 65.9% → **92.3%**.
- `test/form/form_navigation_test.dart` (3 tests). Drives next/prev/skip on
  `FormProgressIndicator` (the personal-plan wizard host), plus the
  save-and-quit header IconButton which navigates to Menu via
  `pushAndRemoveUntil`. `lib/form/form.dart`: 65.4% → **82.7%**.
- `test/form/shareform_interactions_test.dart` (3 tests). Share/download
  IconButton handlers plus the bottom Continue button. Uses the test
  scaffold's `NoopFileService` to assert `download()` was called.
  `lib/form/shareform.dart`: 73.2% → **85.4%**.
- `test/form/phonePageform_interactions_test.dart` (1 test). Continue
  button — drives `loadItemsFromPrefs → saveItemsToPrefs → update → next`.
  `lib/form/phonePageform.dart`: 73.4% → **77.7%**.
- `test/initialForm/form_navigation_test.dart` (5 tests). disclaimerSigned
  false branch renders DisclaimerPage; skip/next/prev jumps between
  InitialFormPage1, InitialFormPage2 and ToFormPage via the parent state's
  callbacks. `lib/initialForm/form.dart`: 65.2% → **76.4%**.
- `test/initialForm/toFormPage_interactions_test.dart` (2 tests). Both
  TextButton onPressed handlers — push FormProgressIndicator and push Menu.
  `lib/initialForm/toFormPage.dart`: 70.5% → **100%**.

#### Menu — `changeCurrentIndex` every PagesCode branch

- `test/menu_change_index_test.dart` (6 tests). Reaches into the rendered
  Home widget and invokes its captured `changeCurrentIndex` closure for
  each `PagesCode` — exercises the FullPlan/QualitiesList/GratitudeJournal/
  EmergencyPhones/About/NotificationPage/FeelGoodPage switch arms
  (lines 91–136 of `lib/menu.dart`). Drains Positive's 10s `initState`
  timer with `tester.pump(Duration(seconds: 11))` and registers a
  `NoopImagePickerService` for the FeelGood arm. `lib/menu.dart`:
  69.0% → **86.0%**.

#### Main menu dialog — every drawer button

- `test/main_menu_dialog_test.dart` (6 tests). Opens the dialog via a
  helper Scaffold, then invokes each TextButton's `onPressed` directly
  (tap-routing through showGeneralDialog's `Stack/Positioned/Material`
  tree is flaky in flutter_test, but invoking the captured closure is
  equivalent and exercises the same production lines). Covers close (X),
  About, Settings (pushes UserSettings), Notifications (with platform
  override), Share (channel stubbed), and the isWeb → hide-notifications
  branch. `lib/main_menu_dialog.dart`: 75.7% → **97.3%**.

#### UserSettings — reset dialog + extra gender branches

- `test/UserSettings/UserSettings_interactions_test.dart` (4 tests).
  Confirm/Close on the reset confirmation dialog drives `resetData` →
  `Navigator.pushAndRemoveUntil(FirstPage)`. Plus render-only tests for
  female user (gender-specific dropdown initial value) and nonBinary user
  (`binary=true` branch). `lib/pages/UserSettings.dart`: 75.0% → **86.2%**.

### Per-file deltas (vs round 4)

| File | R4 | R5 |
|---|---|---|
| `lib/util/Thanks/thanksItemSug.dart` | 75.6% | **100%** |
| `lib/util/Traits/positiveTraitItemSug.dart` | 69.6% | **100%** |
| `lib/initialForm/toFormPage.dart` | 70.5% | **100%** |
| `lib/main_menu_dialog.dart` | 75.7% | **97.3%** |
| `lib/pages/journal.dart` | 73.0% | **96.6%** |
| `lib/pages/positive.dart` | 73.5% | **95.3%** |
| `lib/form/formpagetemplate.dart` | 65.9% | **92.3%** |
| `lib/MainPageHelpers/MainPageList/mainpage_list_widget.dart` | 60.3% | **90.9%** |
| `lib/pages/UserSettings.dart` | 75.0% | **86.2%** |
| `lib/menu.dart` | 69.0% | **86.0%** |
| `lib/form/shareform.dart` | 73.2% | **85.4%** |
| `lib/form/form.dart` | 65.4% | **82.7%** |
| `lib/form/phonePageform.dart` | 73.4% | **77.7%** |
| `lib/initialForm/form.dart` | 65.2% | **76.4%** |
| Global filtered coverage | 79.31% | **85.21%** |

### Production code changes

None. `git diff lib/` is empty. Round 5 is test-only.

### `skip: true` tests

No new skips. The 8 pre-existing skips (3 in `Journal_test.dart`, 5 in
`menu_test.dart`) remain untouched — they covered scenarios that are now
exercised by the new round-5 interaction tests via different (more
deterministic) paths, so the skipped tests are redundant but kept for
historical record.

### Still deferred (unchanged from round 4)

- **`lib/main.dart`** (1.7%). Bootstrap and route generation — integration-
  test territory.
- **`lib/pages/WellnessTools/player.dart`** (5.3%). `YoutubePlayerController`
  callbacks require a real platform view.
- **`lib/util/logger_service.dart`** (10.5%). `initializeSentry` calls
  `runApp` + `SentryFlutter.init` — requires a real Flutter binding.
- **`lib/AnalyticsService.dart`** (36.4%). `MixPanelService.init` gated on a
  non-empty `String.fromEnvironment` token which is empty under
  `flutter test`.
- **`lib/util/Firebase/firebase_functions.dart`** (68.0%, 612/900 covered).
  Round 1's Firebase batch + round 4's load-branches test cover the
  high-traffic paths; the remaining ~290 uncovered lines are mostly
  defensive/error branches in obscure read paths that are not worth
  enumerating without a redesign of the file (which would violate the
  no-production-changes rule).

### CI floor

Raised from 75% → **80%** in `scripts/check_coverage.dart`. Current 85.21%
leaves ~5 pts of headroom — enough to absorb test churn while continuing to
ratchet on every round.

## Pattern established for future contributors

1. **Real production widgets only.** Never duplicate a `lib/...dart` widget into `test/...dart` and test the duplicate. The pattern in `test/helpers/widget_test_scaffold.dart` is the only sanctioned shape: register fakes on GetIt, wrap in MultiProvider + MaterialApp + ScreenUtilInit.
2. **Service layer fakes over mocks.** Implement the abstract `PersistentMemoryService` / `IncidentLoggerService` / `AnalyticsService` interfaces with simple in-memory recorders rather than reach for Mockito for these.
3. **Inject Firestore.** When testing functions that call `FirebaseFirestore.instance`, add an optional `FirebaseFirestore? firestore` named param defaulting to `.instance`, then pass `FakeFirebaseFirestore()` from tests. Already done for 14 helpers in `firebase_functions.dart`.
4. **Mock platform channels** (path_provider, fluttertoast) via `setMockMethodCallHandler` only when unit-testing a function that touches the channel directly. For widget tests, prefer mocking the higher-level service.
5. **`flutter test --coverage` runs in CI** — write tests for new code as you write the code, the gate will fail otherwise.
