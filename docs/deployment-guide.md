# Deployment guide — PR #273 / version 1.7.0

This is the deployment entry point for `feature/basic-fcm-setup` → `main`.
Updated 2026-09-03, including the Functions CI deployment job. Recheck the linked
workflow and scripts when deploying a later revision. This document records
the release procedure, not evidence that production prerequisites are complete.

The changing parts are environment configuration, provider credentials,
deployed client versions, and notification content. Keep them tied to the
selected release revision; do not infer their readiness from a successful build.

## 1. Understand what runs automatically

The authoritative automation is [Build production artifacts](../.github/workflows/main.yml).

| Component | Pull request targeting `main` | Push/merge to `main` |
| --- | --- | --- |
| Notification backend | Node 22 install, tests, production dependency audit | Provision changed notification content and deploy changed Functions to `mezilondb` after the aggregate and Functions checks pass |
| Android | Signed AAB artifact, unit and emulator checks | AAB published to Google Play **internal testing** after dependent gates and the notification-backend gate pass |
| iOS | Simulator FCM integration test | Same test; **no signed IPA or App Store upload** |
| Web | Development Azure static-site deployment when credentials are available | Production Azure static-site deployment |

Merging is therefore a release action for changed notification content or
Functions, Android internal testing, and the production website. Android and
production web wait for the notification-backend gate. Only a detected backend
change enters the protected `firebase-production` environment and requests any
configured approval; no-op backend plans pass the gate without production
approval. Google Play production promotion and iOS distribution remain manual.

The unprotected notification-backend planning job compares the selected
revision with the latest earlier successful `main` push, including changes from
intervening failed runs. Runtime source/configuration changes deploy Functions.
Notification ARBs or provisioner changes run content provisioning. Test-only,
documentation-only, and unrelated workflow changes do not release production
backend code. Changes inside the workflow's marked notification-backend block
do trigger a Functions deployment. When comparison history is unavailable or
malformed, both operations run conservatively. PRs never receive deployment
credentials or execute a release.

The main workflow is serialized. A deployment also rejects a revision if
`main` has already advanced, preventing an old rerun from rolling Functions
back; use the newer main run in that case. Failure to fetch comparison history,
authenticate, provision, or deploy fails the job and blocks Android internal
publishing and the production web release.

## 2. Complete the external prerequisites before rollout

Record the owner, evidence, target project, and selected commit in the release
ticket. The repository does not verify these external settings for you.

- [ ] Confirm the Firebase project and app identities. The current app sends
  reminder HTTP requests to `us-central1-mezilondb.cloudfunctions.net`, and
  [.firebaserc](../.firebaserc) defaults to `mezilondb`. Changing only a CLI
  `--project` argument or FlutterFire options does **not** retarget that client.
  A different environment needs a separately reviewed configuration change.
- [ ] Obtain the canonical production Firestore rules and their deployment
  owner. There is no rules deployment target in [firebase.json](../firebase.json).
  Preserve unrelated access policy; do not create a replacement root rules
  file or run a blanket Firebase deployment from this checkout.
