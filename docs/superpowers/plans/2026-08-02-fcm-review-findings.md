# FCM Review Findings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent newly edited past reminders from being delivered immediately, retain bounded scheduler recovery without steady-state read amplification, and make notification failures visible and observable.

**Architecture:** The scheduler remains the sole server-side delivery boundary. A private scheduler checkpoint narrows the candidate set to the elapsed interval (maximum 120 minutes); a one-minute interval retains the existing exact hour-and-minute query. A schedule's server-maintained `updatedAt` excludes intended times that precede its latest edit. Client migration stays best-effort and is decoupled from successful authentication.

**Tech Stack:** Firebase Functions v2, Firestore Admin SDK, TypeScript node:test, Flutter/Dart, Flutter l10n.

## Global Constraints

- Preserve the approved two-hour, best-effort catch-up bound and at-most-once delivery key.
- Do not retry an FCM delivery after its Firestore claim.
- Do not add client Firestore access for scheduler, delivery, or checkpoint records.
- Keep all user-facing reset failure text localized in English, Hebrew, and Arabic.

---

### Task 1: Scheduler interval, edit guard, and delivery observability

**Files:**
- Modify: `functions/src/index.ts`
- Modify: `functions/src/scheduled_delivery.test.ts`

**Interfaces:**
- Produces `israelLocalDeliveryCandidatesSince(scheduleTime, lastProcessedAt)` with an inclusive current minute and a 120-minute cap.
- Produces `ScheduledDeliveryResult = "sent" | "failed" | "alreadyClaimed" | "claimFailed"`.

- [x] **Step 1: Write failing TypeScript tests**

```ts
assert.deepEqual(
  israelLocalDeliveryCandidatesSince(now, new Date(now.getTime() - 60_000))
    .map((candidate) => candidate.intendedTime),
  ["22:59"],
);
assert.equal(await claimAndSendScheduledDelivery(delivery, failingWriter, sender), "claimFailed");
```

- [x] **Step 2: Run the focused test file**

Run: `npm --prefix functions test -- --test-name-pattern="scheduled notification delivery"`

Expected: failing assertions for the new interval helper and claim result.

- [x] **Step 3: Implement the interval and guards**

```ts
const updatedAt = doc.data().updatedAt as FirebaseFirestore.Timestamp | undefined;
if (updatedAt && candidate.intendedAt.getTime() < updatedAt.toMillis()) return [];
```

Use `hour ==` plus `minute ==` for one candidate; use the current hour-in query only for a genuine multi-minute recovery interval. Write the checkpoint after the invocation finishes. Catch claim and status-write errors, distinguish claim failures, and log their delivery keys without changing a successful-send result.

- [x] **Step 4: Run Functions verification**

Run: `npm --prefix functions test`

Expected: all notification provisioning, validation, and scheduler tests pass.

### Task 2: Authentication, migration serialization, and reset feedback

**Files:**
- Modify: `lib/util/Firebase/fcm_scheduled_notification_service.dart`
- Modify: `lib/pages/auth/auth_page.dart`
- Modify: `lib/main.dart`
- Modify: `lib/pages/UserSettings.dart`
- Modify: `test/Firebase/fcm_scheduled_notification_service_test.dart`
- Modify: `test/UserSettings/UserSettings_interactions_test.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_he.arb`
- Modify: `lib/l10n/app_ar.arb`

**Interfaces:**
- Migration reads its marker inside `_enqueue` and serializes concurrent startup/sign-in calls.
- Successful authentication updates identity before starting non-blocking migration.

- [x] **Step 1: Write failing Flutter tests**

```dart
expect(find.byType(SnackBar), findsOneWidget);
expect(find.text(appLocale.resetReminderCancellationFailed), findsOneWidget);
```

Add a migration race test that starts two migrations before the marker read completes and expects one registration POST.

- [x] **Step 2: Run focused Flutter tests**

Run: `flutter test test/Firebase/fcm_scheduled_notification_service_test.dart test/UserSettings/UserSettings_interactions_test.dart`

Expected: the reset feedback and duplicate-migration assertions fail.

- [x] **Step 3: Implement the client fixes**

```dart
unawaited(
  FcmScheduledNotificationService.migrateLegacyDefaultReminder(
    userInformation: userInfo,
  ).catchError((Object error, StackTrace stackTrace) {
    debugPrint('Legacy reminder migration failed: $error');
  }),
);
```

Move identity updates ahead of this non-blocking migration, attach equivalent error handling at bootstrap, show the localized reset failure SnackBar, and move the migration-marker read into the queued operation.

- [x] **Step 4: Regenerate l10n and run focused tests**

Run: `flutter gen-l10n && flutter test test/Firebase/fcm_scheduled_notification_service_test.dart test/UserSettings/UserSettings_interactions_test.dart`

Expected: generated localizations compile and focused tests pass.

### Task 3: Security and operational record

**Files:**
- Modify: `docs/plans/2026-07-31-pr-273-fcm-remaining-work.md`
- Modify: `firebase.json` only if an existing Firestore-rule deployment target is found.

**Interfaces:**
- Documents `notification_deliveries` and `notification_scheduler_state` as Admin-SDK-only collections and records the exact deny rule that must be deployed.

- [x] **Step 1: Restore the rules record**

```rules
match /notification_deliveries/{deliveryId} { allow read, write: if false; }
match /notification_scheduler_state/{stateId} { allow read, write: if false; }
```

Do not introduce a repository-wide Firestore rules file without an existing deployment configuration because it would alter unrelated production data access.

- [x] **Step 2: Verify documentation and diff hygiene**

Run: `git diff --check && rg -n "notification_deliveries|notification_scheduler_state" docs firebase.json`

Expected: no whitespace errors and explicit Admin-SDK-only documentation for both collections.

### Task 4: Full verification and review response

**Files:**
- Modify: no production files beyond Tasks 1-3.

- [x] **Step 1: Run all local checks**

Run: `flutter test --coverage --reporter=expanded && flutter analyze --no-pub && npm --prefix functions test && git diff --check`

Expected: Flutter tests and Functions tests pass; report separately any analyzer warnings inherited unchanged from the base branch.

- [x] **Step 2: Commit the scoped fix**

```bash
git add functions/src/index.ts functions/src/scheduled_delivery.test.ts lib test docs lib/l10n
git commit -m "Fix FCM scheduling review findings"
```

- [x] **Step 3: Reply to the review**

State the completed fixes and explain that a deployable Firestore rules file was not invented because this repository has no current rules target; the required deny policy is now documented for the production configuration owner.
