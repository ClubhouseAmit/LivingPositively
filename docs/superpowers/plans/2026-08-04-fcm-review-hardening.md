# FCM Review Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve the final PR #309 reliability, observability, validation, UI, and test-seam findings without weakening the approved privacy-first reset fence.

**Architecture:** Keep all changes inside the existing Flutter FCM client, Cloud Functions scheduler/mutation boundary, service locator, and decision record. Corrupt mutation state is recoverable through an authenticated versioned mutation; `resetFence` remains the guard that rejects cancellation while a delivery permit is active. Scheduler telemetry becomes structured JSON, while the canonical Firestore rules remain an explicit external rollout gate because this repository does not own the production rules source.

**Tech Stack:** Flutter/Dart, GetIt, fake_cloud_firestore, Firebase Auth/Firestore, TypeScript, Firebase Functions v7, Node test runner.

## Global Constraints

- Preserve account-wide, privacy-first, all-or-nothing reset semantics.
- Never allow a local-only reset after remote reminder cleanup failure.
- Never treat corrupt mutation state as writable by ordinary registration or cancellation.
- Do not create `firestore.rules` or add a `firebase.json` rules target without the canonical production policy and owner approval.
- Do not add dependencies or architectural layers.
- Do not stage or commit `coverage/lcov.info`.
- Write each regression test before its production change and record the expected red result.

---

### Task 1: Reset-only repair for corrupt mutation versions

**Files:**
- Modify: `functions/src/notification_mutation.ts`
- Modify: `functions/src/notification_validation.test.ts`
- Modify: `functions/src/index.ts`

**Interfaces:**
- Produces: `storedNotificationMutationVersionDecision(value)` returning `use` or `repair`.
- Consumes: existing `expectedMutationVersion`, active delivery permit, and `NotificationMutationConflictError` behavior. `resetFence` remains an endpoint-level guard for active delivery permits.

- [ ] **Step 1: Write the failing decision tests**

Add literal assertions proving invalid state repairs to the current version zero:

```ts
assert.deepEqual(
  storedNotificationMutationVersionDecision("corrupt"),
  { kind: "repair" },
);
assert.deepEqual(
  storedNotificationMutationVersionDecision(7),
  { kind: "use", version: 7 },
);
```

- [ ] **Step 2: Run the focused Functions test and verify RED**

Run: `npm test`

Expected: TypeScript build fails because `storedNotificationMutationVersionDecision` is not exported yet.

- [ ] **Step 3: Implement the minimal decision and handler behavior**

Add the pure decision in `notification_mutation.ts`. Versioned mutations repair an invalid stored version to zero after the active-permit check, so the client can recover from a corrupt state instead of receiving an unrecoverable 409. `resetFence` remains the endpoint-level request for active-delivery-permit rejection; it is not part of version repair authorization. In `getNotificationMutationVersion`, return zero for an invalid stored version and emit a structured warning.

- [ ] **Step 4: Run `npm test` and verify GREEN**

Expected: all Functions tests pass, including the reset-only decision assertions.

### Task 2: Observable recovery-window clamping and structured scheduler metrics

**Files:**
- Create: `functions/src/scheduler_observability.ts`
- Modify: `functions/src/scheduled_delivery.test.ts`
- Modify: `functions/src/index.ts`

**Interfaces:**
- Produces: `schedulerRecoveryWindow(scheduleTime, lastProcessedAt)` with `requestedCandidateMinutes`, `processedCandidateMinutes`, and `wasClamped`.
- Produces: `scheduledNotificationSummary(counts, window)` with real numeric `claimFailed` and recovery fields.

- [ ] **Step 1: Write failing recovery metadata and summary tests**

Use a four-hour stale checkpoint and assert the hand-derived result:

```ts
assert.deepEqual(
  schedulerRecoveryWindow(
    new Date("2026-01-01T20:59:00.000Z"),
    new Date("2026-01-01T16:59:00.000Z"),
  ),
  {
    requestedCandidateMinutes: 240,
    processedCandidateMinutes: 121,
    wasClamped: true,
  },
);
```

Build a summary with `claimFailed: 2` and assert that `claimFailed`, `recoveryCandidateMinutes`, `requestedRecoveryCandidateMinutes`, and `recoveryClamped` are numeric/boolean JSON fields rather than embedded text.

