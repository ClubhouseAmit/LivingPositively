// Coverage gate for Mazilon.
//
// Reads coverage/lcov.info, applies per-file exclude patterns, computes
// global and per-tier line coverage, and exits non-zero if any configured
// threshold is not met.
//
// Usage:
//   dart run scripts/check_coverage.dart            # use defaults
//   dart run scripts/check_coverage.dart --strict   # fail on any tier miss
//
// Tier and threshold configuration is defined inline below.

import 'dart:io';

import '_lcov_parser.dart';

const _excludePatterns = <String>[
  r'lib/l10n/app_localizations.*\.dart$',
  r'lib/l10n/l10n\.dart$',
  r'lib/util/Firebase/firebase_options\.dart$',
  r'lib/global_enums\.dart$',
];

// Tier 1: safety/auth/persistence-critical files. Each file must be >= 50%
// (raise to 80% as the suite matures). notification_service.dart's static
// platform-bound methods (showNotification / scheduleNotification /
// initializeNotification) cannot be exercised without a real platform
// channel for flutter_local_notifications + workmanager — we cover the
// pure-Dart parts (calculateTime, supportsReminderSettings) and leave the
// rest to integration tests.
const _tier1 = <String>{
  'lib/util/Firebase/firebase_functions.dart',
  'lib/util/persistent_memory_service.dart',
  'lib/disclaimerPage.dart',
  'lib/file_service.dart',
  'lib/util/PDF/create_pdf.dart',
  'lib/Locale/locale_service.dart',
};

// Tier 2: large or complex pages with high blast radius.
//
// Updated in round 2: positive.dart (73%), myPlanPageFull.dart (82%), the
// form/*.dart wizard pages, set_notification_widget.dart and the reminder
// debug stack all have smoke tests landed. NumberPicker + WorkManager-bound
// branches keep some sublines uncovered; the 40% floor is the sustainable
// minimum across the lot, the global gate enforces the higher real number.
//
// Round 3: the initialForm/*.dart wizard pages joined the tier after the
// `_Test.dart` → `_test.dart` rename made flutter test pick up their
// existing Mockito-based suites; the same rename also unblocked
// form/formpagetemplate.dart and form/shareform.dart.
const _tier2 = <String>{
  'lib/pages/UserSettings.dart',
  'lib/pages/journal.dart',
  'lib/pages/PersonalPlan/myPlan.dart',
  'lib/pages/positive.dart',
  'lib/pages/PersonalPlan/myPlanPageFull.dart',
  'lib/form/form.dart',
  'lib/form/phonePageform.dart',
  'lib/form/phonePageListItem.dart',
  'lib/form/shareform.dart',
  'lib/form/formpagetemplate.dart',
  'lib/pages/notifications/set_notification_widget.dart',
  'lib/pages/notifications/reminder_debug_panel.dart',
  'lib/pages/notifications/reminder_debug_recorder.dart',
  'lib/pages/notifications/time_picker.dart',
  'lib/initialForm/form.dart',
  'lib/initialForm/initialFormPage1.dart',
  'lib/initialForm/initialFormPage2.dart',
  'lib/initialForm/toFormPage.dart',
};

const double _globalThreshold = 85.0; // ~89.3% as of round 9 (ADR-004)
const double _tier1Threshold = 50.0;
const double _tier2Threshold = 40.0;

// Per-file floors that exist to make ADR-001's hybrid Phase-6 mechanism
// load-bearing. `lib/AnalyticsService.dart` reaches ~90% only because the
// CI workflow re-runs MixPanelService_token_test.dart with
// `--dart-define=MIXPANEL_PROJECT_TOKEN=test-token` and merges the lcov
// output. If that step is ever removed, or merge_lcov.dart silently fails,
// the file drops back to its pre-Phase-6 baseline (~36%) — without this
// per-file gate the global floor would still be met and the regression
// would land unnoticed. The floor sits below the achieved 90.9% with a
// small cushion for future trivial-line drift.
const _perFileFloors = <String, double>{
  'lib/AnalyticsService.dart': 85.0,
};

void main(List<String> args) {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    stderr.writeln('coverage/lcov.info not found. Run '
        '`flutter test --coverage` first.');
    exit(2);
  }

  final excludes =
      _excludePatterns.map((p) => RegExp(p, caseSensitive: false)).toList();

  final stats = parseLcov(lcovFile);

  final filtered = <String, LcovFileStats>{};
  final excluded = <String>[];
  for (final entry in stats.entries) {
    final f = entry.key;
    if (excludes.any((re) => re.hasMatch(f))) {
      excluded.add(f);
    } else {
      filtered[f] = entry.value;
    }
  }

  var totalHit = 0;
  var totalLines = 0;
  for (final s in filtered.values) {
    totalHit += s.hit;
    totalLines += s.total;
  }
  final globalPct = totalLines == 0 ? 0.0 : 100.0 * totalHit / totalLines;

  final failures = <String>[];

  if (globalPct < _globalThreshold) {
    failures.add(
        'GLOBAL: ${globalPct.toStringAsFixed(1)}% < ${_globalThreshold.toStringAsFixed(1)}%');
  }

  final tier1Result = enforceFloors(
    stats: filtered,
    floors: {for (final f in _tier1) f: _tier1Threshold},
    label: 'TIER1',
  );
  failures.addAll(tier1Result.failures);

  final tier2Result = enforceFloors(
    stats: filtered,
    floors: {for (final f in _tier2) f: _tier2Threshold},
    label: 'TIER2',
    missingIsWarning: true,
  );
  failures.addAll(tier2Result.failures);
  for (final w in tier2Result.warnings) {
    stdout.writeln('  WARN $w');
  }

  final perFileResult = enforceFloors(
    stats: filtered,
    floors: _perFileFloors,
    label: 'PER-FILE',
  );
  failures.addAll(perFileResult.failures);

  stdout
    ..writeln('========== Mazilon Coverage Gate ==========')
    ..writeln('Files:    ${filtered.length} (excluded: ${excluded.length})')
    ..writeln(
        'Lines:    $totalHit / $totalLines = ${globalPct.toStringAsFixed(2)}%')
    ..writeln('Tier 1 floor: ${_tier1Threshold.toStringAsFixed(0)}%   '
        'Tier 2 floor: ${_tier2Threshold.toStringAsFixed(0)}%   '
        'Global floor: ${_globalThreshold.toStringAsFixed(0)}%')
    ..writeln('===========================================');

  if (failures.isEmpty) {
    stdout.writeln('PASS: all coverage thresholds met.');
    exit(0);
  } else {
    stderr.writeln('FAIL: coverage thresholds not met:');
    for (final f in failures) {
      stderr.writeln('  - $f');
    }
    exit(1);
  }
}
