# FCM Reset Review Follow-ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep signed-in reset available when no remote reminder can exist, prevent queued migration from restoring a cancelled reminder, and make generated/local rollout records accurate.

**Architecture:** `UserSettings.resetData` remains the owner of the reset policy. It invokes remote cancellation only for a non-anonymous user whose local default reminder proves that a mobile remote schedule exists. Migration re-reads that preference inside its existing serial queue; no new client service or scheduler boundary is introduced.

**Tech Stack:** Flutter/Dart, Firebase Functions TypeScript, Flutter l10n.

## Global Constraints

- Preserve remote cancellation before local reset for an authenticated Android/iOS user with a default reminder.
- A web or desktop reset, and any authenticated reset with no stored reminder, must not make a network request.
- Do not add a new Firestore rules source or test-only public UI API.

---

### Task 1: Platform- and reminder-aware reset

**Files:**
- Modify: `lib/pages/UserSettings.dart`
- Modify: `test/UserSettings/UserSettings_interactions_test.dart`

- [x] **Step 1: Write failing widget tests**

```dart
expect(cancelCalls, 0);
expect(find.byType(FirstPage), findsOneWidget);
```

Cover a signed-in unsupported platform with a local reminder and a signed-in Android user without a local reminder. Both must reset without invoking the injected cancellation callback.

- [x] **Step 2: Run the focused widget test**

Run: `flutter test test/UserSettings/UserSettings_interactions_test.dart`

Expected: both reset flows currently abort or invoke cancellation.

- [x] **Step 3: Implement the narrow guard**

```dart
if (firebaseUser != null &&
    !firebaseUser.isAnonymous &&
    userInfo.getNotificationPreference('default') != null &&
    FcmService.supportsReminderSettings()) {
  // cancel remote reminder and abort reset only on cancellation failure
}
```

- [x] **Step 4: Re-run the focused widget test**

Run: `flutter test test/UserSettings/UserSettings_interactions_test.dart`

Expected: reset still aborts on a real mobile cancellation failure, and succeeds in both no-remote-schedule cases.

### Task 2: Queued migration and generated localization cleanup

**Files:**
- Modify: `lib/util/Firebase/fcm_scheduled_notification_service.dart`
- Modify: `test/Firebase/fcm_scheduled_notification_service_test.dart`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_he.dart`
- Modify: `lib/l10n/app_localizations_ar.dart`

- [x] **Step 1: Write a cancellation-before-migration regression test**

```dart
expect(requests, ['/cancelNotification']);
expect(memory.stored.containsKey('fcmDefaultReminderMigrated'), isFalse);
```

Queue a cancel request first, start migration while cancellation is in flight, complete cancellation, then assert migration sends no registration request.

- [x] **Step 2: Run the focused service test**

Run: `flutter test test/Firebase/fcm_scheduled_notification_service_test.dart`

Expected: the captured preference causes a registration after cancellation.

- [x] **Step 3: Move preference lookup into `_enqueue` and remove stale generated getters**

```dart
await _enqueue(() async {
  final preference = userInfo.getNotificationPreference('default');
  if (preference == null || _legacyMigrationDisabled) return;
  // read marker and register only this current preference
});
```

Remove the three obsolete sign-out declarations and locale implementations absent from every ARB.

- [x] **Step 4: Run l10n and focused verification**

Run: `flutter gen-l10n && flutter test test/Firebase/fcm_scheduled_notification_service_test.dart`

Expected: no generated sign-out getters remain and the migration regression passes.

### Task 3: Scheduler/documentation nits and validation

**Files:**
- Modify: `functions/src/index.ts`
- Modify: `functions/src/notification_provisioning.ts`
- Modify: `docs/plans/2026-07-31-pr-273-fcm-remaining-work.md`
- Modify: `functions/src/scheduled_delivery.test.ts`

- [x] **Step 1: Add a failing scheduler invariant test**

```ts
assert.throws(() => scheduledNotificationQueryPlan([]), /at least one/);
```

- [x] **Step 2: Implement bounded candidate generation and the invariant**

Make `israelLocalDeliveryCandidatesSince` request only the needed candidate count, reject an empty query plan, remove the duplicate migration-disabled branch, and document why ARB scanning detects conflicting duplicate quote keys before `JSON.parse` loses them.

- [x] **Step 3: Make TTL and deny rules deployment gates**

Move their completion ahead of Functions deployment in the decision record; retain the exact external handoff because the repository has no canonical Firestore rules target.

- [x] **Step 4: Run full validation and commit**

Run: `npm --prefix functions test && flutter test --coverage --reporter=expanded && flutter analyze --no-pub && git diff --check`

Expected: server and Flutter suites pass; report separately any analyzer warnings inherited from generated mocks in the parent branch.
