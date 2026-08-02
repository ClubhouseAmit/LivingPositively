import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  buildNotificationDeliveryKey,
  claimAndSendScheduledDelivery,
  israelLocalDeliveryCandidates,
  israelLocalDeliveryCandidatesSince,
  scheduledNotificationQueryPlan,
  selectScheduledNotificationCandidates,
} from "./index.js";

describe("scheduled notification delivery", () => {
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
