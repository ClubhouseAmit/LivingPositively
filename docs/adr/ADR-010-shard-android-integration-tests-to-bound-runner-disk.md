# ADR-010: Shard Android Integration Tests to Bound Runner Disk Usage

- **Status**: accepted
- **Date**: 2026-07-26
- **Deciders**: Dekel
- **Tags**: ci, android, flutter, integration-tests, coverage, github-actions, performance
- **Supersedes**: none
- **Relates-to**: ADR-002 (Android integration-test gate), ADR-003 (aggregate coverage gate)

## Context

ADR-002 established a blocking Android `integration-test` job that runs the
Flutter integration suite on a GitHub-hosted Android emulator and enforces
per-file coverage floors. ADR-003 added the downstream blocking
`coverage-aggregate` job, which consumes the canonical
`coverage/integration.info` artifact and merges it with unit coverage.

The Android job currently passes seven integration-test entry points to one
`flutter test` invocation:

1. `integration_test/custom_categories_e2e_test.dart`
2. `integration_test/dark_mode_settings_test.dart`
3. `integration_test/bootstrap_smoke_test.dart`
4. `integration_test/bootstrap_full_test.dart`
5. `integration_test/wellness_player_test.dart`
6. `integration_test/logger_init_test.dart`
7. `integration_test/notifications_schedule_test.dart`

Together they contain 25 `testWidgets` cases. Flutter builds and installs a
separate Android debug application for each entry point. A successful run on
2026-07-21 showed six `assembleDebug` executions in the same runner workspace.

On 2026-07-24, PR run
`https://github.com/ClubhouseAmit/LivingPositively/actions/runs/30098057012`
exhausted the `integration-test` runner disk. The first two entry points
completed, after which GitHub Actions reported 24 MB free. The third
`assembleDebug` then failed in `:app:copyFlutterAssetsDebug`:

```text
java.io.IOException: No space left on device
```

The downstream `coverage-aggregate` job failed correctly because
`integration-test` did not produce a successful canonical coverage artifact.
The pull request changed only the Android release job; it did not change the
integration tests or their build inputs.

GitHub-hosted jobs receive fresh runner instances. Artifacts retained from
earlier workflow runs therefore did not fill this runner. The volatile inputs
are the hosted runner image, its preinstalled tools, Android SDK components,
Flutter/plugin native build outputs, and the number of integration entry
points. The stable requirements are the test behaviors, isolation, coverage
floors, artifact contracts, and required-check semantics.

### Quality invariants

Any resource optimization must preserve all of the following:

- All seven existing Android integration files and all 25 test cases execute.
- Every test file runs in its own application process, preserving the current
  isolation boundary for plugin state, static state, method-channel mocks,
  Sentry lifecycle, and binding configuration.
- Tests execute on the Android emulator with the existing Flutter version,
  API level, architecture, profile, Firebase options, and synthetic
  `SENTRY_DSN`.
- `scripts/check_integration_coverage.dart` enforces the same four per-file
  floors against the union of all Android integration coverage.
- The unit pipeline retains its current 85% global floor.
- `coverage-aggregate` receives the same canonical
  `coverage-integration-lcov` artifact containing
  `coverage/integration.info`.
- The required `integration-test` check cannot become skipped when a shard
  fails or is cancelled.
- No production code, test assertion, coverage floor, or aggregate floor
  changes as part of this optimization.

## Options considered

### Option A: Combine all tests into one Dart entry point

A single integration-test entry point would require one Android build and
would minimize both disk usage and native build time.

This changes the isolation boundary. All test modules would share one
application process and one `IntegrationTestWidgetsFlutterBinding`. In
particular, `custom_categories_e2e_test.dart` sets a global live frame policy,
while other files rely on their own setup, teardown, plugin, and static-state
lifecycle. Group-scoped setup and teardown can reduce leakage, but cannot
reproduce a fresh process.

Rejected because it lowers isolation and makes the optimization responsible
for proving that unrelated test modules can safely share global state.

### Option B: Clean the workspace between files on one runner

