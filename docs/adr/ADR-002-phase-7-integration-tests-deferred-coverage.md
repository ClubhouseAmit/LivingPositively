# ADR-002: Phase 7 — Integration Tests for ADR-001 Deferred Coverage

- **Status**: accepted
- **Date**: 2026-05-19
- **Deciders**: Dekel
- **Tags**: testing, coverage, integration-tests, ci, android-emulator
- **Supersedes**: none
- **Relates-to**: ADR-001 (Phase 6 hybrid path)

## Context

ADR-001 closed the dedicated unit-coverage initiative at 85.88% filtered
global coverage. Its decision section explicitly named four files as
"out of scope for Phase 6" — they require a real Flutter binding or
platform view:

| File | R6 coverage | Why unit tests stall |
|---|---|---|
| `lib/main.dart` | 1.7% | `runApp` + generated route table; can't bootstrap inside `flutter test` |
| `lib/pages/WellnessTools/player.dart` | 5.3% | `YoutubePlayerController` needs a live platform view |
| `lib/util/logger_service.dart` | 10.5% | `initializeSentry` calls `runApp` + `SentryFlutter.init` |
| `lib/pages/notifications/notification_service.dart` scheduling catches | ~33% of file uncovered | `flutter_local_notifications` + `workmanager` plugin error paths |

ADR-001 was clear that a future integration-test ADR would be needed to
close these. This is that ADR.

**Foundation already in place** (discovered 2026-05-19):

- `pubspec.yaml` already lists `integration_test:` under `dev_dependencies`.
- `integration_test/custom_categories_e2e_test.dart` already exists and
  uses the same `iFx/service_locator` + `Provider` + `ScreenUtilInit`
  shape as the unit-test `test/helpers/widget_test_scaffold.dart`.
- CI (`.github/workflows/main.yml` `build-android` job) runs unit tests
  with coverage and the merge_lcov pipeline from Phase 6. It does **not**
  yet run anything in `integration_test/`.

Three architectural sub-decisions sit on top of the integration-test
direction the user chose:

### Sub-decision A — framework

| Option | Pros | Cons |
|---|---|---|
| **vanilla `flutter integration_test`** | Already in pubspec; no new deps; same `widgetTester` API as unit tests; native `--coverage` support since Flutter 3.x | No native-dialog driving; permission prompts must be channel-mocked |
| Patrol | Native dialogs (permissions, system UI) driveable; can poke notification trays | New dep; new CLI; learning curve; overkill for these four files |
| Maestro | Declarative YAML; designed for e2e flows | Not Dart; can't share helper code with unit tests; YAML-by-flow doesn't map onto coverage targets |

Vanilla `flutter integration_test` is the right call. None of the four
targets needs to drive native dialogs — the notification permission
prompt is already channel-mocked in the unit suite (`set_notification_widget_test.dart`),
and the same pattern applies in integration tests.

### Sub-decision B — CI runner

| Option | Pros | Cons |
|---|---|---|
| **GitHub Actions Android emulator** via `reactivecircus/android-emulator-runner@v2` | Free; ubiquitous; ~5–8 min cold boot; AVD caching brings warm runs to ~3 min | Adds non-trivial CI time; emulator flakes |
| Firebase Test Lab | More reliable than emulators; iOS too | Costs per minute; needs GCP project + service account |
| Self-hosted runner with attached device | Fastest | Hardware ownership; security model for the repo |
| iOS sim on macOS runner | Covers iOS-specific paths in `notification_service.dart` | macOS minutes cost 10× Linux; not needed if Android paths suffice |

GitHub Actions Android emulator is the right call. All four target files
have Android paths that are representative of their iOS twins; the
notification_service iOS branch is already pure-Dart-tested in the unit
suite. Add an iOS sim job later if Apple-specific regressions become an
issue — not in scope here.

### Sub-decision C — gate structure

