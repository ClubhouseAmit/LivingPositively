# Figma-vs-Implementation Diff Process

How to audit a screen for design fidelity with maximum accuracy in one pass,
without needing a human to catch what got missed. Give this file to a fresh
agent along with: the screen/flow to audit, and (if known) the Figma node ID
or URL.

## How to use this file

**Read it before the first edit, and re-read Step 7 before writing any widget.
Not after the review.**

On #338 this file gained five new sections in a single session and was
consulted, while coding, zero times. Every rule broken in that session was a
rule written into this file by the same agent that then broke it — including
the paragraph in Step 7 about not inventing a layout primitive, violated
minutes after being written.

Writing a lesson down *feels* like closing the loop, and that feeling is the
trap: it converts the document into a place to file regrets instead of a
checklist to run. A rule you authored is not a rule you followed. If you have
just added something to this file, that is precisely the moment you are most
likely to violate it, because the lesson feels discharged.

**One violation of "adopt, don't invent" means check every altitude, not the
one you were caught at.** On #338 the same error happened twice within an
hour: first hand-rolling a per-screen action button when `WizardStepPage`
already owned the buttons, then — after that was corrected — hand-rolling
block/gap widgets when `formpagetemplate.dart` already defined
`_gapWithinBlock` / `_gapBetweenBlocks` / `_buildTitleBlock`. Fixing the
altitude the reviewer named and not sweeping the rest is the "a defect is a
sample from a category" rule (Step 7) applied to architecture. When adopting a
sibling flow's structure, enumerate *all* of it — page frame, block builders,
gap constants, control widgets — before writing anything.

Core principle: **enumerate every property, don't sample the obvious ones.**
Freehand visual comparison of two screenshots has a low, inconsistent ceiling
— it finds a few things per pass and always misses more. Structured
value-to-value diffing of literal properties does not.

Third principle, and the one this process kept violating: **geometry is
measured, never estimated.** Colour, weight and radius can be read off the
source and diffed as values; position and spacing cannot. Every time spacing
was set by looking at the frame and picking a plausible number, the reviewer
found it. The design's exact geometry is free — it is `pos` and `size` in the
manifest — so there is never a reason to guess. If a number in a layout can't
be traced to a node, it's wrong.

Second principle, learned the expensive way on #338: **orient before you
answer.** Every check below can be run in two modes — to confirm something you
already suspect, or to discover what you don't know to look for. Run them in
discovery mode first. A `git log` read to answer "was this already fixed?"
that ignores the new architecture in the same output, or a per-screen audit
that never compares the screens to each other, will pass its own completeness
gate and still miss the largest finding on the screen.

## Inputs you need before starting

- `figma_full_dump.json` at the repo root — a Figma API dump (`GET
  /v1/files/:key/nodes?ids=...`). **Only covers the page(s)/node(s) it was
  fetched for.** If the screen you're auditing isn't in it, that doesn't
  necessarily mean it needs re-fetching — check first (see Step 0). If it
  really is missing, re-fetching needs a Figma personal access token (ask the
  user; don't dig for one in env vars/history unprompted).
- `designs/figma_frames.md` — a curated frame↔file mapping. **Treat it as a
  lead, not ground truth.** It was written for "13 main frames" when the file
  actually has 20 top-level frames, and it doesn't cover every screen. Verify
  its claims the same way you'd verify anything else (Step 0), don't assume.
- `DESIGN.md` (repo root) — design tokens (colors, radii, shadows, type
  scale). Cross-check any color/radius/shadow finding against this before
  reporting it as new; it may already be documented (or the doc itself may be
  stale — flag that too if so).

## Step 0 — Establish the frame ↔ source-file mapping with a hard anchor

Don't guess the Dart file from memory or trust a doc's file-path claim
unverified. The reliable anchor is the localization string:

1. Read the Hebrew (or other locale) text visible on screen.
2. Grep `lib/l10n/app_he.arb` (or the relevant locale file) for that string to
   get its `.arb` key.
3. Grep `lib/` for that key (e.g. `appLocale.someKey` or
   `AppLocalizations.of(context)!.someKey`) to get the exact widget file(s).
4. If several screens share one template file (common in this codebase —
   e.g. `lib/form/formpagetemplate.dart` backs 4 different onboarding steps),
   identify which specific data/config drives this screen's instance (look
   for a `retrieveInformation`-style lookup keyed by a collection/step name).

