<INSTRUCTIONS>

# 0. Hard limits — read this before writing code

Section 0 is the part of this file a **machine** checks. Sections 1–11 still bind
you — they are how a human judges the work — but they are *judged*, not measured,
so they cannot be the thing you point at to claim you complied.

**Where any rule in this repo disagrees with another, this section wins.**

Run this before you report work complete. Not "consider running" — run it:

```
tool/check_guidelines.sh            # files you changed vs main
tool/check_guidelines.sh <file>     # one file
```

`tool/check_guidelines.sh` holds the numbers. This table quotes it; if the two
ever disagree, the script is right and this table is stale.

| # | Limit | Why it exists |
|---|---|---|
| 0.1 | **One public widget class per file.** Private `_LeafCard` widgets beside it are fine — they are the fix, not the bug. | A file with three screens in it cannot be read, reviewed, or changed safely. |
| 0.2 | **A new file under `lib/` is ≤ 400 lines.** An existing file over 400 may not grow. Generated `lib/l10n/app_localizations*.dart` files are exempt; their ARB sources are the reviewable input. | Ratchet. 24 files are already over; they are debt, not licence. |
| 0.3 | **A method is ≤ 80 lines** — `build` methods included. | A 250-line method is not a method, it is a file that forgot to be one. |
| 0.4 | **No function defined inside a builder callback.** Hoist it to a method or a widget. | Closures nested inside two builders are unreadable and untestable. |
| 0.5 | **No raw number in a spacing/radius slot.** Use `AppSpacing.*`, `AppRadii.*`, or theme. `0` is allowed. | Not even a number that equals a token's value: nobody can tell `20` from `AppSpacing.xl` by reading it. |
| 0.10 | **A top-level page goes in `lib/pages/*.dart`.** Feature internals go in `lib/features/<name>/{data,ui}` — not the page. `pages/<folder>/`, `util/`, `MainPageHelpers/`, `form/`, `initialForm/` and the `lib/` root stay frozen. | A page that lives inside its feature, or a feature folder under `pages/`, is how one concern ends up in four directories. See 0.10a. |
| 0.11 | **Layers point one way.** `data/` must not import a widget library. `ui/` must not import a file from `data/` other than `*_models`, `*_types`, `*_repository`. | A view model that reaches around its repository grows until nobody can test it. |
| 0.12 | **In `features/*/ui/`, use the design-system widget, not the Material widget it replaces.** No bare `TextButton(` — use `Button` (`lib/design_system/widgets/`). `Card`/`Text`/`Dialog` in ui/ are the design-system widgets; hide Flutter's names at the import. Extends only as new widgets ship; this is not a blanket Material ban. | A component built to fix drift (§0.10a) is worthless if new screens keep reaching past it for the widget underneath. |
| 0.13 | **A `currentScreen` widget does not set `appBar:`.** The class list is read from `lib/menu.dart`, not restated. A route opened with `Navigator.push` keeps its bar. | `menu.dart` already owns the scaffold. A second `AppBar` is a nested scaffold. Existing bars park by count. |
| 0.14 | **No widget class under `lib/util/`.** No `StatelessWidget` / `StatefulWidget` / `State<`. | Util is infra. A widget there is a feature in the wrong tree. |

### 0.5a What the words mean

The script decides, not your reading of the table. Where you need to know:

- **"lines"** — physical lines, counting the signature and the closing brace.
- **"method"** — a class member with a `{ }` body or an `=>` body. Top-level
  functions are not currently measured.
- **"public widget class"** — a class whose name does not start with `_` and
  which extends `StatelessWidget`, `StatefulWidget`, `ConsumerWidget`, or
  `ConsumerStatefulWidget`.
- **"spacing/radius slot"** — the arguments of `SizedBox`, `SizedBox.square`,
  `EdgeInsets*`, `BorderRadius.circular/all`, and `Radius.circular`. Other
  widgets that take a number (`Positioned`, `Container(margin:)`) are not yet
  checked; use tokens there anyway.
