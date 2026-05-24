# ADR-004: Phase 9 — Extend `firestore` Injection Pattern to Close `firebase_functions.dart` Coverage Gap

- **Status**: accepted
- **Date**: 2026-05-24
- **Deciders**: Dekel
- **Tags**: testing, coverage, firebase, production-refactor, qe-test-architect
- **Supersedes**: none
- **Relates-to**: ADR-001 (Phase 6 hybrid path, established the `firestore` injection precedent), ADR-002 (Phase 7 integration pipeline), ADR-003 (Phase 8 aggregate gate)

## Context

After Phase 8 (`docs/coverage-status.md` § Round 8), the aggregate filtered global coverage is **~88.4%** against an **85% floor**. The unit-only filtered global is **85.88%** against an **82% floor**. The two upstream pipelines (`build-android` + `integration-test`) and the new `coverage-aggregate` gate are all stable in CI.

The single largest remaining gap is `lib/util/Firebase/firebase_functions.dart`:

| Metric | Value |
|---|---|
| File LOC | 1,387 |
| Unit coverage | 68.1% (~612 / ~900 effective) |
| Lines uncovered | ~287 |
| Share of total uncovered (filtered) | dominant single file |

Round 6 documented the structural reason these lines stay uncovered:

> The bulk of the remaining 287 uncovered lines in `lib/util/Firebase/firebase_functions.dart` (e.g. `getJournalMainTitle`, `getPersonalInfo`, `getIntroductionFormFirstPage`, `fetchWarnings`, `updateTest1`, `updatePhoneFormTitles`, `updateFormDifficultEventsTitles`, `updateFormDistractionsTitles`, `updateFormFeelBetterTitles`, `updateFormMakeSaferTitles`, `updateFormSharePageTitles`, `updatePhonePersonalPlanText`) call `FirebaseFirestore.instance` directly and have no `firestore` named param. Adding one would close them — but ADR-001 explicitly preserves the no-production-changes rule for Phase 6.

ADR-001 § Decision narrowly sanctioned the `firestore` named-param injection for 14 helpers as the **only** production-code exception for unit testability. Round 7 added a second narrow exception (`@visibleForTesting NotificationsService.resetForTest()`). Both followed the same shape: small, self-documenting, behavior-preserving for production paths.

Phase 9 proposes a **third such sanctioned exception**, this time extending the existing `firestore` named-param pattern to ~30 additional helpers in the same file. The change is mechanical, behavior-preserving, and follows a precedent already accepted across the codebase. Once landed, qe-test-architect can generate the test cases per helper using the established `FakeFirebaseFirestore` pattern.

**Motivation for Phase 9 now:**

- Phase 8 closed the last *infrastructure* gap (aggregate gate). The remaining gaps are *coverage gaps* in specific files, not pipeline gaps.
- 287 lines in one file is a single, well-bounded scope — unlike `main.dart` (background Workmanager, requires a Patrol-class harness) or iOS notification paths (requires a macOS runner).
- The `FakeFirebaseFirestore` testing scaffold already exists from Round 1; ~5 test files in `test/Firebase/` already use it. The incremental test cost is per-helper, not per-infrastructure.
- qe-test-architect's sublinear test generation is well-suited to this: a single production file with ~30 similarly-shaped read/write helpers, each with a small set of branches (happy path, missing doc, malformed doc, network/permission error). The agent can fan out across helpers in parallel.
- The 3-pt headroom over the aggregate floor (88.4% actual vs 85% floor) is intentional buffer; Phase 9 grows the actual to ~92–93% est. (see § Floor-value derivation), then ratchets the floor to ~89–90%.

## Sub-decision A — Scope of the production-code change

**Chosen: extend the optional `FirebaseFirestore? firestore` named param to all read/write helpers in `lib/util/Firebase/firebase_functions.dart` that currently call `FirebaseFirestore.instance` directly.**

Concretely, the helpers in scope (enumerated from Round 6's still-deferred list + Round 5's residuals; final list confirmed via `grep "FirebaseFirestore.instance" lib/util/Firebase/firebase_functions.dart`):

