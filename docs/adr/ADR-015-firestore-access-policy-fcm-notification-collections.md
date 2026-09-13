# ADR-015: Firestore Access Policy for FCM Notification Collections

- **Status**: proposed
- **Date**: 2026-09-13
- **Deciders**: <!-- repository collaborator -->
- **Tags**: firestore, security-rules, notifications, fcm, privacy, devices, ci

## Context

`feature/basic-fcm-setup` introduces server-managed notification state to
Firestore. Until commit `2eb39da` this repository had no canonical
`firestore.rules`, so the deployed authorization policy was unreviewable from
the codebase. That commit imports the live `mezilondb` ruleset verbatim
(release `cloud.firestore`, ruleset `f77b683a-b55a-4bfe-b237-2be00d9849db`)
as the baseline for this decision.

### Collections this branch introduces

| Collection | Document identity | Holder |
| --- | --- | --- |
| `scheduled_notifications` | `base64url(JSON([uid, typeId]))` | per-user reminder settings |
| `notification_mutation_state/{uid}/types/{typeId}` | uid path segment | per-user mutation fence |
| `notification_deliveries/{deliveryKey}` | `base64url(JSON([uid, type, date, time]))` | per-user delivery claim |
| `notification_scheduler_state/primary` | singleton | scheduler checkpoint |
| `notification_types/{typeId}` | type identifier | notification type configuration |

None of these are referenced on `main`. No Flutter client code reads any of
them: every client interaction goes through the authenticated HTTPS Cloud
Functions (`registerNotification`, `cancelNotification`,
`getNotificationMutationVersion`), which use the Admin SDK and therefore
bypass security rules entirely. The client's own `notificationPreferences`
mirror is persisted through `PersistentMemoryService` to local device storage,
not to Firestore, so reminder settings are never written into a shared
document.

### Why the planned deny rules do not work

`docs/plans/2026-07-31-pr-273-fcm-remaining-work.md` specifies adding
`allow read, write: if false` blocks for the new collections. Those blocks
would have no effect. The imported baseline contains:

```rules
match /{document=**} {
  allow read: if true;
  allow write: if hasAnyRole(["ADMIN", "OWNER"]);
}
```

Firestore evaluates every `match` block whose path pattern matches the
requested document and permits the operation if **any** of them allows it.
Rules are OR-combined; a narrower block cannot revoke a grant made by a
broader one. There is no most-specific-wins precedence and no deny primitive.
While that root catch-all stands, every new collection is world-readable by
unauthenticated callers regardless of what is written alongside it, and an
`if false` block would misrepresent the collection as protected.

Protecting the new collections therefore requires changing the catch-all
itself. That is in tension with the constraint that pre-existing objects keep
their current policy, and the resolution below is the substance of this
decision.

### Constraints

1. Every database object introduced by this branch must be restricted to
   authorized access.
2. Objects already present on `main` retain their current access policy.
3. Users who are not signed in remain supported and cannot set reminders.
4. No user may read another user's reminder settings.
5. Future work adds further notification types and user-defined custom
   reminders; the policy must absorb those without a rules change per type.

"Anonymous" is ambiguous here, and in this record it means **a user with no
Firebase account at all** (`FirebaseAuth.currentUser == null`, and
`request.auth == null` in rules). It does not mean Firebase Anonymous
Authentication: `signInAnonymously` appears nowhere in `lib/`, so that user
class does not exist in this app. The distinction matters because a Firebase
anonymous user *is* authenticated as far as rules are concerned
(`request.auth != null`, with a real UID), whereas a not-signed-in user is
not. Not-signed-in users never write to `devices` — all three call sites in
`fcm_service.dart` guard on `uid != null` — and never receive reminders.

Constraint 4 is not expressible as a path-based ownership rule for
`scheduled_notifications`: the owning UID is encoded inside the base64url
document ID rather than carried as a path segment, and a `resource.data.uid ==
request.auth.uid` condition cannot constrain `list` queries, only single-
document `get`s.

## Decision

**1. The repository is the canonical source of Firestore rules.**
`firestore.rules` is registered in `firebase.json` and deployed by CI. Console
edits are drift and are surfaced as a failing check, not silently overwritten.

**2. All five new collections are server-only.** No client, authenticated or
not, reads or writes them directly. Admin SDK access from Cloud Functions is
unaffected because it bypasses rules.

**3. The catch-all is scoped by an explicit server-only denylist**, replacing
the unconditional root wildcard:

```rules
function serverOnlyCollection(collectionId) {
  return collectionId in [
    "scheduled_notifications",
    "notification_deliveries",
    "notification_scheduler_state",
    "notification_mutation_state",
    "notification_types"
  ];
}

match /{collectionId}/{document=**} {
  allow read: if !serverOnlyCollection(collectionId);
  allow write: if hasAnyRole(["ADMIN", "OWNER"]) &&
    !serverOnlyCollection(collectionId);
}
```

