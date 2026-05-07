# Plan: FCM-Based Scheduled Notification System

## Status: Partially Implemented, need to confirm the scheduler is working as intented

---

## What Was Built

The existing Workmanager local-notification system was replaced entirely with a server-driven FCM pipeline:

- Cloud Scheduler fires every 1 minute → Cloud Function queries Firestore → sends FCM push to matching devices
- Two authenticated HTTP Cloud Functions for the app to register/cancel notification preferences
- `FcmScheduledNotificationService` — new Flutter service the UI calls
- `notification_types` config collection — extensible type system
- Anonymous Firebase Auth — replaces UUID-based device identification
- Locale + gender stored per notification — server picks the right language quote

---

## Timezone Strategy

All notification times are stored in **Israel Standard Time (Asia/Jerusalem)**.

- The client sends `hour` and `minute` exactly as the user picked (already local time — no conversion needed).
- The Cloud Function uses luxon to convert current UTC → `Asia/Jerusalem` and queries by that hour/minute.
- When Israel switches daylight saving (UTC+2 → UTC+3), luxon handles it automatically.

---

## Firestore Schema

### `scheduled_notifications/{uid}_{typeId}`

One document per user per type. Document ID enforces uniqueness — re-registering overwrites.
Cancelling **deletes the document** (no soft-delete, no `active` field).

```
uid:        string       // Firebase anonymous UID
typeId:     string       // e.g. "default"
hour:       number       // Israel local time 0-23
minute:     number       // Israel local time 0-59
locale:     string       // e.g. "he", "ar", "en" — sent by app at registration time
gender:     string       // "male" | "female" — sent by app at registration time
updatedAt:  Timestamp
```

### `notification_types/{typeId}` — seed manually

```
id:                  string
messageType:         "dynamic" | "static"
staticTitle?:        string              // only for static types
staticBody?:         string              // only for static types
quotesCollections?:  Map<locale, collectionName>   // for dynamic types
```

Seed `notification_types/default`:

```json
{
  "id": "default",
  "messageType": "dynamic",
  "quotesCollections": {
    "he": "quotes_he",
    "ar": "quotes_ar",
    "en": "quotes_en"
  }
}
```

### `quotes_he` / `quotes_ar` / `quotes_en` — seed manually

Each document is one quote with gender variants:

```json
{ "male": "אני חזק", "female": "אני חזקה", "other": "אני חזק" }
```

Source content: `lib/l10n/app_he.arb`, `app_ar.arb`, `app_en.arb` — keys `inspirationalQuotesNo0`…`N` (ICU format: `{gender,select,male{...} female{...} other{...}}`).
Gender stored in `scheduled_notifications` is normalized: `'male'` | `'female'` | `'other'` (app stores `''` for non-binary/not-willing-to-say — the service converts this to `'other'` before sending).
The Cloud Function reads `quoteData[gender] ?? quoteData.other ?? quoteData.male ?? quoteData.text`.

### `devices/{uid}` — auto-created by app

```
fcmToken:   string       // written by FcmService on every launch + onTokenRefresh
platform:   "android" | "ios"
updatedAt:  Timestamp
```

### Required Firestore composite index

Collection: `scheduled_notifications` — fields: `hour ASC`, `minute ASC`
Create in Firebase Console → Firestore → Indexes → Add index.
(Firestore will also print a direct creation link the first time the query runs without it.)

---

## Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /devices/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /scheduled_notifications/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.uid;
    }
  }
}
```

---

## Cloud Functions (`functions/src/index.ts`)

### Helper: `extractAndVerifyUid`

Reads `Authorization: Bearer <idToken>` header, calls `admin.auth().verifyIdToken()`, returns uid or null.

### 1. `registerNotification` — HTTP POST (authenticated)

- Verifies auth token → uid (401 if invalid)
- Validates body: `{ typeId: string, hour: 0-23, minute: 0-59, locale: string, gender?: string }` (400 if invalid)
- Checks `notification_types/{typeId}` exists (400 if not)
- Writes to `scheduled_notifications/{uid}_{typeId}` with `.set()` — creates or overwrites
- Returns `{ success: true }`

### 2. `cancelNotification` — HTTP POST (authenticated)

- Verifies auth token → uid (401 if invalid)
- Validates body: `{ typeId: string }` (400 if missing)
- Deletes `scheduled_notifications/{uid}_{typeId}`
- Returns `{ success: true }`

### 3. `processScheduledNotifications` — Scheduled every 1 minute

1. Gets current time in `Asia/Jerusalem` via luxon
2. Queries `scheduled_notifications` where `hour == localHour && minute == localMinute`
3. For each matching doc:
   - Reads `locale` and `gender` from the doc
   - Fetches `notification_types/{typeId}` and `devices/{uid}` in parallel
   - Skips if no FCM token
   - Builds message:
     - `dynamic`: reads `quotesCollections[locale]` (falls back to `"he"`), picks a random doc, uses `quoteData[gender] ?? quoteData.male ?? quoteData.text`
     - `static`: uses `staticTitle` / `staticBody`
   - Sends via `admin.messaging().send()`
   - On `messaging/registration-token-not-registered` error: deletes `devices/{uid}` (stale token cleanup)
4. Logs total sent/failed

---

## Flutter

### Anonymous Auth (`lib/util/Firebase/fcm_service.dart`)

- Replaced UUID + SharedPreferences device ID with Firebase Anonymous Auth
- `_getOrCreateUid()`: calls `auth.signInAnonymously()` if no current user; returns `auth.currentUser?.uid`
- `onTokenRefresh` listener uses `FirebaseAuth.currentUser?.uid`
- On every launch: gets current FCM token + saves to `devices/{uid}` via `_saveTokenToFirestore()`

### Service Locator (`lib/iFx/service_locator.dart`)

Added `FirebaseAuth` registration:

```dart
getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
```

### Notification Preference Model (`lib/util/notification_preference.dart`) — new file

```dart
class NotificationPreference {
  final int hour;
  final int minute;
  const NotificationPreference({required this.hour, required this.minute});
  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};
  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      NotificationPreference(hour: json['hour'] as int, minute: json['minute'] as int);
}
```

`locale` and `gender` are NOT stored here — they are read from `UserInformation.localeName` / `.gender` at call time.

### UserInformation (`lib/util/userInformation.dart`)

- Replaced `int notificationHour` / `int notificationMinute` with `Map<String, NotificationPreference> notificationPreferences`
- `getNotificationPreference(String typeId)` — returns current pref or null
- `setNotificationPreference(String typeId, NotificationPreference pref)` — overwrites entry, persists to SharedPreferences as JSON
- `clearNotificationPreference(String typeId)` — removes entry, persists
- SharedPreferences key: `'notificationPreferences'`
- Format: `{ "default": { "hour": 9, "minute": 0 } }`

### App Startup (`lib/util/Firebase/firebase_functions.dart`)

`loadUserInformation()` reads `notificationPreferences` JSON string from SharedPreferences and deserializes into `Map<String, NotificationPreference>`.

### FCM Scheduled Notification Service (`lib/util/Firebase/fcm_scheduled_notification_service.dart`) — new file

- `registerNotification({ context, typeId, hour, minute })`:
  - Reads `locale` and `gender` from `UserInformation` via Provider **before** any await
  - Gets Firebase ID token
  - POSTs to `$baseUrl/registerNotification` with `{ typeId, hour, minute, locale, gender }`
  - On 200: calls `userInfo.setNotificationPreference()`
- `cancelNotification({ context, typeId })`:
  - POSTs to `$baseUrl/cancelNotification` with `{ typeId }`
  - On 200: calls `userInfo.clearNotificationPreference()`
- Base URL: `https://us-central1-mezilondb.cloudfunctions.net`

### Locale Change (`lib/main.dart` — `changeLocale()`)

After updating the app locale, re-registers active notifications so Firestore gets the new locale:

```dart
userInfo.updateLocaleName(locale);
final pref = userInfo.getNotificationPreference('default');
if (pref != null) {
  await FcmScheduledNotificationService.registerNotification(
    context: currentContext, typeId: 'default',
    hour: pref.hour, minute: pref.minute,
  );
}
```

### UI (`lib/pages/notifications/set_notification_widget.dart`)

- Set button → `FcmScheduledNotificationService.registerNotification()`
- Cancel button → `FcmScheduledNotificationService.cancelNotification()`
- InitState loads current time from `userInfo.getNotificationPreference('default')`

### UI (`lib/pages/notifications/notification_page.dart`)

- `_onPickedTime` → `FcmScheduledNotificationService.registerNotification()`
- `_onToggle(false)` → `FcmScheduledNotificationService.cancelNotification()`
- `NotificationToggleCard` reads from `getNotificationPreference('default')`

