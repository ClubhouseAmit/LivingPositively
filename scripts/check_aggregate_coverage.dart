// Aggregate coverage gate for Mazilon (ADR-003, Phase 8).
//
// Reads TWO pre-merged lcov inputs:
//   coverage/lcov.info        — produced by the build-android job (unit tests +
//                               dart-define MixPanel merge; see ADR-001)
//   coverage/integration.info — produced by the integration-test job (ADR-002)
//
// Merges them via parseLcovInputs (max hit-count per line, same semantics as
// scripts/merge_lcov.dart) and enforces a single GLOBAL floor of 85% on the
// union after applying the same exclude list as scripts/check_coverage.dart:
//
//   app_localizations*, firebase_options, global_enums, l10n.dart
//
// This gate does NOT re-enforce tier-1 / tier-2 / per-file floors — those
// are already enforced by check_coverage.dart (unit) and
// check_integration_coverage.dart (integration). Re-enforcing them here
// would produce duplicate failures for regressions already caught upstream.
//
// Usage (CI — after both upstream jobs complete and artifacts are downloaded):
//   dart run scripts/check_aggregate_coverage.dart
//
// Exit codes:
//   0  aggregate global floor met
//   1  aggregate global floor not met
//   2  either coverage/lcov.info or coverage/integration.info is absent —
//      treated as a CI-configuration error rather than a coverage regression
//      so the message is unambiguous (same pattern as
//      check_integration_coverage.dart exit-2 for the integration lcov).
//
// Floor derivation (ADR-003 § "Floor-value derivation"):
//   Unit baseline: 5576 / 6493 = 85.88%
//   Integration contribution (union delta): +163 lines across 4 files
//   Post-merge estimate: 5739 / 6493 = 88.39%
//   Floor = 88.39% − 3.0 pt headroom = 85.39% → rounded to 85%

import 'dart:io';

import '_lcov_parser.dart';

const _unitLcovPath = 'coverage/lcov.info';
const _integrationLcovPath = 'coverage/integration.info';

const double _aggregateFloor = 89.0; // ADR-004 (Phase 9 ratchet)

const _excludePatterns = <String>[
  r'lib/l10n/app_localizations.*\.dart$',
  r'lib/l10n/l10n\.dart$',
  r'lib/util/Firebase/firebase_options\.dart$',
  r'lib/global_enums\.dart$',
];

void main(List<String> args) {
  // Exit 2 if either input is absent — CI-configuration error, not a
  // coverage regression. Check both before emitting any output so the
  // diagnostic is unambiguous.
  final missing = <String>[];
  if (!File(_unitLcovPath).existsSync()) missing.add(_unitLcovPath);
  if (!File(_integrationLcovPath).existsSync()) missing.add(_integrationLcovPath);

  if (missing.isNotEmpty) {
    stderr
      ..writeln('FATAL: the following lcov inputs are missing:')
      ..writeln('  ${missing.join('\n  ')}')
      ..writeln('')
      ..writeln('Expected both files to be present in the coverage-aggregate')
      ..writeln('job — did the artifact-download steps succeed?')
      ..writeln('')
      ..writeln('  $_unitLcovPath is produced by the build-android job')
      ..writeln('    (artifact: coverage-lcov)')
      ..writeln('  $_integrationLcovPath is produced by the integration-test job')
      ..writeln('    (artifact: coverage-integration-lcov)');
    exit(2);
  }

  // Merge both lcovs (max hit-count per line, same semantics as merge_lcov.dart).
  final merged = parseLcovInputs([_unitLcovPath, _integrationLcovPath]);

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
    ..writeln('======= Mazilon Aggregate Coverage Gate (ADR-003) =======')
    ..writeln('Inputs:   $_unitLcovPath (unit) + $_integrationLcovPath (intg)')
    ..writeln('Files:    ${filtered.length} (excluded: ${excluded.length})')
    ..writeln(
        'Lines:    $totalHit / $totalLines = '
        '${aggregatePct.toStringAsFixed(2)}%')
    ..writeln(
        'Global aggregate floor: ${_aggregateFloor.toStringAsFixed(0)}%')
    ..writeln('=========================================================');

  if (aggregatePct >= _aggregateFloor) {
    stdout.writeln('PASS: aggregate coverage floor met.');
    exit(0);
  } else {
    stderr.writeln('FAIL: aggregate coverage floor not met:');
    stderr.writeln(
        '  AGGREGATE: ${aggregatePct.toStringAsFixed(1)}% < '
        '${_aggregateFloor.toStringAsFixed(1)}%');
    exit(1);
  }
}