- **"currentScreen widget"** — a class assigned with `currentScreen = Name(`
  in `lib/menu.dart`. The script reads that file each run; a page reached
  only through a helper is not on the list.
- **Scope** — 0.2 applies to `lib/` only. 0.1/0.3/0.4/0.5/0.13 apply to any
  `.dart` file you point the script at. 0.14 applies to `lib/util/`.

**The script is a text heuristic, not a Dart parser.** `tool/check_guidelines.sh`
documents its known gaps at the top, and `tool/check_guidelines_test.sh` is the
list of shapes actually proven to be caught. "0 violations" means "none of the
known shapes were found" — it does not mean the code is good.

### 0.6 When section 0 and the surrounding code disagree

**The limits win. New code does not inherit old debt.**

This is not hypothetical. 62 of 152 files in `lib/` hardcode spacing, and the
oldest date from 2024 — long before any agent touched this repo. Section 6.3
below says "if existing code is imperfect but consistent, match it." That rule
is about *naming, idiom, and structure*, and it stops where section 0 starts.
Do not cite 6.3 to justify a raw literal or a 200-line method.

### 0.10a Where new code goes

The layout itself is specified in `.claude/skills/architecture-feature-first/SKILL.md`.
**Load that skill before creating any file.** This section does not restate it —
it states only what the skill cannot know about this repo.

`lib/features/remember_to_breathe/` is the reference for feature internals
(`data/` + `ui/` widgets). The screen itself lives in `lib/pages/`. Copy that
split, not `mood_medicine`'s old all-in-`ui/` page. App layout
(`lib/menu.dart`, `lib/main_menu_dialog.dart`) stays at the `lib/` root —
it is not a feature.

```
lib/pages/<name>_page.dart          # top-level screen only — no subfolders
lib/features/<name>/
├── data/    models, repository, store, and that feature's services
└── ui/      <name>_view_model.dart, <name>_view_state.dart, widgets/
```

**This repo is feature-first for data (LeanCode / VGV), not Flutter Compass.**
A service or repository lives in `lib/features/<name>/data/`. Do not create
`lib/data/`, `lib/data/services/`, `lib/services/`, `lib/core/`, or
`lib/shared/`. Compass groups those by type because it treats services as
shared across features; here a feature owns its data layer. Two valid homes
means the next agent guesses.

Deviations from the skill, which is written for a greenfield app:

- Use `ui/`, not `presentation/`. Use `domain/`, not `logic/`.
- Genuine cross-feature infrastructure (file I/O, analytics, GetIt, locale,
  logger, speech recognition, persistent memory, `ThemeData`) stays in
  `lib/util/async/`. That tree may import Flutter for `ThemeData` or
  `runApp`. It must not define a widget (`0.14`). Tokens live in
  `lib/design_system/tokens/`, not `util/theme/`. Shared UI lives in a
  feature: `wizard`, `speech_dictation`, `shell` (app chrome), or the
  feature that owns the screen. A feature API wrapper or a widget cannot
  live in `util/`. Everything else in `lib/util/` is leftover — read it,
  do not extend it.
- `lib/design_system/` is the platform-agnostic component layer: `tokens/`
  (colors, spacing, radii, shadows, type scale) and `widgets/` (`Text`,
  `Card`, `Glass`, `Button`). Nothing in it imports Material or
  Cupertino — a future re-skin touches these implementations, never a feature's
  call sites. Use these over a raw Material `Text`/`Card`/`TextButton` in
  `ui/`; see 0.12. Import `design_system/widgets/` and hide Flutter's names.

**Frozen trees.** `lib/pages/` is flat: one `*.dart` file per top-level
screen. A subdirectory under `pages/` is a feature in the wrong place.
`lib/util/`, `lib/MainPageHelpers/`, `lib/form/`, `lib/initialForm/`, and
loose files at the `lib/` root still predate feature-first organisation.
Editing a leftover file is fine. Adding to a frozen tree is 0.10. Section
6.3 tells you to match surrounding structure — it stops here, exactly as
it stops at 0.5.