- `getJournalMainTitle`, `getPersonalInfo`, `getIntroductionFormFirstPage`
- `fetchWarnings` (the `Warning` data class consumer)
- `updateTest1`, `updatePhoneFormTitles`, `updateFormDifficultEventsTitles`, `updateFormDistractionsTitles`, `updateFormFeelBetterTitles`, `updateFormMakeSaferTitles`, `updateFormSharePageTitles`, `updatePhonePersonalPlanText`
- Any remaining helper that grep surfaces with a direct `.instance` call

Each helper gains one signature line of the existing shape:

```dart
Future<...> helperName({
  // ...existing params...
  FirebaseFirestore? firestore,
}) async {
  final _fs = firestore ?? FirebaseFirestore.instance;
  // ...body uses _fs instead of FirebaseFirestore.instance...
}
```

The pattern is **identical** to the 14 helpers ADR-001 sanctioned in Round 1. No new pattern is introduced; only the existing one is extended.

### Rejected alternatives

| Alternative | Reason rejected |
|---|---|
| **Wrap `FirebaseFirestore` in an internal abstraction** (e.g. `FirestoreClient` interface) | Larger refactor footprint; would touch the 14 already-injected helpers too. Violates the "narrow, mechanical" character of ADR-001's precedent. Saves no test code (`FakeFirebaseFirestore` is already the test seam). |
| **Use a static `FirebaseFirestore` setter for test override** | Global mutable state in test mode; the existing param-injection pattern is more local and explicit. |
| **Mockito-codegen the helpers' callers** | Would require generating mocks per consumer file; brittle, doesn't compose with `FakeFirebaseFirestore`'s in-memory semantics. |
| **Leave the gap; reduce the floor** | Defeats the ratchet discipline. The whole point of the floor is that it holds. |

## Sub-decision B — Use qe-test-architect to author the tests

**Chosen: dispatch qe-test-architect to author `test/Firebase/firebase_functions_phase9_*.dart` files covering the newly-injectable helpers.**

The agent's responsibilities scope the test cases to what the helpers
actually do under the **no-production-change rule** of this ADR. The
helpers in scope have no documented missing-doc or malformed-doc
fallback — they call `doc.get(field)` directly, which throws
`StateError` on absent fields. The behavior-preserving test contract
is therefore:

1. For each helper that gains a `firestore` named param under Sub-decision A:
   - **Happy path (required)** — `FakeFirebaseFirestore` seeded with the
     expected document shape, helper called with `firestore: fake`,
     return value asserted field-by-field. This single test simultaneously
     validates the **firestore parameter wiring**: if the injected fake
     were ignored, the helper would throw "no Firebase app" instead of
     returning the seeded data.
   - **Empty-collection throw path (where applicable)** — for the seven
     `update*` multi-collection helpers that explicitly throw
     `Exception('No documents found in collection')` when a queried
     collection is empty, seed only one collection (or none) and assert
     the throw. This is the **only** documented branch the helpers have
     beyond the happy path.
   - **Missing-field / malformed-doc tests are out of scope.** No helper
     has a documented fallback; adding one would be a behaviour change
     beyond ADR-004's no-production-change rule. If the missing-field
     contract is ever made deterministic (e.g. via a defensive
     `doc.data() as Map?` + fallback), a follow-up ADR can sanction
     those tests.
2. Use the `FakeFirebaseFirestore` pattern from
   `test/Firebase/firebase_functions_load_firebase_branches_test.dart`
   (Round 4 reference). No widget-scaffold dependency is needed (these
   are pure-Dart unit tests, not widget tests).
3. **Do not** generate tests for branches that are still genuinely
   unreachable post-Phase-9 (the `?? FirebaseFirestore.instance`
   right-hand sides identified in Round 6 are unreachable by
   construction; they remain documented as accepted dead lines).
4. **Do not** modify `lib/` beyond the signature changes in Sub-decision A.

The expected fan-out is ~29 helpers × ~1–3 test cases each ≈ 30–60 new
tests. qe-test-architect's sublinear optimization should let it dedupe
boilerplate scaffolding across helpers.

### Rejected alternatives

