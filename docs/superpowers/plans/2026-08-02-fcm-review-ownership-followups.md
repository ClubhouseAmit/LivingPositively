# FCM Review Ownership Follow-ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make signed-in reset account-wide on supported mobile platforms, keep auth state consistent if the auth view closes mid-request, and make ARB quote content authoritative in Firestore.

**Architecture:** `UserSettings` owns the reset policy and will issue the existing idempotent cancellation command for every non-anonymous Android/iOS user before clearing device state. `AuthPage` retains its existing state responsibility; a narrowly scoped `AuthService` test override lets its real callback be exercised after disposal without a test-only widget parameter. Notification provisioning owns only generated `inspirationalQuotesNo<N>` records in the three quote collections, leaving unrelated editorial documents untouched.

**Tech Stack:** Flutter/Dart, Firebase Auth, Firebase Admin SDK, TypeScript, Node test runner.

## Global Constraints

- Reset is account-wide for signed-in Android/iOS users: cancellation is attempted even if this device lacks a local reminder preference.
- Reset aborts and preserves local data if account-wide cancellation cannot complete.
- ARB is authoritative for generated quote IDs; provisioning must delete generated IDs missing from the current ARB seed.
- Do not add a test-only public UI API or a Firestore rules source.
- Preserve the approved at-most-once scheduler checkpoint behavior; document, rather than redesign, recovery-path read amplification and transient claim-failure recovery in this change.

---

### Task 1: Complete auth state after a disposed auth screen

**Files:**
- Modify: `lib/util/Firebase/auth_service.dart`
- Modify: `lib/pages/auth/auth_page.dart`
- Modify: `test/auth/auth_page_interactions_test.dart`

**Interfaces:**
- Produces: `AuthService.saveUserToFirestoreForTesting`, an `@visibleForTesting` nullable callback with type `Future<void> Function(User user)?`.
- Consumes: `_LoginForm.onSuccess`, the existing callback bound to `_AuthPageState._onAuthSuccess`.

- [x] **Step 1: Write the failing disposed-auth regression test**

```dart
final completion = loginForm.onSuccess(firebaseUser);
await tester.pumpWidget(const SizedBox.shrink());
saveUserCompleter.complete();
await completion;

expect(userInformation.loggedIn, isTrue);
expect(userInformation.authDecisionMade, isTrue);
expect(userInformation.userId, 'uid-123');
```

Use a Windows platform override so FCM registration is the production no-op, delay `AuthService.saveUserToFirestore` with a completer, dispose the page, then complete persistence. The test must identify the real login form's public `onSuccess` callback and assert the provider state, not an injected widget callback.

- [x] **Step 2: Run the regression test and verify it fails**

Run: `flutter test test/auth/auth_page_interactions_test.dart --name "disposed auth screen" --reporter expanded`

Expected: the callback returns at `if (!mounted) return`, leaving `loggedIn` false.

- [x] **Step 3: Add the narrow persistence test hook and remove the stale guard**

```dart
@visibleForTesting
static Future<void> Function(User user)? saveUserToFirestoreForTesting;

static Future<void> saveUserToFirestore(User user) =>
    (saveUserToFirestoreForTesting ?? _saveUserToFirestore)(user);
```

Move the existing Firestore body to `_saveUserToFirestore`. In `_onAuthSuccess`, delete only the `if (!mounted) return` after `onUserSignedIn`; retain the existing mounted check immediately around `Navigator.pop`.

- [x] **Step 4: Run the focused auth test**

Run: `flutter test test/auth/auth_page_interactions_test.dart --reporter expanded`

Expected: the disposed callback updates `UserInformation`; existing auth interactions remain green.

### Task 2: Account-wide mobile reset without a test-only widget seam

**Files:**
- Modify: `lib/pages/UserSettings.dart`
- Modify: `test/UserSettings/UserSettings_interactions_test.dart`

**Interfaces:**
- Consumes: `FcmScheduledNotificationService.cancelDefaultForReset(userInformation: userInfo)`.
- Produces: the unchanged public `UserSettings` constructor, with no `cancelDefaultReminder` parameter.

- [x] **Step 1: Write the failing no-local-reminder account-reset test**

```dart
when(firebaseUser.getIdToken()).thenAnswer((_) async => null);
// Android, signed-in user, no local notification preference.
await confirmReset(tester);

expect(find.byType(UserSettings), findsOneWidget);
expect(find.byType(FirstPage), findsNothing);
expect(find.byType(SnackBar), findsOneWidget);
```

Exercise the production cancellation path (no constructor callback). A missing ID token is the real service-level cancellation failure; the test proves reset does not treat a missing local preference as proof that no account schedule exists.

