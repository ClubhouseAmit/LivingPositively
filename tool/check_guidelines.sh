#!/usr/bin/env bash
# Machine-checkable subset of AGENTS.md section 0.
#
# This script is the SOURCE OF TRUTH for every numeric limit. AGENTS.md quotes
# these numbers; it does not restate them. If a limit changes, it changes here.
#
# Usage:
#   tool/check_guidelines.sh                 # your work: working tree + staged + branch
#   tool/check_guidelines.sh lib/foo.dart    # explicit files
#   tool/check_guidelines.sh --all           # whole repo (reporting only)
#
# Exit 0 = no violations in scope.
# Exit 1 = violations found.
# Exit 2 = the check could not run (bad ref, missing file, no git). NEVER silent.
#
# KNOWN CEILING — these checks are regex over text, not a Dart parse. They catch
# the common shapes, not every shape. Documented gaps: expression-bodied (=>)
# methods, signatures wrapped across lines, local functions with inferred or
# custom return types, spacing values laundered through a named constant. Do not
# read "0 violations" as "this code is good"; read it as "none of the shapes
# below were found". See tool/check_guidelines_test.sh for what is proven.
# ponytail: text heuristics; move to the `analyzer` package for a real AST if
# these gaps start getting exploited.

set -uo pipefail

git rev-parse --show-toplevel >/dev/null 2>&1 || {
  echo "check_guidelines: not a git repository" >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)" || exit 2

MAX_FILE_LINES=400     # a new .dart file under lib/
MAX_METHOD_LINES=80    # any single method, widget-building included
MAX_CLOSURE_INDENT=6   # member(2) > body(4) > inside a callback(6+)
BASE_REF="${CHECK_BASE_REF:-main}"

# --- file discovery -----------------------------------------------------------
# Default mode MUST see uncommitted work. An agent writes a file, runs this, and
# reports done — all before committing. Scanning only main...HEAD made the check
# pass on work it had never looked at, which is the failure this script exists
# to prevent.
FILES=()
case "${1:-}" in
  --all)
    while IFS= read -r p; do FILES+=("$p"); done < <(
      find lib -name '*.dart' ! -path '*/l10n/*' | sort)
    ;;
  "")
    tmpfile=$(mktemp) || {
      echo "check_guidelines: cannot create a temp file — refusing to scan nothing" >&2
      exit 2; }
    trap 'rm -f "$tmpfile"' EXIT
    merge_base=$(git merge-base "$BASE_REF" HEAD 2>/dev/null) || {
      echo "check_guidelines: cannot resolve base ref '$BASE_REF'" >&2
      echo "  set CHECK_BASE_REF=<ref>, or pass files explicitly" >&2
      exit 2; }
    {
      git diff --name-only --diff-filter=ACMR "$merge_base" -- 'lib/*.dart' 'lib/**/*.dart'
      git diff --name-only --diff-filter=ACMR --cached            -- 'lib/*.dart' 'lib/**/*.dart'
      git diff --name-only --diff-filter=ACMR                     -- 'lib/*.dart' 'lib/**/*.dart'
      git ls-files --others --exclude-standard                    -- 'lib/*.dart' 'lib/**/*.dart'
    # Read straight from the pipeline. This used to stage the list in
    # /tmp/.cg_files.$$ with stderr suppressed: on a read-only /tmp the write
    # failed silently, FILES came back empty, and the script reported
    # "0 violations" having looked at nothing. Fail-open, again.
    } 2>/dev/null | grep -v '/l10n/' | sort -u > "$tmpfile"
    while IFS= read -r p; do [ -n "$p" ] && FILES+=("$p"); done < "$tmpfile"
    ;;
  *)
    for p in "$@"; do
      [ -f "$p" ] || { echo "check_guidelines: no such file: $p" >&2; exit 2; }
      case "$p" in
        *.dart) FILES+=("$p") ;;
        *) echo "check_guidelines: skipping non-Dart file: $p" >&2 ;;
      esac
    done
    ;;
esac

fail=0
scanned=0
note() { echo "$1"; fail=1; }

# Offending import lines on stdin, per the bad_re/allow_re pair set by 0.11.
offenders() {
  if [ -n "$allow_re" ]; then
    grep -nE "$bad_re" | grep -vE "$allow_re"
  else
    grep -nE "$bad_re"
  fi
}
bad_re=""; allow_re=""