This is exact and cheap. It replaces both "trust the doc" and "grep for
generic screen names," either of which can silently point at the wrong file
or miss a shared-template screen.

Delegate this to a general-purpose agent when the mapping isn't already
obvious — it's a search-heavy task that shouldn't burn main-context tokens.

### Then map the flow and its shell, before auditing any single screen

A screen is almost never the unit the user experiences. Before opening a
frame, answer three questions:

1. **What are all the screens in this flow?** List them in order.
2. **What hosts them?** Find the parent that owns the step list, the header,
   the progress indicator and the navigation callbacks. It is a different file
   from every screen, and it is where screen chrome lives.
3. **Does a sibling flow in this codebase already have a shell for the same
   job?** If so, read it in full now — not as a token lookup, but as the
   pattern this flow is probably supposed to match.

On issue #338 all three answers were available in the first five minutes and
none of them was asked. `lib/form/` had a wizard shell — `wizard_step.dart`,
`wizard_steps.dart`, introduced by the immediately-preceding PR — in which
the header, the step dots and the **primary button all belong to the wrapper**
and only step content swaps. The intro flow being audited was the pre-wrapper
shape, with each of its three screens carrying its own `Scaffold` and its own
buttons. The audit never noticed, and the fixes that followed hand-rolled a
third, fourth and fifth variant of the same button.

**Read `git log` for structure, not just for "was this already fixed".** A
`--stat` on the last few merged PRs is the cheapest possible signal that a
pattern was recently introduced; new files named for an abstraction
(`wizard_step.dart`) are that signal. Running that command to answer one
narrow question and discarding the rest of its output is how a whole
architecture gets missed.

## Step 1 — Extract the full Figma property manifest

Don't hand-pick "the title, the button, the border." Walk the *entire* node
subtree of the frame and pull every leaf's full property set: type, text,
resolved text style (font/weight/size/lineHeight/align), resolved fill/stroke
colors (as hex, not raw 0-1 floats), stroke weight/dash pattern, corner
radius, effects (shadows), position/size, and linked shared-style names.

Use `designs/figma_lookup.py` — a small indexed helper built for exactly this
(see its docstring for full usage) — instead of re-deriving a tree-walk
script each time:

```bash
python3 designs/figma_lookup.py list-frames "Android Large"   # discover frames
python3 designs/figma_lookup.py find-text "some hebrew substring"  # locate a node/frame by content
python3 designs/figma_lookup.py manifest 1660:2020             # full property manifest, one JSON line per node
python3 designs/figma_lookup.py manifest 1660:2020 --type TEXT       # just text + textStyle, no icon/vector noise
python3 designs/figma_lookup.py manifest 1660:2020 --decorated-only  # just shapes/cards/buttons (radius/fill/dash)
python3 designs/figma_lookup.py node 1660:2020                 # raw node JSON, for anything the manifest doesn't surface
```

Use `--type`/`--decorated-only` instead of piping `manifest`'s output through
a throwaway `python3 -c "..."` filter — that was the actual gap the first
time through this process (the manifest already had all the data; it just
had no way to filter it). If you redirect `manifest` to a file to reload
later, keep that file pure JSONL — don't mix it with `node`'s pretty-printed
output or your own header lines in the same file, or reloading it breaks.

`manifest` already resolves colors to hex and inlines linked shared-style
names (`linkedStyles`) — no need to hand-convert 0-1 floats or cross-reference
the `styles` catalog manually. It's read-only and regenerates its index from
`figma_full_dump.json` on every run, so it never goes stale relative to the
dump. If you need a field the manifest doesn't include, use `node` to inspect
the raw JSON and extend `FigmaIndex._manifest_walk` rather than writing a
one-off parser.

