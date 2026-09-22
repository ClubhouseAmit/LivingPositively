import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { readFileSync } from "node:fs";
import path from "node:path";

import {
  buildNotificationSeed,
  parseArbSource,
  parseProvisionProjectId,
  provisionNotificationContent,
} from "./notification_provisioning.js";

const projectId = parseProvisionProjectId(process.argv.slice(2));
const l10nDirectory = path.resolve(__dirname, "../../lib/l10n");
const arbByLocale = {
  he: parseArbSource(
    readFileSync(path.join(l10nDirectory, "app_he.arb"), "utf8"),
  ),
  ar: parseArbSource(
    readFileSync(path.join(l10nDirectory, "app_ar.arb"), "utf8"),
  ),
  en: parseArbSource(
    readFileSync(path.join(l10nDirectory, "app_en.arb"), "utf8"),
  ),
};

initializeApp({ projectId });
const firestore = getFirestore();
const documents = buildNotificationSeed(arbByLocale);

// Seed content in one transaction: a failed provision leaves the previously
// released type/quote revision intact instead of exposing a partial revision.
void firestore.runTransaction(async (transaction) => {
  await provisionNotificationContent(documents, {
    async setDocument(document): Promise<void> {
      transaction.set(
        firestore.collection(document.collection).doc(document.id),
        document.data,
      );
    },
    async listDocumentIds(collection): Promise<string[]> {
      return (await transaction.get(firestore.collection(collection))).docs.map(
        (document) => document.id,
      );
    },
    async deleteDocument(collection, id): Promise<void> {
      transaction.delete(firestore.collection(collection).doc(id));
    },
  });
})
  .then(() => {
    console.log(`Provisioned ${documents.length} notification documents.`);
  })
  .catch((error: unknown) => {
    console.error("Failed to provision notification documents.", error);
    process.exitCode = 1;
  });
