# ADR-006: Reduce iOS Integration Test Runtime

- **Status**: accepted
- **Date**: 2026-05-27
- **Deciders**:
- **Tags**: ci, ios, flutter, github-actions, coverage, performance

## Context

ADR-005 introduced the `integration-test-ios` GitHub Actions job to cover
iOS-specific notification paths and feed the aggregate coverage gate. The ADR
expected the macOS runner job to take roughly 6-8 minutes.

The observed run at
`https://github.com/ClubhouseAmit/LivingPositively/actions/runs/26495525512/job/78022724423`
completed `integration-test-ios` in 41m58s. Step timing showed the bottleneck is
native iOS preparation/build work, not Dart test execution:

- `Run iOS integration test`: about 36m41s.
- `pod install`: 282.4s.
- `Running Xcode build`: 1791.8s.
- Actual test execution: about 1 minute for 14 passing tests.

At decision time, the job ran on `macos-26`, disabled Flutter Swift Package
Manager, and used the CocoaPods path. The repository did not track
`ios/Podfile`, so CI allowed Flutter/Xcode project generation and migration work
to happen inside the timed test step. This made the job slower and made native
build outputs harder to cache with stable keys.

The job is also on the critical path: `coverage-aggregate` depends on
`integration-test-ios`, so the slow iOS native build directly lengthens the
feedback loop for every run where the coverage gate is required.

Volatility to contain:

- GitHub macOS runner labels and installed Xcode/iOS SDK versions change over
  time.
- Flutter, FlutterFire, CocoaPods, and plugin support for Swift Package Manager
  are volatile.
- The iOS notification coverage requirement is stable.
- The current iOS test count is not the runtime driver; native dependency
  resolution and Xcode compilation are.

## Decision

Do not split the iOS integration test suite as the first optimization. There is
only one iOS integration test file, and sharding would duplicate the expensive
native build.

Benchmark the runner label first:

1. Try `macos-15` arm64 for `integration-test-ios`.
2. Keep `macos-26` only if the job needs Xcode/iOS 26 APIs or if the benchmark
   proves it is faster.
3. Do not move to Intel as the first option. Try `macos-15-intel` only if logs
   show memory pressure or if the arm64 benchmark remains dominated by native
   compilation despite cache work.
4. Treat `macos-26-intel` as a last resort when both macOS 26 tooling and Intel
   runner resources are required.

Make the iOS build cacheable before adding broader CI changes:

1. Track the generated iOS project inputs needed for a stable CocoaPods build,
   especially `ios/Podfile` and, if reproducible in this project, `ios/Podfile.lock`.
2. Add CocoaPods cache coverage for `ios/Pods` and CocoaPods download caches,
   keyed by runner OS/architecture, Flutter version, Xcode version,
   `pubspec.lock`, and `ios/Podfile.lock`.
3. Cache Xcode `DerivedData` immediately because the measured Xcode build time
   is the dominant cost. Scope this cache by runner OS, runner architecture,
   Xcode version, Flutter/plugin inputs, and iOS project inputs.
4. Keep cache keys scoped to runner architecture and Xcode version; do not share
   native iOS build caches across arm64 and Intel runners, and do not use
   restore-key fallbacks that drop the Xcode scope.
5. Keep `flutter test` on `--no-pub` because `flutter pub get` already ran
   before cache restore and simulator execution.

Do not fabricate `ios/Podfile.lock` on a Windows development machine. The first
green macOS CI run should be used to confirm that the generated lockfile is
stable for this project; if it is stable, commit `ios/Podfile.lock` in the next
CI-only follow-up so CocoaPods resolution becomes deterministic. The iOS job
uploads the generated `ios/Podfile.lock` as an artifact to make that manual
follow-up possible for contributors who do not have local macOS access. Until
then, `hashFiles('ios/Podfile.lock')` is intentionally harmless when the file is
absent, but fresh checkouts may still re-resolve transitive Pods.

Because this job is assumed to run once per day, caching is expected to remain
warm: GitHub Actions evicts caches after more than 7 days without access, and a
daily run refreshes access. Cache size must still be monitored because the
default repository cache quota is finite and large DerivedData entries can evict
more useful caches.

If the optimized job still materially exceeds the expected range, revisit the
quality gate shape rather than further optimizing simulator mechanics. The
fallback decision is to keep a smaller iOS simulator smoke test as scheduled or
nightly coverage evidence, while moving channel-mocked behavioral assertions back
to unit/widget tests where possible.

## Consequences

### Positive

- Targets the measured bottleneck: CocoaPods and Xcode build time.
- Keeps the coverage contract from ADR-005 intact while reducing feedback time.
- Avoids multiplying native build cost through premature sharding.
- Gives runner selection a measurable A/B path instead of relying on label
  assumptions.
- Daily execution cadence should keep dependency caches warm.

### Negative

- Tracking `Podfile` / `Podfile.lock` and adding native caches introduces CI
  maintenance overhead.
- `DerivedData` caching may consume multiple gigabytes and can evict other
  caches if keyed too broadly; cache version bumps may be required if cache
  pressure becomes visible.
- Runner image updates can invalidate Xcode-related caches unexpectedly.
- `macos-15` may not remain valid if dependencies begin requiring newer Xcode
  or iOS SDK symbols.

### Neutral

- This ADR does not change production code.
- This ADR does not change the coverage floors.
- This ADR does not decide whether the iOS integration job should remain
  required on every PR; that decision is deferred unless optimization fails.

## Links

- ADR-005: `docs/adr/ADR-005-phase-10-macos-runner-ios-and-web-coverage.md`
- Workflow: `.github/workflows/main.yml`
- Coverage status: `docs/coverage-status.md`
