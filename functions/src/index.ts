import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import {
  FieldPath,
  FieldValue,
  getFirestore,
  Timestamp,
} from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { Buffer } from "node:buffer";
import { setGlobalOptions } from "firebase-functions";
import { onRequest, Request } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/scheduler";
import {
  executeNotificationMutation,
  hasActiveDeliveryPermit,
  hasMatchingNotificationScheduleIdentity,
  isNonNegativeNotificationMutationVersion,
  isValidResetFenceMutation,
  notificationScheduleId,
  notificationMutationStatePath,
  parseExpectedNotificationMutationVersion,
} from "./notification_mutation.js";
import {
  hasValidNotificationTypeSchema,
  isValidNotificationLocale,
  isValidNotificationScheduleTime,
  isValidNotificationTypeId,
  isValidNotificationUid,
  normalizeNotificationGender,
} from "./notification_validation.js";
import {
  schedulerRecoveryWindow,
  scheduledNotificationSummary,
} from "./scheduler_observability.js";

initializeApp();
setGlobalOptions({ maxInstances: 10 });

const STALE_TOKEN_DAYS = 180;
// Allow small scheduler/Firestore clock differences around serverTimestamp().
const DEVICE_TIMESTAMP_FUTURE_SKEW_MILLIS = 5 * 60_000;
const DELIVERY_PERMIT_DURATION_MILLIS = 305_000;
const DELIVERY_SEND_BATCH_SIZE = 25;
const MAX_SCHEDULED_NOTIFICATIONS_PER_RECOVERY_PAGE = 250;
const MAX_STALE_DEVICE_CLEANUPS_PER_INVOCATION = 25;
const STALE_DEVICE_CLEANUP_BATCH_SIZE = 5;
const MAX_SCHEDULED_NOTIFICATIONS_PER_STALE_DEVICE_CLEANUP = 25;

// These endpoints still require a Firebase ID token. CORS only permits the
// deployed web app to send that token; it does not grant access itself.
// Keep the origin explicit so an accidental browser deployment cannot use an
// authenticated user's token against these mutation endpoints.
export function notificationClientCors(
  configuredOrigin = process.env.NOTIFICATION_CLIENT_ORIGIN,
): string | false {
  const origin = configuredOrigin?.trim();
  if (!origin) return false;
  try {
    const parsed = new URL(origin);
    return parsed.protocol === "https:" && parsed.origin === origin
      ? origin
      : false;
  } catch {
    return false;
  }
}

export function notificationRequestOptions(
  configuredOrigin = process.env.NOTIFICATION_CLIENT_ORIGIN,
): { cors?: string } {
  const cors = notificationClientCors(configuredOrigin);
  return cors === false ? {} : { cors };
}

// Omitting `cors` entirely keeps firebase-functions from installing its CORS
// middleware. Passing `false` would instead be interpreted by that middleware
// as permissive browser CORS.
const authenticatedNotificationRequestOptions = notificationRequestOptions();

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
  releasePermit?(): Promise<unknown>;
};
export type ScheduledDelivery = {
  uid: string;
  typeId: string;
  localDate: string;
  intendedTime: string;
  intendedAt: Date;
  message: FcmMessage;
};
type ScheduledDeliveryResult =
  | "sent"
  | "failed"
  | "alreadyClaimed"
  | "claimFailed"
  | "notCurrent";
type StaleDeviceCleanupOutcome = "cleaned" | "deferred" | "skipped";
type TimestampLike = {
  isEqual?(other: unknown): boolean;
  toMillis?(): number;
  seconds?: unknown;
  nanoseconds?: unknown;
};
type ScheduledNotificationDocument = {
  data(): Record<string, unknown>;
};
export type ScheduledNotificationQueryPlan =
  | { kind: "exact"; hour: number; minute: number }
  | { kind: "catchUp"; hours: number[] };
function notificationMutationStateRef(
  db: FirebaseFirestore.Firestore,
  uid: string,
  typeId: string,
): FirebaseFirestore.DocumentReference {
  return db.doc(notificationMutationStatePath(uid, typeId));
}

function notificationScheduleRef(
  db: FirebaseFirestore.Firestore,
  uid: string,
  typeId: string,
): FirebaseFirestore.DocumentReference {
  return db.collection("scheduled_notifications").doc(
    notificationScheduleId(uid, typeId),
  );
}

function legacyNotificationScheduleRef(
  db: FirebaseFirestore.Firestore,
  uid: string,
  typeId: string,
): FirebaseFirestore.DocumentReference {
  return db.collection("scheduled_notifications").doc(`${uid}_${typeId}`);
}

function isNotificationMutationRequestBody(
  value: unknown,
): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

type NotificationScheduleDescriptor = {
  hour: number;
  minute: number;
};

