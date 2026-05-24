// Coverage gate for the Mazilon integration_test/ pipeline (ADR-002, Phase 7).
//
// Sibling of scripts/check_coverage.dart. Reads coverage/integration.info
// (produced by `flutter test integration_test --coverage --coverage-path
// coverage/integration.info`) and enforces ONLY the per-file floors below.
// Global coverage is owned by the unit pipeline (`scripts/check_coverage.dart`);
// this gate intentionally does NOT check it so that emulator-class flakes in
// the integration job cannot pull the global gate below 82%.
//
// Per ADR-002 § "Per-file floors in scripts/check_integration_coverage.dart":
//
//   const _floors = <String, double>{
//     'lib/main.dart': 50.0,
//     'lib/pages/WellnessTools/player.dart': 60.0,
//     'lib/util/logger_service.dart': 60.0,
//     'lib/pages/notifications/notification_service.dart': 85.0,
//   };
//
// Exit codes:
//   0  all per-file floors met
//   1  one or more floors not met (or files missing from lcov)
//   2  coverage/integration.info is missing — fatal, treated as a CI-config
//      error rather than a coverage regression so the message is unambiguous.

import 'dart:io';

import '_lcov_parser.dart';

const _floors = <String, double>{
  'lib/main.dart': 50.0,
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
