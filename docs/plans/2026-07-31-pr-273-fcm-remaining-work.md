# PR #273 — FCM Decision Record and Remaining External Work

Created: 2026-07-31
Last updated: 2026-08-02

Parent PR: [#273](https://github.com/ClubhouseAmit/LivingPositively/pull/273)
Stacked implementation PR: [#309](https://github.com/ClubhouseAmit/LivingPositively/pull/309)

## Current Status

Stacked PR #309 implements the FCM follow-up. Local verification passed 793
Flutter tests (9 skipped) and 23 Functions tests. `flutter analyze` reports
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
| Legacy local preference | Migrate idempotently after startup/authentication. |
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
| FCM-04A local preference migration | Implemented | Startup/auth migration registers a saved default reminder; marker follows remote success only. |
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
collisions. A claim conflict suppresses a second send; `sent` and `failed` are
terminal. Configure Firestore TTL for `expiresAt` outside this repository.

- Spring-forward: a configured non-existent Israel-local wall-clock minute is
  skipped. This is accepted best-effort behavior.
- Fall-back: both occurrences share the local-date/time key. The first claim
  may send; the repeated occurrence is suppressed rather than sending twice.

Tests cover the due window, claim-before-send ordering, duplicate suppression,
ambiguous failure with no retry, schedule-edit suppression, and claim-failure
classification. Scheduler checkpoint transactions advance monotonically, so
overlapping invocations cannot widen a future recovery window.

The deployed scheduler invocation is bounded to 300 seconds, 512MiB, and 25
task batches. These are deployment bounds for the approved all-or-nothing
recovery behavior, not runtime configuration: if a bounded recovery cannot
complete, its checkpoint remains held for a later invocation.

### Recovery operations note

A claim-write failure deliberately holds the checkpoint rather than skipping an
unacknowledged intended minute. The next scheduler invocation retries that
bounded window. During recovery (two or more candidate minutes), Firestore
queries every schedule in the affected one-to-three local hours and filters
the exact candidate minutes in memory; the time window is capped at 120
minutes, but read volume still scales with schedules in those hours. Production
monitoring must alert on repeated nonzero `claimFailed` counts and claimed
records that age without reaching a terminal status. Repeated claim failures
keep the checkpoint in recovery; aged claimed records identify a send or
terminal-status update that needs operational investigation.

### Firestore access policy handoff

`notification_deliveries` and `notification_scheduler_state` are server-only
collections. Firebase Admin SDK writes bypass Firestore security rules; the
production rules owner must add these clauses to the canonical deployed rules
source before rollout:

```rules
match /notification_deliveries/{deliveryId} {
  allow read, write: if false;
}
match /notification_scheduler_state/{stateId} {
  allow read, write: if false;
}
```

This repository has no canonical Firestore rules file or rules deployment
target in `firebase.json`. A new root rules file could replace unrelated
production policy, so this record intentionally does not invent one. Verify
the two deny clauses with authenticated emulator read/list/create/update/delete
tests once the rules source is supplied.

## FCM-04 — Two Different Legacy Concerns

### Local preference migration — complete

The client migration is not a Firestore UUID migration. On startup and after
authentication it reads a legacy local default preference, calls
`registerNotification`, and writes its marker only after success. It retries
on a later startup/authentication after failure.

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

1. Before deploying, configure Firestore TTL for
   `notification_deliveries.expiresAt`; it is a rollout gate, not application
   configuration.
2. Before deploying, add the documented deny rules for
   `notification_deliveries` and `notification_scheduler_state` to the
   canonical production rules source,
   then verify them with authenticated emulator read/list/create/update/delete
   checks.
3. Deploy Functions through the normal production process with the approved
   scheduler invocation bound of 300 seconds, 512MiB, and 25 task batches.
4. Before enabling production traffic, configure alerts for repeated claim
   failures and claimed records that age without a terminal status.
5. Run `npm --prefix functions run provision:notifications -- --project
   <firebase-project-id>` with credentials for that explicit project.

### Post-deploy validation and data work

1. Complete the FCM-04 remote UUID inventory and approved disposition.
2. Run authenticated emulator, device, and production canaries for
   registration/cancellation, token refresh, delayed delivery, duplicate
   suppression, failure handling, reset, local migration, and DST.
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
