# Cloud Functions dependency security

The Functions CI quality workflow requires a clean production dependency audit:

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

The Functions manifest selects npm 11.14.0 with `engines.npm`, the supported
[Google buildpack selector](https://docs.cloud.google.com/docs/buildpacks/nodejs#npm_package_manager).
CI and the release runner install that version before `npm ci` and
verify the installed dependency graph using `npm run verify:dependencies`.
The script checks Storage/Gaxios's resolved UUID version and CommonJS `v4`
API, Admin Firestore's gRPC version, and the Firestore test SDK's gRPC version.
CI and the pre-release runner explicitly execute `npm run gcp-build`. That
pipeline runs the verifier with `--managed` to assert Node 22 and
npm 11.14.0, audits the complete installed graph with
`--include=dev --audit-level=low` even under `NODE_ENV=production`,
compiles TypeScript, prunes development
dependencies with implicit auditing disabled, then verifies the production tree
and runs `npm audit --omit=dev --audit-level=low`. CI also audits the production
graph. The `--production` verifier skips the absent test SDK and resolves
UUID/gRPC from their production consumers.
On 2026-10-02 the owner explicitly authorized CI and pre-release audits and
removed the managed-build audit/evidence requirement. Both full and production
audits remain mandatory before release mutations. A newly published advisory or
an unavailable advisory endpoint can block the pre-release runner after CI
passes. Dependency installation also needs registry access. This acceptance
changes where checks run; it accepts no vulnerability or audit failure and adds
no periodic monitoring.
Exact UUID/Gaxios/gRPC assertions intentionally enforce the reviewed lockfile;
update them alongside a reviewed dependency upgrade.

The manifest uses the documented npm selector and contains no `packageManager`
field. CI and the pre-release runner assert the same selected toolchain and consumer
graph. A release-runner replay checks compilation and pruning before rules or
content are changed, then restores dev dependencies for content provisioning.
The pinned Firebase CLI 15.32.1 sets `GOOGLE_NODE_RUN_SCRIPTS=""` in its
[generation 1](https://github.com/firebase/firebase-tools/blob/v15.32.1/src/gcp/cloudfunctions.ts)
and [generation 2](https://github.com/firebase/firebase-tools/blob/v15.32.1/src/gcp/cloudfunctionsv2.ts)
create/update paths. This overrides `gcp-build` and disables managed npm scripts,
as documented by the [Node buildpack](https://docs.cloud.google.com/docs/buildpacks/nodejs#execute_custom_build_steps_during_deployment).
The manifest hook is retained as the shared CI/pre-release pipeline; it is not
claimed to execute inside Firebase's managed build. Successful `firebase deploy`
determines deployment completion, not execution of skipped scripts. Local replay
does not prove the managed npm selection or installed consumer graph; that
remaining assurance limit is accepted under the policy above.

A failed npm download or
managed build can still leave a partial release, since Firebase has no cross-
resource transaction. The independent real-account authentication rollout gates
in `docs/auth-provider-rollout.md` remain open. No managed build or production
deployment was run for this review.