| Alternative | Reason rejected |
|---|---|
| **Hand-author** | Phase 9 is the first round where the test fan-out exceeds what a single session can comfortably author by hand. The agent exists precisely for this shape. |
| **qe-test-generation (the generation skill, not the agent)** | The skill is one-shot; qe-test-architect orchestrates iteration + coverage feedback. Per-helper iteration is needed because some helpers' fallback branches are non-obvious. |
| **Defer to integration tests on emulator** | Wasteful: emulator runtime for read/write helpers that have no platform-specific behavior. The unit pipeline is the right home. |

## Sub-decision C — Floor-value ratchet

**Chosen: raise the unit-pipeline floor from 82% to ~85% and the aggregate floor from 85% to ~89%.**

### Derivation

Closing ~250 of the 287 uncovered lines in `firebase_functions.dart` (allowing ~37 lines for the unreachable `?? FirebaseFirestore.instance` right-hand sides + a small residual margin):

```
Round 8 unit baseline: 5576 / 6493 = 85.88%
Phase 9 unit delta:    +250 lines
Post-Phase-9 unit:     5826 / 6493 = 89.73%
Floor proposal:        89.73% − ~5 pt headroom = 84.7% → 85%

Round 8 aggregate baseline: 5739 / 6493 = 88.39%
Phase 9 aggregate delta:    +250 lines (same lines, single source)
Post-Phase-9 aggregate:     5989 / 6493 = 92.24%
Floor proposal:             92.24% − ~3 pt headroom = 89.24% → 89%
```

The 5 pt vs 3 pt headroom asymmetry is deliberate:

- **Unit floor (85%, 5 pt cushion):** Phase-10+ new-feature churn lands here first. Larger cushion absorbs natural drift.
- **Aggregate floor (89%, 3 pt cushion):** consistent with the ADR-003 ratchet shape; integration-test variance is the binding constraint, not unit churn.

### Rejected alternatives

