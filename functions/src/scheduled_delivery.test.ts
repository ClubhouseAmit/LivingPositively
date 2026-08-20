import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { Timestamp } from "firebase-admin/firestore";

import {
  buildNotificationDeliveryKey,
  claimAndSendScheduledDelivery,
  classifyDeviceUpdatedAt,
  israelLocalDeliveryCandidates,
  israelLocalDeliveryCandidatesSince,
  isCurrentScheduledNotification,
  routeDevicesByUpdatedAt,
  scheduledNotificationQueryPlan,
  selectScheduledNotificationCandidates,
  staleDeviceCleanupBatch,
  staleDeviceScheduleCleanupPlan,
  shouldClearFCMToken,
  shouldAdvanceSchedulerCheckpoint,
} from "./index.js";
import {
  schedulerRecoveryWindow,
  scheduledNotificationSummary,
} from "./scheduler_observability.js";

describe("scheduled notification delivery", () => {
  it("clears an invalid FCM token only when it is still current", () => {
    assert.equal(shouldClearFCMToken("old-token", "old-token"), true);
    assert.equal(shouldClearFCMToken("new-token", "old-token"), false);
    assert.equal(shouldClearFCMToken(undefined, "old-token"), false);
  });

  it("bounds stale-device cleanup and reports the deferred backlog", () => {
    const uids = [
      "stale-0",
      "stale-0",
      ...Array.from({ length: 26 }, (_, index) => `stale-${index + 1}`),
    ];

    assert.deepEqual(staleDeviceCleanupBatch(uids), {
      cleanupUids: Array.from({ length: 25 }, (_, index) => `stale-${index}`),
      deferredCount: 2,
    });
  });

  it("deletes a device when its schedules fit exactly in the cleanup batch", () => {
    assert.deepEqual(staleDeviceScheduleCleanupPlan(25), {
      scheduleDeletes: 25,
      deleteDevice: true,
    });
    assert.deepEqual(staleDeviceScheduleCleanupPlan(26), {
      scheduleDeletes: 25,
      deleteDevice: false,
    });
  });

  describe("device timestamp validation", () => {
    const nowMillis = Date.parse("2026-08-05T12:00:00.000Z");

    it("accepts a fresh Firestore timestamp without calling toMillis", () => {
      let toMillisCalls = 0;
      const freshMillis = nowMillis - 30 * 86_400_000;
      const updatedAt = Timestamp.fromMillis(freshMillis);
      Object.defineProperty(updatedAt, "toMillis", {
        value() {
          toMillisCalls++;
          throw new Error("client method must not execute");
        },
      });

      assert.equal(
        classifyDeviceUpdatedAt(updatedAt, nowMillis),
        "fresh",
      );
      assert.equal(toMillisCalls, 0);
    });

    it("classifies a device timestamp older than 180 days as stale", () => {
      const staleMillis = nowMillis - 181 * 86_400_000;

      assert.equal(
        classifyDeviceUpdatedAt(
          Timestamp.fromMillis(staleMillis),
          nowMillis,
        ),
        "stale",
      );
    });

    it("preserves legacy devices that have no updatedAt field", () => {
      assert.equal(classifyDeviceUpdatedAt(undefined, nowMillis), "missing");
    });

    it("rejects a plain timestamp-shaped map", () => {
      assert.equal(
        classifyDeviceUpdatedAt(
          {
            seconds: Math.floor(nowMillis / 1_000),
            nanoseconds: 0,
          },
          nowMillis,
        ),
        "malformed",
      );
    });

    it("rejects a real Timestamp beyond the allowed future clock skew", () => {
      assert.equal(
        classifyDeviceUpdatedAt(
          Timestamp.fromMillis(nowMillis + 6 * 60_000),
          nowMillis,
        ),
        "malformed",
      );
    });

    it("rejects a malformed updatedAt value without affecting later devices", () => {
      const deviceValues = [
        { seconds: 1, nanoseconds: "not-a-number" },
        Timestamp.fromMillis(nowMillis),
      ];

      assert.deepEqual(
        deviceValues.map((value) => classifyDeviceUpdatedAt(value, nowMillis)),
        ["malformed", "fresh"],
      );
    });

    it("never invokes a hostile client-supplied toMillis method", () => {
      const hostileTimestamp = {
        toMillis() {
          throw new Error("hostile toMillis invoked");
        },
      };

      assert.doesNotThrow(() =>
        classifyDeviceUpdatedAt(hostileTimestamp, nowMillis),
      );
      assert.equal(
        classifyDeviceUpdatedAt(hostileTimestamp, nowMillis),
        "malformed",
      );
    });

    it("skips one malformed device while routing a later valid device", () => {
      let hostileToMillisCalls = 0;
      const staleMillis = nowMillis - 181 * 86_400_000;

      const routes = routeDevicesByUpdatedAt(
        [
          {
            uid: "malformed-device",
            updatedAt: {
              toMillis() {
                hostileToMillisCalls++;
                throw new Error("client method must not execute");
              },
            },
          },
          {
            uid: "stale-device",
            updatedAt: Timestamp.fromMillis(staleMillis),
          },
          {
            uid: "eligible-device",
            updatedAt: Timestamp.fromMillis(nowMillis),
          },
        ],
        nowMillis,
      );

      assert.deepEqual(routes, {
        deliveryEligibleUids: ["eligible-device"],
        staleUids: ["stale-device"],
        malformedUids: ["malformed-device"],
      });
      assert.equal(hostileToMillisCalls, 0);
    });
  });

  it("builds a canonical delivery key from the local intended time", () => {
    assert.equal(
      buildNotificationDeliveryKey(
        "uid-123",
        "default",
        "2026-01-02",
        "00:59",
      ),
      "WyJ1aWQtMTIzIiwiZGVmYXVsdCIsIjIwMjYtMDEtMDIiLCIwMDo1OSJd",
    );
    assert.notEqual(
      buildNotificationDeliveryKey(
        "a_b",
        "c",
        "2026-01-02",
        "00:59",
      ),
      buildNotificationDeliveryKey(
        "a",
        "b_c",
        "2026-01-02",
        "00:59",
      ),
    );
  });

  it("builds rolling Israel-local candidates through the prior 120 minutes", () => {
    const candidates = israelLocalDeliveryCandidates(
      new Date("2026-01-01T20:59:00.000Z"),
    );

    assert.equal(candidates.length, 121);
    assert.deepEqual(candidates[0], {
      localDate: "2026-01-01",
      intendedTime: "22:59",
      hour: 22,
      minute: 59,
      intendedAt: new Date("2026-01-01T20:59:00.000Z"),
    });
    assert.deepEqual(candidates[candidates.length - 1], {
      localDate: "2026-01-01",
      intendedTime: "20:59",
      hour: 20,
      minute: 59,
      intendedAt: new Date("2026-01-01T18:59:00.000Z"),
    });
  });

  it("uses only the elapsed interval when a scheduler checkpoint exists", () => {
    const scheduleTime = new Date("2026-01-01T20:59:00.000Z");

    const candidates = israelLocalDeliveryCandidatesSince(
      scheduleTime,
      new Date("2026-01-01T20:58:00.000Z"),
    );

    assert.equal(candidates.length, 1);
    assert.equal(candidates[0].intendedTime, "22:59");
  });

  it("uses one candidate when no scheduler checkpoint exists", () => {
    const now = new Date("2026-01-01T20:59:00.000Z");

    assert.equal(israelLocalDeliveryCandidatesSince(now, undefined).length, 1);
  });

  it("caps a stale scheduler checkpoint at 121 candidate minutes", () => {
    const now = new Date("2026-01-01T20:59:00.000Z");
    const fourHoursAgo = new Date("2026-01-01T16:59:00.000Z");

    assert.equal(
      israelLocalDeliveryCandidatesSince(now, fourHoursAgo).length,
      121,
    );
  });

  it("reports when a stale scheduler checkpoint is clamped", () => {
    assert.deepEqual(
      schedulerRecoveryWindow(
        new Date("2026-01-01T20:59:00.000Z"),
        new Date("2026-01-01T16:59:00.000Z"),
      ),
      {
        requestedCandidateMinutes: 240,
        processedCandidateMinutes: 121,
        wasClamped: true,
      },
    );
  });

  it("keeps scheduler summary recovery and claim failure metrics structured", () => {
    const summary = JSON.parse(JSON.stringify(scheduledNotificationSummary(
      {
        sent: 3,
        failed: 2,
        alreadyClaimed: 4,
        notCurrent: 5,
        claimFailed: 2,
        staleDevicesCleaned: 6,
        staleCleanupFailed: 7,
        staleCleanupDeferred: 8,
      },
      {
        requestedCandidateMinutes: 240,
        processedCandidateMinutes: 121,
        wasClamped: true,
      },
    )));

    assert.equal(summary.claimFailed, 2);
    assert.equal(typeof summary.claimFailed, "number");
    assert.equal(summary.recoveryCandidateMinutes, 121);
    assert.equal(typeof summary.recoveryCandidateMinutes, "number");
    assert.equal(summary.requestedRecoveryCandidateMinutes, 240);
    assert.equal(typeof summary.requestedRecoveryCandidateMinutes, "number");
    assert.equal(summary.recoveryClamped, true);
    assert.equal(typeof summary.recoveryClamped, "boolean");
    assert.equal(summary.staleCleanupDeferred, 8);
    assert.equal(typeof summary.staleCleanupDeferred, "number");
  });

  it("uses an exact schedule query for the normal one-minute interval", () => {
    assert.deepEqual(
      scheduledNotificationQueryPlan([
        {
          localDate: "2026-01-01",
          intendedTime: "22:59",
          hour: 22,
          minute: 59,
          intendedAt: new Date("2026-01-01T20:59:00.000Z"),
        },
      ]),
      { kind: "exact", hour: 22, minute: 59 },
    );
  });

  it("uses an hour-in query plan for recovery candidates", () => {
    const twoCandidates = [
      {
        localDate: "2026-01-01",
        intendedTime: "22:59",
        hour: 22,
        minute: 59,
        intendedAt: new Date("2026-01-01T20:59:00.000Z"),
      },
      {
        localDate: "2026-01-01",
        intendedTime: "21:59",
        hour: 21,
        minute: 59,
        intendedAt: new Date("2026-01-01T19:59:00.000Z"),
      },
    ];

    assert.deepEqual(scheduledNotificationQueryPlan(twoCandidates), {
      kind: "catchUp",
      hours: [22, 21],
    });
  });

  it("holds the checkpoint when a delivery claim fails", () => {
    assert.equal(shouldAdvanceSchedulerCheckpoint(1), false);
    assert.equal(shouldAdvanceSchedulerCheckpoint(0), true);
  });

  it("rejects a schedule query plan with no delivery candidates", () => {
    assert.throws(
      () => scheduledNotificationQueryPlan([]),
      /at least one delivery candidate/,
    );
  });

  it("skips the non-existent Israel-local hour on spring-forward", () => {
    const candidates = israelLocalDeliveryCandidates(
      new Date("2026-03-27T00:30:00.000Z"),
    );

    assert.equal(
      candidates.some(
        (candidate) =>
          candidate.localDate === "2026-03-27" &&
          candidate.intendedTime === "02:30",
      ),
      false,
    );
  });

  it("does not deliver a candidate that predates a schedule edit", () => {
    const candidates = israelLocalDeliveryCandidates(
      new Date("2026-01-01T08:01:00.000Z"),
    );
    const scheduled = selectScheduledNotificationCandidates(
      [
        {
          data: () => ({
            hour: 9,
            minute: 0,
            updatedAt: { toMillis: () => new Date("2026-01-01T07:00:30.000Z").getTime() },
          }),
        },
      ],
      candidates,
    );

    assert.deepEqual(scheduled, []);
  });

  it("keeps a candidate that follows the schedule edit", () => {
    const candidates = israelLocalDeliveryCandidates(
      new Date("2026-01-01T08:01:00.000Z"),
    );
    const scheduled = selectScheduledNotificationCandidates(
      [
        {
          data: () => ({
            hour: 9,
            minute: 0,
            updatedAt: { toMillis: () => new Date("2026-01-01T06:59:30.000Z").getTime() },
          }),
        },
      ],
      candidates,
    );

    assert.equal(scheduled.length, 1);
    assert.equal(scheduled[0].candidate.intendedTime, "09:00");
  });

  it("claims a delivery before sending and records the FCM message id", async () => {
    const created: Array<Record<string, unknown>> = [];
    const updated: Array<Record<string, unknown>> = [];
    const messages: Array<Record<string, unknown>> = [];

    const result = await claimAndSendScheduledDelivery(
      {
        uid: "uid-123",
        typeId: "default",
        localDate: "2026-01-02",
        intendedTime: "00:59",
        intendedAt: new Date("2026-01-01T22:59:00.000Z"),
        message: {
          token: "latest-token",
          notification: { title: "Title", body: "Body" },
          data: {
            deliveryKey:
                "WyJ1aWQtMTIzIiwiZGVmYXVsdCIsIjIwMjYtMDEtMDIiLCIwMDo1OSJd",
          },
        },
      },
      {
        async create(data: Record<string, unknown>) {
          created.push(data);
        },
        async update(data: Record<string, unknown>) {
          updated.push(data);
        },
      },
      async (message: Record<string, unknown>) => {
        assert.equal(created.length, 1);
        assert.equal(created[0].status, "claimed");
        messages.push(message);
        return "fcm-message-id";
      },
    );

    assert.equal(result, "sent");
    assert.deepEqual(messages, [
      {
        token: "latest-token",
        notification: { title: "Title", body: "Body" },
        data: {
          deliveryKey:
              "WyJ1aWQtMTIzIiwiZGVmYXVsdCIsIjIwMjYtMDEtMDIiLCIwMDo1OSJd",
        },
      },
    ]);
    assert.equal(created.length, 1);
    assert.deepEqual(
      {
        deliveryKey: created[0].deliveryKey,
        uid: created[0].uid,
        typeId: created[0].typeId,
        localDate: created[0].localDate,
        intendedTime: created[0].intendedTime,
        status: created[0].status,
        expiresAt: created[0].expiresAt,
      },
      {
        deliveryKey:
            "WyJ1aWQtMTIzIiwiZGVmYXVsdCIsIjIwMjYtMDEtMDIiLCIwMDo1OSJd",
        uid: "uid-123",
        typeId: "default",
        localDate: "2026-01-02",
        intendedTime: "00:59",
        status: "claimed",
        expiresAt: new Date("2026-01-02T22:59:00.000Z"),
      },
    );
    assert.ok(created[0].claimedAt instanceof Date);
    assert.ok(created[0].attemptStartedAt instanceof Date);
    assert.equal(updated.length, 1);
    assert.equal(updated[0].status, "sent");
    assert.equal(updated[0].messageId, "fcm-message-id");
    assert.ok(updated[0].attemptFinishedAt instanceof Date);
  });

  it("does not send when the schedule is no longer current at claim time", async () => {
    let sendCalls = 0;
    const updates: Array<Record<string, unknown>> = [];

    const result = await claimAndSendScheduledDelivery(
      {
        uid: "uid-123",
        typeId: "default",
        localDate: "2026-01-02",
        intendedTime: "00:59",
        intendedAt: new Date("2026-01-01T22:59:00.000Z"),
        message: {
          token: "latest-token",
          notification: { title: "Title", body: "Body" },
          data: { deliveryKey: "key" },
        },
      },
      {
        async create(_data: Record<string, unknown>) {
          return "notCurrent";
        },
        async update(data: Record<string, unknown>) {
          updates.push(data);
        },
      },
      async () => {
        sendCalls++;
        return "fcm-message-id";
      },
    );

    assert.equal(result, "notCurrent");
    assert.equal(sendCalls, 0);
    assert.deepEqual(updates, []);
  });

  it("does not treat a changed legacy updatedAt timestamp as current", () => {
    assert.equal(
      isCurrentScheduledNotification(
        { updatedAt: { toMillis: () => 1_000 } },
        { updatedAt: { toMillis: () => 1_001 } },
        undefined,
      ),
      false,
    );
  });

  it("does not treat a legacy schedule without a usable selected timestamp as current", () => {
    assert.equal(
      isCurrentScheduledNotification(
        {},
        { updatedAt: { toMillis: () => 1_000 } },
        undefined,
      ),
      false,
    );
  });

  it("treats an unchanged legacy schedule as current after an expired unversioned permit", () => {
    const updatedAt = {
      seconds: 1_000,
      nanoseconds: 123_456_789,
      toMillis: () => 1_000_123,
    };

    assert.equal(
      isCurrentScheduledNotification(
        { updatedAt },
        {
          updatedAt: {
            seconds: 1_000,
            nanoseconds: 123_456_789,
            toMillis: () => 1_000_123,
          },
        },
        {
          deliveryPermitKey: "expired-delivery",
          deliveryPermitExpiresAtMillis: 0,
        },
      ),
      true,
    );
  });

  it("rejects legacy timestamps that differ below the millisecond", () => {
    assert.equal(
      isCurrentScheduledNotification(
        {
          updatedAt: {
            seconds: 1_000,
            nanoseconds: 123_456_001,
            toMillis: () => 1_000_123,
          },
        },
        {
          updatedAt: {
            seconds: 1_000,
            nanoseconds: 123_456_999,
            toMillis: () => 1_000_123,
          },
        },
        undefined,
      ),
      false,
    );
  });

  it("releases a claimed delivery permit after success or send failure but not no-current skip", async () => {
    const delivery = {
      uid: "uid-123",
      typeId: "default",
      localDate: "2026-01-02",
      intendedTime: "00:59",
      intendedAt: new Date("2026-01-01T22:59:00.000Z"),
      message: {
        token: "latest-token",
        notification: { title: "Title", body: "Body" },
        data: { deliveryKey: "key" },
      },
    };
    let successfulReleaseCount = 0;
    let failedReleaseCount = 0;
    let skippedReleaseCount = 0;
    let skippedSendCount = 0;

    assert.equal(
      await claimAndSendScheduledDelivery(
        delivery,
        {
          async create(_data: Record<string, unknown>) {},
          async update(_data: Record<string, unknown>) {},
          async releasePermit() {
            successfulReleaseCount++;
          },
        },
        async () => "fcm-message-id",
      ),
      "sent",
    );
    assert.equal(successfulReleaseCount, 1);

    assert.equal(
      await claimAndSendScheduledDelivery(
        delivery,
        {
          async create(_data: Record<string, unknown>) {},
          async update(_data: Record<string, unknown>) {},
          async releasePermit() {
            failedReleaseCount++;
          },
        },
        async () => {
          throw new Error("FCM unavailable");
        },
      ),
      "failed",
    );
    assert.equal(failedReleaseCount, 1);

    assert.equal(
      await claimAndSendScheduledDelivery(
        delivery,
        {
          async create(_data: Record<string, unknown>) {
            return "notCurrent";
          },
          async update(_data: Record<string, unknown>) {},
          async releasePermit() {
            skippedReleaseCount++;
          },
        },
        async () => {
          skippedSendCount++;
          return "fcm-message-id";
        },
      ),
      "notCurrent",
    );
    assert.equal(skippedReleaseCount, 0);
    assert.equal(skippedSendCount, 0);
  });

  it("does not retry an ambiguous failed send after the create claim", async () => {
    let claimed = false;
    let sendCalls = 0;
    const updates: Array<Record<string, unknown>> = [];
    const delivery = {
      uid: "uid-123",
      typeId: "default",
      localDate: "2026-01-02",
      intendedTime: "00:59",
      intendedAt: new Date("2026-01-01T22:59:00.000Z"),
      message: {
        token: "latest-token",
        notification: { title: "Title", body: "Body" },
        data: {
          deliveryKey:
              "WyJ1aWQtMTIzIiwiZGVmYXVsdCIsIjIwMjYtMDEtMDIiLCIwMDo1OSJd",
        },
      },
    };
    const writer = {
      async create(_data: Record<string, unknown>) {
        if (claimed) {
          const error = new Error("already exists") as Error & { code: number };
          error.code = 6;
          throw error;
        }
        claimed = true;
      },
      async update(data: Record<string, unknown>) {
        updates.push(data);
      },
    };
    const sender = async () => {
      sendCalls++;
      const error = new Error("ambiguous FCM failure") as Error & {
        errorInfo: { code: string };
      };
      error.errorInfo = { code: "messaging/internal-error" };
      throw error;
    };

    assert.equal(
      await claimAndSendScheduledDelivery(delivery, writer, sender),
      "failed",
    );
    assert.equal(
      await claimAndSendScheduledDelivery(delivery, writer, sender),
      "alreadyClaimed",
    );
    assert.equal(sendCalls, 1);
    assert.equal(updates.length, 1);
    assert.equal(updates[0].status, "failed");
    assert.equal(updates[0].failureCode, "messaging/internal-error");
  });

  it("distinguishes a claim-write failure from an already claimed delivery", async () => {
    const writer = {
      async create(_data: Record<string, unknown>) {
        throw new Error("Firestore unavailable");
      },
      async update(_data: Record<string, unknown>) {},
    };
    const delivery = {
      uid: "uid-123",
      typeId: "default",
      localDate: "2026-01-02",
      intendedTime: "00:59",
      intendedAt: new Date("2026-01-01T22:59:00.000Z"),
      message: {
        token: "latest-token",
        notification: { title: "Title", body: "Body" },
        data: { deliveryKey: "key" },
      },
    };

    assert.equal(
      await claimAndSendScheduledDelivery(delivery, writer, async () => "message-id"),
      "claimFailed",
    );
  });

  it("preserves the send result when recording its terminal status fails", async () => {
    const delivery = {
      uid: "uid-123",
      typeId: "default",
      localDate: "2026-01-02",
      intendedTime: "00:59",
      intendedAt: new Date("2026-01-01T22:59:00.000Z"),
      message: {
        token: "latest-token",
        notification: { title: "Title", body: "Body" },
        data: { deliveryKey: "key" },
      },
    };
    const writer = {
      async create(_data: Record<string, unknown>) {},
      async update(_data: Record<string, unknown>) {
        throw new Error("status write unavailable");
      },
    };

    assert.equal(
      await claimAndSendScheduledDelivery(delivery, writer, async () => "message-id"),
      "sent",
    );
  });
});
