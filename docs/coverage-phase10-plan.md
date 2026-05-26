# Phase 10 Coverage Plan

Generated: 2026-05-24 — continuation of `docs/coverage-status.md` (Rounds 1–9)
and the ADR-001 / ADR-002 / ADR-003 / ADR-004 sequence.

This plan is anchored on the constraint **"macOS runners in GitHub Actions are
free for this project (open source)."** Phases 1–9 explicitly deferred iOS-
specific work because macOS minutes were assumed to be ~10× Linux cost; that
assumption no longer applies, which unblocks the largest remaining cluster of
deferred items. The app ships to **android, iOS, and web** — Phase 10 closes
the iOS and web gates that prior phases left open.

## Validation of the current state (vs `docs/coverage-status.md` § Round 9)

| Claim in coverage-status.md | Validated against repo |
|---|---|
| Unit global filtered coverage 89.29% | ✅ `scripts/check_coverage.dart` line 73: `_globalThreshold = 85.0` w/ "~89.3% as of round 9 (ADR-004)" comment |
| Aggregate floor 89% | ✅ `scripts/check_aggregate_coverage.dart` + `.github/workflows/main.yml` § coverage-aggregate |
| 3 CI gate jobs | ✅ `build-android` / `integration-test` / `coverage-aggregate` all wired in `main.yml` |
| 3 sanctioned `lib/` exceptions | ✅ firestore inject ×14 (R1), `@visibleForTesting resetForTest()` (R7), firestore inject ×29 (R9) |
| 8 pre-existing skips untouched | ✅ 3 in `test/Thanks/Journal_test.dart`, 5 in `test/menu_test.dart` |
| `tests/phase101-2026` is base for Phase 10 | ✅ branch at parity with `main@68108fa` |
| Local edit to `docs/coverage-status.md` | ⚠ Post-correction numbers polish in § Aggregate-floor derivation; bundle with Phase 10 commits |

**Real omission found:** the doc has zero discussion of **web-platform test
coverage**. `build-web` / `build-dev-web` jobs only build & deploy — they never
run `flutter test --platform chrome`. This is a genuine gate hole for a
multi-platform app.

## Remaining gap landscape (post Round 9)

| Item | Approx LF uncovered | Reachable by | ADR? | Phase 10 disposition |
|---|---|---|---|---|
| iOS-specific notification paths in `lib/pages/notifications/notification_service.dart` | ~30 | macOS-runner integration job | Yes — ADR-005 § A | **Phase 10A** |
| `main()` / `initializeApp()` / `callbackDispatcher` direct coverage in `lib/main.dart` | ~50 (foreground bootstrap only; background callbackDispatcher excluded) | Refactor → `bootstrapApp()` helper | Yes — ADR-005 § B (4th sanctioned production exception) | **Phase 10B** |
| Web-platform branches across `kIsWeb` guards (`main_menu_dialog.dart`, `file_service.dart`, etc.) | unknown (0–10 likely) | New `unit-test-web` job: `flutter test --platform chrome --coverage` | Yes — ADR-005 § C | **Phase 10C** |
| `lib/util/logger_service.dart` lines 17-18 (empty-DSN if-branch) | 2 | Dual-invocation pattern-2 of ADR-001 | No (low ROI) | **Decline** unless headroom shrinks |
| `lib/util/logger_service.dart` lines 29-31 (outer catch, swallowed by Sentry SDK) | 3 | Runtime-readable `_sentryDsn` (production change) | No (low ROI) | **Decline** |
| `callbackDispatcher` (Workmanager background entry-point), `lib/main.dart` lines 42-89 | ~45 | Patrol-style background harness | Yes — separate ADR, beyond coverage | **Hard skip** in Phase 10 |
| `lib/util/Firebase/firebase_functions.dart` `?? FirebaseFirestore.instance` fallback right-hand-sides | ~43 (1 line × 43 helpers) | Structurally unreachable under injection pattern | Yes — accept-as-dead or rewrite, separate ADR | **Hard skip** — accept as dead |

