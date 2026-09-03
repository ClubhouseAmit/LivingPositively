import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

import { functionsDeploymentPlan } from '../functions_deployment_changes.mjs';

const workflowStart = '  # BEGIN NOTIFICATION BACKEND RELEASE';
const workflowEnd = '  # END NOTIFICATION BACKEND RELEASE';

function repository(t) {
  const workingDirectory = mkdtempSync(
    join(tmpdir(), 'functions-deployment-test-'),
  );
  t.after(() => rmSync(workingDirectory, { recursive: true, force: true }));
  const git = (...args) => execFileSync('git', args, {
    cwd: workingDirectory, encoding: 'utf8',
  }).trim();
  git('init', '--quiet');
  git('config', 'core.autocrlf', 'false');
  function commit(path, value = `${path}\n`) {
    mkdirSync(dirname(join(workingDirectory, path)), { recursive: true });
    writeFileSync(join(workingDirectory, path), value);
    git('add', '.');
    git('-c', 'user.name=Deployment test',
      '-c', 'user.email=test@example.invalid', '-c', 'commit.gpgsign=false',
      'commit', '--quiet', '-m', path);
    return git('rev-parse', 'HEAD');
  }
  commit('.github/workflows/main.yml',
    `jobs:\n${workflowStart}\n  backend: base\n${workflowEnd}\n`);
  return { workingDirectory, git, commit };
}

function successfulRun(commitSha, runNumber = 10) {
  return { head_sha: commitSha, run_number: runNumber, event: 'push',
    head_branch: 'main', status: 'completed', conclusion: 'success' };
}

function plan(repo, baseline, currentCommitSha, workflowRuns = undefined) {
  return functionsDeploymentPlan(
    workflowRuns ?? [successfulRun(baseline)],
    { workingDirectory: repo.workingDirectory, runNumber: 11, currentCommitSha },
  );
}

test('skips documentation and test-only changes', async (t) => {
  for (const path of [
    'docs/readme.md',
    'functions/src/index.test.ts',
    'functions/src/tests/helper.ts',
    'functions/SECURITY.md',
    'functions/tsconfig.dev.json',
    'scripts/tests/functions_deployment_changes.test.mjs',
  ]) {
    await t.test(path, (t) => {
      const repo = repository(t);
      const baseline = repo.git('rev-parse', 'HEAD');
      const currentCommitSha = repo.commit(path);
      assert.equal(plan(repo, baseline, currentCommitSha).functionsRequired, false);
      assert.equal(plan(repo, baseline, currentCommitSha).contentRequired, false);
    });
  }
});

test('catches runtime changes from a failed run before an unrelated push', (t) => {
  const repo = repository(t);
  const baseline = repo.git('rev-parse', 'HEAD');
  const failedCommitSha = repo.commit('functions/src/index.ts');
  const currentCommitSha = repo.commit('docs/readme.md');
  const result = plan(repo, baseline, currentCommitSha, [
    successfulRun(baseline),
    { ...successfulRun(failedCommitSha, 11), conclusion: 'failure' },
  ]);
  assert.equal(result.functionsRequired, true);
  assert.equal(result.contentRequired, false);
});

test('deploys for runtime configuration, dependencies, and source changes', async (t) => {
  for (const path of [
    'functions/src/index.ts',
    'functions/src/notification_validation.ts',
    'functions/package-lock.json',
    'firebase.json',
    '.firebaserc',
  ]) {
    await t.test(path, (t) => {
      const repo = repository(t);
      const baseline = repo.git('rev-parse', 'HEAD');
      const currentCommitSha = repo.commit(path);
      assert.equal(plan(repo, baseline, currentCommitSha).functionsRequired, true);
    });
  }
});

test('provisions notification content for locale and provisioner changes', async (t) => {
  for (const path of [
    'lib/l10n/app_he.arb',
    'lib/l10n/app_ar.arb',
    'lib/l10n/app_en.arb',
    'functions/src/notification_provisioning.ts',
    'functions/src/provision_notifications.ts',
  ]) {
    await t.test(path, (t) => {
      const repo = repository(t);
      const baseline = repo.git('rev-parse', 'HEAD');
      const currentCommitSha = repo.commit(path);
      assert.equal(plan(repo, baseline, currentCommitSha).contentRequired, true);
    });
  }
});

