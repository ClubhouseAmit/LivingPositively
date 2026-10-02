# Social authentication rollout

Social providers are hidden unless their build-time configuration is explicit.
Do not commit OAuth client IDs, Apple private keys, APNs keys, or other provider
credentials to the repository. Supply build defines from the release environment
or CI secret store.

## Google sign-in on Android and iOS

Google sign-in is available on Android when
`GOOGLE_SIGN_IN_SERVER_CLIENT_ID` is nonempty. On iOS it additionally requires
`GOOGLE_SIGN_IN_IOS_CLIENT_ID`, the client ID registered for
`com.clubhouse.livingpositively`. The server client ID is the OAuth 2.0 **Web
application** client ID that Firebase Authentication expects as the Google ID
token audience; do not use an Android or iOS OAuth client ID in its place.

Before enabling it:

1. Enable Google as a sign-in provider in Firebase Authentication.
2. Register the Gradle Android application ID `com.matzilon.mezilon` and the
   SHA-1/SHA-256 fingerprints for every signing certificate used by release,
   internal, and development builds. The source namespace
   `com.example.mezilon` is not the OAuth application ID.
3. Create or select the matching Web OAuth client in the same Google Cloud /
   Firebase project and configure the OAuth consent screen.
4. For iOS, register `com.clubhouse.livingpositively` as an iOS app in the
   Firebase project, enable Google in Firebase Authentication, and download
   its current `GoogleService-Info.plist`. Confirm the FlutterFire options
   identify that production Firebase app before building.
5. For iOS, configure `GOOGLE_SIGN_IN_SERVER_CLIENT_ID`,
   `GOOGLE_SIGN_IN_IOS_CLIENT_ID`, and
   `GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT_ID` in the release environment. Run
   `bash scripts/prepare_ios_google_sign_in_config.sh` as a Codemagic pre-build
   step. It validates the values and generates the ignored
   `ios/Flutter/GoogleSignIn.xcconfig`; the native plist uses that file for
   `GIDClientID`, `GIDServerClientID`, and the required URL callback scheme.
6. Inject the required Dart defines when building. For example:

   ```shell
   APPLE_SIGN_IN_ENABLED=true \
   GOOGLE_SIGN_IN_SERVER_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com \
   GOOGLE_SIGN_IN_IOS_CLIENT_ID=YOUR_IOS_CLIENT_ID.apps.googleusercontent.com \
   GOOGLE_SIGN_IN_IOS_REVERSED_CLIENT_ID=com.googleusercontent.apps.YOUR_IOS_CLIENT_ID \
   ./scripts/build_ios_release.sh
   ```

For the production Android pipeline, set the repository Actions secret named
`GOOGLE_SIGN_IN_SERVER_CLIENT_ID`. The `main` App Bundle build passes it as a
`--dart-define` and fails before release if the secret is empty or whitespace.

An omitted or whitespace-only required value intentionally hides the Google
button. The native URL scheme remains required even when the Dart client ID is
present.

## Sign in with Apple on iOS

The Apple button is available only on iOS and only when
`APPLE_SIGN_IN_ENABLED=true`.

The app delegates the native Apple authorization and nonce binding to
Firebase Authentication through `AppleAuthProvider` and
`signInWithProvider`. The existing `sign_in_with_apple` dependency and
Apple-branded UI remain in place, but the app does not use the package to
construct Firebase credentials manually.

Before enabling it:

1. Enable Push Notifications and Sign in with Apple for the Apple App ID
   `com.clubhouse.livingpositively`.
2. Regenerate the development and distribution provisioning profiles after the
   capabilities are enabled.
3. Enable Apple in Firebase Authentication and configure the required Apple
   Team ID, Services ID, Key ID, and Sign in with Apple private key in the
   provider console.
4. Upload the APNs authentication key to Firebase Cloud Messaging for the iOS
   application.
5. Set `APPLE_SIGN_IN_ENABLED` explicitly before invoking
   `scripts/build_ios_release.sh`: `true` enables Apple Sign-In and `false`
   disables it. The script rejects an unset or invalid value before archiving.

The release owner accepts this documented manual iOS release procedure. The
checked-in release script enforces the flag and verifies its values match the
ignored native configuration before archiving. The committed entitlements
declare both capabilities, but they do not replace Apple Developer,
provisioning-profile, or Firebase Console configuration. An omitted or false
flag intentionally hides the Apple button.

## Verification before rollout

- Install a signed build that uses the production signing identity and profile.
- On Android, complete Google sign-in with a new account and an existing account.
- On iOS, complete Google and Apple sign-in with a new account and an existing
  account.
- Confirm Firebase Authentication records the expected provider.
- On a physical iOS device, confirm APNs registration and one FCM delivery.

## ADR-018 Google Sign-In 7 release gate

Status on 2026-10-01: **BLOCKED: real-account device validation unavailable.**
The owner confirmed that no device testing is currently available. Mocked auth
tests and the notification simulator test do not satisfy ADR-018's authentication
acceptance requirement. Keep PR #420 in draft until the evidence below exists.

