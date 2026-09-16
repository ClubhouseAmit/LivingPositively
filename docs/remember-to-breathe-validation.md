# Remember to Breathe validation

Use Flutter 3.44.0 (Dart 3.12.0), matching CI. Run focused tests under
`test/features/remember_to_breathe`, then the full unit/widget suite with
coverage and existing coverage scripts. The Android integration shard is
`integration_test/remember_to_breathe_test.dart`.

## Device and browser walkthrough

1. Open the home menu and choose Remember to Breathe. Check onboarding, expanded
   information, and the attribution. Repeat in English, Hebrew, and Arabic.
2. Choose Quick Start, skip the rating, and complete eight Basic cycles. No
   duration countdown is displayed. Each inhale/exhale is three seconds.
3. Run Box and check four-second inhale, hold, exhale, hold. For Custom, configure
   background and both durations. Skip each step once and verify the prior
   choice remains. Hold measurement clamps to 3-9 seconds; a scrolling gesture
   over the measurement control must not change the duration.
4. During Custom, change each duration and verify it starts with the next matching
   phase. Hide/show the circle and text. Hide/show secondary controls. Pause,
   continue, restart, and stop early. Back and app backgrounding pause practice.
5. While paused, tap the actual SOS button. Emergency navigation must work
   immediately, with no modal barrier, and must not be hidden by a later callback.
6. Select pre/post ratings and reload history. Check timestamp, pattern, completed
   cycles, and both values. Skipped ratings say not recorded. Equal or higher
   post-ratings are displayed neutrally.
7. Pick a personal photo, finish customization, and reopen the feature/app. The
   photo remains. Cancel the picker and try an unsupported or oversized file;
   the previous selection remains. Replace it and confirm only one personal
   background is retained. Repeat photo import and reload in Chrome.
8. Reset app data using a disposable test profile. Breathing history, settings,
   and retained photo must be removed. Automated tests also cover delayed writes
   crossing the reset boundary.
9. Use a narrow phone and enlarged text in light/dark themes. Check readable
   labels and controls over all backgrounds, including a bright personal photo.

## Failure checks

Automated store/view-model/widget tests inject storage failure and corrupt
snapshots. A failed result remains retryable; ordinary exit requires saved data
or an explicit Leave without saving action. Retries preserve the latest rating
and do not create duplicate sessions. Unreadable data requires confirmed recovery.

The native integration test exercises real SharedPreferences and actual Basic
session timing. It preserves/restores any pre-existing breathing snapshot.
Audio and video are intentionally outside this PR and have no placeholder controls.

## Recorded verification

- Flutter 3.44.0 / Dart 3.12.0: full analysis passed.
- Full unit/widget suite: 1,562 passed, six existing skips. The separate
  token-enabled AnalyticsService run passed all six tests. The subsequently
  retained self-contained browser-flow harness passed its three localized
  production-widget scenarios on the VM.
- Merged unit coverage: 13,609 / 14,964 lines (90.94%). The existing 85% unit
  floor and tier checks passed. Unit coverage plus the local breathing Android
  integration run reaches 13,611 / 14,964 lines (90.96%) and passes the unchanged
  89% aggregate gate. CI additionally includes all existing Android shards.
- The integration test passed on `emulator-5554` (Android 17 / API 37), including
  a real-time eight-cycle Basic session, pause/resume, both ratings, and native
  preferences reload. The test restores any pre-existing breathing snapshot.
- The four self-contained Chrome test files compiled, but local headless Chrome
  stalled before executing tests on bounded retries. Browser UI automation also
  timed out, so local Chrome runtime behavior remains unverified. The focused
  browser telemetry step runs the production flows, view-model rules, model
  validation, and image codecs separately from the legacy web suite's
  `test_support` import limitation. The browser flow harness uses mocked
  preferences and a cancelled picker; it does not assert browser localStorage
  persistence or actual file-picker interaction.
- Independent review covered persistence reset races, image corruption,
  gesture cancellation, navigation, save retries, and CI inventory. Findings
  were fixed and regression-tested.
- [Production-widget captures](images/remember-to-breathe/README.md) document
  the landing page, Hebrew pause state, and Arabic customization. They are
  explicitly scoped to the breathing page body, without the surrounding Menu.
- Android CI runs the dedicated breathing shard; iOS CI includes the same
  platform-neutral test in its existing telemetry job.
