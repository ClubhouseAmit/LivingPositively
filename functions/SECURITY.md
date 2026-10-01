# Cloud Functions dependency security

The Functions workflow requires a clean production dependency audit:

```sh
npm audit --omit=dev --audit-level=low
```

The dependency review on 2026-10-01 upgraded Firebase Admin to 14.5.0 and
Firebase Functions to 7.4.0. Admin now resolves `@google-cloud/storage` 8.2.0
through its own `^8.1.0` requirement, so the former storage override is removed.

Two scoped security overrides remain:

- Storage 8.2.0 uses Gaxios 6.7.1, which requires UUID `^9.0.1`. The `gaxios`
  parent override replaces its UUID dependency with 11.1.1, the final
  CommonJS-compatible release with the
  [buffer bounds fix](https://github.com/advisories/GHSA-w5hq-g745-h8pq).
  Gaxios uses the supported `require('uuid').v4()` API for multipart boundaries;
  forcing the ESM-only UUID 14 into it would change its runtime contract.
  The override targets the immediate Gaxios parent because npm 10.9.8 loses
  ancestor and version-scoped overrides when Gaxios is hoisted and shared
  with other Google SDK consumers. Gaxios 7 has no UUID dependency, so this
  affects only its UUID-consuming version 6 in the resolved graph.
  Re-evaluate the override whenever Gaxios changes; remove it when its
  UUID-consuming parents support a patched release without substitution.
  The graph also passes Node 22 with npm 10.9.8, which first exposed the bug.
- The Firebase 12.19.0 development SDK requires `@grpc/grpc-js ~1.9.0` through
  `@firebase/firestore` 4.17.2. Override only that parent to patched 1.14.5,
  addressing [certificate authorization](https://github.com/advisories/GHSA-m9gg-hp2v-232j)
  and [error disclosure](https://github.com/advisories/GHSA-f596-whhp-79r4).
  This stays within gRPC's major version and is exercised by the Firestore
  emulator rules suite. The root Firebase SDK uses the same scoped override.

The Functions lockfile supplies the rules SDK explicitly as a development
dependency. Production and full development audits must both remain clean.
Re-run the audits and `npm ls --all` whenever either JavaScript lockfile changes.
Remove each override when its parent resolves the patched dependency naturally;
do not add an advisory acceptance without an explicit maintainer decision and
an expiry date.

The Functions manifest pins `engines.npm` to 11.14.0. CI and the release
workflow install that exact version from the manifest before `npm ci` and
verify the installed dependency graph using `npm run verify:dependencies`.
The script checks Storage/Gaxios's resolved UUID version and CommonJS `v4`
API, Admin Firestore's gRPC version, and the Firestore test SDK's gRPC version.
The `gcp-build` hook runs the verifier with `--managed` to assert the actual
executing Node 22 and npm 11.14.0, audits the complete installed dependency tree
with `--include=dev --audit-level=low` (including under `NODE_ENV=production`),
compiles the source with TypeScript, prunes
development dependencies, then verifies and audits the production tree. CI
replays that same hook after backend tests. The `--production` verifier skips
the absent test SDK and resolves UUID/gRPC from their production consumers.
These are build-time checks, including in managed Cloud Build; a mismatch,
compiler failure, or failed audit aborts the build before a revision can deploy.
An npm download failure also aborts the build; do not bypass it with a fallback.

Google's [Node.js buildpack documentation](https://docs.cloud.google.com/docs/buildpacks/nodejs)
supports selecting npm with `engines.npm`. The inspected
[version selection source](https://github.com/GoogleCloudPlatform/buildpacks/blob/a317bc9857f8b013d19b3de0bc33296b700496dc/pkg/nodejs/npm.go#L80)
reads that field, and the [npm buildpack](https://github.com/GoogleCloudPlatform/buildpacks/blob/a317bc9857f8b013d19b3de0bc33296b700496dc/cmd/nodejs/npm/lib/lib.go#L241)
installs the requested version before dependency installation. Local clean
installs demonstrate compatibility with the pin; they do not establish that
the managed Firebase Cloud Build image used in a future deployment has run it.
The buildpack supports the [custom `gcp-build` hook](https://docs.cloud.google.com/docs/buildpacks/nodejs#execute_custom_build_steps_during_deployment).
Do not override it through `GOOGLE_NODE_RUN_SCRIPTS`, install with ignored
scripts, or vendor dependencies for this release. The buildpack's later prune
is redundant with the hook's explicit production prune.

For the next approved `firebase-production` release, retain the Cloud Build ID,
region, source revision and successful build log. The managed log must show:

```text
Build toolchain verified: Node 22.<patch>; npm 11.14.0
Dependency graph verified: Storage/Gaxios 6.7.1 -> UUID 11.1.1 (CommonJS v4); Firestore -> gRPC 1.14.5
found 0 vulnerabilities
```

Require these markers after the production prune and a successful TypeScript
build. Download the log with `gcloud builds log BUILD_ID --region REGION
--project mezilondb` using the release owner's existing access. Missing evidence
keeps the app rollout blocked even if the release workflow is green. No managed
build or production deployment was run for this review; the local replay is
proof that the guard works, not managed-build evidence.
