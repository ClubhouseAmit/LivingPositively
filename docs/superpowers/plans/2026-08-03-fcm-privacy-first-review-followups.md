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

- [ ] **Step 3: Controller: reply/resolve direct review threads**

Reply inline that reset remains privacy-first but is bounded/single-flight; scheduler preserves all-or-nothing checkpoint recovery with explicit resource limits; real ARBs are CI validated. Do not resolve legacy UUID, UID migration, DST, or API-precondition threads: they remain separate decisions.

- [ ] **Step 4: Controller: push the committed plan**

Local verification and the plan-record commit were completed in `136e3e0`
(`Document FCM privacy-first review follow-ups`). The remaining external action
is controller-owned: review the proposed reply topics, post or resolve only the
appropriate GitHub threads, then push when ready.

~~~powershell
git push origin codex/pr-273-fcm-followups
~~~

### Task 6: Fence remote notification mutations across reset

**Files:**

- Modify: `functions/src/index.ts:57-94,347-440`
- Modify: `functions/src/notification_validation.test.ts`
- Modify: `lib/util/Firebase/fcm_scheduled_notification_service.dart:22-294`
- Test: `test/Firebase/fcm_scheduled_notification_service_test.dart`
- Modify: `fcm_notification_plan.md`

**Volatility and approved boundary:** HTTP requests can outlive the client-side
15-second deadline. The existing in-process queue cannot order a late request
at the Functions boundary, so reset needs a server-enforced mutation version.
The user approved this Functions/client contract change on 2026-08-03. The
server is authoritative for the version; the client only reads and presents an
expected value.

**Interfaces:**

- Produces: authenticated `getNotificationMutationVersion` (POST, responds with
  `{ mutationVersion: nonNegativeInteger }`), plus an optional
  `expectedMutationVersion` field on existing register/cancel POST bodies.
- Persisted state: Functions-only `notification_mutation_state/{uid}` with a
  monotonically increasing `version`; every versioned register/cancel runs in a
  Firestore transaction that checks the expected version, applies the schedule
  mutation, then advances the version.
- Compatibility: old requests without an expected version remain usable only
  while no state document exists. Once a versioned client mutates or resets an
  account, the server rejects an unfenced legacy mutation. This keeps a
  pre-reset legacy request from recreating a reminder after the reset fence.

- [x] **Step 1: Write the failing fence regressions**

In Functions validation tests, cover parsing a non-negative expected version,
rejecting a stale version, and rejecting an unfenced mutation once state exists.
In the Flutter service suite, emulate a server version and add
`a late registration cannot recreate a reminder after reset cancellation`:

1. The version endpoint returns 0 and registration starts a post carrying 0.
2. Its post exceeds the client deadline.
3. Reset cancellation reads 0, advances the emulated server to 1, and succeeds.
4. Completing the old registration later must receive the stale-version result
   and leave the emulated remote schedule absent.

This test is RED without an expected server version on registration/cancellation.

- [x] **Step 2: Run focused regressions and observe failure**

~~~powershell
npm --prefix functions test -- --test-name-pattern "notification mutation"
flutter test --no-pub test/Firebase/fcm_scheduled_notification_service_test.dart --plain-name "a late registration cannot recreate a reminder after reset cancellation"
~~~

Expected: missing validators/endpoint contract and a late registration can still
be accepted by the emulated remote state.

- [x] **Step 3: Add the minimal versioned transaction protocol**

Add explicit pure validation helpers for body parsing and stale/fenced
decisions. The handlers retain their existing auth/type validation, then use
one Firestore transaction: read the state document, reject a mismatched
expected version with 409, write/delete the schedule, and increment `version`.
The version-read endpoint returns 0 for an account with no state document.

The Dart service must capture an in-memory reset epoch before each queued
mutation, re-check it after token/version awaits, and send the version obtained
from the endpoint in the subsequent mutation. `cancelDefaultForReset` advances
the local epoch before it queues its cancellation. These local checks avoid
sending an operation that has not left the device; the transaction protects the
request that already has.

Do not retry a 409 automatically: the selected time may no longer represent
the user's current intent. Preserve `Future<bool>` and existing failure paths.

- [x] **Step 4: Document rollout and verify focused suites**

Document the new state collection, expected-version contract, and deployment
ordering: deploy the Functions endpoint before the mobile client; legacy app
mutations are deliberately blocked for an account after it becomes fenced.
Then run:

