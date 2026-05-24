// Quick per-file coverage dump for ad-hoc analysis.
//
// Reads coverage/lcov.info and prints "pct  hit/total  path" sorted by pct asc.
// Optional positional substring filter narrows by path.

import 'dart:io';

void main(List<String> args) {
  final filter = args.isNotEmpty ? args.first : '';
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('coverage/lcov.info not found.');
    exit(2);
  }
  final stats = <String, List<int>>{}; // path -> [hit, total]
  String? cur;
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      cur = line.substring(3).replaceAll(r'\\', '/').replaceAll(r'\', '/');
      stats.putIfAbsent(cur, () => [0, 0]);
    } else if (line.startsWith('DA:')) {
      final c = cur;
      if (c == null) continue;
      final csv = line.substring(3);
      final comma = csv.indexOf(',');
      if (comma == -1) continue;
      final hits = int.tryParse(csv.substring(comma + 1)) ?? 0;
      final s = stats[c]!;
      s[1]++;
      if (hits > 0) s[0]++;
    }
  }
  final entries = stats.entries.where((e) => e.key.contains(filter)).toList();
  entries.sort((a, b) {
    final pa = a.value[1] == 0 ? 0.0 : a.value[0] / a.value[1];
    final pb = b.value[1] == 0 ? 0.0 : b.value[0] / b.value[1];
    return pa.compareTo(pb);
  });
  for (final e in entries) {
    final hit = e.value[0];
    final total = e.value[1];
    final pct = total == 0 ? 0.0 : 100.0 * hit / total;
    stdout.writeln(
        '${pct.toStringAsFixed(1).padLeft(5)}%  ${hit.toString().padLeft(4)}/${total.toString().padLeft(4)}  ${e.key}');
  }
}
