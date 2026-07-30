import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  hasValidNotificationTypeSchema,
  isValidNotificationTypeId,
  normalizeNotificationGender,
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
});
