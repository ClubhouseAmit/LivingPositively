# PR #309 Release Blockers Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Resolve the actionable release blockers in PR #309 without changing the existing notification, authentication, or persistence boundaries.

**Architecture:** Keep FCM lifecycle behavior inside `FcmService`, scheduled-reminder migration inside `FcmScheduledNotificationService`, reset behavior inside `UserSettings`, provider availability inside `AuthService`, and scheduler validation inside the existing Functions module. Runtime/provider volatility is contained at those boundaries; no shared layer or public HTTP/Firestore schema is introduced.

**Tech Stack:** Flutter/Dart, Firebase Messaging/Auth/Firestore, Cloud Functions for Firebase, TypeScript, GitHub Actions, Xcode project configuration.

---

## External rollout gates

- The repository has no canonical `firestore.rules` or Firebase Firestore rules configuration. Do not invent a replacement authorization contract. Obtain the deployed rules before adding an owner-only, field-allowlisted `devices/{uid}` rule with a server-timestamp requirement.
- Apple Developer and Firebase Console state cannot be committed. Before a signed device/archive build, enable Push Notifications and Sign in with Apple for `com.clubhouse.livingpositively`, regenerate provisioning profiles, and upload the APNs key to Firebase.
- The checked-in iOS OAuth client belongs to a different bundle identifier, and web has no Google OAuth client ID. Keep Google hidden outside the already-configured Android build until matching provider configuration is supplied.

## Task 1: Cloud Functions runtime, validation, dependencies, and CI

**Files:**

- Modify: `functions/package.json`
- Modify: `functions/package-lock.json`
- Modify: `functions/src/index.ts`
- Modify: `functions/src/provision_notifications.ts`
- Modify: `functions/src/scheduled_delivery.test.ts`
- Modify: `.github/workflows/main.yml`

1. Add failing scheduler tests for fresh, stale, missing, malformed, and hostile `updatedAt` values. Assert malformed data skips only that device and never invokes a client-supplied `toMillis` method.
2. Run `npm test` in `functions/` and confirm the new test fails for the expected missing validation policy.
3. Add a localized timestamp classifier. Preserve legacy acceptance for a missing timestamp, clean up stale tokens, and fail closed for only a malformed device while allowing the minute's other deliveries to continue.
4. Set the Functions engine to Node 22. Upgrade the compatible pair to `firebase-admin@^14.2.0` and `firebase-functions@^7.3.2`, remove unused incompatible `firebase-functions-test`, and migrate only the affected Admin SDK namespace calls to modular imports.
5. Regenerate the lockfile with npm under Node 22. Do not add dependency overrides.
6. Add a blocking `functions-test` GitHub Actions job using Node 22, npm cache, `npm ci`, `npm test`, and `npm audit --omit=dev --audit-level=high`.
7. Verify with `npm ci`, `npm test`, `npm audit --omit=dev`, `npm ls firebase-admin firebase-functions @grpc/grpc-js websocket-driver`, and `npm run build`.
8. Commit the scoped Functions/CI change.

## Task 2: iOS capabilities, iOS CI, and social-provider availability

**Files:**

- Create: `ios/Runner/Runner.entitlements`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `.github/workflows/main.yml`
- Modify: `lib/util/Firebase/auth_service.dart`
- Modify: `lib/pages/auth/auth_page.dart`
- Modify: `test/Firebase/auth_service_test.dart`
- Modify: `test/auth/auth_page_interactions_test.dart`
- Delete: `scripts/check_ios_integration_coverage.dart`