Run each file separately, preserve its coverage output, remove native build
outputs, and rebuild the next file.

This keeps process isolation and can lower workspace growth, but retains seven
native builds. It materially increases runtime, requires cleanup inside an
already resource-constrained runner, and does not bound growth in Gradle,
Android SDK, emulator, Flutter, or tool caches. Coverage files would also need
additional orchestration before every cleanup.

Rejected because peak usage remains dependent on cleanup completeness and
volatile tool-cache behavior.

### Option C: Cache Gradle and Android virtual device state

Restoring Gradle or Android virtual device state could reduce setup and native
build time, but the cache itself consumes the same constrained runner disk
whose headroom this decision protects. Cache contents and growth are volatile,
so an initial cache can erode per-runner capacity before the test starts.

Rejected for the initial implementation. Gradle caching remains a
telemetry-driven follow-up only after shard disk observations demonstrate
stable headroom; Android virtual device caching is likewise not implemented.

On 2026-08-28, subsequent shard telemetry showed more than 76 GiB of free
space after an Android integration build, while PR run
`https://github.com/ClubhouseAmit/LivingPositively/actions/runs/33153726765`
failed before its test started when Maven Central returned HTTP 429 responses
for Kotlin Gradle artifacts. This satisfied the telemetry condition for
adopting Gradle dependency and wrapper caching.

`build-android` now produces the `actions/setup-java` Gradle cache, and each
`integration-test-shard` waits for that job before restoring the same cache
key. The cache key covers the Android Gradle build files, wrapper properties,
`android/gradle.properties`, and `pubspec.lock`. Each shard still receives a
fresh runner and process. Android virtual devices, emulator state, and project
build outputs remain excluded from caching.

### Option D: Delete preinstalled tools or use a larger runner

Removing unrelated SDKs from the hosted image or purchasing a larger runner
would create more headroom without changing test behavior.

This treats available capacity rather than required working space. Runner-image
contents and deletion paths are volatile, while a larger runner adds an
ongoing cost and does not contain growth as more integration files are added.

Rejected as the primary solution. A larger runner remains an operational
fallback if a single Android build no longer fits a standard runner.

### Option E: Split files across fresh runners and merge coverage

Run one existing integration-test file per matrix shard. Each shard receives a
fresh runner, starts the same emulator, executes the same command-line flags,
and uploads a uniquely named LCOV artifact. A downstream job merges the seven
LCOV files with the existing `scripts/merge_lcov.dart`, applies the unchanged
integration coverage gate, and publishes the canonical artifact expected by
ADR-003.

This bounds each runner to one Android debug build while retaining the current
per-file process isolation and coverage union.

Chosen.

## Decision

Replace the single-runner Android integration execution with a matrix of one
test file per shard and a downstream canonical `integration-test` gate.

### Shard job

Introduce an `integration-test-shard` matrix job with one explicit entry for
each of the seven Android integration files. Each matrix entry has a stable,
filesystem-safe identifier and its existing file path.

Every shard must:

1. Check out the same commit.
2. Materialize the same Firebase options.
3. Configure JDK, Flutter, KVM, and the Android emulator exactly as the current
   job does.
4. Run only its assigned test file with:
   - `--coverage`
   - a unique `--coverage-path`
   - the existing synthetic `SENTRY_DSN`
   - explicit `-d emulator-5554`
5. Upload its uniquely named LCOV artifact on `if: always()`, warning when the
   file is absent so the canonical inventory remains the hard completeness
   gate.
6. Record filesystem capacity before and after the test using `df -h` so peak
   resource regressions remain diagnosable.
7. Parse post-test capacity with portable `df -Pk .`, report available MiB,
   and emit a machine-readable warning when headroom is below 2 GiB
   (2,097,152 KB). Low headroom is telemetry and does not fail a shard alone.

The matrix may cap parallelism for operational reasons, but parallelism must
not alter shard contents or gate semantics. The initial cap is three concurrent
shards to avoid starting seven emulators simultaneously while still completing
the suite in three waves. Each shard has a 45-minute timeout to bound emulator
hangs without weakening the test or coverage contract.

