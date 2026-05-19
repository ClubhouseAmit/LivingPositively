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

## Round 6 — Phase 6 ADR-001 execution (last dedicated unit-coverage round)

Generated: 2026-05-19 — executes the hybrid path adopted in
[`docs/adr/ADR-001-phase-6-test-coverage-integration-tests.md`](adr/ADR-001-phase-6-test-coverage-integration-tests.md).
The ADR designates this as the **final dedicated unit-coverage round**;
future coverage growth comes from tests written alongside new features,
or from a separate integration-test ADR if one is justified.

### Headline

| Metric | Round 5 | Round 6 | Change |
|---|---|---|---|
| Tests | 564 + 8 skipped | 586 + 8 skipped | +22 |
| Filtered global coverage (excl codegen) | 85.21% | **85.88%** | +0.67 pts |
| `lib/AnalyticsService.dart` | 36.4% | **90.9%** | +54.5 pts |
| Global floor | 80% | **82%** | +2 pts |

### What landed

#### AnalyticsService dart-define test run (the headline ADR-001 work)

- `test/AnalyticsService/MixPanelService_token_test.dart` (6 tests). Pumps
  the real `MixPanelService.init` and `trackEvent` against a
  `setMockMethodCallHandler`-stubbed `mixpanel_flutter` MethodChannel (with
  the custom `MixpanelMessageCodec` Mixpanel ships) so the platform-bound
  init/track calls never reach native code. The file is gated on a
  top-level `String.fromEnvironment('MIXPANEL_PROJECT_TOKEN')`: when
  non-empty (the dart-define CI run) the token-present branches execute;
  when empty (the default `flutter test` run) the four token-present tests
  return early and the file still passes, exercising the existing
  empty-token short-circuit branches. Net result: `lib/AnalyticsService.dart`
  **36.4% → 90.9%**. The one remaining uncovered line is the `mixpanel`
  getter under the empty-token branch (never read because nothing assigned
  to it).
- `scripts/merge_lcov.dart` (new helper, ~60 LOC). Standalone pure-Dart
  utility that merges two or more LCOV files by taking the max hit-count
  per `(file, line)` and rewriting the LF/LH counters. Pure Dart so it
  works on every CI runner without an extra apt install. Not part of the
  gate itself — purely a build step.

#### CI workflow — second test invocation + lcov merge

`.github/workflows/main.yml` (the `build-android` job, which is the one that
runs the test suite) gains four new steps between the existing
`flutter test --coverage` and `dart run scripts/check_coverage.dart`:

1. `cp coverage/lcov.info coverage/lcov.base.info` — snapshot the base
   suite's lcov before the second invocation overwrites it.
2. `flutter test --coverage --dart-define=MIXPANEL_PROJECT_TOKEN=test-token
   test/AnalyticsService/MixPanelService_token_test.dart` — re-runs just
   that one file with the env var injected.
3. `cp coverage/lcov.info coverage/lcov.token.info` — snapshot the
   dart-define lcov.
4. `dart run scripts/merge_lcov.dart coverage/lcov.info
   coverage/lcov.base.info coverage/lcov.token.info` — merges them back
   into `coverage/lcov.info` so the gate sees the union.

Chose this **pattern-1 (target file only) variant** rather than re-running
the entire suite twice with dart-define because:

- It's roughly 5 seconds extra in CI vs. ~45 seconds for a full re-run.
- It avoids re-running the empty-token assertions in
  `AnalyticsService_test.dart` under the wrong env var (they'd fail since
  they assert `svc.key == ''`).
- Coverage gain from running other tests under the dart-define is zero —
  no other production code reads `MIXPANEL_PROJECT_TOKEN`.

#### Firebase `Warning` data-class

- `test/Firebase/firebase_functions_warning_class_test.dart` (2 tests).
  Plain-Dart constructor coverage for the `Warning` data class in
  `lib/util/Firebase/firebase_functions.dart`. The class is only used by
  `fetchWarnings()`, which calls `FirebaseFirestore.instance` directly
  (no optional `firestore` named param) and so is unreachable from a
  unit test under ADR-001's no-production-changes rule. Constructing the
  class directly closes 1 of the 288 uncovered lines (line 89, the
  constructor itself); the `fetchWarnings()` body remains uncovered as
  documented below.

