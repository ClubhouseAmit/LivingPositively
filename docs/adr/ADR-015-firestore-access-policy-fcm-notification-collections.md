# ADR-015: Firestore Access Policy for FCM Notification Collections

- **Status**: proposed
- **Date**: 2026-09-13
- **Deciders**: <!-- repository collaborator -->
- **Tags**: firestore, security-rules, notifications, fcm, privacy, ci

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
3. Anonymous users remain supported and cannot set reminders.
4. No user may read another user's reminder settings.
5. Future work adds further notification types and user-defined custom
   reminders; the policy must absorb those without a rules change per type.

Constraint 4 is not expressible as a path-based ownership rule for
`scheduled_notifications`: the owning UID is encoded inside the base64url
document ID rather than carried as a path segment, and a `resource.data.uid ==
request.auth.uid` condition cannot constrain `list` queries, only single-
document `get`s.

## Decision

**1. The repository is the canonical source of Firestore rules.**
`firestore.rules` is registered in `firebase.json` and deployed by CI. Console
edits are drift and are surfaced as a failing check, not silently overwritten.

**2. All six new collections are server-only.** No client, authenticated or
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

**5. Anonymity is enforced in the Functions layer, not in rules.** Rules deny
all direct client access uniformly, so they cannot express "non-anonymous
users may set reminders." That check stays where it already lives, in the
register and cancel handlers, consistent with the FCM-05 decision. Constraint
3 is an application authorization rule; constraint 1 and 4 are a data access
rule. They are enforced at different layers on purpose.

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

### Explicitly out of scope

The imported baseline also contains two pre-existing weaknesses:
`/{document=**}` grants unauthenticated read of every document, and
`/devices/{document=**}` grants unauthenticated read *and write* of every
device and FCM-token record. Decision 3 removes the first one's reach over the
new collections only; it does not otherwise narrow either rule. Both predate
this branch, both apply to objects already on `main`, and constraint 2 keeps
them as they are. They are tracked separately and are not resolved here.

This is a deliberate, bounded acceptance: the new collections are protected,
the rest of the database remains as exposed as it is in production today.

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

### Negative

- Modifying the catch-all touches a rule that governs every collection in the
  database. The blast radius is the whole ruleset, which is why decision 7
  requires the unchanged-behavior assertion before deploy.
- A future client feature that needs direct read access to
  `notification_types` requires a rules change and its own decision record.
- The database remains world-readable outside the new collections, and device
  records remain publicly writable. This branch does not improve that.

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
