import assert from "node:assert/strict";
import { once } from "node:events";
import { createServer } from "node:http";
import { describe, it } from "node:test";

import {
  cancelNotification,
  getNotificationMutationVersion,
  registerNotification,
} from "./index.js";

type HttpFunction = typeof getNotificationMutationVersion;

async function preflight(functionHandler: HttpFunction): Promise<Response> {
  const server = createServer((request, response) => {
    void functionHandler(
      request as Parameters<HttpFunction>[0],
      response as Parameters<HttpFunction>[1],
    );
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const address = server.address();
  if (address === null || typeof address === "string") {
    throw new Error("Expected the CORS test server to use a TCP port.");
  }
  const port = address.port;

  try {
    return await fetch(`http://127.0.0.1:${port}`, {
      method: "OPTIONS",
      headers: {
        Origin: "https://living-positively.example",
        "Access-Control-Request-Method": "POST",
        "Access-Control-Request-Headers": "authorization,content-type",
      },
    });
  } finally {
    server.close();
    await once(server, "close");
  }
}

describe("notification mutation HTTP CORS", () => {
  for (const [name, functionHandler] of [
    ["getNotificationMutationVersion", getNotificationMutationVersion],
    ["registerNotification", registerNotification],
    ["cancelNotification", cancelNotification],
  ] as const) {
    it(`allows browser preflight for ${name}`, async () => {
      const response = await preflight(functionHandler);

      assert.equal(response.status, 204);
      assert.equal(
        response.headers.get("access-control-allow-origin"),
        "https://living-positively.example",
      );
      assert.match(
        response.headers.get("access-control-allow-headers") ?? "",
        /authorization/i,
      );
      assert.match(
        response.headers.get("access-control-allow-headers") ?? "",
        /content-type/i,
      );
      assert.match(
        response.headers.get("access-control-allow-methods") ?? "",
        /post/i,
      );
    });
  }
});
