# Cloud Functions dependency security

The Functions workflow requires a clean production dependency audit:

```sh
npm audit --omit=dev --audit-level=low
```

The dependency review on 2026-10-01 upgraded Firebase Admin to 14.5.0 and
Firebase Functions to 7.4.0. Admin now resolves `@google-cloud/storage` 8.2.0
through its own `^8.1.0` requirement, so the former storage override is removed.

Two scoped security overrides remain:

- Storage 8.2.0 uses Gaxios 6.7.1, which requires UUID `^9.0.1`. Override only
  that consumer to UUID 11.1.1, the final CommonJS-compatible release with the
  [buffer bounds fix](https://github.com/advisories/GHSA-w5hq-g745-h8pq).
  Gaxios uses the supported `require('uuid').v4()` API for multipart boundaries;
  forcing the ESM-only UUID 14 into it would change its runtime contract.
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