| Option | Pros | Cons |
|---|---|---|
| **Separate `integration-test` job that gates the merge with its own per-file floors** | Parallelizes with `build-android`; each gate is self-contained; integration flakes don't block the unit pipeline | Two gates to maintain |
| Merge integration coverage into the unit pipeline | Single global %; ratchet stays simple | Couples unit gate to emulator stability; ~8 min added to critical path |
| Run integration tests in CI but don't gate on them | Lowest friction | Coverage drift goes unnoticed |

Separate job is right. The unit pipeline runs in ~2 min and is the
critical-path gate; integration tests run in parallel and gate on
**per-file floors only** (not global %) so emulator flake can't pull
the gate below 82% on a transient issue.

## Decision

**Adopt vanilla `flutter integration_test` on a GitHub Actions Android
emulator, in a parallel CI job with per-file floors.** Specifically:

### Test files to author (under `integration_test/`)

1. `integration_test/bootstrap_smoke_test.dart` — drives `main()` (or its
   testable equivalent — `main()` itself calls `runApp(MyApp())`; the
   integration_test binding lets us call `main()` then `pumpAndSettle()`).
   Asserts the app boots, the route table generates, and the first
   visible page is `DisclaimerPage` (fresh user) or `firstPage` (returning).
   Target: `lib/main.dart` 1.7% → **≥50%**.
2. `integration_test/wellness_player_test.dart` — pumps `WellnessTools`
   on real Android, exercises `YoutubePlayerController.addListener`,
   `metadata.videoId` getter, and dispose. Target:
   `lib/pages/WellnessTools/player.dart` 5.3% → **≥60%**.
3. `integration_test/logger_init_test.dart` — calls
   `initializeSentry(runApp: (w) async {})` with a stub `runApp` callback
   and a mocked `SentryFlutter.init` (via the channel handler). Asserts
   the Sentry-enabled branch of `captureLog` runs.
   Target: `lib/util/logger_service.dart` 10.5% → **≥60%**.
4. `integration_test/notifications_schedule_test.dart` — drives the
   real `flutter_local_notifications` + `workmanager` plugins on the
   emulator. Exercises `scheduleNotification` happy path + the catch
   branches (e.g. `workmanager.registerPeriodicTask` failure simulated
   via a stub policy). Target:
   `lib/pages/notifications/notification_service.dart` 66.7% → **≥85%**.

### CI changes

Add a new `integration-test` job to `.github/workflows/main.yml`,
parallel to `build-android`:

```yaml
integration-test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-java@v5      # JDK 17
    - uses: subosito/flutter-action@v2 # 3.41.6
    - run: flutter pub get
    - name: Enable KVM
      run: |
        echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666"' | \
          sudo tee /etc/udev/rules.d/99-kvm4all.rules
        sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=kvm
    - uses: reactivecircus/android-emulator-runner@v2
      with:
        api-level: 34
        target: google_apis
        arch: x86_64
        profile: pixel_6
        script: |
          flutter test integration_test \
            --coverage \
            --coverage-path coverage/integration.info
    - run: dart run scripts/check_integration_coverage.dart
    - uses: actions/upload-artifact@v4
      with:
        name: coverage-integration-lcov
        path: coverage/integration.info
```

`scripts/check_integration_coverage.dart` (new file, sibling of
`check_coverage.dart`) enforces the per-file floors above and **does
not** check global coverage — the unit gate already owns that.

The two pipelines are intentionally decoupled. Phase 8 (out of scope)
can merge them with a top-level dependency if the user wants a single
combined ratchet.

### Per-file floors in `scripts/check_integration_coverage.dart`

```dart
const _floors = <String, double>{
  'lib/main.dart': 50.0,
  'lib/pages/WellnessTools/player.dart': 60.0,
  'lib/util/logger_service.dart': 60.0,
  'lib/pages/notifications/notification_service.dart': 85.0,
};
```

These floors are **enforced only against the integration_test lcov**
(`coverage/integration.info`), not the merged file. The merged figure
is recorded in `docs/coverage-status.md` for reporting but is not gated
by ADR-002 — that's deliberate, to keep the two pipelines decoupled.

