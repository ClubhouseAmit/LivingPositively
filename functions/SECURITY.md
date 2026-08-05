# Cloud Functions dependency security

## Accepted residual advisory

- **Owner:** `ClubhouseAmit/LivingPositively` maintainers
- **Last reviewed:** 2026-08-05
- **Next review:** 2026-09-05, or earlier when a recheck trigger below occurs
- **Advisory:** `GHSA-w5hq-g745-h8pq` (`uuid < 11.1.1`, moderate)

`npm audit --omit=dev` currently reports seven moderate findings that all
trace to `uuid@9.0.1` through Firebase Admin's optional
`@google-cloud/storage` dependency (`gaxios` and `teeny-request`). The advisory
concerns the UUID v3/v5/v6 API when a caller supplies an output buffer.

The Functions source does not import or use `@google-cloud/storage` or `uuid`,
and does not invoke the vulnerable UUID API with a caller-provided buffer. The
affected transitive code is therefore not reachable through the deployed
Functions behavior currently in this repository.

At the review date, the compatible current pair is
`firebase-admin@14.2.0` with `firebase-functions@7.3.2`. npm offers no
non-breaking remediation for this chain: `npm audit fix --force` proposes
downgrading Firebase Admin to `10.3.0`. That downgrade is incompatible with the
approved Admin 14 / Functions 7 runtime upgrade and is not an acceptable
security fix.

CI remains blocking for high and critical production findings with
`npm audit --omit=dev --audit-level=high`. Recheck this acceptance whenever:

- Firebase Admin, Firebase Functions, or `@google-cloud/storage` publishes a
  release that can resolve the advisory;
- the Functions dependency lockfile changes;
- Functions source begins using Cloud Storage or `uuid`; or
- the advisory severity, exploitability, or affected API changes.
