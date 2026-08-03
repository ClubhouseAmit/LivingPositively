import * as admin from "firebase-admin";
import { Buffer } from "node:buffer";
import { setGlobalOptions } from "firebase-functions";
import { onRequest, Request } from "firebase-functions/https";
import { onSchedule } from "firebase-functions/scheduler";

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

const STALE_TOKEN_DAYS = 180;
const NOTIFICATION_TYPE_ID_PATTERN = /^[A-Za-z0-9_-]{1,64}$/;

type NotificationGender = "male" | "female" | "other";
type DynamicNotificationType = {
  messageType: "dynamic";
  quotesCollections: Record<string, unknown>;
};
type StaticNotificationType = {
  messageType: "static";
  staticTitle: string;
  staticBody: string;
};
type ValidNotificationType = DynamicNotificationType | StaticNotificationType;
export type IsraelLocalDeliveryCandidate = {
  localDate: string;
  intendedTime: string;
  hour: number;
  minute: number;
  intendedAt: Date;
};
type FcmMessage = {
  token: string;
  notification: { title: string; body: string };
  data: Record<string, string>;
};
export type ScheduledDeliveryWriter = {
  create(data: Record<string, unknown>): Promise<unknown>;
  update(data: Record<string, unknown>): Promise<unknown>;
};
export type ScheduledDelivery = {
  uid: string;
  typeId: string;
  localDate: string;
  intendedTime: string;
  intendedAt: Date;
  message: FcmMessage;
};
type ScheduledDeliveryResult = "sent" | "failed" | "alreadyClaimed" | "claimFailed";
type TimestampLike = { toMillis(): number };
type ScheduledNotificationDocument = {
  data(): Record<string, unknown>;
};
export type ScheduledNotificationQueryPlan =
  | { kind: "exact"; hour: number; minute: number }
  | { kind: "catchUp"; hours: number[] };
export type ExpectedNotificationMutationVersion =
  | { kind: "legacy" }
  | { kind: "versioned"; version: number }
  | { kind: "invalid" };
export type NotificationMutationDecision =
  | "apply"
  | "stale"
  | "legacyBlocked"
  | "invalid";

export function isValidNotificationTypeId(
  value: unknown,
): value is string {
  return (
    typeof value === "string" && NOTIFICATION_TYPE_ID_PATTERN.test(value)
  );
}

export function normalizeNotificationGender(
  value: unknown,
): NotificationGender {
  return value === "male" || value === "female" || value === "other"
    ? value
    : "other";
}

function isNonNegativeNotificationMutationVersion(value: unknown): value is number {
  return (
    typeof value === "number" &&
    Number.isSafeInteger(value) &&
    value >= 0
  );
}

export function parseExpectedNotificationMutationVersion(
  value: unknown,
): ExpectedNotificationMutationVersion {
  if (value === undefined) return { kind: "legacy" };
  if (isNonNegativeNotificationMutationVersion(value)) {
    return { kind: "versioned", version: value };
  }
  return { kind: "invalid" };
}

export function notificationMutationDecision(
  expected: ExpectedNotificationMutationVersion,
  currentVersion: number | undefined,
): NotificationMutationDecision {
  if (expected.kind === "invalid") return "invalid";
  if (expected.kind === "legacy") {
    return currentVersion === undefined ? "apply" : "legacyBlocked";
  }
  return expected.version === (currentVersion ?? 0) ? "apply" : "stale";
}

export function hasValidNotificationTypeSchema(
  value: unknown,
): value is ValidNotificationType {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  const data = value as Record<string, unknown>;
  if (data.messageType === "dynamic") {
    return (
      data.quotesCollections !== null &&
      typeof data.quotesCollections === "object" &&
      !Array.isArray(data.quotesCollections)
    );
  }
  if (data.messageType === "static") {
    return (
      typeof data.staticTitle === "string" &&
      typeof data.staticBody === "string"
    );
  }
  return false;
}

