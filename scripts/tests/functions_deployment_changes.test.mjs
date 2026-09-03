import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

import { functionsDeploymentPlan } from '../functions_deployment_changes.mjs';

function repository(t) {
  const cwd = mkdtempSync(join(tmpdir(), 'functions-deployment-test-'));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  const git = (...args) => execFileSync('git', args, { cwd, encoding: 'utf8' }).trim();
  git('init', '--quiet');
  git('config', 'core.autocrlf', 'false');
  function commit(path) {
    mkdirSync(dirname(join(cwd, path)), { recursive: true });
    writeFileSync(join(cwd, path), `${path}\n`);
    git('add', '.');
    git('-c', 'user.name=Deployment test', '-c', 'user.email=test@example.invalid',
      '-c', 'commit.gpgsign=false', 'commit', '--quiet', '-m', path);
    return git('rev-parse', 'HEAD');
  }
  return { cwd, git, commit };
}

function successfulRun(sha, runNumber = 10) {
  return { head_sha: sha, run_number: runNumber, event: 'push',
    head_branch: 'main', status: 'completed', conclusion: 'success' };
}

test('skips documentation-only changes after a successful main run', (t) => {
  const repo = repository(t);
  const base = repo.commit('functions/src/index.ts');
  const sha = repo.commit('docs/readme.md');
  const plan = functionsDeploymentPlan([successfulRun(base)], {
    cwd: repo.cwd, runNumber: 11, sha,
  });
  assert.equal(plan.required, false);
});

test('catches Functions changes from a failed run before an unrelated push', (t) => {
  const repo = repository(t);
  const base = repo.commit('README.md');
  const failedSha = repo.commit('functions/src/index.ts');
  const sha = repo.commit('docs/readme.md');
  const plan = functionsDeploymentPlan([
    successfulRun(base),
    { ...successfulRun(failedSha, 11), conclusion: 'failure' },
  ], { cwd: repo.cwd, runNumber: 12, sha });
  assert.equal(plan.required, true);
});

test('deploys for configuration, dependency, workflow, and detector changes', async (t) => {
  for (const path of ['functions/package-lock.json', 'firebase.json', '.firebaserc',
    '.github/workflows/main.yml', 'scripts/functions_deployment_changes.mjs',
    'scripts/tests/functions_deployment_changes.test.mjs']) {
    await t.test(path, (t) => {
      const repo = repository(t);
      const base = repo.commit('README.md');
      const sha = repo.commit(path);
      assert.equal(functionsDeploymentPlan([successfulRun(base)], {
        cwd: repo.cwd, runNumber: 11, sha,
      }).required, true);
    });
  }
});

test('detects deleted Functions files', (t) => {
  const repo = repository(t);
  const base = repo.commit('functions/src/obsolete.ts');
  repo.git('rm', 'functions/src/obsolete.ts');
  const sha = repo.commit('README.md');
  assert.equal(functionsDeploymentPlan([successfulRun(base)], {
    cwd: repo.cwd, runNumber: 11, sha,
  }).required, true);
});

test('uses the latest successful main push, ignoring PRs, reruns, and later runs', (t) => {
  const repo = repository(t);
  const old = repo.commit('README.md');
  const base = repo.commit('functions/src/index.ts');
  const sha = repo.commit('docs/readme.md');
  const runs = [successfulRun(old, 1), successfulRun(base, 10),
    { ...successfulRun(old, 11), event: 'pull_request' },
    { ...successfulRun(old, 12), head_branch: 'feature/test' },
    successfulRun(old, 20), successfulRun(old, 21)];
  assert.equal(functionsDeploymentPlan(runs, {
    cwd: repo.cwd, runNumber: 20, sha,
  }).required, false);
});

test('deploys when successful history is empty or its commit is unavailable', (t) => {
  const repo = repository(t);
  const sha = repo.commit('README.md');
  for (const runs of [[], [successfulRun('a'.repeat(40))]]) {
    assert.equal(functionsDeploymentPlan(runs, {
      cwd: repo.cwd, runNumber: 11, sha,
    }).required, true);
  }
});

test('rejects malformed history rather than silently skipping deployment', () => {
  assert.throws(() => functionsDeploymentPlan(undefined, {
    runNumber: 11, sha: 'a'.repeat(40), cwd: '.',
  }), /Invalid workflow history/);
});

test('CLI writes the required output consumed by deployment steps', (t) => {
  const repo = repository(t);
  const sha = repo.commit('functions/src/index.ts');
  const historyPath = join(repo.cwd, 'history.json');
  const outputPath = join(repo.cwd, 'github-output');
  writeFileSync(historyPath, JSON.stringify({ workflow_runs: [] }));
  const output = execFileSync(process.execPath, [
    fileURLToPath(new URL('../functions_deployment_changes.mjs', import.meta.url)),
    historyPath,
  ], { cwd: repo.cwd, encoding: 'utf8', env: {
    ...process.env, GITHUB_SHA: sha, GITHUB_RUN_NUMBER: '11',
    GITHUB_OUTPUT: outputPath,
  } });
  assert.equal(readFileSync(outputPath, 'utf8'), 'required=true\n');
  assert.match(output, /Functions deployment required: true/);
});
