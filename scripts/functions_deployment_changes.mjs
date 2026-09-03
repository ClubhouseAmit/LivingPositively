import { spawnSync } from 'node:child_process';
import { appendFileSync, readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

// Include deployment tooling itself so introducing or fixing CI also deploys
// the Functions. ARB content is provisioned separately, not shipped by deploy.
const deploymentPaths = [
  'functions/',
  'firebase.json',
  '.firebaserc',
  '.github/workflows/main.yml',
  'scripts/functions_deployment_changes.mjs',
  'scripts/tests/functions_deployment_changes.test.mjs',
];
const commitPattern = /^[a-f0-9]{40}$/;

export function functionsDeploymentPlan(workflowRuns, { runNumber, sha, cwd }) {
  if (!Array.isArray(workflowRuns) ||
      !Number.isSafeInteger(runNumber) || runNumber < 1 ||
      typeof sha !== 'string' || !commitPattern.test(sha)) {
    throw new Error('Invalid workflow history or current run metadata.');
  }

  // Comparing only event.before would lose a Functions change when its run
  // failed and a subsequent push changed only unrelated files. Exclude the
  // current run (including reruns) and later runs from the baseline search.
  const baseline = workflowRuns
    .filter((run) => run.event === 'push' && run.head_branch === 'main' &&
      run.status === 'completed' && run.conclusion === 'success' &&
      Number.isSafeInteger(run.run_number) && run.run_number < runNumber &&
      typeof run.head_sha === 'string' && commitPattern.test(run.head_sha))
    .sort((left, right) => right.run_number - left.run_number)[0];

  if (!baseline) {
    return { required: true, reason: 'No previous successful main run.' };
  }

  const baseSha = baseline.head_sha;
  const ancestor = spawnSync('git', ['merge-base', '--is-ancestor', baseSha, sha], {
    cwd, encoding: 'utf8',
  });
  if (ancestor.error) throw ancestor.error;
  if (ancestor.status !== 0) {
    // Missing history or rewritten main: deploy conservatively instead of
    // treating an unavailable comparison as "no changes".
    return { required: true, reason: 'Previous successful revision is not an available ancestor.' };
  }

  const diff = spawnSync('git', [
    'diff', '--quiet', baseSha, sha, '--', ...deploymentPaths,
  ], { cwd, encoding: 'utf8' });
  if (diff.error) throw diff.error;
  if (diff.status !== 0 && diff.status !== 1) {
    throw new Error('Unable to compare Functions deployment inputs.');
  }
  return {
    required: diff.status === 1,
    reason: `Compared deployment inputs with successful revision ${baseSha}.`,
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const history = JSON.parse(readFileSync(process.argv[2], 'utf8'));
  const plan = functionsDeploymentPlan(history.workflow_runs, {
    runNumber: Number(process.env.GITHUB_RUN_NUMBER),
    sha: process.env.GITHUB_SHA,
    cwd: process.cwd(),
  });
  appendFileSync(process.env.GITHUB_OUTPUT, `required=${plan.required}\n`);
  console.log(`Functions deployment required: ${plan.required}. ${plan.reason}`);
}
