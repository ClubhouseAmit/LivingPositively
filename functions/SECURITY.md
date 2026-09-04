# Cloud Functions dependency security

The Functions workflow requires a clean production dependency audit:

```sh
npm audit --omit=dev --audit-level=low
```

The lockfile pins compatible `@google-cloud/storage` and `uuid` overrides to
resolve the former transitive UUID advisory. Re-run the command whenever the
Functions lockfile changes; do not add an advisory acceptance without an
explicit maintainer decision and an expiry date.