- [ ] Provide reviewed rules and authenticated emulator get/list/create/update/
  delete test evidence denying client access to `notification_deliveries`,
  `notification_scheduler_state`, `notification_mutation_state/{uid}`, and
  `notification_mutation_state/{uid}/types/{typeId}`. Verify owner-only,
  field-constrained device token writes to `devices/{uid}` as well. See the
  [rules handoff](plans/2026-07-31-pr-273-fcm-remaining-work.md#firestore-access-policy-handoff).
  **Do not provision content or deploy/enable these Functions before this gate.**
- [ ] Configure Firestore TTL for collection group `notification_deliveries`,
  field `expiresAt`. The scheduler writes delivery claims with a 24-hour
  expiration; the field alone does not configure TTL in the target project.
- [ ] Verify the target project's required Firestore indexes for the scheduler
  queries, billing, Functions/Scheduler/FCM availability, and deploy/runtime
  permissions. There is no checked-in index deployment manifest. Do not use
  production canaries as the first index check.
- [ ] Complete Firebase Auth, signing, OAuth, and APNs setup in the
  [authentication rollout guide](auth-provider-rollout.md). Android's app ID is
  `com.matzilon.mezilon`; iOS uses `com.clubhouse.livingpositively`.
- [ ] Validate the release FlutterFire options, including the CI
  `FIREBASE_OPTIONS` secret. The checked-in iOS options still identify
  `com.example.mezilon`; they are **not** the production iOS configuration.
  Obtain/regenerate the correct app configuration rather than guessing client
  IDs or changing just the bundle-ID string.
- [ ] Record whether any already-distributed clients call the remote reminder
  APIs without `expectedMutationVersion`. If so, obtain an approved rollout
  for compatible clients/minimum versions before deploying the fence: those
  requests can receive HTTP 409 once mutation state exists. If this is the
  first remote-reminder release, record that evidence instead of inventing an
  old remote-client population. Only after that evidence is approved, set the
  protected `firebase-production` environment variable
  `NOTIFICATION_MUTATION_FENCE_CLIENT_ROLLOUT_APPROVED` to exactly `true`.
  Functions releases fail closed while this value is unset or has any other
  value; content-only provisioning does not require it.
- [ ] Assign an operator to scheduler/error monitoring and confirm the rollback
  procedure before making the scheduled function live.

### Legacy reminders: local, not remote

The released legacy reminder was an Android device-local notification. It is
not evidence of UUID-keyed remote schedules and does not require an invented
UUID → Firebase UID ownership mapping. Historical plan text suggesting such a
production migration is not a deployment prerequisite for this release.

Current [local migration code](../lib/util/Firebase/fcm_scheduled_notification_service.dart)
requires `legacyDefaultReminderEnabled == true`, a valid persisted hour/minute,
an eligible authenticated session, and an unset `fcmDefaultReminderMigrated`
marker. On success it registers the remote reminder, cancels the local alarm,
then writes the completion marker. It is Android-only. Hour/minute defaults
alone are not consent: do not set enabled markers in bulk to force migration.
Users without verified enabled state must explicitly enable their new reminder.

## 3. Validate the selected revision

Use Flutter **3.44.0**, JDK **17** for Android, and Node.js **22** for Functions,
matching the workflow. The app version in [pubspec.yaml](../pubspec.yaml) is
`1.7.0`. Work from the repository root with the release configuration installed.

```sh
flutter pub get
flutter analyze
flutter test --coverage
dart run scripts/check_coverage.dart
npm --prefix functions ci
npm --prefix functions test
node --test scripts/tests/functions_deployment_changes.test.mjs
npm --prefix functions audit --omit=dev --audit-level=low
```

Also review the selected revision's Android integration, iOS integration, web
telemetry, and coverage-aggregate results. Web telemetry is intentionally
observational (`continue-on-error`) and does not gate the backend release; the
aggregate and Functions jobs do. Local unit tests do not substitute for
device/simulator checks. When `coverage-aggregate` fails because an upstream
job failed, investigate that upstream job before changing coverage. Use current
run evidence, not a green run from an earlier commit.

## 4. Configure notification backend CI and content provisioning

### One-time service-account credential setup

After completing section 2, configure the GitHub environment
`firebase-production` under repository Settings → Environments. Restrict its
deployment branches to `main`. If the release owner requires an approval,
configure its required reviewers there; the workflow honors environment rules.
The environment is assigned only to the actual release job after unprotected
change detection reports that Functions deployment or content provisioning is
required.

Create/use a dedicated deployment service account in `mezilondb`. Have the IAM
owner grant the Functions deployment permissions, including permission to act
as the runtime account and manage the scheduled function's Cloud Scheduler job.
Firebase documents Cloud Functions Admin and Service Account User for deployment;
the owner must also verify the target project's API, build, and second-generation
Cloud Run/Scheduler permissions. See [Firebase deployment IAM](https://firebase.google.com/docs/projects/iam/permissions#cloud-functions-for-firebase-permissions).

Create a JSON key for that dedicated deployment service account and store the
entire JSON document as the `FIREBASE_SERVICE_ACCOUNT_JSON` environment secret
on `firebase-production`. Do not commit the key, place it in workflow YAML, or
store it as a repository variable. Restrict access to the environment and rotate
the key immediately if it is exposed.

The release validates that the secret is parseable service-account JSON for
`mezilondb` and contains the required identity and private-key fields without
printing credential contents. A Functions release separately requires the
protected environment variable
`NOTIFICATION_MUTATION_FENCE_CLIENT_ROLLOUT_APPROVED=true`; configure it only
after the compatible-client or first-remote-release evidence in section 2 is
approved.

The pinned Google authentication action writes an ephemeral credentials file
for the job and exposes Application Default Credentials to both the Admin SDK
provisioner and Firebase CLI. The credentials file is removed by the action's
post-job cleanup. This follows the CLI's [CI authentication mechanism](https://firebase.google.com/docs/cli#cli-ci-systems).

A missing or invalid `FIREBASE_SERVICE_ACCOUNT_JSON` secret fails a related
backend release with an explicit setup message; it is not treated as success.
Adding this workflow does not create IAM resources, configure production
rules/TTL, or seed Firestore. Complete that setup before the first related merge
to `main`.

### Content provisioning and first rollout

Only proceed after section 2 is signed off. CI automatically runs the Admin SDK
provisioner when one of the notification-content ARBs or provisioner sources
changed since the last successful main release. The authenticated release job
records provisioning success before the backend gate allows Android or
production web to release. A failure stops the gate and leaves those dependent
releases blocked.

For first-rollout preparation or manual recovery, use an authorized release
environment with Application Default Credentials. Do not commit credentials or
paste them into logs.

The following is **Bash syntax**, run from the repository root. Set the project
explicitly after verifying it matches the intended client; do not rely on the
default alias. These commands write to the target project.

```bash
export DEPLOY_PROJECT='mezilondb'
npm --prefix functions run provision:notifications -- --project "$DEPLOY_PROJECT"
```

Before provisioning, back up the existing affected content and review the ARB
quote changes in this release. The
[provisioner](../functions/src/notification_provisioning.ts) reads the Hebrew,
Arabic, and English ARBs, overwrites `notification_types/default` and generated
`inspirationalQuotesNoN` documents in `quotes_he`, `quotes_ar`, and `quotes_en`,
and **deletes obsolete generated quote IDs**. Other quote IDs are retained.
There is no dry-run flag, and a failed run can leave partial changes; inspect
the target before retrying. Keep backup evidence for recovery.

Provisioning before enabling the new scheduler ensures content is available
for its first run. If a scheduler already operates on these collections, the
release owner must arrange the maintenance window before provisioning because
these writes are not atomic.

Once prerequisites are ready, merge the tested changes to `main` and watch
**Release changed notification backend** in Build production artifacts. When
runtime inputs changed, CI installs Node 22, the locked Functions dependencies,
and Firebase CLI `15.29.0`, then runs:

```sh
firebase deploy --only functions --project mezilondb --non-interactive
```

The deployment builds TypeScript through the configured predeploy hook. It
omits `--force`, so function deletion requests needing confirmation fail for
review rather than being automatically approved. The
current exports are `registerNotification`, `cancelNotification`,
`getNotificationMutationVersion`, and `processScheduledNotifications`.
The scheduled function runs every minute with a 300-second timeout and 512 MiB
memory. **Treat deployment as making it live**: there is no repository rollout
flag that keeps it disabled after deployment. The compatibility gate above is
therefore a pre-deployment requirement, not a runtime kill switch.

Content provisioning is deliberately part of this protected release job because
the mobile/web artifacts consume that content. Configure a required reviewer on
the `firebase-production` environment if production writes need an explicit
human approval. An ARB-only change provisions content without needlessly
redeploying Functions. An operator can use the same commands from an
authenticated release environment when manual recovery is needed.

Verify the endpoints match the app's `us-central1` URL, the scheduler job exists,
and logs show successful queries/content loading before releasing clients.
If activation reports `getNotificationMutationVersion failed: 404`, check this
deployment job and `firebase functions:list --project mezilondb`. A successful
build/test job alone does not publish the endpoint. After correcting credentials
or permissions, rerun the failed main workflow if it is still the current main
revision; otherwise use its newer run, which includes pending Functions changes.

## 5. Build and distribute the mobile apps

### Android

Configure these Actions secrets before merging:

| Purpose | Exact secret names |
| --- | --- |
| Signing | `APPSIGNINGKEY` (base64 keystore), `APPSIGNINGKEYPASSWORD`, `APPSIGNINGKEYSTOREPASSWORD` |
| Firebase | `FIREBASE_OPTIONS` (base64 release Dart options file) |
| Google sign-in | `GOOGLE_SIGN_IN_SERVER_CLIENT_ID` (Web OAuth client ID) |
| Telemetry | `MIXPANEL_PROJECT_TOKEN`, `SENTRY_DSN` |
| Play internal upload | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` |

The workflow creates `app-release` from
`build/app/outputs/bundle/release/app-release.aab`. Its version name combines
the pubspec version and commit hash; its build number uses `GITHUB_RUN_NUMBER`.
Check that the version code is acceptable for the existing Play listing.
After the main-branch internal release succeeds, install that exact artifact
through internal testing. Promote to wider distribution only after section 7.

### iOS — manual, on a signing-capable Mac

Follow [the provider setup](auth-provider-rollout.md), including the correct
Firebase iOS app, OAuth callback scheme, provisioning profiles, and APNs key.
Populate the ignored `ios/Flutter/GoogleSignIn.xcconfig` from its
[example](../ios/Flutter/GoogleSignIn.xcconfig.example). Verify native and Dart
Google client IDs match the production Firebase app.

Set the three Google variables and `APPLE_SIGN_IN_ENABLED` in your release
environment, then run from the repository root:

```bash
./scripts/build_ios_release.sh
```

The [script](../scripts/build_ios_release.sh) requires
`GOOGLE_SIGN_IN_SERVER_CLIENT_ID`, `GOOGLE_SIGN_IN_IOS_CLIENT_ID`, and
`GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT_ID`, checks them against the native config,
and passes the two client IDs to Dart. `APPLE_SIGN_IN_ENABLED` must be explicit
`true` or `false`; there is no default and no true-only enforcement. Choose the
value through the release owner's provider decision, not as a workaround for
missing setup. Google configuration is required even when Apple is disabled.

Before archiving, assign a new release build number in the approved release
configuration/pubspec. Unlike Android CI, this script does not supply a build
number or forward extra command-line arguments. It also does not pass telemetry
Dart defines; do not assume Android's telemetry settings reach the IPA.
Verify the archive's version, signing, capabilities, and intended telemetry
configuration. Upload the resulting IPA through the team's approved
TestFlight/App Store procedure. Simulator CI does not prove physical-device
APNs delivery or provider sign-in works.

## 6. Web deployment configuration

The current workflow uses storage account keys, with these exact secrets:

- Production: `AZURE_WEB_STORAGE_ACCOUNT`, `AZURE_WEB_STORAGE_KEY`.
- Development: `AZURE_DEV_WEB_STORAGE_ACCOUNT`, `AZURE_DEV_WEB_STORAGE_KEY`.
- Both: `FIREBASE_OPTIONS`, `MIXPANEL_PROJECT_TOKEN`, `SENTRY_DSN`.

Confirm the intended accounts have static website hosting configured. Uploads
target the `$web` container with overwrite enabled. Preserve the previous web
artifact for rollback. The older Azure setup document describes a different
credential setup; use the current workflow for secret names and actual behavior.
FCM reminder delivery is a mobile capability; do not require web push as a
release acceptance criterion for this branch.

## 7. Run canaries before wider release

Use dedicated test accounts and record the artifact version and result.

- [ ] Sign in with new and existing accounts using the configured Android/iOS
  providers; restart and verify session restoration. Test terminated-app
  notification taps as well as background taps.
- [ ] Grant notification permission on a physical Android and iOS device.
  Verify `devices/{Firebase UID}` receives the token and server timestamp,
  then register a default reminder and observe delivery. Test Hebrew, Arabic,
  and English content. Scheduling uses Israel local time.
- [ ] Reopen Notifications offline and after permission changes. Confirm the
  screen settles and a registered reminder can be cancelled after permission
  revocation. Verify cancellation removes the server schedule.
- [ ] Exercise a verified-enabled legacy Android reminder and an install with
  only default hour/minute values. Only the explicitly enabled case should
  migrate; successful migration should retire its local alarm.
- [ ] Test reset with a remote reminder, including when no local preference
  exists. A cancellation failure or active delivery-permit HTTP 409 must not
  report a successful reset. Retry after the in-flight operation has ended.
- [ ] Verify a token refresh and the documented one-token-per-UID behavior
  (the latest device registration wins).
- [ ] Exercise duplicate/delayed scheduler invocations and DST boundary cases
  in the controlled test environment. Ordinary 02:xx times are valid; the
  nonexistent Israel spring-transition occurrence is skipped.

Monitor scheduler errors, repeated `claimFailed` counts, recovery-window clamp
and bounded-page warnings, stale-device cleanup backlog, and delivery claims
that never reach a terminal status. Both normal and recovery queries are paged.
The scheduler is best-effort at-most-once: ambiguous/failed claimed deliveries
are not automatically resent, and catch-up is bounded to the preceding two
hours. Do not promise guaranteed delivery or unlimited outage recovery.

## 8. Stop and roll back safely

If canaries fail, stop wider mobile promotion and have the release operator
pause affected scheduled delivery through the approved cloud operations path.
Record the failing revision, timestamps, and logs before changing anything.

Restore only a known-compatible backend revision and reviewed content backup.
Do not delete delivery claims, mutation versions, or scheduler checkpoints to
force retries: that can invalidate duplicate-delivery and cancellation fences.
Older mobile/backend versions are not automatically safe downgrade targets.
Restore the previously retained web artifact if the website regresses; do not
use a blanket Firebase deploy as a rollback command.

Record backend deployment, content provisioning, store artifacts, CI results,
rules/TTL evidence, canary results, and the rollback revision in the release
ticket. Historical [FCM decisions](plans/2026-07-31-pr-273-fcm-remaining-work.md)
and [release-blocker notes](plans/2026-08-05-pr-309-release-blockers.md) provide
context, but their old test counts and legacy assumptions are not current
release evidence.