Run this per frame, not per element-you-thought-to-check.

If the same template backs multiple steps (Step 0, case 4), pull the
manifest for **all** instances once — differences between them tell you
what's supposed to vary per-step (copy) vs. what's supposed to be identical
(the shared visual spec), which is exactly the signal you need for "does the
implementation deviate from the *template*."

**Also resolve shared-style linkage, don't stop at raw values.** Many nodes
carry a `styles` field (e.g. `"styles": {"fill": "76:512"}`) pointing at a
named entry in the dump's top-level `styles` catalog (`data['nodes'][...]
['styles']`, keyed by the same ID, with a `name`/`styleType`). Resolve this
for every node that has it and include the style name in the manifest. This
gives two things raw values alone don't:
- Findings can cite the design system's own token name ("should be Figma
  style `grey`") instead of just a hex/size number — more useful to whoever
  fixes it.
- It surfaces a *third* kind of drift, independent of the code entirely:
  whether a node's literal value still matches what its own linked style
  currently resolves to (Figma-internal staleness — a style got edited but
  this node wasn´t updated, or vice versa). Note this as its own category if
  found; it's not an implementation bug and doesn't belong in the same issue
  as a code-vs-design mismatch.

Don't assume shared styles exist for everything — check first. In this
codebase's file, only `fill`/`stroke` color is ever linked to a shared style;
there is no shared *text* style (no combined font/size/weight token), so
font size and weight really are hand-set per node and must be diffed as raw
numbers — there's no name to shortcut to.

### Turn the coordinates into a spacing table — this is the step everyone skips

`manifest` reports `pos` and `size` for every node. Those two fields are the
entire design spec for geometry, and they are useless until someone subtracts
them. **Do the subtraction, and write the result down as a table, before
writing a single line of layout code.**

Convert to frame-local first (`node.pos - frame.pos`), then list, in document
order: each element's top, its height, and the gap to the element above it.
For frame 28 on issue #338 that table is:

| Boundary | Gap |
|---|---|
| skip link top | 51 |
| title top | 104 |
| title → subtitle | 16 |
| subtitle → first field group | 45 |
| label → its own field | 5 |
| field group → next field group | 16 |
| last field → primary button | 111 |
| button → step dots | 28 |

Five minutes of arithmetic on data already in context. On #338 it was never
done, and every spacing constant in the fix — 8, 12, 16, 24 — was instead
guessed from looking at the frame. Four of them were wrong, the reviewer
caught them by eye, and the round trip cost far more than the subtraction
would have.

**Measure between container/group nodes, not leaf text nodes.** A `TEXT`
node's box carries line-height slack that the painted glyphs don't, so gaps
derived from leaf text boxes are noisy and produce phantom findings. Frame 28
wraps each label+field pair in a `GROUP` (`Group 141`/`142`/`143`, 90pt tall,
106pt pitch) — those are the boxes to diff. Prefer the named container every
time one exists; fall back to leaves only when it doesn't, and say so.

**`manifest` reports hidden paints as if they were painted.** Figma keeps a
fill/stroke entry in the array and flips `"visible": false` on it; the
manifest walk does not check that flag, so a hidden paint shows up as a real
colour. On issue #338 node `1660:2320` — the "fill later" secondary action —
reported `fills: ["#A688F8"]` when the design actually renders it as bare
purple text on no background, and node `1660:2319` reported a stroke that
isn't drawn. Reading the manifest alone would have confirmed the exact
opposite of the truth on that screen's single most important finding.
Until `_manifest_walk` filters `visible == false` paints, **confirm any
fill/stroke that decides a structural question against `node <id>` raw JSON**
— particularly "is this a button or a link", where a phantom fill turns a
text link into a solid pill. The same applies to `visible: false` child nodes
(component defaults such as a leading `icon/add`) which the manifest lists as
present.

**`manifest` reports one style per text node, but Figma styles text per
character.** A `TEXT` node carries `characterStyleOverrides` (one style id per
character) and a `styleOverrideTable` keyed by those ids. The manifest surfaces
only the node-level `style` and `fills`, so a node whose paragraphs differ reads
as uniform.

On issue #338 node `1660:2317` — the safety-plan subtitle — reports grey and
Medium at node level. Its overrides say otherwise:

| run | applies to | override |
|---|---|---|
| 18 | first paragraph | `fontWeight: 400` (node says 500) |
| 16 | second paragraph | `fills: #01B91E` — green (node says grey) |

