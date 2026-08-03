# FCM scheduled notifications — implementation handoff

This document records the implemented scheduled-notification behavior and the
external work still required to operate it. It is intentionally a handoff, not
a deployment checklist or a statement that Firebase resources have been
configured.

## Implemented behavior

### Authentication and app lifecycle

- Scheduled notification registration and cancellation use the authenticated
  Firebase ID token. Anonymous and missing Firebase users cannot create or
  cancel a remote schedule.
- The app stores the current FCM token in `devices/{uid}`. There is one device
  document per user, so the latest token overwrites the previous token
  (last-token-wins).
- Signing in refreshes the device-token document and attempts the legacy
  reminder migration.
- Reset does not sign the Firebase user out and no Workmanager job is used.
  For a non-anonymous authenticated user, reset first cancels the remote
  `default` reminder. A failed cancellation keeps local data and navigation in
  place. After a successful reset, local profile data is cleared and the
  authenticated identity is restored from the current Firebase user.

### Schedule registration and legacy migration

- A schedule contains a `typeId`, Israel-local `hour`/`minute`, locale, and
  normalized gender. The client updates its local preference only after the
  remote registration or cancellation succeeds.
- The legacy local `default` preference migration runs during app startup and
  after successful authentication. It registers once and writes its local
  marker only after a successful remote registration.
- Schedule mutations and the migration are serialized in the existing FCM
  scheduled-notification service. Reset disables an in-flight migration before
  it can register. A successful reset cancellation leaves that migration
  disabled for the app session; a failed or thrown cancellation re-enables a
  subsequent migration attempt.
- Every current-client schedule mutation first reads the authoritative
  `notification_mutation_state/{uid}/types/{typeId}` version and sends the `typeId`
  and version as
  `expectedMutationVersion` to the register/cancel Function. The Function
  transaction applies the mutation only when that version still matches, then
  advances it. A versioned registration stores that advanced value as
  `mutationVersion` on its schedule document. Reset advances a local epoch
  before cancellation, so work that has not left the app stops; a request that
  has already left is rejected by the server if reset wins the transaction.
- `getNotificationMutationVersion` requires a validated `typeId` and returns
  version 0 when that schedule type has no state document. Legacy requests
  without an expected version remain accepted only until that schedule type is
  fenced by a versioned mutation or reset.
  Afterwards the Function returns 409 for an unfenced request, preventing an
  older app request from recreating a reminder after reset.
- Reset cancellation additionally sends `resetFence: true`. If the scheduler
  has already committed authority to initiate the matching FCM send, the
  active delivery permit makes that cancellation return 409. The app treats
  this as a cancellation failure and preserves local data; a reset never
  claims success while that send can still begin.

### Server delivery

- `processScheduledNotifications` runs once per minute. From the scheduler
  event time, it derives Israel-local intended times from now back through the
  previous 120 minutes (inclusive), so a delayed invocation can still process
  the intended reminder time.
- It retains the existing dynamic/static notification-content behavior. Dynamic
  messages select a localized quote and gender fallback; static messages use
  the stored title and body.
- Before FCM send, the function atomically creates a claim in
  `notification_deliveries/{deliveryKey}`. The key is base64url JSON encoding
  of `[uid, typeId, localDate, intendedHHmm]`, avoiding delimiter collisions
  and remaining valid for both Firestore document IDs and FCM data.
- The claim transaction re-reads the selected schedule and its matching
  `notification_mutation_state/{uid}/types/{typeId}` document. It sends only when
  the selected/current schedule mutation versions still agree; a deleted or
  replaced schedule is skipped without an FCM call or checkpoint failure.
- The same transaction records a delivery permit that expires 305 seconds
  after server time. The send releases only its matching permit in `finally`;
  a failed release is deliberately conservative and blocks reset until expiry.
  Legacy schedules without a mutation version are current only when both the
  selected and re-read `updatedAt` timestamps are valid and equal.
- The delivery record contains its identity, `claimed`/`sent`/`failed` status,
  claim and attempt timestamps, the FCM message ID or failure code, and an
  `expiresAt` value of intended time plus 24 hours. The FCM payload also
  includes `deliveryKey`.
- A duplicate claim means no FCM resend. This is intentional even when the
  original FCM result was ambiguous or failed: one claimed delivery gets one
  send attempt.
- Invalid registration-token responses still clear the FCM token from the
  existing `devices/{uid}` document. Long-inactive device cleanup remains in
  the scheduled function.

### Content provisioning

- Notification content is provisioned by an idempotent command that validates
  an explicit Firebase project ID and writes the notification type and
  localized quote documents:

  ```powershell
  npm --prefix functions run provision:notifications -- --project <firebase-project-id>
  ```

  It requires credentials appropriate for that project. The command has not
  been run by this repository change.

## Remaining external work

The following are deployment gates, not application configuration. Do not
deploy or enable scheduled delivery until each gate is satisfied:

1. Configure Firestore TTL for `notification_deliveries.expiresAt` in the
   canonical production Firebase configuration.
2. Add server-only deny rules for `notification_deliveries`,
   `notification_scheduler_state`, and both the parent and `types`
   subcollection paths of `notification_mutation_state` to the
   canonical production rules source, and verify authenticated emulator
   read/list/create/update/delete denial for all three collections.

   ```rules
   match /notification_mutation_state/{uid} {
     allow read, write: if false;
   }
   match /notification_mutation_state/{uid}/types/{typeId} {
     allow read, write: if false;
   }
   ```
3. Deploy the Functions code through the normal project deployment process
   with the approved scheduler invocation bound of 300 seconds, 512MiB, and
   25 task batches. These bounds preserve all-or-nothing recovery: a recovery
   that cannot finish leaves its checkpoint for a later invocation.
4. Configure monitoring alerts for repeated claim failures and claimed
   delivery records that age without a terminal status.
5. With explicit project selection and suitable credentials, run the
   provisioning command above.
6. Inventory any production schedules and `devices` documents created with
   legacy UUID identifiers. The repository contains no verified mapping from
   those identifiers to Firebase UIDs, so decide whether to migrate that data
   with an approved ownership mapping or retire it explicitly before relying
   on UID-keyed delivery.
7. Perform the appropriate manual emulator, physical-device, and production
   validation: authenticated registration/cancellation, token refresh,
   delayed scheduler delivery, duplicate-claim suppression, failure handling,
   reset/migration behavior, and reset rejection while an authorized send is
   in flight.
8. Deploy the Functions version-read and expected-version support before a
   mobile release that sends `expectedMutationVersion`. This ordering preserves
   current legacy behavior until an account is fenced; after fencing, legacy
   reminder mutations are deliberately blocked to preserve reset privacy.
9. Resolve and merge this stacked change through the parent/stacked PR flow.
