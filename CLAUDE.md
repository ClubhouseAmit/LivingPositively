# Project Instructions

## Engineering principles

Read [`AGENTS.md`](./AGENTS.md) before doing any architecture, design, or code-authoring
work in this repo. It defines mandatory rules for this project (volatility-based design,
no speculative abstraction, convention-over-novelty, when to stop and ask a human) that
override generic instincts like "extract a method" or "add an interface for reuse."

## UI / design work

Before building or modifying any UI (screens, widgets, buttons, cards, theming), read
[`DESIGN.md`](./DESIGN.md) first. It defines the color tokens (`AppColors`), typography,
border radii, shadows, and reusable component patterns (`myText`, `ConfirmationButton`,
`CancelButton`, etc.) that all screens must use instead of ad-hoc styling.

Do not hardcode colors, font sizes, radii, or shadows that duplicate what's already a
token in `DESIGN.md` — reference the token instead.