### Builds and configuration

Use the candidate commit, Flutter 3.47.5, and the committed Dart/native locks.
Record the commit, artifact identifier, OS version, package/bundle ID, and
certificate fingerprints with each result. Do not attach tokens or account data.

- Android: use a release-signed candidate with the production Web client ID.
  The existing release pipeline signs only trusted `main` revisions; PR jobs
  produce test evidence without a production-signed bundle. Prepare a candidate
  through the release owner's signing process. If distributed through Play,
  check the Play app-signing certificate fingerprints, which may differ from
  the upload key. Confirm those fingerprints and `com.matzilon.mezilon` match
  the Android OAuth registration in the same Firebase project as the Web ID.
- iOS: use the existing macOS CI/Codemagic release environment to run
  `scripts/build_ios_release.sh` with production provider values and signing
  profile. Install the signed archive on an iPhone. Confirm the iOS client ID,
  Firebase options, bundle ID, and generated callback URL scheme agree. The
  simulator telemetry job does not produce this signed device build.

The [official Android plugin configuration guide](https://pub.dev/packages/google_sign_in_android)
also notes that some Credential Manager configuration failures appear as
`canceled`. A neutral cancellation result alone cannot prove configuration.
Successful real-account authentication is required on each platform.

### Required device results

| Check | Android release / production certificate | iOS signed / production configuration |
| --- | --- | --- |
| New and existing Google account sign-in produces the expected Firebase user/provider | NOT RUN | NOT RUN |
| Dismiss/back from account UI leaves Firebase signed out and permits the next attempt | NOT RUN | NOT RUN |
| Sign-out clears Firebase state; the next sign-in succeeds | NOT RUN | NOT RUN |
| Restart while signed in, then sign out and sign in again | NOT RUN | NOT RUN |
| Kill/background immediately after Firebase logout; record prior-account offering/preselection and ensure no automatic Firebase authentication | NOT RUN | NOT RUN |
| Slow cleanup: Google retry shows close/reopen guidance; a settled cleanup permits retry without restart | NOT RUN | NOT RUN |
| Interrupt the flow/background the app, return, and retry | NOT RUN | NOT RUN |
| Android with no Google account: record the actual add-account flow or error and subsequent recovery | NOT RUN | N/A |
| After success, FCM token registration and legacy reminder migration still run | NOT RUN | NOT RUN |
| Configured analytics receives started/success/canceled/interrupted/uiUnavailable outcomes with platform, without account data | NOT RUN | NOT RUN |

Record actual SDK exception codes for dismissal/interruption/no-account outcomes.
Do not infer them from mocks. A configuration failure is a failed validation,
including a misleading `canceled` result when the next complete sign-in fails.

### Simulator evidence is separate

For an explicit macOS simulator validation run, dispatch the existing workflow:

```shell
gh workflow run _ios-integration.yml --ref Tovli/adr-upgrade-flutter-functions \
  -f refresh-pod-lock=false -f require-simulator-test-success=true
```

Download `ios-integration-diagnostics`, check `test-step-outcome.txt` and
`post-test.txt` (`=== flutter test exit ===` followed by `0`). The manual input
requires the actual test outcome to be `success`; ordinary PR telemetry retains
its ADR-006 policy. These tests cover notifications/persistence, not Google
account authentication. They cannot close the device rows above.

### Authentication observability and recovery

`Google sign-in outcome` uses the existing `AnalyticsService`/Mixpanel channel.
Each offered attempt records `started` and its result: `success`, `canceled`,
the SDK error code, `initializationFailed`, or `failed` for other failures.
`appCanceled` identifies attempts superseded by logout; `cleanupPending`
identifies a retry while native cleanup is still running. Neither counts as a
provider dismissal or sign-in failure.
The only explicit properties are `outcome` and `platform`; provider descriptions,
tokens, client IDs and account details are excluded. Telemetry failure cannot
block sign-in. An unavailable analytics service or absent Mixpanel token sends
no event; verify receipt in the production telemetry project before rollout.

Operators can group the event by platform and outcome for the candidate app
version using their Mixpanel release metadata. Compare started and successful
attempts with cancellations and unavailable-UI outcomes. A sustained increase
without successful Android sign-in requires checking the release signing SHA,
package name and server client ID. The SDK cannot tell an individual dismissal
apart from its configuration-related `canceled` result, so cancellations are
counted in analytics as ambiguous results. Individual dismissals produce no
incident. Three cancellations within five minutes without an intervening success produce a
credential-free `Repeated Android Google sign-in cancellations` incident with
a stack trace. Reports are capped at one per incident logger instance (normally
one app run), independently of Mixpanel. A successful authentication resets the
retry count. This is a repeated-failure signal, not proof of misconfiguration.
The Android release build requires `SENTRY_DSN`. Before rollout, verify receipt
and record the alert owner, threshold and quota/sampling settings. Production
usage volume and those settings were not available in this review, so no daily
quota estimate or configured alert is claimed. Device success remains required.

`interrupted` and `uiUnavailable` retain localized retry guidance and analytics
counts without creating an incident per dismissal. Unknown and configuration
errors still go to incident telemetry. A failed initialization is cached under
the SDK's exactly-once contract; it shows localized close/reopen guidance and
reports the original error/stack once per SDK instance, shared with sign-out.
There is no verified device evidence classifying such failures as transient or
permanent. Restart permits a new initialization, and persistent failure requires
support/configuration investigation rather than repeated taps.

Configured Google cleanup initializes the SDK on cold-start sign-out too.
Every logout clears Firebase, even while an earlier provider cleanup remains
pending. Already-issued Google credential exchanges must settle within five
seconds before Firebase is cleared. If that wait expires, logout throws rather
than reporting success; the settings caller restores cancelled reminders and
keeps the logged-in UI. A timed-out exchange wait schedules no later Firebase
logout. If the exchange later succeeds after failed logout, its credential is
returned through normal sign-in success handling, so the app handles that account
instead of silently discarding its Firebase session. Logout can then be retried.
Only successful Firebase logout cancels an already-issued exchange. This prevents an
exchange from restoring a session after successful logout. Firebase
failures belong to the caller; the cleanup observer reports only provider work.
Firebase logout returns without waiting for optional provider cleanup. Cleanup
continues in the background even if initialization takes longer than five
seconds. The observer's five-second clock starts only when provider setup and
native sign-out begin, after Firebase logout and captured interactive attempts
settle. An open account picker alone therefore does not cause a cleanup timeout
incident. The observer reports slow native cleanup without cancelling it.
A new Google authentication attempt waits for pending cleanup, with a bounded
five-second wait and a `cleanupPending` interruption if cleanup is still
pending. The auth page shows localized guidance to retry shortly, and to close
and reopen the app if sign-in remains unavailable;
subsequent taps fail promptly while that same cleanup remains pending. If the
native work eventually settles, the guard clears and sign-in can proceed without
restarting. Settled cleanup failures are consumed by the cleanup observer and do
not fail a later sign-in. The timeout does not clear the guard or cancel native
work: releasing it early could let stale cleanup sign out a new Google session.
This prevents stale cleanup from signing out a new provider session. Native
operations cannot be forcibly cancelled by this app. Do not equate Firebase
logout completion with removal of the Google account from the device. Actual
account-picker behavior on Android/iOS remains NOT RUN. The owner accepted the
background cleanup trade-off in this review session on 2026-10-02, explicitly
requiring device validation. The interrupted-cleanup and slow-cleanup rows remain
open; this finding is not closed until their Android/iOS results are recorded.

The installed Android plugin (7.2.17) awaits Credential Manager's
`clearCredentialStateAsync` callbacks; it supplies no cancellation signal or
plugin-level deadline. The iOS plugin (6.3.6) calls `GIDSignIn.signOut()` directly.
[Google's iOS guide](https://developers.google.com/identity/sign-in/ios/sign-in#4_add_a_sign-out_button)
describes clearing app sign-in state and Keychain credentials. Those API/source
checks do not prove that a native operation or an interactive attempt cannot
stall on a device; neither a native hang nor a five-second completion guarantee
was established here. Firebase logout remains the boundary for app access.

Mixpanel events sent during initialization share its future and are delivered
when it succeeds. Callers wait at most five seconds, while a late native result
can still recover and deliver the retained events. The startup buffer holds at
most 64 events, dropping the oldest on overflow. Buffered events copy their
properties and capture occurrence time in Mixpanel's reserved `time` field
(epoch milliseconds), preserving a caller-supplied timestamp. This follows
[Mixpanel's event time contract](https://docs.mixpanel.com/docs/data-structure/property-reference/reserved-properties)
and the native Swift SDK's millisecond representation. New events stay in the
same FIFO while older startup events are delivered. A rejected track call reports
a delivery failure and permits the remaining events to drain; it does not reset
successful initialization. Native/network ingestion order is outside this queue's
guarantee. Initialization failure, timeout,
and overflow each write their own credential-free diagnostic to logs and incident
telemetry when registered. A timeout does not suppress a later buffer-overflow
report. Each distinct startup condition reports at most once per service instance
in an app run, including across failed initialization retries. This does not
establish a quota or sampling policy across devices or app restarts; that rollout
evidence remains required. Pending native initialization is not restarted concurrently: a timeout
cannot cancel it safely. A late result can still recover the queue. A failed native initialization clears the buffer; a later event
retries after a one-minute backoff without polling or periodic timers. All current
trackEvent callers use this behavior, including cold-start Session started,
Home opened, startup journal views, and interaction events. The tests exercise
this startup sequence and native initialization failure in the default suite;
main's Android workflow also invokes the token-defined test variant.