## Phase 10A — iOS notification paths via macOS runner (ADR-005 § A)

**Goal:** close the iOS-specific arms of
`lib/pages/notifications/notification_service.dart` that the
ADR-002 macOS-cost framing deferred.

**Workflow change:** add a fourth CI job `integration-test-ios` parallel to
`integration-test`:

- `runs-on: macos-14` (free for public/open-source repos under GitHub's
  current billing; verify on first run that the org is opted in).
- Boot an iOS Simulator via `xcrun simctl` rather than a third-party action —
  the macos-14 runner ships with Xcode 15+ and the iOS sim is pre-installed.
- Run `flutter test integration_test --coverage --coverage-path
  coverage/integration_ios.info -d "iPhone 15"` (or whatever sim name the
  `xcrun simctl list devices` step surfaces).
- Reuse the existing
  `--dart-define=SENTRY_DSN=https://test@dsn.example.local/0` from the
  Android job for symmetry.

**Test files:**

- `integration_test/notifications_schedule_ios_test.dart` — mirror of
  `notifications_schedule_test.dart` but exercises the **iOS-specific
  branches** that the Android job cannot reach:
  - `IOSFlutterLocalNotificationsPlugin.requestPermissions` happy path +
    denied path (the Android job uses the Android plugin variant).
  - `DarwinInitializationSettings` permission flags (`requestAlertPermission`,
    `requestBadgePermission`, `requestSoundPermission`).
  - The `Platform.isIOS` arm of `supportsReminderSettings()` (the Android job
    only hits the `Platform.isAndroid` arm).

**Gate:** new `scripts/check_ios_integration_coverage.dart` sibling of
`scripts/check_integration_coverage.dart`. Single per-file floor:
`lib/pages/notifications/notification_service.dart` ≥ 75% under the iOS
invocation alone (will exceed 95% post-merge with Android intg lcov).

**Aggregate-gate merge:** extend the coverage-aggregate job to download a
third artifact (`coverage-integration-ios-lcov`) and pass it as a third input
to `scripts/merge_lcov.dart`. The merge script already accepts N inputs.

**Expected lift:** `notification_service.dart` aggregate % 90.6% → ~98%;
~15 new raw lines into the aggregate denominator.

**Risk:** macOS-runner cold start ~3-4 min + iOS sim boot ~60-90s. Total job
time ≈ 6-8 min; acceptable. If it ever flakes, set `continue-on-error: true`
on the gate step and require the aggregate gate to pass — symmetric with the
existing Android emulator job's flake tolerance.

## Phase 10B — `bootstrapApp()` extraction for main.dart (ADR-005 § B)

**Goal:** close the foreground bootstrap of `lib/main.dart` — currently 1.7%
unit + 59.3% via integration `MyApp` widget = ~60% post-merge. Lines 104-156
(`main()` body + `initializeApp`) are unreachable because `Firebase.initializeApp`
in the test would need either secret-injected `firebase_options.dart` or a
fake Firebase app, and `main()` calls these directly.

**Production-code change — 4th sanctioned exception under the coverage
initiative:**

- Extract `Future<Widget> bootstrapApp({FirebaseApp? firebaseApp,
  WorkmanagerPlatform? workmanager, SentryService? sentryService, ...})`
  from the current `main()` body. The helper does **everything `main()` does
  except `runApp`** — that one line stays in `main()` so `bootstrapApp()` is
  callable from an integration test that uses its own pump.
- `main()` becomes a 2-line shim:
  ```dart
  Future<void> main() async {
    final app = await bootstrapApp();
    runApp(app);
  }
  ```
- Pattern is identical in shape to ADR-001's `firestore` named-param
  injection (R1) and ADR-004's extension of it (R9). Behaviour-preserving for
  production: every default value equals the current direct call.

**Test files:**

