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

# expect_at <want-exit> <name> <lib-relative path> — for the path-based rules
# (0.10 placement, 0.11 layer direction). The fixture is planted under a fake
# lib/ tree so the checker's path patterns match exactly as they do in the repo.
expect_at() {
  local want=$1 name=$2 file="$TMP/fixture/lib/$3"
  mkdir -p "$(dirname "$file")"
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

expect 0 "a named-parameter constructor is not a long method" <<'DART'
class Foo extends StatelessWidget {
  const Foo({
    super.key,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.e,
    required this.f,
    required this.g,
    required this.h,
    required this.i,
    required this.j,
    required this.k,
    required this.l,
    required this.m,
    required this.n,
    required this.o,
    required this.p,
    required this.q,
    required this.r,
    required this.s,
    required this.t,
    required this.u,
    required this.v,
    required this.w,
    required this.x,
    required this.y,
    required this.z,
    required this.aa,
    required this.bb,
    required this.cc,
    required this.dd,
    required this.ee,
    required this.ff,
    required this.gg,
    required this.hh,
    required this.ii,
    required this.jj,
    required this.kk,
    required this.ll,
    required this.mm,
    required this.nn,
    required this.oo,
    required this.pp,
    required this.qq,
    required this.rr,
    required this.ss,
    required this.tt,
    required this.uu,
    required this.vv,
    required this.ww,
    required this.xx,
    required this.yy,
    required this.zz,
    required this.aaa,
    required this.bbb,
    required this.ccc,
    required this.ddd,
    required this.eee,
    required this.fff,
    required this.ggg,
    required this.hhh,
    required this.iii,
    required this.jjj,
    required this.kkk,
    required this.lll,
    required this.mmm,
    required this.nnn,
    required this.ooo,
    required this.ppp,
    required this.qqq,
    required this.rrr,
    required this.sss,
    required this.ttt,
    required this.uuu,
    required this.vvv,
    required this.www,
    required this.xxx,
    required this.yyy,
    required this.zzz,
  });
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

# --- 0.10 where new code goes -------------------------------------------------
expect_at 1 "new file in a frozen tree is rejected" "pages/new_thing.dart" <<'DART'
class C {}
DART

expect_at 1 "new loose file at lib/ root is rejected" "new_thing.dart" <<'DART'
class C {}
DART

expect_at 0 "new file in a feature is fine" "features/x/ui/x_page.dart" <<'DART'
class C {}
DART

expect_at 0 "new shared theme file is fine" "util/theme/new_tokens.dart" <<'DART'
class C {}
DART

# --- 0.11 layer direction -----------------------------------------------------
expect_at 1 "data/ importing a widget library is rejected" "features/x/data/x_renderer.dart" <<'DART'
import 'package:flutter/material.dart';
class C {}
DART

expect_at 1 "data/ importing pdf widgets is rejected" "features/x/data/x_report.dart" <<'DART'
import 'package:pdf/widgets.dart' as pw;
class C {}
DART

expect_at 0 "data/ importing foundation is fine" "features/x/data/x_store.dart" <<'DART'
import 'package:flutter/foundation.dart';
class C {}
DART

expect_at 1 "ui/ importing a data service is rejected" "features/x/ui/x_view_model.dart" <<'DART'
import 'package:mazilon/features/x/data/x_source_link_service.dart';
class C {}
DART

expect_at 0 "ui/ importing models and the repository is fine" "features/x/ui/x_page.dart" <<'DART'
import 'package:mazilon/features/x/data/x_models.dart';
import 'package:mazilon/features/x/data/x_repository.dart';
class C {}
DART

# --- 0.12 use the design-system component --------------------------------
expect_at 1 "a new bare TextButton( in ui/ is rejected" "features/x/ui/x_page.dart" <<'DART'
class C {
  Widget build(c) => TextButton(onPressed: () {}, child: const Text('Go'));
}
DART

expect_at 1 "a new bare Card( in ui/ is rejected" "features/x/ui/x_page.dart" <<'DART'
class C {
  Widget build(c) => Card(child: const Text('Go'));
}
DART

expect_at 0 "AppButton/AppCard in ui/ are fine" "features/x/ui/x_page.dart" <<'DART'
class C {
  Widget build(c) => AppCard(child: AppButton(label: 'Go', onPressed: () {}));
}
DART

expect_at 0 "a private _FeatureCard class is not a bare Card(" "features/x/ui/x_page.dart" <<'DART'
class _FeatureCard extends StatelessWidget {}
DART

expect_at 0 "the legacy myTextButton helper is not a bare TextButton(" "features/x/ui/x_page.dart" <<'DART'
class C {
  Widget build(c) => myTextButton(() {}, Icons.close, Colors.red);
}
DART


echo
echo "check_guidelines_test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
