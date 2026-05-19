# ADR-001: Phase 6 Test Coverage — Adopt Integration Tests for Platform-Bound Code

- **Status**: accepted
- **Date**: 2026-05-19
- **Deciders**: Dekel
- **Tags**: testing, coverage, integration-tests, ci

## Context

Rounds 1–5 of the test-coverage initiative (see `docs/coverage-status.md`)
moved filtered global line coverage from 27.6% → **85.21%** entirely within
the `flutter test` unit suite, holding two non-negotiable rules:

1. Real production widgets only — no stub duplication.
2. Zero production code changes for testability (one exception: the
   `FirebaseFirestore? firestore` named param landed in Round 1 across 14
   helpers in `firebase_functions.dart`).

The remaining uncovered surface in `lib/` is now structurally different
from what rounds 1–5 closed. The Round 5 retro lists it explicitly:

| File | Coverage | Reason it stalled |
|---|---|---|
| `lib/main.dart` | 1.7% | `runApp` + generated route table; can't bootstrap inside `flutter test` |
| `lib/pages/WellnessTools/player.dart` | 5.3% | `YoutubePlayerController` callbacks need a live platform view |
| `lib/util/logger_service.dart` | 10.5% | `initializeSentry` calls `runApp` + `SentryFlutter.init` — needs real Flutter binding |
| `lib/AnalyticsService.dart` | 36.4% | `MixPanelService.init` body gated on non-empty `String.fromEnvironment('MIXPANEL_PROJECT_TOKEN')` (empty under `flutter test`) |
| `lib/pages/notifications/notification_service.dart` | 66.7% | Remaining `scheduleNotification` catch-branches need real `flutter_local_notifications` + `workmanager` plugins on a device |
| `lib/util/Firebase/firebase_functions.dart` | 68.0% | Defensive/error branches in obscure read paths; pushing higher needs a refactor that violates rule 2 |

The CI gate (`scripts/check_coverage.dart`) sits at **80% global floor** and
**85.21% actual**. Returns from another unit-test round are diminishing —
each additional point of coverage now costs more test infrastructure than
the previous one, and the patterns established in rounds 1–5 do not apply
to platform-bound code paths.

Three Phase 6 paths are viable:

1. **Adopt `flutter integration_test`** for the four "integration-test
   territory" files (`main.dart`, `player.dart`, `logger_service.dart`,
   `notification_service.dart` catch-branches). Requires new CI
   infrastructure (Android/iOS emulator runners or Firebase Test Lab) and
   a separate coverage stream that the gate would need to merge.
2. **Accept the 85% plateau** as the unit-test ceiling and reframe the
   remaining gap as known/accepted risk documented in this ADR. Treat
   future coverage growth as a side-effect of new feature tests, not a
   dedicated initiative.
3. **Hybrid**: pick one of the four files (`AnalyticsService.dart` is the
   cheapest — its gap is a build-time string constant, not a real platform
   dep) and add a `--dart-define=MIXPANEL_PROJECT_TOKEN=test-token` CI test
   variant. Defer the rest to integration tests when CI infra is ready.

## Decision

**Adopt option 3 — the hybrid path — for Phase 6.** Specifically:

- Add a single new test run in CI with `--dart-define=MIXPANEL_PROJECT_TOKEN=test-token`
  that exercises `MixPanelService.init` and the post-init `trackEvent`
  branches. Use the same `qe-test-architect` agent and the established
  `test/helpers/widget_test_scaffold.dart` pattern.
- Author a `test/AnalyticsService/MixPanelService_token_test.dart` that
  asserts the init body runs and `trackEvent` no-throws when the token is
  present. Expected delta: `AnalyticsService.dart` 36.4% → ~85%.
- Add `firebase_functions.dart` defensive-branch tests opportunistically:
  the round-5 retro flagged ~290 uncovered lines, but a meaningful subset
  is reachable via `FakeFirebaseFirestore` doc-shape edge cases the
  Round 4 `firebase_functions_load_firebase_branches_test.dart` did not
  enumerate. Target: 68.0% → ~80%.
  - **Revised during execution (2026-05-19):** This target was abandoned.
    Inspection showed the remaining ~287 uncovered lines call
    `FirebaseFirestore.instance` directly with no `firestore` named param,
    so reaching them requires extending the Round-1 injection refactor to
    ~30 more helpers — a production-code change ruled out by the no-
    refactor-for-testability rule re-affirmed elsewhere in this ADR. Only
    the `Warning` data-class constructor was covered (the one cheap
    in-scope target). The 68.0% figure is therefore the accepted plateau
    for `firebase_functions.dart` under ADR-001's rules; see Outcome below
    and `docs/coverage-status.md` § Round 6 for the recorded reasoning.
- For `main.dart`, `player.dart`, `logger_service.dart`, and the residual
  `notification_service.dart` scheduling catch-branches: **do not chase
  them in Phase 6**. They are explicitly out of scope. They will be
  addressed only when an integration-test harness (Patrol, Maestro, or
  vanilla `flutter integration_test` on Firebase Test Lab) is justified
  by an independent need — e.g., adding a smoke test that boots the app
  on a real device. Coverage gains there will be a side-effect, not the
  goal.
