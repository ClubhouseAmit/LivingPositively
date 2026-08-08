# ADR-012: Approve Temporary API 37 Android Toolchain

- **Status**: accepted
- **Date**: 2026-08-08
- **Deciders**: Lubac (repository collaborator)
- **Tags**: android, toolchain, gradle, kotlin, ci

## Context

The Android app compiles against API 37. The repository's Android build must
use a compatible Android Gradle Plugin (AGP) path while preserving Flutter's
current generated Gradle integration. The toolchain is volatile: Flutter's
Kotlin migration, AGP compatibility, and Android SDK requirements evolve
independently of the application's stable notification and SOS behavior.

The current repository configuration uses AGP 9.1.1, Gradle 9.3.1, Kotlin
Gradle Plugin 2.4.0, and Flutter's legacy Kotlin compatibility flags:
`android.builtInKotlin=false` and `android.newDsl=false`. Android CI validates
this combination with Flutter 3.44.0 and JDK 17.

## Decision

Temporarily retain the existing API 37 toolchain:

- AGP 9.1.1
- Gradle 9.3.1
- Kotlin Gradle Plugin 2.4.0
- `android.builtInKotlin=false`
- `android.newDsl=false`

This is an explicit compatibility exception, not a new application
architecture or a production behavior change. API 37 requires the AGP 9.1.1
path used by this repository, and the current Android CI passes with this
combination.

## Consequences

- Android builds retain API 37 compatibility without changing notification,
  location, or SMS behavior.
- The legacy Kotlin flags remain narrowly scoped to the Flutter/Gradle
  transition and must not be copied into unrelated projects by default.
- Flutter's built-in Kotlin migration in Flutter 3.47 or later is the exit
  condition. Revisit this ADR after that migration is available and validated,
  then remove the exception rather than carrying it forward indefinitely.

## Links

- `android/settings.gradle.kts`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/gradle.properties`
- `.github/workflows/main.yml`