### Notification Service (`lib/pages/notifications/notification_service.dart`)

`updateNotification()` fixed to use `getNotificationPreference('default')` instead of removed fields. File kept but no longer the primary scheduling path.

### Menu (`lib/menu.dart`)

- Removed `NotificationsService` import
- Removed `supportsReminderSettings()` platform gate — notification page and button now shown on all platforms

---

## Tests

| File                                                        | Change                                                                                    |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `test/notifications/reminder_platform_policy_test.dart`     | **Deleted** — tested `supportsReminderSettings()` which no longer exists                  |
| `test/notifications/reminder_locale_change_guard_test.dart` | **Deleted** — tested `refreshReminderForLocaleChange()` removed from `main.dart`          |
| `test/MenuTest/reminder_visibility_test.dart`               | **Updated** — both iOS and Android tests now expect the notification button to be visible |

---

## Dependencies

### `functions/package.json`

```json
"dependencies": {
  "luxon": "^3.0.0"
},
"devDependencies": {
  "@types/luxon": "^3.0.0"
}
```

Run `cd functions && npm install` before deploying.

---

## Files Modified Summary

| File                                                        | Change                                                                                     |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `functions/src/index.ts`                                    | 3 functions: `registerNotification`, `cancelNotification`, `processScheduledNotifications` |
| `functions/package.json`                                    | Added `luxon` + `@types/luxon`                                                             |
| `lib/util/notification_preference.dart`                     | **New** — `NotificationPreference` model                                                   |
| `lib/util/Firebase/fcm_scheduled_notification_service.dart` | **New** — HTTP service layer                                                               |
| `lib/util/Firebase/fcm_service.dart`                        | Replaced UUID with Anonymous Auth; `onTokenRefresh` listener                               |
| `lib/iFx/service_locator.dart`                              | Registered `FirebaseAuth`                                                                  |
| `lib/util/userInformation.dart`                             | Replaced `notificationHour/Minute` with `Map<String, NotificationPreference>`              |
| `lib/util/Firebase/firebase_functions.dart`                 | `loadUserInformation` deserializes new preference map                                      |
| `lib/pages/notifications/set_notification_widget.dart`      | Calls new service; reads pref from new map in initState                                    |
| `lib/pages/notifications/notification_page.dart`            | `_onPickedTime`, `_onToggle`, `NotificationToggleCard` use new service/model               |
| `lib/pages/notifications/notification_service.dart`         | Fixed `updateNotification()` for new preference API                                        |
| `lib/pages/notifications/time_picker.dart`                  | Removed `NotificationsService.init()`                                                      |
| `lib/main.dart`                                             | Removed Workmanager/callbackDispatcher; added locale-change re-registration                |
| `lib/menu.dart`                                             | Removed `NotificationsService` import and platform gate                                    |
| `test/notifications/reminder_platform_policy_test.dart`     | Deleted                                                                                    |
| `test/notifications/reminder_locale_change_guard_test.dart` | Deleted                                                                                    |
| `test/MenuTest/reminder_visibility_test.dart`               | Updated — button always visible                                                            |

---

## Pending Setup (one-time, manual)

1. **`cd functions && npm install`** — installs luxon
2. **`firebase functions:delete sendNotification --region us-central1`** — removes orphaned legacy function
3. **`firebase deploy --only functions`** — deploys all 3 functions
4. **Firestore composite index** — `scheduled_notifications`: `hour ASC` + `minute ASC`
5. **Seed `notification_types/default`** — JSON above
6. **Seed `quotes_he`, `quotes_ar`, `quotes_en`** — one document per quote, `{ male, female }` fields, sourced from ARB files
7. **Apply Firestore security rules** — rules above

---

## Verification

1. Open notification settings → pick a time 2 minutes from now → tap Set
   - Logs: `[FcmScheduledNotificationService] Notification registered successfully`
   - Firestore: `scheduled_notifications/{uid}_default` appears with `locale` and `gender` fields

2. Wait for Cloud Scheduler to fire at that minute
   - Firebase Console → Functions → `processScheduledNotifications` logs: `sent=1, failed=0`
   - Notification arrives on device in the correct language

3. Change locale → verify Firestore doc updates its `locale` field without changing `hour`/`minute`

4. Tap Cancel → `scheduled_notifications/{uid}_default` document deleted

5. Pick a new time (existing notification) → verify only one document in Firestore (overwrite, not addition)
