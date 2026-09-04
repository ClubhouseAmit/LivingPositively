# PR #273 — FCM Decision Record and Remaining External Work

Created: 2026-07-31
Last updated: 2026-08-04

Parent PR: [#273](https://github.com/ClubhouseAmit/LivingPositively/pull/273)
Stacked implementation PR: [#309](https://github.com/ClubhouseAmit/LivingPositively/pull/309)

## Current Status

Stacked PR #309 implements the FCM follow-up. Local verification passed 801
Flutter tests (9 skipped) and 53 Functions tests. `flutter analyze` reports
only 24 inherited warnings in unchanged generated mocks.
The earlier Android integration failure was a missing
`integration_test/notifications_schedule_test.dart`; the rebased parent now
contains that restored smoke test.

## Decision Log

| Decision | Approved behavior |
| --- | --- |
| Reminder authentication | Non-anonymous Firebase users only. |
| Sign-out | Not offered; reset preserves Firebase-authenticated identity. |
| Device model | One current device token per UID; last registration wins. |
| Reset | On Android/iOS, a non-anonymous user cancels the account-wide remote `default` before local reset, even when this device has no local reminder record; abort if cancellation fails. |
| Legacy local preference | On Android, register an FCM reminder from the persisted legacy hour/minute, then retire the local reminder only after remote provisioning succeeds. |
| Delivery | Bounded best-effort, at-most-once: consider the event minute and preceding 120 minutes, with one send attempt per key. |
| Delivery state | Atomic claim retained for intended time plus 24 hours. |
| Cancellation method | Retain authenticated `POST /cancelNotification`. |

“Best effort” does not mean duplicate-tolerant. It means no eventual-delivery
guarantee: an invocation outside the lateness window, or an ambiguous FCM
failure after a claim, is not retried. The claim prevents duplicate attempts.

## Implemented Work

| ID | Status | Evidence |
| --- | --- | --- |
| FCM-01 content provisioning | Implemented | ARB-derived `provision:notifications` validates an explicit project, replaces generated quote documents, and prunes withdrawn generated quote IDs. |
| FCM-02 lifecycle/reset | Implemented | Sign-out UI/API removed; reset cancels before clear and restores Firebase identity. |
| FCM-03 durable delivery | Implemented | Atomic encoded delivery claim, one attempt, edit-time guard, checkpointed 120-minute Israel-local recovery, and 24-hour `expiresAt`. |
| FCM-04A local preference migration | Retired safely | Legacy hour/minute values are ambiguous, so they never create a remote reminder without an explicit modern preference. |
| FCM-04B legacy remote UUID records | External decision | Requires production inventory and approved mapping-or-retirement policy. |
| FCM-05 authentication policy | Decided and implemented | Authenticated-only; no anonymous account creation. |
| FCM-06 cancellation contract | Decided and implemented | POST retained. |
| FCM-07 dependency approval | Governance follow-up | Record only if project process requires it. |
| FCM-08 verification | Local complete; external validation pending | Coverage, analysis, and Functions suite pass. |
| FCM-09 review cleanup | Complete except FCM-04B | Legacy UUID inventory thread remains open intentionally. |
| FCM-10 optional refactors | Deferred | No unapproved shared UI/request abstractions. |

## FCM-02 — Authenticated Lifecycle and Reset Safety

Sign-out is not an application action. No account-A-to-account-B handoff path
remains to clean up. On Android and iOS, reset always sends the existing
authenticated cancellation command for `default` for a non-anonymous user,
including when the current device has no local reminder preference. The server
operation is idempotent, so it safely deletes either the account schedule or
nothing. On cancellation failure it leaves state and navigation unchanged; on
success it clears local profile data then restores identity from FirebaseAuth.
Unsupported platforms have no remote reminder capability and reset locally.

The existing `clearFCMToken()` and `cleanupInactiveDevice()` helpers are not
wired to reset: they would erase an active account's token or schedules under
the approved no-sign-out model. A future account-detach feature can reuse them
only after ownership and token-match semantics are approved.

## FCM-03 — Delivery Semantics and DST

The scheduler persists its last completed event minute in the Admin-SDK-only
`notification_scheduler_state/primary` document. A normal invocation queries
only its exact Israel-local hour and minute; after a genuine scheduler gap it
recovers the elapsed interval, capped at the event minute plus the preceding
120 UTC minutes formatted in `Asia/Jerusalem`. A schedule candidate that
predates the schedule document's `updatedAt` is ignored, so moving a reminder
to an earlier time cannot send it immediately. For each remaining matching
schedule it atomically creates
`notification_deliveries/{deliveryKey}` before FCM send. The key is base64url
JSON encoding of UID, type, local date, and intended time, avoiding delimiter
collisions. Its transaction re-reads the exact selected schedule and its
per-type `notification_mutation_state/{uid}/types/{typeId}` version before creating
the claim. A deleted or replaced schedule is a non-send skip; a claim conflict
suppresses a second send; `sent` and `failed` are terminal. Configure Firestore
TTL for `expiresAt` outside this repository.

The claim transaction also records a delivery permit with a server-time expiry
of 305 seconds, longer than the 300-second Function deadline. The FCM callback
releases only its own permit in `finally`. Reset's cancellation request carries
`resetFence: true` with the server-authoritative mutation version; legacy
requests cannot establish a reset fence. It receives 409 while a matching
permit is active and therefore preserves local data rather than reporting reset
success. This cannot
recall a message already accepted by FCM; it prevents reset from succeeding
after the scheduler has been authorized to start that send. Legacy schedules
without a mutation version are current only when the selected and re-read
`updatedAt` timestamps are both usable and equal. An expired permit without a
stored mutation version is not a legacy mutation fence.

If a stored mutation version is malformed, `getNotificationMutationVersion`
returns zero to the authenticated client. A subsequent authenticated register
replaces the unusable state so a user can re-enable the reminder; a
reset-fenced cancellation can also repair it. The active-delivery-permit check
remains authoritative for the reset path, while ordinary cancellation can
retire a schedule during the short permit window.

- Spring-forward: the scheduler skips the non-existent Israel-local 02:00–02:59
  occurrence on the transition day. This is accepted best-effort behavior;
  the same wall-clock time remains valid on every other day.
- Fall-back: both occurrences share the local-date/time key. The first claim
  may send; the repeated occurrence is suppressed rather than sending twice.

Tests cover the due window, claim-before-send ordering, duplicate suppression,
ambiguous failure with no retry, schedule-edit suppression, and claim-failure
classification. Scheduler checkpoint transactions advance monotonically, so
overlapping invocations cannot widen a future recovery window.

The deployed scheduler invocation is bounded to 300 seconds and 512MiB.
Outbound sends run in batches of 25. Stale-device cleanup is independent of
delivery and is capped at 25 unique UIDs per invocation after the checkpoint
has advanced. Each cleanup reads and deletes at most 25 schedules in one
Firestore batch; it retains the stale device document when further schedules
remain. UID overflow is reported as deferred and is eligible for a later
scheduling pass. These bounds prevent stale cleanup from consuming the
delivery deadline. Catch-up queries page at 250 documents using a durable
document-ID cursor while holding their original recovery window fixed. A later
invocation resumes after that cursor; only the final page advances the
checkpoint.

### Recovery operations note

A claim-write failure deliberately holds the checkpoint rather than skipping an
unacknowledged intended minute. The next scheduler invocation retries that
bounded window. The scheduler summary emits `claimFailed`,
`recoveryCandidateMinutes`, `requestedRecoveryCandidateMinutes`, and
`recoveryClamped` as structured Cloud Logging fields. During recovery (two or
more candidate minutes), Firestore queries every schedule in the affected
one-to-three local hours, pages the query by document ID, and filters the exact
candidate minutes in memory. A gap beyond the 120-minute lookback drops older
intended minutes by design and always emits a clamp warning before the
scheduler can advance its checkpoint; the fields distinguish the requested
window from the processed bounded window. A bounded page emits a structured
warning with its fixed recovery time and cursor. Production monitoring must
alert on repeated nonzero `claimFailed` counts, repeated bounded-page warnings,
and claimed records that age without reaching a terminal status. Repeated claim
failures keep the current page in recovery; aged claimed records identify a
send or terminal-status update that needs operational investigation.

### Firestore access policy handoff

`notification_deliveries`, `notification_scheduler_state`, and both the parent
and `types` subcollection paths of `notification_mutation_state` are
server-only. Firebase Admin SDK
writes bypass Firestore security rules; the production rules owner must add
these clauses to the canonical deployed rules source before rollout:

```rules
match /notification_deliveries/{deliveryId} {
  allow read, write: if false;
}
match /notification_scheduler_state/{stateId} {
  allow read, write: if false;
}
match /notification_mutation_state/{uid} {
  allow read, write: if false;
}
match /notification_mutation_state/{uid}/types/{typeId} {
  allow read, write: if false;
}
```

This repository has no canonical Firestore rules file or rules deployment
target in `firebase.json`. A new root rules file could replace unrelated
production policy, so this record intentionally does not invent one. Verify
the four deny clauses with authenticated emulator read/list/create/update/delete
tests once the rules source is supplied.

**Rollout is blocked until that verification exists.** Required evidence is:

1. the canonical rules repository, file, and Firebase deployment target;
2. the reviewed deny-rule change for every path above; and
3. an authenticated emulator result covering get, list, create, update, and
   delete attempts against each parent and nested path.

Do not deploy these Functions, provision notification content, or enable the
scheduler until the production rules owner records all three artifacts in the
release ticket. This is a hard pre-deployment gate, not a post-merge
follow-up.

## FCM-04 — Two Different Legacy Concerns

### Local reminder migration — complete

The removed Android local scheduler used the persisted `notificationHour` and
`notificationMinute` values to identify its daily reminder. Migration treats
that Android-only schedule as active until it has safely registered the same
time with FCM, cancels the matching local notification ID, and only then writes
`fcmDefaultReminderMigrated`. The modern `notificationPreferences` record is
written only after the remote registration succeeds, so the UI does not report
an enabled FCM reminder prematurely. If registration or local retirement
fails, the marker remains unset and the existing local reminder is left intact
for a later retry. An explicit remote cancellation also writes the marker so a
queued migration cannot recreate a reminder the user has just turned off.

### ARB notification content — authoritative

The ARB files are the approved source for generated notification quote content.
Provisioning replaces each generated `inspirationalQuotesNo<N>` document from
the seed and deletes generated IDs that are absent from the current ARB files.
It does not delete other documents in `quotes_he`, `quotes_ar`, or `quotes_en`;
those non-pattern documents are outside the generated-content contract.

### Remote UUID records — open external decision

No verified UUID-to-Firebase-UID mapping exists in the repository. Before any
server-side migration, inventory production records and choose one approved
path: retire inactive records, run a versioned/dry-run-capable migration with a
trustworthy ownership mapping, or communicate an expiry when safe mapping is
impossible. Do not assign schedules to guessed identities.

## Remaining External Work

### Deployment gates

1. Release a compatible mobile client that sends
   `expectedMutationVersion` for register, cancel, and reset, and enforce the
   project's minimum-version/upgrade policy before deploying the mutation
   fence. After a versioned mutation or reset creates state, older clients
   intentionally receive 409. Treating an omitted version as current would let
   a delayed legacy request recreate a reminder after reset.
2. Before deploying, configure Firestore TTL for
   `notification_deliveries.expiresAt`; it is a rollout gate, not application
   configuration.
3. Before deploying, add the documented deny rules for
   `notification_deliveries`, `notification_scheduler_state`, and both the
   parent and `types` paths of `notification_mutation_state` to the canonical
   production rules source,
   then verify them with authenticated emulator read/list/create/update/delete
   checks. Attach the canonical source, reviewed diff, and emulator result to
   the release ticket; deployment remains blocked without all three.
4. Deploy Functions through the normal production process with the approved
   scheduler invocation bound of 300 seconds, 512MiB, and 25 task batches.
5. Before enabling production traffic, configure alerts for repeated claim
   failures and claimed records that age without a terminal status.
6. Run `npm --prefix functions run provision:notifications -- --project
   <firebase-project-id>` with credentials for that explicit project.

### Post-deploy validation and data work

1. Complete the FCM-04 remote UUID inventory and approved disposition.
2. Run authenticated emulator, device, and production canaries for
   registration/cancellation, token refresh, delayed delivery, duplicate
    suppression, failure handling, reset (including an active-send 409),
    legacy-reminder retirement, and DST.
3. Record dependency approval only if required by project governance.

## Deferred Work

Multiple active devices per UID, shared notification-state UI, a shared auth
form shell, and shared request helpers require a separate volatility and
consumer review before implementation.

A full `processScheduledNotifications` orchestration test is also deferred.
The existing unit tests cover its scheduling, query-plan, claim, and delivery
helpers. Exercising the complete handler needs an approved Firestore/FCM test
boundary (emulator or explicit dependency injection); adding that seam solely
for one test would broaden the Functions architecture.