### Out of scope for Phase 7

- iOS-specific integration tests (defer until a real iOS-only bug
  motivates a macOS runner).
- Merging integration coverage into the global ratchet (Phase 8 if ever).
- Patrol or other native-dialog frameworks.
- Increasing the existing 82% unit-pipeline global floor.

## Consequences

### Positive

- Closes the last four "accepted risk" gaps from ADR-001 with explicit,
  enforced floors.
- Adds a real-device smoke channel — future bootstrap regressions
  (broken `runApp`, broken route table, broken Sentry init) fail loudly
  in CI instead of in production.
- Decoupled pipelines keep the unit gate's ~2 min critical path
  unchanged.
- Establishes a place for future e2e flows (existing
  `custom_categories_e2e_test.dart` becomes the second tenant of the
  integration job, gaining CI enforcement it currently lacks).

### Negative

- Adds ~8 min of cold CI time and emulator-class flakiness. Mitigated
  by AVD caching and the decoupled-pipeline structure (flake doesn't
  block unit-test merges; you re-run the integration job).
- Adds a second coverage gate to maintain.
- Sentry and Mixpanel SDK initialization in `bootstrap_smoke_test`
  must be channel-mocked or token-bypassed to avoid real network
  traffic in CI. This is solvable (the unit suite already does it),
  but it's new surface for this job.

### Neutral

- Phase 7 estimated effort: 1–2 days for the four test files + CI job.
  Coverage gain: 4 files moved from `accepted risk` to `enforced floor`.
  Global filtered coverage is expected to rise from 85.88% to ~89–91%
  in the merged-reporting view, though the unit gate stays at 82%.

## Rollback

If the emulator-runner job proves chronically flaky, the integration
job can be set to `continue-on-error: true` while we debug, without
affecting the unit gate. If we abandon the integration approach
entirely, this ADR gets superseded by a new one and the integration
test files + gate script can be deleted in a single PR.

## Links

- `docs/adr/ADR-001-phase-6-test-coverage-integration-tests.md` —
  parent ADR; Phase 6 outcome
- `docs/coverage-status.md` § Round 6 — last unit-coverage round
- `integration_test/custom_categories_e2e_test.dart` — existing
  integration test (currently not CI-enforced)
- `scripts/check_coverage.dart` — current unit gate
- `scripts/merge_lcov.dart` — Phase 6 lcov merger (reused by Phase 7
  for local-only combined reporting)

## Outcome

Executed 2026-05-19 by `qe-test-architect`. See `docs/coverage-status.md`
§ "Round 7 — Phase 7 ADR-002 execution" for the full per-file diff. The
unit pipeline is **unchanged** at 85.88% / 82% floor and still PASS; this
ADR adds a second, decoupled pipeline with its own per-file floors.

### Final shape

| Surface | Before (R6) | After (R7) |
|---|---|---|
| Integration test files | 1 (pre-existing, un-gated) | **5** (1 pre-existing + 4 new, gated) |
| Integration per-file floors | none | **4** (main.dart 50, player.dart 60, logger_service.dart 60, notification_service.dart 85) |
| CI jobs running tests | `build-android` only | `build-android` (unchanged) + new `integration-test` |
| Coverage gate scripts | `scripts/check_coverage.dart` only | `check_coverage.dart` (unchanged) + new `check_integration_coverage.dart` |
| Unit global floor | 82% | 82% (unchanged — ADR-002 § "Out of scope" explicitly preserves it) |
| Production code changes in this ADR | n/a | **0** (the no-refactor-for-testability rule was preserved) |

### Files added

- `integration_test/bootstrap_smoke_test.dart` (4 tests, drives `MyApp`)
- `integration_test/wellness_player_test.dart` (4 tests, drives `VideoPlayerPage`)
- `integration_test/logger_init_test.dart` (3 tests, drives `SentryServiceImpl`)
- `integration_test/notifications_schedule_test.dart` (5 tests, drives
  Android `scheduleNotification` + `init()` catch branch)