function notificationScheduleDescriptor(
  schedule: Record<string, unknown> | undefined,
  uid: string,
  typeId: string,
): NotificationScheduleDescriptor | undefined {
  if (
    schedule === undefined ||
    !hasMatchingNotificationScheduleIdentity(schedule, uid, typeId)
  ) {
    return undefined;
  }
  const { hour, minute } = schedule;
  if (
    typeof hour !== "number" ||
    !Number.isInteger(hour) ||
    hour < 0 ||
    hour > 23 ||
    typeof minute !== "number" ||
    !Number.isInteger(minute) ||
    minute < 0 ||
    minute > 59
  ) {
    return undefined;
  }
  return { hour, minute };
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
    if (!(updatedAt instanceof Timestamp)) return [];
    if (candidate.intendedAt.getTime() < updatedAt.toMillis()) {
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

export function isValidSchedulerCheckpoint(
  value: unknown,
  scheduleMillis: number,
): value is number {
  return (
    typeof value === "number" &&
    Number.isSafeInteger(value) &&
    value >= 0 &&
    value <= 8_640_000_000_000_000 &&
    value <= scheduleMillis
  );
}

export type SchedulerRecoveryContinuation = {
  scheduleTimeMillis: number;
  cursorDocumentId: string;
};

export function schedulerRecoveryContinuation(
  state: Record<string, unknown> | undefined,
  currentScheduleMillis: number,
): SchedulerRecoveryContinuation | undefined {
  const scheduleTimeMillis = state?.recoveryScheduleTimeMillis;
  const cursorDocumentId = state?.recoveryCursorDocumentId;
  if (
    !isValidSchedulerCheckpoint(scheduleTimeMillis, currentScheduleMillis) ||
    typeof cursorDocumentId !== "string" ||
    cursorDocumentId.length === 0
  ) {
    return undefined;
  }
  return { scheduleTimeMillis, cursorDocumentId };
}

export type DeviceUpdatedAtClassification =
  | "missing"
  | "fresh"
  | "stale"
  | "malformed";

export function classifyDeviceUpdatedAt(
  updatedAt: unknown,
  nowMillis: number,
): DeviceUpdatedAtClassification {
  if (updatedAt === undefined) return "missing";
  if (!(updatedAt instanceof Timestamp)) return "malformed";

  let timestampParts: ReturnType<typeof timestampSecondsAndNanoseconds>;
  try {
    timestampParts = timestampSecondsAndNanoseconds(updatedAt);
  } catch {
    return "malformed";
  }
  if (timestampParts === undefined) return "malformed";

  const updatedAtMillis =
    timestampParts.seconds * 1_000 +
    Math.floor(timestampParts.nanoseconds / 1_000_000);
  if (!Number.isSafeInteger(updatedAtMillis)) return "malformed";
  if (updatedAtMillis > nowMillis + DEVICE_TIMESTAMP_FUTURE_SKEW_MILLIS) {
    return "malformed";
  }

  return nowMillis - updatedAtMillis > STALE_TOKEN_DAYS * 86_400_000
    ? "stale"
    : "fresh";
}

type DeviceUpdatedAtEntry = {
  uid: string;
  updatedAt: unknown;
};

type DeviceUpdatedAtRoutes = {
  deliveryEligibleUids: string[];
  staleUids: string[];
  malformedUids: string[];
};

export function routeDevicesByUpdatedAt(
  entries: readonly DeviceUpdatedAtEntry[],
  nowMillis: number,
): DeviceUpdatedAtRoutes {
  const routes: DeviceUpdatedAtRoutes = {
    deliveryEligibleUids: [],
    staleUids: [],
    malformedUids: [],
  };

  for (const entry of entries) {
    const classification = classifyDeviceUpdatedAt(entry.updatedAt, nowMillis);
    if (classification === "stale") {
      routes.staleUids.push(entry.uid);
    } else if (classification === "malformed") {
      routes.malformedUids.push(entry.uid);
    } else {
      routes.deliveryEligibleUids.push(entry.uid);
    }
  }

  return routes;
}

function timestampSecondsAndNanoseconds(
  value: unknown,
): { seconds: number; nanoseconds: number } | undefined {
  if (value === null || typeof value !== "object") {
    return undefined;
  }
  const { seconds, nanoseconds } = value as TimestampLike;
  if (
    typeof seconds !== "number" ||
    typeof nanoseconds !== "number" ||
    !Number.isSafeInteger(seconds) ||
    !Number.isInteger(nanoseconds) ||
    nanoseconds < 0 ||
    nanoseconds >= 1_000_000_000
  ) {
    return undefined;
  }
  return { seconds, nanoseconds };
}

function timestampsAreExactlyEqual(left: unknown, right: unknown): boolean {
  return (
    left instanceof Timestamp &&
    right instanceof Timestamp &&
    left.isEqual(right)
  );
}

export function isCurrentScheduledNotification(
  selectedSchedule: Record<string, unknown>,
  currentSchedule: Record<string, unknown> | undefined,
  currentState: Record<string, unknown> | undefined,
): boolean {
  if (currentSchedule === undefined) return false;

  const selectedMutationVersion = selectedSchedule.mutationVersion;
  const currentMutationVersion = currentSchedule.mutationVersion;
  if (selectedMutationVersion === undefined) {
    return (
      currentMutationVersion === undefined &&
      (currentState === undefined ||
        (currentState.version === undefined &&
          !hasActiveDeliveryPermit(currentState))) &&
      timestampsAreExactlyEqual(
        selectedSchedule.updatedAt,
        currentSchedule.updatedAt,
      )
    );
  }

  return (
    isNonNegativeNotificationMutationVersion(selectedMutationVersion) &&
    currentMutationVersion === selectedMutationVersion &&
    currentState?.version === selectedMutationVersion
  );
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
    const claimResult = await writer.create({
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
    if (claimResult === "notCurrent") return "notCurrent";
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
      console.error(
        `Scheduled delivery sent-status update failed: ${deliveryKey}`,
        error,
      );
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
      console.error(
        `Scheduled delivery failure-status update failed: ${deliveryKey}`,
        updateError,
      );
    }
    return "failed";
  } finally {
    try {
      await writer.releasePermit?.();
    } catch (error: unknown) {
      console.error(
        `Scheduled delivery permit release failed: ${deliveryKey}`,
        error,
      );
    }
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
    const decoded = await getAuth().verifyIdToken(idToken);
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
export function shouldClearFCMToken(
  storedToken: unknown,
  failedToken: string,
): boolean {
  return typeof storedToken === "string" && storedToken === failedToken;
}

export function hasValidFCMToken(value: unknown): value is string {
  return typeof value === "string" && value.length > 0;
}

async function clearFCMToken(uid: string, failedToken: string): Promise<void> {
  const db = getFirestore();
  const deviceRef = db.collection("devices").doc(uid);
  await db.runTransaction(async (transaction) => {
    const device = await transaction.get(deviceRef);
    if (!shouldClearFCMToken(device.data()?.fcmToken, failedToken)) return;
    transaction.update(deviceRef, {
      fcmToken: FieldValue.delete(),
    });
  });
}

// ---------------------------------------------------------------------------
// cleanupInactiveDevice — deletes a bounded batch of schedules for a user who
// has been inactive for STALE_TOKEN_DAYS. It reads one document past the
// deletion cap so a user with exactly one full batch is fully removed.
// triggered when:
// 1. user is inactive for 180 days.
// ---------------------------------------------------------------------------
async function cleanupInactiveDevice(
  uid: string,
  expectedUpdatedAt: Timestamp,
): Promise<StaleDeviceCleanupOutcome> {
  const db = getFirestore();
  const deviceRef = db.collection("devices").doc(uid);
  const schedules = db
    .collection("scheduled_notifications")
    .where("uid", "==", uid)
    .limit(MAX_SCHEDULED_NOTIFICATIONS_PER_STALE_DEVICE_CLEANUP + 1);

  return db.runTransaction(async (transaction) => {
    const device = await transaction.get(deviceRef);
    // A foreground launch can refresh this document after pre-fetch. Keeping
    // all reads and deletes in one transaction protects that fresh schedule.
    if (!timestampsAreExactlyEqual(device.data()?.updatedAt, expectedUpdatedAt)) {
      return "skipped";
    }
    const scheduledSnap = await transaction.get(schedules);
    const cleanupPlan = staleDeviceScheduleCleanupPlan(scheduledSnap.size);
    const cleanupOutcome = staleDeviceCleanupOutcome(scheduledSnap.size);
    for (const doc of scheduledSnap.docs.slice(0, cleanupPlan.scheduleDeletes)) {
      transaction.delete(doc.ref);
    }
    if (cleanupOutcome === "cleaned") transaction.delete(deviceRef);
    return cleanupOutcome;
  });
}

export function staleDeviceScheduleCleanupPlan(scheduleCount: number): {
  scheduleDeletes: number;
  deleteDevice: boolean;
} {
  return {
    scheduleDeletes: Math.min(
      scheduleCount,
      MAX_SCHEDULED_NOTIFICATIONS_PER_STALE_DEVICE_CLEANUP,
    ),
    deleteDevice:
      scheduleCount <= MAX_SCHEDULED_NOTIFICATIONS_PER_STALE_DEVICE_CLEANUP,
  };
}

export function staleDeviceCleanupOutcome(
  scheduleCount: number,
): "cleaned" | "deferred" {
  return staleDeviceScheduleCleanupPlan(scheduleCount).deleteDevice
    ? "cleaned"
    : "deferred";
}

export function staleDeviceCleanupBatch(
  staleUids: readonly string[],
  totalStaleDeviceCount?: number,
): {
  cleanupUids: string[];
  deferredCount: number;
} {
  const uniqueUids = [...new Set(staleUids)];
  const reportedStaleDeviceCount = Math.max(
    uniqueUids.length,
    totalStaleDeviceCount ?? uniqueUids.length,
  );
  return {
    cleanupUids: uniqueUids.slice(0, MAX_STALE_DEVICE_CLEANUPS_PER_INVOCATION),
    deferredCount: Math.max(
      0,
      reportedStaleDeviceCount -
        Math.min(
          uniqueUids.length,
          MAX_STALE_DEVICE_CLEANUPS_PER_INVOCATION,
        ),
    ),
  };
}

class NotificationMutationConflictError extends Error {}

// ---------------------------------------------------------------------------
// getNotificationMutationVersion — returns the server-authoritative version
// used to fence scheduled-notification writes for one authenticated schedule.
// Body: { typeId: string }
// ---------------------------------------------------------------------------
export const getNotificationMutationVersion = onRequest(
  authenticatedNotificationRequestOptions,
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const uid = await extractAndVerifyUid(req);
    if (!uid) {
      res.status(401).send("Unauthorized");
      return;
    }
    if (!isValidNotificationUid(uid)) {
      res.status(400).send("Invalid authenticated uid");
      return;
    }

    const typeId = req.body?.typeId;
    if (!isValidNotificationTypeId(typeId)) {
      res.status(400).send("Invalid typeId");
      return;
    }

    const stateDoc = await notificationMutationStateRef(
      getFirestore(),
      uid,
      typeId,
    ).get();
    if (!stateDoc.exists) {
      res.send({ mutationVersion: 0 });
      return;
    }

    const mutationVersion = stateDoc.data()?.version;
    if (mutationVersion === undefined) {
      res.send({ mutationVersion: 0 });
      return;
    }
    if (!isNonNegativeNotificationMutationVersion(mutationVersion)) {
      logger.warn("Invalid notification mutation state version", {
        uid,
        typeId,
        valueType: typeof mutationVersion,
      });
      res.send({ mutationVersion: 0 });
      return;
    }
    res.send({ mutationVersion });
  },
);

// ---------------------------------------------------------------------------
// registerNotification — creates or updates a scheduled notification entry.
// Body: { typeId: string, hour: number, minute: number,
//         expectedMutationVersion?: non-negative integer }
// ---------------------------------------------------------------------------
export const registerNotification = onRequest(
  authenticatedNotificationRequestOptions,
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const uid = await extractAndVerifyUid(req);
    if (!uid) {
      res.status(401).send("Unauthorized");
      return;
    }
    if (!isValidNotificationUid(uid)) {
      res.status(400).send("Invalid authenticated uid");
      return;
    }

    if (!isNotificationMutationRequestBody(req.body)) {
      res.status(400).send("Invalid body");
      return;
    }
    const { typeId, hour, minute, locale, gender, expectedMutationVersion } =
      req.body;
    const expectedVersion = parseExpectedNotificationMutationVersion(
      expectedMutationVersion,
    );

    if (
      !isValidNotificationTypeId(typeId) ||
      !isValidNotificationScheduleTime(hour, minute) ||
      !isValidNotificationLocale(locale)
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

    const typeDoc = await getFirestore()
      .collection("notification_types")
      .doc(typeId)
      .get();
    if (!typeDoc.exists || !hasValidNotificationTypeSchema(typeDoc.data())) {
      res.status(400).send(`Unknown or invalid typeId: ${typeId}`);
      return;
    }

    const db = getFirestore();
    const stateRef = notificationMutationStateRef(db, uid, typeId);
    const scheduleRef = notificationScheduleRef(db, uid, typeId);
    const legacyScheduleRef = legacyNotificationScheduleRef(db, uid, typeId);
    let mutationVersion: number | undefined;
    try {
      mutationVersion = await db.runTransaction(async (transaction) => {
        const legacySchedule =
          legacyScheduleRef.path === scheduleRef.path
            ? undefined
            : await transaction.get(legacyScheduleRef);
        const scheduleData: Record<string, unknown> = {
          uid,
          typeId,
          hour,
          minute,
          locale,
          gender: normalizeNotificationGender(gender),
          updatedAt: FieldValue.serverTimestamp(),
        };
        const decision =
          await executeNotificationMutation<FirebaseFirestore.DocumentReference>(
            transaction,
            {
              stateRef,
              scheduleRef,
              expectedVersion,
              rejectActiveDeliveryPermit: false,
              // A corrupt version is already unreadable. The authenticated
              // version read returns the recovery fence (0), so allow this
              // explicit registration to replace the unusable state.
              allowsCorruptStateRepair: true,
              operation: { kind: "register", scheduleData },
            },
          );
        if (decision.kind === "conflict") {
          throw new NotificationMutationConflictError(decision.message);
        }
        if (
          legacySchedule?.exists &&
          hasMatchingNotificationScheduleIdentity(
            legacySchedule.data(),
            uid,
            typeId,
          )
        ) {
          transaction.delete(legacyScheduleRef);
        }
        return decision.nextVersion;
      });
    } catch (error) {
      if (error instanceof NotificationMutationConflictError) {
        res.status(409).send(error.message);
        return;
      }
      throw error;
    }

    res.send({
      success: true,
      ...(mutationVersion === undefined ? {} : { mutationVersion }),
    });
  },
);

// ---------------------------------------------------------------------------
// cancelNotification — deletes the scheduled notification entry.
// Body: { typeId: string, expectedMutationVersion?: non-negative integer,
//         resetFence?: boolean }
// ---------------------------------------------------------------------------
export const cancelNotification = onRequest(
  authenticatedNotificationRequestOptions,
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const uid = await extractAndVerifyUid(req);
    if (!uid) {
      res.status(401).send("Unauthorized");
      return;
    }
    if (!isValidNotificationUid(uid)) {
      res.status(400).send("Invalid authenticated uid");
      return;
    }

    if (!isNotificationMutationRequestBody(req.body)) {
      res.status(400).send("Invalid body");
      return;
    }
    const { typeId, expectedMutationVersion, resetFence } = req.body;
    if (!isValidNotificationTypeId(typeId)) {
      res.status(400).send("Invalid typeId");
      return;
    }
    if (resetFence !== undefined && typeof resetFence !== "boolean") {
      res.status(400).send("Invalid resetFence");
      return;
    }
    const expectedVersion = parseExpectedNotificationMutationVersion(
      expectedMutationVersion,
    );
    if (expectedVersion.kind === "invalid") {
      res.status(400).send("Invalid expectedMutationVersion");
      return;
    }
    if (!isValidResetFenceMutation(resetFence, expectedVersion)) {
      res.status(400).send("resetFence requires expectedMutationVersion");
      return;
    }

    const db = getFirestore();
    const stateRef = notificationMutationStateRef(db, uid, typeId);
    const scheduleRef = notificationScheduleRef(db, uid, typeId);
    const legacyScheduleRef = legacyNotificationScheduleRef(db, uid, typeId);
    let mutationResult: {
      mutationVersion: number | undefined;
      schedule?: NotificationScheduleDescriptor;
    };
    try {
      mutationResult = await db.runTransaction(async (transaction) => {
        const [currentSchedule, legacySchedule] = await Promise.all([
          transaction.get(scheduleRef),
          legacyScheduleRef.path === scheduleRef.path
            ? Promise.resolve(undefined)
            : transaction.get(legacyScheduleRef),
        ]);
        const schedule =
          notificationScheduleDescriptor(
            currentSchedule.exists ? currentSchedule.data() : undefined,
            uid,
            typeId,
          ) ??
          notificationScheduleDescriptor(
            legacySchedule?.exists ? legacySchedule.data() : undefined,
            uid,
            typeId,
          );
        const decision =
          await executeNotificationMutation<FirebaseFirestore.DocumentReference>(
            transaction,
            {
              stateRef,
              scheduleRef,
              expectedVersion,
              // Only account reset/sign-out needs the privacy fence. Ordinary
              // toggle cancellation, including local-write compensation, must
              // be able to retire a schedule while a delivery permit expires.
              rejectActiveDeliveryPermit: resetFence === true,
              allowsCorruptStateRepair: resetFence === true,
              operation: { kind: "cancel" },
            },
          );
        if (decision.kind === "conflict") {
          throw new NotificationMutationConflictError(decision.message);
        }
        if (
          legacySchedule?.exists &&
          hasMatchingNotificationScheduleIdentity(
            legacySchedule.data(),
            uid,
            typeId,
          )
        ) {
          transaction.delete(legacyScheduleRef);
        }
        return { mutationVersion: decision.nextVersion, schedule };
      });
    } catch (error) {
      if (error instanceof NotificationMutationConflictError) {
        res.status(409).send(error.message);
        return;
      }
      throw error;
    }

    res.send({
      success: true,
      ...(mutationResult.mutationVersion === undefined
        ? {}
        : { mutationVersion: mutationResult.mutationVersion }),
      ...(mutationResult.schedule === undefined
        ? {}
        : { schedule: mutationResult.schedule }),
    });
  },
);

// ---------------------------------------------------------------------------
// processScheduledNotifications — runs every minute via Cloud Scheduler.
//
// Invocation flow:
//   1. Query phase   — query the bounded recovery window for matching
//                      scheduled_notifications, then continue through the
//                      checkpoint and structured summary even when none match.
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
    const db = getFirestore();
    const schedulerStateRef = db
      .collection("notification_scheduler_state")
      .doc("primary");
    const schedulerState = await schedulerStateRef.get();
    const schedulerStateData = schedulerState.data();
    const recoveryContinuation = schedulerRecoveryContinuation(
      schedulerStateData,
      scheduleTime.getTime(),
    );
    // Keep a paged recovery window fixed until it completes. Otherwise every
    // invocation would move the two-hour window forward and permanently lose
    // the earliest schedules while it works through a large result set.
    const recoveryScheduleTime = recoveryContinuation === undefined
      ? scheduleTime
      : new Date(recoveryContinuation.scheduleTimeMillis);
    const lastProcessedMillis = schedulerStateData?.lastProcessedMillis;
    const recoveryWindow = schedulerRecoveryWindow(
      recoveryScheduleTime,
      isValidSchedulerCheckpoint(
        lastProcessedMillis,
        recoveryScheduleTime.getTime(),
      )
        ? new Date(lastProcessedMillis)
        : undefined,
    );
    if (recoveryWindow.wasClamped) {
      logger.warn("processScheduledNotifications recovery window clamped", {
        recoveryCandidateMinutes: recoveryWindow.processedCandidateMinutes,
        requestedRecoveryCandidateMinutes:
          recoveryWindow.requestedCandidateMinutes,
      });
    }
    const deliveryCandidates = israelLocalDeliveryCandidates(
      recoveryScheduleTime,
      recoveryWindow.processedCandidateMinutes,
    );
    const scheduledNotifications = db.collection("scheduled_notifications");
    const queryPlan = scheduledNotificationQueryPlan(deliveryCandidates);
    let snapshot;
    let recoveryPageHasMore = false;
    if (queryPlan.kind === "exact") {
      snapshot = await scheduledNotifications
        .where("hour", "==", queryPlan.hour)
        .where("minute", "==", queryPlan.minute)
        .get();
    } else {
      let recoveryQuery = scheduledNotifications
        .where("hour", "in", queryPlan.hours)
        .orderBy(FieldPath.documentId());
      if (recoveryContinuation !== undefined) {
        recoveryQuery = recoveryQuery.startAfter(
          recoveryContinuation.cursorDocumentId,
        );
      }
      snapshot = await recoveryQuery
        .limit(MAX_SCHEDULED_NOTIFICATIONS_PER_RECOVERY_PAGE + 1)
        .get();
      recoveryPageHasMore =
        snapshot.size > MAX_SCHEDULED_NOTIFICATIONS_PER_RECOVERY_PAGE;
    }
    const pageDocs = recoveryPageHasMore
      ? snapshot.docs.slice(0, MAX_SCHEDULED_NOTIFICATIONS_PER_RECOVERY_PAGE)
      : snapshot.docs;
    if (recoveryPageHasMore) {
      logger.warn("processScheduledNotifications recovery page bounded", {
        recoveryScheduleTimeMillis: recoveryScheduleTime.getTime(),
        recoveryCursorDocumentId: recoveryContinuation?.cursorDocumentId,
        recoveryPageSize: MAX_SCHEDULED_NOTIFICATIONS_PER_RECOVERY_PAGE,
      });
    }

    const scheduledCandidates = selectScheduledNotificationCandidates(
      pageDocs,
      deliveryCandidates,
    );

    const advanceSchedulerCheckpoint = () =>
      db.runTransaction(async (transaction) => {
        const currentState = await transaction.get(schedulerStateRef);
        const currentMillis = currentState.data()?.lastProcessedMillis;
        const currentRecovery = schedulerRecoveryContinuation(
          currentState.data(),
          scheduleTime.getTime(),
        );
        if (
          currentRecovery !== undefined &&
          currentRecovery.scheduleTimeMillis !== recoveryScheduleTime.getTime()
        ) {
          return;
        }
        if (
          typeof currentMillis === "number" &&
          currentMillis >= recoveryScheduleTime.getTime()
        ) {
          return;
        }
        transaction.set(
          schedulerStateRef,
          {
            lastProcessedMillis: recoveryScheduleTime.getTime(),
            recoveryScheduleTimeMillis: FieldValue.delete(),
            recoveryCursorDocumentId: FieldValue.delete(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

    const advanceSchedulerRecoveryCursor = (cursorDocumentId: string) =>
      db.runTransaction(async (transaction) => {
        const currentState = await transaction.get(schedulerStateRef);
        const currentData = currentState.data();
        const currentMillis = currentData?.lastProcessedMillis;
        if (
          typeof currentMillis === "number" &&
          currentMillis >= recoveryScheduleTime.getTime()
        ) {
          return;
        }
        const currentRecovery = schedulerRecoveryContinuation(
          currentData,
          scheduleTime.getTime(),
        );
        if (
          currentRecovery !== undefined &&
          currentRecovery.scheduleTimeMillis !== recoveryScheduleTime.getTime()
        ) {
          return;
        }
        if (
          currentRecovery !== undefined &&
          currentRecovery.cursorDocumentId >= cursorDocumentId
        ) {
          return;
        }
        transaction.set(
          schedulerStateRef,
          {
            recoveryScheduleTimeMillis: recoveryScheduleTime.getTime(),
            recoveryCursorDocumentId: cursorDocumentId,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

    // --- Pre-fetch phase ---

    // Collect unique typeIds and all locales present per typeId
    const localesByTypeId = new Map<string, Set<string>>();
    for (const { doc } of scheduledCandidates) {
      const { typeId, locale } = doc.data();
      if (
        !isValidNotificationTypeId(typeId) ||
        !isValidNotificationLocale(locale)
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
        const doc = await getFirestore()
          .collection("notification_types")
          .doc(typeId)
          .get();
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
        if (typeof collectionName === "string" && collectionName.length > 0) {
          neededQuoteCollections.add(collectionName);
        }
      }
    }

    const quotesMap = new Map<string, FirebaseFirestore.DocumentData[]>();
    await Promise.all(
      [...neededQuoteCollections].map(async (collectionName) => {
        const snap = await getFirestore().collection(collectionName).get();
        quotesMap.set(
          collectionName,
          snap.docs.map((d) => d.data()),
        );
      }),
    );

    // --- Device fetch phase (parallel) ---

    const uniqueUids = [
      ...new Set(
        scheduledCandidates
          .map(({ doc }) => doc.data().uid)
          .filter(
          (uid): uid is string => isValidNotificationUid(uid),
          ),
      ),
    ];
    const nowMillis = Date.now();
    const staleDeviceQuery = db
      .collection("devices")
      .where(
        "updatedAt",
        "<",
        Timestamp.fromMillis(
          nowMillis - STALE_TOKEN_DAYS * 86_400_000,
        ),
      );
    const [
      deviceDocs,
      independentlyStaleDeviceSnapshot,
      independentlyStaleDeviceCount,
    ] = await Promise.all([
      Promise.all(
        uniqueUids.map((uid) => db.collection("devices").doc(uid).get()),
      ),
      staleDeviceQuery
        .limit(MAX_STALE_DEVICE_CLEANUPS_PER_INVOCATION + 1)
        .get()
        .catch((error: unknown) => {
          logger.warn("Unable to query stale devices independently", { error });
          return undefined;
        }),
      staleDeviceQuery
        .count()
        .get()
        .then((snapshot) => snapshot.data().count)
        .catch((error: unknown) => {
          logger.warn("Unable to count stale devices independently", { error });
          return undefined;
        }),
    ]);
    const deviceMap = new Map(deviceDocs.map((d) => [d.id, d.data()]));
    const deviceTimestampRoutes = routeDevicesByUpdatedAt(
      [...deviceMap.entries()].map(([uid, deviceData]) => ({
        uid,
        updatedAt: deviceData?.updatedAt,
      })),
      nowMillis,
    );
    const independentlyStaleDeviceEntries =
      independentlyStaleDeviceSnapshot?.docs
        .filter((doc) => isValidNotificationUid(doc.id))
        .map((doc) => ({
          uid: doc.id,
          updatedAt: doc.data()?.updatedAt,
          data: doc.data(),
        })) ?? [];
    const independentlyStaleDeviceRoutes = routeDevicesByUpdatedAt(
      independentlyStaleDeviceEntries,
      nowMillis,
    );
    const deliveryEligibleUids = new Set(
      deviceTimestampRoutes.deliveryEligibleUids,
    );
    const staleDeviceUids = new Set([
      ...deviceTimestampRoutes.staleUids,
      ...independentlyStaleDeviceRoutes.staleUids,
    ]);
    const allDeviceEntries = new Map([
      ...deviceMap.entries(),
      ...independentlyStaleDeviceEntries.map(({ uid, data }) => [
        uid,
        data,
      ] as const),
    ]);
    const staleDeviceUpdatedAts = new Map(
      [...allDeviceEntries.entries()].flatMap(([uid, deviceData]) =>
        staleDeviceUids.has(uid) && deviceData?.updatedAt instanceof Timestamp
            ? [[uid, deviceData.updatedAt] as const]
            : [],
      ),
    );
    const malformedDeviceUids = new Set(deviceTimestampRoutes.malformedUids);

    // --- Build send list, collecting stale UIDs for deferred cleanup ---

    const staleUids = [...staleDeviceUids];
    const sendTasks: Array<() => Promise<ScheduledDeliveryResult>> = [];

    for (const { doc, candidate } of scheduledCandidates) {
      const { uid, typeId, locale, gender } = doc.data();
      if (
        !isValidNotificationUid(uid) ||
        !isValidNotificationTypeId(typeId) ||
        !isValidNotificationLocale(locale)
      ) {
        continue;
      }

      const deviceData = deviceMap.get(uid);

      if (staleDeviceUids.has(uid)) {
        continue;
      }
      if (malformedDeviceUids.has(uid)) {
        logger.warn("Skipping device with malformed updatedAt", { uid });
        continue;
      }
      if (!deliveryEligibleUids.has(uid)) continue;

      const fcmToken = deviceData?.fcmToken;
      if (!hasValidFCMToken(fcmToken)) continue;

      const typeData = typeDataMap.get(typeId);
      if (!hasValidNotificationTypeSchema(typeData)) continue;

      let title = "Living Positively";
      let body: string;

      if (typeData.messageType === "dynamic") {
        const collectionName =
          typeData.quotesCollections[locale] ??
          typeData.quotesCollections["he"];
        if (typeof collectionName !== "string" || collectionName.length === 0) {
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
          (candidate): candidate is string => typeof candidate === "string",
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
      const deliveryRef = db
        .collection("notification_deliveries")
        .doc(deliveryKey);
      const stateRef = notificationMutationStateRef(db, uid, typeId);
      const selectedSchedule = doc.data();
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
            create: (data) =>
              db.runTransaction(async (transaction) => {
                const [currentSchedule, currentState] = await Promise.all([
                  transaction.get(doc.ref),
                  transaction.get(stateRef),
                ]);
                if (
                  !isCurrentScheduledNotification(
                    selectedSchedule,
                    currentSchedule.exists ? currentSchedule.data() : undefined,
                    currentState.exists ? currentState.data() : undefined,
                  ) ||
                  hasActiveDeliveryPermit(currentState.data())
                ) {
                  return "notCurrent";
                }
                transaction.create(deliveryRef, data);
                transaction.set(
                  stateRef,
                  {
                    deliveryPermitKey: deliveryKey,
                    deliveryPermitExpiresAtMillis:
                      Timestamp.now().toMillis() +
                      DELIVERY_PERMIT_DURATION_MILLIS,
                  },
                  { merge: true },
                );
                return undefined;
              }),
            update: (data) => deliveryRef.update(data),
            releasePermit: () =>
              db.runTransaction(async (transaction) => {
                const state = await transaction.get(stateRef);
                if (state.data()?.deliveryPermitKey !== deliveryKey) return;

                if (state.data()?.version === undefined) {
                  transaction.delete(stateRef);
                  return;
                }
                transaction.set(
                  stateRef,
                  {
                    deliveryPermitKey: FieldValue.delete(),
                    deliveryPermitExpiresAtMillis: FieldValue.delete(),
                  },
                  { merge: true },
                );
              }),
          },
          async (message) => {
            try {
              return await getMessaging().send(message);
            } catch (error: unknown) {
              if (
                failureCode(error) ===
                "messaging/registration-token-not-registered"
              ) {
                await clearFCMToken(uid, fcmToken);
              }
              throw error;
            }
          },
        ),
      );
    }

    // --- Send phase (batched parallel) ---

    const results: PromiseSettledResult<ScheduledDeliveryResult>[] = [];
    for (
      let start = 0;
      start < sendTasks.length;
      start += DELIVERY_SEND_BATCH_SIZE
    ) {
      results.push(
        ...(await Promise.allSettled(
          sendTasks
            .slice(start, start + DELIVERY_SEND_BATCH_SIZE)
            .map((task) => task()),
        )),
      );
    }
    let successCount = 0;
    let failureCount = 0;
    let alreadyClaimedCount = 0;
    let notCurrentCount = 0;
    let claimFailedCount = 0;
    for (const r of results) {
      if (r.status === "fulfilled" && r.value === "sent") successCount++;
      else if (r.status === "fulfilled" && r.value === "alreadyClaimed") {
        alreadyClaimedCount++;
      } else if (r.status === "fulfilled" && r.value === "notCurrent") {
        notCurrentCount++;
      } else if (r.status === "fulfilled" && r.value === "claimFailed") {
        claimFailedCount++;
        failureCount++;
      } else failureCount++;
    }

    // Complete the delivery checkpoint before independent stale-device cleanup.
    if (shouldAdvanceSchedulerCheckpoint(claimFailedCount)) {
      if (recoveryPageHasMore) {
        const cursorDocumentId = pageDocs[pageDocs.length - 1]?.id;
        if (cursorDocumentId === undefined) {
          throw new Error("Recovery page did not contain a cursor document");
        }
        await advanceSchedulerRecoveryCursor(cursorDocumentId);
      } else {
        await advanceSchedulerCheckpoint();
      }
    }

    // --- Stale device cleanup (batched, after the delivery checkpoint) ---

    const {
      cleanupUids: staleUidsToClean,
      deferredCount: staleCleanupDeferredByBatch,
    } = staleDeviceCleanupBatch(
      staleUids,
      independentlyStaleDeviceCount,
    );
    const staleCleanupResults:
      PromiseSettledResult<StaleDeviceCleanupOutcome>[] = [];
    for (
      let start = 0;
      start < staleUidsToClean.length;
      start += STALE_DEVICE_CLEANUP_BATCH_SIZE
    ) {
      staleCleanupResults.push(
        ...(await Promise.allSettled(
          staleUidsToClean
              .slice(start, start + STALE_DEVICE_CLEANUP_BATCH_SIZE)
              .map((uid) => {
                const updatedAt = staleDeviceUpdatedAts.get(uid);
                return updatedAt === undefined
                    ? Promise.resolve<StaleDeviceCleanupOutcome>("skipped")
                    : cleanupInactiveDevice(uid, updatedAt);
              }),
        )),
      );
    }
    const staleDevicesCleaned = staleCleanupResults.filter(
      (result) => result.status === "fulfilled" && result.value === "cleaned",
    ).length;
    const staleCleanupFailedCount = staleCleanupResults.filter(
      (result) => result.status === "rejected",
    ).length;
    const staleCleanupDeferred =
      staleCleanupDeferredByBatch +
      staleCleanupResults.filter(
        (result) =>
          result.status === "fulfilled" && result.value === "deferred",
      ).length;

    logger.info(
      "processScheduledNotifications",
      scheduledNotificationSummary(
        {
          sent: successCount,
          failed: failureCount,
          alreadyClaimed: alreadyClaimedCount,
          notCurrent: notCurrentCount,
          claimFailed: claimFailedCount,
          staleDevicesCleaned,
          staleCleanupFailed: staleCleanupFailedCount,
          staleCleanupDeferred,
        },
        recoveryWindow,
      ),
    );
  },
);
