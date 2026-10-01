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
Backend quality also prunes development dependencies and runs the script with
`--production`, which skips the test SDK check. These checks run in CI and
before release, not inside a deployed function.

Google's [Node.js buildpack documentation](https://docs.cloud.google.com/docs/buildpacks/nodejs)
supports selecting npm with `engines.npm`. The inspected
[version selection source](https://github.com/GoogleCloudPlatform/buildpacks/blob/a317bc9857f8b013d19b3de0bc33296b700496dc/pkg/nodejs/npm.go#L80)
reads that field, and the [npm buildpack](https://github.com/GoogleCloudPlatform/buildpacks/blob/a317bc9857f8b013d19b3de0bc33296b700496dc/cmd/nodejs/npm/lib/lib.go#L241)
installs the requested version before dependency installation. Local clean
installs demonstrate compatibility with the pin; they do not establish that
the managed Firebase Cloud Build image used in a future deployment has run it.
Confirm its selected npm version, build, production dependency graph, and
audit in an authorized managed build before release.
