# ADR-014: Approve Display-only Mood Medicine PDF Preview Dependency

- **Status**: accepted
- **Date**: 2026-08-29
- **Deciders**: Lubac (repository collaborator)
- **Tags**: mood-medicine, report, preview, dependency, privacy

## Context

Issue #357 lets a person view a locally generated Mood Medicine report before
choosing the existing system share flow. Flutter's built-in widgets do not
provide an in-app PDF document renderer with a fixed page format.

PDF rendering and platform preview behavior are volatile implementation
concerns. The feature-local report preview keeps those concerns out of the
Mood Medicine view model, report data, and existing share delivery path.

## Decision

The repository collaborator explicitly approves the direct dependency
`printing: ^5.15.0` for Issue #357.

- Use it only for the display-only `PdfPreview` in
  `lib/pages/MoodMedicine/mood_medicine_report_preview.dart`.
- Preview a fixed A4 report with printing, sharing, page-format changes,
  orientation changes, debug controls, and dynamic layout disabled.
- Keep the existing explicit Share action as the sole route to the system
  share or printer sheet.
- Do not use this dependency for report generation, analytics, networking,
  data collection, background work, or any new permission.
- Moving the dependency version or widening its scope requires a separately
  reviewed dependency decision.

## Consequences

- The optional plugin remains inside the Mood Medicine preview surface; report
  bytes and feature-local export state retain their existing ownership.
- People can inspect a PDF in app without an implicit print or share action.
- The explicit approval and fixed scope satisfy the repository rule that a new
  dependency requires human sign-off.

## Links

- Issue #357 — Mood Tracker & Personal Medicine
- PR #372 — Mood Medicine implementation and review fixes
- `pubspec.yaml` — approved direct dependency declaration
- `lib/pages/MoodMedicine/mood_medicine_report_preview.dart` — sole production
  `PdfPreview` consumer
