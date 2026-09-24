import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';

import { findUnclassifiedCollectionReferences } from '../check_firestore_collection_policy.mjs';

function writeRules(root) {
  const rulesPath = join(root, 'firestore.rules');
  writeFileSync(rulesPath, [
    'function serverOnlyCollection(collectionId) {',
    '  return collectionId in ["devices", "scheduled_notifications"] ||',
    '    collectionId.matches("quotes_.*");',
    '}',
  ].join('\n'));
  return rulesPath;
}

test('allows server-only and schema-constrained collection references', (t) => {
  const root = mkdtempSync(join(tmpdir(), 'firestore-policy-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const rulesPath = writeRules(root);
  writeFileSync(join(root, 'index.ts'), [
    'db.collection("devices");',
    'db.collection("quotes_en");',
    'db.collection(collectionName);',
  ].join('\n'));
  assert.deepEqual(findUnclassifiedCollectionReferences(root, rulesPath), []);
});

test('rejects unclassified literal and dynamic collection references', (t) => {
  const root = mkdtempSync(join(tmpdir(), 'firestore-policy-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const rulesPath = writeRules(root);
  mkdirSync(join(root, 'nested'));
  writeFileSync(join(root, 'nested', 'index.ts'), [
    'db.collection("unclassified");',
    'db.collection(unknownCollection);',
  ].join('\n'));
  const issues = findUnclassifiedCollectionReferences(root, rulesPath);
  assert.equal(issues.length, 2);
  assert.match(issues[0], /unclassified collection/);
  assert.match(issues[1], /unclassified dynamic collection/);
});

test('uses the server-only collection list declared by Firestore rules', (t) => {
  const root = mkdtempSync(join(tmpdir(), 'firestore-policy-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const rulesPath = writeRules(root);
  writeFileSync(join(root, 'index.ts'), 'db.collection("notification_deliveries");');

  const issues = findUnclassifiedCollectionReferences(root, rulesPath);
  assert.equal(issues.length, 1);
  assert.match(issues[0], /unclassified collection notification_deliveries/);
});