export function buildNotificationDeliveryKey(
  uid: string,
  typeId: string,
  localDate: string,
  intendedTime: string,
): string {
  return Buffer.from(
    JSON.stringify([uid, typeId, localDate, intendedTime]),
    "utf8",
  ).toString("base64url");
}

export function israelLocalDeliveryCandidates(
  scheduleTime: Date,
  candidateCount = 121,
): IsraelLocalDeliveryCandidate[] {
  const dateFormatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Jerusalem",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  const timeFormatter = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Asia/Jerusalem",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  });

  return Array.from({ length: candidateCount }, (_, minuteOffset) => {
    const intendedAt = new Date(scheduleTime.getTime() - minuteOffset * 60_000);
    const dateParts = dateFormatter.formatToParts(intendedAt);
    const timeParts = timeFormatter.formatToParts(intendedAt);
    const year = dateParts.find((part) => part.type === "year")?.value;
    const month = dateParts.find((part) => part.type === "month")?.value;
    const day = dateParts.find((part) => part.type === "day")?.value;
    const hour = timeParts.find((part) => part.type === "hour")?.value;
    const minute = timeParts.find((part) => part.type === "minute")?.value;

    if (!year || !month || !day || !hour || !minute) {
      throw new Error("Could not derive Israel-local delivery time");
    }

    return {
      localDate: `${year}-${month}-${day}`,
      intendedTime: `${hour}:${minute}`,
      hour: Number(hour),
      minute: Number(minute),
      intendedAt,
    };
  });
}

export function israelLocalDeliveryCandidatesSince(
  scheduleTime: Date,
  lastProcessedAt: Date | undefined,
): IsraelLocalDeliveryCandidate[] {
  if (lastProcessedAt === undefined) {
    return israelLocalDeliveryCandidates(scheduleTime, 1);
  }

  const elapsedMinutes = Math.max(
    1,
    Math.min(
      121,
      Math.floor((scheduleTime.getTime() - lastProcessedAt.getTime()) / 60_000),
    ),
  );
  return israelLocalDeliveryCandidates(scheduleTime, elapsedMinutes);
}

export function selectScheduledNotificationCandidates<
  T extends ScheduledNotificationDocument,
>(
  docs: readonly T[],
  deliveryCandidates: readonly IsraelLocalDeliveryCandidate[],
): Array<{ doc: T; candidate: IsraelLocalDeliveryCandidate }> {
  const candidatesByTime = new Map(
    deliveryCandidates.map((candidate) => [
      `${candidate.hour}:${candidate.minute}`,
      candidate,
    ]),
  );

  return docs.flatMap((doc) => {
    const { hour, minute, updatedAt } = doc.data();
    if (!Number.isInteger(hour) || !Number.isInteger(minute)) return [];
    const candidate = candidatesByTime.get(`${hour}:${minute}`);
    if (!candidate) return [];
    if (
      updatedAt !== null &&
      typeof updatedAt === "object" &&
      "toMillis" in updatedAt &&
      typeof (updatedAt as TimestampLike).toMillis === "function" &&
      candidate.intendedAt.getTime() < (updatedAt as TimestampLike).toMillis()
    ) {
      return [];
    }
    return [{ doc, candidate }];
  });
}

export function scheduledNotificationQueryPlan(
  deliveryCandidates: readonly IsraelLocalDeliveryCandidate[],
): ScheduledNotificationQueryPlan {
  if (deliveryCandidates.length === 0) {
    throw new Error("Expected at least one delivery candidate");
  }
  if (deliveryCandidates.length === 1) {
    return {
      kind: "exact",
      hour: deliveryCandidates[0].hour,
      minute: deliveryCandidates[0].minute,
    };
  }
  return {
    kind: "catchUp",
    hours: [...new Set(deliveryCandidates.map((candidate) => candidate.hour))],
  };
}

export function shouldAdvanceSchedulerCheckpoint(
  claimFailedCount: number,
): boolean {
  return claimFailedCount === 0;
}