~~~powershell
npm --prefix functions test
flutter test --no-pub test/Firebase/fcm_scheduled_notification_service_test.dart
~~~

- [x] **Step 5: Commit**

~~~powershell
git add functions/src/index.ts functions/src/notification_validation.test.ts fcm_notification_plan.md lib/util/Firebase/fcm_scheduled_notification_service.dart test/Firebase/fcm_scheduled_notification_service_test.dart
git commit -m "Fence FCM mutations across reset"
~~~

### Task 7: Keep an in-flight reset dialog on screen

**Files:**

- Modify: `lib/pages/UserSettings.dart:622-736`
- Test: `test/UserSettings/UserSettings_interactions_test.dart`

**Interfaces:**

- Produces: while reset cancellation is pending, neither a modal-barrier tap
  nor system Back can dismiss the confirmation dialog. The existing Close
  action remains available before a reset starts.

- [x] **Step 1: Write the failing dialog-dismissal regression**

Extend the existing pending-reset test (or add a focused sibling) to begin a
token-pending reset, assert the modal barrier is not dismissible, invoke the
route back action, and confirm the dialog, spinner, and single token request
remain. Complete the token with null and retain the existing privacy-first
failure assertions.

- [x] **Step 2: Run the focused regression and observe failure**

~~~powershell
flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart --plain-name "reset confirmation cannot be dismissed while remote cancellation is pending"
~~~

Expected: the default dialog barrier/back route closes the dialog during the
pending operation.

- [x] **Step 3: Block only pending dismissal**

Set the dialog's `barrierDismissible` to false and wrap the dialog with
`PopScope(canPop: !isResetting)`. Keep the existing dialog-local state, disabled
buttons, spinner, and mounted guard; no reset behavior or navigation changes.

- [x] **Step 4: Verify the UserSettings suite**

~~~powershell
flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart
~~~

- [x] **Step 5: Commit**

~~~powershell
git add lib/pages/UserSettings.dart test/UserSettings/UserSettings_interactions_test.dart
git commit -m "Keep pending reset confirmation open"
~~~

### Task 8: Validate the current schedule at delivery claim time

> **Status: superseded.** Commit `43341f7` established the claim-time fence,
> but review found a post-claim send race, legacy timestamp weakness, and an
> ambiguous state key. Tasks 10-11 replace its state/claim protocol.

**Files:**

- Modify: `functions/src/index.ts:382-584,601-870`
- Modify: `functions/src/scheduled_delivery.test.ts`
- Modify: `lib/util/Firebase/fcm_scheduled_notification_service.dart`
- Modify: `test/Firebase/fcm_scheduled_notification_service_test.dart`
- Modify: `fcm_notification_plan.md`
- Modify: `docs/plans/2026-07-31-pr-273-fcm-remaining-work.md`

**Volatility and approved boundary:** Scheduler selection is asynchronous. A
schedule can be deleted or replaced by reset after the scheduler query but
before an FCM send. The approved server fence must therefore protect delivery
claiming as well as registration/cancellation. The existing mutation state
becomes per `(uid, typeId)`, which prevents an update to one reminder type from
invalidating another type's schedule.

**Interfaces:**

- `notification_mutation_state/{uid}_{typeId}` holds the version for one
  schedule type. `getNotificationMutationVersion` requires the validated
  `typeId` in its POST body. Current clients supply it before each mutation.
- Versioned registration stores the successful next version as
  `mutationVersion` on its schedule document.
- Scheduler claim uses a Firestore transaction to re-read the exact schedule
  document and its matching per-type state. It creates the delivery claim only
  if both still match the selected snapshot; missing, legacy-after-fence, or
  changed schedules return a non-send skip result. The checkpoint still
  advances for skips, because no claim write failed.

- [ ] **Step 1: Write failing current-schedule regressions**

Add a pure scheduler regression where a claim writer reports that the selected
schedule is no longer current; assert no FCM send and a skip result. Extend
the FCM client expectations to assert `typeId` in the version-read request.
Document the expected state-ID/validation contract in the test fixture as
needed. The scheduler behavior is RED first because it currently sends after
any successful delivery claim.

- [ ] **Step 2: Run focused tests and observe failure**

~~~powershell
npm --prefix functions test -- --test-name-pattern "current schedule|notification mutation"
flutter test --no-pub test/Firebase/fcm_scheduled_notification_service_test.dart --plain-name "register sends an authenticated FCM schedule and saves it"
~~~