| Alternative | Reason rejected |
|---|---|
| **Keep both floors unchanged** | Wastes the Phase 9 gain — the gate would no longer be the binding constraint on any regression. Defeats ratchet discipline. |
| **Match floors (e.g. both at 87%)** | Removes the deliberate decoupling: the unit gate is intentionally easier to hit than the aggregate (so emulator-class flake doesn't pull the unit critical path). |
| **Aggressive 91% aggregate floor** | Leaves only ~1 pt of headroom; first run-to-run integration variance would spuriously fail PRs. |

## Sub-decision D — Verification of qe-test-architect output

**Chosen: each batch of agent-authored tests must clear three gates before commit.**

1. **`dart analyze` clean** — no warnings, no missing imports.
2. **`flutter test --coverage` passes locally** — no skipped tests added without an inline justification comment, no flakes (10 consecutive passes for any new test before merge).
3. **Coverage delta verified via `scripts/file_coverage.dart`** — each touched helper file's % must rise by the expected delta from the ADR's per-helper plan; surprise misses are flagged and re-authored.

These are the same gates Round 5–7 used; no new tooling needed.

## Decision

1. Extend the `firestore` named-param injection pattern (ADR-001 precedent) to all remaining helpers in `lib/util/Firebase/firebase_functions.dart` that directly call `FirebaseFirestore.instance`.
2. Dispatch `qe-test-architect` to author the corresponding unit tests under `test/Firebase/firebase_functions_phase9_*.dart`, using `FakeFirebaseFirestore` as the seam.
3. Ratchet `scripts/check_coverage.dart` unit floor from 82% → 85% and `scripts/check_aggregate_coverage.dart` aggregate floor from 85% → 89%.
4. Production-code changes are limited to the signature extension in Sub-decision A. No other `lib/` modification is permitted under this ADR.
5. Document the round in `docs/coverage-status.md` § "Round 9" once landed.

## Consequences

### Positive

- Closes the single largest remaining unit-pipeline coverage gap (~250 lines, ~3.8 pts of global coverage).
- Establishes qe-test-architect as a sanctioned tool for future coverage-expansion rounds (the precedent itself is portable: Phase 10+ rounds for `myPlanPageFull.dart` or `lib/main.dart`'s `bootstrapApp()` extraction would follow the same pattern).
- Brings `firebase_functions.dart` from 68.1% to an estimated ~90%+ — the same tier as the rest of `lib/util/Firebase/`.
- Aggregate floor moves to 89%, a meaningful new ratchet over Phase 8's 85%.

### Negative

- **Third sanctioned production-code exception** to the original no-production-changes rule. Each exception narrows the bar for future ones; this ADR's narrow framing (same pattern as ADR-001, not a new shape) is the right discipline but the trend should be watched.
- ~90 new tests adds ~5–10 s to local `flutter test` runtime and a similar bump in CI. Still well within the existing budget.
- qe-test-architect output requires human review per Sub-decision D; estimated 1–2 review sessions before merge.

### Neutral

- The unreachable `?? FirebaseFirestore.instance` fallback lines (lines 234/384/843/858/903/916/975/1040/1060/1086/1097/1145/1379/1393/1413 per Round 6) remain documented as accepted dead lines; Phase 9 does not attempt to cover them.
- iOS-specific notification paths, `main()`/`callbackDispatcher`, empty-DSN/outer-catch branches in `logger_service.dart` — all out of scope for Phase 9; they remain on the still-deferred list with their existing unblock criteria from ADR-002/003.

## Out of scope for Phase 9

- `lib/main.dart` (`bootstrapApp()` extraction). Tracked for a future ADR.
- iOS-specific `notification_service.dart` paths. Requires macOS runner; tracked under ADR-002.
- `lib/util/logger_service.dart` empty-DSN if-branch and outer catch branch. Structurally dead in CI per Round 7 documentation.
- Any non-Firebase coverage work. Phase 9 is deliberately single-file in scope to keep the agent's output reviewable.
- Raising integration per-file floors. Phase 9 is unit-only; integration pipeline is untouched.

## Floor-value derivation (summary)

```
Unit baseline (R8):       5576 / 6493 = 85.88%
Phase 9 helpers covered:  ~250 of 287 uncovered lines in firebase_functions.dart
Post-Phase-9 unit:        5826 / 6493 = 89.73%
Unit floor proposal:      89.73% − 5 pt cushion = 85% (up from 82%)

Aggregate baseline (R8):  5739 / 6493 = 88.39%
Phase 9 contribution:     same +250 lines (unit-source)
Post-Phase-9 aggregate:   5989 / 6493 = 92.24%
Aggregate floor proposal: 92.24% − 3 pt cushion = 89% (up from 85%)
```

## Outcome

(To be filled in once Phase 9 executes; mirrors the ADR-002 / ADR-003 § Outcome shape.)

### What will change

| Surface | Before (R8) | After (R9, projected) |
|---|---|---|
| `firebase_functions.dart` coverage | 68.1% | ~90% |
| Unit global filtered | 85.88% | ~89.7% |
| Aggregate global filtered | ~88.4% | ~92.2% |
| Unit floor | 82% | **85%** |
| Aggregate floor | 85% | **89%** |
| Helpers with `firestore` named param | 14 | ~44 |
| Test files in `test/Firebase/` | 6 | ~8–10 |

### What stays unchanged

- `integration_test/` pipeline and per-file floors.
- `scripts/check_integration_coverage.dart`.
- `coverage-aggregate` CI job shape.
- All `lib/` files outside `firebase_functions.dart`. `git diff lib/` for Phase 9 should touch one file only.

## Links

- `docs/adr/ADR-001-phase-6-test-coverage-integration-tests.md` — established the `firestore` injection precedent
- `docs/adr/ADR-002-phase-7-integration-tests-deferred-coverage.md` — Phase 7 outcome
- `docs/adr/ADR-003-phase-8-aggregate-coverage-gate.md` — Phase 8 outcome
- `docs/coverage-status.md` § "Round 8" — last execution record; § "Round 9" to be added on Phase 9 landing
- `scripts/check_coverage.dart` — unit gate (floor to ratchet 82% → 85%)
- `scripts/check_aggregate_coverage.dart` — aggregate gate (floor to ratchet 85% → 89%)
- `test/Firebase/firebase_functions_load_firebase_branches_test.dart` — reference for `FakeFirebaseFirestore` seam
- `test/helpers/widget_test_scaffold.dart` — reusable provider+GetIt fixture (sanctioned test-side helper)