function isAlreadyClaimedError(error: unknown): boolean {
  if (error === null || typeof error !== "object") return false;
  const code = (error as { code?: unknown }).code;
  return code === 6 || code === "already-exists";
}

function failureCode(error: unknown): string {
  if (error !== null && typeof error === "object") {
    const errorInfoCode = (error as { errorInfo?: { code?: unknown } })
      .errorInfo?.code;
    if (typeof errorInfoCode === "string") return errorInfoCode;
    const code = (error as { code?: unknown }).code;
    if (typeof code === "string") return code;
  }
  return "unknown";
}

export async function claimAndSendScheduledDelivery(
  delivery: ScheduledDelivery,
  writer: ScheduledDeliveryWriter,
  send: (message: FcmMessage) => Promise<string>,
): Promise<ScheduledDeliveryResult> {
  const deliveryKey = buildNotificationDeliveryKey(
    delivery.uid,
    delivery.typeId,
    delivery.localDate,
    delivery.intendedTime,
  );
  const claimedAt = new Date();
  try {
    await writer.create({
      deliveryKey,
      uid: delivery.uid,
      typeId: delivery.typeId,
      localDate: delivery.localDate,
      intendedTime: delivery.intendedTime,
      status: "claimed",
      claimedAt,
      attemptStartedAt: claimedAt,
      expiresAt: new Date(delivery.intendedAt.getTime() + 86_400_000),
    });
  } catch (error: unknown) {
    if (isAlreadyClaimedError(error)) return "alreadyClaimed";
    console.error(`Scheduled delivery claim failed: ${deliveryKey}`, error);
    return "claimFailed";
  }

  try {
    const messageId = await send(delivery.message);
    try {
      await writer.update({
        status: "sent",
        attemptFinishedAt: new Date(),
        messageId,
      });
    } catch (error: unknown) {
      console.error(`Scheduled delivery sent-status update failed: ${deliveryKey}`, error);
    }
    return "sent";
  } catch (error: unknown) {
    try {
      await writer.update({
        status: "failed",
        attemptFinishedAt: new Date(),
        failureCode: failureCode(error),
      });
    } catch (updateError: unknown) {
      console.error(`Scheduled delivery failure-status update failed: ${deliveryKey}`, updateError);
    }
    return "failed";
  }
}

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

  await Promise.all([
    ...scheduledSnap.docs.map((doc) => doc.ref.delete()),
    db.collection("devices").doc(uid).delete(),
  ]);
}

class NotificationMutationConflictError extends Error {}

// ---------------------------------------------------------------------------
// getNotificationMutationVersion — returns the server-authoritative version
// used to fence scheduled-notification writes for one authenticated account.
// ---------------------------------------------------------------------------
export const getNotificationMutationVersion = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const uid = await extractAndVerifyUid(req);
  if (!uid) {
    res.status(401).send("Unauthorized");
    return;
  }

  const stateDoc = await admin
    .firestore()
    .collection("notification_mutation_state")
    .doc(uid)
    .get();
  if (!stateDoc.exists) {
    res.send({ mutationVersion: 0 });
    return;
  }

  const mutationVersion = stateDoc.data()?.version;
  if (!isNonNegativeNotificationMutationVersion(mutationVersion)) {
    res.status(500).send("Invalid notification mutation state");
    return;
  }
  res.send({ mutationVersion });
});