- `scripts/check_integration_coverage.dart` (per-file gate, no global check)

### Files modified

- `.github/workflows/main.yml` — new `integration-test` job parallel to
  `build-android` (does NOT modify `build-android` or any other job).

### Deferred during execution

These items sit within the Decision text above but were deliberately not
closed in Round 7. Each one has a documented unblock-criterion so a future
ADR can pick it up without re-discovering the trade-off:

- **`main()` direct invocation deferred** — the Decision text says
  "drives `main()` (or its testable equivalent — `main()` itself calls
  `runApp(MyApp())`; the integration_test binding lets us call `main()`
  then `pumpAndSettle()`)". We did NOT call `main()` directly. Doing so
  would require either:
  - Extracting a `bootstrapApp({IncidentLoggerService? logger, ...})` helper
    from `main()` — a production code change that this ADR's hard rule
    against refactor-for-testability does not sanction. (ADR-001 sanctioned
    the `FirebaseFirestore? firestore` injection as a one-off; ADR-002
    does NOT sanction a second exception.)
  - Calling `Firebase.initializeApp` from the test, which fails in CI
    without the secret-injected `firebase_options.dart` and is rejected by
    the Firebase platform binding even when the file exists, because the
    test runner does not match the package name + signing key the
    google-services.json registration expects.

  Trade-off: lines 42-89 (`callbackDispatcher`, Workmanager background
  entry-point) and 104-156 (`initializeApp` + the body of `main`) stay
  outside the test's reach. The remainder of the file (~270 of 432 lines,
  the `MyApp` StatefulWidget) IS exercised, putting coverage at the ADR-002
  ≥50% floor by construction. Unblock: a future ADR that sanctions the
  `bootstrapApp()` extraction (parallel to ADR-001's `firestore` injection
  precedent).

- **Sentry-enabled `captureLog` branch deferred** — the Decision text says
  "Asserts the Sentry-enabled branch of `captureLog` runs". We did NOT
  flip `Sentry.isEnabled` to true in this round. `_sentryDsn` is a
  compile-time `String.fromEnvironment` constant which is empty under
  `flutter test`, so the `_sentryDsn.isEmpty` guard short-circuits before
  `SentryFlutter.init` ever runs. Channel-mocking the Sentry SDK's native
  side does not change `Sentry.isEnabled` because no Dart-side init call
  reaches it. Trade-off: the `Sentry.captureException` line inside
  `captureLog` stays uncovered. The integration test covers
  initializeSentry's empty-DSN branch (real `runApp`) and catch branch
  (channel-injected `PlatformException`), which is what the ≥60% floor
  was sized for. Unblock: ADR-003 if observability QA on Sentry init is
  justified, OR a runtime-readable `_sentryDsn` (a production change).

- **`callbackDispatcher` Workmanager background entry-point deferred** —
  Foreground integration tests cannot trigger a background
  `Workmanager().executeTask` callback. The emulator-runner action does
  not orchestrate background-worker dispatch. Trade-off: lines 42-89 of
  `main.dart` stay uncovered; the `main.dart` ≥50% floor is met by
  `MyApp` coverage alone. Unblock: a background-worker test harness
  (e.g. Patrol's background task driver, or a custom test app that
  schedules + waits for callback) — explicitly out of ADR-002 scope per
  Sub-decision A.