### Workflow concurrency

Pushes to `main` share the repository-local literal concurrency group
`main-release-pipeline` with `cancel-in-progress: false` and `queue: max`.
Because the group is not derived from the workflow display name, workflow
renames do not split release ordering. This serializes the entire
version-producing workflow before build-number generation, retaining pushes in
FIFO order while the queue remains within GitHub's 100-pending-job limit.
Pull-request and non-main runs instead use their unique `github.run_id`; they
are not cancelled at workflow level, so unrelated jobs continue independently.
`build-dev-web` has narrower job-level concurrency keyed by pull-request ref
with `cancel-in-progress: false`. The running deployment completes, while
GitHub retains only the newest pending deployment for that ref and replaces
intermediate pending jobs. Because the group is serialized, an older deployment
cannot finish after a newer one. If the newest build fails, the prior completed
site remains available.

Each `integration-test-shard` has narrower job-level concurrency keyed by
workflow, ref, and matrix ID. Only a superseded pull-request shard is cancelled.
This releases the matching emulator runner without interrupting unrelated PR
jobs or other shard identities.

The Google Play internal-release job uses its shared serialization group with
`cancel-in-progress: false` and `queue: max`. Eligible `main` releases are
therefore retained and published one at a time while the queue remains within
GitHub's limit of 100 pending jobs. Pushes beyond that platform capacity can be
canceled and require an operational response. This remains a defensive second
serialization boundary after whole-pipeline ordering.

### Permissions and secret scope

Workflow permissions are explicitly limited to `contents: read`. Bulk secret
export is prohibited: Firebase and signing material are exposed only through
named, step-scoped environments, and build/deployment tokens remain scoped to
their consuming steps or action inputs. The Google Play service-account JSON
appears only in the publish step. The Play upload action is pinned to reviewed
v1 commit `e738b9dd8f2476ea806d921b64aacd24f34515a5`, resolved from the annotated
v1 tag.

### Canonical integration gate

Retain `integration-test` as the downstream job ID and required-check contract.
It depends on both the complete `integration-test-shard` matrix and an
independent `integration-test-inventory` job, and uses `if: ${{ always() }}`.

Its first step explicitly verifies that both dependency results are `success`.
A failed, cancelled, or skipped shard or inventory job therefore makes
`integration-test` fail rather than skip. This preserves the
branch-protection shape established by ADR-003.

The five-minute `integration-test-inventory` job runs alongside the emulator
shards. It mechanically parses matrix `test_file` entries from the checked-in
workflow and compares their sorted set with discovered
`*_test.dart` files recursively beneath `integration_test/`, excluding
`*_ios_test.dart`. Nested test directories are therefore covered. Any drift
fails independently, and the canonical dependency-result check propagates that
failure into the required check.

When both prerequisites succeed, `integration-test`:

1. downloads all seven shard coverage artifacts;
2. derives expected LCOV names from the matrix `id` entries and verifies that
   exactly those inputs are present;
3. merges them into `coverage/integration.info` with
   `scripts/merge_lcov.dart`;
4. runs the unchanged `scripts/check_integration_coverage.dart`;
5. uploads `coverage/integration.info` as the unchanged
   `coverage-integration-lcov` artifact.

Shard uploads use `if-no-files-found: warn` so upload diagnostics do not
duplicate gate ownership. Missing coverage still fails the workflow at the
canonical exact-inventory check before any merge or coverage-floor evaluation.

`scripts/merge_lcov.dart` already combines line hits using maximum-hit
semantics. The merged result therefore represents whether each production line
was exercised by at least one shard, matching the union semantics used by the
existing aggregate coverage pipeline. Its CLI accepts one or more LCOV inputs,
so a future one-shard matrix remains valid; zero inputs still fail with exit
code 2.

The canonical `integration-test` and downstream `coverage-aggregate` jobs each
have a 15-minute timeout. These bounds contain gate hangs after the longer
emulator work has completed without changing coverage or release contracts.

### Downstream contracts

