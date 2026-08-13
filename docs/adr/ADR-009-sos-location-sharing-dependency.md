# ADR-009: Approve Foreground SOS Location Dependency

- **Status**: accepted
- **Date**: 2026-07-31
- **Deciders**: Lubac (repository collaborator)
- **Tags**: sos, location, privacy, dependency

## Context

Issue #217 adds a one-time SOS action that appends the user's current
location to an existing help message before opening the native share sheet.
The existing sharing service is responsible only for presenting text to the
system share sheet.

Location permissions, GPS availability, and platform implementations are
volatile concerns. ADR-013 supersedes this record's earlier decision to keep
those concerns directly in `PhonePage`: the SOS-specific lookup service now
owns platform access and failure classification, while `PhonePage` retains the
stable UI and delivery choices.

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
- The Location action fails closed on web and desktop and must not invoke
  location access. The separate Message action remains the intentional
  text-only SOS flow.
- Pin `14.0.2` as the currently resolved, validated baseline to avoid
  unrelated dependency churn. Moving to a later version requires a separately
  reviewed dependency update.

## Consequences

- The SOS lookup service owns permission and device-location failure
  classification, keeping volatile GPS behavior out of `PhonePage` and the
  shared sharing service. `PhonePage` owns the resulting UI and delivery
  choices.
- The dependency is deliberately limited to one foreground-only product need;
  any background, live-tracking, or additional current-position consumer
  requires a new decision record.
- The explicit approval and version rationale satisfy the repository rule that
  new dependencies require human sign-off.

## Links

- Issue #217 — SOS current-location sharing
- `lib/pages/phone.dart` — sole production location consumer
- `docs/adr/ADR-013-sos-location-lookup-boundary.md` — SOS lookup boundary
- `pubspec.yaml` — approved direct dependency declaration