Move a leftover legacy folder into `lib/features/` only as part of a ticket
that already touches it, never as a standalone refactor PR.

### 0.7 Stop conditions you can actually detect

Stop and ask a human when any of these is true. These replace "stop if
volatility has not been identified," which no agent can evaluate about itself:

- Following section 0 would require changing a file you were not asked to change
- `tool/check_guidelines.sh` exits 2 (it could not run) and you cannot fix the cause
- Two documents in this repo tell you different things and section 0 does not settle it
- You are about to add a package to `pubspec.yaml`
- You are about to change a public method signature that has callers outside its feature folder
- You are about to add an `// ignore:` or otherwise suppress a check rather than satisfy it

### 0.8a Where the debt is

Every check in this repo is a ratchet: old violations are parked, new ones fail.
Parked is not gone. `tool/debt_report.sh` counts all six registers from the live
sources — analyzer baseline, disabled strict modes, section-0 violations,
in-code suppressions, TODO/ponytail markers, and blocked upgrades.

Run it before proposing a cleanup task, so the work is aimed at the biggest pile
rather than the most visible one. Nothing in it is restated by hand, so it cannot
go stale; if a number looks wrong, the register is wrong, not the report.

```
tool/debt_report.sh
```

No trend file. A hand-appended history is a metric nobody consumes and nobody
is forced to update — the one row it ever produced named a commit that
contained neither the measurement nor the script that took it. If a trend is
ever needed, it belongs in CI on a clean checkout, not a file an agent remembers
to append to.

### 0.9 Why 0.1–0.5 are a script and not a linter

`very_good_analysis` is wired up and owns general Dart/Flutter quality, but it
has **no rule for any of 0.1–0.5** — no method-length metric, no magic-number
rule, no widget-per-file rule. The two do not overlap; neither replaces the other.

The package that *would* cover them is `solid_lints`: `function_lines_of_code`,
`no_magic_number`, `cyclomatic_complexity` and `avoid_returning_widgets` as real
AST rules — strictly better than regex, and `avoid_returning_widgets` is a better
fix for long `_buildX` methods than 0.3's line cap.

Flutter 3.47 lifts the former dependency blocker: its `flutter_test` accepts
`meta ^1.18.3`, allowing `mockito ^5.8.1` to resolve. `solid_lints` remains an
option for replacing the text-based 0.3 and 0.5 checks with AST rules; it is
not installed or configured. Adding that package requires human approval under
0.7 and a separate migration that proves the new rules before removing the old
checks. Keep 0.2, the git-history ratchet, which is not a lint. The
now-unmaintained `dart_code_metrics` (last release July 2023) is not an option.

### 0.8 Verify block

A rule without a runnable check is already drifting. These commands are the
evidence that section 0 held — quote their output, do not describe it:

```
tool/check_guidelines.sh        # must print "0 violations" (exit 2 = it could not run)
flutter analyze                 # must print "No issues found"
flutter test                    # must pass
```

`flutter analyze` runs **very_good_analysis** (~200 rules). 71 of them are
baselined to `ignore` in `analysis_options.yaml` because the existing codebase
already violates them 8,844 times; the other ~130 fail on sight. That baseline
is **debt, not permission**: fix a rule and delete its line. Adding a line to
silence a new violation is the one move it exists to prevent — see 0.7.

If you changed `tool/check_guidelines.sh` itself, you must also run
`tool/check_guidelines_test.sh` — the suite that plants a known-bad file per rule
and asserts the checker rejects it. Add a case there for anything you fix. A check
that cannot fail is not a check, and a check nobody has broken on purpose has not
been shown to be able to fail.

---

# 1. Purpose

This file defines **mandatory rules and principles** governing all AI agents
operating in this repository.

