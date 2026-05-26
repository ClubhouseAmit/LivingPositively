// Coverage gate for the Mazilon iOS integration_test/ pipeline
// (ADR-005 § A, Phase 10A).
//
// Sibling of scripts/check_integration_coverage.dart. Reads
// coverage/integration_ios.info (produced by `flutter test integration_test/
// notifications_schedule_ios_test.dart --coverage --coverage-path
// coverage/integration_ios.info` in the macos-15 `integration-test-ios` job)
// and enforces ONLY the per-file floors below.
//
// Global coverage is owned by the unit pipeline (`scripts/check_coverage.dart`)
// and the aggregate gate (`scripts/check_aggregate_coverage.dart`). This iOS
// gate intentionally does NOT check global — it would be misleading: this
// invocation runs only one test file, so its lcov is sparse by design.
//
// The 60% floor on `lib/pages/notifications/notification_service.dart` under
// the iOS invocation alone is sized to:
//   - Catch a regression where the iOS test stops exercising the file
//     meaningfully (e.g. setup change accidentally skips the body of every
//     testWidgets block) — that would push coverage below 60% immediately.
//   - Tolerate the iOS surface being structurally narrower than Android
//     (no Workmanager arm, no Android permission flow, no
//     androidScheduleMode-only code paths).
//
// Exit codes:
//   0  per-file floors met
//   1  one or more floors not met (or files missing from lcov)
//   2  coverage/integration_ios.info is missing — fatal, treated as a CI-
//      config error rather than a coverage regression.

import 'dart:io';

import '_lcov_parser.dart';

const _floors = <String, double>{
  'lib/pages/notifications/notification_service.dart': 60.0,
};

void main(List<String> args) {
  final lcovFile = File('coverage/integration_ios.info');
  if (!lcovFile.existsSync()) {
    stderr
      ..writeln('FATAL: coverage/integration_ios.info not found.')
      ..writeln(
          '  Expected the integration-test-ios job to have produced it via:')
      ..writeln('    flutter test integration_test/'
          'notifications_schedule_ios_test.dart \\')
      ..writeln('      --coverage \\')
      ..writeln('      --coverage-path coverage/integration_ios.info \\')
      ..writeln('      -d "<iPhone simulator UDID>"')
      ..writeln('  If you are running locally without an iOS simulator '
          'attached, this is expected — the file is generated only by the '
          'macos-15 CI integration-test-ios job.');
    exit(2);
  }

  final stats = parseLcov(lcovFile);

  final result = enforceFloors(
    stats: stats,
    floors: _floors,
    label: 'iOS PER-FILE',
  );

  stdout
    ..writeln('===== Mazilon iOS Integration Coverage Gate (ADR-005 § A) =====')
    ..writeln('Files inspected: ${_floors.length}')
    ..writeln(result.reportLines.join('\n'))
    ..writeln(
        '===============================================================');

  if (result.failures.isEmpty) {
    stdout.writeln('PASS: all iOS integration-test per-file floors met.');
    exit(0);
  } else {
    stderr.writeln('FAIL: iOS integration-test per-file floors not met:');
    for (final f in result.failures) {
      stderr.writeln('  - $f');
    }
    exit(1);
  }
}
