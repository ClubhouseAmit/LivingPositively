# PR 309 Review Findings Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development to implement this plan task-by-task.

**Goal:** Rebase PR #309 onto the current `feature/basic-fcm-setup` tip and ensure reset failures cannot leave the confirmation dialog permanently locked.

**Architecture:** Preserve the existing FCM, authentication, and settings boundaries. Replay only the follow-up commit range onto the rewritten parent because the old and new parent trees are identical for the affected product files. Keep reset error recovery local to the dialog callback: asynchronous cleanup may fail, but modal controls must always return to an interactive state.

**Tech Stack:** Git, Flutter/Dart widget tests, GetIt test services.

---

### Task 1: Rebuild the stacked branch

**Files:**
- Preserve: `coverage/lcov.info`
- Rebase: commits after `d927f48606ec3eb6789e14fdc22cc90fefbec5a1`

1. Stash only `coverage/lcov.info`.
2. Run `git rebase --onto origin/feature/basic-fcm-setup d927f48606ec3eb6789e14fdc22cc90fefbec5a1 codex/pr-273-fcm-followups`.
3. Verify `git merge-tree --write-tree origin/feature/basic-fcm-setup HEAD` reports no conflicts.
4. Restore the coverage stash and confirm it remains the only pre-existing local edit.

### Task 2: Reproduce the reset modal lock

**Files:**
- Modify: `test/UserSettings/UserSettings_interactions_test.dart`

1. Add an image-picker test double whose `deleteImages()` throws.
2. Add a widget test that starts reset on an unsupported platform, observes the cleanup exception, and asserts the dialog controls become interactive again.
3. Run `flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart --plain-name "reset confirmation regains controls when cleanup throws"`.
4. Verify RED: the spinner remains and both dialog buttons stay disabled.

### Task 3: Restore modal state on every completion path

**Files:**
- Modify: `lib/pages/UserSettings.dart:692-707`
- Test: `test/UserSettings/UserSettings_interactions_test.dart`

1. Wrap `await resetData(userInfoProvider)` in `try/finally`.
2. In `finally`, restore `isResetting` when the dialog context is still mounted.
3. Re-run the focused test and verify GREEN.
4. Run the complete `UserSettings_interactions_test.dart` file.

### Task 4: Verify the rebased PR

1. Run `npm --prefix functions test`.
2. Run the focused FCM, settings, and auth Flutter suites.
3. Run `flutter analyze --no-pub` and compare warnings with the known generated-mock baseline.
4. Run `git diff --check origin/feature/basic-fcm-setup...HEAD`.
5. Verify the PR is mergeable after publishing the rebased branch.