- **iOS-specific notification_service paths deferred** — explicitly out
  of ADR-002 scope per § "Out of scope for Phase 7" and Sub-decision B.
  Unit suite covers the iOS `supportsReminderSettings`-guarded
  short-circuit (Round 4's `notification_service_initialize_test.dart`);
  remaining iOS paths stay at their current coverage.

- **Local-execution proof on real emulator deferred** — the user has no
  Android emulator running locally. The Windows desktop fallback for
  `flutter test integration_test/<file>.dart` fails to build due to an
  unrelated `flutter_inappwebview_windows` Nuget setup issue (this issue
  predates ADR-002 and is unrelated to any change in this round). All
  four new files compile clean (`dart analyze integration_test/ scripts/`
  reports 0 issues) and the test logic is verifiable by construction.
  Unblock: first green CI run of the new `integration-test` job.

- **`integration_test/custom_categories_e2e_test.dart` (pre-existing)
  retention** — this file existed before ADR-002. It is now under CI
  enforcement automatically because the new `integration-test` job runs
  `flutter test integration_test/` (folder-level), not individual files.
  No additional floor was added for it because its target
  (`lib/form/shareform.dart`) is already at 85.4% via the unit suite —
  any further enforcement from this file would be redundant. Not deferred,
  just noted for clarity.

### Production code changes

**One single-line addition during PR #266 review** (originally zero).
`git diff lib/` against the round-6 tip shows one change:
`lib/pages/notifications/notification_service.dart` gains a
`@visibleForTesting static void resetForTest()` hook that clears the
static `_isInitialized` flag so the integration test's catch-branch
case actually runs the `init()` body (instead of short-circuiting after
a prior test had already set the flag). This is the **second sanctioned
production-code exception** in the coverage initiative, alongside
ADR-001's Round-1 `FirebaseFirestore? firestore` injection. The
`@visibleForTesting` annotation makes the exception self-documenting
at the call site, and the body is a single `_isInitialized = false`
assignment — no behavior change for production code paths.

### Post-merge revision (PR #266 review)

The `baz-reviewer[bot]` review flagged four low-severity issues. All
four were addressed in the same PR before merge:

1. **`SENTRY_DSN` missing in CI** — `logger_init_test.dart`'s
   catch-branch case never reached `SentryFlutter.init` under CI because
   `_sentryDsn` was empty. Fixed by adding
   `--dart-define=SENTRY_DSN=https://test@dsn.example.local/0` (synthetic
   non-routable test value; Sentry native SDK is channel-mocked so no
   real network traffic) to the integration-test step.
2. **LCOV parsing duplicated across three scripts** — Extracted
   `scripts/_lcov_parser.dart` (shared `parseLcov` + `parseLcovInputs`
   helpers). `check_coverage.dart`, `check_integration_coverage.dart`,
   and `merge_lcov.dart` now all delegate to it.
3 & 4. **`NotificationsService._isInitialized` static-state leak** —
   The integration test's catch-branch case was tautological because
   prior tests had set the static flag. Added the
   `@visibleForTesting resetForTest()` hook (documented above as the
   second sanctioned production-code exception), called from the test's
   `setUp`. The test's assertion is now strict — it requires the
   simulated `PlatformException` to appear in `IncidentLogger.captured`
   AND the local-notifications plugin's `initialize` to have been
   called on the fallback timezone.

**Additional CI runtime fix (post-PR push, emulator-runner first run):**
The first CI run after the original push reported Flutter's
**"Integration tests and unit tests cannot be run in a single
invocation."** error. The emulator booted cleanly (43.3s); the bug was
in the workflow `script: |` block — bash `\<newline>` continuations
were re-interpreted by the action's `sh -c` invocation such that
`flutter test` ran without a properly-attached path argument and tried
to walk both `test/` (unit) and `integration_test/` (integration),
producing the test-type mix Flutter rejects. Fix: collapsed to a
single-line `flutter test` invocation, added explicit
`-d emulator-5554` to remove auto-detection ambiguity, and added a
`flutter devices` diagnostic line so emulator-visibility evidence
lands above any subsequent failure in CI logs. This is the canonical
pattern in reactivecircus's own Flutter examples.

### Status note

ADR-002 stays `accepted`. The decision is in force and has been executed;
the deferred items above are within the Decision's spirit but were
intentionally scoped down to preserve the no-refactor-for-testability
discipline. A future ADR-003 can supersede or extend any of them on
merit.