The implementation already had that paragraph green and correct. Reading the
manifest alone "corrected" it to grey, which the reviewer caught on the render.
**Whenever one text node holds copy that the design shows in more than one
colour or weight — any multi-paragraph block — dump `node <id>` and walk
`characterStyleOverrides` before diffing it.** Same failure shape as the hidden
paints above: the manifest's answer is true of the node and false of the pixels.

## Step 2 — Extract the full Dart property manifest

Delegate to an agent (this is a large-context reading task): "read file X,
and for every `TextStyle`, `BoxDecoration`/`Container` color+border+radius,
`EdgeInsets`, and shadow/effect on this screen, report the literal value and
`file:line`. Resolve helper functions (`myText`, `ConfirmationButton`,
`primaryButtonStyle`, etc.) to their actual underlying values — don't stop at
the helper call site." Explicitly ask it to include the **screen's
container/AppBar/theme wrapper**, not just the content widgets — that's where
"invisible" effects like default elevation/shadows live.

Watch for:
- Colors as theme tokens (`colorScheme.primary`, etc.) rather than literals —
  note the token name; a mismatch there traces back to `AppColors` in
  `app_theme.dart`, a different fix than a mismatch in the widget itself.
- Default framework behavior the source doesn't make explicit (e.g. a plain
  `AppBar` has default elevation/shadow unless `elevation: 0` is set — that's
  a real visual effect even though no line of code "adds" it).

## Step 3 — Match by role and diff every shared property

Build a table: Figma node → Dart widget, matched by semantic role (title,
subtitle, list-item-text, chip/suggestion, primary-button, header-container),
not by "these seem related." For every matched pair, diff **every** property
both manifests define for it (size, weight, color, radius, border style,
shadow, alignment) — not just the property that looked different at a
glance. A mismatch you weren't looking for is still a mismatch.

Report as a table, one row per property per element — this is what makes
"what did I miss" answerable by re-reading the table instead of re-staring at
screenshots.

**Then diff the same role across screens, not only against its own frame.**
A per-screen table cannot surface an inconsistency that only exists *between*
screens, because no row ever compares two screens to each other. Add one table
whose rows are roles and whose columns are the screens in the flow —
primary button, secondary action, title, field container, header control —
and fill in the implementation for each cell. Anything that varies down a
column is either a design difference you can point at in the frames, or an
accident.

On issue #338 the primary button was full-width with radius 20 on one screen,
`fieldWidth` at height 52 on the next, and intrinsic-width on the third —
three implementations in three files. All three were written into the audit,
each in its own table, and the inconsistency was invisible because nothing
ever put them side by side. The reviewer found it in seconds by clicking
through the flow and watching the button move.

The question that table forces, and that a per-screen audit never asks:
**why is the same control implemented differently here, and who should own
it?** That question leads to the shell, which is where the fix usually is.

**Then walk it backwards: Dart → Figma.** A table keyed on Figma nodes can
only ever surface things the design *has*. Anything the implementation paints
with no design counterpart gets no row and is structurally invisible to this
step, no matter how carefully the table is filled in. On issue #338 that hid
a grey `AppBar` band across the top of all three intro screens — the design
frames have no app bar at all — which never appeared in the audit and was the
first thing the reviewer saw. So enumerate the implementation side too: every
`AppBar`, `bottomNavigationBar`, `Scaffold` background, `Divider`, decoration
and spacer the screen paints, and give each one a verdict of *in design* /
*deliberate addition* / *should not be there*. Screen chrome lives in the
parent widget, not the page widget, so this pass has to read the parent.