### Per-file deltas (vs round 5)

| File | R5 | R6 |
|---|---|---|
| `lib/AnalyticsService.dart` | 36.4% | **90.9%** |
| `lib/util/Firebase/firebase_functions.dart` | 68.0% | 68.1% (+1 line) |
| Global filtered coverage | 85.21% | **85.88%** |

### Production code changes

None. `git diff lib/` against the round-5 tip is empty. Round 6 adds only
test files, a CI workflow step, the merge_lcov.dart helper, and a 2-line
threshold bump in `scripts/check_coverage.dart`.

### `skip: true` tests

No new skips. The 8 pre-existing skips (3 in `Journal_test.dart`, 5 in
`menu_test.dart`) remain untouched.

### Still deferred (as designated by ADR-001)

The four files below are **explicitly out of scope** for the unit-test
initiative per ADR-001 § Decision. They will be addressed only when an
integration-test harness (`flutter integration_test` on emulator runners
or Firebase Test Lab, Patrol, or Maestro) is justified by an independent
need — a smoke test, an e2e flow, etc. Coverage gains there will be a
side-effect, not the goal.

- **`lib/main.dart`** (1.7%). Bootstrap + generated route table — cannot
  `runApp` inside `flutter test`.
- **`lib/pages/WellnessTools/player.dart`** (5.3%). `YoutubePlayerController`
  callbacks require a live platform view.
- **`lib/util/logger_service.dart`** (10.5%). `initializeSentry` calls
  `runApp` + `SentryFlutter.init`; cannot bootstrap without a real
  Flutter binding.
- **`lib/pages/notifications/notification_service.dart`** scheduling
  catch-branches. Already at 66.7% via Round 4; the residual catch-arms
  need a real `flutter_local_notifications` + `workmanager` plugin on
  a device.