- [ ] **Step 2: Run `npm test` and verify RED**

Expected: TypeScript build fails because the internal observability module does not exist.

- [ ] **Step 3: Implement recovery metadata and structured logging**

Use `import * as logger from "firebase-functions/logger"`. Generate delivery candidates from `processedCandidateMinutes`. When `wasClamped` is true, emit `logger.warn("processScheduledNotifications recovery window clamped", {...})`. Replace the interpolated `console.log` with:

```ts
logger.info(
  "processScheduledNotifications",
  scheduledNotificationSummary(counts, recoveryWindow),
);
```

Remove the zero-candidate early return so checkpoint advancement and the zero-valued structured summary still occur after a clamped query with no matching schedules.

- [ ] **Step 4: Run `npm test` and verify GREEN**

Expected: all Functions tests pass and TypeScript accepts the Firebase logger import.

### Task 3: Restrict persisted notification locales

**Files:**
- Modify: `functions/src/notification_validation.ts`
- Modify: `functions/src/notification_validation.test.ts`
- Modify: `functions/src/index.ts`

**Interfaces:**
- Produces: `isValidNotificationLocale(value): value is "he" | "ar" | "en"`.

- [ ] **Step 1: Write the failing locale test**

```ts
assert.equal(isValidNotificationLocale("he"), true);
assert.equal(isValidNotificationLocale("ar"), true);
assert.equal(isValidNotificationLocale("en"), true);
assert.equal(isValidNotificationLocale("constructor"), false);
assert.equal(isValidNotificationLocale("toString"), false);
assert.equal(isValidNotificationLocale("__proto__"), false);
```

- [ ] **Step 2: Run `npm test` and verify RED**

Expected: TypeScript build fails because `isValidNotificationLocale` is missing.

- [ ] **Step 3: Implement the minimal validator**

Accept only `he`, `ar`, and `en` in `registerNotification`. Apply the same predicate while reading schedule documents so legacy or directly written invalid values never become property lookups on `quotesCollections`.

- [ ] **Step 4: Run `npm test` and verify GREEN**

Expected: all Functions tests pass.

### Task 4: Make reset cancellation errors visible

**Files:**
- Modify: `test/UserSettings/UserSettings_interactions_test.dart`
- Modify: `lib/pages/UserSettings.dart`

**Interfaces:**
- Preserves: `resetData` aborts local reset when remote cancellation fails.
- Changes: the confirmation dialog closes before the failure SnackBar is shown.

- [ ] **Step 1: Strengthen the existing failure widget test**

After the failed reset settles, assert:

```dart
expect(find.byType(Dialog), findsNothing);
expect(find.byType(ModalBarrier), findsNothing);
expect(find.byType(SnackBar), findsOneWidget);
```

- [ ] **Step 2: Run the focused widget test and verify RED**

Run: `flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart`

Expected: the dialog and modal barrier remain present.

- [ ] **Step 3: Implement the minimal UI change**

When cancellation returns false and the state is mounted, pop the confirmation dialog before calling `ScaffoldMessenger.maybeOf(context)?.showSnackBar(...)`. Keep local data and navigation unchanged.

- [ ] **Step 4: Run the focused widget test and verify GREEN**

Expected: the dialog is gone, the SnackBar is visible on the page route, and reset data remains intact.

### Task 5: Replace the mutable AuthService test hook with the existing locator

**Files:**
- Modify: `test/auth/auth_page_interactions_test.dart`
- Modify: `lib/util/Firebase/auth_service.dart`
- Modify: `lib/iFx/service_locator.dart`

**Interfaces:**
- Consumes: `GetIt.instance<FirebaseFirestore>()` registered by production and tests.
- Removes: `AuthService.saveUserToFirestoreForTesting`.

- [ ] **Step 1: Replace the test hook with a real in-memory Firestore assertion**

Register `FakeFirebaseFirestore` as `FirebaseFirestore`, call `AuthService.saveUserToFirestore`, then read `users/uid-123` and assert the persisted email/display name/provider fields. Adapt the disposed-auth-screen test to use the registered fake instead of the mutable static.

- [ ] **Step 2: Run the focused auth test and verify RED**

Run: `flutter test --no-pub test/auth/auth_page_interactions_test.dart`

Expected: persistence still reaches `FirebaseFirestore.instance` rather than the registered fake.

