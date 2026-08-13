# ADR-013: Isolate SOS Location Lookup

- **Status**: accepted
- **Date**: 2026-08-13
- **Deciders**: Lubac (repository collaborator)
- **Tags**: sos, location, privacy, testing

## Context

The SOS Location action requires a one-time foreground position before it can
offer delivery. Platform support, location-service availability, permission
state, and position lookup failures are volatile concerns. They had been
implemented directly in `PhonePage`, which also owns dialogs, retry UX, map
link preparation, and SOS delivery choices.

This record supersedes only ADR-009's earlier decision that a current-position
abstraction was unsupported and that `PhonePage` should own platform lookup
handling. ADR-009's dependency approval and privacy constraints remain in
effect.

## Decision

Introduce a feature-scoped injectable SOS location lookup service.

- The service owns Android/iOS support checks, foreground permission checks
  and requests, one high-accuracy current-position lookup, and typed failure
  classification.
- `PhonePage` owns dialogs, bounded retry UX, map-link preparation, and app,
  contact, SMS, WhatsApp, and map delivery choices.
- The service exposes only a one-shot lookup result; it does not expose
  continuous updates, background work, history, or tracking.
- The concrete implementation continues to use the exact approved
  `geolocator: 14.0.2` dependency. It requests only while-in-use permission
  and may use an already-granted `always` status only for the same bounded
  foreground snapshot.
- The Location action fails closed when a position is unavailable, including
  on web and desktop. The separate Message action remains the intentional
  text-only SOS flow.

## Consequences

- `PhonePage` widget tests can inject deterministic lookup results without
  mutating the global geolocation platform implementation.
- The concrete lookup behavior receives direct, ordered platform-call tests.
- No location permission, dependency, background capability, recipient
  targeting, automatic delivery, or tracking behavior changes.

## Links

- `docs/adr/ADR-009-sos-location-sharing-dependency.md`
- `lib/pages/sos_location_service.dart`
- `lib/pages/phone.dart`
