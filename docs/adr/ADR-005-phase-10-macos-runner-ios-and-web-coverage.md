# ADR-005: Phase 10 — macOS-runner iOS coverage, `bootstrapApp()` extraction, and web test gate

- **Status**: accepted
- **Date**: 2026-05-25
- **Deciders**:
- **Tags**: coverage, ci, ios, web, refactor

## Context

The Mazilon coverage initiative reached 89.29% unit / ~91.83% aggregate after
Round 9 (see `docs/coverage-status.md` § Round 9 and ADR-004). The
still-deferred table in Round 9 lists six items; three of them share a single
root cause that this ADR addresses, and one new gap was identified during the
Phase 10 plan validation that the prior ADRs never covered.

### The macOS-runner cost framing changed

ADR-002 § "Out of scope for Phase 7" and Round 9 § "Still deferred" both
explicitly excluded iOS-specific notification paths on the grounds that
"macOS runner costs 10× Linux CI minutes; no iOS-specific bug has motivated
it." That framing was correct under GitHub Actions' standard billing.

The project is **open-source** and the GitHub org is (or can be) opted into
the free macOS runner allotment for public repositories. Under that billing,
the 10× cost framing no longer applies, which unblocks the iOS deferred
items at zero ongoing cost. This ADR ratifies that change in framing and
plans the work it enables.

### `main.dart` bootstrap is still uncovered

`lib/main.dart` reached ~59.3% in Round 7 via the `bootstrap_smoke_test.dart`
integration test that pumps the `MyApp` widget directly. Lines 104-156
(`main()` body + `initializeApp` + the synchronous `Firebase.initializeApp`
call before `runApp`) remained uncovered because Round 7 deliberately did
not extract a `bootstrapApp()` helper — ADR-002 hard rule #1 ("no production
code changes") prohibited it without a new ADR.

### Web ships to production with zero test gate

`build-web` and `build-dev-web` jobs in `.github/workflows/main.yml` build
and deploy the web target to Azure Storage on every push, but neither job
runs `flutter test --platform chrome` or any other web-specific test step.
This means a web-only regression (a `dart:html` vs `dart:io` divergence, a
`kIsWeb` branch bug, a web-incompatible plugin call) ships to production
without any CI signal. None of ADR-001 through ADR-004 noticed this gap;
it surfaced during the Phase 10 plan validation against the workflow file.

### What this ADR does **not** address