- [ ] **Step 3: Gate production claims with the per-type state**

Move state refs to `{uid}_{typeId}`. Validate `typeId` in the read endpoint
and include it in client reads. In each versioned register transaction, store
the post-mutation version on the schedule doc. Replace the handler's delivery
writer `create` with a transaction that re-reads the original schedule ref and
the per-type state ref, verifies the snapshot's `mutationVersion` equals the
current schedule/state version, and atomically creates the delivery claim.
Treat a failed current-schedule check as `notCurrent` rather than an error;
never call FCM for it. Keep direct writer test doubles compatible and retain
the all-or-nothing checkpoint decision for actual claim failures.

- [ ] **Step 4: Align deployment records and verify focused suites**

Update both FCM handoff documents to include `notification_mutation_state` in
their server-only deny-rule/emulator requirements. Run:

~~~powershell
npm --prefix functions test
flutter test --no-pub test/Firebase/fcm_scheduled_notification_service_test.dart
~~~

- [ ] **Step 5: Commit**

~~~powershell
git add functions/src/index.ts functions/src/scheduled_delivery.test.ts lib/util/Firebase/fcm_scheduled_notification_service.dart test/Firebase/fcm_scheduled_notification_service_test.dart fcm_notification_plan.md docs/plans/2026-07-31-pr-273-fcm-remaining-work.md
git commit -m "Validate FCM schedule state before delivery"
~~~

### Task 9: Synchronously reject duplicate reset confirmation

**Files:**

- Modify: `lib/pages/UserSettings.dart:687-706`
- Modify: `test/UserSettings/UserSettings_interactions_test.dart`

**Interfaces:**

- Produces: a second Confirm activation returns immediately once the first
  callback has marked `isResetting`, including before Flutter has rebuilt the
  disabled button. The dialog stays non-dismissible until the one pending
  attempt completes.

- [x] **Step 1: Add the same-frame duplicate-confirm regression**

In the token-pending Android reset fixture, invoke the captured Confirm handler
twice before pumping a rebuild. Assert one token request, one spinner, and that
completing the token with null retains UserSettings and the existing snackbar.

- [x] **Step 2: Run it RED**

~~~powershell
flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart --plain-name "reset confirmation ignores same-frame duplicate activation"
~~~

- [x] **Step 3: Add the callback-entry guard**

The existing asynchronous callback begins with `if (isResetting) return;`,
then retains the current `setDialogState`, await, and mounted reset path. Do
not change the reset protocol or move dialog state to the page.

- [x] **Step 4: Verify the UserSettings suite and commit**

~~~powershell
flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart
git add lib/pages/UserSettings.dart test/UserSettings/UserSettings_interactions_test.dart
git commit -m "Guard duplicate reset confirmation"
~~~

### Task 10: Hold reset behind an authorized in-flight FCM send

> **Status: completed with recovery follow-up.** Commit `8d53feb` added the
> permit protocol; Task 11 corrected its legacy permit-expiry and timestamp
> identity recovery paths.

**Files:**

- Modify: `functions/src/index.ts`
- Modify: `functions/src/notification_validation.test.ts`
- Modify: `functions/src/scheduled_delivery.test.ts`
- Modify: `lib/util/Firebase/fcm_scheduled_notification_service.dart`
- Test: `test/Firebase/fcm_scheduled_notification_service_test.dart`
- Modify: `fcm_notification_plan.md`
- Modify: `docs/plans/2026-07-31-pr-273-fcm-remaining-work.md`

**Volatility and approved behavior:** A Firestore transaction cannot atomically
include the external FCM call. The claim-time fence in Task 8 still permits
reset after claim and before send. Privacy-first reset therefore treats an
already-authorized FCM send as a remote cancellation conflict: reset receives
409 and preserves local data rather than claiming success. This is the
existing hard-block behavior applied to the final send boundary.

**Interfaces:**

- Use an unambiguous per-type state path:
  `notification_mutation_state/{uid}/types/{typeId}`, not a delimiter-composed
  document ID.
- Scheduler's atomic claim also records a `deliveryPermitKey` and a
  server-timestamp-derived permit expiry greater than the 300-second Function
  deadline. It may call FCM only after that transaction commits.
- `cancelDefaultForReset` sends `resetFence: true`. The cancellation transaction
  rejects with 409 while the matching state has an active delivery permit; it
  must not delete the schedule or advance the mutation version. The Dart
  boolean failure already keeps reset local data intact.
