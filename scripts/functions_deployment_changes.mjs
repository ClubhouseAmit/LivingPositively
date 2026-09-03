import { spawnSync } from 'node:child_process';
import { appendFileSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const directlyDeployedFiles = new Set([
  'firebase.json',
  '.firebaserc',
  'functions/package.json',
  'functions/package-lock.json',
  'functions/tsconfig.json',
]);
const notificationContentFiles = new Set([
  'lib/l10n/app_he.arb',
  'lib/l10n/app_ar.arb',
  'lib/l10n/app_en.arb',
  'functions/src/notification_provisioning.ts',
  'functions/src/provision_notifications.ts',
]);
const workflowPath = '.github/workflows/main.yml';
const deploymentBlockStart = '  # BEGIN NOTIFICATION BACKEND RELEASE';
const deploymentBlockEnd = '  # END NOTIFICATION BACKEND RELEASE';
const commitPattern = /^[a-f0-9]{40}$/;

function runGit(argumentsList, workingDirectory) {
  const result = spawnSync('git', argumentsList, {
    cwd: workingDirectory,
    encoding: 'utf8',
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`Git command failed: git ${argumentsList.join(' ')}`);
  }
  return result.stdout;
}

function deploymentWorkflowBlock(source) {
  const start = source.indexOf(deploymentBlockStart);
  const end = source.indexOf(deploymentBlockEnd);
  if (start < 0 || end < start) return undefined;
  return source.slice(start, end + deploymentBlockEnd.length);
}

function isFunctionsRuntimeFile(path) {
  if (!path.startsWith('functions/src/') || notificationContentFiles.has(path)) {
    return false;
  }
  return !/(^|\/)(test|tests)\//.test(path) &&
    !/\.(test|spec)\.[cm]?[jt]s$/.test(path);
}

function changedFiles(baseCommitSha, currentCommitSha, workingDirectory) {
  return runGit([
    'diff', '--name-only', '--diff-filter=ACDMRTUXB',
    baseCommitSha, currentCommitSha,
  ], workingDirectory).split(/\r?\n/).filter(Boolean);
}

function workflowDeploymentChanged(baseCommitSha, workingDirectory) {
  let previousWorkflow;
  try {
    previousWorkflow = runGit(
      ['show', `${baseCommitSha}:${workflowPath}`], workingDirectory,
    );
  } catch {
    return true;
  }
  const currentWorkflow = readFileSync(
    join(workingDirectory, workflowPath), 'utf8',
  );
  return deploymentWorkflowBlock(previousWorkflow) !==
    deploymentWorkflowBlock(currentWorkflow);
}

export function functionsDeploymentPlan(
  workflowRuns,
  { runNumber, currentCommitSha, workingDirectory },
) {
  if (!Array.isArray(workflowRuns) ||
      !Number.isSafeInteger(runNumber) || runNumber < 1 ||
      typeof currentCommitSha !== 'string' ||
      !commitPattern.test(currentCommitSha)) {
    throw new Error('Invalid workflow history or current run metadata.');
  }

  // Comparing only event.before would lose backend changes when that run
  // failed and a later push changed unrelated files. Exclude the current run
  // (including reruns) and later runs from the baseline search.
  const baseline = workflowRuns
    .filter((run) => run.event === 'push' && run.head_branch === 'main' &&
      run.status === 'completed' && run.conclusion === 'success' &&
      Number.isSafeInteger(run.run_number) && run.run_number < runNumber &&
      typeof run.head_sha === 'string' && commitPattern.test(run.head_sha))
    .sort((left, right) => right.run_number - left.run_number)[0];

  if (!baseline) {
    return {
      functionsRequired: true,
      contentRequired: true,
      reason: 'No previous successful main run.',
    };
  }

  const baseCommitSha = baseline.head_sha;
  const ancestorCheckResult = spawnSync(
    'git', ['merge-base', '--is-ancestor', baseCommitSha, currentCommitSha],
    { cwd: workingDirectory, encoding: 'utf8' },
  );
  if (ancestorCheckResult.error) throw ancestorCheckResult.error;
  if (ancestorCheckResult.status !== 0) {
    return {
      functionsRequired: true,
      contentRequired: true,
      reason: 'Previous successful revision is not an available ancestor.',
    };
  }

  const paths = changedFiles(
    baseCommitSha, currentCommitSha, workingDirectory,
  );
  const contentRequired = paths.some((path) =>
    notificationContentFiles.has(path));
  const functionsRequired = paths.some((path) =>
    directlyDeployedFiles.has(path) || isFunctionsRuntimeFile(path)) ||
    workflowDeploymentChanged(baseCommitSha, workingDirectory);

  return {
    functionsRequired,
    contentRequired,
    reason: `Compared backend inputs with successful revision ${baseCommitSha}.`,
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const history = JSON.parse(readFileSync(process.argv[2], 'utf8'));
  const plan = functionsDeploymentPlan(history.workflow_runs, {
    runNumber: Number(process.env.GITHUB_RUN_NUMBER),
    currentCommitSha: process.env.GITHUB_SHA,
    workingDirectory: process.cwd(),
  });
  const releaseRequired = plan.functionsRequired || plan.contentRequired;
  appendFileSync(process.env.GITHUB_OUTPUT,
    `required=${releaseRequired}\n` +
    `functions_required=${plan.functionsRequired}\n` +
    `content_required=${plan.contentRequired}\n`);
  console.log(
    `Backend release required: ${releaseRequired}; ` +
    `Functions: ${plan.functionsRequired}; content: ${plan.contentRequired}. ` +
    plan.reason,
  );
}
