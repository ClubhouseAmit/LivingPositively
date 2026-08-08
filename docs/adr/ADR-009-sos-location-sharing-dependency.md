# ADR-009: Approve Foreground SOS Location Dependency

- **Status**: accepted
- **Date**: 2026-07-31
- **Deciders**: Lubac (repository collaborator)
- **Tags**: sos, location, privacy, dependency

## Context

Issue #217 adds a one-time SOS action that appends the user's current
location to an existing help message before opening the native share sheet.
The app has no existing current-position abstraction: a repository search
found only the new `PhonePage` call site, and the existing sharing service is
responsible only for presenting text to the system share sheet.

Location permissions, GPS availability, and platform implementations are
volatile concerns. They remain local to the SOS page, while the stable shared
text-sharing behavior remains in `FileService`. Creating a new application
abstraction for this single current-position use case would add an unsupported
boundary without an identified second consumer.

## Decision

The repository collaborator explicitly approves adding the direct dependency
`geolocator: 14.0.2` for Issue #217.

- Use it only for an Android/iOS foreground request for one current position.
- Request only when-in-use permission. If the platform reports an existing
  `always` grant, use it only for the same bounded foreground snapshot, then
  hand the resulting map link to the existing native share flow. The app does
  not request always authorization or perform background location access.
- Do not enable background location, continuous location streams, location
  history, automatic recipient targeting, or tracking of a user's movement.
- Web and desktop remain text-only SOS fallbacks and must not invoke location
  access.
- Pin `14.0.2` as the currently resolved, validated baseline to avoid
  unrelated dependency churn. Moving to a later version requires a separately
  reviewed dependency update.

## Consequences

- The SOS page owns permission and device-location failure handling, keeping
  volatile GPS behavior out of the shared sharing service.
- The dependency is deliberately limited to one foreground-only product need;
  any background, live-tracking, or additional current-position consumer
  requires a new decision record.
- The explicit approval and version rationale satisfy the repository rule that
  new dependencies require human sign-off.

## Links

- Issue #217 — SOS current-location sharing
- `lib/pages/phone.dart` — sole production location consumer
- `pubspec.yaml` — approved direct dependency declaration
