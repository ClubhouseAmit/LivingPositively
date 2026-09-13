import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  validateFirebaseDeploymentConfig,
} from '../validate_firebase_deployment_config.mjs';

const validServiceAccount = JSON.stringify({
  type: 'service_account',
  project_id: 'mezilondb',
  private_key_id: 'key-id',
  private_key:
    '-----BEGIN PRIVATE KEY-----\nnot-a-production-key\n-----END PRIVATE KEY-----\n',
  client_email: 'firebase-deployer@mezilondb.iam.gserviceaccount.com',
  client_id: '123456789',
  token_uri: 'https://oauth2.googleapis.com/token',
});

function validate(overrides = {}) {
  return validateFirebaseDeploymentConfig({
    serviceAccountJson: validServiceAccount,
    expectedProjectId: 'mezilondb',
    functionsReleaseRequired: false,
    mutationFenceClientRolloutApproved: undefined,
    ...overrides,
  });
}

test('rejects missing, malformed, and incomplete service-account JSON', () => {
  for (const serviceAccountJson of [
    undefined,
    '   ',
    '{malformed',
    '{}',
    JSON.stringify({
      type: 'service_account',
      project_id: 'mezilondb',
      private_key: 'not a PEM key',
      client_email: 'deployer@example.invalid',
    }),
  ]) {
    assert.throws(
      () => validate({ serviceAccountJson }),
      /valid FIREBASE_SERVICE_ACCOUNT_JSON/,
    );
  }
});

test('rejects a service account from another Firebase project', () => {
  const wrongProject = JSON.stringify({
    ...JSON.parse(validServiceAccount),
    project_id: 'another-project',
  });
  assert.throws(
    () => validate({ serviceAccountJson: wrongProject }),
    /valid FIREBASE_SERVICE_ACCOUNT_JSON/,
  );
});

test('allows content-only release without the mutation-fence rollout gate', () => {
  assert.doesNotThrow(() => validate());
});

test('requires explicit compatible-client approval for a Functions release', () => {
  for (const mutationFenceClientRolloutApproved of [undefined, '', 'false']) {
    assert.throws(
      () => validate({
        functionsReleaseRequired: true,
        mutationFenceClientRolloutApproved,
      }),
      /NOTIFICATION_MUTATION_FENCE_CLIENT_ROLLOUT_APPROVED=true/,
    );
  }
  assert.doesNotThrow(() => validate({
    functionsReleaseRequired: true,
    mutationFenceClientRolloutApproved: 'true',
  }));
});
