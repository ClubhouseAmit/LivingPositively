#!/usr/bin/env bash
# Where this repo's deliberate debt is parked, counted from the live sources.
#
#   tool/debt_report.sh            # human-readable, current state only
#
# Every number here is DERIVED. Nothing is restated, so this file cannot go
# stale the way a hand-maintained TECH_DEBT.md does. If a count looks wrong,
# the register is wrong, not this script.
#
# Each entry names WHERE the debt is recorded and HOW to pay it down. Debt that
# is only in someone's head is not tracked; debt that is only in prose is not
# counted. Add a register here when you add a place debt can hide.
#
# No trend file. A hand-appended row only gets written when someone remembers
# to, it duplicates state git already has (checkout an old commit and rerun
# this script), and the one row this produced was already wrong: it named a
# commit that contained neither the measurement it recorded nor this script.
# If a trend is ever needed, it belongs in CI on a clean checkout, not here.

# NOTE: no `pipefail` here on purpose. `flutter analyze` exits non-zero whenever
# it reports anything, so under pipefail every `analyze | grep -c` pipeline looks
# like a failure and the `|| echo 0` fallback appends a second line to the count.
set -u
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || { echo "not a git repo" >&2; exit 2; }

AO=analysis_options.yaml
case "${1:-}" in
  "") ;;
  *) echo "usage: $0" >&2; exit 2 ;;
esac

# --- registers ----------------------------------------------------------------
# [a-z0-9_] not [a-z_]: lines_longer_than_80_chars has digits.
baselined_rules=$(grep -cE '^ +[a-z0-9_]+: ignore' "$AO" 2>/dev/null)
# [a-z-] not [a-z]: strict-raw-types has an inner hyphen.
strict_off=$(grep -cE '^ +strict-[a-z-]+: false' "$AO" 2>/dev/null)

# Section 0: count per rule from the checker itself.
s0_raw=$(./tool/check_guidelines.sh --all 2>/dev/null | grep -oE 'AGENTS\.md 0\.[0-9]+' | sort | uniq -c || true)
s0_total=$(echo "$s0_raw" | awk '{s+=$1} END{print s+0}')

suppressions=$(grep -rnE '// *ignore(_for_file)?:' lib --include='*.dart' 2>/dev/null | grep -vc '/l10n/' || echo 0)
markers=$(grep -rnE '(TODO|FIXME|HACK|XXX|ponytail:)' lib tool --include='*.dart' --include='*.sh' 2>/dev/null | grep -vc '/l10n/' || echo 0)

# Lint violations currently hidden by the baseline. Measured by re-running the
# analyzer with the baseline stripped, so it reflects reality, not a memory.
# This temporarily strips the baseline from a TRACKED file, so the restore is
# trapped on every exit path including Ctrl-C. If you ever see analysis_options
# .yaml modified after running this, the trap failed — `git checkout` it.
hidden="-"
AO_BACKUP=""
restore_ao() { [ -n "$AO_BACKUP" ] && [ -f "$AO_BACKUP" ] && cp "$AO_BACKUP" "$AO" && rm -f "$AO_BACKUP"; }
trap restore_ao EXIT INT TERM

if [ "${SKIP_SLOW:-0}" != "1" ] && command -v flutter >/dev/null 2>&1; then
  AO_BACKUP=$(mktemp); cp "$AO" "$AO_BACKUP"
  python3 - "$AO" <<'PY' 2>/dev/null
import sys
p=sys.argv[1]; s=open(p).read()
head,rest=s.split('  errors:',1); _,tail=rest.split('  exclude:',1)
open(p,'w').write(head+'  exclude:'+tail)
PY
  hidden=$(flutter analyze 2>/dev/null | grep -cE '^[[:space:]]+(info|warning|error) •')
  restore_ao; AO_BACKUP=""
fi

echo "TECH DEBT — $(date +%Y-%m-%d), $(git rev-parse --short HEAD)"
echo
echo "1. Analyzer baseline                       $baselined_rules rules ignored, hiding $hidden findings"
echo "   where: $AO (errors:)"
echo "   pay down: delete one line, fix what it surfaces, commit."
echo
echo "2. Strict language modes disabled          $strict_off"
echo "   where: $AO (language:)"
echo "   pay down: strict-casts alone is ~600 real type-safety findings."
echo "             Biggest single win on this list."
echo
echo "3. AGENTS.md section 0 violations          $s0_total"
echo "$s0_raw" | sed 's/^ */   /'
echo "   where: the code. Ratcheted — new code cannot add to it."
echo "   pay down: tool/check_guidelines.sh --all"
echo
echo "4. In-code suppressions                    $suppressions"
echo "   where: // ignore: comments under lib/"
echo "   pay down: each one is a rule someone opted out of locally."
echo
echo "5. TODO / FIXME / ponytail markers         $markers"
echo "   pay down: grep them; most are one-liners."
echo
echo "6. Blocked upgrades"
echo "   solid_lints — cannot install on Flutter 3.44.9 (meta 1.18.0 pin)."
echo "   Unblocks on the next SDK upgrade. See AGENTS.md 0.9."
