import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  buildNotificationSeed,
  parseArbSource,
  parseGenderSelect,
  parseProvisionProjectId,
  provisionNotificationContent,
  SeedDocument,
} from "./notification_provisioning.js";

describe("notification content provisioning", () => {
  it("extracts every gender variant from an inspirational quote", () => {
    assert.deepEqual(
      parseGenderSelect(
        "{gender,select,male{He is ready} female{She is ready} other{They are ready}}",
      ),
      {
        male: "He is ready",
        female: "She is ready",
        other: "They are ready",
      },
    );
  });

  it("rejects a gender select without its outer closing brace", () => {
    assert.throws(
      () =>
        parseGenderSelect(
          "{gender,select,male{He is ready} female{She is ready} other{They are ready}",
        ),
      /outer closing brace/,
    );
  });

  it("requires an explicit valid Firebase project ID", () => {
    assert.equal(
      parseProvisionProjectId(["--project", "mezilondb"]),
      "mezilondb",
    );
    assert.throws(
      () => parseProvisionProjectId([]),
      /--project <firebase-project-id>/,
    );
    assert.throws(
      () => parseProvisionProjectId(["--project", "INVALID_PROJECT"]),
      /Invalid Firebase project ID/,
    );
  });

  it("allows duplicate quote keys with identical decoded values", () => {
    const source = String.raw`{
      "inspirationalQuotesNo0": "{gender,select,male{same} female{same} other{same}}",
      "inspirationalQuotesNo0": "{gender,select,male{s\u0061me} female{same} other{same}}"
    }`;

    assert.deepEqual(parseArbSource(source), {
      inspirationalQuotesNo0:
        "{gender,select,male{same} female{same} other{same}}",
    });
  });

  it("rejects conflicting duplicate quote keys and names the key", () => {
    const source = `{
      "inspirationalQuotesNo7": "{gender,select,male{first} female{first} other{first}}",
      "inspirationalQuotesNo7": "{gender,select,male{second} female{second} other{second}}"
    }`;

    assert.throws(
      () => parseArbSource(source),
      /Conflicting duplicate inspirational quote key: inspirationalQuotesNo7/,
    );
  });

  it("builds deterministic notification type and localized quote documents", () => {
    const documents = buildNotificationSeed({
      he: {
        inspirationalQuotesNo1:
          "{gender,select,male{חזק} female{חזקה} other{חזקים}}",
        inspirationalQuotesNo0:
          "{gender,select,male{רגוע} female{רגועה} other{רגועים}}",
        unrelated: "ignored",
      },
      ar: {
        inspirationalQuotesNo0:
          "{gender,select,male{هادئ} female{هادئة} other{هادئون}}",
      },
      en: {
        inspirationalQuotesNo0:
          "{gender,select,male{calm} female{calm} other{calm}}",
      },
    });

    assert.deepEqual(documents, [
      {
        collection: "notification_types",
        id: "default",
        data: {
          id: "default",
          messageType: "dynamic",
          quotesCollections: {
            he: "quotes_he",
            ar: "quotes_ar",
            en: "quotes_en",
          },
        },
      },
      {
        collection: "quotes_he",
        id: "inspirationalQuotesNo0",
        data: { male: "רגוע", female: "רגועה", other: "רגועים" },
      },
      {
        collection: "quotes_he",
        id: "inspirationalQuotesNo1",
        data: { male: "חזק", female: "חזקה", other: "חזקים" },
      },
      {
        collection: "quotes_ar",
        id: "inspirationalQuotesNo0",
        data: { male: "هادئ", female: "هادئة", other: "هادئون" },
      },
      {
        collection: "quotes_en",
        id: "inspirationalQuotesNo0",
        data: { male: "calm", female: "calm", other: "calm" },
      },
    ]);
  });

  it("is idempotent and leaves documents outside the seed untouched", async () => {
    const storedDocuments = new Map<string, SeedDocument["data"]>([
      ["quotes_en/editorial_quote", { text: "Keep this document" }],
      ["unowned_collection/document", { value: 42 }],
    ]);
    const writer = {
      async setDocument(document: SeedDocument): Promise<void> {
        storedDocuments.set(
          `${document.collection}/${document.id}`,
          document.data,
        );
      },
    };
    const seed: SeedDocument[] = [
      {
        collection: "quotes_en",
        id: "inspirationalQuotesNo0",
        data: { male: "calm", female: "calm", other: "calm" },
      },
    ];

    await provisionNotificationContent(seed, writer);
    const afterFirstRun = [...storedDocuments.entries()];
    await provisionNotificationContent(seed, writer);

    assert.deepEqual([...storedDocuments.entries()], afterFirstRun);
    assert.deepEqual(storedDocuments.get("quotes_en/editorial_quote"), {
      text: "Keep this document",
    });
    assert.deepEqual(storedDocuments.get("unowned_collection/document"), {
      value: 42,
    });
  });
});
