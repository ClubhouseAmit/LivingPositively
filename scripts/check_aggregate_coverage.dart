// Aggregate coverage gate for Mazilon (ADR-003 Phase 8, ratcheted by
// ADR-004 Phase 9; iOS input added under ADR-005 § A, Phase 10A).
//
// Reads THREE pre-merged lcov inputs:
//   coverage/lcov.info            — produced by the build-android job (unit
//                                   tests + dart-define MixPanel merge; see
//                                   ADR-001)
//   coverage/integration.info     — produced by the integration-test job
//                                   (ADR-002)
//   coverage/integration_ios.info — produced by the integration-test-ios job
//                                   (ADR-005 § A, Phase 10A)
//
// Merges them via parseLcovInputs (max hit-count per line, same semantics as
// scripts/merge_lcov.dart) and enforces a single GLOBAL floor on the union
// after applying the same exclude list as scripts/check_coverage.dart. The
// floor was 85% under ADR-003 (Phase 8); ADR-004 (Phase 9) ratcheted it to
// 89% — see the _aggregateFloor constant below and the Phase 9 derivation
// in docs/coverage-status.md § Round 9:
//
//   app_localizations*, firebase_options, global_enums, l10n.dart
//
// This gate does NOT re-enforce tier-1 / tier-2 / per-file floors — those
// are already enforced by check_coverage.dart (unit) and
// check_integration_coverage.dart (integration). Re-enforcing them here
// would produce duplicate failures for regressions already caught upstream.
//
// Usage (CI — after all upstream jobs complete and artifacts are downloaded):
//   dart run scripts/check_aggregate_coverage.dart
//
// Exit codes:
//   0  aggregate global floor met
//   1  aggregate global floor not met
//   2  any of coverage/lcov.info, coverage/integration.info, or
//      coverage/integration_ios.info is absent — treated as a CI-configuration
//      error rather than a coverage regression so the message is unambiguous
//      (same pattern as check_integration_coverage.dart exit-2 for the
//      integration lcov).
//
// Floor derivation:
//   ADR-003 (Phase 8) — original 85% floor:
//     Unit baseline: 5576 / 6493 = 85.88%
//     Integration contribution (union delta): +163 lines across 4 files
//     Post-merge estimate: 5739 / 6493 = 88.39%
//     Floor = 88.39% − 3.0 pt headroom = 85.39% → rounded to 85%
//
//   ADR-004 (Phase 9) — ratchet to 89%:
//     Unit baseline grew to 5800 / 6493 = 89.33% after extending the
//     firestore injection pattern in firebase_functions.dart from 14 to
//     43 helpers + qe-test-architect-authored tests.
//     Aggregate estimate: 5963 / 6493 = 91.84%
//     Floor = 91.84% − 3.0 pt headroom ≈ 88.84% → rounded to 89%
//     The 3 pt cushion matches every prior ratchet step.
//
//   ADR-005 § A (Phase 10A) — iOS input added without ratchet:
//     The iOS integration lcov can only raise the union's hit-count (max
//     per line), never lower it, so the existing 89% floor stays safe and
//     the headroom only grows. A future ratchet to track the iOS-inclusive
//     baseline is deferred until the iOS suite covers more than the single
//     notifications_schedule_ios_test.dart file.

import 'dart:io';

import '_lcov_parser.dart';

const _unitLcovPath = 'coverage/lcov.info';
const _integrationLcovPath = 'coverage/integration.info';
const _iosIntegrationLcovPath = 'coverage/integration_ios.info';

const double _aggregateFloor = 89.0; // ADR-004 (Phase 9 ratchet)

const _excludePatterns = <String>[
  r'lib/l10n/app_localizations.*\.dart$',
  r'lib/l10n/l10n\.dart$',
  r'lib/util/Firebase/firebase_options\.dart$',
  r'lib/global_enums\.dart$',
];

void main(List<String> args) {
  // Exit 2 if any input is absent — CI-configuration error, not a coverage
  // regression. Check all three before emitting any output so the diagnostic
  // is unambiguous.
  final missing = <String>[];
  if (!File(_unitLcovPath).existsSync()) missing.add(_unitLcovPath);
  if (!File(_integrationLcovPath).existsSync())
    missing.add(_integrationLcovPath);
  if (!File(_iosIntegrationLcovPath).existsSync())
    missing.add(_iosIntegrationLcovPath);

  if (missing.isNotEmpty) {
    stderr
      ..writeln('FATAL: the following lcov inputs are missing:')
      ..writeln('  ${missing.join('\n  ')}')
      ..writeln('')
      ..writeln('Expected all three files to be present in the')
      ..writeln('coverage-aggregate job — did the artifact-download steps')
      ..writeln('succeed?')
      ..writeln('')
      ..writeln('  $_unitLcovPath is produced by the build-android job')
      ..writeln('    (artifact: coverage-lcov)')
      ..writeln(
          '  $_integrationLcovPath is produced by the integration-test job')
      ..writeln('    (artifact: coverage-integration-lcov)')
      ..writeln('  $_iosIntegrationLcovPath is produced by the')
      ..writeln('    integration-test-ios job')
      ..writeln('    (artifact: coverage-integration-ios-lcov)');
    exit(2);
  }

  // Merge all three lcovs (max hit-count per line, same semantics as
  // merge_lcov.dart).
  final merged = parseLcovInputs(
      [_unitLcovPath, _integrationLcovPath, _iosIntegrationLcovPath]);

  // Apply exclude list (identical to check_coverage.dart).
  final excludes =
      _excludePatterns.map((p) => RegExp(p, caseSensitive: false)).toList();

  final filtered = <String, LcovFileStats>{};
  final excluded = <String>[];
  for (final entry in merged.entries) {
    if (excludes.any((re) => re.hasMatch(entry.key))) {
      excluded.add(entry.key);
    } else {
      filtered[entry.key] = entry.value;
    }
  }

  var totalHit = 0;
  var totalLines = 0;
  for (final s in filtered.values) {
    totalHit += s.hit;
    totalLines += s.total;
  }
  final aggregatePct = totalLines == 0 ? 0.0 : 100.0 * totalHit / totalLines;

  stdout
    ..writeln(
        '======= Mazilon Aggregate Coverage Gate (ADR-003/ADR-004) =======')
    ..writeln('Inputs:   $_unitLcovPath (unit) + '
        '$_integrationLcovPath (intg) + '
        '$_iosIntegrationLcovPath (iOS intg)')
    ..writeln('Files:    ${filtered.length} (excluded: ${excluded.length})')
    ..writeln('Lines:    $totalHit / $totalLines = '
        '${aggregatePct.toStringAsFixed(2)}%')
    ..writeln('Global aggregate floor: ${_aggregateFloor.toStringAsFixed(0)}%')
    ..writeln('=========================================================');

  if (aggregatePct >= _aggregateFloor) {
    stdout.writeln('PASS: aggregate coverage floor met.');
    exit(0);
  } else {
    stderr.writeln('FAIL: aggregate coverage floor not met:');
    stderr.writeln('  AGGREGATE: ${aggregatePct.toStringAsFixed(1)}% < '
        '${_aggregateFloor.toStringAsFixed(1)}%');
    exit(1);
  }
}