## Step 4 — Completeness gate before reporting

Before writing up findings, confirm every row from Step 1's manifest has an
explicit verdict: matched / mismatched / not-applicable (e.g., platform
chrome, expected per-step copy difference). "I found N differences" is not
the stopping condition — "every property has a verdict" is. This is the
single biggest lever against the "you missed X" problem: it converts a
sampling process into an enumeration process.

## Step 5 — Render and measure. Not optional, not last.

**Correction to earlier guidance:** this step used to say "reserve visual
comparison for what source can't tell you." That was wrong and cost roughly
fifteen review rounds on issue #333. `flutter analyze` and `flutter test`
prove the code compiles and behaves; they say *nothing* about pixels. Render
after every visual change, and never report a visual result you have not
looked at.

**Capturing is not comparing.** On issue #338 a screenshot was taken, glanced
at for "no overflow, no blank region", and the change reported as verified —
the design frame was never opened next to it. The reviewer put the two images
side by side and the answer was obvious in seconds: wrong dot shape, a grey
app-bar band, and the button floating mid-screen above a large void. A
screenshot you did not diff against the design reference is worth nothing;
it only proves the app didn't crash. So: **put the two images side by side
and walk the frame top to bottom** — every band of content, in order, against
the design's node list. Say what each one is and whether it matches. If you
cannot produce the design reference to compare against, say that you rendered
but could not compare, rather than implying the render validated anything.

**You do not need a Figma export to know the design's geometry.** This step
reads as "get two images and compare them", and getting the reference image
needs a personal access token — so the whole step gets skipped whenever the
token isn't to hand, which on #338 was every single time. That reasoning is
wrong. Only the *render* side needs measuring; the *design* side is already
exact in the manifest's `pos`/`size` (see Step 1's spacing table). An image
diff is a convenience, never the prerequisite.

And the render side does not need an image either. A widget test can read
exact logical geometry, with the view pinned to the Figma frame's own width so
the numbers are directly comparable to frame-local coordinates:

```dart
tester.view.devicePixelRatio = 1.0;
tester.view.physicalSize = const Size(360, 800); // the frame's own size
addTearDown(tester.view.reset);
// ...
final gap = tester.getTopLeft(find.byType(TextFormField)).dy -
            tester.getBottomLeft(find.text(label)).dy;
expect(gap, closeTo(5, 1)); // Figma: label -> field is 5pt
```

That turns the spacing table into assertions that fail in CI instead of in
review. Do this for the gaps that carry the design's rhythm — the ones in the
Step 1 table — not for every pair. **A gap you asserted cannot silently drift;
a gap you eyeballed always does.**

**A narrowed scope does not narrow the render.** When the task is one slice
of a fidelity fix ("just the fonts"), the screenshot still shows the whole
screen and the reader still judges the whole screen. Report the delta between
the render and the *design*, not between the render and the slice — and lead
with what is still wrong, not with what the slice achieved. "Both decisions
implemented, tests pass" followed by a list of caveats reads as done even
when the caveats are the larger half.

Get a real screenshot without needing the user:

```bash
xcrun simctl list devices | grep -i booted        # find the simulator
xcrun simctl io booted screenshot /path/shot.png  # capture
```

Then **measure both images with the same scan** rather than eyeballing them
or comparing a screenshot against Figma *node boxes*. A text node's box
carries auto-height slack the painted glyphs don't, so box-vs-ink comparisons
produce phantom discrepancies. `designs/ui_render_diff.py` reports ink bands
(y, height, gap-to-previous, left/right inset) in logical units:

```bash
python3 designs/ui_render_diff.py shot.png --scale 3               # 3x device
python3 designs/ui_render_diff.py design.png --scale 2 --skip-top 60
python3 designs/ui_render_diff.py design.png --scale 2 \
    --against shot.png --against-scale 3        # side-by-side gap deltas
```

