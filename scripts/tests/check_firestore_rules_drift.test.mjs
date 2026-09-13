import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  deployedRulesSource,
  driftReport,
  normalizeRules,
} from '../check_firestore_rules_drift.mjs';

const baseline = [
  "rules_version = '2';",
  'service cloud.firestore {',
  '\tmatch /databases/{database}/documents {',
  '\t\tmatch /{collectionId}/{document=**} {',
  '\t\t\tallow read: if !serverOnlyCollection(collectionId);',
  '\t\t}',
  '\t}',
  '}',
].join('\n');

test('treats line endings and trailing whitespace as equivalent', () => {
  // A Windows checkout and the Rules API disagree about line endings. That is
  // not a policy change and must not fail a release.
  const windows = baseline.replace(/\n/g, '\r\n');
  const trailing = `${baseline}   \n\n`;

  assert.equal(normalizeRules(windows), normalizeRules(baseline));
  assert.equal(driftReport(windows, baseline).drifted, false);
  assert.equal(driftReport(trailing, baseline).drifted, false);
});

test('reports no drift for identical rulesets', () => {
  assert.deepEqual(driftReport(baseline, baseline), { drifted: false });
});

test('reports the first differing line when the console was edited', () => {
  const consoleEdited = baseline.replace(
    'allow read: if !serverOnlyCollection(collectionId);',
    'allow read: if true;',
  );
  const report = driftReport(baseline, consoleEdited);

  assert.equal(report.drifted, true);
  assert.equal(report.line, 5);
  assert.match(report.repositoryLine, /serverOnlyCollection/);
  assert.match(report.deployedLine, /allow read: if true;/);
});

test('detects a ruleset that is a prefix of the repository version', () => {
  // Truncation is the shape a partially applied or hand-edited ruleset takes,
  // and it must not read as "no difference found".
  const truncated = baseline.split('\n').slice(0, 4).join('\n');
  const report = driftReport(baseline, truncated);

  assert.equal(report.drifted, true);
  assert.equal(report.deployedLine, '(end of file)');
});

test('extracts the single rules file from a ruleset response', () => {
  const ruleset = {
    source: { files: [{ name: 'firestore.rules', content: baseline }] },
  };
  assert.equal(deployedRulesSource(ruleset), baseline);
});

test('refuses a ruleset that does not carry exactly one file', () => {
  // A multi-file ruleset means the deployment target is not what this check
  // assumes, and comparing only the first file would give false assurance.
  for (const ruleset of [
    { source: { files: [] } },
    { source: { files: [{ content: 'a' }, { content: 'b' }] } },
    { source: {} },
    {},
    null,
  ]) {
    assert.throws(() => deployedRulesSource(ruleset), /exactly one rules file/);
  }
});

test('refuses a rules file with unreadable content', () => {
  assert.throws(
    () => deployedRulesSource({ source: { files: [{ name: 'r' }] } }),
    /no readable content/,
  );
});
