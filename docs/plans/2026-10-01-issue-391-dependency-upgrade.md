# Issue #391: dependency upgrade implementation evidence

Date: 2026-10-01. Accepted decision: [ADR-018](../adr/ADR-018-upgrade-flutter-and-functions-dependencies.md).
Baseline: `68d30320`. Branch: `Tovli/adr-upgrade-flutter-functions`.

## SPARC execution

| Phase | Result |
| --- | --- |
| Specification | Owner accepted ADR-018 and expanded scope to every Flutter and Functions package, supporting root Firebase, and required CI tooling. |
| Pseudocode | Inventory stable targets; resolve compatible graphs; migrate current consumers; regenerate artifacts; test; independently review; import macOS lockfile; run PR CI. |
| Architecture | Existing feature boundaries and external APIs retained. Auth owns the identity API migration; Functions owns its TypeScript runtime and data contracts. |
| Refinement | Separate Ruflo-tracked Functions, auth, and Flutter compatibility agents implemented and validated their owned changes. |
| Completion | Full local checks passed. The fresh-context reviewer confirmed both findings resolved, including provider cleanup/logout coupling and native lock regeneration. Normal PR platform CI remains the final validation stage. |

Ruflo swarm: `swarm-1790828261782-j88sgg`; task: `task-1790828283752-9upl9d`. The Ruflo agent registry tracks execution; Codex collaboration agents execute the implementation and independent review.

## Implemented changes

- All 58 hosted Flutter production/development declarations resolve to the dated latest stable target. The resolved graph changed 113 dependencies, including federated file-picker implementations.
- Google Sign-In 7 initializes its singleton once, shares concurrent initialization, uses Firebase ID-token credentials, and maps cancellation to the existing null result. Public signatures and platform/client-ID policy are preserved. Google cleanup and diagnostic failures cannot block Firebase logout; Firebase logout failures still propagate.
- Generated ten Mockito outputs for the updated FirebaseAuth API, including `migrateCurrentUser`. Flutter tooling also regenerated localization output without a semantic diff.
- Functions uses Firebase Admin 14.5.0, Firebase Functions 7.4.0, TypeScript 7.0.2, and explicit development Firebase 12.19.0 for its rules tests. Root Firebase is also 12.19.0 with a new reproducible lockfile.
- Confirmed unused typescript-eslint parser/plugin declarations and their orphan config were removed. Their latest release still excludes TypeScript 7.
- Security overrides now target only their affected parents. Storage resolves 8.2.0 naturally; its Gaxios consumer receives CommonJS UUID 11.1.1 through an immediate-parent override compatible with both npm 10 and npm 11. Firebase Firestore receives patched grpc-js 1.14.5. See [Functions security rationale](../../functions/SECURITY.md).
- Firebase CLI testing and release pins move together to 15.32.1. Node 22 remains the deployment and test runtime.
- very_good_analysis is upgraded to 11.0.0 while `analysis_options.yaml` retains its deliberately versioned 10.3 lint profile and existing baseline. No new suppression or disabled rule was introduced. Trying the 11.0 profile exposed unrelated repository-wide policy debt; that additional policy migration is outside this dependency update.
- Current native requirements are already met: Android minSdk 24 through Flutter 3.47, iOS target 16. The existing iOS CI retains CocoaPods deployment verification; a manual macOS lock-refresh job generates the updated lockfile artifact.

## Local validation