- `integration_test/bootstrap_full_test.dart` — calls
  `await bootstrapApp(firebaseApp: FakeFirebaseApp(), ...)` directly, asserts
  the returned widget tree is a `MultiProvider(... MyApp ...)`, then pumps
  through the integration_test binding to drive the same lifecycle paths the
  existing `bootstrap_smoke_test.dart` already covers — but **this time
  exercising the lines that build that widget tree, not just the tree
  itself**.

**Gate:** raise the per-file floor for `lib/main.dart` from "covered by
MyApp alone" to a new explicit floor of 65% in
`scripts/check_integration_coverage.dart`.

**Expected lift:** `main.dart` aggregate % ~60% → ~85%; +50 lines into the
aggregate denominator. `callbackDispatcher` (lines 42-89) stays uncovered —
that's a background Workmanager entry-point still blocked by the lack of a
background-task harness; explicitly out of Phase 10B scope.

**Risk:** the refactor must preserve the existing `main()` semantics line-
for-line for both Android release builds and web release builds. CI's
`build-android` + `build-web` jobs are the safety net — both build the
app from `main()` and surface any regression. Add a smoke `flutter analyze`
diff check to PR review.

## Phase 10C — Web platform test gate (ADR-005 § C)

**Goal:** close the gate hole — `build-web` and `build-dev-web` currently
build and deploy without any test step.

**Workflow change:** new CI job `unit-test-web`:

- `runs-on: ubuntu-latest` (Chrome headless is available on Linux runners; no
  macOS needed for this one).
- Steps: checkout → flutter setup (already cached from build-android) →
  `flutter pub get` → `flutter test --platform chrome --coverage`.
- `--platform chrome` runs the same `test/` suite under Chrome's `dart2js`
  compiler — surfaces any test that accidentally depends on `dart:io` or
  Android-specific plugin channel mocks.
