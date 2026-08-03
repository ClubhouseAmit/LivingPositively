# FCM Privacy-First Review Follow-ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (\`- [ ]\`) syntax for tracking.

**Goal:** Preserve privacy-first account-wide reset while bounding client/server work, preventing repeated reset requests, and adding regression coverage for reviewed FCM paths.

**Architecture:** The remote schedule remains authoritative: supported mobile reset deletes \`default\` before local data is cleared, and any failed or timed-out cancellation keeps local state intact. The client retains its serialized queue but bounds token and HTTP work so a stuck request releases later work. The scheduler retains its all-or-nothing checkpoint; resource limits and bounded send batches contain each invocation without creating a partial-checkpoint protocol.

**Tech Stack:** Flutter/Dart, Firebase Auth, http, Firebase Functions v2/TypeScript, Node test runner, Firestore.

## Global Constraints

- Reset remains privacy-first: non-anonymous Android/iOS users do not locally reset unless remote \`default\` cancellation succeeds.
- No offline reset escape hatch or persisted cancellation intent is introduced.
- Keep the scheduler checkpoint all-or-nothing; do not add per-minute checkpoint advancement.
- Keep at-most-once claims and one send attempt per claimed delivery.
- Do not add dependencies, public UI test callbacks, or a new Functions orchestration test seam.
- ARB controls generated \`inspirationalQuotesNo<N>\` content only.
- Treat Firestore TTL and deny rules as deployment gates.

---

### Task 1: Bound FCM client operations and release the serialized queue

**Files:**

- Modify: \`lib/util/Firebase/fcm_scheduled_notification_service.dart:22-290\`
- Test: \`test/Firebase/fcm_scheduled_notification_service_test.dart\`

**Interfaces:**

- Consumes: \`NotificationHttpPost\`, injected token providers, and the existing \`_enqueue\` queue.
- Produces: \`registerNotification\`, \`cancelNotification\`, and \`cancelDefaultForReset\` continue returning \`Future<bool>\`; missing token, timeout, exception, or non-200 results in \`false\`.

- [x] **Step 1: Write the failing queue-timeout regression**

Add \`a timed out operation releases the serialized notification queue\`. On Android, start a registration with an injected post whose \`Completer<http.Response>\` never completes, then queue cancellation with an immediate 200 response. Advance the widget clock by 15 seconds. Assert registration is false, cancellation is true, and the saved preference is removed. It fails before implementation because the first operation never releases the queue.

~~~dart
final registering = FcmScheduledNotificationService.registerNotification(
  userInformation: user,
  typeId: 'default', hour: 9, minute: 30,
  idTokenProvider: () async => 'token-123',
  post: (_, {headers, body, encoding}) => stalledPost.future,
);
final cancelling = FcmScheduledNotificationService.cancelNotification(
  userInformation: user, typeId: 'default',
  idTokenProvider: () async => 'token-123',
  post: (_, {headers, body, encoding}) async => http.Response('{}', 200),
);
await tester.pump(const Duration(seconds: 15));
expect(await registering, isFalse);
expect(await cancelling, isTrue);
~~~

- [x] **Step 2: Run the focused regression and observe its expected failure**

Run: \`flutter test --no-pub test/Firebase/fcm_scheduled_notification_service_test.dart --plain-name "a timed out operation releases the serialized notification queue"\`

Expected: failure because cancellation remains queued behind the stalled request.

- [x] **Step 3: Implement the minimal deadline**

Define a private 15-second duration. In both private register/cancel paths, move token acquisition into the existing try/catch and apply that deadline to the token-provider call and the HTTP post. Keep the existing false result for every failure and do not change queue ordering.

~~~dart
try {
  final idToken =
      await (idTokenProvider ?? _getIdToken)().timeout(_networkTimeout);
  if (idToken == null) return false;
  final response =
      await (post ?? http.post)(...).timeout(_networkTimeout);
  // Retain existing 200/non-200 handling.
} catch (error) {
  _log('cancelNotification error: $error');
  return false;
}
~~~

- [x] **Step 4: Verify the whole FCM service suite**

Run: \`flutter test --no-pub test/Firebase/fcm_scheduled_notification_service_test.dart\`

Expected: pass, including the new queue deadline regression.

- [x] **Step 5: Commit**

~~~powershell
git add lib/util/Firebase/fcm_scheduled_notification_service.dart test/Firebase/fcm_scheduled_notification_service_test.dart
git commit -m "Bound FCM notification operations"
~~~

### Task 2: Make reset visibly single-flight without relaxing its gate

**Files:**

- Modify: \`lib/pages/UserSettings.dart:248-320,620-703\`
- Test: \`test/UserSettings/UserSettings_interactions_test.dart\`

**Interfaces:**

- Consumes: \`cancelDefaultForReset\`'s existing boolean.
- Produces: the reset confirmation dialog disables both actions and renders progress while one attempt is pending; failed cancellation leaves settings and navigation intact and shows the existing localized message.

- [x] **Step 1: Write the failing reset-dialog regression**

Add \`reset confirmation disables repeat taps while remote cancellation is pending\`. Configure a non-anonymous Android user whose \`getIdToken\` returns a \`Completer<String?>\`. After Confirm, assert one \`CircularProgressIndicator\`, both dialog buttons have null \`onPressed\`, and the token was requested once. Complete it with null, settle, then assert UserSettings remains, FirstPage is absent, and the failure snackbar exists. It fails now because Confirm remains enabled and no progress state exists.

- [x] **Step 2: Run the focused test and confirm the missing pending state**

Run: \`flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart --plain-name "reset confirmation disables repeat taps while remote cancellation is pending"\`

Expected: failure on absent progress state/enabled action.

- [x] **Step 3: Implement dialog-local state**

Wrap the current dialog body with \`StatefulBuilder\`. Confirm marks local \`isResetting\` before awaiting \`resetData\`; while true, Close/Confirm are disabled and Confirm displays a compact progress indicator. Restore local dialog state only if its context is mounted. Do not change resetData's cancellation-failure branch or identity restoration.

~~~dart
onPressed: isResetting ? null : () async {
  setDialogState(() => isResetting = true);
  await resetData(userInfoProvider);
  if (dialogContext.mounted) {
    setDialogState(() => isResetting = false);
  }
}
~~~

- [x] **Step 4: Verify the UserSettings suite**

Run: \`flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart\`

Expected: pass; failed remote cancellation remains a hard stop.

- [x] **Step 5: Commit**

~~~powershell
git add lib/pages/UserSettings.dart test/UserSettings/UserSettings_interactions_test.dart
git commit -m "Guard reset while reminder cancellation is pending"
~~~

### Task 3: Bound scheduler work while preserving all-or-nothing recovery

**Files:**

- Modify: \`functions/src/index.ts:149-165,198-215,451-730\`
- Test: \`functions/src/scheduled_delivery.test.ts\`

**Interfaces:**

- Consumes: existing candidates/query plan, claimed delivery tasks, and checkpoint transaction.
- Produces: 300-second/512MiB Function options, batches of at most 25 send tasks, and \`shouldAdvanceSchedulerCheckpoint\` to keep checkpoint advance explicit: zero claim failures advance; one or more failed claims hold recovery.

- [x] **Step 1: Add coverage for recovery helper branches**

Add independent tests named:

~~~ts
it("uses one candidate when no scheduler checkpoint exists", () => {
  assert.equal(israelLocalDeliveryCandidatesSince(now, undefined).length, 1);
});
it("caps a stale scheduler checkpoint at 121 candidate minutes", () => {
  assert.equal(israelLocalDeliveryCandidatesSince(now, fourHoursAgo).length, 121);
});
it("uses an hour-in query plan for recovery candidates", () => {
  assert.deepEqual(scheduledNotificationQueryPlan(twoCandidates), {
    kind: "catchUp", hours: [22, 21],
  });
});
it("holds the checkpoint when a delivery claim fails", () => {
  assert.equal(shouldAdvanceSchedulerCheckpoint(1), false);
  assert.equal(shouldAdvanceSchedulerCheckpoint(0), true);
});
~~~

The explicit query-plan branch was previously uncovered; the other tests protect the cold-start and clamp contract. The checkpoint assertion is RED first because \`shouldAdvanceSchedulerCheckpoint\` does not yet exist; it then replaces both handler checkpoint decisions, including the empty-candidate advance with zero failures.

- [x] **Step 2: Run focused Functions tests**

Run: \`npm --prefix functions test -- --test-name-pattern "checkpoint|hour-in|recovery candidates"\`

Expected: FAIL for the missing checkpoint helper; the characterization tests for the existing candidate/query behavior pass.

- [x] **Step 3: Set explicit limits and settle bounded batches**

Use:

~~~ts
onSchedule(
  { schedule: "every 1 minutes", timeoutSeconds: 300, memory: "512MiB" },
  async (event) => { /* existing handler */ },
);
~~~

Add the pure helper below, use it for the empty-candidate path with zero failures and for the post-send checkpoint guard, then replace unbounded \`Promise.allSettled(sendTasks.map(...))\` with sequential 25-task slices:

~~~ts
export function shouldAdvanceSchedulerCheckpoint(claimFailedCount: number): boolean {
  return claimFailedCount === 0;
}

const results: PromiseSettledResult<ScheduledDeliveryResult>[] = [];
for (let start = 0; start < sendTasks.length; start += 25) {
  results.push(...await Promise.allSettled(
    sendTasks.slice(start, start + 25).map((task) => task()),
  ));
}
~~~

Do not alter claim classification: the helper retains the existing checkpoint decision exactly.

- [x] **Step 4: Verify all Functions tests**

Run: \`npm --prefix functions test\`

Expected: pass; existing failed-claim classification remains green and checkpoint code remains all-or-nothing.

- [x] **Step 5: Commit**

~~~powershell
git add functions/src/index.ts functions/src/scheduled_delivery.test.ts
git commit -m "Bound scheduled notification recovery work"
~~~

### Task 4: Validate checked-in ARB sources and document deployment gates

**Files:**

- Modify: \`functions/src/notification_provisioning.test.ts:1-230\`
- Modify: \`docs/plans/2026-07-31-pr-273-fcm-remaining-work.md:92-169\`
- Modify: \`fcm_notification_plan.md:78-93\`

**Interfaces:**

- Consumes: the checked-in Hebrew, Arabic, and English ARB files, \`parseArbSource\`, and \`buildNotificationSeed\`.
- Produces: CI validation that every locale yields 41 generated quote documents; rollout instructions that label TTL, deny rules, sizing, and claim monitoring as deployment requirements.

- [x] **Step 1: Write the failing real-ARB contract test**

Read the ARBs from \`../../lib/l10n\`, parse them, build the seed, and assert 124 docs: one notification type plus 41 quote documents per locale.

~~~ts
assert.equal(documents.length, 124);
for (const collection of ["quotes_he", "quotes_ar", "quotes_en"]) {
  assert.equal(documents.filter((doc) => doc.collection === collection).length, 41);
}
~~~

It protects the real English duplicate entries: identical decoded values remain valid; an inconsistent duplicate fails during CI before provisioning.

- [x] **Step 2: Run the focused test and confirm it is initially absent**

Run: \`npm --prefix functions test -- --test-name-pattern "checked-in ARB"\`

Expected: no matching test before adding it; then pass after the test is implemented.

- [x] **Step 3: Add the test and deployment documentation**

Import node fs/path in the test. Retain the raw JSON scanner: a JSON reviver cannot observe overwritten duplicate keys, while a regex cannot safely parse escapes/nesting. Update both rollout documents: TTL/deny rules must exist before deploy; 300 seconds/512MiB/25 task batches are the invocation bound; alert on repeated claim failures and aged claimed records. Do not remove identical English duplicate ARB keys in this PR.

- [x] **Step 4: Verify all provisioning tests**

Run: \`npm --prefix functions test -- --test-name-pattern "notification content provisioning"\`

Expected: pass, including ARB-authoritative pruning and checked-in source validation.

- [x] **Step 5: Commit**

~~~powershell
git add functions/src/notification_provisioning.test.ts docs/plans/2026-07-31-pr-273-fcm-remaining-work.md fcm_notification_plan.md
git commit -m "Validate FCM notification ARB sources"
~~~

### Task 5: Verify and close review context

**Files:**

- Verify: \`test/auth/auth_page_interactions_test.dart:21-82\`
- Verify: \`lib/pages/UserSettings.dart:255-303\`
- Verify: \`functions/src/notification_provisioning.ts:37-127,223-249\`

**Interfaces:**

- Produces: no new production API. Review replies distinguish implemented fixes from intentionally retained design choices.

- [x] **Step 1: Verify no-change findings**

Confirm the AuthService hook resets via test-local addTearDown/finally. Keep the JSON scanner because alternatives lose duplicate-key evidence. Keep two FirebaseAuth reads in reset because the second intentionally observes identity after the awaited remote call.

- [x] **Step 2: Run complete validation**

~~~powershell
npm --prefix functions test
flutter test --coverage --reporter=expanded
flutter analyze --no-pub
git diff --check
~~~

Expected: Functions/Flutter tests pass; analyzer only has inherited generated-mock warnings; whitespace check passes.

- [x] **Step 3: Reply/resolve direct review threads**

Reply inline that reset remains privacy-first but is bounded/single-flight; scheduler preserves all-or-nothing checkpoint recovery with explicit resource limits; real ARBs are CI validated. Do not resolve legacy UUID, UID migration, DST, or API-precondition threads: they remain separate decisions.

- [x] **Step 4: Commit the plan and push**

~~~powershell
git add docs/superpowers/plans/2026-08-03-fcm-privacy-first-review-followups.md
git commit -m "Document FCM privacy-first review follow-ups"
git push origin codex/pr-273-fcm-followups
~~~

## Self-Review

- Tasks 1-2 preserve the hard remote cancellation gate and make it bounded/single-flight.
- Task 3 changes resource use but not checkpoint semantics.
- Task 4 validates actual localization content without weak duplicate detection or text mutations.
- Excluded without new approval: offline reset, pending-cancellation replay, incremental checkpoints, a Functions orchestration seam, scanner rewrite, generic request helper, and Firestore batch provisioning.
