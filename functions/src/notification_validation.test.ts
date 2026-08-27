import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  hasValidNotificationTypeSchema,
  isValidNotificationLocale,
  isValidNotificationScheduleTime,
  isValidNotificationTypeId,
  isValidNotificationUid,
  normalizeNotificationGender,
} from "./notification_validation.js";
import {
  hasActiveDeliveryPermit,
  hasEffectiveNotificationMutationState,
  hasMatchingNotificationScheduleIdentity,
  isValidResetFenceMutation,
  executeNotificationMutation,
  notificationMutationAuthorizationDecision,
  notificationMutationDecision,
  notificationMutationStatePath,
  notificationScheduleId,
  parseExpectedNotificationMutationVersion,
  storedNotificationMutationVersionDecision,
} from "./notification_mutation.js";

describe("notification validation", () => {
  it("accepts only the supported persisted notification locales", () => {
    assert.equal(isValidNotificationLocale("he"), true);
    assert.equal(isValidNotificationLocale("ar"), true);
    assert.equal(isValidNotificationLocale("en"), true);
    assert.equal(isValidNotificationLocale("constructor"), false);
    assert.equal(isValidNotificationLocale("toString"), false);
    assert.equal(isValidNotificationLocale("__proto__"), false);
  });

  it("accepts identifier-safe type IDs and rejects Firestore paths", () => {
    assert.equal(isValidNotificationTypeId("default"), true);
    assert.equal(isValidNotificationTypeId("daily_quote-2"), true);
    assert.equal(isValidNotificationTypeId("../default"), false);
    assert.equal(isValidNotificationTypeId("folder/default"), false);
    assert.equal(isValidNotificationTypeId(""), false);
    assert.equal(isValidNotificationTypeId(42), false);
  });

  it("normalizes unknown genders to the documented fallback", () => {
    assert.equal(normalizeNotificationGender("male"), "male");
    assert.equal(normalizeNotificationGender("female"), "female");
    assert.equal(normalizeNotificationGender("other"), "other");
    assert.equal(normalizeNotificationGender("unexpected"), "other");
    assert.equal(normalizeNotificationGender(null), "other");
  });

  it("accepts only complete dynamic and static type schemas", () => {
    assert.equal(
      hasValidNotificationTypeSchema({
        messageType: "dynamic",
        quotesCollections: {
          he: "quotes_he",
          ar: "quotes_ar",
          en: "quotes_en",
        },
      }),
      true,
    );
    assert.equal(
      hasValidNotificationTypeSchema({
        messageType: "static",
        staticTitle: "Title",
        staticBody: "Body",
      }),
      true,
    );
    assert.equal(
      hasValidNotificationTypeSchema({ messageType: "dynamic" }),
      false,
    );
    assert.equal(
      hasValidNotificationTypeSchema({
        messageType: "dynamic",
        quotesCollections: {
          he: "private_documents",
          ar: "quotes_ar",
          en: "quotes_en",
        },
      }),
      false,
    );
    assert.equal(
      hasValidNotificationTypeSchema({
        messageType: "static",
        staticTitle: "Title",
      }),
      false,
    );
    assert.equal(
      hasValidNotificationTypeSchema({
        messageType: "typo",
        staticTitle: "Title",
        staticBody: "Body",
      }),
      false,
    );
  });

  it("parses only non-negative integer expected notification mutation versions", () => {
    assert.deepEqual(parseExpectedNotificationMutationVersion(undefined), {
      kind: "legacy",
    });
    assert.deepEqual(parseExpectedNotificationMutationVersion(0), {
      kind: "versioned",
      version: 0,
    });
    assert.deepEqual(parseExpectedNotificationMutationVersion(3), {
      kind: "versioned",
      version: 3,
    });
    assert.deepEqual(parseExpectedNotificationMutationVersion(-1), {
      kind: "invalid",
    });
    assert.deepEqual(parseExpectedNotificationMutationVersion(1.5), {
      kind: "invalid",
    });
    assert.deepEqual(parseExpectedNotificationMutationVersion("0"), {
      kind: "invalid",
    });
  });

  it("repairs corrupt stored versions for versioned mutations", () => {
    assert.deepEqual(
      storedNotificationMutationVersionDecision("corrupt"),
      { kind: "repair" },
    );
    assert.deepEqual(
      storedNotificationMutationVersionDecision(7),
      { kind: "use", version: 7 },
    );
  });

  it("accepts authenticated UIDs that are safe Firestore path segments", () => {
    assert.equal(isValidNotificationUid("uid-123"), true);
    assert.equal(isValidNotificationUid(""), false);
    assert.equal(isValidNotificationUid("."), false);
    assert.equal(isValidNotificationUid(".."), false);
    assert.equal(isValidNotificationUid("nested/uid"), false);
  });

  it("requires a reset fence before repairing a corrupt mutation", () => {
    assert.deepEqual(
      notificationMutationAuthorizationDecision({
        storedVersion: "corrupt",
        expectedVersion: { kind: "versioned", version: 0 },
        rejectActiveDeliveryPermit: false,
        allowsCorruptStateRepair: false,
        hasActiveDeliveryPermit: false,
        hasEffectiveState: false,
      }),
      {
        kind: "conflict",
        message: "Notification mutation state requires reset",
      },
    );
  });

  it("rejects Israel's nonexistent spring-forward hour", () => {
    assert.equal(isValidNotificationScheduleTime(1, 59), true);
    assert.equal(isValidNotificationScheduleTime(2, 0), false);
    assert.equal(isValidNotificationScheduleTime(2, 59), false);
    assert.equal(isValidNotificationScheduleTime(3, 0), true);
    assert.equal(isValidNotificationScheduleTime(24, 0), false);
  });

  it("lets the authenticated version-zero recovery re-enable a corrupt schedule", () => {
    assert.deepEqual(
      notificationMutationAuthorizationDecision({
        storedVersion: "corrupt",
        expectedVersion: { kind: "versioned", version: 0 },
        rejectActiveDeliveryPermit: false,
        allowsCorruptStateRepair: true,
        hasActiveDeliveryPermit: false,
        hasEffectiveState: false,
      }),
      { kind: "apply", nextVersion: 1 },
    );
  });

  it("lets an ordinary cancellation retire a schedule with an active permit", () => {
    assert.deepEqual(
      notificationMutationAuthorizationDecision({
        storedVersion: 4,
        expectedVersion: { kind: "versioned", version: 4 },
        rejectActiveDeliveryPermit: false,
        allowsCorruptStateRepair: false,
        hasActiveDeliveryPermit: true,
        hasEffectiveState: true,
      }),
      { kind: "apply", nextVersion: 5 },
    );
  });

  it("does not let a delivery fence repair corrupt mutation state", () => {
    assert.deepEqual(
      notificationMutationAuthorizationDecision({
        storedVersion: "corrupt",
        expectedVersion: { kind: "versioned", version: 0 },
        rejectActiveDeliveryPermit: true,
        allowsCorruptStateRepair: false,
        hasActiveDeliveryPermit: false,
        hasEffectiveState: false,
      }),
      {
        kind: "conflict",
        message: "Notification mutation state requires reset",
      },
    );
  });

  it("writes version one when a reset cancellation repairs a corrupt mutation", () => {
    assert.deepEqual(
      notificationMutationAuthorizationDecision({
        storedVersion: "corrupt",
        expectedVersion: { kind: "versioned", version: 0 },
        rejectActiveDeliveryPermit: true,
        allowsCorruptStateRepair: true,
        hasActiveDeliveryPermit: false,
        hasEffectiveState: false,
      }),
      { kind: "apply", nextVersion: 1 },
    );
  });

  it("blocks corrupt-state reset repair while a delivery permit is active", () => {
    assert.deepEqual(
      notificationMutationAuthorizationDecision({
        storedVersion: "corrupt",
        expectedVersion: { kind: "versioned", version: 0 },
        rejectActiveDeliveryPermit: true,
        allowsCorruptStateRepair: true,
        hasActiveDeliveryPermit: true,
        hasEffectiveState: true,
      }),
      { kind: "conflict", message: "Scheduled delivery is already authorized" },
    );
  });

  it("does not mutate a corrupt state without a reset fence", async () => {
    const writes: Array<{
      kind: "set" | "delete";
      reference: "state" | "schedule";
      data?: Record<string, unknown>;
    }> = [];
    const transaction = {
      get: async () => ({ data: () => ({ version: "corrupt" }) }),
      set: (
        reference: "state" | "schedule",
        data: Record<string, unknown>,
      ) => {
        writes.push({ kind: "set", reference, data });
      },
      delete: (reference: "state" | "schedule") => {
        writes.push({ kind: "delete", reference });
      },
    };

    assert.deepEqual(
      await executeNotificationMutation(transaction, {
        stateRef: "state",
        scheduleRef: "schedule",
        expectedVersion: { kind: "versioned", version: 0 },
        rejectActiveDeliveryPermit: false,
        allowsCorruptStateRepair: false,
        operation: { kind: "cancel" },
      }),
      {
        kind: "conflict",
        message: "Notification mutation state requires reset",
      },
    );
    assert.deepEqual(writes, []);
  });

  it("deletes the schedule and writes version one for a corrupt reset", async () => {
    const writes: Array<{
      kind: "set" | "delete";
      reference: "state" | "schedule";
      data?: Record<string, unknown>;
    }> = [];
    const transaction = {
      get: async () => ({ data: () => ({ version: "corrupt" }) }),
      set: (
        reference: "state" | "schedule",
        data: Record<string, unknown>,
      ) => {
        writes.push({ kind: "set", reference, data });
      },
      delete: (reference: "state" | "schedule") => {
        writes.push({ kind: "delete", reference });
      },
    };

    assert.deepEqual(
      await executeNotificationMutation(transaction, {
        stateRef: "state",
        scheduleRef: "schedule",
        expectedVersion: { kind: "versioned", version: 0 },
        rejectActiveDeliveryPermit: true,
        allowsCorruptStateRepair: true,
        operation: { kind: "cancel" },
      }),
      { kind: "apply", nextVersion: 1 },
    );
    assert.deepEqual(writes, [
      { kind: "delete", reference: "schedule" },
      { kind: "set", reference: "state", data: { version: 1 } },
    ]);
  });

  it("writes version one to the state and schedule for a versioned registration", async () => {
    const writes: Array<{
      kind: "set" | "delete";
      reference: "state" | "schedule";
      data?: Record<string, unknown>;
    }> = [];
    const transaction = {
      get: async () => ({ data: () => undefined }),
      set: (
        reference: "state" | "schedule",
        data: Record<string, unknown>,
      ) => {
        writes.push({ kind: "set", reference, data });
      },
      delete: (reference: "state" | "schedule") => {
        writes.push({ kind: "delete", reference });
      },
    };

    assert.deepEqual(
      await executeNotificationMutation(transaction, {
        stateRef: "state",
        scheduleRef: "schedule",
        expectedVersion: { kind: "versioned", version: 0 },
        rejectActiveDeliveryPermit: false,
        allowsCorruptStateRepair: false,
        operation: {
          kind: "register",
          scheduleData: { uid: "uid", typeId: "default" },
        },
      }),
      { kind: "apply", nextVersion: 1 },
    );
    assert.deepEqual(writes, [
      { kind: "set", reference: "state", data: { version: 1 } },
      {
        kind: "set",
        reference: "schedule",
        data: { uid: "uid", typeId: "default", mutationVersion: 1 },
      },
    ]);
  });

  it("does not repair a corrupt reset while a delivery permit is active", async () => {
    const writes: Array<{
      kind: "set" | "delete";
      reference: "state" | "schedule";
      data?: Record<string, unknown>;
    }> = [];
    const transaction = {
      get: async () => ({
        data: () => ({
          version: "corrupt",
          deliveryPermitKey: "delivery-key",
          deliveryPermitExpiresAtMillis: Date.now() + 1_000,
        }),
      }),
      set: (
        reference: "state" | "schedule",
        data: Record<string, unknown>,
      ) => {
        writes.push({ kind: "set", reference, data });
      },
      delete: (reference: "state" | "schedule") => {
        writes.push({ kind: "delete", reference });
      },
    };

    assert.deepEqual(
      await executeNotificationMutation(transaction, {
        stateRef: "state",
        scheduleRef: "schedule",
        expectedVersion: { kind: "versioned", version: 0 },
        rejectActiveDeliveryPermit: true,
        allowsCorruptStateRepair: true,
        operation: { kind: "cancel" },
      }),
      { kind: "conflict", message: "Scheduled delivery is already authorized" },
    );
    assert.deepEqual(writes, []);
  });

  it("rejects a stale notification mutation version", () => {
    assert.equal(
      notificationMutationDecision(
        { kind: "versioned", version: 0 },
        1,
      ),
      "stale",
    );
  });

  it("rejects a mutation version that cannot be incremented safely", () => {
    assert.equal(
      notificationMutationDecision(
        { kind: "versioned", version: Number.MAX_SAFE_INTEGER },
        Number.MAX_SAFE_INTEGER,
      ),
      "overflow",
    );
  });

  it("blocks an unfenced notification mutation after an account is fenced", () => {
    assert.equal(
      notificationMutationDecision({ kind: "legacy" }, undefined),
      "apply",
    );
    assert.equal(
      notificationMutationDecision({ kind: "legacy" }, 0),
      "legacyBlocked",
    );
  });

  it("requires a versioned mutation request for a reset fence", () => {
    assert.equal(
      isValidResetFenceMutation(true, { kind: "legacy" }),
      false,
    );
    assert.equal(
      isValidResetFenceMutation(true, { kind: "versioned", version: 0 }),
      true,
    );
    assert.equal(
      isValidResetFenceMutation(false, { kind: "legacy" }),
      true,
    );
  });

  it("does not retain a legacy mutation fence after an unversioned permit expires", () => {
    const expiredPermit = {
      deliveryPermitKey: "delivery-key",
      deliveryPermitExpiresAtMillis: 1_000,
    };

    assert.equal(
      notificationMutationDecision(
        { kind: "legacy" },
        undefined,
        hasEffectiveNotificationMutationState(expiredPermit, 1_000),
      ),
      "apply",
    );
    assert.equal(
      notificationMutationDecision(
        { kind: "legacy" },
        undefined,
        hasEffectiveNotificationMutationState(expiredPermit, 999),
      ),
      "legacyBlocked",
    );
  });

  it("uses nested state paths that distinguish underscore-containing UID and type pairs", () => {
    assert.equal(
      notificationMutationStatePath("a_b", "c"),
      "notification_mutation_state/a_b/types/c",
    );
    assert.equal(
      notificationMutationStatePath("a", "b_c"),
      "notification_mutation_state/a/types/b_c",
    );
    assert.notEqual(
      notificationMutationStatePath("a_b", "c"),
      notificationMutationStatePath("a", "b_c"),
    );
    assert.throws(
      () => notificationMutationStatePath("nested/uid", "default"),
      /cannot contain a slash/,
    );
  });

  it("uses unambiguous schedule IDs and only retires matching legacy schedules", () => {
    assert.notEqual(
      notificationScheduleId("a_b", "c"),
      notificationScheduleId("a", "b_c"),
    );
    assert.equal(
      hasMatchingNotificationScheduleIdentity(
        { uid: "a_b", typeId: "c" },
        "a_b",
        "c",
      ),
      true,
    );
    assert.equal(
      hasMatchingNotificationScheduleIdentity(
        { uid: "a_b", typeId: "c" },
        "a",
        "b_c",
      ),
      false,
    );
  });

  it("treats only an unexpired matching delivery permit as active", () => {
    assert.equal(
      hasActiveDeliveryPermit(
        {
          deliveryPermitKey: "delivery-key",
          deliveryPermitExpiresAtMillis: 1_001,
        },
        1_000,
      ),
      true,
    );
    assert.equal(
      hasActiveDeliveryPermit(
        {
          deliveryPermitKey: "delivery-key",
          deliveryPermitExpiresAtMillis: 1_000,
        },
        1_000,
      ),
      false,
    );
  });
});