- The send callback releases its matching permit in `finally`. Failed release
  is logged and leaves reset conservatively blocked until the permit expires.
- Legacy schedule freshness compares the selected and current `updatedAt`
  values. An unfenced legacy schedule without a usable timestamp is skipped;
  a legacy replacement after query cannot send the stale selection.

- [x] **Step 1: Write focused failing pure regressions**

Cover (a) unambiguous state paths for underscore-containing uid/type inputs,
(b) active permit blocks reset while an expired one does not, (c) a legacy
schedule whose `updatedAt` differs from the selected snapshot is not current,
and (d) a `notCurrent` or blocked-permit claim makes zero FCM calls. Run these
tests RED before implementation.

- [x] **Step 2: Implement permit and freshness protocol**

Add private/pure helpers that validate current schedule revisions and active
permit state, then use them from the request handlers and scheduler transaction.
Use Firestore `merge` writes for state version changes so an active permit is
never cleared by a concurrent registration/cancellation. Keep the existing
FCM send bounded by the Function timeout and do not add retries.

- [x] **Step 3: Update deployed-contract docs and verify**

Document the nested state path, deny rules for parent/subcollection paths, and
the reset-versus-active-send behavior. Run the complete Functions suite and
the FCM service suite after the focused tests.

- [x] **Step 4: Commit**

~~~powershell
git add functions/src/index.ts functions/src/notification_validation.test.ts functions/src/scheduled_delivery.test.ts lib/util/Firebase/fcm_scheduled_notification_service.dart test/Firebase/fcm_scheduled_notification_service_test.dart fcm_notification_plan.md docs/plans/2026-07-31-pr-273-fcm-remaining-work.md
git commit -m "Block reset during active FCM delivery"
~~~

### Task 11: Recover legacy schedules safely after a delivery permit

**Files:**

- Modify: `functions/src/index.ts`
- Modify: `functions/src/notification_validation.test.ts`
- Modify: `functions/src/scheduled_delivery.test.ts`

**Interfaces:**

- A state document with no mutation `version` is a temporary legacy permit
  state. It behaves as absent once its permit is expired; a live permit still
  blocks reset and concurrent claims.
- Legacy schedule identity uses exact Firestore timestamp equality
  (`isEqual` or seconds/nanoseconds), never millisecond truncation. A timestamp
  that cannot be compared exactly is not current.
- `claimAndSendScheduledDelivery` calls a supplied permit release after either
  a successful or failed FCM attempt, but not after a no-claim skip.

- [x] **Step 1: Add failing recovery regressions**

Cover expired unversioned state as current for an unchanged legacy schedule,
same-millisecond timestamps with distinct nanoseconds as non-current, and
permit release after both success and failure. Keep a `notCurrent` case to
prove it has no release/send side effects.

- [x] **Step 2: Implement the narrow recovery rules**

Use the active-permit predicate when interpreting unversioned state, replace
millisecond comparison with full timestamp identity, and retain the existing
permit release `finally` semantics. Do not widen reset behavior or create an
emulator harness.

- [x] **Step 3: Verify and commit**

~~~powershell
npm --prefix functions test
git add functions/src/index.ts functions/src/notification_validation.test.ts functions/src/scheduled_delivery.test.ts
git commit -m "Recover legacy FCM schedules after permit expiry"
~~~

## Self-Review

- Tasks 1-2 preserve the hard remote cancellation gate and make it bounded/single-flight.
- Task 3 changes resource use but not checkpoint semantics.
- Task 4 validates actual localization content without weak duplicate detection or text mutations.
- Task 6 makes the asynchronous Functions boundary authoritative when a reset races a timed-out request; a 409 leaves the caller's local selection unchanged.
- Task 7 closes the dialog dismissal race without relaxing the reset gate.
- Task 8 prevents a schedule selected before reset or schedule replacement
  from being claimed/sent after that state changes.
- Task 9 keeps the dialog-local single-flight promise valid before a button
  rebuild occurs.
- Task 10 does not promise to recall an FCM message already accepted by FCM;
  it guarantees reset cannot succeed once scheduler has committed authority to
  initiate that send.
- Task 11 keeps the delivery permit bounded for legacy schedules without
  weakening exact schedule freshness checks.
- Excluded without new approval: offline reset, pending-cancellation replay, incremental checkpoints, a Functions orchestration seam, scanner rewrite, generic request helper, and Firestore batch provisioning.
