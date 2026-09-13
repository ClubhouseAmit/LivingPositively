import { pathToFileURL } from 'node:url';

const credentialSetupError =
  'Set a valid FIREBASE_SERVICE_ACCOUNT_JSON in the firebase-production ' +
  'environment after completing docs/deployment-guide.md.';
const rolloutSetupError =
  'Set NOTIFICATION_MUTATION_FENCE_CLIENT_ROLLOUT_APPROVED=true in the ' +
  'firebase-production environment only after recording the compatible-client ' +
  'or first-remote-release evidence required by docs/deployment-guide.md.';

function isNonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

export function validateFirebaseDeploymentConfig({
  serviceAccountJson,
  expectedProjectId,
  functionsReleaseRequired,
  mutationFenceClientRolloutApproved,
}) {
  let serviceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountJson?.trim() ?? '');
  } catch {
    throw new Error(credentialSetupError);
  }

  const hasRequiredCredentialFields =
    serviceAccount !== null &&
    typeof serviceAccount === 'object' &&
    !Array.isArray(serviceAccount) &&
    serviceAccount.type === 'service_account' &&
    serviceAccount.project_id === expectedProjectId &&
    isNonEmptyString(serviceAccount.private_key_id) &&
    isNonEmptyString(serviceAccount.private_key) &&
    serviceAccount.private_key.includes('-----BEGIN PRIVATE KEY-----') &&
    serviceAccount.private_key.includes('-----END PRIVATE KEY-----') &&
    isNonEmptyString(serviceAccount.client_email) &&
    serviceAccount.client_email.includes('@') &&
    isNonEmptyString(serviceAccount.client_id) &&
    isNonEmptyString(serviceAccount.token_uri);
  if (!hasRequiredCredentialFields) {
    throw new Error(credentialSetupError);
  }

  if (functionsReleaseRequired &&
      mutationFenceClientRolloutApproved !== 'true') {
    throw new Error(rolloutSetupError);
  }
}

function parseFunctionsReleaseRequired(value) {
  if (value === 'true') return true;
  if (value === 'false') return false;
  throw new Error('FUNCTIONS_RELEASE_REQUIRED must be true or false.');
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    validateFirebaseDeploymentConfig({
      serviceAccountJson: process.env.FIREBASE_SERVICE_ACCOUNT_JSON,
      expectedProjectId: process.env.FIREBASE_PROJECT_ID,
      functionsReleaseRequired: parseFunctionsReleaseRequired(
        process.env.FUNCTIONS_RELEASE_REQUIRED,
      ),
      mutationFenceClientRolloutApproved:
        process.env.NOTIFICATION_MUTATION_FENCE_CLIENT_ROLLOUT_APPROVED,
    });
  } catch (error) {
    console.error(`::error::${error.message}`);
    process.exitCode = 1;
  }
}