AI agents are treated as **junior engineers with infinite speed**: powerful,
tireless, and dangerous without discipline.

Sections 1–11 are the reasoning behind section 0. They are written for a human
and for an agent that has already satisfied section 0. **Satisfying them is not
a substitute for section 0**, and an agent that produces a compliant-sounding
design document while shipping a 1800-line file has failed.

---

## 2. Definition of an Agent

An **agent** is an AI-driven process that performs engineering work: architecture
analysis, detailed design, code authoring, refactoring, code review, estimation,
documentation, validation.

Agents **operate on the system**. Agents are **not part of the runtime system**.

---

## 2A. Pre-work: consult graphify

Before design, code, or review output, ground yourself in what exists:

- run `graphify query "<the task>"` against `graphify-out/graph.json` to find existing
  code, patterns, and dependents
- treat the result as ground truth for "what already exists"

If `graphify-out/graph.json` is missing or stale, run `graphify --update` first —
**except** for a single-file review or read-only lookup, where you query the
existing graph as-is and note possible staleness. Do not block a small task on a
full-corpus rebuild.

If you are in a read-only sandbox, do not attempt `--update`; query what exists,
note the limitation, continue. Stop for a human only if no graph exists at all
*and* the task is design-scoped.

---

## 2B. Pre-work: Dart/Flutter style skills

Before writing or reviewing Dart/Flutter, load the `effective-dart` and
`dart-3-updates` skills and follow this repo's conventions rather than generic
Dart habits.

Before creating any **new file**, also load `architecture-feature-first`. Where it
and section 0.10a disagree, 0.10a wins — it knows this repo, the skill does not.

---

## 3. Non-Negotiable First Principles

- add comments which are only useful for an agent to continue building a scalable production grade app
- load i-have-adhd skill and use it to format responses

### 3.1 Engineering over generation

Understand the problem, identify constraints, reason about consequences. If the
reasoning cannot be articulated, **stop**.

### 3.2 Volatility is the primary design axis

Reason about **volatility before structure**: what is expected to change, what
must remain stable, what is being mistaken for a requirement but is actually a
solution. Never design around features, domains, or frameworks.

### 3.3 Design big, build small

**Design Big**: reason across systems, consumers, and time.
**Build Small**: generate minimal, safe, localized artifacts.

Do not jump to code, invent reuse opportunities, or create "common" abstractions
without evidence.

---

## 4. Scope and role discipline

### 4.1 Single cognitive responsibility

Each agent operates in **one role at a time**. Design agents do not write
production code. Code agents do not invent architecture. Review agents do not
introduce new behavior.

### 4.2 No god agent

No agent defines architecture, implements it, reviews itself, and approves its
own work. This is the God Object anti-pattern at the cognitive level, and
section 7.1 makes it operational.

---

## 5. Stop conditions

**0.7 is the operative list — it is what you check yourself against.** The
judgement calls below are for a human reviewer, and an agent that cannot
evaluate them about itself should not pretend to: architecture missing or
ambiguous, requirements in conflict, a decision affecting more than one
boundary, a public contract changing, a new abstraction that seems "useful",
reuse considered "for the future".

---

## 6. Code-writing agents

### 6.1 Code is an outcome, not a goal

Implement already-designed behavior, follow existing architecture, respect
boundaries. If design is unclear, do **not** guess.

### 6.2 Forbidden

Never invent architectural layers, add dependencies without approval, collapse
layers "for simplicity", generalize prematurely, introduce shared utilities
"just in case", bypass managers or access layers, or refactor for aesthetics
without intent.

### 6.3 Convention over novelty — bounded by section 0

Prioritize consistency, symmetry, predictability. If existing code is imperfect
but consistent, **match its naming, idiom, and structure**.

**This rule does not extend to section 0.** Matching the surrounding code is not
a reason to hardcode a value that has a token, to exceed a length limit, or to
nest a function inside a builder. Where the surrounding code violates section 0,
the surrounding code is debt — leave it alone and do not copy it. See 0.6.