1. Add failing provider-matrix tests: Google is Android-only; Apple is iOS-only and requires an explicit build capability; unsupported platforms expose no social provider and no dangling divider.
2. Run the focused Flutter tests and confirm they fail for the current always-visible Google UI/direct platform checks.
3. Move availability policy into testable methods on `AuthService`. Gate Apple with a compile-time `APPLE_SIGN_IN_ENABLED` flag defaulting to false until external provisioning is complete. Render the divider and buttons only when at least one provider is available.
4. Add Runner entitlements for APNs and Sign in with Apple, reference them from the Runner group, set `CODE_SIGN_ENTITLEMENTS` in Debug/Profile/Release, and declare the target capabilities.
5. Point the iOS integration job to `integration_test/notifications_schedule_test.dart`, make its test result gating, remove the obsolete per-file coverage command/artifact, and delete the stale checker that targets the removed local notification service.
6. Verify focused tests/analyzer checks. On macOS/CI, validate the plist, Xcode build settings, simulator build, and one executed integration test.
7. Commit the scoped iOS/auth/CI change.

## Task 3: Best-effort, retryable FCM initialization

**Files:**

- Modify: `lib/main.dart`
- Modify: `lib/util/Firebase/fcm_service.dart`
- Modify: `lib/pages/auth/auth_page.dart`
- Modify: `integration_test/bootstrap_full_test.dart`
- Modify: `test/Firebase/fcm_service_platform_test.dart`
- Modify: `test/auth/auth_page_interactions_test.dart`

1. Add failing bootstrap tests proving a pending FCM initializer does not delay the root widget and a rejected initializer is contained.
2. Add failing FCM tests proving a failed attempt may be retried, iOS does not request an FCM token before an APNs token exists, and Android can request the FCM token directly.
3. Launch guarded FCM initialization without awaiting it during bootstrap. Guard concurrent attempts, commit initialized state only after success, and contain/report failures.
4. Reuse the APNs-ready token path during post-sign-in refresh. Make post-sign-in FCM refresh fire-and-forget so messaging failure cannot abort authentication/navigation.
5. Retry initialization from the existing app-resume lifecycle hook; do not add a lifecycle service.
6. Run focused bootstrap, FCM, and auth tests plus analyzer checks.
7. Commit the scoped FCM lifecycle change.

## Task 4: Retire the legacy local reminder after remote migration

**Files:**

- Modify: `lib/util/Firebase/fcm_service.dart`
- Modify: `lib/util/Firebase/fcm_scheduled_notification_service.dart`
- Modify: `test/Firebase/fcm_scheduled_notification_service_test.dart`

1. Extend the migration test to require cancellation of the historical local notification ID (`int.parse('$hour$minute')`) after successful remote registration and before writing `fcmDefaultReminderMigrated`.
2. Add failure coverage proving the marker remains unset if local retirement fails, so migration is retryable.
3. Expose only a narrow `FcmService` operation for cancelling that legacy ID. Inject it in tests through the migration's existing test-seam style.
4. Preserve the operation queue/reset fence and all remote request contracts.
5. Run the focused notification service tests and analyzer.
6. Commit the scoped migration change.

## Task 5: Keep reset terminal after best-effort image cleanup failure

**Files:**

- Modify: `lib/pages/UserSettings.dart`
- Modify: `test/UserSettings/UserSettings_interactions_test.dart`

1. Change the existing cleanup-failure regression to assert the reset still navigates to `FirstPage`, provider name/age remain reset, and stale Settings controls cannot persist old values.
2. Run the focused test and confirm it fails because the current catch path restores the stale dialog.
3. Contain and report `deleteImages` failure inside the already-documented best-effort cleanup boundary, then continue terminal reset navigation. Keep the outer recovery for failures in required reset work.
4. Run the complete UserSettings interaction suite and analyzer.
5. Commit the scoped reset change.

## Task 6: Verification and review

1. Run `dart format --output=none --set-exit-if-changed` on changed Dart files, focused tests, the full Flutter test suite, `flutter analyze`, Functions clean install/build/tests/audit, and `git diff --check`.
2. Confirm only the user's pre-existing `coverage/lcov.info` remains uncommitted.
3. Request independent specification and code-quality reviews. Address findings with new failing tests before production changes.
4. Push the branch and inspect PR #309 checks and unresolved review threads. Do not resolve or reply to GitHub threads unless explicitly requested.
