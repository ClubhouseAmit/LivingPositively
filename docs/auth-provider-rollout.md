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
   its current `GoogleService-Info.plist`. The checked-in FlutterFire options
   identify `com.example.mezilon`, so regenerate the local Firebase options
   from the newly registered iOS app before building.
5. For iOS, copy
   `ios/Flutter/GoogleSignIn.xcconfig.example` to the ignored
   `ios/Flutter/GoogleSignIn.xcconfig` and fill its three values from the
   registered iOS app: `CLIENT_ID`, `REVERSED_CLIENT_ID`, and the Web OAuth
   client ID. The native plist uses those values for `GIDClientID`,
   `GIDServerClientID`, and the required URL callback scheme.
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
