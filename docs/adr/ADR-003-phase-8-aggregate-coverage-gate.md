# ADR-003: Phase 8 — Aggregate Coverage Gate (Merge Integration into Global Ratchet)

- **Status**: accepted
- **Date**: 2026-05-24
- **Deciders**: Dekel
- **Tags**: testing, coverage, integration-tests, ci, aggregate-gate
- **Supersedes**: none
- **Relates-to**: ADR-001 (Phase 6 hybrid path), ADR-002 (Phase 7 integration-test pipeline)

## Context

ADR-002 closed Phase 7 with two decoupled CI jobs:

| Job | Gate | What it enforces |
|---|---|---|
| `build-android` | `scripts/check_coverage.dart` | 82% global floor + tier-1/tier-2 per-file floors (unit lcov only) |
| `integration-test` | `scripts/check_integration_coverage.dart` | 4 per-file floors against `coverage/integration.info` only |

The two pipelines are intentionally decoupled — emulator-class flakes in
`integration-test` cannot pull the `build-android` 82% floor below
threshold. ADR-002 § "Out of scope for Phase 7" explicitly lists
"Merging integration coverage into the global ratchet (Phase 8 if ever)"
as deferred.

Phase 8 implements that deferred item. Both upstream pipelines are now
stable (PR #266 landed all four per-file floors; the emulator job runs
reliably); the question is whether adding a third aggregate gate is worth
the CI complexity.

**Motivation for Phase 8 now:**

- The two per-file gates enforce floors against each lcov separately.
  Neither gate sees the union of unit + integration coverage — a file
  could satisfy its per-file floor in isolation while regressing badly
  in the other pipeline without triggering either gate.
- A single aggregate ratchet provides a summary health signal that is
  visible at the PR level without requiring a reviewer to cross-reference
  two separate gate results.
- The infrastructure to merge lcovs already exists (`scripts/merge_lcov.dart`,
  `scripts/_lcov_parser.dart`, `actions/download-artifact@v4`). The
  marginal CI cost of a third job is one artifact download + two `dart run`
  invocations (~30 seconds of compute after both upstream jobs complete).

## Sub-decision A — Aggregate job location

**Chosen: new `coverage-aggregate` job that `needs: [build-android, integration-test]`.**

Alternatives considered and rejected:

| Alternative | Reason rejected |
|---|---|
| **Extend `build-android`** to download the integration artifact and merge there | Violates the decoupling principle: a timeout or infrastructure failure in the integration-test job would leave `build-android` unable to complete, blocking the unit-pipeline gate even when unit tests are healthy. ADR-002's explicit design goal is that emulator flake does not block the unit critical path. |
| **Extend `integration-test`** symmetrically | Same problem from the other direction: the unit artifact upload is gated behind `build-android` completing, so `integration-test` would have to wait for it, negating the parallelism. |
| **Share state via a GitHub Actions cache key** (write lcov to cache in one job, read in the other) | Cache is not a reliable inter-job rendezvous — cache misses are silent, no ordering guarantees. Artifact upload/download via `actions/upload-artifact@v4` + `actions/download-artifact@v4` is the official, deterministic pattern. |

A new downstream `coverage-aggregate` job preserves all existing job
boundaries and adds no new dependencies to either upstream job.

## Sub-decision B — New global aggregate floor

**Chosen: 85%.**

### Derivation

Unit-only baseline from `coverage/lcov.info` (R7 tip, confirmed by
`dart run scripts/check_coverage.dart`):

```
5576 / 6493 = 85.88%
```

The four ADR-001/ADR-002 deferred files contribute additional hits when
the integration lcov is merged. Using the per-file coverage %s recorded
in `docs/coverage-status.md` § Round 7 and the LF counts from the
current `coverage/lcov.info`:

