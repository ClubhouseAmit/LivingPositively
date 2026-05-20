// Shared LCOV parser used by check_coverage.dart,
// check_integration_coverage.dart, and merge_lcov.dart.
//
// Parses SF + DA records only — that is all the gate scripts and the merge
// helper inspect. Other LCOV record types (LF/LH/BRDA/FN*/FNDA*) are
// recomputed from DA records on emit (merge) or ignored (gates).
//
// Extracted from `check_coverage.dart`'s inline parser during PR #266 review
// (baz-reviewer finding 2: SF/DA parsing duplicated across three scripts).

import 'dart:io';

/// Per-file line-coverage stats keyed by line number. Total / hit / pct are
/// derived from the line map so duplicate DA entries for the same line
/// collapse — which is the correct LCOV semantic (the format guarantees one
/// DA per (file, line) but historically the inline gate parsers were
/// counting duplicates twice).
class LcovFileStats {
  LcovFileStats(this.path);
  final String path;
  final Map<int, int> lineHits = <int, int>{};
  int get total => lineHits.length;
  int get hit => lineHits.values.where((h) => h > 0).length;
  double get pct => total == 0 ? 0.0 : 100.0 * hit / total;
}

/// Parse an LCOV file into a `path → LcovFileStats` map. Normalizes Windows
/// path separators to forward slashes so the maps are comparable to the
/// `lib/...` paths used by gate config.
///
/// [mergeMode] controls per-line conflict resolution when the same source
/// line appears in multiple SF blocks (only relevant when merging multiple
/// input files via [parseLcovInputs]). In mergeMode the higher hit count
/// wins (a line covered in any input is reported as covered). Outside merge
/// mode the first observation wins; for well-formed LCOV this is
/// irrelevant.
Map<String, LcovFileStats> parseLcov(
  File lcov, {
  bool mergeMode = false,
}) {
  final stats = <String, LcovFileStats>{};
  String? cur;
  for (final raw in lcov.readAsLinesSync()) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      cur = line.substring(3).replaceAll(r'\\', '/').replaceAll(r'\', '/');
      stats.putIfAbsent(cur, () => LcovFileStats(cur!));
    } else if (line.startsWith('DA:')) {
      final c = cur;
      if (c == null) continue;
      final csv = line.substring(3);
      final comma = csv.indexOf(',');
      if (comma == -1) continue;
      final ln = int.tryParse(csv.substring(0, comma));
      final hits = int.tryParse(csv.substring(comma + 1));
      if (ln == null || hits == null) continue;
      final fileStats = stats[c]!;
      if (mergeMode) {
        final prev = fileStats.lineHits[ln] ?? 0;
        fileStats.lineHits[ln] = hits > prev ? hits : prev;
      } else {
        fileStats.lineHits.putIfAbsent(ln, () => hits);
      }
    }
  }
  return stats;
}

/// Parse and merge multiple LCOV files via [parseLcov] in mergeMode. Returns
/// the combined map. Missing input files are fatal — the caller is expected
/// to validate paths first or accept this helper's exit-2 behavior.
Map<String, LcovFileStats> parseLcovInputs(List<String> paths) {
  final merged = <String, LcovFileStats>{};
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('FATAL: lcov input not found: $path');
      exit(2);
    }
    final parsed = parseLcov(file, mergeMode: true);
    for (final entry in parsed.entries) {
      final dest = merged.putIfAbsent(entry.key, () => LcovFileStats(entry.key));
      for (final lineEntry in entry.value.lineHits.entries) {
        final prev = dest.lineHits[lineEntry.key] ?? 0;
        final next = lineEntry.value;
        dest.lineHits[lineEntry.key] = next > prev ? next : prev;
      }
    }
  }
  return merged;
}