- **`callbackDispatcher` (Workmanager background entry-point, `main.dart`
  lines 42-89).** Foreground integration tests cannot trigger a background
  `Workmanager().executeTask` callback. Requires Patrol's background task
  driver or a custom harness — out of scope, will need a separate ADR with
  motivation beyond coverage (e.g. "we need to confirm the periodic worker
  actually fires after reboot").
- **`firebase_functions.dart` `?? FirebaseFirestore.instance` fallback
  right-hand-sides (43 lines).** Structurally unreachable under the
  injection pattern from ADR-001 / ADR-004. Accept as dead lines under the
  existing tier-1 50% floor (file is at 93.8%) or rewrite the helpers to
  not use the fallback shape — separate refactor ADR.
- **`logger_service.dart` lines 17-18 (empty-DSN if-branch) and 29-31
  (outer catch swallowed by Sentry SDK).** ~5 lines, ~0.07 pt aggregate
  impact. Documented as accepted risk; revisit only if Phase 10 lift
  consumes the 3 pt headroom.

## Decision

Execute Phase 10 as **three sub-decisions, one per PR**, each ratchetting
the aggregate floor by ≤1 pt:

### Sub-decision A — iOS notification paths via macOS-14 runner

Add a fourth CI job `integration-test-ios` parallel to the existing
`integration-test` job:

- `runs-on: macos-14` (free for public repos under GitHub's open-source
  macOS runner allotment; first job run must confirm the org is opted in
  before the gate is treated as required).
- Boot an iOS Simulator via `xcrun simctl` (macos-14 ships with Xcode +
  iOS Simulator pre-installed; no third-party action needed).
- Run `flutter test integration_test --coverage --coverage-path
  coverage/integration_ios.info -d "iPhone 15"
  --dart-define=SENTRY_DSN=https://test@dsn.example.local/0`.
- New test file `integration_test/notifications_schedule_ios_test.dart`
  mirrors the existing Android `notifications_schedule_test.dart` but
  exercises **iOS-specific branches** in
  `lib/pages/notifications/notification_service.dart`:
  `IOSFlutterLocalNotificationsPlugin.requestPermissions` happy + denied
  paths, `DarwinInitializationSettings` permission flags, and the
  `Platform.isIOS` arm of `supportsReminderSettings()`.
- New gate script `scripts/check_ios_integration_coverage.dart` enforces
  a single per-file floor:
  `lib/pages/notifications/notification_service.dart` ≥ 75% under the iOS
  invocation alone (will exceed 95% post-aggregate-merge with Android intg).
- Aggregate-gate merge updated to accept a third lcov input
  (`coverage-integration-ios-lcov` artifact). `scripts/merge_lcov.dart`
  already accepts N positional args.

**No production-code change.** The iOS plugin paths are reached purely by
test code; channel mocks follow the same shape as
`test/notifications/notification_service_initialize_test.dart`.

### Sub-decision B — `bootstrapApp()` extraction (4th sanctioned production exception)

Extract `Future<Widget> bootstrapApp({FirebaseApp? firebaseApp,
WorkmanagerPlatform? workmanager, SentryService? sentryService, ...})` from
the current `main()` body. The helper does **everything `main()` does except
`runApp`**. `main()` becomes a 2-line shim:

```dart
Future<void> main() async {
  final app = await bootstrapApp();
  runApp(app);
}
```

This is the **fourth sanctioned production-code exception** to the coverage
initiative's no-production-changes guard rail, alongside:

1. ADR-001 Round 1 — `firestore` named-param injection on 14 helpers in
   `firebase_functions.dart`.
2. ADR-002 PR #266 — `@visibleForTesting NotificationsService.resetForTest()`.
3. ADR-004 Round 9 — `firestore` named-param injection extended to 29 more
   helpers in `firebase_functions.dart`.

All four share the same shape: **narrow, mechanical, behaviour-preserving for
production paths, necessary to reach a genuinely-unreachable test seam**.

Test file `integration_test/bootstrap_full_test.dart` calls `bootstrapApp(...)`
directly with fakes for the injectable parameters, asserts the returned
widget tree, then pumps through the integration_test binding to drive
lifecycle paths the existing `bootstrap_smoke_test.dart` only reached via
the already-built `MyApp` instance.

`scripts/check_integration_coverage.dart` gains a new per-file floor of 65%
for `lib/main.dart`. `callbackDispatcher` (lines 42-89) stays uncovered —
explicitly out of Phase 10B scope per § Context.

### Sub-decision C — Web platform test gate

Add a new CI job `unit-test-web`:

- `runs-on: ubuntu-latest` (Chrome headless is available on Linux runners;
  no macOS needed for this sub-decision).
- Steps: checkout → flutter setup → `flutter pub get` →
  `flutter test --platform chrome --coverage`.
- Upload coverage as `coverage-web-lcov` artifact (distinct filename — does
  NOT clobber the Android unit job's `coverage-lcov`).

**Initial landing posture: `continue-on-error: true` on the test step.**
Web-platform test execution will almost certainly fail in some files that
mock Android-specific plugin channels (path_provider, workmanager). The
first run's failure modes are triaged in PR review and filed as follow-up
issues; once the suite is green under `--platform chrome`, flip the gate
to strict and add the web lcov as a fourth input to
`scripts/merge_lcov.dart` in the coverage-aggregate job.

**No production-code change** unless triage uncovers an actual web bug —
in which case the bug fix lands in its own PR, not as part of this ADR.

### Aggregate floor ratchet

| Step | Aggregate % (est) | Floor | Headroom |
|---|---|---|---|
| Round 9 baseline | 91.83% | 89% | 2.83 pt |
| + Phase 10A (iOS notif, ~15 lines) | ~92.0% | 89% | 3.0 pt |
| + Phase 10B (bootstrapApp, ~50 lines) | ~92.8% | **90%** | 2.8 pt |
| + Phase 10C (web gate, est 0-10 lines) | ~92.9% | 90% | 2.9 pt |

Aggregate floor ratchets from **89% → 90%** when Sub-decision B lands and
the first three CI runs confirm the aggregate %. Per-tier and per-file
floors in `scripts/check_coverage.dart` are unchanged.

## Consequences

### Positive

- iOS-specific notification paths gain CI coverage for the first time —
  closes the largest remaining cluster of deferred items from ADR-002 / ADR-004.
- `main.dart` foreground bootstrap (currently ~60%) lifts to ~85% — closes
  the largest deferred unit-side item left after Round 9.
- Web target gains a CI test gate — closes a real production-risk gap that
  prior ADRs missed.
- All three sub-decisions follow established ADR-001 / ADR-002 patterns:
  narrow production exceptions, per-file floor scripts, aggregate-gate
  merge. No new infrastructure invented.
- Open-source macOS runner billing is a permanent constraint shift, not a
  one-off — future iOS-specific work (e.g. iOS-specific UI tests, iOS
  share extension) can build on the Phase 10A runner setup.

### Negative

- macOS-14 runner cold start ~3-4 min + iOS sim boot ~60-90s pushes
  Phase 10A's job time to ~6-8 min. The aggregate-coverage job blocks on
  it, lengthening the critical path of a PR's CI to ~10-12 min.
- `bootstrapApp()` extraction is the fourth production-code exception in
  a coverage-driven initiative; each exception slightly weakens the
  "no-production-changes" guard rail. The mitigation (narrow, mechanical,
  behaviour-preserving, ADR-sanctioned) is the same pattern as the prior
  three, but reviewers may push back on the cumulative drift. The
  alternative — leaving `main.dart` at ~60% forever — was judged worse.
- Web test job initial landing with `continue-on-error: true` is a known
  CI smell: a gate that doesn't gate. Mitigated by the explicit triage
  step in PR review and the commitment to flip strict once the suite is
  green. Risk: that flip never happens if no-one prioritizes the triage.

### Neutral

- The coverage-aggregate job's merge now handles 3 (and eventually 4)
  lcov inputs instead of 2. `scripts/merge_lcov.dart` already supports
  this; no script changes needed for the merge itself.
- The three sub-decisions can land in any order; recommended sequence
  (10A → 10B → 10C) is by ROI, not technical dependency.
- macOS-runner billing opt-in status is checked at first job run, not
  at ADR-acceptance time. If the org is not opted in, Phase 10A is
  blocked at PR-CI level and the ADR will be marked superseded / on hold
  until billing is resolved.

## Links

- `docs/coverage-status.md` — Round 9 § "Still deferred" lists the items
  Phase 10 closes.
- `docs/coverage-phase10-plan.md` — full Phase 10 plan, including
  validation against repo state, three PR sequence, tooling reuse notes,
  and open questions.
- `docs/adr/ADR-001-phase-6-test-coverage-integration-tests.md` —
  established the `firestore` injection pattern that ADR-005 § B mirrors
  for `bootstrapApp()`.
- `docs/adr/ADR-002-phase-7-integration-tests-deferred-coverage.md` —
  established the per-file gate script pattern that ADR-005 § A reuses
  for iOS.
- `docs/adr/ADR-003-phase-8-aggregate-coverage-gate.md` — established
  the aggregate-gate merge pattern that ADR-005 extends to 3-4 inputs.
- `docs/adr/ADR-004-phase-9-firestore-injection-extension-firebase-functions.md`
  — most recent precedent for a production-code exception, parallel in
  shape to ADR-005 § B.
