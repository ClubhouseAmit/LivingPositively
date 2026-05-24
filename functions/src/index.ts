import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions";
import { onRequest, Request } from "firebase-functions/https";
import { onSchedule } from "firebase-functions/scheduler";
import { DateTime } from "luxon";

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

const STALE_TOKEN_DAYS = 180;

// ---------------------------------------------------------------------------
// Helper: verify the Bearer token and return the uid, or null if invalid.
// ---------------------------------------------------------------------------
async function extractAndVerifyUid(req: Request): Promise<string | null> {
  const authHeader = req.headers.authorization ?? "";
  const idToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!idToken) return null;
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    return decoded.uid;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// clearFCMToken — nulls out the fcmToken field on a device doc without touching
// scheduled_notifications. Used when the token is invalid but the user may still
// have the app. The token will be repopulated the next time the user opens the app.
// triggered when:
// 1. user uninstalls the app.
// 2. user clears their data.
// 3. user restores the app from backup on a new device.
// 4. Firebase server-side rotation (rare, automatic).
// ---------------------------------------------------------------------------
async function clearFCMToken(uid: string): Promise<void> {
  await admin.firestore().collection("devices").doc(uid).update({
    fcmToken: admin.firestore.FieldValue.delete(),
  });
}

// ---------------------------------------------------------------------------
// cleanupInactiveDevice — deletes the device doc and all scheduled_notifications
// for a user who has been inactive for STALE_TOKEN_DAYS. Only called when we are
// confident the user has abandoned the app.
// triggered when:
// 1. user is inactive for 180 days.
// ---------------------------------------------------------------------------
async function cleanupInactiveDevice(uid: string): Promise<void> {
  const db = admin.firestore();
  const scheduledSnap = await db
    .collection("scheduled_notifications")
    .where("uid", "==", uid)
    .get();

  const deletes: Promise<any>[] = scheduledSnap.docs.map((doc) =>
    doc.ref.delete(),
  );
  deletes.push(db.collection("devices").doc(uid).delete());
  await Promise.all(deletes);
}