test('ignores unrelated workflow changes but detects backend release changes', (t) => {
  const unrelatedRepo = repository(t);
  const unrelatedBaseline = unrelatedRepo.git('rev-parse', 'HEAD');
  const existingWorkflow = readFileSync(
    join(unrelatedRepo.workingDirectory, '.github/workflows/main.yml'), 'utf8',
  );
  const unrelatedSha = unrelatedRepo.commit(
    '.github/workflows/main.yml', `${existingWorkflow}\n# Android comment\n`,
  );
  assert.equal(
    plan(unrelatedRepo, unrelatedBaseline, unrelatedSha).functionsRequired,
    false,
  );

  const backendRepo = repository(t);
  const backendBaseline = backendRepo.git('rev-parse', 'HEAD');
  const changedWorkflow = readFileSync(
    join(backendRepo.workingDirectory, '.github/workflows/main.yml'), 'utf8',
  ).replace('backend: base', 'backend: changed');
  const backendSha = backendRepo.commit(
    '.github/workflows/main.yml', changedWorkflow,
  );
  assert.equal(
    plan(backendRepo, backendBaseline, backendSha).functionsRequired,
    true,
  );
});

test('detects deleted Functions runtime files', (t) => {
  const repo = repository(t);
  repo.commit('functions/src/obsolete.ts');
  const baseline = repo.git('rev-parse', 'HEAD');
  repo.git('rm', 'functions/src/obsolete.ts');
  const currentCommitSha = repo.commit('README.md');
  assert.equal(plan(repo, baseline, currentCommitSha).functionsRequired, true);
});

test('uses the latest earlier successful main push', (t) => {
  const repo = repository(t);
  const old = repo.git('rev-parse', 'HEAD');
  const baseline = repo.commit('functions/src/index.ts');
  const currentCommitSha = repo.commit('docs/readme.md');
  const runs = [successfulRun(old, 1), successfulRun(baseline, 10),
    { ...successfulRun(old, 11), event: 'pull_request' },
    { ...successfulRun(old, 12), head_branch: 'feature/test' },
    successfulRun(old, 20), successfulRun(old, 21)];
  assert.equal(functionsDeploymentPlan(runs, {
    workingDirectory: repo.workingDirectory,
    runNumber: 20,
    currentCommitSha,
  }).functionsRequired, false);
});

test('releases both boundaries when history is empty or unavailable', (t) => {
  const repo = repository(t);
  const currentCommitSha = repo.git('rev-parse', 'HEAD');
  for (const runs of [[], [successfulRun('a'.repeat(40))]]) {
    const result = functionsDeploymentPlan(runs, {
      workingDirectory: repo.workingDirectory,
      runNumber: 11,
      currentCommitSha,
    });
    assert.equal(result.functionsRequired, true);
    assert.equal(result.contentRequired, true);
  }
});

test('rejects malformed history rather than silently skipping release', () => {
  assert.throws(() => functionsDeploymentPlan(undefined, {
    runNumber: 11,
    currentCommitSha: 'a'.repeat(40),
    workingDirectory: '.',
  }), /Invalid workflow history/);
});

test('CLI writes outputs consumed by conditional release steps', (t) => {
  const repo = repository(t);
  const currentCommitSha = repo.commit('functions/src/index.ts');
  const historyPath = join(repo.workingDirectory, 'history.json');
  const outputPath = join(repo.workingDirectory, 'github-output');
  writeFileSync(historyPath, JSON.stringify({ workflow_runs: [] }));
  const output = execFileSync(process.execPath, [
    fileURLToPath(new URL('../functions_deployment_changes.mjs', import.meta.url)),
    historyPath,
  ], { cwd: repo.workingDirectory, encoding: 'utf8', env: {
    ...process.env,
    GITHUB_SHA: currentCommitSha,
    GITHUB_RUN_NUMBER: '11',
    GITHUB_OUTPUT: outputPath,
  } });
  assert.equal(
    readFileSync(outputPath, 'utf8'),
    'required=true\nfunctions_required=true\ncontent_required=true\n',
  );
  assert.match(output, /Backend release required: true/);
});
