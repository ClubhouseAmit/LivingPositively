# Social authentication rollout

Social providers are hidden unless their build-time configuration is explicit.
Do not commit OAuth client IDs, Apple private keys, APNs keys, or other provider
credentials to the repository. Supply build defines from the release environment
or CI secret store.

## Google sign-in on Android

The Google button is available only on Android and only when
`GOOGLE_SIGN_IN_SERVER_CLIENT_ID` is a nonempty value. Use the OAuth 2.0 **Web
application** client ID that Firebase Authentication expects as the Google ID
token audience; do not use an Android OAuth client ID.

Before enabling it:

1. Enable Google as a sign-in provider in Firebase Authentication.
2. Register the Gradle Android application ID `com.matzilon.mezilon` and the
   SHA-1/SHA-256 fingerprints for every signing certificate used by release,
   internal, and development builds. The source namespace
   `com.example.mezilon` is not the OAuth application ID.
3. Create or select the matching Web OAuth client in the same Google Cloud /
   Firebase project and configure the OAuth consent screen.
4. Inject the client ID when building. For example:

   ```shell
   flutter build appbundle --dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com
   ```

For the production Android pipeline, set the repository Actions secret named
`GOOGLE_SIGN_IN_SERVER_CLIENT_ID`. The `main` App Bundle build passes it as a
`--dart-define` and fails before release if the secret is empty or whitespace.

An omitted or whitespace-only value intentionally hides the Google button.

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
5. Inject the capability flag when building. For example:

   ```shell
   if [ "${APPLE_SIGN_IN_ENABLED:-}" != "true" ]; then
     echo "APPLE_SIGN_IN_ENABLED=true is required for an iOS release" >&2
     exit 1
   fi
   flutter build ipa --dart-define=APPLE_SIGN_IN_ENABLED="$APPLE_SIGN_IN_ENABLED"
   ```

The committed entitlements declare both capabilities, but they do not replace
Apple Developer, provisioning-profile, or Firebase Console configuration. An
omitted or false flag intentionally hides the Apple button.

## Verification before rollout

- Install a signed build that uses the production signing identity and profile.
- Complete Google and Apple sign-in with a new account and an existing account.
- Confirm Firebase Authentication records the expected provider.
- On a physical iOS device, confirm APNs registration and one FCM delivery.