// ---------------------------------------------------------------------------
// registerNotification — creates or updates a scheduled notification entry.
// Body: { typeId: string, hour: number, minute: number }
// ---------------------------------------------------------------------------
export const registerNotification = onRequest(async (req, res) => {
  const uid = await extractAndVerifyUid(req);
  if (!uid) {
    res.status(401).send("Unauthorized");
    return;
  }

  const { typeId, hour, minute, locale, gender } = req.body;

  if (
    typeof typeId !== "string" ||
    typeof hour !== "number" ||
    typeof minute !== "number" ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59 ||
    typeof locale !== "string"
  ) {
    res
      .status(400)
      .send(
        "Invalid body: typeId (string), hour (0-23), minute (0-59), locale (string) required",
      );
    return;
  }

  const typeDoc = await admin
    .firestore()
    .collection("notification_types")
    .doc(typeId)
    .get();
  if (!typeDoc.exists) {
    res.status(400).send(`Unknown typeId: ${typeId}`);
    return;
  }

  await admin
    .firestore()
    .collection("scheduled_notifications")
    .doc(`${uid}_${typeId}`)
    .set({
      uid,
      typeId,
      hour,
      minute,
      locale,
      gender: gender ?? "male",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  res.send({ success: true });
});

// ---------------------------------------------------------------------------
// cancelNotification — deletes the scheduled notification entry.
// Body: { typeId: string }
// ---------------------------------------------------------------------------
export const cancelNotification = onRequest(async (req, res) => {
  const uid = await extractAndVerifyUid(req);
  if (!uid) {
    res.status(401).send("Unauthorized");
    return;
  }

  const { typeId } = req.body;
  if (typeof typeId !== "string") {
    res.status(400).send("typeId required");
    return;
  }

  await admin
    .firestore()
    .collection("scheduled_notifications")
    .doc(`${uid}_${typeId}`)
    .delete();

  res.send({ success: true });
});

// ---------------------------------------------------------------------------
// processScheduledNotifications — runs every minute via Cloud Scheduler.
//
// Invocation flow:
//   1. Query phase   — fetch all scheduled_notifications matching the current
//                      hour+minute. Early-exit if none match.
//   2. Pre-fetch phase — collect the unique typeIds and locales from the result
//                      set, then fetch all notification_type docs and quote
//                      collections in parallel. Each collection is fetched at
//                      most once regardless of how many users share it.
//   3. Send phase    — iterate users, fetch their device doc, check token
//                      freshness, build the message from pre-fetched data,
//                      and dispatch via FCM.
// ---------------------------------------------------------------------------
export const processScheduledNotifications = onSchedule(
  "every 1 minutes",
  async () => {
    // --- Query phase ---
    const now = DateTime.now().setZone("Asia/Jerusalem");
    const localHour = now.hour;
    const localMinute = now.minute;

    const snapshot = await admin
      .firestore()
      .collection("scheduled_notifications")
      .where("hour", "==", localHour)
      .where("minute", "==", localMinute)
      .get();

    if (snapshot.empty) return;

    // --- Pre-fetch phase ---

    // Collect unique typeIds and all locales present per typeId
    const localesByTypeId = new Map<string, Set<string>>();
    for (const doc of snapshot.docs) {
      const { typeId, locale } = doc.data();
      if (!localesByTypeId.has(typeId)) localesByTypeId.set(typeId, new Set());
      localesByTypeId.get(typeId)!.add(locale);
    }

    // Fetch all unique notification_type docs in parallel
    const typeDataMap = new Map<string, FirebaseFirestore.DocumentData>();
    await Promise.all(
      [...localesByTypeId.keys()].map(async (typeId) => {
        const doc = await admin.firestore().collection("notification_types").doc(typeId).get();
        if (doc.exists) typeDataMap.set(typeId, doc.data()!);
      }),
    );

    // Fetch each unique quote collection once, keyed by collection name
    const quotesMap = new Map<string, FirebaseFirestore.DocumentData[]>();
    await Promise.all(
      [...localesByTypeId.entries()].map(async ([typeId, locales]) => {
        const typeData = typeDataMap.get(typeId);
        if (typeData?.messageType !== "dynamic" || !typeData?.quotesCollections) return;

        const neededCollections = new Set<string>();
        for (const locale of locales) {
          const name = typeData.quotesCollections[locale] ?? typeData.quotesCollections["he"];
          if (name) neededCollections.add(name);
        }

        await Promise.all(
          [...neededCollections].map(async (collectionName) => {
            if (quotesMap.has(collectionName)) return;
            const snap = await admin.firestore().collection(collectionName).get();
            quotesMap.set(collectionName, snap.docs.map((d) => d.data()));
          }),
        );
      }),
    );

    // --- Send phase ---

    let successCount = 0;
    let failureCount = 0;

    for (const doc of snapshot.docs) {
      const { uid, typeId, locale, gender } = doc.data();

      const deviceDoc = await admin.firestore().collection("devices").doc(uid).get();

      const deviceData = deviceDoc.data();

      const updatedAt = deviceData?.updatedAt as
        | admin.firestore.Timestamp
        | undefined;
      if (updatedAt) {
        const ageDays = (Date.now() - updatedAt.toMillis()) / 86_400_000;
        if (ageDays > STALE_TOKEN_DAYS) {
          await cleanupInactiveDevice(uid);
          failureCount++;
          continue;
        }
      }

      const fcmToken = deviceData?.fcmToken as string | undefined;
      if (!fcmToken) {
        failureCount++;
        continue;
      }

      const typeData = typeDataMap.get(typeId);
      if (!typeData) {
        failureCount++;
        continue;
      }

      let title = "Living Positively";
      let body = "";

      if (typeData.messageType === "dynamic" && typeData.quotesCollections) {
        const collectionName =
          typeData.quotesCollections[locale] ??
          typeData.quotesCollections["he"];
        if (!collectionName) {
          failureCount++;
          continue;
        }
        const quotes = quotesMap.get(collectionName);
        if (!quotes || quotes.length === 0) {
          failureCount++;
          continue;
        }
        const quoteData = quotes[Math.floor(Math.random() * quotes.length)];
        body = quoteData[gender] ?? quoteData.other ?? quoteData.male ?? quoteData.text ?? "";
      } else {
        title = typeData.staticTitle ?? title;
        body = typeData.staticBody ?? "";
      }

      try {
        await admin
          .messaging()
          .send({ token: fcmToken, notification: { title, body } });
        successCount++;
      } catch (err: any) {
        if (
          err?.errorInfo?.code === "messaging/registration-token-not-registered"
        ) {
          await clearFCMToken(uid);
        }
        failureCount++;
      }
    }

    console.log(
      `processScheduledNotifications: sent=${successCount}, failed=${failureCount}`,
    );
  },
);