- Raise the CI floor to **82%** after Phase 6 lands. The 3-point cushion
  preserves room for new-feature churn.

Phase 6 is therefore the last dedicated unit-coverage round. Future
coverage discipline shifts to "write tests for new code as you write the
code" (per pattern 5 in `coverage-status.md`).

## Consequences

### Positive

- Closes the cheapest remaining unit-testable gap (`AnalyticsService.dart`)
  and the lowest-hanging Firebase defensive branches without violating
  the no-production-changes rule.
- Sets a clear, documented exit criterion for the dedicated coverage
  initiative — no perpetual "one more round."
- Locks in 85%+ coverage with a 82% CI floor; further growth comes from
  feature tests landing alongside features.
- Avoids the cost of standing up integration-test CI (emulator runners,
  Firebase Test Lab account, separate coverage merging) until a
  non-coverage need (smoke tests, e2e flows) justifies it.

### Negative

- Four files stay below 70% coverage indefinitely. Bugs in those files
  will not be caught by the test suite — they are accepted risk:
  - `main.dart` — bootstrap regression risk (one-time at startup).
  - `player.dart` — YoutubePlayer regression risk (limited blast radius,
    user-visible).
  - `logger_service.dart` — Sentry initialization regression risk
    (observability tool, not user-facing behavior).
  - `notification_service.dart` scheduling catch-branches — silent
    notification-failure risk (already partially mitigated by
    `reminder_debug_panel`'s diagnostic UI).
- A future integration-test initiative will need its own ADR and CI
  build-out. This ADR does not solve that.

### Neutral

- Phase 6 is small (estimated 1–2 days, 10–20 tests). Subsequent quality
  work will come from the simplify/security-review skills and feature
  PRs, not a separate coverage round.

## Links

- `docs/coverage-status.md` — full history of rounds 1–5
- `docs/coverage-gap-analysis.md` — original 2026-05-08 gap analysis
- `scripts/check_coverage.dart` — the CI gate
- `test/helpers/widget_test_scaffold.dart` — canonical test fixture

## Outcome

Executed 2026-05-19 by `qe-test-architect`. See `docs/coverage-status.md`
§ "Round 6 — Phase 6 ADR-001 execution" for the full per-file diff.

### Final numbers

| Metric | Before (R5) | After (R6) |
|---|---|---|
| Filtered global coverage | 85.21% | **85.88%** |
| `lib/AnalyticsService.dart` | 36.4% | **90.9%** |
| `lib/util/Firebase/firebase_functions.dart` | 68.0% | 68.1% |
| Tests passing | 564 | **586** (+22) |
| Skipped | 8 | 8 (unchanged) |
| CI global floor | 80% | **82%** |

### Test files added

- `test/AnalyticsService/MixPanelService_token_test.dart` (6 tests) —
  exercises `MixPanelService.init` + `trackEvent` under both empty- and
  non-empty-token branches via a `setMockMethodCallHandler`-stubbed
  `mixpanel_flutter` MethodChannel. The non-empty-token branches run only
  under the dart-define CI variant.
- `test/Firebase/firebase_functions_warning_class_test.dart` (2 tests) —
  direct constructor coverage for the `Warning` data class.
- `scripts/merge_lcov.dart` — standalone Dart helper that merges multiple
  LCOV files by max hits-per-line.

### CI changes (`.github/workflows/main.yml`)

The `build-android` job's "Run tests with coverage" step is followed by:

1. Snapshot the base lcov.
2. Re-run only `test/AnalyticsService/MixPanelService_token_test.dart`
   with `--dart-define=MIXPANEL_PROJECT_TOKEN=test-token`.
3. Snapshot the dart-define lcov.
4. Merge the two snapshots back into `coverage/lcov.info` via
   `dart run scripts/merge_lcov.dart`.

This is the **pattern-1 (target file only)** variant from the ADR Decision
section: only the affected test file is re-run under dart-define, not
the whole suite. Justification: ~5s extra CI time vs ~45s for a full
re-run, and other tests have no production code that reads the env var.

### What was deliberately not done (per ADR-001 § Decision, restated)

- No tests for `lib/main.dart`, `lib/pages/WellnessTools/player.dart`,
  `lib/util/logger_service.dart`, or the residual
  `lib/pages/notifications/notification_service.dart` scheduling
  catch-branches. These are integration-test territory and excluded from
  this ADR's scope.
- No production-code refactor to add `FirebaseFirestore? firestore` named
  params to the ~30 Firebase helpers that don't already have one (e.g.
  `getJournalMainTitle`, `getPersonalInfo`, `fetchWarnings`,
  `updateFormDifficultEventsTitles`). Reaching their bodies would
  violate the no-production-changes rule the ADR explicitly preserves.
  These ~270 lines stay uncovered as documented/accepted risk.

### Status note

ADR-001 stays `accepted`. The decision is in force and has been executed;
it has not been superseded. Phase 6 was the **last dedicated unit-coverage
round**. Future coverage growth is expected to come from feature PRs
landing alongside tests (pattern 5 in `coverage-status.md`).