Export the Figma reference at a known scale via the Images API (below) so the
`--scale` divisor is exact. Compare gaps ink-to-ink; both sides measured the
same way are directly comparable even at different device widths. Watch for
index drift when the two sides have different content (an extra row, wrapped
vs single-line text) — the tool warns about this.

This is what caught a continue button rendering 20px into the iPhone
home-indicator zone, which no amount of source reading had surfaced.

Two things this measurement cannot see, so check them separately:
- a *blank* region means a thrown exception, not a spacing bug — run the
  widget test to get the stack trace.
- colour/weight/radius still come from Step 1's manifest; ink bands only
  describe geometry.

For anything genuinely runtime-only (theme-composition shadows, real device
font rendering):

1. **Normalize scale first.** A Figma export and a simulator/device
   screenshot are almost never at the same px-per-point ratio. Compute it
   from a known dimension (e.g. the Figma frame's declared width vs. its
   exported pixel width) before comparing anything spatial.
2. Get the reference image via the Figma Images API, not a guess:
   `curl -s -H "X-Figma-Token: $TOKEN" "https://api.figma.com/v1/images/<FILE_KEY>?ids=<NODE_ID>&format=png&scale=2"`
   → returns a short-lived S3 URL → download that.
3. Prefer targeted, programmatic checks (crop a region, sample a pixel color,
   measure a glyph's bounding box) over repeated freehand "look again" passes.

## Step 5b — Attaching screenshots to the issue (no manual drag-in needed)

Use `designs/gh_upload_image.sh <owner/repo> <path/to/image.png>` — it uploads
to the same endpoint GitHub's own paste/drag-drop uses
(`uploads.github.com/user-attachments/assets`), authenticated with `gh`'s own
token, and prints back a `https://github.com/user-attachments/assets/<uuid>`
URL. Embed it directly in the issue body with `![alt](<url>)`.

Two things that aren't optional:
- The URL 404s until it's actually referenced inside a **saved** issue/PR
  body (`gh issue create`/`gh issue edit`/`gh issue comment`) — uploading
  alone isn't enough, and that save is what activates it. Upload, embed in
  the body text, then write/edit the issue — don't check the URL before that
  last step or it'll look broken when it isn't.
- A plain unauthenticated `curl` on the URL returns 403 even once live —
  that's an unrelated signed-CDN quirk, not a sign it's broken. It renders
  fine inside an actual GitHub page. Verify liveness with
  `curl -sI -H "Authorization: Bearer $(gh auth token)" <url>` (expect 302),
  not a bare `curl`.
- Filenames with spaces (common for Figma's own PNG exports, e.g.
  `Android Large - 35.png`) need URL-encoding in the upload request's `name`
  query param — the script already handles this, but if you ever build the
  request by hand, don't skip it (raw spaces in the URL silently break the
  upload with an empty response, no clear error).

This isn't a documented/versioned API — it's the same endpoint the web UI
calls, verified working manually. If it stops working, this script is the
one place to fix it; fall back to committing images under
`designs/issue-screenshots/` and linking `raw.githubusercontent.com` URLs,
which is slower but doesn't depend on undocumented behavior.

## Step 6 — Report format

- Structural findings: one bullet per confirmed mismatch, with `file:line`
  and a one-line "design says X, code does Y."
- Typography/token findings: a table (element | Figma spec | code value |
  diff), since these are naturally tabular and a table makes gaps visible at
  a glance.
- Split **systemic** issues (a one-line-per-style fix affecting many
  screens, e.g. a hardcoded `FontWeight.bold` used everywhere) into their own
  issue, separate from **screen-specific structural** issues — they have
  different fixes and different owners' attention spans.
- Don't flag things that are known-deliberate — e.g. `Rubix` as the
  registered font-family name is an intentional, documented deferral
  (`docs/adr/ADR-005-resolve-ux-gaps.md`), not a bug. Check ADRs / DESIGN.md
  before flagging something that might already be a known, accepted tradeoff.

## Step 7 — Structure, not patches