| File | LF | Unit hits | Intg post-merge % | Intg hit est. | Union delta |
|---|---|---|---|---|---|
| `lib/main.dart` | 177 | 3 | 59.3% | 105 | +102 |
| `lib/pages/WellnessTools/player.dart` | 38 | 2 | 94.7% | 36 | +34 |
| `lib/util/logger_service.dart` | 19 | 2 | 73.7% | 14 | +12 |
| `lib/pages/notifications/notification_service.dart` | 63 | 42 | 90.6% | 57 | +15 |
| **Total delta** | — | — | — | — | **+163** |

Post-merge estimate: (5576 + 163) / 6493 = **88.39%**

Floor = 88.39% − 3.0 pt headroom = 85.39% → rounded to **85%**.

Rationale for 3 pt headroom:
- Consistent with the ADR-001 → ADR-002 ratchet shape (each floor was set
  ~3–5 pts below the then-current actual %).
- The integration-test %s above are the ADR-002-recorded values, not
  directly verified from a local `integration.info`. The 3 pt cushion
  absorbs minor CI variance in the integration-test run.
- 85% is clearly above the 82% unit-only floor, so the aggregate gate is
  a genuine ratchet, not a rubber stamp.

### Rejected alternatives

- **88%** (1 pt below estimate): leaves insufficient headroom for
  integration-test run-to-run variance (~1–2 lines difference in `main.dart`
  depending on async timing in `bootstrap_smoke_test.dart`). Risk of spurious
  gate failures.
- **84%** (4 pt headroom): technically safe but only 2 pts above the unit
  floor — barely meaningful as a ratchet over `check_coverage.dart`.
- **Keep at 82%** (same as unit floor): meaningless — the aggregate gate
  would never be the binding constraint.

## Sub-decision C — Decoupling principle and blocking behaviour

**Chosen: `coverage-aggregate` is a blocking required-check.**

The aggregate gate runs after both upstream jobs succeed. If either upstream
job fails, GitHub Actions does not start `coverage-aggregate` at all (the
`needs:` dependency prevents it). This is the correct behaviour: if the unit
gate fails, the aggregate gate is moot; if the integration job fails, the
aggregate merge would be operating on a stale or absent artifact.

Blocking (rather than advisory/`continue-on-error`) is the right default
because:
- The floor was deliberately set with 3 pts of headroom — spurious failures
  from headroom exhaustion are expected to be rare.
- An advisory gate would be ignored under PR time pressure. The whole point
  of a ratchet is that it holds.
- If the aggregate floor proves too tight in practice, the correct response
  is to raise the floor to match the new actual (the same ratchet discipline
  as all previous rounds), not to make the gate optional.

The existing 82% unit-only floor in `build-android` is **unchanged**. It
remains the floor under emulator-out-of-band conditions (e.g., a PR that
must land before the emulator job is healthy again, using a temporary
`continue-on-error: true` on `integration-test`).

## Sub-decision D — What `check_aggregate_coverage.dart` enforces

**Chosen: single new global aggregate floor (85%) + input-file presence check only.**

`check_aggregate_coverage.dart` does **not** re-enforce tier-1, tier-2, or
per-file floors from the upstream gates. Those floors are already enforced
by `check_coverage.dart` (unit gate) and `check_integration_coverage.dart`
(integration gate). Re-enforcing them here would:
- Duplicate gate logic across three scripts (the PR #266 review noted this
  pattern was a problem and led to `_lcov_parser.dart` extraction).
- Make the aggregate gate fail on tier-1/tier-2 regressions that the
  upstream gates already catch, producing redundant failure messages.

Exit codes follow the established pattern:
- `0` — all thresholds met
- `1` — aggregate global floor not met
- `2` — either input lcov file (`coverage/lcov.info` or
  `coverage/integration.info`) is absent (CI-config error, not a coverage
  regression)

The same exclude list as `check_coverage.dart` is applied before computing
the aggregate global %:
`app_localizations*`, `firebase_options`, `global_enums`, `l10n.dart`.

## Sub-decision E — Behaviour when integration-test job is skipped or fails

**Chosen: `if: ${{ always() }}` on the aggregate job + explicit
dependency-result check as its first step.**