for f in "${FILES[@]:-}"; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  scanned=$((scanned + 1))

  # 0.1 one screen per file ----------------------------------------------------
  # Counts PUBLIC widget classes only. A private _FooState pairs with its public
  # widget (one screen, not two), and private _LeafCard widgets in the same file
  # are the idiomatic way to break a screen up — they are the fix, not the bug.
  screens=$(grep -cE '^(final |base |abstract |sealed )*class [A-Z][A-Za-z0-9_]* extends (StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget)' "$f")
  if [ "$screens" -gt 1 ]; then
    note "$f: $screens public widget classes in one file (max 1) [AGENTS.md 0.1]"
  fi

  # 0.2 file length ------------------------------------------------------------
  # Ratchet against the MERGE BASE, not the tip of main: otherwise independent
  # growth on main hides growth on this branch.
  case "$f" in lib/*)
    lines=$(wc -l < "$f" | tr -d ' ')
    if [ "$lines" -gt "$MAX_FILE_LINES" ]; then
      mb=$(git merge-base "$BASE_REF" HEAD 2>/dev/null || echo "")
      base=0
      [ -n "$mb" ] && base=$(git show "$mb:$f" 2>/dev/null | wc -l | tr -d ' ')
      base=${base:-0}
      if [ "$base" -eq 0 ]; then
        note "$f: new file is $lines lines (max $MAX_FILE_LINES) [AGENTS.md 0.2]"
      elif [ "$lines" -gt "$base" ]; then
        note "$f: $lines lines, over $MAX_FILE_LINES and grew from $base [AGENTS.md 0.2]"
      fi
    fi
  ;; esac

  # 0.3 method length ----------------------------------------------------------
  # Brace-bodied members, plus expression-bodied (=>) members, which are the
  # obvious way to launder a 300-line build method past a brace-only scan.
  out=$(awk -v lim="$MAX_METHOD_LINES" -v file="$f" '
    # brace-bodied: signature at 2-space indent ending in {, or a wrapped
    # signature whose continuation closes with ") ... {"
    !open && /^  [A-Za-z_@~].*\{[ \t]*$/            { open=1; kind="{"; start=NR; sig=$0; next }
    !open && /^  \) *(async|async\*|sync\*)? *\{$/  { open=1; kind="{"; start=NR; sig="(wrapped signature)"; next }
    # expression-bodied: "=> ... ;" possibly spanning many lines
    !open && /^  [A-Za-z_@~].*=>[ \t]*$/            { open=1; kind="=>"; start=NR; sig=$0; next }
    !open && /^  [A-Za-z_@~].*=> *[A-Za-z_].*\($/   { open=1; kind="=>"; start=NR; sig=$0; next }
    open && kind=="{"  && /^  \}$/    { n=NR-start+1; if (n>lim)
        printf "%s:%d: method is %d lines (max %d):%s [AGENTS.md 0.3]\n", file,start,n,lim,substr(sig,1,55)
        open=0; next }
    open && kind=="{"  && /^  \};?$/  { open=0; next }   # map/list field, not a method
    # A named-parameter-list constructor — `Foo({` opens the PARAMETER list,
    # not a body, and closes as `});`. Previously unrecognized: the "open"
    # state never cleared, so the checker kept scanning until some unrelated
    # later `^  }$` closed it, misreporting an ordinary constructor as a
    # 100+ line method. Same category as the map/list carve-out above.
    open && kind=="{"  && /^  \}\);?$/ { open=0; next }
    # An expression body ends at the FIRST line terminated by ";", at ANY
    # indent. Requiring indent 2 left "=>\n      value;" open forever, which
    # silently disabled every later check in the file.
    open && kind=="=>" && /;[ \t]*$/  { n=NR-start+1; if (n>lim)
        printf "%s:%d: expression-bodied member is %d lines (max %d):%s [AGENTS.md 0.3]\n", file,start,n,lim,substr(sig,1,55)
        open=0; next }
    END { if (open) printf "%s:%d: UNCLOSED member — checker could not parse past here [AGENTS.md 0.3]\n", file, start }
  ' "$f")
  [ -n "$out" ] && { echo "$out"; fail=1; }

  # 0.4 functions defined inside a callback ------------------------------------
  # Any local function declared at depth: return type may be a custom type or
  # absent, so match "<word> name(...) {" / "(...) async {" at indent >= 10.
  # "[^()]*" for the parameter list is what separates a DEFINITION from a CALL
  # that takes a closure: setState(() { and listen((e) { have parens inside.
  deep=$(grep -nE "^ {$MAX_CLOSURE_INDENT,}([A-Za-z_][A-Za-z0-9_<>,? ]*\s+)?[a-z_][A-Za-z0-9_]*\([^()]*\) *(async|async\*|sync\*)? *\{ *$" "$f" \
         | grep -vE '\b(if|for|while|switch|catch|return|else|case|do|try|setState)\b' || true)
  if [ -n "$deep" ]; then
    echo "$deep" | while IFS= read -r l; do
      echo "$f:${l%%:*}: function defined inside a callback — hoist it [AGENTS.md 0.4]"
    done
    fail=1
  fi

  # 0.5 raw numbers where a token belongs --------------------------------------
  # A spacing/radius slot takes AppSpacing.*/AppRadii.*/theme, or 0. Never a
  # number — not even one equal to a token's value, because the next person
  # cannot tell 20 from AppSpacing.xl by reading it.
  lits=$(grep -nE 'SizedBox(\.square)?\((width|height|dimension): *-?[0-9]|EdgeInsets(Directional)?\.(all|only|symmetric|fromLTRB|fromSTEB)\([^)]*-?[0-9]|BorderRadius\.(circular|all)\( *-?[0-9]|Radius\.circular\( *-?[0-9]' "$f" \
         | grep -vE '\((width|height|dimension): *0(\.0)?[,)]' || true)
  if [ -n "$lits" ]; then
    echo "$lits" | while IFS= read -r l; do
      echo "$f:${l%%:*}: raw number where an AppSpacing/AppRadii token belongs [AGENTS.md 0.5]"
    done
    fail=1
  fi
  # --- path-based rules -------------------------------------------------------
  # Normalise to a lib-relative path so the same patterns match a repo file
  # (lib/pages/x.dart) and a test fixture (/tmp/xxx/lib/pages/x.dart).
  rel="${f##*/lib/}"
  [ "$rel" = "$f" ] && rel="${f#lib/}"
  if [ "$rel" != "$f" ]; then

  # 0.10 where new code goes ---------------------------------------------------
  # The frozen trees predate feature-first organisation. They are debt, not a
  # template: editing them is fine, adding to them is not. Ratchet — only a file
  # with no version at the merge base is judged, so existing files stay legal.
  frozen=0
  case "$rel" in
    features/*|util/theme/*|util/layout/*|util/async/*|l10n/*|iFx/*|Locale/*) ;;
    pages/*|util/*|MainPageHelpers/*|form/*|initialForm/*)                     frozen=1 ;;
    */*)                                                                       ;;
    *)                                                                         frozen=1 ;;
  esac
  if [ "$frozen" -eq 1 ]; then
    mb=$(git merge-base "$BASE_REF" HEAD 2>/dev/null || echo "")
    if [ -z "$mb" ] || ! git show "$mb:$f" >/dev/null 2>&1; then
      note "$f: new file in a frozen tree — new work goes in lib/features/<name>/{data,ui} [AGENTS.md 0.10]"
    fi
  fi

  # 0.11 layer direction -------------------------------------------------------
  # Two directions, both greppable:
  #   data/ must not import a widget library — a renderer is not persistence.
  #   ui/   must not import a data-layer SERVICE. Models, types and the
  #         repository are the feature's public data surface; everything else in
  #         data/ is reached THROUGH the repository, never around it.
  # Ratchet by count against the merge base, so the existing violations park and
  # only a new one fails.
  bad_re=""; allow_re=""; why=""
  case "$rel" in
    features/*/data/*)
      bad_re='^import .*(package:flutter/(material|widgets|cupertino)\.dart|package:pdf/widgets\.dart)'
      why="data/ imports a widget library — rendering belongs in ui/" ;;
    features/*/ui/*)
      bad_re='^import .*features/[a-z0-9_]+/data/'
      allow_re='(_models|_types|_repository)\.dart'
      why="ui/ imports a data-layer service — go through the repository" ;;
  esac
  if [ -n "$bad_re" ]; then
    now=$(offenders < "$f" | wc -l | tr -d ' ')
    if [ "${now:-0}" -gt 0 ]; then
      mb=$(git merge-base "$BASE_REF" HEAD 2>/dev/null || echo "")
      was=0
      [ -n "$mb" ] && was=$(git show "$mb:$f" 2>/dev/null | offenders | wc -l | tr -d ' ')
      was=${was:-0}
      if [ "$now" -gt "$was" ]; then
        note "$f: $now layer violation(s), was $was at $BASE_REF — $why [AGENTS.md 0.11]"
      fi
    fi
  fi

  # 0.12 use the design-system component, not the Material widget it replaces -
  # Scoped to features/*/ui/ only: that's where 0.10 lets new UI code land,
  # and the only place these two components exist to be reached for.
  # TextButton/Card are named specifically because design_system/ has a
  # drop-in replacement for exactly those two today (AppButton, AppCard) —
  # this is not a blanket Material ban. Extend the list only as new
  # primitives ship; banning a widget with no replacement just blocks work.
  # Ratchet by count, same as 0.11.
  bad_re=""; allow_re=""; why=""
  case "$rel" in
    features/*/ui/*)
      # The word-boundary group is why this doesn't also flag myTextButton(
      # (DESIGN.md's legacy icon-button helper) or a MoodMedicineCard class —
      # both have a non-boundary character immediately before the match.
      bad_re='(^|[^A-Za-z0-9_.])(TextButton|Card)\('
      why="use AppButton/AppCard (design_system/) instead" ;;
  esac
  if [ -n "$bad_re" ]; then
    now=$(offenders < "$f" | wc -l | tr -d ' ')
    if [ "${now:-0}" -gt 0 ]; then
      mb=$(git merge-base "$BASE_REF" HEAD 2>/dev/null || echo "")
      was=0
      [ -n "$mb" ] && was=$(git show "$mb:$f" 2>/dev/null | offenders | wc -l | tr -d ' ')
      was=${was:-0}
      if [ "$now" -gt "$was" ]; then
        note "$f: $now new Material-widget call(s), was $was at $BASE_REF — $why [AGENTS.md 0.12]"
      fi
    fi
  fi

  fi
done

if [ "$fail" -ne 0 ]; then
  echo
  echo "Guideline violations above. See AGENTS.md section 0."
  exit 1
fi
echo "check_guidelines: $scanned file(s) scanned, 0 violations" \
     "(limits: file ${MAX_FILE_LINES}, method ${MAX_METHOD_LINES}, closure indent ${MAX_CLOSURE_INDENT})"