- [x] **Step 2: Run the new test and verify it fails**

Run: `flutter test test/UserSettings/UserSettings_interactions_test.dart --name "no local reminder" --reporter expanded`

Expected: current code skips cancellation and navigates to `FirstPage`.

- [x] **Step 3: Make cancellation account-wide and remove the test-only parameter**

```dart
if (firebaseUser != null &&
    !firebaseUser.isAnonymous &&
    FcmService.supportsReminderSettings()) {
  final cancelled = await FcmScheduledNotificationService.cancelDefaultForReset(
    userInformation: userInfo,
  );
  if (!cancelled) return;
}
```

Delete `cancelDefaultReminder` from `UserSettings` and replace callback-based tests with the real service path. Keep unsupported platforms non-blocking, and retain a Windows test proving reset preserves a signed-in identity after local clearing.

- [x] **Step 4: Run the focused settings tests**

Run: `flutter test test/UserSettings/UserSettings_interactions_test.dart --reporter expanded`

Expected: unsupported platforms reset locally; every signed-in Android reset waits for cancellation, including when no local preference exists.

### Task 3: Prune generated Firestore quotes absent from ARB

**Files:**
- Modify: `functions/src/notification_provisioning.ts`
- Modify: `functions/src/provision_notifications.ts`
- Modify: `functions/src/notification_provisioning.test.ts`

**Interfaces:**
- Extends `SeedWriter` with `listDocumentIds(collection: string): Promise<string[]>` and `deleteDocument(collection: string, id: string): Promise<void>`.
- `provisionNotificationContent` owns only `inspirationalQuotesNo<N>` IDs in `quotes_he`, `quotes_ar`, and `quotes_en`.

- [x] **Step 1: Write the failing authoritative-pruning test**

```ts
const storedDocuments = new Map([
  ["quotes_en/inspirationalQuotesNo0", { male: "old" }],
  ["quotes_en/inspirationalQuotesNo1", { male: "withdrawn" }],
  ["quotes_en/editorial_quote", { text: "leave alone" }],
]);

await provisionNotificationContent(seedWithOnlyQuoteZero, writer);

assert.equal(storedDocuments.has("quotes_en/inspirationalQuotesNo1"), false);
assert.deepEqual(storedDocuments.get("quotes_en/editorial_quote"), {
  text: "leave alone",
});
```

The fake writer must expose document IDs and record deletions. It must also assert that a seeded quote is replaced by the ARB data, including removal of a stale editorial field on that generated quote.

- [x] **Step 2: Run the focused Functions test and verify it fails**

Run: `npm --prefix functions test -- --test-name-pattern "prunes generated quotes"`

Expected: the obsolete generated quote remains because the current writer only upserts.

- [x] **Step 3: Implement generated-ID pruning and the CLI adapter**

```ts
for (const collection of quoteCollections) {
  const seededIds = seededQuoteIdsByCollection.get(collection)!;
  for (const id of await writer.listDocumentIds(collection)) {
    if (QUOTE_KEY_PATTERN.test(id) && !seededIds.has(id)) {
      await writer.deleteDocument(collection, id);
    }
  }
}
```

After successful upserts, delete only absent IDs matching the generated quote pattern. In the CLI adapter, implement listing through `firestore.collection(collection).listDocuments()` and deletion through `.doc(id).delete()`. Keep `.set(document.data)` without `merge` so ARB remains authoritative for each generated record.

- [x] **Step 4: Run the Functions suite**

Run: `npm --prefix functions test`

Expected: provisioning and scheduler tests pass, including generated quote pruning.

### Task 4: Record scheduler recovery costs and close review housekeeping

**Files:**
- Modify: `docs/plans/2026-07-31-pr-273-fcm-remaining-work.md`

- [x] **Step 1: Record the bounded recovery behavior**

Document that a claim-write failure holds the checkpoint so the affected intended minute is retried, that recovery queries all schedules in candidate hours then filters exact minutes in memory, and that the 120-minute window bounds this cost. State that deployment monitoring must alert on repeated `claimFailed` counts.

- [x] **Step 2: Update the decision records**

Replace the reset decision with the approved account-wide mobile behavior. State that ARB is authoritative for generated quote IDs, provisioning prunes withdrawn generated quotes, and non-pattern editorial documents remain out of scope.

- [x] **Step 3: Run final validation**

Run: `npm --prefix functions test && flutter test --coverage --reporter=expanded && flutter analyze --no-pub && git diff --check`

Expected: Functions and Flutter suites pass; report inherited analyzer warnings separately if they remain confined to unchanged generated mocks.
