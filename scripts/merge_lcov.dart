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
// we emit only SF + DA + LF + LH + end_of_record. The gate tolerates the
// absence of the function/branch records; the output is still valid LCOV for
// tools that inspect more aggressively.
//
// LCOV parsing is shared with the gate scripts via `_lcov_parser.dart` (PR
// #266 review: extracted to eliminate triple-duplication of the SF/DA loop).

import 'dart:io';

import '_lcov_parser.dart';

void main(List<String> args) {
  if (args.length < 3) {
    stderr.writeln('Usage: merge_lcov.dart OUT IN1 IN2 [IN3...]');
    exit(2);
  }
  final outPath = args.first;
  final inputs = args.skip(1).toList();

  // parseLcovInputs is fatal on missing files — that intentional behavior
  // landed during the PR #266 review (finding 2 in the broader cleanup:
  // missing inputs must not silently produce a partial merge report).
  final merged = parseLcovInputs(inputs);

  final buf = StringBuffer();
  for (final entry in merged.entries) {
    buf.writeln('SF:${entry.key}');
    final lineNumbers = entry.value.lineHits.keys.toList()..sort();
    for (final ln in lineNumbers) {
      buf.writeln('DA:$ln,${entry.value.lineHits[ln]}');
    }
    buf.writeln('LF:${entry.value.total}');
    buf.writeln('LH:${entry.value.hit}');
    buf.writeln('end_of_record');
  }

  File(outPath).writeAsStringSync(buf.toString());
  stdout.writeln(
      'wrote $outPath: ${merged.length} files, ${inputs.length} inputs merged');
}