## 6A. SOLID — local construction only

SOLID applies **only inside an already-approved boundary**, when the boundary
exists, the responsibility is assigned, and the layering is defined. It must
never justify new boundaries, new abstractions, decomposition, or reuse
decisions. If SOLID conflicts with volatility-based design, **SOLID yields**.

- **SRP**: refines responsibilities; it does not create them. Split a class that
  mixes unrelated behaviors inside one boundary. Do not create services or layers
  "for SRP".
- **OCP**: if no variation exists today, OCP does not apply. No speculative hooks,
  flags, strategies, or abstract bases without active subclasses.
- **LSP**: if substitution is conditional, the inheritance is invalid.
- **ISP**: interfaces follow consumers, not taste.
- **DIP**: indirection without volatility is noise.

Stop and ask a human if SOLID is being used to introduce an abstraction, create a
boundary, justify reuse, generalize behavior, refactor across layers, or change a
public contract.

> SOLID improves code **inside** a design. SOLID does not create the design.

---

## 7. Review agents

### 7.1 The reviewer is a separate agent in a fresh context

**The agent that wrote the code may not review it.** Not a later turn of the same
session, not the same context after a compaction. A dedicated reviewer, started
clean, whose only job is read-diff → apply section 0 → write findings.

The reason is specific: an agent that also built the feature will rationalize its
own code, and it is the one agent in the loop least able to see its own blind spot.

### 7.2 Triage on the resulting file, never on the diff

A reviewer that measures the diff will approve a small patch to an enormous file,
every time. This is how an 1800-line file passed three consecutive reviews: each
individual diff was modest and reasonable.

**For every `.dart` file in the diff, run `tool/check_guidelines.sh <file>`
against the file as it now stands.** The diff is what changed. The file is what
ships. Generated `lib/l10n/app_localizations*.dart` files return success as the
explicit 0.2 exception; review their ARB inputs instead. (Bare
`tool/check_guidelines.sh` already covers working-tree, staged, and branch
changes under `lib/` — including files not yet committed.)

### 7.3 Report what you checked, not only what failed

End every review with a table of section 0 rules and a PASS/FAIL for each, per
file. A reviewer that reports only findings cannot be distinguished from a
reviewer that checked nothing. Quote the script's output.

### 7.4 One retry, then a human

If a finding is disputed and re-reviewed once without resolution, escalate to a
human. A loop that retries until something reads PASS is single-agent
self-approval run by two agents.

### 7.5 Validation criteria

Output is valid only if section 0 passes, volatility is contained, reasoning is
explainable, boundaries are preserved, changes are localized, and the system is
more resilient to change than before.

---

## 8. Reuse

Reuse is an outcome, not a goal. Identify reusable utilities only if explicitly
requested. Do not create "common services", centralize behavior preemptively, or
assume other systems will consume the output. "Field of Dreams" behavior is
forbidden.

**This bans creating shared code, not finding it.** Before you write a helper,
search for one: `lib/util/` and the existing features are the two places to look,
and 2A's graphify query is how to look. `lib/features/mood_medicine/` shipped its
own PDF direction helpers, its own share-sheet stack, and a copy of another
feature's write queue, all of which already existed. Writing a second copy is not
neutral — it is the cost this section exists to avoid, pointed the other way.

---

## 9. Human authority

Humans remain the architects. Agents may propose, analyze, critique, simulate.
Agents may not commit irreversible decisions, redefine architecture, override
explicit human instructions, or optimize for speed over correctness.

---

## 10. Quality bar

Output must be explainable, reviewable, reversible, convention-compliant, and
volatility-aware — and must pass section 0.8. Fast, clever, or impressive output
that violates these rules is **invalid**.

---

## 11. Final assertion

> AI agents do not replace engineers. AI agents must behave like engineers.

An engineer runs the check before saying it is done.

</INSTRUCTIONS>