- Upload `coverage/lcov.info` as `coverage-web-lcov` artifact (filename
  uniqueness avoids clobbering the unit job's `coverage-lcov`).

**Gate:** **don't gate strictly on the first run.** Web-platform test
execution will likely fail in some files that mock Android-specific plugin
channels (path_provider, workmanager). Land the job with
`continue-on-error: true` on the test step, surface the lcov as an artifact,
review the first run's failure modes in PR review, and ratchet the gate
once the suite is green under `--platform chrome`.

**Expected lift:** unknown — likely 0-10 new lines (web-specific `kIsWeb`
branches), but the **gate hole itself is the real motivation**.

**Aggregate-gate merge:** once green, add the web lcov as a fourth input to
`scripts/merge_lcov.dart` in the coverage-aggregate job.

## Phase 10D — logger_service.dart residual lines (optional, recommended **decline**)

5 lines total split across two structurally separate causes:

- Lines 17-18: empty-DSN if-branch, dead under CI's `--dart-define=SENTRY_DSN=...`.
  Fix would be dual-invocation pattern-2 of ADR-001 (one CI run with the
  define, one without) + lcov merge. ~3 min extra CI time for ~0.03 pt
  aggregate gain.
- Lines 29-31: outer catch branch, swallowed by `sentry_flutter` SDK internals.
  Fix would require either (a) a runtime-readable `_sentryDsn` (production
  change — would need a 5th ADR-005 sub-decision), or (b) a different
  exception-injection strategy.

**Recommendation: decline both in Phase 10.** Net aggregate impact ~0.07 pt;
both are documented as accepted risk in the Round 9 still-deferred table.
Revisit only if Phase 10A+B+C lift consumes the 3 pt headroom.

## Hard skips for Phase 10

These items are listed for completeness — they are **explicitly out of scope**
and should not be attempted in Phase 10:

- **`callbackDispatcher` (Workmanager background entry-point, lines 42-89 of
  `main.dart`).** Foreground integration tests cannot trigger a background
  `Workmanager().executeTask` callback. Needs Patrol's background task driver
  or a custom emulator harness — a separate ADR with motivation beyond
  coverage (e.g. "we need to confirm the periodic worker actually fires after
  reboot").
- **`firebase_functions.dart` `?? FirebaseFirestore.instance` fallback right-
  hand-sides (43 lines).** Structurally unreachable under the injection
  pattern. Accept as dead lines under the existing tier-1 50% floor (file is
  93.8%), or rewrite the helpers to not use the fallback shape — separate
  refactor ADR.

## Aggregate-floor target after Phase 10

| Step | Aggregate % | Floor proposal | Headroom |
|---|---|---|---|
| Round 9 (current) | 91.83% | 89% | 2.83 pt |
| + Phase 10A (iOS notifications, ~15 lines) | ~92.0% | 89% | 3.0 pt |
| + Phase 10B (bootstrapApp, ~50 lines) | ~92.8% | 90% | 2.8 pt |
| + Phase 10C (web, est 0-10 lines) | ~92.9% | 90% | 2.9 pt |

Floor ratchet recommendation: aggregate **89% → 90%**, applied once all
three sub-phases land and the first three CI runs confirm the aggregate %.

Per-tier and per-file floors in `scripts/check_coverage.dart` and
`scripts/check_integration_coverage.dart` are unchanged.

## Execution sequence

Three small PRs against `tests/phase101-2026`, matching the cadence of
phases 6→9 (one PR per ADR sub-decision):

1. **PR 10A — iOS notification paths**
   - `docs/adr/ADR-005-phase-10-macos-runner-ios-and-web-coverage.md` (§ A only initially)
   - `integration_test/notifications_schedule_ios_test.dart`
   - `scripts/check_ios_integration_coverage.dart`
   - `.github/workflows/main.yml` — new `integration-test-ios` job + aggregate merge update

2. **PR 10B — bootstrapApp extraction**
   - ADR-005 § B addendum
   - `lib/main.dart` — `bootstrapApp()` extraction (4th sanctioned exception)
   - `integration_test/bootstrap_full_test.dart`
   - `scripts/check_integration_coverage.dart` — `main.dart` per-file floor 65%

3. **PR 10C — web test gate**
   - ADR-005 § C addendum
   - `.github/workflows/main.yml` — new `unit-test-web` job (`continue-on-error: true` initially)
   - Triage report on first run's failures filed as follow-up issues

4. **Doc bundle commit** (in PR 10A or a precursor):
   - The currently-uncommitted `docs/coverage-status.md` edit (post-correction
     numbers polish in § Aggregate-floor derivation) goes with PR 10A.
   - Add a Round 10 section to `coverage-status.md` after each PR lands.

## Open questions before starting

1. Is the GitHub org opted into the open-source macOS-runner billing program?
   First Phase 10A run will surface a billing error if not — confirm before
   merging the new job.
2. Does `flutter test --platform chrome` work with the current Flutter 3.41.6
   pin given the project's dependency graph? Sanity-check by running locally
   once before opening PR 10C.
3. Is the `bootstrapApp()` extraction acceptable to reviewers as a fourth
   sanctioned production-code exception? ADR-005 § B must make the case
   explicitly — parallel to ADR-001's `firestore` precedent and ADR-002 PR
   #266's `resetForTest()`.

## Tooling reuse

- `scripts/_lcov_parser.dart` — already supports N-input merging via
  `parseLcovInputs`; no changes needed for Phase 10A or 10C.
- `scripts/merge_lcov.dart` — already accepts N positional args; coverage-
  aggregate job will pass 3 (or 4) artifacts instead of 2.
- `test/helpers/widget_test_scaffold.dart` — applies to integration tests
  unchanged. iOS-specific tests in 10A may need a `darwin_test_scaffold.dart`
  sibling if iOS-specific GetIt fakes diverge from the cross-platform ones;
  evaluate during PR 10A authoring.
- `qe-test-architect` (Agentic QE Fleet) — proven in Round 9 for pure-Dart
  unit tests against `FakeFirebaseFirestore`. Less obviously a fit for the
  integration-test files in 10A/10B (platform-channel mocking + binding
  setup is finicky) — author those by hand, reserve the agent for any
  pure-Dart helpers that come out of the bootstrap extraction.
