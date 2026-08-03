import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  hasActiveDeliveryPermit,
  hasValidNotificationTypeSchema,
  isValidNotificationTypeId,
  notificationMutationStatePath,
  notificationMutationDecision,
  normalizeNotificationGender,
  parseExpectedNotificationMutationVersion,
} from "./index.js";

describe("notification validation", () => {
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
        quotesCollections: { en: "quotes_en" },
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

  it("rejects a stale notification mutation version", () => {
    assert.equal(
      notificationMutationDecision(
        { kind: "versioned", version: 0 },
        1,
      ),
      "stale",
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