The following remain unchanged:

- `coverage-aggregate.needs` continues to reference `integration-test`.
- `coverage-aggregate` continues to download `coverage-integration-lcov`.
- The canonical Android integration path remains
  `coverage/integration.info`.
- All integration per-file floors remain unchanged.
- The aggregate global floor remains unchanged.
- The Android internal-release job remains downstream of
  `coverage-aggregate`.

The matrix is the sole maintained source for shard IDs and Android test paths.
Adding or removing an entry point changes its test file and matrix entry; the
parallel drift job discovers filesystem membership, while the canonical gate
derives expected `.info` names from matrix IDs. After that exact inventory is
verified, the merge discovers the approved `coverage/shards/*.info` inputs.

## Consequences

### Positive

- Peak workspace demand on each Android runner is bounded to one native test
  build instead of seven.
- All current test assertions and per-file process-isolation boundaries remain
  intact.
- Existing coverage scripts and downstream artifact contracts are reused.
- A failure identifies the responsible test file directly in the matrix check.
- Additional integration files add runners rather than cumulative native build
  state to one fixed-size workspace.
- Superseded pull-request shards release matching emulator capacity without
  cancelling unrelated PR jobs.
- Every `main` push is ordered before build-number generation and retained
  through both pipeline and release serialization while queue depth remains
  within the 100-job platform limit.
- Read-only workflow permissions, named step-scoped secrets, and the pinned
  Play action reduce permission and supply-chain blast radius.
- The change is confined to the CI/test boundary; production code is untouched.

### Negative

- Seven runners repeat checkout, dependency setup, emulator boot, and the first
  native build. Total compute consumption increases substantially even though
  wall-clock time can decrease through parallelism.
- Superseded pull-request workflows are not cancelled wholesale. Non-emulator
  jobs continue to consume compute. `build-dev-web` completes its running
  deployment and serializes the newest pending deployment; intermediate
  pending deployments may be replaced.
- Concurrent emulator jobs may encounter repository or organization
  concurrency limits. The initial `max-parallel: 3` cap mitigates this.
- Serializing the entire `main` pipeline reduces throughput and can increase
  release latency. A burst can fill either 100-pending-job queue; pushes beyond
  the platform limit can be canceled and require an operational response.
- A shard that exceeds 45 minutes is terminated and fails the canonical gate;
  the bound must be revisited if healthy shards approach it.
- A post-test disk warning below 2 GiB does not fail the shard, but provides a
  stable machine-emitted signal for runner-capacity review.
- The workflow gains a matrix-to-merge handoff and seven intermediate artifacts.
- Workflow parsing couples the inventory checks to the matrix's checked-in YAML
  shape, but avoids a second maintained list of IDs or test paths.
- Firebase configuration is materialized in more runner instances. Each shard
  receives only `FIREBASE_OPTIONS`, scoped to the materialization step; the
  matrix does not multiply access to other repository secrets.

### Neutral

- Stored artifact volume increases slightly because coverage is uploaded once
  per shard and once in canonical merged form. LCOV files are small relative to
  native build outputs and are stored remotely, not on later runner
  workspaces.
- Individual shard check names become visible in addition to the canonical
  required `integration-test` check.
- The job remains sensitive to emulator and hosted-runner availability, but a
  single runner no longer accumulates seven builds.

## Verification and acceptance criteria

The implementation is accepted only when a pull-request workflow run proves:

1. Seven matrix shards start, one for each existing Android integration file.
2. All 25 existing tests pass without editing their assertions.
3. Each shard log contains one integration entry point and no second
   `assembleDebug` for another entry point.
4. Every shard reports numeric post-test available MiB; capacity below
   2,097,152 KB emits `::warning::` without failing solely for low headroom,
   and no shard reaches `No space left on device`.
5. Seven uniquely named shard LCOV artifacts are produced.
6. The canonical `integration-test` job fails if any shard or the independent
   inventory job is unsuccessful.
7. The canonical merge produces `coverage/integration.info`.
8. `scripts/check_integration_coverage.dart` passes with the existing floors.
9. `coverage-aggregate` downloads the canonical artifact and passes with the
   existing aggregate floor.
