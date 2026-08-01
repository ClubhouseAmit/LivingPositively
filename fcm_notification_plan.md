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

1. Deploy the Functions code through the normal project deployment process.
2. With explicit project selection and suitable credentials, run the
   provisioning command above.
3. Configure Firestore TTL for
   `notification_deliveries.expiresAt` outside this repository. No TTL policy
   is provisioned or assumed here.
4. Inventory any production schedules and `devices` documents created with
   legacy UUID identifiers. The repository contains no verified mapping from
   those identifiers to Firebase UIDs, so decide whether to migrate that data
   with an approved ownership mapping or retire it explicitly before relying
   on UID-keyed delivery.
5. Perform the appropriate manual emulator, physical-device, and production
   validation: authenticated registration/cancellation, token refresh,
   delayed scheduler delivery, duplicate-claim suppression, failure handling,
   and reset/migration behavior.
6. Resolve and merge this stacked change through the parent/stacked PR flow.