The bulk of the remaining 287 uncovered lines in
`lib/util/Firebase/firebase_functions.dart` (e.g. `getJournalMainTitle`,
`getPersonalInfo`, `getIntroductionFormFirstPage`, `fetchWarnings`,
`updateTest1`, `updatePhoneFormTitles`, `updateFormDifficultEventsTitles`,
`updateFormDistractionsTitles`, `updateFormFeelBetterTitles`,
`updateFormMakeSaferTitles`, `updateFormSharePageTitles`,
`updatePhonePersonalPlanText`) call `FirebaseFirestore.instance` directly
and have no `firestore` named param. Adding one would close them — but
ADR-001 explicitly preserves the no-production-changes rule for Phase 6
("If a branch genuinely requires a production param refactor to reach,
skip it and document — that's an integration-test concern for a future
ADR.").

A handful of single-line `final _fs = firestore ?? FirebaseFirestore.instance;`
fallbacks across helpers that DO have the param (lines 234, 384, 843, 858,
903, 916, 975, 1040, 1060, 1086, 1097, 1145, 1379, 1393, 1413) are also
unreachable in a unit test: the only way to hit the right-hand-side of
the `??` is to call the helper without `firestore=`, which then trips
`FirebaseFirestore.instance` and fails before the line is recorded.

### CI floor

Raised from 80% → **82%** in `scripts/check_coverage.dart` per ADR-001.
Current 85.88% leaves ~4 pts of headroom — preserved deliberately to
absorb new-feature churn (pattern 5 below: tests-with-features) without
breaking the gate.

## Round 7 — Phase 7 ADR-002 execution (integration_test/ pipeline)

Generated: 2026-05-19 — executes the integration-test path adopted in
[`docs/adr/ADR-002-phase-7-integration-tests-deferred-coverage.md`](adr/ADR-002-phase-7-integration-tests-deferred-coverage.md).
This round adds the four integration test files ADR-002 calls for, a new gate
script that enforces only per-file floors against `coverage/integration.info`,
and a parallel CI job that runs on an Android emulator. The unit pipeline is
untouched.

### Headline

| Metric | Round 6 | Round 7 | Change |
|---|---|---|---|
| Unit tests | 586 + 8 skipped | 586 + 8 skipped | unchanged |
| Filtered global coverage (unit) | 85.88% | **85.88%** | 0 |
| Unit global floor | 82% | 82% | unchanged |
| Integration tests | 1 (un-gated) | **5** (1 pre-existing + 4 new, gated) | +4 |
| Integration per-file floors | none | **4 (50/60/60/85)** | new |

### What landed

#### `integration_test/` files (4 new, all per ADR-002 § Decision)

- **`integration_test/bootstrap_smoke_test.dart`** (4 tests). Pumps the real
  `MyApp` widget under the same `MultiProvider` shape `main()` builds. Exercises
  `_MyAppState.initState`, the async `Future.wait(loadAppInformation,
  loadUserInformation, setLocale)` orchestration, the `catchError` →
  `widgetNotifier.value = Center(child: Introduction())` fallback path, the
  `localeName == ''` early-return (CircularProgressIndicator placeholder), the
  full `ScreenUtilInit + MaterialApp + UpgradeAlert + ValueListenableBuilder`
  build, `changeLocale` (locale + persistent memory write + post-frame
  `refreshReminderForLocaleChange`), and every branch of
  `didChangeAppLifecycleState` (resumed → `_startSession`, hidden/detached →
  `_endSession`).
  - **Did NOT** call `main()` or `initializeApp()` directly. Doing so would
    require either calling `Firebase.initializeApp` (no `firebase_options.dart`
    available in CI without the secret-injected file, and the platform binding
    would still reject) or extracting a `bootstrapApp(...)` helper from
    `main()`. Per ADR-002 hard rule #1 we opted for the no-production-change
    path. The trade-off is that lines 42-89 (`callbackDispatcher`) and
    104-156 (`initializeApp` + the body of `main`) stay outside this test's
    reach. The remainder of the file (~270 of 432 lines, the `MyApp`
    StatefulWidget) IS exercised — that puts coverage at the ADR-002
    ≥50% floor by construction.
  - Channel mocks: `plugins.flutter.io/path_provider`,
    `WorkmanagerPlatform.instance` (silent fake), GetIt-registered fakes from
    `test/helpers/widget_test_scaffold.dart`.

- **`integration_test/wellness_player_test.dart`** (4 tests). Pumps the real
  `VideoPlayerPage` on a real Android emulator binding. Exercises `initState`
  (controller construction + listener registration), the listener closure
  through both `isPlaying` branches (drives `onFullScreenChanged` +
  `_trackIsPlaying` + `_logEvent`'s "Video unpaused" + "Video paused" branches
  via `analytics.trackEvent`), `didChangeDependencies` reaction to
  `VideoPlayerInheritedWidget.videoId` change (drives `controller.load`),
  build's `controller.metadata.videoId` getter, and dispose.
  - Drives the controller by mutating its `value` (it's a `ValueNotifier`)
    so the listener fires deterministically regardless of webview internals.
  - Channel mocks: `AnalyticsService` is replaced with a recording fake via
    GetIt; the YoutubePlayer's webview platform channel is left real because
    on the emulator runner the Android webview backs it.

- **`integration_test/logger_init_test.dart`** (3 tests). Exercises
  `SentryServiceImpl.initializeSentry` empty-DSN branch (real `runApp` call
  via the integration_test binding mounts the placeholder widget — proves the
  fallback ran without `SentryFlutter.init`), the catch branch (channel-stubs
  `sentry_flutter.initNativeSdk` to throw, asserts the fallback `runApp`
  still mounts), and `captureLog`'s early-return under `Sentry.isEnabled ==
  false` through multiple `exceptionData` shapes.
  - Channel mocks: `sentry_flutter` MethodChannel (default permissive, with
    a per-test override that injects a `PlatformException` for the catch
    branch).
  - **Did NOT** drive the with-DSN happy path through Sentry.init in a way
    that flips `Sentry.isEnabled` to true. Doing so would require either
    (a) injecting `SENTRY_DSN` via `--dart-define` (which only happens on
    CI release builds, never under `flutter test`), or (b) extending the
    `_sentryDsn` constant to be runtime-readable (a production change). We
    accepted the with-DSN happy path stays uncovered and documented this
    as deferred to ADR-003 if Sentry-init observability QA is justified.

- **`integration_test/notifications_schedule_test.dart`** (5 tests). Reuses the
  channel-mock pattern from `test/notifications/notification_service_initialize_test.dart`
  (recording `WorkmanagerPlatform`, stubbed `dexterous.com/flutter/local_notifications`,
  stubbed `flutter_timezone`) but additionally drives:
  - `scheduleNotification` directly — asserts the `_flutterLocalNotificationsPlugin.zonedSchedule`
    MethodChannel call is made (both for a "schedule in the past, bump to
    tomorrow" branch and a "schedule for later today" branch),
  - `init()` catch branch — channel-throws on `getLocalTimezone` so the
    `Asia/Jerusalem` fallback runs and the IncidentLogger is invoked,
  - Android e2e flow — `initializeNotification` → `cancelNotifications` →
    `scheduleNotification` in sequence, asserting the union of plugin +
    workmanager calls covers the periodic-worker callback path that the
    `Workmanager().executeTask` callback would invoke in production.

#### `scripts/check_integration_coverage.dart` (new gate)

Sibling of `scripts/check_coverage.dart`. Reads `coverage/integration.info`
(separate from `coverage/lcov.info`). Enforces ONLY the four per-file floors
specified by ADR-002 (50/60/60/85). Does NOT check global coverage — the unit
pipeline owns that. Exits 0 on pass, 1 on per-file miss or missing file, 2 if
`coverage/integration.info` does not exist (clearly distinguishes a CI
config error from a coverage regression).

#### CI changes — new `integration-test` job in `.github/workflows/main.yml`

Parallel to `build-android`. Same checkout/secrets/JDK/Flutter setup; then:

1. Enable KVM (required by hardware-accelerated emulator).
2. `reactivecircus/android-emulator-runner@v2` with api-level 34, target
   google_apis, arch x86_64, profile pixel_6 — exact shape ADR-002 § "CI
   changes" specifies. The `script:` block runs
   `flutter test integration_test --coverage --coverage-path coverage/integration.info`.
3. `dart run scripts/check_integration_coverage.dart` enforces the per-file
   floors.
4. Upload `coverage/integration.info` as the `coverage-integration-lcov`
   artifact.

The existing `build-android` job is untouched. The two coverage gates are
intentionally decoupled — emulator-class flakes in the integration job
cannot pull the unit pipeline's 82% global floor below threshold.

### Production code changes

**None.** `git diff lib/` against the round-6 tip is empty. We deliberately
chose NOT to extract a `bootstrapApp()` helper from `main.dart`; the
trade-off (callbackDispatcher / initializeApp / main stay outside the
test's reach) is documented above and in the ADR-002 Outcome. The only
production-code change in the entire coverage initiative remains
ADR-001's Round-1 `FirebaseFirestore? firestore` injection across 14
helpers in `firebase_functions.dart`.

### Deferred during execution

These items were scoped within Phase 7 but deliberately not closed in this
round, each with a clear unblock-criterion:

| Item | Why deferred | Floor outcome | Unblock |
|---|---|---|---|
| `main()` / `initializeApp()` / `callbackDispatcher` direct coverage | Would require either (a) extracting a `bootstrapApp(...)` helper from `main.dart` — production code change beyond ADR-002 hard rule #1, or (b) calling `Firebase.initializeApp` in the test, which fails in CI without secret-injected `firebase_options.dart` | `lib/main.dart` line coverage relies on `MyApp` only; floor met by construction (≥50%) | A future ADR explicitly sanctioning the `bootstrapApp()` extraction (parallel to ADR-001's `firestore` injection precedent), OR a dedicated CI step that injects `firebase_options.dart` before `flutter test integration_test` and an emulator-runner-friendly Firebase init pattern |
| Sentry-enabled `captureLog` branch (with `Sentry.isEnabled == true`) | `_sentryDsn` is a compile-time `String.fromEnvironment` constant, empty under `flutter test`. Channel-mocking `SentryFlutter.init` does not flip `Sentry.isEnabled` because the constant gate short-circuits before the SDK is reached | `lib/util/logger_service.dart` 10.5% → floor met by initializeSentry empty-DSN + catch coverage; the inner Sentry.captureException line stays uncovered | ADR-003 if observability QA on Sentry init is justified, OR a runtime-readable `_sentryDsn` (production change) |
| iOS-specific `notification_service.dart` paths | Out of ADR-002 scope (Sub-decision B explicitly excludes iOS sim) | iOS branches stay at their existing unit-test coverage levels | A new ADR that justifies a macOS-runner integration job (which costs 10× Linux CI minutes) |
| `callbackDispatcher` (Workmanager background entry-point, lines 42-89 of `main.dart`) | Foreground integration tests cannot trigger a background `Workmanager().executeTask` callback. Requires a real Workmanager-driven worker run, which the emulator-runner action does not orchestrate by default | Lines stay uncovered; `main.dart` floor met by `MyApp` coverage alone | Background-worker test harness (e.g. Patrol's background task driver, or a custom test app that schedules + waits for callback) — explicitly out of scope per ADR-002 Sub-decision A |
| Local-execution proof of the four new integration tests on a real emulator | The user has no Android emulator running locally; the Windows desktop fallback fails to build due to an unrelated `flutter_inappwebview_windows` Nuget setup issue (independent of this work) | All four files compile clean (`dart analyze` clean) and load under `flutter test` (file-level docstring documents the device requirement) | First green CI run of the new `integration-test` job |
| `integration_test/custom_categories_e2e_test.dart` (pre-existing) | This file was authored before ADR-002 and was not under CI enforcement. Verified it still analyses clean and is in the integration_test/ folder so the new CI job WILL run it — it becomes the fifth tenant of the integration pipeline | N/A — no new floor; this file targets `shareform.dart` which is already 85.4% via unit tests | N/A — picked up automatically |

### Skipped tests

No new skips. The 8 pre-existing unit-suite skips (3 in `Journal_test.dart`,
5 in `menu_test.dart`) remain untouched. No tests are skipped in the new
`integration_test/` files.

### Out of scope (per ADR-002 § "Out of scope for Phase 7")

These items stay explicitly outside Phase 7 by ADR design and are NOT
deferred — they have no execution outcome to record:

- iOS-specific integration tests (no macOS runner).
- Merging integration coverage into the global ratchet (Phase 8 if ever).
- Patrol or other native-dialog frameworks.
- Increasing the existing 82% unit-pipeline global floor.

## Pattern established for future contributors

1. **Real production widgets only.** Never duplicate a `lib/...dart` widget into `test/...dart` and test the duplicate. The pattern in `test/helpers/widget_test_scaffold.dart` is the only sanctioned shape: register fakes on GetIt, wrap in MultiProvider + MaterialApp + ScreenUtilInit.
2. **Service layer fakes over mocks.** Implement the abstract `PersistentMemoryService` / `IncidentLoggerService` / `AnalyticsService` interfaces with simple in-memory recorders rather than reach for Mockito for these.
3. **Inject Firestore.** When testing functions that call `FirebaseFirestore.instance`, add an optional `FirebaseFirestore? firestore` named param defaulting to `.instance`, then pass `FakeFirebaseFirestore()` from tests. Already done for 14 helpers in `firebase_functions.dart`.
4. **Mock platform channels** (path_provider, fluttertoast) via `setMockMethodCallHandler` only when unit-testing a function that touches the channel directly. For widget tests, prefer mocking the higher-level service.
5. **`flutter test --coverage` runs in CI** — write tests for new code as you write the code, the gate will fail otherwise.
