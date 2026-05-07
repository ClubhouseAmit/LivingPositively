import * as admin from "firebase-admin";
import { setGlobalOptions } from "firebase-functions";
import { onRequest, Request } from "firebase-functions/https";
import { onSchedule } from "firebase-functions/scheduler";
import { DateTime } from "luxon";

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

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
// registerNotification — creates or updates a scheduled notification entry.
// Body: { typeId: string, hour: number, minute: number }
// ---------------------------------------------------------------------------
export const registerNotification = onRequest(async (req, res) => {
  const uid = await extractAndVerifyUid(req);
  if (!uid) { res.status(401).send("Unauthorized"); return; }

  const { typeId, hour, minute, locale, gender } = req.body;

  if (typeof typeId !== "string" || typeof hour !== "number" || typeof minute !== "number" ||
      hour < 0 || hour > 23 || minute < 0 || minute > 59 || typeof locale !== "string") {
    res.status(400).send("Invalid body: typeId (string), hour (0-23), minute (0-59), locale (string) required");
    return;
  }

  const typeDoc = await admin.firestore().collection("notification_types").doc(typeId).get();
  if (!typeDoc.exists) { res.status(400).send(`Unknown typeId: ${typeId}`); return; }

  await admin.firestore()
    .collection("scheduled_notifications")
    .doc(`${uid}_${typeId}`)
    .set({ uid, typeId, hour, minute, locale, gender: gender ?? "male", updatedAt: admin.firestore.FieldValue.serverTimestamp() });

  res.send({ success: true });
});

// ---------------------------------------------------------------------------
// cancelNotification — deletes the scheduled notification entry.
// Body: { typeId: string }
// ---------------------------------------------------------------------------
export const cancelNotification = onRequest(async (req, res) => {
  const uid = await extractAndVerifyUid(req);
  if (!uid) { res.status(401).send("Unauthorized"); return; }

  const { typeId } = req.body;
  if (typeof typeId !== "string") { res.status(400).send("typeId required"); return; }

  await admin.firestore()
    .collection("scheduled_notifications")
    .doc(`${uid}_${typeId}`)
    .delete();

  res.send({ success: true });
});

// ---------------------------------------------------------------------------
// processScheduledNotifications — runs every minute, sends FCM to matching users.
// ---------------------------------------------------------------------------
export const processScheduledNotifications = onSchedule("every 1 minutes", async () => {
  const now = DateTime.now().setZone("Asia/Jerusalem");
  const localHour = now.hour;
  const localMinute = now.minute;

  const snapshot = await admin.firestore()
    .collection("scheduled_notifications")
    .where("hour", "==", localHour)
    .where("minute", "==", localMinute)
    .get();

  if (snapshot.empty) return;

  let successCount = 0;
  let failureCount = 0;

  for (const doc of snapshot.docs) {
    const { uid, typeId, locale, gender } = doc.data();

    const [typeDoc, deviceDoc] = await Promise.all([
      admin.firestore().collection("notification_types").doc(typeId).get(),
      admin.firestore().collection("devices").doc(uid).get(),
    ]);

    const fcmToken = deviceDoc.data()?.fcmToken as string | undefined;
    if (!fcmToken) { failureCount++; continue; }

    const typeData = typeDoc.data();
    if (!typeData) { failureCount++; continue; }

    let title = "Living Positively";
    let body = "";

    if (typeData.messageType === "dynamic" && typeData.quotesCollections) {
      const collectionName = typeData.quotesCollections[locale] ?? typeData.quotesCollections["he"];
      if (!collectionName) { failureCount++; continue; }
      const quotesSnap = await admin.firestore().collection(collectionName).get();
      if (quotesSnap.empty) { failureCount++; continue; }
      const randomDoc = quotesSnap.docs[Math.floor(Math.random() * quotesSnap.docs.length)];
      const quoteData = randomDoc.data();
      body = quoteData[gender] ?? quoteData.other ?? quoteData.male ?? quoteData.text ?? "";
    } else {
      title = typeData.staticTitle ?? title;
      body = typeData.staticBody ?? "";
    }

    try {
      await admin.messaging().send({ token: fcmToken, notification: { title, body } });
      successCount++;
    } catch (err: any) {
      if (err?.errorInfo?.code === "messaging/registration-token-not-registered") {
        await admin.firestore().collection("devices").doc(uid).delete();
      }
      failureCount++;
    }
  }

  console.log(`processScheduledNotifications: sent=${successCount}, failed=${failureCount}`);
});