| Command / check | Observed output |
| --- | --- |
| `flutter analyze` | `No issues found! (ran in 18.3s)` |
| `flutter test` after review correction | `00:52 +1832 ~6: All tests passed!` |
| `flutter build web --no-pub` | `Built build\web`; WASM dry run succeeded |
| Non-auth export/image/notification regressions | `00:08 +115: All tests passed!` |
| Auth migration regressions after review correction | `00:03 +47: All tests passed!` |
| `dart run build_runner build` | `Built with build_runner/aot in 58s; wrote 10 outputs.` |
| Functions `npm ci` and `npm ls --all`, Node 22.23.2/22.23.3, npm 10.9.8/11.14.0 | Both exit 0; 310 installed packages; no invalid/required missing peers |
| Functions `npm test`, TypeScript 7.0.2 | `tests 86`, `pass 86`, `fail 0` |
| Functions `npm run test:rules`, CLI 15.32.1 | `tests 47`, `pass 47`, `fail 0`; root node_modules absent during this run |
| Functions production and complete development audits | `found 0 vulnerabilities` |
| Root `npm ci`, `npm ls --all`, complete audit | All exit 0; `found 0 vulnerabilities` |
| Both JavaScript direct outdated reports | `{}` |
| Deployment, rules drift, and collection policy script regressions | `tests 51`, `pass 51`, `fail 0` |
| iOS Google Sign-In configuration shell regression | Exit 0 |
| Independent source review | Both findings resolved; no new findings; all 12 resulting Dart files pass section 0 |

Local Functions rules validation used Java 22.0.1 / emulator 1.22.0. CI continues to validate its JDK 21 environment. Platform-inapplicable optional TypeScript native packages are allowed to remain absent by npm.

The default guideline check and every changed Dart file each report:

```text
check_guidelines: 1 file(s) scanned, 0 generated localization file(s) exempt, 0 violations (limits: file 400, method 80, closure indent 6)
```

`git diff --check` also passes. Deployment script fixtures expect LF checkout files; the local workflow checkout was normalized to LF without a content change before the successful 51-test run.

## macOS and PR CI