A naive `needs: [build-android, integration-test]` without `always()` is
**unsafe under branch protection**. The GitHub Actions semantics:

- `needs:` alone causes a downstream job to be **skipped** when an upstream
  job fails or is itself skipped.
- A required check that resolves to "skipped" in branch protection can be
  treated as a successful check by GitHub's protected-branch evaluator —
  meaning a PR with a failed upstream can merge with the aggregate gate
  appearing green in the merge UI even though it never ran. This was
  flagged during PR review (`tests/phase8-2026`, first review pass).

The correct pattern is the `always()` + explicit-result-check shape used
elsewhere in the GitHub Actions ecosystem (e.g. the canonical
[reusable-workflow gate pattern](https://docs.github.com/en/actions/using-jobs/using-conditions-to-control-job-execution#using-the-status-of-previous-jobs)).

The implementation:

```yaml
coverage-aggregate:
  needs: [build-android, integration-test]
  if: ${{ always() }}
  steps:
    - name: Verify both upstream jobs succeeded
      run: |
        build_result="${{ needs.build-android.result }}"
        intg_result="${{ needs.integration-test.result }}"
        if [ "$build_result" != "success" ]; then
          echo "::error::Upstream job build-android did not succeed (result=$build_result); cannot compute aggregate coverage." >&2
          exit 1
        fi
        if [ "$intg_result" != "success" ]; then
          echo "::error::Upstream job integration-test did not succeed (result=$intg_result); cannot compute aggregate coverage." >&2
          exit 1
        fi
```

Outcome by upstream state:

| `build-android` | `integration-test` | `coverage-aggregate` status |
|---|---|---|
| success | success | **runs** → success/failure based on aggregate floor |
| failure | * | **runs** → fails fast in the result-check step (does NOT skip) |
| * | failure | **runs** → fails fast in the result-check step (does NOT skip) |
| cancelled | * | runs → fails fast (treats cancellation as not-success) |
| skipped | * | runs → fails fast (treats skipped as not-success) |

The job's GitHub-reported status is therefore ALWAYS one of `{success,
failure}` — never `skipped`. Branch protection treats it correctly as a
genuine required check.

If a future ADR adds an `if:` skip condition to either upstream job,
update the result-check logic here to treat that specific skip as
not-blocking (rather than as a failure) — but only with explicit
documentation of why the aggregate gate is safe to bypass in that
condition. The current implementation does NOT special-case any skip
scenario.

## Decision

Add a `coverage-aggregate` CI job that:

1. `needs: [build-android, integration-test]` — runs only when both upstream
   jobs succeed.
2. Downloads `coverage-lcov` and `coverage-integration-lcov` artifacts.
3. Merges them via `dart run scripts/merge_lcov.dart coverage/aggregate.info
   coverage/lcov.info coverage/integration.info`.
4. Enforces 85% aggregate global floor via a new
   `scripts/check_aggregate_coverage.dart`.
5. Uploads the merged lcov as `coverage-aggregate-lcov`.

The new gate script applies the same exclude list as `check_coverage.dart`
and exits 2 if either input file is missing (distinguishes CI-config error
from coverage regression).

## Consequences

### Positive

- Single combined health signal visible at PR level; reviewers no longer
  need to cross-reference two separate gate results to assess total coverage.
- Ratchets aggregate coverage above 82% (unit-only floor) to 85% — a genuine
  new constraint that the unit gate alone cannot enforce.
- The `coverage-aggregate-lcov` artifact provides a merged lcov for future
  tooling (coverage diff comments, badge generation, trend charts) without
  any additional CI work.
- Additive — removing this job restores the Phase 7 state exactly; the two
  upstream gates are still independently sufficient.

### Negative

- Adds ~30 s of extra CI time (artifact downloads + merge + gate script) on
  top of the existing ~8 min integration-test job.
- Adds a third gate script to maintain (but it is ~60 LOC, simpler than
  `check_coverage.dart`, and delegates all parsing to `_lcov_parser.dart`).
- Any floor adjustment now requires a change in two places:
  `check_coverage.dart` (unit floor) and `check_aggregate_coverage.dart`
  (aggregate floor). They are intentionally different numbers and serve
  different purposes, so co-location would be confusing; the two-file
  discipline is the right trade-off.

### Neutral

- The `integration-test` job's `if: always()` on the artifact upload step
  means `coverage-integration-lcov` is available even when the coverage
  floor check fails (which is how Phase 7 was designed). The
  `coverage-aggregate` job still waits for `integration-test` to complete
  successfully before running — it is NOT triggered on a per-file floor
  failure in the integration gate.

## Floor-value derivation (summary)

```
Unit baseline:  5576 / 6493 = 85.88%
Integration contribution (union of per-file additions):
  main.dart              +102 lines  (3→105 of 177)
  player.dart             +34 lines  (2→36 of 38)
  logger_service.dart     +12 lines  (2→14 of 19)
  notification_service    +15 lines  (42→57 of 63)
  Total delta:           +163 lines

Aggregate estimate: 5739 / 6493 = 88.39%
Floor = 88.39% − 3.0 pt headroom = 85.39% → 85%
```

## Outcome

### What changes

| Surface | Before (R7) | After (R8) |
|---|---|---|
| CI jobs | `build-android` + `integration-test` | + new `coverage-aggregate` |
| Coverage gate scripts | `check_coverage.dart` + `check_integration_coverage.dart` | + new `check_aggregate_coverage.dart` |
| Global unit floor | 82% | **82% (unchanged)** |
| Global aggregate floor | none | **85%** |
| Merged lcov artifact | none | `coverage-aggregate-lcov` |

### What stays unchanged

- `build-android` job and its `check_coverage.dart` gate — untouched.
- `integration-test` job and its `check_integration_coverage.dart` gate — untouched.
- Per-file floors in both upstream gates — untouched.
- All production code (`lib/`) — untouched. `git diff lib/` is empty.

### Files added

- `scripts/check_aggregate_coverage.dart` — new aggregate gate script
- `docs/adr/ADR-003-phase-8-aggregate-coverage-gate.md` — this file

### Files modified

- `.github/workflows/main.yml` — adds `coverage-aggregate` job
- `docs/coverage-status.md` — adds Round 8 section

### ADR-002 deferred items affected by this ADR

The four files previously marked as "accepted risk" in ADR-001 and given
per-file floors in ADR-002 are now also visible in the aggregate gate:

| File | ADR-001 status | ADR-002 status | ADR-003 status |
|---|---|---|---|
| `lib/main.dart` | accepted risk | ≥50% floor (intg) | included in aggregate; callbackDispatcher / initializeApp still uncovered |
| `lib/pages/WellnessTools/player.dart` | accepted risk | ≥60% floor (intg) | included in aggregate; all ADR-002 targets closed |
| `lib/util/logger_service.dart` | accepted risk | ≥60% floor (intg) | included in aggregate; empty-DSN if-branch + outer catch still structurally dead in CI |
| `lib/pages/notifications/notification_service.dart` | accepted risk | ≥85% floor (intg) | included in aggregate; iOS-specific paths still unit-test only |

The aggregate gate provides a combined ratchet but does not remove the
remaining individually-documented gaps above — those stay as-is per
ADR-002's accepted trade-offs.

## Links

- `docs/adr/ADR-001-phase-6-test-coverage-integration-tests.md` — Phase 6 outcome
- `docs/adr/ADR-002-phase-7-integration-tests-deferred-coverage.md` — Phase 7 outcome
- `docs/coverage-status.md` § "Round 8" — execution record
- `scripts/check_coverage.dart` — unit gate (82% floor, unchanged)
- `scripts/check_integration_coverage.dart` — integration gate (per-file floors, unchanged)
- `scripts/check_aggregate_coverage.dart` — new aggregate gate (85% floor)
- `scripts/merge_lcov.dart` — lcov merger (unchanged, reused)
- `scripts/_lcov_parser.dart` — shared parser (unchanged, reused)
