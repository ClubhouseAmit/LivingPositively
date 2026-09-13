# ADR-015: Remember to Breathe core practice

- **Status**: accepted
- **Date**: 2026-09-13
- **Deciders**: repository collaborator, through explicit implementation-plan approval

## Context

Issue #386 requests breathing practice, media customization, and a practice log.
Breathing timings, platform image handling, and local persistence can change
independently. Existing navigation, emergency access, app-data reset, and
localization contracts remain stable. The collaborator approved a first PR with
images while explicitly deferring voice guidance, audio/music, and video.

## Decision

- Follow the existing Mood Medicine UI/data arrangement within
  `lib/features/remember_to_breathe`, without creating shared timing or wellness
  abstractions. A page-owned ChangeNotifier controls breathing rules and visit
  state; a singleton store serializes snapshot mutations. Flutter renders phase
  progress but does not determine when a cycle completes.
- Basic, Box, and Custom each finish after exactly eight full cycles. Quick Start
  chooses Basic. Pre/post stress ratings are optional and never inferred from a
  default control value. Restart discards the unfinished attempt.
- Use three customization steps: background, inhale, exhale. Skip retains the
  prior value. Custom timing changes during practice affect the next matching
  phase. Pause freezes progress; backgrounding requires explicit resume.
- Keep practice and results inside Menu's fullscreen body with SOS still
  actionable. Pause and recovery controls use in-page content, not modal
  barriers. SOS captures a partial result and leaves immediately; a failed save
  cannot delay access to the emergency page.
- Store one versioned snapshot in the existing PersistentMemoryService. Use
  revisioned session identities for idempotent retries. Do not overwrite
  unreadable data without explicit recovery. Before app reset, invalidate
  breathing operations that have not yet reached the memory service's queue;
  already accepted writes remain governed by its existing reset fence.
- Bundle eight CC0 backgrounds with provenance in the asset manifest. Use the
  unchanged image picker's gallery operation, not Feel Good's gallery manifest.
  Retain one normalized local PNG (at most 768 pixels on its longest edge and
  512 KiB), replacing the previous photo. Reject input larger than 20 MiB before
  reading. Store image bytes, never temporary paths or browser blob URLs.
- Preserve the issue's exact Hebrew passages and provide English/Arabic keys.
  Do not send photos or stress data to analytics, cloud storage, or device sync.
  No dependencies or platform permissions are added.

## Consequences

The feature works offline after installation and its data participates in app
reset. Explicit failed-save retry and discard choices keep ordinary navigation
from silently losing a result. Process termination does not resume an active
session; only finished or explicitly stopped attempts are recorded.

Issue #386 remains open for voice guidance, looping background audio, personal
music, and instructional video. This PR uses `Refs #386`, not a closing keyword.

## References

- https://github.com/ClubhouseAmit/LivingPositively/issues/386
- `assets/images/breathing/manifest.json`
- `lib/features/mood_medicine` (existing local state/persistence conventions)
- ADR-005 (SOS access during fullscreen use)
