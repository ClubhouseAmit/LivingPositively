#!/usr/bin/env bash
# Proof that tool/check_guidelines.sh can fail. AGENTS.md 0.8 requires this:
# a check nobody has broken on purpose is not a check.
#
# Each case plants a known-bad (or known-good) file and asserts the expected
# exit code. Run it after ANY edit to check_guidelines.sh.
#
#   tool/check_guidelines_test.sh
#
# Exit 0 = the checker behaves as specified. Exit 1 = it does not.

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 2
CHECK=tool/check_guidelines.sh
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0

# expect <want-exit> <name> <<'DART' ... DART
expect() {
  local want=$1 name=$2 file="$TMP/t.dart"
  cat > "$file"
  "$CHECK" "$file" >/dev/null 2>&1
  local got=$?
  if [ "$got" -eq "$want" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1)); echo "FAIL: $name (want exit $want, got $got)"
  fi
}

# --- must PASS (exit 0): compliant code ---------------------------------------
expect 0 "tokens and a short method" <<'DART'
class AScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppSpacing.lg);
  }
}
DART

expect 0 "zero is allowed in a spacing slot" <<'DART'
class AScreen extends StatelessWidget {
  Widget build(c) => const SizedBox(height: 0);
}
DART

expect 0 "a map field is not a long method" <<'DART'
class C {
  final handlers = <String, int>{
    'a': 1,
    'b': 2,
  };
}
DART

expect 0 "private leaf widgets beside their screen are fine" <<'DART'
class MoodPage extends StatefulWidget {}
class _MoodPageState extends State<MoodPage> {}
class _FeatureCard extends StatelessWidget {}
class _PageHeading extends StatelessWidget {}
DART

expect 0 "setState with a closure is a call, not a definition" <<'DART'
class C {
  Widget build(c) {
    return TextButton(
      onPressed: () {
        setState(() {
          _refresh(force: true);
        });
      },
      child: const Text('x'),
    );
  }
}
DART

# --- must FAIL (exit 1): each rule, broken on purpose -------------------------
expect 1 "0.1 two StatefulWidget screens" <<'DART'
class CheckInPage extends StatefulWidget {}
class _CheckInPageState extends State<CheckInPage> {}
class InsightsPage extends StatefulWidget {}
class _InsightsPageState extends State<InsightsPage> {}
DART

expect 1 "0.1 two StatelessWidget screens (was a false negative)" <<'DART'
class CheckInScreen extends StatelessWidget {}
class InsightsScreen extends StatelessWidget {}
DART

expect 1 "0.1 Dart 3 class modifiers (was a false negative)" <<'DART'
final class CheckInScreen extends StatelessWidget {}
final class InsightsScreen extends StatelessWidget {}
DART

{ echo 'class C {'; echo '  void big() {'
  for i in $(seq 1 90); do echo "    print($i);"; done
  echo '  }'; echo '}'; } > "$TMP/long.dart"
expect 1 "0.3 brace-bodied 92-line method" < "$TMP/long.dart"

{ echo 'class C {'; echo '  Widget big() => Column('
  for i in $(seq 1 90); do echo "    Text('$i'),"; done
  echo '  );'; echo '}'; } > "$TMP/arrow.dart"
expect 1 "0.3 expression-bodied method (was a false negative)" < "$TMP/arrow.dart"

{ echo 'class C {'; echo '  Future<void> methodWithAVeryLongNameForcingAWrap('
  echo '    String parameterWithAVeryLongNameForcingAWrap,'
  echo '  ) async {'
  for i in $(seq 1 90); do echo "    print($i);"; done
  echo '  }'; echo '}'; } > "$TMP/wrapped.dart"
expect 1 "0.3 wrapped signature (was a false negative)" < "$TMP/wrapped.dart"

expect 1 "0.4 local fn in a callback, custom return type" <<'DART'
class C {
  Widget build(c) {
    return Builder(
      builder: (c) {
        int helper() {
          return 1;
        }
        return Text('$helper');
      },
    );
  }
}
DART

expect 1 "0.5 raw number" <<'DART'
class C {
  Widget build(c) => const SizedBox(height: 18);
}
DART

expect 1 "0.5 SizedBox.square (was a false negative)" <<'DART'
class C {
  Widget build(c) => const SizedBox.square(dimension: 36);
}
DART

expect 1 "0.5 EdgeInsetsDirectional (was a false negative)" <<'DART'
class C {
  Widget build(c) => const Padding(
    padding: EdgeInsetsDirectional.only(end: 20),
    child: Text('x'),
  );
}
DART

# --- must ERROR (exit 2): the check could not run -----------------------------
"$CHECK" "$TMP/does_not_exist.dart" >/dev/null 2>&1
[ $? -eq 2 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: missing file must exit 2"; }

CHECK_BASE_REF=definitely-not-a-ref "$CHECK" >/dev/null 2>&1
[ $? -eq 2 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: bad base ref must exit 2"; }

# --- scope: uncommitted work must be seen by default mode ---------------------
probe=lib/zz_check_guidelines_probe.dart
cat > "$probe" <<'DART'
class C {
  Widget build(c) => const SizedBox(height: 18);
}
DART
"$CHECK" >/dev/null 2>&1
got=$?
rm -f "$probe"
[ "$got" -eq 1 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: default mode must see an UNCOMMITTED file (want 1, got $got)"; }

echo
echo "check_guidelines_test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