- [ ] **Step 3: Implement locator-backed persistence**

Register `FirebaseFirestore` lazily in `setupLocator` and read it from GetIt in `AuthService.saveUserToFirestore`. Remove the mutable static and `visibleForTesting` import.

- [ ] **Step 4: Run the focused auth test and verify GREEN**

Expected: the real AuthService persistence behavior writes to the in-memory Firestore and the disposal regression remains green.

### Task 6: Unify legacy-migration failure reporting

**Files:**
- Modify: `test/Firebase/fcm_scheduled_notification_service_test.dart`
- Modify: `lib/util/Firebase/fcm_scheduled_notification_service.dart`
- Modify: `lib/main.dart`
- Modify: `lib/pages/auth/auth_page.dart`

**Interfaces:**
- Produces: `migrateLegacyDefaultReminderWithReporting({required UserInformation userInformation})`.
- Consumes: the existing `IncidentLoggerService` locator registration with debug fallback when absent.

- [ ] **Step 1: Write the failing reporting test**

Configure persistent-memory migration-marker reads to throw, register a recording `IncidentLoggerService`, call `migrateLegacyDefaultReminderWithReporting`, and assert the real logger received the same exception and stack trace without the error escaping.

- [ ] **Step 2: Run the focused FCM service test and verify RED**

Run: `flutter test --no-pub test/Firebase/fcm_scheduled_notification_service_test.dart`

Expected: compile failure because the shared wrapper is missing.

- [ ] **Step 3: Implement and adopt the shared wrapper**

The wrapper awaits `migrateLegacyDefaultReminder`, catches `(error, stackTrace)`, awaits `IncidentLoggerService.captureLog` when registered, and otherwise emits the existing debug fallback. Both startup and auth success call this wrapper with `unawaited(...)`; remove their duplicate `catchError` blocks.

- [ ] **Step 4: Run the focused FCM and auth tests and verify GREEN**

Expected: both suites pass and both consumers use the same reporting policy.

### Task 7: Align the operational decision record

**Files:**
- Modify: `docs/plans/2026-07-31-pr-273-fcm-remaining-work.md`

**Interfaces:**
- Documents: reset-only corrupt-state repair, structured scheduler field names, clamp-loss warning, and the existing hard rules gate.

- [ ] **Step 1: Update the recovery operations note**

Record `claimFailed`, `recoveryClamped`, `recoveryCandidateMinutes`, and `requestedRecoveryCandidateMinutes` as structured Cloud Logging fields. State that a gap beyond 120 lookback minutes drops older intended minutes by design and always emits a clamp warning before advancing the checkpoint.

- [ ] **Step 2: Update reset-fence recovery semantics**

State that malformed stored versions are returned to the client as zero only to enable authenticated reset-fenced repair; ordinary register/cancel remains blocked, and active delivery permits remain authoritative.

- [ ] **Step 3: Reconfirm the rules gate without creating a rules file**

Keep rollout blocked until the canonical rules repository/file/deployment target, reviewed deny diff, and authenticated emulator evidence are attached. Explicitly state that this is pre-deployment work, not a post-merge follow-up.

### Task 8: Verification and publication

**Files:**
- Verify all modified files; never stage `coverage/lcov.info`.

- [ ] **Step 1: Run focused and full verification**

Run:

```text
npm --prefix functions test
npm --prefix functions exec tsc -- --noEmit
flutter test --coverage --reporter=expanded
flutter analyze --no-pub
git diff --check
```

Expected: 0 Functions failures, 0 Flutter failures, TypeScript exit 0, only the documented generated-mock analyzer warning baseline, and no whitespace errors.

- [ ] **Step 2: Request independent review**

The reviewer must inspect privacy/reset semantics, scheduler checkpoint behavior, structured metric field names, the removal of mutable production test state, and the absence of `coverage/lcov.info` from the intended commit.

- [ ] **Step 3: Commit and push the exact reviewed files**

Stage explicit paths only and commit with `Address FCM reliability review findings`. Push `codex/pr-273-fcm-followups` without force.

- [ ] **Step 4: Update PR #309**

Update the validation count, rename the PR-body follow-up section to hard rollout gates, and report the handled decisions. Resolve only actual unresolved GitHub threads; if GitHub reports zero unresolved threads, do not create artificial inline replies.
