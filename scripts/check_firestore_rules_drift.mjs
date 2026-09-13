// Verifies that the Firestore ruleset serving production matches the one in
// this repository.
//
// ADR-015 makes the repository the single writer for production rules. That
// only holds if console edits are detected: `firebase deploy --only
// firestore:rules` replaces the entire ruleset, so an undetected console edit
// would be silently reverted by the next release that touches the file.
//
// Runs after the rules deploy step, so a match also confirms the deploy
// landed. On a release that deployed no rules, it confirms nothing has
// drifted since the last one.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const rulesApi = 'https://firebaserules.googleapis.com/v1';

// Compare semantics, not formatting. The Rules API returns the source it was
// given, but line endings differ between a Windows checkout and the runner,
// and trailing whitespace is not a policy change.
export function normalizeRules(source) {
  return source.replace(/\r\n/g, '\n').replace(/[ \t]+$/gm, '').trim();
}

export function driftReport(repositorySource, deployedSource) {
  const repositoryLines = normalizeRules(repositorySource).split('\n');
  const deployedLines = normalizeRules(deployedSource).split('\n');
  if (repositoryLines.join('\n') === deployedLines.join('\n')) {
    return { drifted: false };
  }

  const limit = Math.max(repositoryLines.length, deployedLines.length);
  for (let index = 0; index < limit; index += 1) {
    if (repositoryLines[index] !== deployedLines[index]) {
      return {
        drifted: true,
        line: index + 1,
        repositoryLine: repositoryLines[index] ?? '(end of file)',
        deployedLine: deployedLines[index] ?? '(end of file)',
      };
    }
  }
  return { drifted: true };
}

export function deployedRulesSource(ruleset) {
  const files = ruleset?.source?.files;
  if (!Array.isArray(files) || files.length !== 1) {
    throw new Error(
      'Expected exactly one rules file in the deployed ruleset, found ' +
        `${Array.isArray(files) ? files.length : 0}.`,
    );
  }
  const content = files[0]?.content;
  if (typeof content !== 'string') {
    throw new Error('Deployed ruleset file has no readable content.');
  }
  return content;
}

async function requestJson(url, token, projectId) {
  const response = await fetch(url, {
    headers: {
      authorization: `Bearer ${token}`,
      'x-goog-user-project': projectId,
    },
  });
  if (!response.ok) {
    throw new Error(
      `${url} returned ${response.status}: ${await response.text()}`,
    );
  }
  return response.json();
}

async function main() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const token = process.env.GOOGLE_ACCESS_TOKEN;
  if (!projectId) throw new Error('FIREBASE_PROJECT_ID is not set.');
  if (!token) {
    throw new Error(
      'GOOGLE_ACCESS_TOKEN is not set. The authenticate step must request ' +
        "token_format: 'access_token'.",
    );
  }

  const repositorySource = readFileSync(
    join(dirname(fileURLToPath(import.meta.url)), '..', 'firestore.rules'),
    'utf8',
  );

  const release = await requestJson(
    `${rulesApi}/projects/${projectId}/releases/cloud.firestore`,
    token,
    projectId,
  );
  const ruleset = await requestJson(
    `${rulesApi}/${release.rulesetName}`,
    token,
    projectId,
  );

  const report = driftReport(repositorySource, deployedRulesSource(ruleset));
  if (!report.drifted) {
    console.log(
      `Deployed ruleset ${release.rulesetName} matches firestore.rules.`,
    );
    return;
  }

  console.error(
    '::error title=Firestore rules drift::The deployed ruleset does not ' +
      'match firestore.rules. Someone edited the rules outside this ' +
      'repository. Reconcile that change into firestore.rules before ' +
      'releasing, or the next rules deploy will revert it.',
  );
  if (report.line !== undefined) {
    console.error(`First difference at line ${report.line}:`);
    console.error(`  repository: ${report.repositoryLine}`);
    console.error(`  deployed  : ${report.deployedLine}`);
  }
  process.exitCode = 1;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