Under `rules_version = '2'` a recursive wildcard matches zero or more
segments, so `/{collectionId}/{document=**}` covers every document the
previous `/{document=**}` covered while exposing the first path segment as a
testable value. Every collection that is not named in the denylist keeps
byte-for-byte the same effective policy it has today, satisfying constraint 2.
The nested `notification_mutation_state/{uid}/types/{typeId}` path is covered
by the same block because `collectionId` binds to the root segment.

**4. No inert `if false` blocks are added.** This supersedes the deny-clause
specification in `docs/plans/2026-07-31-pr-273-fcm-remaining-work.md`. Rules
that cannot change an outcome are removed from the design rather than kept as
documentation, because their presence implies a protection the engine does not
provide. The denylist condition is the sole mechanism.

**5. Anonymity cannot be enforced in rules, and is not currently enforced on
the server either.** Rules deny all direct client access uniformly, so they
cannot express "non-anonymous users may set reminders." That check exists
today only in the Flutter client:
`fcm_scheduled_notification_service.dart:123` refuses to fetch an ID token
when `user.isAnonymous`.

A client-side check is a policy, not a control. `extractAndVerifyUid`
(`functions/src/index.ts:565`) calls `verifyIdToken` and returns
`decoded.uid` without inspecting `decoded.firebase.sign_in_provider`, so any
caller holding a valid anonymous ID token can register a reminder by calling
the endpoint directly. Enforcing constraint 3 requires a server-side check:

```ts
if (decoded.firebase?.sign_in_provider === "anonymous") return null;
```

This is recorded as required work, not as an existing property. Whether it is
presently exploitable depends on whether Anonymous sign-in is enabled in the
`mezilondb` console, which is not observable from this repository; if it is
enabled, the Web API key shipped in the client is sufficient to mint such a
token. The FCM-05 entry in
`docs/plans/2026-07-31-pr-273-fcm-remaining-work.md` marks this "decided and
implemented," which is accurate for the client and not for the server.

Constraint 3 is an application authorization rule; constraints 1 and 4 are
data access rules. They belong at different layers on purpose — but both
layers have to actually exist.

**6. The denylist is collection-scoped, not type-scoped.** New notification
types and user-defined custom reminders are new *documents* in the same
collections and inherit the deny with no rules change, satisfying constraint
5. Introducing a new server-only *collection* does require a denylist entry,
so CI enforces that: a check fails when `functions/src` references a Firestore
collection that appears in neither the denylist nor an allowlist of
intentionally client-readable collections.

**7. Verification is an emulator test, not a review claim.** Rules ship with
`@firebase/rules-unit-testing` coverage asserting that unauthenticated,
anonymous, and authenticated non-owner contexts are all denied `get`, `list`,
`create`, `update`, and `delete` on each new collection and on the nested
`types` subcollection — `list` asserted separately from `get`, since a query
can succeed where a document read fails. The suite additionally asserts that a
representative pre-existing collection's behavior is unchanged against the
imported baseline, which is what makes constraint 2 a tested property rather
than an intention.

**8. The pre-existing `devices/{document=**}` rule is deleted.** The baseline
contains, above the owner-scoped rule:

```rules
match /devices/{document=**} { allow read, write: if true; }
```

This is brought into scope despite constraint 2, because the premise behind
that constraint does not hold for this rule. Constraint 2 exists to protect
working production behavior. This rule protects none:

- It was load-bearing for the *original* FCM design (commit `e4c16de`), which
  wrote `devices/{deviceId}` keyed by a locally generated identifier with no
  signed-in user. Unauthenticated write was the only way that worked.
- That design was replaced. All three current call sites
  (`fcm_service.dart:275,347,425`) pass `uid` under a `uid != null` guard, so
  every write is `devices/{uid}` by a signed-in user. The surviving
  `deviceId` parameter name is a fossil of the old scheme.
- The feature has never shipped. `fcm_service.dart` does not exist on `main`,
  so no released client writes to this collection under either scheme and
  removal cannot break a deployed app version.
- This branch makes the rule newly destructive.
  `processScheduledNotifications` queries
  `devices.where("updatedAt", "<", now - 180 days)`
  (`functions/src/index.ts:1248`), and `cleanupInactiveDevice` then deletes
  that user's `scheduled_notifications` documents and the device document.
  `updatedAt` is attacker-writable under this rule, so an unauthenticated
  caller can drive the scheduler's own cleanup path into deleting other
  users' reminders, bounded only by the 25-UID-per-invocation cap. The
  transaction's `timestampsAreExactlyEqual` guard defends against races, not
  against forged values.

