// Coverage gate for the Mazilon integration_test/ pipeline (ADR-002, Phase 7;
// `lib/main.dart` floor raised under ADR-005 § B, Phase 10B).
//
// Sibling of scripts/check_coverage.dart. Reads coverage/integration.info
// (produced by `flutter test integration_test --coverage --coverage-path
// coverage/integration.info`) and enforces ONLY the per-file floors below.
// Global coverage is owned by the unit pipeline (`scripts/check_coverage.dart`)
// and the aggregate gate (`scripts/check_aggregate_coverage.dart`); this gate
// intentionally does NOT check global so that emulator-class flakes in the
// integration job cannot pull the unit pipeline's 85% global floor below
// threshold.
//
// **Current floors** (see `_floors` map below for the authoritative values —
// this comment is illustrative and is updated when the map changes):
//
//   const _floors = <String, double>{
//     'lib/main.dart': 65.0,                                         // ADR-005 § B (was 50.0 under ADR-002)
//     'lib/pages/WellnessTools/player.dart': 60.0,                   // ADR-002
//     'lib/util/logger_service.dart': 60.0,                          // ADR-002
//     'lib/pages/notifications/notification_service.dart': 85.0,     // ADR-002
//   };
//
// Exit codes:
//   0  all per-file floors met
//   1  one or more floors not met (or files missing from lcov)
//   2  coverage/integration.info is missing — fatal, treated as a CI-config
//      error rather than a coverage regression so the message is unambiguous.

import 'dart:io';

import '_lcov_parser.dart';

// Phase 10B (ADR-005 § B) raised `lib/main.dart` from 50.0 → 65.0 after the
// `bootstrapApp()` extraction made the bootstrap path reachable from the
// new `integration_test/bootstrap_full_test.dart`. The smoke test already
// covered MyApp; the full test additionally exercises the lines that
// build the widget tree (the MultiProvider construction + the optional
// dependency-injection branches) plus the extracted `initializeApp` body.
// callbackDispatcher (lines 42-89) stays uncovered — foreground integration
// tests cannot trigger a Workmanager background entry-point. The 65% floor
// is set below the expected ~75% so the gate tolerates incidental drift
// from new lines added to MyApp in future feature work.
const _floors = <String, double>{
  'lib/main.dart': 65.0,
  'lib/pages/WellnessTools/player.dart': 60.0,
  'lib/util/logger_service.dart': 60.0,
  'lib/pages/notifications/notification_service.dart': 85.0,
};

void main(List<String> args) {
  final lcovFile = File('coverage/integration.info');
  if (!lcovFile.existsSync()) {
    stderr
      ..writeln('FATAL: coverage/integration.info not found.')
      ..writeln(
          '  Expected the integration-test job to have produced it via:')
      ..writeln(
          '    flutter test integration_test --coverage --coverage-path coverage/integration.info')
      ..writeln(
          '  If you are running locally and have no emulator attached, this is')
      ..writeln(
          '  expected — the file is generated only by the CI integration-test job.');
    exit(2);
  }

  final stats = parseLcov(lcovFile);

  final result = enforceFloors(
    stats: stats,
    floors: _floors,
    label: 'PER-FILE',
  );

  stdout
    ..writeln('===== Mazilon Integration Coverage Gate (ADR-002) =====')
    ..writeln('Files inspected: ${_floors.length}')
    ..writeln(result.reportLines.join('\n'))
    ..writeln('=======================================================');

  if (result.failures.isEmpty) {
    stdout.writeln('PASS: all integration-test per-file floors met.');
    exit(0);
  } else {
    stderr.writeln('FAIL: integration-test per-file floors not met:');
    for (final f in result.failures) {
      stderr.writeln('  - $f');
    }
    exit(1);
  }
}