If the implementation's widget tree doesn't mirror the design's container
tree, per-gap tuning never converges — you fix one number, the next review
finds another. A Figma frame is already a hierarchy of *named* containers
(`Frame 210` = title block, `Frame 216` = items block holding the rows plus
the "add your own" link, `Frame 223` = suggestions block). Build the widget
tree isomorphic to it, one builder per named container, with spacing
constants named after the boundaries they represent. Then spacing and
alignment are properties of the structure and the structure enumerates what
must be checked.

**Every spacing constant must cite its source.** A number in the code is
either a value from Step 1's spacing table — in which case name the node it
came from — or it is invented. There is no third category, and invented
numbers are the ones the reviewer finds:

```dart
// Figma frame 28, Group 143 -> Group 141: 16pt between field groups.
const double _gapBetweenFieldGroups = 16;
```

not `const SizedBox(height: 12)` with no comment, which is what shipped on
#338 in four separate places. If you cannot name the node, you are guessing —
go back to Step 1 and do the subtraction. Reaching for a round number (8, 12,
16, 24) or a ScreenUtil `.h` because it "looks about right" is the tell.

**Conform to the structure that exists before inventing one.** The isomorphic
widget tree above is the goal, but if a sibling flow already has a shell that
does this job, the work is to *adopt* it, not to build a parallel one. Check
before writing any new layout widget: does this codebase already have a
wrapper that owns the header, the progress indicator and the action buttons?

The failure mode is subtle because each individual step looks reasonable.
On issue #338 the fixes went: give screen 1 a local `_actionButton`; give
screen 3 its own bottom-pinned `Column`; give screen 2 a `_primaryActionButton`
— each a defensible local change, and together a fourth and fifth
reimplementation of a wrapper that already existed one directory away. Every
one of those helpers was deleted when the flow was finally ported to
`WizardStep`/`WizardStepPage`.

So: **when a fix requires inventing a layout primitive — a button wrapper, a
page frame, a bottom-pinned action row — stop.** That is the signal that the
work belongs one level up, in the shell, and quite possibly in a shell that is
already written. Ask the reviewer before porting; it is a larger change than a
fidelity fix and it changes the flow's navigation contract.

