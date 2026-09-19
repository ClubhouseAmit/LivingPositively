# Project Instructions

## Before you write code

Read [`AGENTS.md`](./AGENTS.md) — **section 0 first**. It is one screen. It is the only
set of rules in this repo that is mechanically checked, and it is checked.

**Where anything in this repo disagrees with `AGENTS.md` section 0, section 0 wins.**

Sections 1–11 of that file are the reasoning behind section 0 (volatility-based design,
no speculative abstraction, convention-over-novelty, when to stop and ask a human). They
override generic instincts like "extract a method" or "add an interface for reuse" — but
they do not override section 0, and satisfying them is not a substitute for it.

## Before you say the work is done

```
tool/check_guidelines.sh        # must print "0 violations"
flutter analyze
flutter test
```

Quote the output. Do not describe it, and do not report work complete without it.

## UI / design work

Before building or modifying any UI (screens, widgets, buttons, cards, theming), read
[`DESIGN.md`](./DESIGN.md) first. It defines the color tokens (`AppColors`), typography,
border radii, shadows, and reusable component patterns.

Spacing and radius tokens are enforced by `AGENTS.md` 0.5 — raw numbers are rejected
there, including numbers that happen to equal a token's value. Colors, fonts, and shadows
are not yet machine-checked; follow `DESIGN.md` for those by hand.
