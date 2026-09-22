# ADR-016: Rebase the FCM branch onto main's architecture

- **Status**: accepted
- **Date**: 2026-09-20
- **Decider**: Dekel (repository owner)
- **Tags**: git, rebase, architecture, feature-first, fcm

## Context

`feature/basic-fcm-setup` contains the FCM delivery work and additional changes
to authentication, startup recovery, account reset, personal-plan persistence
and export, CI, release configuration, and tests. While that work was in
progress, `main` adopted a feature-first layout and changed several ownership
boundaries. Earlier attempts to merge and revert `main` left the branch with a
large, misleading structural diff and duplicated history.

The volatile concern is the implementation history and the old locations of
changed files. The stable concerns are the user-visible behavior, security and
persistence contracts, tests that express those contracts, and the current
architectural ownership established by `main`.

## Decision

Rebase the branch onto the latest `origin/main`. The structure and layer
ownership on `main` are authoritative. Every effective behavioral change from
the pre-rebase branch must be evaluated and preserved in the corresponding
feature-first location; old paths, deleted architecture, generated output, and
superseded tooling are not preserved merely because they exist in the branch
tree.

Because the branch contains repeated merge, revert, and reapplied histories,
the rebase may consolidate the branch's effective changes instead of replaying
every historical commit mechanically. A named backup reference must retain the
original history until verification is complete. Conflict resolution is based
on behavioral contracts and consumers, never a blanket `ours` or `theirs`
choice.

The owner also approves two previously missing feature boundaries:
`lib/features/auth/{data,ui}` owns identity-provider policy, restored sessions,
and sign-in UI internals; `lib/features/user_settings/ui` owns reset and sign-out
orchestration. Top-level screens remain flat files in `lib/pages/`. These
boundaries contain variation already present in the branch; they do not add a
new architectural layer or speculative reuse.

The existing `lib/features/notifications/{data,ui}` boundary owns FCM device
registration, authenticated scheduling, migration, and notification
preferences. Its repository is the single owner of preference state, replacing
the branch's additional notification state in `UserInformation`. Concrete
notification implementation may be split within that boundary to meet main's
file-size, method-size, dependency-direction, and design-token rules. Reset
and sign-out coordinate the auth and notification repositories from the
approved settings view model; neither page widgets nor generic `util/` code
become a second owner.

Public client APIs may change as needed to move those responsibilities and
remove the retired local Workmanager scheduler, provided all callers and tests
are migrated together. Persisted notification keys and legacy markers,
Firebase Functions endpoint names and payloads, mutation-version semantics,
Firestore paths and rules, and signed-in/reset behavior remain stable external
contracts. Legacy local reminders are retired only after their migration path
is retained.

Verification must cover FCM registration and scheduling, authentication,
account reset, startup and persistence recovery, personal-plan export and
custom categories, platform configuration, and affected CI contract tests.

The branch and CI require Flutter 3.47 or newer; CI uses 3.47.5. This resolves
the SDK `meta` constraint that prevented Mockito 5.8.1 from generating clean
auth mocks. Generated `app_localizations*.dart` files are exempt from the
hand-authored file-length ratchet; their ARB inputs remain reviewable. The SDK
upgrade does not itself authorize adding `solid_lints` or removing existing
guideline checks.

## Consequences

- The final branch follows `main`'s feature-first architecture and can be
  merged without restoring obsolete paths.
- Existing behavior may move or be rewritten locally within the approved auth,
  settings, and notification boundaries; no new architectural layer is added.
- Commit hashes and fine-grained branch history change. The backup reference
  provides a reversible audit trail.
- Passing tests, rather than path equality with the old branch, establish that
  functionality was preserved.

## Revision history

- **2026-09-21** — The owner approved the auth and settings feature boundaries,
  notification preference ownership, concrete FCM decomposition, client API
  migrations, and retirement of local scheduling subject to preserved external
  and migration contracts.
- **2026-09-21** — The owner approved upgrading to Flutter 3.47 and treating
  generated localization output as an exception to the file-length ratchet.