// ---------------------------------------------------------------------------
// registerNotification — creates or updates a scheduled notification entry.
// Body: { typeId: string, hour: number, minute: number,
//         expectedMutationVersion?: non-negative integer }
// ---------------------------------------------------------------------------
export const registerNotification = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const uid = await extractAndVerifyUid(req);
  if (!uid) {
    res.status(401).send("Unauthorized");
    return;
  }

  const { typeId, hour, minute, locale, gender, expectedMutationVersion } =
    req.body;
  const expectedVersion = parseExpectedNotificationMutationVersion(
    expectedMutationVersion,
  );

  if (
    !isValidNotificationTypeId(typeId) ||
    !Number.isFinite(hour) ||
    !Number.isInteger(hour) ||
    !Number.isFinite(minute) ||
    !Number.isInteger(minute) ||
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
  if (expectedVersion.kind === "invalid") {
    res.status(400).send("Invalid expectedMutationVersion");
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

  const db = admin.firestore();
  const stateRef = db.collection("notification_mutation_state").doc(uid);
  const scheduleRef = db
    .collection("scheduled_notifications")
    .doc(`${uid}_${typeId}`);
  try {
    await db.runTransaction(async (transaction) => {
      const stateDoc = await transaction.get(stateRef);
      let currentVersion: number | undefined;
      if (stateDoc.exists) {
        const storedVersion = stateDoc.data()?.version;
        if (!isNonNegativeNotificationMutationVersion(storedVersion)) {
          throw new Error("Invalid notification mutation state");
        }
        currentVersion = storedVersion;
      }
      if (notificationMutationDecision(expectedVersion, currentVersion) !== "apply") {
        throw new NotificationMutationConflictError("Stale notification mutation");
      }

      transaction.set(scheduleRef, {
        uid,
        typeId,
        hour,
        minute,
        locale,
        gender: normalizeNotificationGender(gender),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      if (expectedVersion.kind === "versioned") {
        transaction.set(stateRef, { version: (currentVersion ?? 0) + 1 });
      }
    });
  } catch (error) {
    if (error instanceof NotificationMutationConflictError) {
      res.status(409).send(error.message);
      return;
    }
    throw error;
  }

  res.send({ success: true });
});

// ---------------------------------------------------------------------------
// cancelNotification — deletes the scheduled notification entry.
// Body: { typeId: string, expectedMutationVersion?: non-negative integer }
// ---------------------------------------------------------------------------
export const cancelNotification = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const uid = await extractAndVerifyUid(req);
  if (!uid) {
    res.status(401).send("Unauthorized");
    return;
  }

  const { typeId, expectedMutationVersion } = req.body;
  if (!isValidNotificationTypeId(typeId)) {
    res.status(400).send("Invalid typeId");
    return;
  }
  const expectedVersion = parseExpectedNotificationMutationVersion(
    expectedMutationVersion,
  );
  if (expectedVersion.kind === "invalid") {
    res.status(400).send("Invalid expectedMutationVersion");
    return;
  }

  const db = admin.firestore();
  const stateRef = db.collection("notification_mutation_state").doc(uid);
  const scheduleRef = db
    .collection("scheduled_notifications")
    .doc(`${uid}_${typeId}`);
  try {
    await db.runTransaction(async (transaction) => {
      const stateDoc = await transaction.get(stateRef);
      let currentVersion: number | undefined;
      if (stateDoc.exists) {
        const storedVersion = stateDoc.data()?.version;
        if (!isNonNegativeNotificationMutationVersion(storedVersion)) {
          throw new Error("Invalid notification mutation state");
        }
        currentVersion = storedVersion;
      }
      if (notificationMutationDecision(expectedVersion, currentVersion) !== "apply") {
        throw new NotificationMutationConflictError("Stale notification mutation");
      }

      transaction.delete(scheduleRef);
      if (expectedVersion.kind === "versioned") {
        transaction.set(stateRef, { version: (currentVersion ?? 0) + 1 });
      }
    });
  } catch (error) {
    if (error instanceof NotificationMutationConflictError) {
      res.status(409).send(error.message);
      return;
    }
    throw error;
  }

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
  { schedule: "every 1 minutes", timeoutSeconds: 300, memory: "512MiB" },
  async (event) => {
    // --- Query phase ---
    const scheduleTime = new Date(event.scheduleTime);
    const db = admin.firestore();
    const schedulerStateRef = db
      .collection("notification_scheduler_state")
      .doc("primary");
    const schedulerState = await schedulerStateRef.get();
    const lastProcessedMillis = schedulerState.data()?.lastProcessedMillis;
    const deliveryCandidates = israelLocalDeliveryCandidatesSince(
      scheduleTime,
      typeof lastProcessedMillis === "number"
        ? new Date(lastProcessedMillis)
        : undefined,
    );
    const scheduledNotifications = db.collection("scheduled_notifications");
    const queryPlan = scheduledNotificationQueryPlan(deliveryCandidates);
    const snapshot = queryPlan.kind === "exact"
      ? await scheduledNotifications
        .where("hour", "==", queryPlan.hour)
        .where("minute", "==", queryPlan.minute)
        .get()
      : await scheduledNotifications.where("hour", "in", queryPlan.hours).get();

    const scheduledCandidates = selectScheduledNotificationCandidates(
      snapshot.docs,
      deliveryCandidates,
    );

    const advanceSchedulerCheckpoint = () => db.runTransaction(async (transaction) => {
      const currentState = await transaction.get(schedulerStateRef);
      const currentMillis = currentState.data()?.lastProcessedMillis;
      if (
        typeof currentMillis === "number" &&
        currentMillis >= scheduleTime.getTime()
      ) {
        return;
      }
      transaction.set(
        schedulerStateRef,
        {
          lastProcessedMillis: scheduleTime.getTime(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    if (scheduledCandidates.length === 0) {
      if (shouldAdvanceSchedulerCheckpoint(0)) {
        await advanceSchedulerCheckpoint();
      }
      return;
    }

    // --- Pre-fetch phase ---

    // Collect unique typeIds and all locales present per typeId
    const localesByTypeId = new Map<string, Set<string>>();
    for (const { doc } of scheduledCandidates) {
      const { typeId, locale } = doc.data();
      if (
        !isValidNotificationTypeId(typeId) ||
        typeof locale !== "string"
      ) {
        continue;
      }
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
    const neededQuoteCollections = new Set<string>();
    for (const [typeId, locales] of localesByTypeId.entries()) {
      const typeData = typeDataMap.get(typeId);
      if (
        !hasValidNotificationTypeSchema(typeData) ||
        typeData.messageType !== "dynamic"
      ) {
        continue;
      }
      for (const locale of locales) {
        const collectionName =
          typeData.quotesCollections[locale] ??
          typeData.quotesCollections["he"];
        if (
          typeof collectionName === "string" &&
          collectionName.length > 0
        ) {
          neededQuoteCollections.add(collectionName);
        }
      }
    }

    const quotesMap = new Map<string, FirebaseFirestore.DocumentData[]>();
    await Promise.all(
      [...neededQuoteCollections].map(async (collectionName) => {
        const snap = await admin
          .firestore()
          .collection(collectionName)
          .get();
        quotesMap.set(collectionName, snap.docs.map((d) => d.data()));
      }),
    );

    // --- Device fetch phase (parallel) ---

    const uniqueUids = [
      ...new Set(
        scheduledCandidates
          .map(({ doc }) => doc.data().uid)
          .filter(
            (uid): uid is string =>
              typeof uid === "string" && uid.length > 0,
          ),
      ),
    ];
    const deviceDocs = await Promise.all(
      uniqueUids.map((uid) =>
        admin.firestore().collection("devices").doc(uid).get(),
      ),
    );
    const deviceMap = new Map(
      deviceDocs.map((d) => [d.id, d.data()]),
    );

    // --- Build send list, collecting stale UIDs for deferred cleanup ---

    const staleUids: string[] = [];
    const sendTasks: Array<() => Promise<ScheduledDeliveryResult>> = [];

    for (const { doc, candidate } of scheduledCandidates) {
      const { uid, typeId, locale, gender } = doc.data();
      if (
        typeof uid !== "string" ||
        !isValidNotificationTypeId(typeId) ||
        typeof locale !== "string"
      ) {
        continue;
      }

      const deviceData = deviceMap.get(uid);

      const updatedAt = deviceData?.updatedAt as
        | admin.firestore.Timestamp
        | undefined;
      if (updatedAt) {
        const ageDays = (Date.now() - updatedAt.toMillis()) / 86_400_000;
        if (ageDays > STALE_TOKEN_DAYS) {
          staleUids.push(uid);
          continue;
        }
      }

      const fcmToken = deviceData?.fcmToken as string | undefined;
      if (!fcmToken) continue;

      const typeData = typeDataMap.get(typeId);
      if (!hasValidNotificationTypeSchema(typeData)) continue;

      let title = "Living Positively";
      let body: string;

      if (typeData.messageType === "dynamic") {
        const collectionName =
          typeData.quotesCollections[locale] ??
          typeData.quotesCollections["he"];
        if (
          typeof collectionName !== "string" ||
          collectionName.length === 0
        ) {
          continue;
        }
        const quotes = quotesMap.get(collectionName);
        if (!quotes || quotes.length === 0) continue;
        const quoteData = quotes[Math.floor(Math.random() * quotes.length)];
        const normalizedGender = normalizeNotificationGender(gender);
        const quote = [
          quoteData[normalizedGender],
          quoteData.other,
          quoteData.male,
          quoteData.text,
        ].find(
          (candidate): candidate is string =>
            typeof candidate === "string",
        );
        if (quote === undefined) continue;
        body = quote;
      } else {
        title = typeData.staticTitle;
        body = typeData.staticBody;
      }

      const deliveryKey = buildNotificationDeliveryKey(
        uid,
        typeId,
        candidate.localDate,
        candidate.intendedTime,
      );
      const deliveryRef = admin
        .firestore()
        .collection("notification_deliveries")
        .doc(deliveryKey);
      sendTasks.push(() =>
        claimAndSendScheduledDelivery(
          {
            uid,
            typeId,
            localDate: candidate.localDate,
            intendedTime: candidate.intendedTime,
            intendedAt: candidate.intendedAt,
            message: {
              token: fcmToken,
              notification: { title, body },
              data: { deliveryKey },
            },
          },
          {
            create: (data) => deliveryRef.create(data),
            update: (data) => deliveryRef.update(data),
          },
          async (message) => {
            try {
              return await admin.messaging().send(message);
            } catch (error: unknown) {
              if (
                failureCode(error) ===
                "messaging/registration-token-not-registered"
              ) {
                await clearFCMToken(uid);
              }
              throw error;
            }
          },
        ),
      );
    }

    // --- Send phase (batched parallel) ---

    const results: PromiseSettledResult<ScheduledDeliveryResult>[] = [];
    for (let start = 0; start < sendTasks.length; start += 25) {
      results.push(...await Promise.allSettled(
        sendTasks.slice(start, start + 25).map((task) => task()),
      ));
    }
    let successCount = 0;
    let failureCount = 0;
    let alreadyClaimedCount = 0;
    let claimFailedCount = 0;
    for (const r of results) {
      if (r.status === "fulfilled" && r.value === "sent") successCount++;
      else if (r.status === "fulfilled" && r.value === "alreadyClaimed") {
        alreadyClaimedCount++;
      } else if (r.status === "fulfilled" && r.value === "claimFailed") {
        claimFailedCount++;
        failureCount++;
      } else failureCount++;
    }

    // --- Stale device cleanup (batched, after sends) ---

    const staleDeviceIds = [...new Set(staleUids)];
    if (staleDeviceIds.length > 0) {
      await Promise.allSettled(
        staleDeviceIds.map((uid) => cleanupInactiveDevice(uid)),
      );
    }

    console.log(
      `processScheduledNotifications: sent=${successCount}, failed=${failureCount}, alreadyClaimed=${alreadyClaimedCount}, claimFailed=${claimFailedCount}, staleDevicesCleaned=${staleDeviceIds.length}`,
    );

    if (shouldAdvanceSchedulerCheckpoint(claimFailedCount)) {
      await advanceSchedulerCheckpoint();
    }
  },
);