Two habits that cost the most on issue #333:
- **Audit both axes.** An audit table with columns for colour/font/border/
  radius/*vertical gap* and none for horizontal alignment or inset cannot
  ever surface a centred link the design start-aligns, no matter how
  carefully it is iterated. Record x, width, left/right inset and alignment
  for every element, and audit *every* file feeding the screen — the
  AppBar/header file too, not just the body widget.
- **A defect the reviewer finds is a sample from a category.** Sweep the
  whole category (all alignments, all insets) before replying; fixing only
  the named instance forces another round.

**Re-run Step 4's completeness gate after implementing, not only after
auditing.** The gate is cheap the first time because the table is fresh; the
expensive failure is building the table, fixing a subset, and then reporting
against the subset. Before saying anything about a change, walk the table
again and mark each row done / deliberately deferred / still open, then put
the deferred and open rows in front of the reader — those are the ones that
decide whether the screen looks right.

Never report "done". State what was verified and name what was not.

When the reviewer pushes back, **stop and enumerate what was missed before
touching any code.** Jumping straight to a fix discards the most useful thing
in the exchange — the reviewer's read of *why* it was missed — and produces
another partial pass aimed at whatever was named first.

## Known gotchas from doing this the first time

- `figma_full_dump.json` may only contain one Figma *page* (check
  `data['nodes']` — if it's got exactly one top-level key, that's the scope).
  A screen genuinely missing from it may live on a different page, not
  require a re-fetch of the same page.
- Frame node IDs use colons (`1660:2020`); Figma share URLs use hyphens
  (`1660-2020`) — convert when moving between a pasted URL and API/dump
  lookups.
- **Absence of an argument is not absence of behaviour.** Each of these
  silently added invisible space on issue #333 and is invisible in a source
  read: `ListView`/`BoxScrollView` with `padding: null` inherits
  `MediaQuery.padding` (safe-area insets) as sliver padding — pass
  `EdgeInsets.zero`, or better, if it's `shrinkWrap: true` +
  `NeverScrollableScrollPhysics` inside a `SingleChildScrollView`, delete the
  ListView and use a plain `Column`; `TextButton`/`IconButton` default to a
  48px minimum tap target, inflating a 32px design box (resetting it trades
  away the accessibility target — flag that, don't do it silently);
  `AutoSizeText`'s `maxFontSize` *grows* text to fill space rather than only
  capping shrinkage; nothing insets the bottom for the home indicator unless
  you add `SafeArea`.
- **`myAutoSizedText`'s `maxFontSize` argument is the size that paints, and
  the style's `fontSize` is inert.** With `maxLines: null` inside an
  unbounded-height `SingleChildScrollView`, every candidate size "fits", so
  `AutoSizeText` settles on its ceiling. On issue #338 titles declared at
  `40.sp` painted at 60 and buttons declared at `20.sp` painted at 44 — so an
  audit that reads `fontSize` off the source reports numbers that are 1.4–2.6×
  smaller than what the user sees, and patching `fontSize` alone changes
  nothing at all. Measure what renders (pump the widget and read the resolved
  style off each `Text`) before quoting any size from source. The durable fix
  is to stop sizing through `AutoSizeText`: a plain `Text` at an explicit size
  cannot drift from its own declaration.
- **`.sp` is inert in widget tests that set only `surfaceSize`.** ScreenUtil
  reads the *window*, which `tester.binding.setSurfaceSize` does not change,
  so `.sp` scales against the default 800px test window — a factor of 2.22 at
  `designSize: Size(360, 690)` — no matter what `surfaceSize` says. Layout
  assertions written this way are validating a geometry no device produces.
  Drive the view instead, and reset it:
  ```dart
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.reset);
  ```
  Pin the width to the Figma frame's own width (360 here) and `.sp` resolves
  1:1, so assertions can be the design's literal numbers. Production is fine —
  `main.dart` puts `ScreenUtilInit` above `MaterialApp` with `builder:` — this
  is a test-harness artifact only, so **confirm a suspicious measured size
  against a real render before reporting it as a bug.**
- `AutoSizeText` asserts `maxFontSize % stepGranularity == 0`, so pass a
  whole-number design size — never a ScreenUtil-scaled `.sp` value, which is
  fractional and throws at runtime.
- `IntrinsicHeight` + `Spacer` (the usual "bottom-anchored button inside a
  scroll view" recipe) throws when descendants don't support intrinsics
  (`AutoSizeText`, `DottedBorder`) and renders a blank body. Use
  `Column(children: [Expanded(child: SingleChildScrollView(...)), <pinned>])`.
- **Run `flutter attach` from the worktree you are editing.** It syncs
  sources from the current directory, so attaching from the main checkout
  hot-restarts the device with *that* code and your edits appear to have no
  effect. The `l10n.yaml` path in its output tells you which project it used.
  Find the URI with `ps aux | grep dds` and reuse it:
  `flutter attach --debug-uri=<uri> -d <device-id>`, piping `R` then `d`.
- **A step that needs an artifact you don't have will be skipped, silently.**
  Step 5 reads as "export the frame, diff the images", the export needs a
  Figma token, and on #338 the token was never to hand — so the measurement
  never happened, on any screen, across many rounds, while the write-ups kept
  saying spacing had been addressed. When a step has a prerequisite you can't
  satisfy, don't drop the step: find the path to the same answer that has no
  prerequisite (here, manifest coordinates plus `tester.getRect`), or say
  out loud that the check did not run. Silent skipping is what turns one
  missing capability into a string of unverified claims.
- `gh gist create` does not support binary files — it can't be used to host
  screenshots for embedding in an issue. Attach images either by opening the
  issue in the browser and dragging files in, or by committing them
  somewhere fetchable and linking raw URLs (adds repo clutter — prefer the
  browser drag-in for one-off audits).