The rule immediately below it already covers every legitimate write and is
retained unchanged:

```rules
match /devices/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

Verification adds: an owner write to `devices/{uid}` succeeds; a write to
another user's document is denied; and unauthenticated `get`, `list`,
`create`, `update`, and `delete` against `devices` are all denied.

### Explicitly out of scope

The imported baseline also grants unauthenticated read of every document:

```rules
match /{document=**} { allow read: if true; }
```

This record does not narrow it, because the application depends on it.
`getSyncPages` (`firebase_functions.dart:1716`) and the sibling content
fetches for `VersionManager`, `feelGoodPageTitles`, `ShareTexts`,
`SharePDFtexts`, the `IntroductionForm_*` collections, and the app-info blob
carrying `wellnessVideos` (`firebase_functions.dart:613`) all issue bare
`FirebaseFirestore.instance.collection(...).get()` calls with no auth gate
ahead of them. Changing the condition to `request.auth != null` would break
first launch for every user who has not signed in: no videos, no onboarding
copy, no version check. Decision 3's denylist deliberately leaves the read
condition intact and carves out only collections that no client reads.

Narrowing it is a content-authorization question requiring its own consumer
analysis, and belongs in a separate record. The consequence accepted here is
that every collection outside the denylist stays world-readable, exactly as in
production today.

## Consequences

### Positive

- Reminder settings are unreadable by any client, so constraint 4 holds
  absolutely rather than depending on a query-shape assumption.
- The policy is expressed once per collection and is invariant across future
  notification types and custom reminders.
- Rules become reviewable in pull requests and testable in CI, replacing an
  unversioned console artifact.
- The `if false` correction prevents shipping a rule set that reads as
  protective while permitting unauthenticated reads.
- Deleting the `devices` wildcard closes unauthenticated enumeration of every
  user's UID and push token, token hijacking, silent reminder suppression,
  and the scheduler-driven deletion path in decision 8 — at no functional
  cost, since no shipped or current code path depends on it.

### Negative

- Modifying the catch-all touches a rule that governs every collection in the
  database. The blast radius is the whole ruleset, which is why decision 7
  requires the unchanged-behavior assertion before deploy.
- A future client feature that needs direct read access to
  `notification_types` requires a rules change and its own decision record.
- The database remains world-readable outside the denylisted collections.
  This record does not improve that, and that catch-all is precisely what
  makes the denylist necessary rather than optional.
- Constraint 3 is left enforced only in the client until the decision-5
  server check ships. The gap is recorded rather than closed by this record.

### Neutral

- Enforcement is split across two layers (rules for data access, Functions for
  anonymity). This is inherent to Admin SDK access bypassing rules.
- CI gains a rules deployment path, which makes the repository the single
  writer for production authorization policy.

## Open question for the deciders

`quotes_he`, `quotes_ar`, and `quotes_en` are written by
`provision:notifications` and read only by the scheduler; no client code reads
them. They are new to the *codebase* on this branch, but the provisioning
contract's rule that it must not delete non-generated documents implies the
collections already hold Rowy-managed content in production, which would make
them pre-existing *data* under constraint 2.

This ADR leaves them on their current policy. Confirm that reading: if those
collections are in fact new in production, they should be added to the
denylist as server-only.

## Links

- `docs/plans/2026-07-31-pr-273-fcm-remaining-work.md` — FCM decision record;
  its Firestore access policy handoff section is superseded by decision 4.
- `docs/plans/2026-08-05-pr-309-release-blockers.md` — external rollout gates.
- Commit `2eb39da` — verbatim import of the production ruleset baseline.
- Commit `e4c16de` — original FCM implementation whose device-ID scheme
  required the `devices/{document=**}` rule removed by decision 8.

## Revision history

- **2026-09-13** — Original record, committed as `3060c3a`.
- **2026-09-13** — Revised in place while still `proposed`:
  - **Decision 5 corrected.** The original stated that anonymity is enforced
    in the Cloud Functions layer. It is not: `extractAndVerifyUid` never
    inspects `sign_in_provider`, and the only check is client-side. A
    server-side check is now recorded as required work.
  - **"Anonymous" pinned to not-signed-in users**, after confirming
    `signInAnonymously` appears nowhere in `lib/` and that Firebase anonymous
    auth users do not exist in this app.
  - **Decision 8 added**, bringing `devices/{document=**}` into scope for
    deletion on the evidence that it supports no current or shipped code
    path, and that this branch makes it destructive.
  - **Out-of-scope section narrowed** to the `/{document=**}` read catch-all,
    with the client content-fetch evidence for why it must stay.
  - Corrected the new-collection count from six to five.

  Revised in place rather than as a superseding record because the ADR has not
  been accepted by any decider; the original text remains in git history at
  `3060c3a`.
