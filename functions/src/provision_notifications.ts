import * as admin from "firebase-admin";
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

admin.initializeApp({ projectId });
const firestore = admin.firestore();
const documents = buildNotificationSeed(arbByLocale);

void provisionNotificationContent(documents, {
  async setDocument(document): Promise<void> {
    await firestore
      .collection(document.collection)
      .doc(document.id)
      .set(document.data);
  },
  async listDocumentIds(collection): Promise<string[]> {
    return (await firestore.collection(collection).listDocuments()).map(
      (document) => document.id,
    );
  },
  async deleteDocument(collection, id): Promise<void> {
    await firestore.collection(collection).doc(id).delete();
  },
})
  .then(() => {
    console.log(`Provisioned ${documents.length} notification documents.`);
  })
  .catch((error: unknown) => {
    console.error("Failed to provision notification documents.", error);
    process.exitCode = 1;
  });
