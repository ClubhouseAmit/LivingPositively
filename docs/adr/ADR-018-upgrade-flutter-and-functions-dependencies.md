# ADR-018: Upgrade Flutter and Functions dependencies to latest stable releases

- **Status**: accepted
- **Date**: 2026-10-01
- **Decider**: Dekel (repository owner; accepted 2026-10-01)
- **Issue**: [#391 — Update project dependencies](https://github.com/ClubhouseAmit/LivingPositively/issues/391)
- **Tags**: dependencies, flutter, firebase, functions, typescript, security

## Context

Issue #391 describes older Flutter dependencies and three major upgrades. The
owner expanded the task to all packages in the Flutter application and the
Functions JavaScript project. Functions is authored in TypeScript under
`functions/src/` and compiled to JavaScript under `functions/lib/`.

The issue's inventory is historical. The current manifest already declares
Mockito `^5.8.1`, and Workmanager is absent following the FCM migration in
[ADR-016](ADR-016-rebase-fcm-branch-onto-main-architecture.md). The current
inventory also exposes major upgrades for Google Sign-In, Apple Sign-In,
Cupertino icons, and Functions development tooling. Updating only the packages
named in the issue would leave the expanded task incomplete.

Dependency APIs, platform requirements, compiler versions, and advisory fixes
are volatile. Feature ownership, persisted user data, authentication policy,
notification delivery contracts, and export behavior are stable. Migration
work belongs at existing package consumers and repositories; a package upgrade
does not justify a new layer or a general architecture refactor.

Evidence was collected at repository revision `68d30320` using the manifests,
lockfiles, current imports, CI workflows, `flutter pub outdated --json
--no-prereleases`, and npm registry metadata for every Functions declaration
and override. `npm outdated --json` alone did not expose the full development
inventory in this environment, so each development package was queried too.
The graph at `graphify-out/graph.json` records revision `442a0326`. The
`graphify query` and Python module attempts failed because Graphify is not
installed here; the existing graph was read directly and its relevant file
picker and Firebase relationships checked against current source. Graph
freshness must be restored before implementation.

## Decision

Expand #391 into a coordinated dependency migration with the following scope:

| Area | Scope |
| --- | --- |
| Flutter | Every hosted production and development dependency in `pubspec.yaml`, exact pins, and the resolved transitive graph in `pubspec.lock`. |
| Functions | Every production and development dependency in `functions/package.json`, its overrides, and `functions/package-lock.json`. |
| Supporting JavaScript | The existing root `package.json` Firebase dependency, so it cannot provide an obsolete alternative to the Functions rules-test SDK. |
| Toolchain and CI | SDK/runtime compatibility, generated mocks and localization output when affected, native plugin configuration, and the Firebase CLI pins used to test and deploy Functions. |

### 1. Define latest and reproducibility

For pub packages, target the newest published stable, non-retracted version.
For npm packages, inspect the registry's `latest` tag and confirm it is a
stable release. Include major upgrades and development dependencies. Packages
already at that target satisfy the task without a version change. Replace the
existing file picker beta with a stable release.

Refresh the inventory at implementation start and attach the dated before/after
reports to the implementation PR. The tables below are a planning snapshot,
not permanent pins or proof that installation succeeds.

Raise manifest constraints where necessary, including exact pins such as
`geolocator` and `url_launcher`, and commit each manifest with its lockfile.
Keep existing constraint styles where they permit the target. SDK packages
(`flutter`, `flutter_test`, `integration_test`, `flutter_localizations`) move
with Flutter rather than receiving hosted-package versions.

Resolve transitives to the newest mutually compatible releases. Any gap from a
transitive package's latest stable release must identify the owning parent or
SDK constraint and the available remedy. A direct package blocked below latest
requires a named maintainer decision; do not label the whole upgrade complete
while that decision is outstanding. Do not add overrides, ignore flags,
`--force`, or `--legacy-peer-deps` to disguise incompatibility.

[Pub outdated](https://dart.dev/tools/pub/cmd/pub-outdated) distinguishes
current, upgradable, resolvable, and latest versions.
[Pub upgrade](https://dart.dev/tools/pub/cmd/pub-upgrade) documents that
`--major-versions` selects resolvable versions and changes constraints; it does
not guarantee every registry latest can coexist. Likewise,
[npm update](https://docs.npmjs.com/cli/v11/commands/npm-update/) respects
dependency constraints. Both manifests therefore need explicit comparison
against registry targets after resolution.

### 2. Migrate inside existing boundaries

- Upgrade the Flutter Firebase family and `fake_cloud_firestore` as a compatible
  set, including the explicitly declared `cloud_firestore_web`. Preserve
  Firestore paths/rules, account ownership, and persisted notification keys.
- Migrate Google Sign-In in `lib/features/auth/data/auth_repository.dart` to
  the current singleton and initialization API. Preserve cancellation behavior,
  configured client IDs, existing platform availability, sign-out, and reset.
  The [Google Sign-In changelog](https://pub.dev/packages/google_sign_in/changelog)
  documents the separation of authentication and authorization in version 7;
  use the ID token for the existing Firebase identity flow and request extra
  authorization only if an existing consumer requires it. Keep the repository's
  public methods stable and adapt its test seam to the upstream API internally.
- Apple sign-in currently uses Firebase's `AppleAuthProvider`; no direct Dart
  import of `sign_in_with_apple` was found. Upgrade the declared plugin and
  validate its native requirements without substituting an authentication flow.
- Migrate file selection/save behavior at
  `lib/features/feel_good/data/image_picker_repository.dart` and
  `lib/util/async/file_service.dart`, including their existing test seams.
  Preserve cancellation, destination handling, exported bytes, and RTL titles.
- Audit native configuration for notifications, contacts, location, speech,
  scanning, sharing, and image selection against each target's changelog.
  Preserve the existing permission and foreground/background behavior.
- No current imports were found for `googleapis` or `device_preview`; upgrade
  their declarations and validate resolution/builds without inventing consumers.
- Upgrade `very_good_analysis` and fix newly enabled diagnostics in affected
  code. Preserve the existing analysis baseline and guideline ratchets; new
  suppressions or disabled rules require the stop procedure in `AGENTS.md`.
  Regenerate Mockito output if its generator or analyzer changes.
- Advance `printing` to the latest stable release while retaining the fixed,
  display-only preview scope in [ADR-014](ADR-014-mood-medicine-pdf-preview-dependency.md).
  Acceptance of this ADR replaces ADR-014's version restriction only for this
  upgrade; it does not expand the plugin's feature scope.

All Dart edits obey section 0, including file/method length and frozen-tree
rules. If an upstream migration requires changing a public method with callers
outside its feature, adding a package to `pubspec.yaml`, or suppressing a check,
stop for the specific approval required by `AGENTS.md` 0.7.

### 3. Resolve Functions tooling and overrides deliberately

Upgrade `firebase-admin`, `firebase-functions`, the rules-testing package, and
TypeScript, then regenerate the Functions lockfile and compiled JavaScript.
Keep the existing NodeNext module configuration unless the target compiler
requires a documented adjustment. Verify compiler output remains executable
under the deployed runtime; type checking alone is insufficient.

The latest TypeScript is `7.0.2`, while the latest typescript-eslint parser and
plugin (`8.71.0`) declare TypeScript `>=4.8.4 <6.1.0`. These targets cannot form
a supported latest-version toolchain together. No ESLint configuration, lint
script, or CI invocation was found in this repository. The proposed resolution
is to confirm there are no external consumers, then remove those two unused
development declarations and their orphaned transitives, allowing TypeScript
7 to be evaluated without an unused peer restriction. If a consumer exists,
retain the tooling and obtain a maintainer decision on a supported version set;
that is an explicit exception to the all-latest objective. Do not silently
freeze TypeScript or install an unsupported peer combination.

The `@google-cloud/storage` and `uuid` overrides are documented security fixes
in `functions/SECURITY.md`. First test whether updated parent packages supply
patched versions without the overrides. Remove an override only with dependency
tree and audit evidence. If still needed, scope it to the affected parent and
use a compatible patched release; forcing UUID 14 across every consumer is not
an acceptable interpretation of upgrading all packages. Update the security
document with the resulting rationale.

`functions/src/firestore_rules.test.ts` imports `firebase/firestore` directly.
Its local lockfile currently supplies Firebase `12.19.0` as a peer dependency,
whereas root `package.json` declares `^10.8.1`. Upgrade that existing root
declaration and make the Functions test install reproducible from its own
lockfile. Demonstrate rules tests work without root `node_modules`; if an
explicit Functions development dependency is needed, record that addition in
the implementation PR instead of relying on accidental parent resolution.

### 4. Align tools with supported platforms

The current application and CI use Flutter `3.47.5`; the local Dart version is
`3.13.4`. Evaluate whether targets require a newer stable SDK and change all
active Flutter CI pins together if they do. Preserve the native compatibility
decision in [ADR-012](ADR-012-temporary-api-37-android-toolchain.md); changes to
its Kotlin flags or platform minimums need a documented reason and review.

Functions declares Node `22`, and both backend workflows use Node `22`.
Retain that common supported runtime while targets support it. Local Node
`24.15.0` is not evidence of deployment compatibility. Confirm Firebase runtime
support before proposing any runtime change and update the engine, testing,
and release jobs together. Firebase describes this contract in
[Manage functions](https://firebase.google.com/docs/functions/manage-functions).

Upgrade the Firebase CLI currently pinned to `15.29.0` in backend quality and
release workflows to the same validated latest stable version. This scope
includes npm/pub packages and necessary tool compatibility; arbitrary Gradle,
Kotlin, or GitHub Action upgrades are separate decisions unless required by a
package migration.

## Implementation sequence

1. Refresh Graphify and both complete dependency inventories, including dev
   dependencies and transitive constraints. Capture the current tool versions
   and baseline checks before changing dependencies.
2. Resolve the TypeScript/unused-lint-tooling decision. Upgrade Functions and
   the supporting root Firebase declaration, reassess overrides, and validate
   under Node 22 before coordinating Firebase CLI pins.
3. Upgrade compatible Flutter packages as a first batch. Then migrate majors
   in small batches, keeping Firebase/authentication, file picker/export, and
   analysis/generation changes independently understandable and reversible.
   Inspect `flutter pub upgrade --major-versions --dry-run` before using it;
   explicitly retain stable Sentry targets if the resolver offers a release
   candidate.
4. Regenerate affected artifacts, validate native builds and existing behavior,
   and refresh both inventories. Attach remaining constraints and their
   decisions to the PR. Record final exact versions in the lockfiles.
5. Obtain a dedicated review in a fresh agent context under `AGENTS.md` 7.1.
   Merge and release through the existing quality and production gates.

## Acceptance and release

The implementation is complete only when every retained direct dependency is
at the dated latest stable target or has an explicit maintainer-approved
exception, transitive gaps have evidence, manifests/lockfiles are reproducible,
and the following checks pass with quoted output in the implementation PR:

```sh
# Repository root
tool/check_guidelines.sh
flutter analyze
flutter test

# Functions, using the same Node 22 runtime as CI
cd functions
npm ci
npm ls --all
npm test
npm run test:rules
npm audit --omit=dev --audit-level=low
```

Run `npm outdated --include=dev --json` and query every declaration's latest
registry version again; outdated reports alone may omit relevant packages.
Also review the complete development audit and document any unresolved
advisory. Production audit acceptance follows `functions/SECURITY.md` and may
not be weakened by this migration.

Existing CI deployment-guard tests, Firestore collection-policy checks, and
iOS Google Sign-In configuration tests must remain green. Use the existing
Android and iOS build/integration jobs and coverage gate. Compile web to catch
federated-plugin regressions even though the web workflow is disabled; record
that disabled workflow rather than claiming it ran. Native/runtime validation
must cover authentication and cancellation, FCM token registration and scheduled
delivery, mutation fencing, account reset, file saving/sharing, PDF preview,
and persistence recovery. Use targeted regression tests for API migrations.

Functions manifest or lockfile changes are deployment inputs in
`scripts/functions_deployment_changes.mjs`; even development dependency edits
can trigger a production release. Preserve that guard and use the existing
`firebase-production` environment approval. Validate backend compatibility with
the currently released client before app rollout. Endpoint names, payloads,
Firestore policy, and notification mutation semantics remain compatible.

Keep dependency batches revertible together with their manifests, lockfiles,
and consumer migrations. Before release, retain a known-good tested revision.
If backend regression occurs, restore and redeploy that revision through the
same production gate; do not rely on reverting an app rollout to repair a
deployed backend. No data migration is planned by this dependency decision.

## Alternatives and consequences

- Updating only issue-listed Flutter packages fails the expanded scope.
- Running plain `pub upgrade`/`npm update` alone leaves major constraints and
  exact pins unchanged and cannot establish the all-latest result.
- A single unexamined upgrade batch makes peer, platform, and behavior failures
  harder to isolate; staged implementation retains one coordinated outcome.
- Forced transitive majors can break upstream consumers despite a clean audit.
  Prefer patched parents, with evidence for any retained security override.
- The expanded migration adds authentication, compiler, native-plugin, and CI
  work. It yields current supported packages and reproducible installs while
  retaining the existing feature and external contracts.
- The owner accepted this resolution on 2026-10-01 and authorized implementation
  through Ruflo/SPARC, using the existing CI pipeline for macOS validation.
  Acceptance does not certify that the target set resolves or release checks pass.

## Dated target inventory

Snapshot: **2026-10-01**. Flutter rows list every outdated hosted direct or
development dependency reported locally; all other declarations are still in
scope and must be checked at implementation time. Current means locked version,
not the manifest's lower bound. Registry links support the dated targets.

| Flutter package | Current | Latest stable target |
| --- | --- | --- |
| [build_runner](https://pub.dev/packages/build_runner) | 2.15.1 | 2.16.1 |
| [cloud_firestore](https://pub.dev/packages/cloud_firestore) | 6.8.0 | 6.10.0 |
| [cloud_firestore_web](https://pub.dev/packages/cloud_firestore_web) | 5.7.2 | 5.7.3 |
| [cupertino_icons](https://pub.dev/packages/cupertino_icons) | 1.0.9 | 2.0.0 |
| [device_preview](https://pub.dev/packages/device_preview) | 1.3.1 | 3.0.0 |
| [devicelocale](https://pub.dev/packages/devicelocale) | 0.9.0 | 0.9.1 |
| [fake_cloud_firestore](https://pub.dev/packages/fake_cloud_firestore) | 4.2.0 | 4.3.0 |
| [file_picker](https://pub.dev/packages/file_picker) | 12.0.0-beta.7 | 13.1.0 |
| [firebase_auth](https://pub.dev/packages/firebase_auth) | 6.5.7 | 6.7.0 |
| [firebase_core](https://pub.dev/packages/firebase_core) | 4.13.0 | 4.15.0 |
| [firebase_database](https://pub.dev/packages/firebase_database) | 12.4.7 | 12.6.0 |
| [firebase_messaging](https://pub.dev/packages/firebase_messaging) | 16.5.0 | 16.7.0 |
| [flutter_contacts](https://pub.dev/packages/flutter_contacts) | 2.3.1 | 2.5.0 |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | 22.2.0 | 22.3.1 |
| [geolocator](https://pub.dev/packages/geolocator) | 14.0.2 | 14.1.1 |
| [get_it](https://pub.dev/packages/get_it) | 9.2.1 | 9.3.0 |
| [google_sign_in](https://pub.dev/packages/google_sign_in) | 6.3.0 | 7.2.0 |
| [googleapis](https://pub.dev/packages/googleapis) | 16.0.0 | 17.0.0 |
| [googleapis_auth](https://pub.dev/packages/googleapis_auth) | 2.3.3 | 2.3.4 |
| [mixpanel_flutter](https://pub.dev/packages/mixpanel_flutter) | 2.13.0 | 2.14.0 |
| [mobile_scanner](https://pub.dev/packages/mobile_scanner) | 7.4.0 | 7.4.2 |
| [pdf](https://pub.dev/packages/pdf) | 3.13.0 | 3.13.1 |
| [permission_handler](https://pub.dev/packages/permission_handler) | 13.0.0 | 13.0.2 |
| [printing](https://pub.dev/packages/printing) | 5.15.0 | 5.15.1 |
| [sentry_flutter](https://pub.dev/packages/sentry_flutter) | 9.20.0 | 9.30.1 |
| [sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple) | 6.1.4 | 8.2.0 |
| [speech_to_text](https://pub.dev/packages/speech_to_text) | 7.4.0 | 7.5.0 |
| [upgrader](https://pub.dev/packages/upgrader) | 13.6.0 | 13.7.0 |
| [very_good_analysis](https://pub.dev/packages/very_good_analysis) | 10.3.0 | 11.0.0 |

The local report offered Sentry `10.0.0-rc.1` in its resolvable column even
with `--no-prereleases`; its latest stable column was `9.30.1`. Select stable
explicitly. Reported transitive gaps include `cross_file`, `dbus`, `equatable`,
`file_picker_linux`, `gsettings`, `jni`, `material_color_utilities`,
`pointycastle`, `qr`, `test_api`, and `xml`. Re-evaluate after major migrations
and identify each owning constraint rather than forcing registry majors.

| Functions/supporting package | Current | Latest target or disposition |
| --- | --- | --- |
| [firebase-admin](https://registry.npmjs.org/firebase-admin/latest) | 14.3.0 | 14.5.0 |
| [firebase-functions](https://registry.npmjs.org/firebase-functions/latest) | 7.3.2 | 7.4.0 |
| [@firebase/rules-unit-testing](https://registry.npmjs.org/@firebase%2Frules-unit-testing/latest) | 5.0.2 | 5.0.2; already current |
| [typescript](https://registry.npmjs.org/typescript/latest) | 6.0.3 | 7.0.2; migrate compiler |
| [@typescript-eslint/eslint-plugin](https://registry.npmjs.org/@typescript-eslint%2Feslint-plugin/latest) | 5.62.0 | 8.71.0; proposed removal if confirmed unused |
| [@typescript-eslint/parser](https://registry.npmjs.org/@typescript-eslint%2Fparser/latest) | 5.62.0 | 8.71.0; proposed removal if confirmed unused |
| [@google-cloud/storage](https://registry.npmjs.org/@google-cloud%2Fstorage/latest), override | 8.0.1 | 8.2.0; reassess owning parent and override |
| [uuid](https://registry.npmjs.org/uuid/latest), override | 11.1.1 | 14.0.2; use patched parent-compatible resolution |
| [firebase](https://registry.npmjs.org/firebase/latest), root declaration | ^10.8.1; no root lockfile | 12.19.0; Functions peer already locks this version |
| [firebase-tools](https://registry.npmjs.org/firebase-tools/latest), CI pin | 15.29.0 | 15.32.1; coordinate test and deployment pins |

## Implementation evidence

The owner accepted this decision on 2026-10-01 and authorized Ruflo/SPARC implementation. See the [dated implementation inventory and validation evidence](../plans/2026-10-01-issue-391-dependency-upgrade.md) for the resulting package graphs, migrations, independent review, and macOS CI artifact. Graphify was installed and its graph refreshed before implementation.

## Record numbering

When integrating main on 2026-10-01, this record was renumbered from ADR-017 to ADR-018 because main introduced ADR-017 for reminder settings. The accepted dependency-upgrade decision is unchanged.
