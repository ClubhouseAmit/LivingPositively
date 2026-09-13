import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { after, before, beforeEach, describe, it } from "node:test";

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} from "firebase/firestore";

// Collections the notification backend owns. No client may reach these by any
// verb. See docs/adr/ADR-015 decisions 2, 3 and 8.
const SERVER_ONLY_COLLECTIONS = [
  "devices",
  "scheduled_notifications",
  "notification_deliveries",
  "notification_scheduler_state",
  "notification_mutation_state",
  "notification_types",
  "quotes_he",
  "quotes_ar",
  "quotes_en",
  // Proves the prefix match rather than a literal list: a locale nobody has
  // added yet must already be denied.
  "quotes_ru",
];

// Collections that existed before this branch. Constraint 2 requires their
// effective policy to be unchanged, so these assert the baseline behaviour
// still holds.
const PUBLICLY_READABLE_COLLECTIONS = [
  "SyncPages",
  "VersionManager",
  "feelGoodPageTitles",
  "ShareTexts",
  "users",
];

const ALICE = "alice-uid";
const BOB = "bob-uid";

let testEnv: RulesTestEnvironment;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "mazilon-rules-test",
    firestore: {
      rules: readFileSync(resolve(__dirname, "../../firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// Seeds a document past the rules so read denials are proven against a
// document that exists. A denied read of a missing document would pass for
// the wrong reason.
async function seed(path: string, data: Record<string, unknown>) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

describe("server-only collections", () => {
  for (const collectionId of SERVER_ONLY_COLLECTIONS) {
    describe(collectionId, () => {
      it("denies every verb to an unauthenticated caller", async () => {
        await seed(`${collectionId}/seeded`, { value: 1 });
        const db = testEnv.unauthenticatedContext().firestore();

        await assertFails(getDoc(doc(db, `${collectionId}/seeded`)));
        await assertFails(getDocs(collection(db, collectionId)));
        await assertFails(setDoc(doc(db, `${collectionId}/new`), { v: 1 }));
        await assertFails(
          updateDoc(doc(db, `${collectionId}/seeded`), { value: 2 }),
        );
        await assertFails(deleteDoc(doc(db, `${collectionId}/seeded`)));
      });

      it("denies every verb to a signed-in caller", async () => {
        await seed(`${collectionId}/seeded`, { value: 1 });
        const db = testEnv.authenticatedContext(ALICE).firestore();

        await assertFails(getDoc(doc(db, `${collectionId}/seeded`)));
        await assertFails(getDocs(collection(db, collectionId)));
        await assertFails(setDoc(doc(db, `${collectionId}/new`), { v: 1 }));
        await assertFails(
          updateDoc(doc(db, `${collectionId}/seeded`), { value: 2 }),
        );
        await assertFails(deleteDoc(doc(db, `${collectionId}/seeded`)));
      });

      it("denies an ADMIN role the catch-all would otherwise grant", async () => {
        await seed(`${collectionId}/seeded`, { value: 1 });
        const db = testEnv
          .authenticatedContext(ALICE, { roles: ["ADMIN"] })
          .firestore();

        await assertFails(getDoc(doc(db, `${collectionId}/seeded`)));
        await assertFails(setDoc(doc(db, `${collectionId}/new`), { v: 1 }));
        await assertFails(deleteDoc(doc(db, `${collectionId}/seeded`)));
      });
    });
  }

  it("denies the nested notification_mutation_state types subcollection", async () => {
    const path = `notification_mutation_state/${ALICE}/types/default`;
    await seed(path, { version: 1 });

    for (const context of [
      testEnv.unauthenticatedContext(),
      testEnv.authenticatedContext(ALICE),
      testEnv.authenticatedContext(ALICE, { roles: ["ADMIN"] }),
    ]) {
      const db = context.firestore();
      await assertFails(getDoc(doc(db, path)));
      await assertFails(
        getDocs(collection(db, `notification_mutation_state/${ALICE}/types`)),
      );
      await assertFails(setDoc(doc(db, path), { version: 2 }));
      await assertFails(deleteDoc(doc(db, path)));
    }
  });
});

describe("devices ownership", () => {
  it("lets a signed-in user read and write only their own document", async () => {
    const db = testEnv.authenticatedContext(ALICE).firestore();

    await assertSucceeds(
      setDoc(doc(db, `devices/${ALICE}`), {
        fcmToken: "token-a",
        platform: "android",
      }),
    );
    await assertSucceeds(getDoc(doc(db, `devices/${ALICE}`)));
    await assertSucceeds(
      updateDoc(doc(db, `devices/${ALICE}`), { fcmToken: "token-a2" }),
    );
  });

  it("denies reading or writing the device document of another user", async () => {
    await seed(`devices/${BOB}`, { fcmToken: "token-b" });
    const db = testEnv.authenticatedContext(ALICE).firestore();

    await assertFails(getDoc(doc(db, `devices/${BOB}`)));
    await assertFails(setDoc(doc(db, `devices/${BOB}`), { fcmToken: "x" }));
    await assertFails(deleteDoc(doc(db, `devices/${BOB}`)));
  });

  it("denies the unauthenticated enumeration the removed wildcard allowed", async () => {
    await seed(`devices/${ALICE}`, { fcmToken: "token-a" });
    await seed(`devices/${BOB}`, { fcmToken: "token-b" });
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(getDocs(collection(db, "devices")));
    await assertFails(getDoc(doc(db, `devices/${ALICE}`)));
  });

  it("denies backdating updatedAt, which drives stale-device cleanup", async () => {
    // The scheduler deletes schedules for devices whose updatedAt is older
    // than STALE_TOKEN_DAYS. Under the removed wildcard this field was
    // writable by anyone. See ADR-015 decision 8.
    await seed(`devices/${BOB}`, { fcmToken: "token-b" });
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(
      updateDoc(doc(db, `devices/${BOB}`), { updatedAt: new Date(0) }),
    );
  });
});

describe("pre-existing collections keep their baseline policy", () => {
  for (const collectionId of PUBLICLY_READABLE_COLLECTIONS) {
    it(`still allows an unauthenticated read of ${collectionId}`, async () => {
      // Constraint 2. The app issues these reads before any sign-in, so
      // requiring auth here would break first launch.
      await seed(`${collectionId}/seeded`, { value: 1 });
      const db = testEnv.unauthenticatedContext().firestore();

      await assertSucceeds(getDoc(doc(db, `${collectionId}/seeded`)));
      await assertSucceeds(getDocs(collection(db, collectionId)));
    });
  }

  it("still allows an ADMIN role to write a collection that is not denylisted", async () => {
    const db = testEnv
      .authenticatedContext(ALICE, { roles: ["ADMIN"] })
      .firestore();

    await assertSucceeds(setDoc(doc(db, "SyncPages/page"), { value: 1 }));
  });

  it("still denies an unauthenticated write to a collection that is not denylisted", async () => {
    const db = testEnv.unauthenticatedContext().firestore();

    await assertFails(setDoc(doc(db, "SyncPages/page"), { value: 1 }));
  });

  it("still lets a user write only their own users document", async () => {
    const alice = testEnv.authenticatedContext(ALICE).firestore();

    await assertSucceeds(setDoc(doc(alice, `users/${ALICE}`), { name: "a" }));
    await assertFails(setDoc(doc(alice, `users/${BOB}`), { name: "b" }));
  });
});

describe("denylist coverage", () => {
  it("names every collection the functions runtime owns", () => {
    // Guards against a new server-only collection being added in code without
    // a matching rules entry. ADR-015 decision 6.
    const source = readFileSync(resolve(__dirname, "../src/index.ts"), "utf8");
    const referenced = new Set(
      [...source.matchAll(/collection\("([A-Za-z_0-9]+)"\)/g)].map(
        (match) => match[1],
      ),
    );

    assert.ok(referenced.size > 0, "expected to find collection references");

    for (const collectionId of referenced) {
      assert.ok(
        SERVER_ONLY_COLLECTIONS.includes(collectionId) ||
          collectionId.startsWith("quotes_"),
        `${collectionId} is referenced by functions/src/index.ts but is not ` +
          "covered by the server-only denylist",
      );
    }
  });
});
