import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { notificationClientCors } from "./index.js";

describe("notification mutation HTTP CORS", () => {
  it("allows only an explicit HTTPS browser origin", () => {
    assert.equal(
      notificationClientCors("https://living-positively.example"),
      "https://living-positively.example",
    );
    assert.equal(notificationClientCors("https://living-positively.example/"), false);
  });

  for (const origin of [undefined, "", "http://localhost:3000", "not a URL"]) {
    it(`rejects ${String(origin)}`, () => {
      assert.equal(notificationClientCors(origin), false);
    });
  }
});
