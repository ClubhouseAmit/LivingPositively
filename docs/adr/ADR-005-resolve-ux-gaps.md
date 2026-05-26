# ADR-005: Resolve UX Gaps Identified in UX_GAPS Audit

- **Status**: proposed
- **Date**: 2026-05-24
- **Deciders**: <leave blank for author to fill>
- **Tags**: ux, accessibility, rtl, theming, crisis-safety, mental-health

## Context

A static UX audit of `lib/` was completed on 2026-05-24 and recorded in [`docs/UX_GAPS.md`](../UX_GAPS.md). The audit catalogues UX gaps across the Mazilon Flutter mental-health app (Hebrew/English, iOS + Android + Web) with `file:line` evidence and a four-tier severity scale:

| Sev | Meaning |
|-----|---------|
| **S0** | Blocks a crisis-time task or risks user harm (silent failure on emergency call, trapped flow) |
| **S1** | Accessibility / safety regression for vulnerable users (touch targets, screen readers, locale) |
| **S2** | Visible polish / correctness gap that erodes trust |
| **S3** | Inconsistency or maintainability issue with downstream UX cost |

The audit surfaces two **S0** findings on the crisis path (`UX_GAPS.md` §2.1, §2.2), several **S1** accessibility/RTL findings spread across the home → plan → phone routes, and a long tail of **S2/S3** polish and theming items. The Phase-10 test-coverage work (ADR-001 → ADR-004) closed the test-infrastructure gaps; ADR-005 picks up the parallel UX track.

**Why decide now:**

- The S0 findings are user-safety issues on a mental-health app. `launchUrl` failures during a dial attempt are currently silent (`lib/util/Phone/phoneTextAndIcon.dart:39-43`); the SOS FAB and bottom nav are both removed during full-screen video (`lib/menu.dart:289,320`). Both reach production with no telemetry or recovery affordance.
- The S1 RTL and Semantics gaps compound: every new screen added without a `Directionality`-aware pattern and without `Semantics(label:)` adds to the remediation cost.
- The codebase has no `ThemeData` and no semantic color tokens (`lib/util/styles.dart:5-13`, `lib/main.dart:410-428`). Each new feature adds another ad-hoc color/font choice; without a tokens decision, S2 polish work is duplicate effort.

## Decision

Adopt the five-phase remediation order proposed in `UX_GAPS.md` §4, with each phase scoped as a separate PR. The phases are ordered by user-impact (S0 first) and by structural unblock (theme tokens unblock the S2 polish work):

1. **Phase A — Crisis path hardening (S0).** Wrap `launchUrl` and SMS/WhatsApp helpers in `lib/util/Phone/phoneTextAndIcon.dart` with explicit failure UI (snackbar + "Copy number" fallback + haptic). Keep the SOS FAB visible during full-screen video in `lib/menu.dart`. Surface the country-fallback condition in `lib/util/Phone/EmergencyPhones.dart:45-50`.
2. **Phase B — Accessibility pass (S1).** Add `Semantics(label:)` / `tooltip:` to every icon-only control on the home → plan → phone route. Replace fixed `fontSize:` with `.sp` in the four hotspots listed in §1.7. Add `selected:` semantics to the bottom-nav buttons.
3. **Phase C — RTL pass (S1).** Stop branching on `isRtl` for `textDirection` and padding. Lean on `Directionality.of(context)` and `EdgeInsetsDirectional` start/end. Fix the inverted `textDirection` in `lib/main_menu_dialog.dart:97-99`.
4. **Phase D — Theme + tokens (S3, unlocks S2).** Define `ThemeData` (light + initially light-only `darkTheme` stub). Move the nine palette colors in `styles.dart:5-13` to a `ColorScheme`-backed token layer. Replace `Colors.red` destructive buttons (`myButtonStyle3`) with `colorScheme.error`.
5. **Phase E — Loading / error contract (S2).** Introduce one shared async widget (loading / error-with-retry / empty / data) and route every `FutureBuilder` through it. Remove the unconditional "finished" toast in `personalPlanWidget.dart:127`.

Each phase ships behind its own PR with a regression test where feasible. Phase A is the only phase blocked from being deferred — the others may be reordered post-A based on capacity.

## Consequences

### Positive
- Closes the two S0 crisis-path gaps before the next release cuts.
- Establishes a `Semantics` and `Directionality` discipline that future screens inherit.
- A `ThemeData` definition removes the per-screen color drift and makes a future dark-mode PR feasible in one change rather than dozens.
- Each phase is independently reviewable and revertible.

### Negative
- Phase D touches every page that reads from `lib/util/styles.dart`. The blast radius is large even though each call site change is small. Mitigation: keep the legacy top-level `Color` variables as forwarders to the new tokens during the migration window.
- Phase A introduces user-visible error UI on a path that today fails silently. Some users may prefer the silent failure ("the call just didn't happen, I'll try again") to a visible error. We accept this tradeoff because silent failure on a crisis dialer is the higher harm.
- The phase plan does not yet account for caption/transcript work on Wellness Tools videos (§3.9), which is a WCAG 1.2.x gap but requires content work outside the Flutter codebase.

### Neutral
- The audit is static-only. Some findings (e.g. `UserSettings.dart` locale-dropdown live re-render at §3.8) are flagged as "verify on device"; Phase B/C work will need device-time before merging.
- Typography target in `UX_GAPS.md` §5 (Lora + Raleway) is a *reference*, not part of this ADR's decision. Replacing `Rubix` is out of scope until a design review confirms the swap.

## Links

- [docs/UX_GAPS.md](../UX_GAPS.md) — source audit, severity scale, evidence with `file:line`
- ADR-001 — Phase 6 hybrid path (established the precedent of staging risky changes phase-by-phase)
- ADR-004 — Phase 9 production-injection extension (precedent for narrowly-scoped production changes with explicit consequence accounting)
