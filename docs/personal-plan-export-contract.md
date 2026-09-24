# Personal Plan export contract

Approved on 2026-09-02 for PR #273: use an immutable in-memory export snapshot,
not an atomic persisted whole-plan format.

## Source and timing

- An explicit `memoryService` is the source of the exported plan. Otherwise use
  `UserInformation.service`, falling back to the registered persistence service.
- An alternate source never receives a copy of another model's Dreams and Goals
  or custom categories. Reading or saving its categories does not change the
  default model's categories or pending-save/retry state.
- For the model's own source, finish pending category and Dreams and Goals saves
  (including existing retry/repair behavior), then capture the plan. If a model
  save changes during preparation or capture, repeat. Eight unsuccessful
  stabilization attempts fail with normal export error feedback, not a spinner
  that waits indefinitely for editing to stop.
- Capture all exported selections, contact names/numbers, and custom categories
  behind the selected service's serialized read barrier. The barrier waits for
  earlier accepted writes; later writes/resets cannot interleave with capture.
- Pass that defensively copied snapshot to `FileService.share` or `download`.
  When a snapshot is supplied, the renderer must not read storage again.
  Changes after capture belong to the next export.
- Localized metadata and PDF link text/allowlists are copied for the request.
  Download coalescing uses the actual captured plan content plus metadata and
  source identity, not an earlier model fingerprint disconnected from the PDF.

## Failure and compatibility

Capture failures prevent rendering and follow the existing logged share/download
failure paths. A failed write to an exported key blocks capture until that key is
successfully saved or the store successfully reset. A failed reset blocks capture
until reset succeeds. This avoids exporting SharedPreferences' eager cached but
unsaved values. Incomplete contact pairs are rejected rather than mispaired.

Existing canonical category JSON and legacy category-list parsing are retained.
There are no new persisted keys, dependencies, server changes, or data migrations.
The removed alternate-store copy has no partial-copy state to roll back.

## Limits

This is not an atomic multi-key write transaction or an export history feature.
The barrier orders operations through one service instance in one isolate; it
does not coordinate direct platform writes, other isolates, or another instance
pointing at the same physical store. Callers must continue using the injected
service and await logical multi-key saves before exporting. The model-owned
category/Dreams save groups receive the additional preparation checks above.

## Regression coverage

- `test/util/personal_plan_export_snapshot_test.dart`: complete immutable payload,
  no renderer rereads, writes during capture, model-edit retry/bounded failure,
  alternate source isolation, legacy categories, incomplete contacts.
- `test/util/personal_plan_export_entry_points_test.dart`: share/download snapshot
  handoff, overlapping downloads keyed to actual content, independent sources
  during hydration, capture failure and retry without staging writes.
- `test/util/persistent_memory_service_test.dart`: queued read ordering,
  failed writes/resets, defensive copying, malformed fields, and read recovery.
- Share-form interaction tests retain rendering/editing of an explicit source
  without replacing the default model's categories.