[macOS lockfile refresh run](https://github.com/ClubhouseAmit/LivingPositively/actions/runs/36815392143) runs `pod update --repo-update` on macos-15 with Flutter 3.47.5, then uploads `ios-podfile-lock`. The run succeeded, and artifact `11141571346` was imported into `ios/Podfile.lock`. The independent reviewer downloaded the artifact separately and confirmed its SHA-256 matches the repository file. Native dependencies now include Firebase 12.19.0, GoogleSignIn 9.2.0, Sentry 8.58.4, and file_picker_darwin 1.0.0. This manual refresh runs no production deployment and skips the simulator job; ordinary reusable integration continues to use `pod install --deployment`.

[Draft PR #420](https://github.com/ClubhouseAmit/LivingPositively/pull/420) runs the existing platform pipeline. The first run found npm 10.9.8 discarding the ancestor-scoped UUID override after shared Gaxios hoisting. Moving the override to the immediate Gaxios parent fixes clean installation without changing the resolved lockfile; both npm toolchains are explicitly checked. Code quality, inventory, iOS deployment-mode CocoaPods installation, and simulator boot passed that run. Final native build/runtime verification remains pending the corrected PR run. Check the iOS simulator test step outcome directly: this repository intentionally marks its telemetry test step as continue-on-error, so a green aggregate job alone cannot prove the simulator test passed.

## Flutter direct/development inventory

All retained hosted declarations were queried directly through pub.dev metadata and compared with `pubspec.lock`; SDK packages are managed by Flutter. Versions here are locked versions, not old manifest lower bounds.

| Package | Before | After / latest stable |
| --- | --- | --- |
| `encrypt` | 5.0.3 | 5.0.3 |
| `shared_preferences` | 2.5.5 | 2.5.5 |
| `url_launcher` | 6.3.2 | 6.3.2 |
| `permission_handler` | 13.0.0 | 13.0.2 |
| `speech_to_text` | 7.4.0 | 7.5.0 |
| `geolocator` | 14.0.2 | 14.1.1 |
| `flutter_local_notifications` | 22.2.0 | 22.3.1 |
| `pdf` | 3.13.0 | 3.13.1 |
| `printing` | 5.15.0 | 5.15.1 |
| `path_provider` | 2.1.6 | 2.1.6 |
| `cupertino_icons` | 1.0.9 | 2.0.0 |
| `mixpanel_flutter` | 2.13.0 | 2.14.0 |
| `getwidget` | 7.0.2 | 7.0.2 |
| `fluttericon` | 2.0.0 | 2.0.0 |
| `dotted_border` | 3.1.0 | 3.1.0 |
| `keyboard_dismisser` | 3.0.0 | 3.0.0 |
| `provider` | 6.1.5+1 | 6.1.5+1 |
| `cloud_firestore` | 6.8.0 | 6.10.0 |
| `firebase_core` | 4.13.0 | 4.15.0 |
| `cloud_firestore_web` | 5.7.2 | 5.7.3 |
| `fluttertoast` | 10.0.0 | 10.0.0 |
| `firebase_auth` | 6.5.7 | 6.7.0 |
| `firebase_messaging` | 16.5.0 | 16.7.0 |
| `font_awesome_flutter` | 11.0.0 | 11.0.0 |
| `share_plus` | 13.3.0 | 13.3.0 |
| `flutter_screenutil` | 5.9.3 | 5.9.3 |
| `auto_size_text` | 3.0.0 | 3.0.0 |
| `image_picker` | 1.2.3 | 1.2.3 |
| `youtube_player_flutter` | 10.0.1 | 10.0.1 |
| `url_launcher_platform_interface` | 2.3.2 | 2.3.2 |
| `uuid` | 4.6.0 | 4.6.0 |
| `qr_flutter` | 4.1.0 | 4.1.0 |
| `mobile_scanner` | 7.4.0 | 7.4.2 |
| `firebase_database` | 12.4.7 | 12.6.0 |
| `file_picker` | 12.0.0-beta.7 | 13.1.0 |
| `googleapis` | 16.0.0 | 17.0.0 |
| `googleapis_auth` | 2.3.3 | 2.3.4 |
| `http` | 1.6.0 | 1.6.0 |
| `get_it` | 9.2.1 | 9.3.0 |
| `sentry_flutter` | 9.20.0 | 9.30.1 |
| `device_preview` | 1.3.1 | 3.0.0 |
| `flutter_timezone` | 5.1.0 | 5.1.0 |
| `numberpicker` | 2.1.2 | 2.1.2 |
| `flutter_contacts` | 2.3.1 | 2.5.0 |
| `intl` | 0.20.3 | 0.20.3 |
| `language_code` | 0.7.1 | 0.7.1 |
| `devicelocale` | 0.9.0 | 0.9.1 |
| `upgrader` | 13.6.0 | 13.7.0 |
| `country_code_picker` | 3.4.1 | 3.4.1 |
| `flutter_svg` | 2.3.0 | 2.3.0 |
| `google_sign_in` | 6.3.0 | 7.2.0 |
| `sign_in_with_apple` | 6.1.4 | 8.2.0 |
| `mockito` | 5.8.1 | 5.8.1 |
| `mocktail` | 1.0.5 | 1.0.5 |
| `build_runner` | 2.15.1 | 2.16.1 |
| `flutter_lints` | 6.0.0 | 6.0.0 |
| `fake_cloud_firestore` | 4.2.0 | 4.3.0 |
| `very_good_analysis` | 10.3.0 | 11.0.0 |

## Functions and supporting JavaScript inventory

| Package | Before | After | Disposition |
| --- | --- | --- | --- |
| `firebase-admin` | 14.3.0 | 14.5.0 | latest stable on 2026-10-01 |
| `firebase-functions` | 7.3.2 | 7.4.0 | latest stable on 2026-10-01 |
| `@firebase/rules-unit-testing` | 5.0.2 | 5.0.2 | latest stable on 2026-10-01 |
| `firebase` | 12.19.0 | 12.19.0 | peer before; now explicit dev dependency; latest stable on 2026-10-01 |
| `typescript` | 6.0.3 | 7.0.2 | latest stable on 2026-10-01 |
| `@typescript-eslint/eslint-plugin` | 5.62.0 | removed | removed unused lint tooling |
| `@typescript-eslint/parser` | 5.62.0 | removed | removed unused lint tooling |
| Root Firebase | ^10.8.1, no root lockfile | 12.19.0 | latest stable; root lockfile now tracked |
| Firebase CLI | 15.29.0 | 15.32.1 | coordinated backend test/release pin |

## Flutter transitive constraints

Every retained direct package is current. The following 13 transitive gaps require owning-parent or stable-SDK changes. No transitive override was added to Flutter to bypass their API constraints.

| Package | Resolved | Registry latest stable | Owning constraint and remedy |
| --- | --- | --- | --- |
| `cross_file` | 0.3.5+5 | 0.4.0 | File picker, share_plus, and image/file selectors require ^0.3.x; wait for those parents to adopt 0.4. |
| `dbus` | 0.7.15 | 0.8.0 | geolocator_linux/geoclue and flutter_local_notifications_linux require ^0.7.x; wait for parent updates. |
| `equatable` | 2.1.0 | 3.0.0 | fake_cloud_firestore, rules emulator, flutter_timezone, and cel require ^2.x; wait for parent updates. |
| `file_picker_linux` | 2.0.0 | 2.0.1 | 2.0.1 requires dbus ^0.8.0, conflicting with the Linux location/notifications graph. |
| `gsettings` | 0.2.8 | 0.2.9 | 0.2.9 requires dbus ^0.8.0, conflicting with the Linux location/notifications graph. |
| `jni` | 0.14.2 | 1.1.0 | Stable sentry_flutter 9.30.1 pins jni 0.14.2; wait for a stable Sentry parent supporting JNI 1.x. |
| `material_color_utilities` | 0.13.0 | 0.13.1 | Flutter SDK pins 0.13.0; upgrade only through a stable SDK adopting the new version. |
| `package_config` | 2.2.0 | 3.0.0 | The Sentry-pinned jni 0.14.2 requires ^2.1.0; wait for the stable Sentry/JNI migration. |
| `path_provider_android` | 2.2.23 | 2.3.1 | 2.3.1 requires jni ^1.0.0; conflicts with the stable Sentry JNI pin. |
| `pointycastle` | 3.9.1 | 4.0.0 | encrypt 5.0.3 requires ^3.6.2; wait for encrypt to support 4.x. |
| `qr` | 3.0.2 | 4.0.0 | qr_flutter and barcode require ^3.x; wait for supported parent upgrades. |
| `test_api` | 0.7.12 | 0.7.14 | Flutter test SDK pins 0.7.12; upgrade through the stable Flutter SDK. |
| `xml` | 7.0.1 | 7.1.0 | vector_graphics_compiler caps xml at <=7.0.1; wait for its supported parent update. |

## JavaScript transitive registry differences

`npm update` refreshed compatible transitives. Remaining registry differences are constrained by upstream parent declarations and scoped security patches; registry latest may also be lower than a parent-selected version. These do not imply a direct package is outdated. Parent declarations below are the evidence and identify where a future fix must occur. Use a supported updated parent when available; retain API-compatible patched consumers until then.

| Package | Installed | Registry latest | Parent constraints |
| --- | --- | --- | --- |
| `@google-cloud/firestore-api` | 0.2.0 | 0.6.0 | `@google-cloud/firestore@9.3.0: ^0.2.0` |
| `@grpc/proto-loader` | 0.7.15 | 0.8.1 | `@firebase/firestore@4.17.2: ^0.7.8` |
| `@isaacs/cliui` | 8.0.2 | 9.0.0 | `jackspeak@3.4.3: ^8.0.2` |
| `accepts` | 2.0.0 | 1.3.8 | `express@5.2.1: ^2.0.0` |
| `agent-base` | 7.1.4 | 9.0.0 | `http-proxy-agent@7.0.2: ^7.1.0`; `https-proxy-agent@7.0.6: ^7.1.2` |
| `ansi-regex` | 5.0.1 | 6.4.0 | `strip-ansi-cjs@6.0.1: ^5.0.1`; `strip-ansi@6.0.1: ^5.0.1`; `strip-ansi@7.2.0: ^6.2.2` |
| `ansi-styles` | 4.3.0 | 7.0.0 | `wrap-ansi-cjs@7.0.0: ^4.0.0`; `wrap-ansi@7.0.0: ^4.0.0`; `wrap-ansi@8.1.0: ^6.1.0` |
| `ansi-styles` | 6.2.3 | 7.0.0 | `wrap-ansi@7.0.0: ^4.0.0`; `wrap-ansi@8.1.0: ^6.1.0` |
| `balanced-match` | 1.0.2 | 4.0.4 | `brace-expansion@2.1.7: ^1.0.0` |
| `bignumber.js` | 9.3.1 | 11.1.5 | `json-bigint@1.0.0: ^9.0.0` |
| `brace-expansion` | 2.1.7 | 5.0.12 | `minimatch@9.0.9: ^2.0.2` |
| `cliui` | 8.0.1 | 9.0.1 | `yargs@17.7.3: ^8.0.1` |
| `color-convert` | 2.0.1 | 3.1.3 | `ansi-styles@4.3.0: ^2.0.1` |
| `color-name` | 1.1.4 | 2.1.1 | `color-convert@2.0.1: ~1.1.4` |
| `content-disposition` | 1.1.0 | 3.0.0 | `express@5.2.1: ^1.0.0` |
| `content-type` | 1.0.5 | 3.1.1 | `express@5.2.1: ^1.0.5` |
| `content-type` | 2.1.0 | 3.1.1 | `body-parser@2.3.0: ^2.0.0`; `negotiator@1.1.0: ^2.1.0`; `type-is@2.1.0: ^2.0.0` |
| `cookie` | 0.7.2 | 2.0.1 | `express@5.2.1: ^0.7.1` |
| `data-uri-to-buffer` | 4.0.1 | 8.0.0 | `node-fetch@3.3.2: ^4.0.0` |
| `eastasianwidth` | 0.2.0 | 0.3.0 | `string-width@5.1.2: ^0.2.0` |
| `emoji-regex` | 8.0.0 | 11.0.0 | `string-width-cjs@4.2.3: ^8.0.0`; `string-width@4.2.3: ^8.0.0`; `string-width@5.1.2: ^9.2.2` |
| `emoji-regex` | 9.2.2 | 11.0.0 | `string-width@4.2.3: ^8.0.0`; `string-width@5.1.2: ^9.2.2` |
| `event-target-shim` | 5.0.1 | 6.0.2 | `abort-controller@3.0.0: ^5.0.0` |
| `fetch-blob` | 3.2.0 | 4.0.0 | `formdata-polyfill@4.0.10: ^3.1.2`; `node-fetch@3.3.2: ^3.1.4` |
| `foreground-child` | 3.3.1 | 4.0.3 | `glob@10.5.0: ^3.1.0` |
| `fresh` | 2.0.0 | 0.5.2 | `express@5.2.1: ^2.0.0`; `send@1.2.1: ^2.0.0` |
| `gaxios` | 6.7.1 | 8.1.0 | `@google-cloud/storage@8.2.0: ^6.0.2`; `gcp-metadata@6.1.1: ^6.1.1`; `gcp-metadata@8.1.4: 7.1.3`; `gcp-metadata@9.0.4: ^7.1.3`; `google-auth-library@10.5.0: ^7.0.0`; `google-auth-library@11.1.0: ^7.1.4`; `google-auth-library@9.15.1: ^6.1.1`; `gtoken@7.1.0: ^6.0.0`; `gtoken@8.0.0: ^7.0.0` |
| `gaxios` | 7.1.3 | 8.1.0 | `gcp-metadata@6.1.1: ^6.1.1`; `gcp-metadata@8.1.4: 7.1.3`; `gcp-metadata@9.0.4: ^7.1.3` |
| `gaxios` | 7.3.1 | 8.1.0 | `gcp-metadata@6.1.1: ^6.1.1`; `gcp-metadata@8.1.4: 7.1.3`; `gcp-metadata@9.0.4: ^7.1.3`; `google-auth-library@10.5.0: ^7.0.0`; `google-auth-library@11.1.0: ^7.1.4`; `google-auth-library@9.15.1: ^6.1.1`; `gtoken@7.1.0: ^6.0.0`; `gtoken@8.0.0: ^7.0.0` |
| `gcp-metadata` | 6.1.1 | 9.0.4 | `google-auth-library@10.5.0: ^8.0.0`; `google-auth-library@11.1.0: ^9.0.0`; `google-auth-library@9.15.1: ^6.1.0` |
| `gcp-metadata` | 8.1.4 | 9.0.4 | `google-auth-library@10.5.0: ^8.0.0`; `google-auth-library@11.1.0: ^9.0.0`; `google-auth-library@9.15.1: ^6.1.0` |
| `glob` | 10.5.0 | 13.0.6 | `rimraf@5.0.10: ^10.3.7` |
| `google-auth-library` | 10.5.0 | 11.1.0 | `google-gax@5.0.8: 10.5.0`; `google-gax@6.10.0: ^11.0.0` |
| `google-auth-library` | 9.15.1 | 11.1.0 | `@google-cloud/storage@8.2.0: ^9.6.3` |
| `google-gax` | 5.0.8 | 6.10.0 | `@google-cloud/firestore-api@0.2.0: ^5.0.0` |
| `google-logging-utils` | 0.0.2 | 2.0.1 | `gcp-metadata@6.1.1: ^0.0.2`; `gcp-metadata@8.1.4: 1.1.3`; `gcp-metadata@9.0.4: ^2.0.0` |
| `google-logging-utils` | 1.1.3 | 2.0.1 | `gcp-metadata@6.1.1: ^0.0.2`; `gcp-metadata@8.1.4: 1.1.3`; `gcp-metadata@9.0.4: ^2.0.0`; `google-auth-library@10.5.0: ^1.0.0`; `google-auth-library@11.1.0: ^2.0.0`; `google-gax@5.0.8: 1.1.3`; `google-gax@6.10.0: ^2.0.0` |
| `gtoken` | 7.1.0 | 8.0.0 | `google-auth-library@10.5.0: ^8.0.0`; `google-auth-library@9.15.1: ^7.0.0` |
| `http-proxy-agent` | 7.0.2 | 9.1.0 | `teeny-request@10.1.4: ^7.0.0`; `teeny-request@11.0.1: ^7.0.0` |
| `https-proxy-agent` | 7.0.6 | 9.1.0 | `gaxios@6.7.1: ^7.0.1`; `gaxios@7.1.3: ^7.0.1`; `gaxios@7.3.1: ^7.0.1`; `teeny-request@10.1.4: ^7.0.1`; `teeny-request@11.0.1: ^7.0.1` |
| `idb` | 7.1.1 | 8.0.3 | `@firebase/app@0.16.2: 7.1.1`; `@firebase/installations@0.6.24: 7.1.1`; `@firebase/messaging@0.13.3: 7.1.1` |
| `ipaddr.js` | 1.9.1 | 2.5.0 | `proxy-addr@2.0.8: 1.9.1` |
| `is-fullwidth-code-point` | 3.0.0 | 5.1.0 | `string-width-cjs@4.2.3: ^3.0.0`; `string-width@4.2.3: ^3.0.0` |
| `is-stream` | 2.0.1 | 4.0.1 | `gaxios@6.7.1: ^2.0.0` |
| `isexe` | 2.0.0 | 4.0.0 | `which@2.0.2: ^2.0.0` |
| `jackspeak` | 3.4.3 | 4.2.3 | `glob@10.5.0: ^3.1.2` |
| `limiter` | 1.1.5 | 4.1.0 | `jwks-rsa@4.1.0: ^1.1.5` |
| `lru-cache` | 10.4.3 | 11.5.3 | `path-scurry@1.11.1: ^10.2.0` |
| `media-typer` | 1.1.1 | 2.0.0 | `type-is@2.1.0: ^1.1.0` |
| `mime` | 3.0.0 | 4.1.0 | `@google-cloud/storage@8.2.0: ^3.0.0` |
| `minimatch` | 9.0.9 | 10.2.6 | `glob@10.5.0: ^9.0.4` |
| `node-domexception` | 1.0.0 | 2.0.2 | `fetch-blob@3.2.0: ^1.0.0` |
| `node-fetch` | 2.7.0 | 3.3.2 | `gaxios@6.7.1: ^2.6.9`; `gaxios@7.1.3: ^3.3.2`; `gaxios@7.3.1: ^3.3.2` |
| `p-limit` | 3.1.0 | 7.3.3 | `@google-cloud/storage@8.2.0: ^3.0.1` |
| `path-key` | 3.1.1 | 4.0.0 | `cross-spawn@7.0.6: ^3.1.0` |
| `path-scurry` | 1.11.1 | 2.0.2 | `glob@10.5.0: ^1.11.1` |
| `proto3-json-serializer` | 3.0.4 | 4.0.2 | `google-gax@5.0.8: 3.0.4`; `google-gax@6.10.0: ^4.0.0` |
| `protobufjs` | 7.6.6 | 8.8.0 | `@google-cloud/firestore@9.3.0: ^7.5.3`; `@grpc/proto-loader@0.7.15: ^7.2.5`; `@grpc/proto-loader@0.8.1: ^7.5.5`; `firebase-functions@7.4.0: ^7.2.2`; `google-gax@5.0.8: ^7.5.4`; `google-gax@6.10.0: ^7.5.4`; `proto3-json-serializer@3.0.4: ^7.4.0`; `proto3-json-serializer@4.0.2: ^7.5.4` |
| `raw-body` | 3.0.2 | 4.0.0 | `body-parser@2.3.0: ^3.0.2` |
| `readable-stream` | 3.6.2 | 4.7.0 | `duplexify@4.1.3: ^3.1.1` |
| `retry-request` | 8.0.4 | 9.0.1 | `google-gax@5.0.8: ^8.0.2`; `google-gax@6.10.0: ^9.0.0` |
| `rimraf` | 5.0.10 | 6.1.3 | `gaxios@7.1.3: ^5.0.1`; `google-gax@5.0.8: ^5.0.1` |
| `shebang-regex` | 3.0.0 | 4.0.0 | `shebang-command@2.0.0: ^3.0.0` |
| `string-width` | 4.2.3 | 8.3.0 | `cliui@8.0.1: ^4.2.0`; `wrap-ansi-cjs@7.0.0: ^4.1.0`; `wrap-ansi@7.0.0: ^4.1.0`; `wrap-ansi@8.1.0: ^5.0.1`; `yargs@17.7.3: ^4.2.3` |
| `string-width` | 5.1.2 | 8.3.0 | `@isaacs/cliui@8.0.2: ^5.1.2`; `wrap-ansi@7.0.0: ^4.1.0`; `wrap-ansi@8.1.0: ^5.0.1` |
| `string-width-cjs:string-width@^4.2.0` | 4.2.3 | 8.3.0 | `@isaacs/cliui@8.0.2: string-width-cjs npm:string-width@^4.2.0` |
| `strip-ansi` | 6.0.1 | 7.2.0 | `cliui@8.0.1: ^6.0.1`; `string-width-cjs@4.2.3: ^6.0.1`; `string-width@4.2.3: ^6.0.1`; `string-width@5.1.2: ^7.0.1`; `wrap-ansi-cjs@7.0.0: ^6.0.0`; `wrap-ansi@7.0.0: ^6.0.0`; `wrap-ansi@8.1.0: ^7.0.1` |
| `strip-ansi-cjs:strip-ansi@^6.0.1` | 6.0.1 | 7.2.0 | `@isaacs/cliui@8.0.2: strip-ansi-cjs npm:strip-ansi@^6.0.1` |
| `teeny-request` | 10.1.4 | 11.0.1 | `retry-request@8.0.4: ^10.0.0`; `retry-request@9.0.1: ^11.0.0` |
| `tr46` | 0.0.3 | 6.0.0 | `whatwg-url@5.0.0: ~0.0.3` |
| `type-is` | 2.1.0 | 3.0.0 | `body-parser@2.3.0: ^2.1.0`; `express@5.2.1: ^2.0.1` |
| `undici-types` | 8.9.0 | 8.11.2 | `@types/node@26.6.3: ~8.9.0` |
| `uuid` | 11.1.1 | 14.0.2 | `gaxios@6.7.1: ^9.0.1`; `manifest scoped override: @google-cloud/storage > gaxios > uuid ^11.1.1 (CommonJS security patch)` |
| `web-streams-polyfill` | 3.3.3 | 4.3.0 | `fetch-blob@3.2.0: ^3.0.3` |
| `web-vitals` | 4.2.4 | 6.2.2 | `@firebase/performance@0.7.14: ^4.2.4` |
| `webidl-conversions` | 3.0.1 | 8.0.1 | `whatwg-url@5.0.0: ^3.0.0` |
| `whatwg-url` | 5.0.0 | 17.1.2 | `node-fetch@2.7.0: ^5.0.0` |
| `which` | 2.0.2 | 7.0.0 | `cross-spawn@7.0.6: ^2.0.1` |
| `wrap-ansi` | 7.0.0 | 10.0.2 | `cliui@8.0.1: ^7.0.0` |
| `wrap-ansi` | 8.1.0 | 10.0.2 | `@isaacs/cliui@8.0.2: ^8.1.0` |
| `wrap-ansi-cjs:wrap-ansi@^7.0.0` | 7.0.0 | 10.0.2 | `@isaacs/cliui@8.0.2: wrap-ansi-cjs npm:wrap-ansi@^7.0.0` |
| `yargs` | 17.7.3 | 18.2.0 | `@grpc/proto-loader@0.7.15: ^17.7.2`; `@grpc/proto-loader@0.8.1: ^17.7.2` |
| `yargs-parser` | 21.1.1 | 22.0.0 | `yargs@17.7.3: ^21.1.1` |
| `yocto-queue` | 0.1.0 | 1.2.2 | `p-limit@3.1.0: ^0.1.0` |

The complete Functions installation audit and root audit were clean with this graph. Review each retained override when its parent begins resolving the patched version naturally.

## Main integration checkpoint

Merged main at `92e17e91` after the original implementation and CI validation. Dependency manifest and lockfile conflicts retain the validated latest stable graph and scoped security overrides; main's reminder features, ownership checks, and recovery changes are preserved. The accepted dependency-upgrade record is now ADR-018 to avoid colliding with main's reminder-settings ADR-017. Validation for this combined revision is recorded on PR #420.

Combined-revision local checks:

```text
No issues found! (ran in 140.4s)
01:14 +1912 ~6: All tests passed!
Backend: tests 92, pass 92, fail 0
Firestore rules: tests 50, pass 50, fail 0
check_guidelines: 22 file(s) scanned, 4 generated localization file(s) exempt, 0 violations (limits: file 400, method 80, closure indent 6)
```

The merge resolutions passed independent review. Backend and rules validation used Node 22.23.2; rules tests ran against the current rules on their fixed localhost:8080 endpoint. Dependency manifests and lockfiles are byte-for-byte unchanged from the previously validated branch. PR CI reruns on the merge commit.
