# PR #273 — FCM Decision Record and Remaining External Work

Date: 2026-08-02

Parent PR: [#273](https://github.com/ClubhouseAmit/LivingPositively/pull/273)
Stacked implementation PR: [#309](https://github.com/ClubhouseAmit/LivingPositively/pull/309)

## Current Status

Stacked PR #309 implements the FCM follow-up. Local verification passed 742
Flutter tests (8 skipped), clean `flutter analyze`, and 14 Functions tests.
The earlier Android integration failure was a missing
`integration_test/notifications_schedule_test.dart`; the rebased parent now
contains that restored smoke test.

## Decision Log

| Decision | Approved behavior |
| --- | --- |
| Reminder authentication | Non-anonymous Firebase users only. |
| Sign-out | Not offered; reset preserves Firebase-authenticated identity. |
| Device model | One current device token per UID; last registration wins. |
| Reset | Cancel remote `default` before local reset; abort if cancellation fails. |
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
| FCM-01 content provisioning | Implemented | ARB-derived idempotent `provision:notifications` command validates an explicit project. |
| FCM-02 lifecycle/reset | Implemented | Sign-out UI/API removed; reset cancels before clear and restores Firebase identity. |
| FCM-03 durable delivery | Implemented | Atomic encoded delivery claim, one attempt, 120-minute Israel-local lookback, 24-hour `expiresAt`. |
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
remains to clean up. For a non-anonymous user, reset sends the existing
authenticated cancellation command for `default`; on failure it leaves state
and navigation unchanged, and on success it clears local profile data then
restores identity from FirebaseAuth.

The existing `clearFCMToken()` and `cleanupInactiveDevice()` helpers are not
wired to reset: they would erase an active account's token or schedules under
the approved no-sign-out model. A future account-detach feature can reuse them
only after ownership and token-match semantics are approved.

## FCM-03 — Delivery Semantics and DST

The scheduler derives 121 Israel-local intended minutes from the Cloud
Scheduler event: the event minute and preceding 120 UTC minutes formatted in
`Asia/Jerusalem`. For each matching schedule it atomically creates
`notification_deliveries/{deliveryKey}` before FCM send. The key is base64url
JSON encoding of UID, type, local date, and intended time, avoiding delimiter
collisions. A claim conflict suppresses a second send; `sent` and `failed` are
terminal. Configure Firestore TTL for `expiresAt` outside this repository.

- Spring-forward: a configured non-existent Israel-local wall-clock minute is
  skipped. This is accepted best-effort behavior.
- Fall-back: both occurrences share the local-date/time key. The first claim
  may send; the repeated occurrence is suppressed rather than sending twice.

Tests cover the due window, claim-before-send ordering, duplicate suppression,
and ambiguous failure with no retry.

## FCM-04 — Two Different Legacy Concerns

### Local preference migration — complete

The client migration is not a Firestore UUID migration. On startup and after
authentication it reads a legacy local default preference, calls
`registerNotification`, and writes its marker only after success. It retries
on a later startup/authentication after failure.

### Remote UUID records — open external decision

No verified UUID-to-Firebase-UID mapping exists in the repository. Before any
server-side migration, inventory production records and choose one approved
path: retire inactive records, run a versioned/dry-run-capable migration with a
trustworthy ownership mapping, or communicate an expiry when safe mapping is
impossible. Do not assign schedules to guessed identities.

## Remaining External Work

1. Deploy Functions through the normal production process.
2. Run `npm --prefix functions run provision:notifications -- --project
   <firebase-project-id>` with credentials for that explicit project.
3. Configure Firestore TTL for `notification_deliveries.expiresAt`.
4. Complete the FCM-04 remote UUID inventory and approved disposition.
5. Run authenticated emulator, device, and production canaries for
   registration/cancellation, token refresh, delayed delivery, duplicate
   suppression, failure handling, reset, local migration, and DST.
6. Record dependency approval only if required by project governance.

## Deferred Work

Multiple active devices per UID, shared notification-state UI, a shared auth
form shell, and shared request helpers require a separate volatility and
consumer review before implementation.
