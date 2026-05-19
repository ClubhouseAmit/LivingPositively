// Merges two or more LCOV files into a single output.
//
// Usage:
//   dart run scripts/merge_lcov.dart out.info in1.info in2.info [in3.info...]
//
// For each input file we accumulate per-line hit counts (DA records). When the
// same source file appears in multiple inputs the maximum hit count per line
// is taken (this is the LCOV-equivalent "branch executed in at least one run"
// semantic — what matters for the Phase 6 gate is whether a line was hit at
// all, not how many times).
//
// Other record types (LF, LH, BRDA, BRF, BRH, FN*, FNDA*) are not strictly
// needed by `scripts/check_coverage.dart` (which only inspects SF + DA), so
// we emit only SF + DA + end_of_record. The gate tolerates the absence of
// the function/branch records; the output is still valid LCOV for tools
// that inspect more aggressively.

import 'dart:io';

void main(List<String> args) {
  if (args.length < 3) {
    stderr.writeln('Usage: merge_lcov.dart OUT IN1 IN2 [IN3...]');
    exit(2);
  }
  final outPath = args.first;
  final inputs = args.skip(1).toList();

  // file -> line -> hits
  final accumulated = <String, Map<int, int>>{};

  for (final path in inputs) {
    final file = File(path);
    if (!file.existsSync()) {
      // A coverage-gate helper must not silently produce a partial report
      // when an expected input is missing. CI orchestration relies on every
      // listed input being present — a typo or skipped step would otherwise
      // yield a plausible-but-incomplete merged report and could mask a
      // regression.
      stderr.writeln('FATAL: lcov input not found: $path');
      exit(2);
    }
    String? cur;
    for (final raw in file.readAsLinesSync()) {
      final line = raw.trim();
      if (line.startsWith('SF:')) {
        cur = line.substring(3).replaceAll(r'\\', '/').replaceAll(r'\', '/');
        accumulated.putIfAbsent(cur, () => <int, int>{});
      } else if (line.startsWith('DA:')) {
        final c = cur;
        if (c == null) continue;
        final csv = line.substring(3);
        final comma = csv.indexOf(',');
        if (comma == -1) continue;
        final ln = int.tryParse(csv.substring(0, comma));
        final hits = int.tryParse(csv.substring(comma + 1));
        if (ln == null || hits == null) continue;
        final map = accumulated[c]!;
        final prev = map[ln] ?? 0;
        // Take the max so a line covered in either run is reported as
        // covered. (Sum would also work for the gate, but max keeps numbers
        // stable when re-running tests on top of an existing artifact.)
        map[ln] = hits > prev ? hits : prev;
      }
    }
  }

  final buf = StringBuffer();
  for (final entry in accumulated.entries) {
    buf.writeln('SF:${entry.key}');
    final lines = entry.value.keys.toList()..sort();
    var lf = 0;
    var lh = 0;
    for (final ln in lines) {
      final hits = entry.value[ln]!;
      buf.writeln('DA:$ln,$hits');
      lf++;
      if (hits > 0) lh++;
    }
    buf.writeln('LF:$lf');
    buf.writeln('LH:$lh');
    buf.writeln('end_of_record');
  }

  File(outPath).writeAsStringSync(buf.toString());
  stdout.writeln(
      'wrote $outPath: ${accumulated.length} files, '
      '${inputs.length} inputs merged');
}
