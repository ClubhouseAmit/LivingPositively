# Architecture passdown: where code belongs

Use this guide to place a change, follow the existing dependencies, and check
your work. It explains the structure introduced in
[PR #397](https://github.com/ClubhouseAmit/LivingPositively/pull/397).
[AGENTS.md §0](../AGENTS.md) defines the mandatory rules;
[tool/check_guidelines.sh](../tool/check_guidelines.sh) defines the checked
limits. If an old file uses a different pattern, follow those rules.

- [Current structure](#1-current-structure)
- [Where to put a change](#2-where-to-put-a-change)
- [Responsibilities and dependencies](#3-responsibilities-and-dependencies)
- [Worked example: saving breathing settings](#4-worked-example-saving-breathing-settings)
- [Design-system usage](#5-design-system-usage)
- [Legacy code and completion checks](#6-legacy-code-and-completion-checks)
- [Migration history](#7-migration-history)

## 1. Current structure

A **page** is a top-level screen. A **feature** groups the UI, state, and data
for one app capability, such as breathing practice or a personal plan.
Feature widgets can be stateless or stateful; their responsibility determines
where they belong.

This map shows the current homes for application code covered by this guide.

```text
lib/
├── pages/
│   └── <name>_page.dart            top-level screen; no subfolders
├── features/
│   └── <name>/
│       ├── data/                 models, repository, store, services
│       └── ui/                   view model, view state, feature widgets
│           └── widgets/          feature widgets grouped here when needed
├── design_system/
│   ├── tokens/                   named colors, spacing, radii, typography
│   └── widgets/                  app primitives: Button, Card, Text, etc.
├── util/
│   └── async/                    existing cross-feature infrastructure
├── menu.dart                     existing app layout and screen switching
└── main_menu_dialog.dart         existing main-menu UI
```

Keep feature services and repositories inside that feature's `data/`.
Do not create `lib/data/`, `lib/services/`, `lib/core/`, or `lib/shared/`.
The existing root files above stay in place; they are not permission to add
more loose files at the `lib/` root.

## 2. Where to put a change

Start with the capability the ticket changes. Find its existing feature before
creating a folder or helper. Search the existing features and `lib/util/` for
code that already does the job; finding legacy code does not make its location
the right home for new code.

| I need to…                                                                 | Put the change here                                     | Keep this boundary                                                                                   |
| -------------------------------------------------------------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Add a top-level screen                                                     | `lib/pages/<name>_page.dart`                            | Compose feature widgets; keep feature state and behavior in the feature.                             |
| Add or change a base widget, such as `Card`, `Button`, or an input control | `lib/design_system/widgets/`                            | Use design tokens; keep feature-specific content and behavior out. No Material or Cupertino imports. |
| Compose a feature-specific form or section                                 | `lib/features/<name>/ui/`                               | Build it from design-system widgets and connect it to the feature's state and actions.               |
| Handle loading, a draft, or a user action                                  | The feature's view model in `lib/features/<name>/ui/`   | Call its repository for persisted data.                                                              |
| Save/load feature data or call a feature API                               | `lib/features/<name>/data/`                             | Expose operations through the repository; UI must not call a store or service directly.              |
| Change app navigation or the main menu                                     | Existing `lib/menu.dart` or `lib/main_menu_dialog.dart` | A page hosted by Menu must not add its own AppBar.                                                   |
| Add or change a visual token                                               | `lib/design_system/tokens/`                             | Keep colors, spacing, radii, and typography consistent with `DESIGN.md`.                             |
| Change shared technical infrastructure                                     | `lib/util/async/`                                       | No widget classes and no feature-specific API wrappers.                                              |
| Fix a legacy file                                                          | Its current location, within the ticket's scope         | Move it only as part of a ticket already touching it.                                                |

A base `Card` belongs in the design system. A personal-plan section that uses
that `Card` belongs in the personal-plan feature: it supplies the content and
connects user actions to feature behavior.

Use the feature that already owns the behavior. Existing shared app-specific
UI belongs to named features such as `shell`, `wizard`, and `speech_dictation`;
base widgets belong in the design system. Reuse existing components when they
fit; do not create a shared abstraction for hypothetical future users.

## 3. Responsibilities and dependencies

### Pages and feature UI

A new page lays out feature widgets and connects their inputs and callbacks.
A static screen may be a simple `StatelessWidget`, as in
[about_page.dart](../lib/pages/about_page.dart).

Complex state, controllers, and the lifecycle of an interaction belong in the
feature's UI. **Lifecycle** means creating the needed objects when the
interaction starts and releasing listeners, timers, and controllers when it ends.

[home_page.dart](../lib/pages/home_page.dart) shows how a page composes sections
from several features. It still contains state and persistence logic, so use
its composition as an example, not the entire file as a template.

### What each part owns

| Part                      | Responsibility                                               | Example in breathing practice                                   |
| ------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------- |
| UI widget                 | Render state and forward user actions.                       | Show a Save button and call the view model when tapped.         |
| View model (`ui/`)        | Coordinate actions and expose current UI state.              | Hold draft settings, saving status, and an error.               |
| View state (`ui/`)        | Describe presentation state.                                 | Identify which step or screen to display.                       |
| Data model (`data/`)      | Describe the feature's data.                                 | Breathing settings and saved sessions.                          |
| Repository (`data/`)      | Provide the operations the UI needs to read or persist data. | `load()` and `saveSettings(...)`.                               |
| Store / service (`data/`) | Implement storage or external access behind the repository.  | Write a breathing snapshot through the existing memory service. |

Dependencies point toward the data layer:

```text
page / feature widgets → view model → repository → storage / external access
```

The arrows show who may call whom. Results return to the view model, which
updates its state and tells listening widgets to rebuild.

- `data/` must not import a widget library.
- `ui/` may import data-layer files only when they end in `_models.dart`,
  `_types.dart`, or `_repository.dart`.
- A repository can have a separate implementation. For example,
  `BreathingStore` implements `BreathingRepository`; these are two names for
  the interface and implementation, not two objects every call must traverse.

Create only the parts the behavior needs. A static widget needs no repository;
an existing repository may already provide everything a new interaction needs.
Do not add empty layers to match a diagram. A new domain/use-case layer or
cross-feature abstraction needs an architecture decision, not just a new folder.

### App shell and shared technical infrastructure

**App chrome** means the UI around the current screen: navigation, the app bar,
and the main menu. These two locations have different responsibilities:

- [menu.dart](../lib/menu.dart) owns the app scaffold and assigns
  `currentScreen = SomePage(...)`. Those pages do not set `appBar:`.
  A separate route opened with `Navigator.push` keeps its own bar.
  [main_menu_dialog.dart](../lib/main_menu_dialog.dart) also stays at the root.
- [features/shell/ui/](../lib/features/shell/ui/) holds shared app UI pieces,
  such as toasts and widgets that handle text direction. It does not move
  ownership of the app scaffold away from `menu.dart`.

**Infrastructure** is technical support used across features: file I/O,
analytics, dependency registration through GetIt, locale, logging, speech
recognition, persistent memory, and `ThemeData` construction. Its home is
`lib/util/async/`. It may import Flutter where needed, but must not define
widget classes. A service dedicated to one feature stays in that feature.

## 4. Design-system usage

### Tokens: named visual values

[design_system/tokens/](../lib/design_system/tokens/) contains `AppColors`,
`AppSpacing`, `AppRadii`, `AppShadows`, font weights, and the type scale.
These names let code express the intended visual role of a value.

Use tokens for spacing and radius: for example,
`SizedBox(height: AppSpacing.lg)` and `BorderRadius.circular(AppRadii.card)`.
Do not substitute a raw number even when it happens to equal a token. Zero is
allowed. Use tokens in other spacing slots, such as `Wrap.spacing`, too.
The visual definitions must agree with [DESIGN.md](../DESIGN.md).

### Widgets: use the app's implementations

In `lib/features/*/ui/`, use the replacements from
[design_system/widgets/](../lib/design_system/widgets/), including `Button`,
`Card`, `Text`, and `Dialog`. Hide Flutter's conflicting names at the import:

```dart
import 'package:flutter/material.dart' hide Card, Dialog, Text, TextButton;
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/design_system/widgets/card.dart';
import 'package:mazilon/design_system/widgets/dialog.dart';
import 'package:mazilon/design_system/widgets/text.dart';
```

Keep only the imports the file uses. For controls with no design-system
replacement, Material remains available. Inside `design_system/` itself,
do not import Material or Cupertino; the primitives use Flutter's lower-level
widgets so changes to the app's appearance stay in one place.

**Do not add new bare `TextButton(...)` calls in feature UI.** Rule 0.12
requires `Button`, and the checker rejects increases in those calls.
A compact text-only action is not an exception. If `Button` cannot express
the required design, raise the missing design-system capability before
introducing an exception or suppressing the check.

## 5. Legacy code and completion checks

### What “frozen” means

Frozen directories may still contain files that need maintenance. You may edit
an existing file within your ticket, but may not add new files to these locations:

- `lib/form/`, `lib/initialForm/`, `lib/MainPageHelpers/`
- `lib/util/` outside `async/`
- subfolders under `lib/pages/`
- the `lib/` root

Move a legacy file into its feature only as part of a ticket already touching
it. Do not open a separate “move everything” refactor. Existing stateful pages
such as `home_page`, `phone_page`, `journal_page`, and `breathing_page` are
examples of unfinished migration, not templates for new pages.

### What the checks guarantee

A **ratchet** lets recorded old violations remain while rejecting new ones.
**Parked debt** means those existing violations still need fixing; it does not
mean they are approved patterns. [tool/debt_report.sh](../tool/debt_report.sh)
counts the debt and must be run before proposing a cleanup task.

| Rule        | What new work must satisfy                                                                                                                                                                                  |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **0.1–0.5** | One public widget per file; new `lib/` files at most 400 lines; existing oversized files must not grow; methods at most 80 lines; no functions defined inside builder callbacks; tokens for spacing/radius. |
| **0.10**    | Flat top-level pages, feature internals in their feature, no new files in frozen trees.                                                                                                                     |
| **0.11**    | No widget imports in `data/`; feature UI imports data only through models, types, and repositories.                                                                                                         |
| **0.12**    | Use available design-system replacements in feature UI. The current checker specifically counts new bare `TextButton(...)` calls.                                                                           |
| **0.13**    | A `currentScreen` page does not set `appBar:`.                                                                                                                                                              |
| **0.14**    | No widget classes under `lib/util/`, including `async/`.                                                                                                                                                    |

Before calling a change done:

1. Check that each new file has an allowed home and a clear owner.
2. Check that imports follow the allowed dependency direction.
3. Check widget/token usage and ownership of listeners, controllers, and timers.
4. Run the required checks and inspect the actual output:

```sh
tool/check_guidelines.sh    # must print "0 violations"
flutter analyze            # must print "No issues found"
flutter test               # must pass
```

The guideline checker uses text patterns, not a full Dart parser. “0 violations”
means it found none of the shapes it recognizes. Check the scanned-file count;
a run that scans zero Dart files says nothing about a Markdown document.

If you change the checker itself, run `tool/check_guidelines_test.sh` too and
add a case for the behavior you change. For a code review, run
`tool/check_guidelines.sh <file>` for each changed Dart file.

Stop and ask under [AGENTS.md §0.7](../AGENTS.md): adding a package, changing
a public method signature used outside the feature, suppressing a check,
needing an out-of-scope edit to satisfy §0, an unfixable checker exit 2, or
conflicting documents that §0 does not settle.

## 7. Migration history

PR #397 addressed three sources of drift:

| Before                                                                                             | Change                                                                                             | What future work should preserve                                  |
| -------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Feature code was spread across `pages/`, `form/`, `initialForm/`, `MainPageHelpers/`, and `util/`. | Feature internals moved into `features/<name>/{data,ui}`; top-level screens stayed in `pages/`.    | Keep a feature's internals together and keep pages flat.          |
| Tokens lived in `util/theme/`, and screens used Material defaults directly.                        | Tokens moved to `design_system/tokens/`; app primitives were added under `design_system/widgets/`. | Use the current token paths and app primitives for new UI.        |
| Placement, layer direction, widget choice, and shell ownership relied on prose.                    | Rules 0.10–0.14 gained checks in `tool/check_guidelines.sh`.                                       | Satisfy the rules even where neighboring code still carries debt. |

Feature destinations from that migration:

| Feature            | Responsibility                                                             |
| ------------------ | -------------------------------------------------------------------------- |
| `feel_good`        | Gallery items and image picker repository                                  |
| `home`             | Name bar, quote card, reminders, main-page list                            |
| `journal`          | Gratitude / thank-you flow                                                 |
| `notifications`    | Reminder widgets and notification repository                               |
| `onboarding`       | Initial form pages, country selector, sign-in callback                     |
| `personal_plan`    | Plan UI, custom categories, phone-page forms, share/export                 |
| `phone`            | Emergency contacts / SOS                                                   |
| `positive`         | Virtues / positive traits                                                  |
| `shell`            | Shared app UI moved out of `util/`, such as toasts and directional widgets |
| `speech_dictation` | Dictation session and suffix action                                        |
| `wellness_tools`   | Video player pieces                                                        |
| `wizard`           | Wizard step and actions                                                    |

`mood_medicine` and `remember_to_breathe` already had feature directories.
Use `remember_to_breathe` as the reference for the `data/` + `ui/` split,
with the legacy exceptions called out in the worked example. The migration
left existing files in place where moving them was outside its scope.