10. Branch protection continues to require the canonical `integration-test`
    and `coverage-aggregate` checks; matrix checks need not be individually
    configured as required checks.
11. Each shard is bounded by `timeout-minutes: 45`; a missing shard LCOV emits
    an upload warning and then fails the canonical exact-inventory check.
12. `main` push workflows share the repository-local literal group
    `main-release-pipeline` with `cancel-in-progress: false` and `queue: max`,
    and serialize before build-number generation even if the workflow is
    renamed. Pull-request workflows use unique run groups and are not cancelled
    wholesale.
13. The Google Play internal-release concurrency uses `queue: max`; multiple
    eligible `main` releases serialize and no pending release is replaced while
    the queue remains below the 100-pending-job limit.
14. The five-minute `integration-test-inventory` job runs independently of the
    shards, proves the matrix `test_file` set exactly matches discovered
    non-iOS integration tests recursively under `integration_test/`, including
    nested directories, and propagates failure through the canonical required
    check.
15. `scripts/merge_lcov.dart` accepts one valid LCOV input and emits normalized
    output; both no-argument and OUT-only invocations retain exit code 2 and
    create no output.
16. Canonical `integration-test` and `coverage-aggregate` are each bounded by
    `timeout-minutes: 15`.
17. Canonical expected LCOV names are derived from matrix IDs, leaving the
    matrix as the sole maintained source for shard IDs and Android test paths.
18. Job-level shard concurrency is keyed by workflow, ref, and matrix ID and
    cancels only superseded pull-request shards.
19. Workflow permissions are `contents: read`; no bulk secret export remains;
    the Play service-account JSON is referenced only by the publish step.
20. The Google Play upload action is pinned to reviewed v1 commit
    `e738b9dd8f2476ea806d921b64aacd24f34515a5`.
21. Pull-request workflows remain uniquely grouped, while `build-dev-web`
    uses `cancel-in-progress: false`: the running same-ref deployment completes,
    only the newest pending deployment follows, and an older deployment cannot
    finish after a newer one.

Disk observations from the first three successful runs should be retained in
the job logs. Any machine-emitted post-test warning below 2 GiB triggers review
of shard disk telemetry and the runner-size/caching decision; repeated warnings
mean the standard runner no longer provides adequate headroom.

## Rollback

The change is workflow-only and reversible:

1. remove the matrix shard job;
2. restore the seven-file `flutter test` invocation inside `integration-test`;
3. keep the canonical artifact name, coverage path, scripts, floors, and
   `coverage-aggregate` dependency unchanged.

Rollback restores the ADR-002/ADR-003 execution shape but also restores the
known cumulative disk-exhaustion risk. If rollback is required because of
runner-minute or concurrency constraints, use a larger runner as a temporary
capacity measure rather than weakening coverage gates or removing tests.

## Out of scope

- Combining test modules into a shared Dart process.
- Changing integration assertions or coverage floors.
- Downgrading Android integration tests to telemetry.
- Changing production code for testability.
- Changing Android SDK, emulator profile, Flutter version, or plugin versions.
- Refactoring the existing LCOV parser or merge semantics.
- Changing the iOS integration-test job.

## Links

- `docs/adr/ADR-002-phase-7-integration-tests-deferred-coverage.md`
- `docs/adr/ADR-003-phase-8-aggregate-coverage-gate.md`
- `.github/workflows/main.yml`
- `scripts/check_integration_coverage.dart`
- `scripts/check_aggregate_coverage.dart`
- `scripts/merge_lcov.dart`
- Failed integration job:
  `https://github.com/ClubhouseAmit/LivingPositively/actions/runs/30098057012/job/89496922017`
- Downstream aggregate failure:
  `https://github.com/ClubhouseAmit/LivingPositively/actions/runs/30098057012/job/89499928870`
- Prior successful integration job:
  `https://github.com/ClubhouseAmit/LivingPositively/actions/runs/29805535525/job/88555180257`
